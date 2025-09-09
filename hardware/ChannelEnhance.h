#ifndef PASS_CHANNELENHANCE_H
#define PASS_CHANNELENHANCE_H

#include <vector>
#include <unordered_map>

#include "pass/pass.h"

using namespace bir;

class ChannelEnhance : public Pass {
 public:
  ChannelEnhance() {}
  virtual ~ChannelEnhance() {}
  virtual int run(bir::Module &module) override;
};

#endif