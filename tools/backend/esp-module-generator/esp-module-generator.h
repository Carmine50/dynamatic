//#include "dynamatic/Support/RTL.h"
#include "mlir/Dialect/Arith/IR/Arith.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/InitLLVM.h"
#include "llvm/Support/SourceMgr.h"
#include <fstream>
#include <map>
#include <regex>

using namespace llvm;
using namespace mlir;

class Node {

public:

  Node() {
    this->name = "";
    this->type = "";
    this->inputs = std::vector<Node*>();
    this->outputs = std::vector<Node*>();
  }

  Node(std::string name, std::string type) {
    this->name = name;
    this->type = type;
    this->inputs = std::vector<Node*>();
    this->outputs = std::vector<Node*>();
  }

  std::string getName() {
    return name;
  }

  std::string getType() {
    return type;
  }

  std::vector<Node*> getInputs() {
    return inputs;
  }

  std::vector<Node*> getOutputs() {
    return outputs;
  }

  int getInputPos( Node * input ) {
    return distance(inputs.begin(), find(inputs.begin(), inputs.end(), input));
  }

  void setName(std::string name) {
    this->name = name;
  }

  void setType(std::string type) {
    this->type = type;
  }

  void setInputs(std::vector<Node*> inputs) {
    this->inputs = inputs;
  }

  void setInputPos(Node * input, int pos) {
    inputs.insert(inputs.begin() + pos, input);
  }

  void setOutputs(std::vector<Node*> outputs) {
    this->outputs = outputs;
  }

  void setOutputPos(Node * output, int pos) {
    outputs.insert(outputs.begin() + pos, output);
  }

  void addInput(Node * input) {
    inputs.push_back(input);
  }

  void addOutput(Node * output) {
    outputs.push_back(output);
  }

  void removeInput(Node * input) {
    inputs.erase(std::remove(inputs.begin(), inputs.end(), input), inputs.end());
  }

  void removeOutput(Node * output) {
    outputs.erase(std::remove(outputs.begin(), outputs.end(), output), outputs.end());
  }

  bool operator==(const Node &other) const {
    return name == other.name;
  }

  bool operator!=(const Node &other) const {
    return name != other.name;
  }

private:
  std::string name;
  std::string type;
  std::vector<Node*> inputs;
  std::vector<Node*> outputs;
};
