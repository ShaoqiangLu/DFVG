#include "pass/LowerComplex.h"
#include "bir/LoopAxis.h"
#include "bir/MemoryLocation.h"
#include <limits>
#include <string>
#include <iostream>
#include <fstream>
#include <vector>


int LowerComplex::run(bir::Module &module) {
  Arch *A = module.getArchModel();
  std::vector<bir::Conv2dInst*> conv2ds;
  for (auto &f : module) {
    for (auto &bb : f) {
      //std::cout << "[BB] " << bb.getName() << "\n";
      for (auto &inst : bb) {
        //std::cout << "[INST] " << inst.getName() << "\n"; 
        if (llvm::isa<bir::Conv2dInst>(inst)) {
          bir::Conv2dInst* I = llvm::cast<bir::Conv2dInst>(&inst);
          conv2ds.push_back(I);
        } 
      }  
    }   
  }
  for (auto *I : conv2ds) {
    std::cout << "[INST] " << I->getName() << " " << InstructionType2String(I->getOpcode()) <<"\n";   
    LowerConv2d(I, A);  
  }
  return 0;  
}

