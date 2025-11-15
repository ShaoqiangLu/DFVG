#include <fstream>
#include <iostream>
#include "bir/BasicBlock.h"
#include "bir/Instruction.h"
#include "bir/NodeContainer.h"

#include "nlohmann/json.hpp"

using namespace bir;

template<> std::atomic<unsigned> NodeWithParent<BasicBlock, Function>::IdCounter(0);

BasicBlock::BasicBlock(const std::string &Name, Function *Parent) : NodeWithParent<BasicBlock, Function>(Name, Parent){};

void BasicBlock::removeInstruction(Instruction &I) {
  NodeContainer<BasicBlock, Instruction>::removeElement(I);
}

Instruction* BasicBlock::getInstructionByName(const std::string &Name) {
  return NodeContainer<BasicBlock, Instruction>::getElementByName(Name);
}

void BasicBlock::dump(std::ostream &os) {
  os << "BasicBlock : " << this->getName() << " ";
  os << "#Instructions : " << this->size() - complex_instructions.size() << "\n";
  for (auto &I : this->instructions()) {
    auto it = std::find(complex_instructions.begin(), complex_instructions.end(), &I);
    if (it != complex_instructions.end())
      continue;
    os << I.toString() << "\n";  
  }
  os << "\n";
}