#ifndef PASS_LOWERCOMPLEX_H
#define PASS_LOWERCOMPLEX_H

#include "pass/pass.h"
#include "bir/Instruction.h"
#include "bir/AffineExpr.h"
#include "Arch.h"

class LowerComplex : public Pass {
 public:
  LowerComplex() {}
  virtual ~LowerComplex() {}
  virtual int run(bir::Module &module) override;

  void LowerConv2d(bir::Conv2dInst *I, Arch *arch);
  void FindTilingFactorConv2D(bir::Conv2dInst *I, Arch *A, std::unordered_map<std::string, std::vector<int>> &tiling);
  void LowerConv2dToInstruction(bir::Conv2dInst *I, std::vector<bir::LoopAxis*>& loopnest, bir::loopmap& values, int level);
  int cnt = 0;
};

#endif
