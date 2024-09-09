//===- ESPfpsa.cpp - Integration of ESP FPSA  ----------------*- C++ -*-===//
//
// Dynamatic is under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
// This file implement the integration of ESP FPSA applying the following
// steps:
// 1. Identify an external module function called __esp_fpsa
// 2. It replaces this module with a sub-circuit depending on the input
//    settings (fpsaMode and arcPath)
//===----------------------------------------------------------------------===//

#include "experimental/Transforms/ESPIntegration/ESPfpsa.h"
#include "dynamatic/Analysis/NameAnalysis.h"
#include "dynamatic/Dialect/Handshake/HandshakeInterfaces.h"
#include "dynamatic/Dialect/Handshake/HandshakeOps.h"
#include "dynamatic/Support/DynamaticPass.h"
#include "dynamatic/Support/LLVM.h"
#include "dynamatic/Support/Logging.h"
#include "dynamatic/Transforms/HandshakeMaterialize.h"
#include "mlir/IR/Attributes.h"
#include "mlir/IR/BuiltinAttributes.h"
#include "mlir/Pass/PassManager.h"
#include "mlir/Support/LogicalResult.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/Support/Casting.h"
#include "llvm/Support/Path.h"
#include "llvm/Support/raw_ostream.h"
#include <cassert>
#include <cstddef>

using namespace llvm;
using namespace mlir;
using namespace dynamatic;
using namespace dynamatic::experimental;
using namespace dynamatic::experimental::espIntegration;

struct ESPfpsaPass
    : public dynamatic::experimental::espIntegration::impl::ESPfpsaBase<
          ESPfpsaPass> {

  ESPfpsaPass(StringRef fpsaMode, StringRef arcPath) {}

  void runDynamaticPass() override;

  LogicalResult replaceInstanceOp(handshake::InstanceOp instanceOp,
                                  handshake::FuncOp instanceFuncOp);
};

// this function replaces the InstanceOp with the sub-circuit of ESP FPSA
LogicalResult ESPfpsaPass::replaceInstanceOp(handshake::InstanceOp instanceOp,
                                             handshake::FuncOp instanceFuncOp) {

  if (instanceOp->getNumOperands() != 5 || instanceOp.getNumResults() != 2) {
    llvm::errs() << "Instance operation " << instanceOp->getName()
                 << " should have 5 inputs and 2 outputs\n";
    return failure();
  }

  // Before creating the ESP FPSA structure, it is essential understanding the
  // meaning of each input values of the instance operation
  SmallVector<Value> operandsESPmodule;
  SmallVector<StringRef> operandsNames = {"fifo_in", "conf_info_op_mode",
                                          "conf_info_fpsa",
                                          "conf_info_mat_1_size", "start"};
  ArrayAttr argNames =
      instanceFuncOp->getAttr("argNames").dyn_cast<ArrayAttr>();
  for (size_t jOp = 0; jOp < operandsNames.size(); jOp++) {
    for (size_t iArg = 0; iArg < instanceOp->getNumOperands(); iArg++) {
      StringRef argName = argNames[iArg].dyn_cast<StringAttr>().getValue();
      if (operandsNames[jOp] == argName) {
        Value argValue = instanceOp->getOperand(iArg);
        operandsESPmodule.push_back(argValue);
      }
    }
    // if the expected inputs are not present, the behaviour of ESP FPSA cannot
    // be replicated
    if (operandsESPmodule.size() != (jOp + 1)) {
      // the start signal is automatically added in dynamatic during the
      // creation of the instance operation
      llvm::errs()
          << "Instance operation " << instanceOp->getName()
          << " should have all the following inputs fifo_in,"
          << " conf_info_op_mode, conf_info_fpsa, conf_info_mat_1_size.";
      return failure();
    }
  }

  // the same it's replicated for the output values
  SmallVector<Value> resultsESPmodule;
  SmallVector<StringRef> resultsNames = {"out0", "end"};
  ArrayAttr resNames =
      instanceFuncOp->getAttr("resNames").dyn_cast<ArrayAttr>();
  for (size_t jRes = 0; jRes < resultsNames.size(); jRes++) {
    for (size_t iOut = 0; iOut < instanceOp.getNumResults(); iOut++) {
      auto resName = resNames[iOut].dyn_cast<StringAttr>().getValue();
      if (resultsNames[jRes] == resName) {
        Value resValue = instanceOp->getResult(iOut);
        resultsESPmodule.push_back(resValue);
      }
    }

    if (resultsESPmodule.size() != (jRes + 1)) {
      // the end signal is automatically added in dynamatic during the
      // creation of the instance operation
      llvm::errs() << "Instance operation " << instanceOp->getName()
                   << " should have the following output out0";
      return failure();
    }
  }

  Value inputData = operandsESPmodule[0];
  Value opMode = operandsESPmodule[1];
  Value infoFpsa = operandsESPmodule[2];
  Value matInSize = operandsESPmodule[3];
  Value startSig = operandsESPmodule[4];
  Value out0 = resultsESPmodule[0];
  Value endEsp = resultsESPmodule[1];

  MLIRContext *ctx = &getContext();
  OpBuilder builder(ctx);

  builder.setInsertionPoint(instanceOp);

  handshake::BufferOp inputFifo = builder.create<handshake::BufferOp>(
      instanceOp->getLoc(), inputData.getType(), inputData, SIZE);

  return success();
}

void ESPfpsaPass::runDynamaticPass() {
  NameAnalysis &namer = getAnalysis<NameAnalysis>();
  ModuleOp modOp = getOperation();
  SymbolTable symbols(modOp);

  for (handshake::FuncOp funcOp : modOp.getOps<handshake::FuncOp>()) {
    if (funcOp.isExternal())
      continue;
    // iterating through the instance operations that represent calls of
    // external functions
    for (handshake::InstanceOp extOp : funcOp.getOps<handshake::InstanceOp>()) {
      auto instFuncOp = symbols.lookup<handshake::FuncOp>(extOp.getModule());
      StringRef instFuncName = instFuncOp.getNameAttr().strref();
      // if the instance's function respects the desired tag, it should be
      // replaced with the ESP FPSA
      if (instFuncName.equals("__esp_fpsa")) {
        if (failed(replaceInstanceOp(extOp, instFuncOp))) {
          modOp->emitError() << "Failed inserting ESP FPSA module";
          return;
        }
      }
    }
  }
}

namespace dynamatic {
namespace experimental {
namespace espIntegration {

/// Returns a unique pointer to an operation pass that matches MLIR modules.
std::unique_ptr<dynamatic::DynamaticPass> insertESPfpsa(StringRef fpsaMode,
                                                        StringRef arcPath) {
  return std::make_unique<ESPfpsaPass>(fpsaMode, arcPath);
}

} // namespace espIntegration
} // namespace experimental
} // namespace dynamatic
