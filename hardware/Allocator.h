#ifndef PASS_ALLOCATOR_H
#define PASS_ALLOCATOR_H

#include "pass/pass.h"
#include "bir/Function.h"
#include "bir/BasicBlock.h"
#include "Arch.h"

using namespace bir;

class Allocator : public Pass {
 public:
  Allocator() {}
  virtual ~Allocator() {}
  virtual int run(bir::Module &module) override;
  
  void dram_allocation(Function &f, Arch *A);
  void remove_same_dram_load(BasicBlock &bb, Arch *A, MemoryType Type); 
  void allocate_wb(BasicBlock &bb, Arch *A);
};

#endif