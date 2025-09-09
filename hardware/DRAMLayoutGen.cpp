#include "pass/DRAMLayoutGen.h"
#include "bir/MemoryLocation.h"
#include "nlohmann/json.hpp"

#include <fstream>
#include <functional>
#include <string>

using namespace nlohmann;

void reform_conv2d_weight(MemoryLocation *m, std::vector<std::vector<int>>& data) {
  std::string wpath = "dump/";
  std::function<std::string(std::string)> get_file_name = [](std::string mw_name) {
    return "weights_" + mw_name.substr(1) + ".npy";  
  };

}

void gen_weight_layout(BasicBlock &bb, std::ofstream &os) {
  //std::cout << ">> " << bb.getName() << "\n";
  Instruction *main = nullptr;
  for (auto &I : bb) {
    if (llvm::isa<Conv2dInst>(I)) {
      main = &I;
      break;
    }
  }
  assert(main != nullptr);
  for (auto &I : bb) {
    if (llvm::isa<LoadInst>(I)) {
      auto mo = I.getOutput(0);
      if (mo->getType() == MemoryType::WB) {
        //std::cout << I.getInput(0)->toString() << "\n";  
        json j;
        auto m = I.getInput(0);
        j["name"] = m->getName();
        j["layer index"] = std::atoi(bb.getName().substr(6).c_str());  // layer_xx
        j["range"] = m->getAccessPatternRange();
        j["start address"] = m->getOffset();
        j["address count"] = m->getStepSize() * m->getStep();
        j["format"] = "KCRS";
        j["weight fraclen"] = main->getAttr("weight fraclen");
        j["shape"] = m->getTensorshape();
        for (auto *succ : I.succ) {
          if (llvm::isa<MatmultInst>(*succ)) {
            j["output channel tiling size"] = succ->getAttr("output_num");
            break;
          }
        }
        if (main->hasAttr("channel enhanced")) {
          j["channel enhanced"] = true;
          std::vector<int> raw_wshape = {main->getAttr("raw K"), main->getAttr("raw C"), main->getAttr("raw R"), main->getAttr("raw S")};  // KCRS
          j["raw weight shape"] = raw_wshape;
        } else {
          j["channel enhanced"] = false;
        }
        os << j << "\n";
      }  
    }  
  }  
}

void gen_bias_layout(BasicBlock &bb, std::ofstream &os) {
  //std::cout << ">> " << bb.getName() << "\n";
  Instruction *main = nullptr;
  for (auto &I : bb) {
    if (llvm::isa<Conv2dInst>(I)) {
      main = &I;
      break;
    }
  }
  assert(main != nullptr);
  for (auto &I : bb) {
    if (llvm::isa<LoadInst>(I)) {
      auto mo = I.getOutput(0);
      if (mo->getType() == MemoryType::BB) {
        //std::cout << I.getInput(0)->toString() << "\n";
        json j;
        auto m = I.getInput(0);
        j["name"] = m->getName();
        j["layer index"] = std::atoi(bb.getName().substr(6).c_str());  // layer_xx
        j["range"] = m->getAccessPatternRange();
        j["start address"] = m->getOffset();
        j["address count"] = m->getStepSize() * m->getStep();
        j["bias fraclen"] = main->getAttr("bias fraclen");
        os << j << "\n";
      }  
    }  
  }  
}


int DRAMLayoutGen::run(bir::Module &module) {
  std::ofstream outw("dram-weight-layout.json");
  for (auto &f : module) {
    for (auto &bb : f) {
      gen_weight_layout(bb, outw);  
    } 
  }
  outw.close();
  std::ofstream outb("dram-bias-layout.json");
  for (auto &f : module) {
    for (auto &bb : f) {
      gen_bias_layout(bb, outb);  
    } 
  }
  outb.close();
  return 0;  
}
