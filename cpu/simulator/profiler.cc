#include "profiler.h"
#include <glog/logging.h>

void Profiler::setFreq(int64_t freq) {
  frequency = freq;  
}

void Profiler::incrementLast(int64_t cycle_cnt) {
  tmp_cycle_cnt.back() += cycle_cnt;
}

void Profiler::collect(int64_t cycle_cnt) {
  tmp_cycle_cnt.push_back(cycle_cnt);   
}

void Profiler::sync() {
  CHECK_GT(tmp_cycle_cnt.size(), 0) << "Profiler: No cycle count collected for synchronization";
  auto iter = std::max_element(tmp_cycle_cnt.begin(), tmp_cycle_cnt.end());
  int64_t max_cycle_cnt = *iter;
  stage_cycle_cnt.push_back(max_cycle_cnt);
  tmp_cycle_cnt.clear();
}

void Profiler::dump() {
  std::cout << "\n\n========== Profiler =========\n";
  std::cout << "#stage : " << stage_cycle_cnt.size() << "\n";
  int64_t cycle = std::accumulate(stage_cycle_cnt.begin(), stage_cycle_cnt.end(), 0);
  std::cout << "#cycle : " << cycle << "\n";
  double latency = static_cast<double>(cycle) / static_cast<double>(frequency) * 1000;
  std::cout << "runtime(ms) : " << latency << "\n";
}