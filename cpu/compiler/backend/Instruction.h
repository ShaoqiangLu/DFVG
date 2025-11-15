#ifndef BIR_INSTRUCTION_H
#define BIR_INSTRUCTION_H

#include <algorithm>

#include "bir/NodeContainer.h"
#include "bir/LoopAxis.h"
#include "bir/MemoryLocation.h"
#include "EngineType.h"
#include "nlohmann/json.hpp"

namespace bir {

class BasicBlock;

enum class InstructionType {
  // Atomic  
  Load,
  Store,
  Matmult,
  // Compound (to be lowered first)
  Conv2d,
  Conv2ddw,
  // TBD
  Activation,
  Pooling,
  Loop,
};

std::string InstructionType2String(InstructionType ty);

class Instruction : public NodeWithParent<Instruction, BasicBlock> {
 public:
  InstructionType Opcode;
  std::vector<Instruction*> pred;
  std::vector<Instruction*> succ;
  std::vector<MemoryLocation*> input;
  std::vector<MemoryLocation*> output;

  std::unordered_map<std::string, int> attributes;

  EngineType engine;

  bool complex = false;

  Instruction(const std::string &Name, BasicBlock *Parent, InstructionType Opcode);

  InstructionType getOpcode() const {return Opcode;}

  void addInput(MemoryLocation* m) {
    input.push_back(m);
    m->addReader(this);
  }
  void addOutput(MemoryLocation* m) {
    output.push_back(m);
    m->addWriter(this);
  }
  void removeInput(MemoryLocation* m) {
    input.erase(std::find(input.begin(), input.end(), m));
    m->removeReader(this);  
  }
  void removeOutput(MemoryLocation* m) {
    output.erase(std::find(output.begin(), output.end(), m));
    m->removeWriter(this);  
  }

  MemoryLocation *getInput(int idx) {return input[idx];}
  MemoryLocation *getOutput(int idx) {return output[idx];}

  void addDependency(Instruction *I) {
    auto it = std::find(pred.begin(), pred.end(), I);
    if (it == pred.end()) {
      pred.push_back(I);
      I->succ.push_back(this);
    }
  }

  void removeDependency(Instruction* I) {
    pred.erase(std::find(pred.begin(), pred.end(), I));
    I->succ.erase(std::find(I->succ.begin(), I->succ.end(), this));
  }

  std::string toString();

  void toJson(nlohmann::json& j);

  std::unordered_map<std::string, int>& getAttrs() {
    return attributes;
  }
  void setAttr(std::string key, int value) {
    attributes[key] = value;
  }
  int getAttr(std::string key) {
    return attributes[key];
  }
  bool hasAttr(std::string key) {
    return attributes.find(key) != attributes.end();
  }

  EngineType getEngine() {return engine;}
  void setEngine(EngineType engine) {this->engine = engine;}

  bool isComplex() {return complex;}
};

class LoadInst : public Instruction {
 public:
  LoadInst(const std::string &Name, BasicBlock *Parent) 
    : Instruction(Name, Parent, InstructionType::Load) {}

  static bool classof(const Instruction *I) {
    return I->getOpcode() == InstructionType::Load;
  }  
};

class StoreInst : public Instruction {
 public:
  StoreInst(const std::string &Name, BasicBlock *Parent) 
    : Instruction(Name, Parent, InstructionType::Store) {}

  static bool classof(const Instruction *I) {
    return I->getOpcode() == InstructionType::Store;
  }   
};

class MatmultInst : public Instruction {
 public:
  MatmultInst(const std::string &Name, BasicBlock *Parent) 
    : Instruction(Name, Parent, InstructionType::Matmult) {};

  static bool classof(const Instruction *I) {
    return I->getOpcode() == InstructionType::Matmult;
  }   

  int stride = 1;
  void setStride(int s) {this->stride = s;}
  int getStride() {return this->stride;}
};



class ActivationInst : public Instruction {
 public:
  std::string type = "ReLU";
  float factor = 0.1;

  ActivationInst(const std::string &Name, BasicBlock *Parent, std::string type, float factor = 0.1)
    : Instruction(Name, Parent, InstructionType::Activation), type(type), factor(factor) {
    complex = true;
  }

  static bool classof(const Instruction *I) {
    return I->getOpcode() == InstructionType::Activation;
  }

  std::string getType() {
    return type;
  }
};

class PoolingInst : public Instruction {
 public:
  std::string type = "max";
  int size_r = 2;
  int size_s = 2;
  int stride_r = 2;
  int stride_s = 2;

  PoolingInst(const std::string &Name, BasicBlock *Parent, std::string type, int r = 2, int s = 2, int sr = 2, int ss = 2)
    : Instruction(Name, Parent, InstructionType::Pooling), type(type), size_r(r), size_s(s), stride_r(sr), stride_s(ss) {
    complex = true;
  }

  static bool classof(const Instruction *I) {
    return I->getOpcode() == InstructionType::Pooling;
  }

  std::string getType() {
    return type;
  }
};

class Conv2dInst : public Instruction {
 public:
  int n;
  int h;
  int w;
  int k; // output channel
  int c;
  int r;
  int s;
  int stride;
  std::vector<LoopAxis*> loopnest;
  Conv2dInst(const std::string &Name, BasicBlock *Parent, int n, int h, int w, int k, int c, int r, int s, int stride)
    : Instruction(Name, Parent, InstructionType::Conv2d), n(n), h(h), w(w), k(k), c(c), r(r), s(s), stride(stride) {
    loopnest.clear();
    complex = true;
  };

  static bool classof(const Instruction *I) {
    return I->getOpcode() == InstructionType::Conv2d;
  }
};

class Conv2ddwInst : public Conv2dInst {
 public:
  Conv2ddwInst(const std::string &Name, BasicBlock *Parent, int n, int h, int w, int k, int c, int r, int s, int stride)
    : Conv2dInst(Name, Parent, n, h, w, k, c, r, s, stride) {
    Opcode = InstructionType::Conv2ddw;
    complex = true;
  };

  static bool classof(const Instruction *I) {
    return I->getOpcode() == InstructionType::Conv2ddw;
  } 
};

}  // namespace bir

#endif

