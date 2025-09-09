#include "pass/MCBase.h"

using namespace bir;

void MachineCodeGenerator::Emit(BasicBlock* bb) {
    
}

void MachineCodeGenerator::PrintRegs() {
  for (auto item : name_reg_map_) {
    if (item.first.find("zero") != std::string::npos)
      continue;
    auto reg = item.second;
    std::cout << "reg<" << reg->GetBitWidth() << "> "
              << item.first << "\n";
  }
}

void MachineCodeGenerator::PrintInsts() {
  for (auto item : opcode_inst_map_) {
    auto inst = item.second;
    std::cout << "opcode=" << item.first << " SET ";
    for (auto reg : inst->fields) {
      std::cout << reg->GetName() << " " << reg->GetValue() << " ";
      if (reg->GetName() == "sync")
        std::cout << "\n";
    }
    std::cout << "\n";
  }
}