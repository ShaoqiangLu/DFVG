#include <fstream>
#include <iostream>
#include "bir/Function.h"
#include "bir/BasicBlock.h"
#include "bir/Instruction.h"
#include "bir/NodeContainer.h"

#include "nlohmann/json.hpp"

using namespace bir;

template<> std::atomic<unsigned> NodeWithParent<Function, Module>::IdCounter(0);

Function::Function(const std::string &Name, Module *Parent) : NodeWithParent<Function, Module>(Name, Parent){};

BasicBlock & Function::addBasicBlock(const std::string &Name) {
  BasicBlock &Block = NodeContainer<Function, BasicBlock>::insertElement<BasicBlock>(end(), Name);
  return Block;  
}

void Function::removeBasicBlock(BasicBlock &Block) {
  NodeContainer<Function, BasicBlock>::removeElement(Block);
}

BasicBlock* Function::getBasicBlockByName(const std::string &Name) {
  return NodeContainer<Function, BasicBlock>::getElementByName(Name);
}