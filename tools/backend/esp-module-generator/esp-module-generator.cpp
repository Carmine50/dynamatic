//===- rtl-cmpf-generator.cpp - Generator for arith.cmpf --------*- C++ -*-===//
//
// Dynamatic is under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// RTL generator for the `arith.cmpf` MLIR operation. Generates the correct RTL
// based on the floating comparison predicate.
//
//===----------------------------------------------------------------------===//

#include "esp-module-generator.h"

static cl::OptionCategory mainCategory("Tool options");

static cl::opt<std::string> inputRTLPath(cl::Positional, cl::Required,
                                         cl::desc("<input file>"),
                                         cl::cat(mainCategory));

static cl::opt<std::string> outputRTLPath(cl::Positional, cl::Required,
                                          cl::desc("<output file>"),
                                          cl::cat(mainCategory));

static Node * getNode ( std::vector<Node*> nodes, std::string node_name ){

  for (Node * node : nodes) {
    if (node->getName().compare(node_name) == 0) {
      return node;
    }
  }
  return NULL;

}

// function used to build the definition of the operation
static int getOpDef(Node * node, std::string * operationDef){
  std::string type = node->getType();
  std::string mlirOp;
  std::string mlirType;
  std::string inPort, outPort;
  if (type.compare("input") == 0) {
    mlirOp = "handshake.func";
    mlirType = "Entry";
    inPort = "in1:64";  // as a default all the bitwidth are 64 bits
    outPort = "out1:64";
    // the only case in which the bitwidth is different is for the opMode and matSize
    if (node->getName().compare("opMode") == 0 || node->getName().compare("matSize") == 0 ){
      inPort = "in1:32";
      outPort = "out1:32";
    }
  } else if (type.compare("fifo") == 0) {
    mlirOp = "handshake.tehb";
    mlirType = "TEHB";
    inPort = "in1:64";  // as a default all the bitwidth are 64 bits
    outPort = "out1:64";
  } else if (type.compare("output") == 0) {
    mlirOp = "handshake.end";
    mlirType = "Exit";
    inPort = "in1:64";  // as a default all the bitwidth are 64 bits
    outPort = "out1:64";
  } else if (type.compare("decoderOp") == 0) {
    mlirOp = "handshake.decoderAlt";
    mlirType = "DecoderAlt";
    inPort = "in1:64";  // as a default all the bitwidth are 64 bits
    outPort = "out1:64 out2:64";
  } else if (type.compare("systolicUnit") == 0){
    mlirOp = "handshake.systolicOp";
    mlirType = "systolic_unit";
    inPort = "in1:32 in2:32 in3:32 in4:64 in5:64";
    outPort = "out1:64";
  } else if (type.compare("systolicCtrlUnit") == 0){
    mlirOp = "handshake.systolicCtrlOp";
    mlirType = "systolic_ctrl_unit";
    inPort = "in1:32 in2:64";
    outPort = "out1:64 out2:32";
  } else {
    llvm::outs() << "Error: Operation " <<  type << " not supported\n";
    return -1;
  }

  *operationDef = "\"" + node->getName() + "\" [mlir_op=\"" + mlirOp + "\", label=\"" + node->getName() + "\", " ;
  *operationDef += "type=\"" + mlirType + "\", in=\"" + inPort + "\", out=\"" + outPort + "\", bbID=1";
  if (type.compare("fifo") == 0) 
    *operationDef += ", slots=64";
  *operationDef += "];\n";


  return 0;
}

static int writeDotFile( std::ofstream * file, std::vector<Node*> nodes) {

  *file << "digraph G {\n";
  *file << "splines=spline;\ncompound=true; // Allow edges between clusters \n// Units/Channels in BB 0\nsubgraph \"cluster0\" {\nlabel=\"block0\"\n";
  
  for (Node * node : nodes) {
    std::string opDefinition;
    int status = getOpDef(node , &opDefinition);
    if(status != 0){
      return status;
    }
    *file << opDefinition;
  }
  for (Node * node : nodes){
    int output_cnt = 1;
    for (Node * output : node->getOutputs()) {
      *file << "\"" << node->getName() << "\" -> \"" << output->getName() << "\" ";
      *file << "[style=\"dotted\", dir=\"both\", from=\"out" << output_cnt << "\", to=\"in" << output->getInputPos(node) + 1 << "\"];\n";
      output_cnt++;
    }
  }
  *file << "}\n}\n";

  return 0;
}

static std::vector<Node*> readDotFile( std::ifstream * file) {

  std::vector<Node*> nodes;
  std::string line;
  while (std::getline(*file, line)) {
    // assumes that a connection and statement are not multi-lines
    std::regex connectionRegex("\"(\\w+)\"\\s*->\\s*\"(\\w+)\"\\s*\\[\\s*output=(\\d+),\\s*input=(\\d+)\\s*\\]");
    std::regex typeRegex("\"(\\w+)\"\\s*\\[\\s*type=\"(\\w+)\"\\s*\\]");

    std::smatch match;
    if (std::regex_search(line, match, connectionRegex)) {
      std::string src = match[1];
      std::string dst = match[2];
      int output = std::stoi(match[3]);
      int input = std::stoi(match[4]);
      Node * src_node = getNode(nodes, src);
      Node * dst_node = getNode(nodes, dst);
      if ( src_node != NULL && dst_node != NULL ) {
        //src_node->setOutputPos(dst_node, output);
        //dst_node->setInputPos(src_node, input);
        src_node->addOutput(dst_node);
        dst_node->addInput(src_node);
      } else {
        llvm::errs() << "Error: Node not found\n";
        exit(1);
      }
    } else if (std::regex_search(line, match, typeRegex)) {
      std::string type = match[2];
      Node * new_node = new Node();
      new_node->setName(match[1]);
      new_node->setType(type);
      nodes.push_back(new_node);
    }
  }

  return nodes;
}


int main(int argc, char **argv) {
  InitLLVM y(argc, argv);

  cl::ParseCommandLineOptions(
      argc, argv,
      "RTL generator for the `__esp_module` MLIR operation. Generates the "
      "correct RTL based on the input specificates.");

  // Open the input file
  std::ifstream inputFile(inputRTLPath);
  if (!inputFile.is_open()) {
    llvm::errs() << "Failed to open input file @ \"" << inputRTLPath << "\"\n";
    return 1;
  }

  // Open the output file
  std::ofstream outputFile(outputRTLPath);
  if (!outputFile.is_open()) {
    llvm::errs() << "Failed to open output file @ \"" << outputRTLPath
                 << "\"\n";
    return 1;
  }

  // Read the input dot file that specifies connections and entities
  std::vector<Node*> nodes;
  nodes = readDotFile(&inputFile);
  // Close the input file
  inputFile.close();


  // Generate the RTL code
  int status = writeDotFile(&outputFile, nodes);
  // Close the output file
  outputFile.close();

  return status;
}

