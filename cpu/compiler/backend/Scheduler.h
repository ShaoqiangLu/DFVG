#ifndef PASS_SCHEDULER_H
#define PASS_SCHEDULER_H

#include "pass/pass.h"
#include "bir/BasicBlock.h"
#include "Arch.h"

using namespace bir;

class Scheduler : public Pass {
 public:
  Scheduler() {}
  virtual ~Scheduler() {}
  virtual int run(bir::Module &module) override;

  int inst_sched(BasicBlock &bb, Arch* A);
};

#endif
