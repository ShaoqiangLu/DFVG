#ifndef MACHINEINST_H
#define MACHINEINST_H

#include <vector>
#include <string>
#include <iostream>
#include <bitset>
#include <sstream>
#include <fstream>
#include <cmath>

#include <boost/dynamic_bitset.hpp>

class Register {
 public:
  std::string name {""};
  int id {-1};
  int bit_width {0};
  int value {-1};
  Register(std::string str, int bw) : name(str), bit_width(bw) {}
  int GetBitWidth() {return bit_width;}  
  int GetValue() {return value;}  
  std::string GetName() {return name;}
};

enum MachineInstType {
  SET,
  UNKNOWN  
};

class MachineInst {
 public:
  MachineInstType type;
  int opcode;
  std::vector<Register*> fields;  // LSB -> MSB
  std::vector<int> values;
  MachineInst(MachineInstType ty, int x, std::vector<Register*> args) : type(ty), opcode(x) {
    fields = args;
  }
  std::string ToString() {
    std::stringstream ss;
    ss << "opcode[" << opcode << "] SET ";
    for (auto reg : fields) {
      if (reg->GetName().find("zero") != std::string::npos)
        continue;
      ss << reg->GetName() << " " << reg->GetValue() << " ";
    }
    return ss.str();
  }
  std::string ToBinString() {
    std::stringstream ss;
    int pre_zero_padding_bits = 32 - 1 - 6; 
    for (auto reg : fields) {
      pre_zero_padding_bits -= reg->GetBitWidth();
    }
    if (pre_zero_padding_bits > 0) {
      boost::dynamic_bitset<> zero(pre_zero_padding_bits, 0);
      ss << zero;
    }
    for(int i = fields.size() - 1;i >= 0; i--) {
      auto *reg = fields[i];
      boost::dynamic_bitset<> reg_bits(reg->bit_width, values[i]);
      ss << reg_bits;
    }
    boost::dynamic_bitset<> opc(6, opcode);
    ss << opc;
    return ss.str(); 
  }
};

#endif
