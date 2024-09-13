//===- rtl-cmpi-generator.cpp - Generator for arith.cmpi --------*- C++ -*-===//
//
// Dynamatic is under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// RTL generator for the `arith.cmpi` MLIR operation. Generates the correct RTL
// based on the integer comparison predicate.
//
//===----------------------------------------------------------------------===//

#include "dynamatic/Dialect/Handshake/HandshakeDialect.h"
#include "dynamatic/Support/RTL/RTL.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/InitLLVM.h"
#include "llvm/Support/SourceMgr.h"
#include <cstddef>
#include <fstream>
#include <string>
#include <sys/types.h>

using namespace llvm;
using namespace mlir;
using namespace dynamatic;

static cl::OptionCategory mainCategory("Tool options");

static cl::opt<std::string> rowsInputMatrix(cl::Positional, cl::Required,
                                            cl::desc("<rows input matrix>"),
                                            cl::cat(mainCategory));

static cl::opt<std::string> rowsKernelMatrix(cl::Positional, cl::Required,
                                             cl::desc("<rows kernel matrix>"),
                                             cl::cat(mainCategory));

static cl::opt<std::string> outputRTLPath(cl::Positional, cl::Required,
                                          cl::desc("<output file>"),
                                          cl::cat(mainCategory));

// Generate the RTL for the `handshake::systolicCtrlConv` operation
static std::string generateReshapeLoop(uint rowsInput, uint rowsKernel) {

  std::string outputLoop = "always @(posedge clk) begin\n";
  outputLoop += "  if (start_write && ins_ready[0]) begin\n";
  outputLoop += "    dataOutSignal_valid <= 1;\n";
  outputLoop += "    case (cnt_write_rows)\n";

  SmallVector<std::string> kernelValues;
  for (uint yCoord = 0; yCoord < rowsKernel; yCoord++) {
    for (uint xCoord = 0; xCoord < rowsKernel; xCoord++) {
      kernelValues.push_back(
          "kernelMatrix[" + std::to_string(xCoord * rowsKernel + yCoord) + "]");
    }
    for (uint xCoord = 0; xCoord < (rowsInput - rowsKernel); xCoord++) {
      kernelValues.push_back("16'd0");
    }
  }

  uint numInternalStates = (rowsInput * rowsInput) / 4;
  uint cntWriteRows = 0;
  uint rowsPerLine = rowsInput - rowsKernel + 1;
  for (uint xCoord = 0; xCoord < rowsPerLine; xCoord++) {
    for (uint yCoord = 0; yCoord < rowsPerLine; yCoord++) {
      outputLoop += "      10'd" + std::to_string(cntWriteRows) + ": begin\n";
      outputLoop += "         case(cnt_write_cols)\n";

      uint numberPrecedingZeros = xCoord * rowsInput + yCoord;
      uint numberPostZeros = (rowsInput - xCoord - rowsKernel) * rowsInput +
                             (rowsInput - yCoord - rowsKernel);

      for (uint iState = 0; iState < numInternalStates; iState++) {
        // Generate the input matrix values
        std::string valueInputMat =
            "inputMatrix[" + std::to_string(iState * 4 + 3) +
            "], inputMatrix[" + std::to_string(iState * 4 + 2) +
            "], inputMatrix[" + std::to_string(iState * 4 + 1) +
            "], inputMatrix[" + std::to_string(iState * 4) + "]";

        outputLoop +=
            "           10'd" + std::to_string(iState * 2) + ": begin\n";
        outputLoop += "             dataOutSignal[ 63 : 0] <= {{" +
                      valueInputMat + "}};\n";
        outputLoop += "             cnt_write_cols <= cnt_write_cols + 1;\n";
        outputLoop += "           end\n";

        // Generate the kernel matrix values
        outputLoop +=
            "           10'd" + std::to_string(iState * 2 + 1) + ": begin\n";
        outputLoop += "             dataOutSignal[ 63 : 0 ] <= {{" +
                      kernelValues[iState * 4 + 3] + ", " +
                      kernelValues[iState * 4 + 2] + ", " +
                      kernelValues[iState * 4 + 1] + ", " +
                      kernelValues[iState * 4] + "}};\n";
        if (iState != numInternalStates - 1) {
          outputLoop += "             cnt_write_cols <= cnt_write_cols + 1;\n";
        } else {
          outputLoop += "             cnt_write_cols <= 0;\n";
          outputLoop += "             cnt_write_rows <= cnt_write_rows + 1;\n";
        }
        outputLoop += "           end\n";
      }
      outputLoop += "         default: start_write <= 1\n";
      outputLoop += "         endcase\n";
      outputLoop += "      end\n";
      cntWriteRows++;
    }
  }

  outputLoop +=
      "    10'd" + std::to_string(rowsPerLine * rowsPerLine) + ": begin\n";
  outputLoop += "      start_write <= 0;\n";
  outputLoop += "      dataOutSignal_valid <= 0;\n";
  outputLoop += "      startSignal_valid <= 1;\n";
  outputLoop += "      startSignal <= 1;\n";
  outputLoop += "      readyOut <= 2'd3;\n";
  outputLoop += "    end\n";
  outputLoop += "    default: start_write <= 1\n";
  outputLoop += "    endcase\n";
  outputLoop += "  end\n";
  outputLoop += "  end\n";
  return outputLoop;
}

int main(int argc, char **argv) {
  InitLLVM y(argc, argv);

  cl::ParseCommandLineOptions(
      argc, argv,
      "RTL generator for the `handshake::systolicCtrlConv` MLIR operation. "
      "Generates the "
      "correct RTL based on the number of rows of matrices A and B.");

  uint rowsInput = std::stoul(rowsInputMatrix);
  uint rowsKernel = std::stoul(rowsKernelMatrix);

  if (rowsKernel <= 0 || rowsInput <= 0) {
    llvm::errs()
        << "Negative/null number of rows for input and kernel matrices\n";
    return 1;
  }

  if (rowsKernel >= rowsInput) {
    llvm::errs() << "Number of rows for kernel matrix must be less than the "
                    "number of rows for input matrix\n";
    return 1;
  }

  // Open template file
  std::ifstream templateFile("systolicCtrlConv_template.v");
  if (!templateFile.is_open()) {
    llvm::errs()
        << "Failed to open template file @ \"systolicCtrlConv_template.v\"\n";
    return 1;
  }

  // Read the template file
  std::string inputData;
  std::string line;
  while (std::getline(templateFile, line))
    inputData += line + "\n";

  // Open the output file
  std::ofstream outputFile(outputRTLPath);
  if (!outputFile.is_open()) {
    llvm::errs() << "Failed to open output file @ \"" << outputRTLPath
                 << "\"\n";
    return 1;
  }

  // Record the replacements to be made
  std::map<std::string, std::string> replacementMap;
  replacementMap["TEMPLATE_ROWS_SIZE_INPUT_MAT"] = std::to_string(rowsInput);
  replacementMap["TEMPLATE_ROWS_SIZE_KERNEL_MAT"] = std::to_string(rowsKernel);
  replacementMap["TEMPLATE_SIZE_INPUT_MAT"] =
      std::to_string(rowsInput * rowsInput);
  replacementMap["TEMPLATE_SIZE_KERNEL_MAT"] =
      std::to_string(rowsKernel * rowsKernel);

  replacementMap["RESHAPE_LOOP"] = generateReshapeLoop(rowsInput, rowsKernel);

  // Dump to the output file and return
  outputFile << dynamatic::replaceRegexes(inputData, replacementMap);
  return 0;
}
