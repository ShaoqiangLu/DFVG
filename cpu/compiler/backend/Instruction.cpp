#include "Instruction.h"

#include "nlohmann/json.hpp"

using namespace bir;

template<> std::atomic<unsigned> NodeWithParent<Instruction, BasicBlock>::IdCounter(0);

std::string bir::InstructionType2String(InstructionType ty) {
  std::string name;
  switch (ty) {
    case InstructionType::Load: name = "Load"; break;
    case InstructionType::Store: name = "Store"; break;
    case InstructionType::Matmult: name = "Matmult"; break;
    case InstructionType::Activation: name = "Activation"; break;  
    case InstructionType::Pooling: name = "Pooling"; break;
    case InstructionType::Loop: name = "Loop"; break;
    case InstructionType::Conv2d: name = "Conv2d"; break;
    case InstructionType::Conv2ddw: name = "Conv2ddw"; break;
    default: name = "?"; break;
  }  
  return name;
} 

Instruction::Instruction(const std::string &Name, BasicBlock *Parent, InstructionType Opcode) 
  : NodeWithParent<Instruction, BasicBlock>(Name, Parent), Opcode(Opcode) {};


void Instruction::toJson(nlohmann::json& j) {

}

std::string Instruction::toString() {
  std::stringstream ss;
  
  ss << output[0]->toString() << " <- ";
  ss << InstructionType2String(Opcode) << "(";
  for (auto i = 0; i < input.size(); i++) {
    ss << input[i]->toString();
    if (i != input.size() - 1) 
      ss << ",";
  } 
  ss << ")";
  
  auto it = attributes.find("start cycle");
  if (it != attributes.end()) {
    ss << "  // in-flight@[" << it->second << "," << attributes["end cycle"] << "] ";
  }

  it = attributes.find("sync id");
  if (it != attributes.end()) {
    ss << "  // sync@" << it->second;
  }

  it = attributes.find("trigger condition");
  if (it != attributes.end()) {
    ss << "  // trig@" << it->second;
  }
  return ss.str();
}