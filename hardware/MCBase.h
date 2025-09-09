#ifndef PASS_MCBASE_H
#define PASS_MCBASE_H

#include <vector>
#include <unordered_map>

#include "bir/BasicBlock.h"
#include "pass/MachineInst.h"

using namespace bir;

class MachineCodeGenerator {
 public:
  
  /*MachineCodeGenerator(std::string target) {
    if (target == "legacy") {
        
    } else {
      std::cout << "(Abort) Unknown target: " << target << "!\n";
      exit(1);
    }
  }*/
  
  std::vector<std::pair<Register*, int>> reg_trace;
  std::vector<bool> eob;
  void SetReg(std::string reg_name, int value) {
    auto it = name_reg_map_.find(reg_name);
    if (it == name_reg_map_.end())
      std::cout << reg_name << "\n";
    assert(it != name_reg_map_.end());
    reg_trace.push_back({it->second, value});
    //std::cout << "SET " << reg_name << " " << value << "\n";
    //if (reg_name == "sync") std::cout << "\n";
  }
  
  std::vector<std::pair<MachineInst*, std::vector<int>>> mc_bb;
  void Emit(BasicBlock* bb);
  
  std::unordered_map<std::string, Register*> name_reg_map_; 
  std::unordered_map<int, MachineInst*> opcode_inst_map_;
  std::unordered_map<std::string, MachineInst*> reg_inst_map_;

  Register *GetRegister(std::string name) {
    auto it = name_reg_map_.find(name);
    if (it != name_reg_map_.end()) {
      return it->second;
    } else {
      std::cout << name << " not defined\n";
      return nullptr;
    }
  }
  
  Register* DefReg(std::string reg_name, int bit_width) {
    Register* reg = new Register(reg_name, bit_width);
    name_reg_map_[reg_name] = reg;
    return reg;
  }
  
  Register* DefZero(int bit_width) {
    std::string reg_name = "zero_" + std::to_string(bit_width);
    Register* reg = new Register(reg_name, bit_width);
    reg->value = 0;
    name_reg_map_[reg_name] = reg;
    return reg;
  }
  
  template <typename ...Args>
  void DefInst(MachineInstType ty, int opcode, Args ...args) {
    auto regs = std::vector<Register*>{args...}; 
    MachineInst* mc_inst = new MachineInst(ty, opcode, regs);  
    opcode_inst_map_[opcode] = mc_inst;
    for (auto reg : regs) {
      reg_inst_map_[reg->GetName()] = mc_inst;
    }
  }
  
  void PrintRegs();
  void PrintInsts();
};

#endif
