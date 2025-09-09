#include <vector>
#include <algorithm>
#include <iostream>
#include <numeric>
#include <vector>
#include <cmath>

class Profiler {
 public:
  std::vector<int64_t> stage_cycle_cnt;
  std::vector<int64_t> tmp_cycle_cnt;
  int64_t frequency {200*1000000};
  
  Profiler() {
    stage_cycle_cnt.clear();
    tmp_cycle_cnt.clear();
  }
  void setFreq(int64_t freq);
  void incrementLast(int64_t cycle_cnt);
  void collect(int64_t cycle_cnt);
  void sync();
  void dump();
};