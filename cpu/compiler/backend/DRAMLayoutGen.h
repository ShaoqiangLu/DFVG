#ifndef PASS_DRAM_LAYOUT_GEN_H
#define PASS_DRAM_LAYOUT_GEN_H

#include <vector>
#include <unordered_map>

#include "pass/pass.h"

using namespace bir;

class DRAMLayoutGen : public Pass {
 public:
  DRAMLayoutGen() {}
  virtual ~DRAMLayoutGen() {}
  virtual int run(bir::Module &module) override;
};

#endif