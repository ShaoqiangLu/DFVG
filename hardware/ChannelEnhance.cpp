#include "pass/ChannelEnhance.h"
#include <string>
#include "bir/MemoryLocation.h"
#include "Arch.h"

using namespace bir;

void enhance_channel(BasicBlock &bb, Arch* A) {
  for (auto &inst : bb) {
    if (llvm::isa<Conv2dInst>(inst)) {
      Conv2dInst* I = llvm::cast<Conv2dInst>(&inst);
      if ((I->r > 1 || I->s > 1) && I->r * I->s * I->c < A->getElementsPerDRAMAddr()) {
        I->setAttr("channel enhanced", 1);
        I->setAttr("raw K", I->k);
        I->setAttr("raw C", I->c);
        I->setAttr("raw R", I->r);
        I->setAttr("raw S", I->s);
        // Parameter
        I->h -= I->r - 1;
        I->w -= I->s - 1;
        I->c *= I->r * I->s;
        I->r = 1;
        I->s = 1;
        // Input tensorshape
        auto mx = I->getInput(0);
        assert(mx->getName().find("x") != std::string::npos);
        mx->setTensorshape(I->n, I->c, I->h, I->w);
        // Weight tensorshape
        auto mw = I->getInput(1);
        assert(mw->getName().find("w") != std::string::npos);
        mw->setTensorshape(I->k, I->c, I->r, I->s);
        // TODO: layout transform 
      }
    }  
  }
}

int ChannelEnhance::run(Module &module) {
  Arch *A = module.getArchModel();
  for (auto &f : module) {
    for (auto &bb : f) {
      enhance_channel(bb, A);  
    }  
  }  
}