#include "pass/Scheduler.h"
#include "EngineType.h"

using namespace bir;

void get_latency(BasicBlock &bb, Arch *A) {
  int dram_latency = A->getDRAMLatency();
  int pe_latency = A->getPELatency();
  for (auto &I : bb) {
    // assume after allocation
    if (llvm::isa<LoadInst>(I)) {
      auto mi = I.getInput(0);  // assume uni-operand and load from DRAM
      int latency = mi->step * (mi->step_size + dram_latency);
      I.setAttr("latency", latency);
    } else if (llvm::isa<StoreInst>(I)) {
      auto mo = I.getOutput(0);  
      int latency = mo->step * (mo->step_size + dram_latency);
      I.setAttr("latency", latency);   
    } else if (llvm::isa<MatmultInst>(I)){
      MemoryLocation* mx;
      MemoryLocation* mw;
      for (auto *m : I.input) {
        if (m->getType() == MemoryType::FB) {
          mx = m;
        } else if (m->getType() == MemoryType::WB) {
          mw = m;
        }
      }
      int n = mx->getAccessPattern(0)->getIteration();
      int c = mx->getAccessPattern(1)->getIteration();
      int h = mx->getAccessPattern(2)->getIteration();
      int w = mx->getAccessPattern(3)->getIteration();
      int k = mw->getAccessPattern(0)->getIteration();
      int r = mw->getAccessPattern(2)->getIteration();
      int s = mw->getAccessPattern(3)->getIteration();
      int cycle_for_k = ceil((float)k / (A->multipliers / 64));
      I.setAttr("output_num", A->multipliers / 64);
      if (c <= 16) {
        cycle_for_k = ceil((float)cycle_for_k / 4);
        I.setAttr("output_num", A->multipliers / 64 * 4);
      } else if (c <= 32) {
        cycle_for_k = ceil((float)cycle_for_k / 2); 
        I.setAttr("output_num", A->multipliers / 64 * 2);
      }
      I.setAttr("ker_round", cycle_for_k);
      int latency = n * r * s * ((h - r + 1) * (w - s + 1) * cycle_for_k + pe_latency);
      I.setAttr("latency", latency);
    } else {
      I.setAttr("latency", 0);
    }
  }
}

// updated by buffer allocation
std::string getMemLocName(MemoryLocation* m) {
  return MemoryType2String(m->getType()) + "-" + std::to_string(m->getBankId());
}

void add_true_dependency(BasicBlock &bb) {
  std::unordered_map<std::string, Instruction*> last_def;
  for (auto &I : bb) {
    for(auto *mi : I.input) {
      std::string mname = getMemLocName(mi);
      auto it = last_def.find(mname);
      if (it != last_def.end()) {
        I.addDependency(it->second);
      }
    }
    // update last def
    for (auto *mo : I.output) {
      if (mo->getType() == MemoryType::DRAM)
        continue;
      last_def[getMemLocName(mo)] = &I;
    }
  }
}

void add_output_dependency(BasicBlock &bb) {
  std::unordered_map<std::string, Instruction*> last_def;
  for (auto &I : bb) {
    for(auto *mo : I.output) {
      std::string mname = getMemLocName(mo);
      auto it = last_def.find(mname);
      if (it != last_def.end()) {
        I.addDependency(it->second);
      }
    }
    // update last def
    for (auto *mo : I.output) {
      if (mo->getType() == MemoryType::DRAM)
        continue;
      last_def[getMemLocName(mo)] = &I;
    }
  }
}

void add_anti_dependency(BasicBlock &bb) {
  std::unordered_map<std::string, Instruction*> last_use;
  for (auto &I : bb) {
    for(auto *mo : I.output) {
      std::string mname = getMemLocName(mo);
      auto it = last_use.find(mname);
      if (it != last_use.end()) {
        I.addDependency(it->second);
      }
    }
    // update last use
    for (auto *mi : I.input) {
      if (mi->getType() == MemoryType::DRAM)
        continue;
      last_use[getMemLocName(mi)] = &I;
    }
  }
}

void assign_engine(BasicBlock &bb) {
  for (auto &I : bb) {
    if (llvm::isa<LoadInst>(I) ||
        llvm::isa<StoreInst>(I)) {
      I.setEngine(EngineType::DMA);    
    } else if (llvm::isa<MatmultInst>(I)){
      I.setEngine(EngineType::PE);
    } else {
      I.setEngine(EngineType::UNKNOWN);
    }
  }  
}

Instruction &getInstructionByIndex(BasicBlock &bb, int index) {
  int i = 0;
  for (auto &I : bb) {
    if (i == index) {
      return I;
    }
    i++;
  }
} 

void insertion_sort(BasicBlock &bb) {
  int i, key, j;
  auto it = bb.begin();
  for (i = 1; i < bb.size(); i++) {
    key = getInstructionByIndex(bb, i).getAttr("start cycle");
    j = i - 1;
    while (j >= 0 && getInstructionByIndex(bb, j).getAttr("start cycle") > key) {
      j--;
    }
    auto &inst_j = getInstructionByIndex(bb, j + 1);
    auto &inst_i = getInstructionByIndex(bb, i);
    inst_i.moveBefore(inst_j);
  }
}

int Scheduler::inst_sched(BasicBlock &bb, Arch *A) {
  std::unordered_map<std::string, int> rmap;
  rmap[EngineType2String(EngineType::DMA)] = A->getDRAMBank();  // 1
  rmap[EngineType2String(EngineType::PE)] = A->getComputeEngineCnt();  // 1

  std::unordered_map<Instruction*, bool> completed;

  std::vector<Instruction*> ready;
  std::vector<Instruction*> active;
  int cycle = 1;
  // construct initial ready insts 
  for (auto &I : bb) {
    if (I.pred.size() == 0 && !I.isComplex()) {
      ready.push_back(&I);
    }
    completed[&I] = false;
  }
  int i = 0;
  while (!ready.empty() || !active.empty()) {
    if (!ready.empty()) {
      std::vector<Instruction*> issue;
      for (auto *inst : ready) {
        if (rmap[EngineType2String(inst->getEngine())] > 0) {
          rmap[EngineType2String(inst->getEngine())]--;
          issue.push_back(inst);
          inst->setAttr("start cycle", cycle);
          //std::cout << inst->toString() << "\n";
          active.push_back(inst);
          //i++;if (i == 8) exit(1);
        }
      }
      for (auto *inst : issue) {
        ready.erase(std::find(ready.begin(), ready.end(), inst));
      }
    }
    cycle++;
    std::vector<Instruction*> remove;
    for (auto *I : active) {
      if (I->getAttr("start cycle") + I->getAttr("latency") <= cycle) {
        remove.push_back(I);
        completed[I] = true;
        I->setAttr("end cycle", cycle);
        rmap[EngineType2String(I->getEngine())]++;
        for (auto *succ : I->succ) {
          // need to check if all pred are completed
          bool all_pred_complete = true;
          for (auto *pred : succ->pred) {
            all_pred_complete &= completed[pred];
          }
          if (all_pred_complete) {
            ready.push_back(succ);
          }
        }
      }
    }
    for (auto *I : remove) {
      active.erase(std::find(active.begin(), active.end(), I));
    }
  }
  std::cout << "Estimated cycle count = " << cycle << "\n";
  return cycle;
}

void unroll_matmult(BasicBlock &bb) {
  std::vector<Instruction*> matmults;
  for (auto &I : bb) {
    if (llvm::isa<MatmultInst>(I)) {
      matmults.push_back(&I);
    }
  }
  for (auto *I : matmults) {
    MemoryLocation* mx;
    MemoryLocation* mw;
    for (auto *m : I->input) {
      if (m->getType() == MemoryType::FB) {
        mx = m;
      } else if (m->getType() == MemoryType::WB) {
        mw = m;
      }
    }
    //std::cout << I->toString() << "\n";
    std::vector<std::pair<int, int>> xrange = mx->getAccessPatternRange();
    int h_ub = xrange[2].second;
    int h_lb = xrange[2].first;
    int w_ub = xrange[3].second;
    int w_lb = xrange[3].first;
    std::vector<std::pair<int, int>> wrange = mw->getAccessPatternRange();
    int r_ub = wrange[2].second;
    int r_lb = wrange[2].first;
    int s_ub = wrange[3].second;
    int s_lb = wrange[3].first;
    Instruction *pos = I;
    int start_cycle = I->getAttr("start cycle");
    int end_cycle = I->getAttr("end cycle");
    int cycle_per_rs = (end_cycle - start_cycle) / ((r_ub - r_lb) * (s_ub - s_lb));
    I->setAttr("end cycle", start_cycle + cycle_per_rs);
    int offset = mw->getOffset();
    int step_size = mw->getStepSize();
    for (int i = r_lb; i < r_ub; i++) {
      for (int j = s_lb; j < s_ub; j++) {
        int rs_cnt = (i - r_lb) * (s_ub - s_lb) + j;
        int stride = (*mx->getAccessPattern(2)->vars.begin())->getStride();
        MemoryLocation* mx_local = mx->clone();
        MemoryLocation* mw_local = mw->clone();
        mw_local->setOffset(offset + rs_cnt * step_size);
        mw_local->setStep(1);
        mw_local->setStride(1);
        if (i == r_lb && j == s_lb) {
          mx_local->setAP(2, new AffineExpr(new LoopAxis("h_unroll", h_lb + i, h_ub - r_ub + r_lb + i + 1, stride)));
          mx_local->setAP(3, new AffineExpr(new LoopAxis("w_unroll", w_lb + j, w_ub - s_ub + s_lb + j + 1, stride)));
          mw_local->setAP(2, new AffineExpr(new LoopAxis("r_unroll", i, i + 1)));
          mw_local->setAP(3, new AffineExpr(new LoopAxis("s_unroll", j, j + 1)));
          for (auto &m : I->input) {
            if (m->getType() == MemoryType::FB) {
              m = mx_local;
            } else if (m->getType() == MemoryType::WB) {
              m = mw_local;
            }
          }
          continue;
        }
        mx_local->setAP(2, new AffineExpr(new LoopAxis("h_unroll", h_lb + i, h_ub - r_ub + r_lb + i + 1, stride)));
        mx_local->setAP(3, new AffineExpr(new LoopAxis("w_unroll", w_lb + j, w_ub - s_ub + s_lb + j + 1, stride)));
        mw_local->setAP(2, new AffineExpr(new LoopAxis("r_unroll", i, i + 1)));
        mw_local->setAP(3, new AffineExpr(new LoopAxis("s_unroll", j, j + 1)));
        Instruction *inst = &bb.addInstruction<MatmultInst>(I->getName() + "_" + std::to_string(i) + "_" + std::to_string(j));
        inst->attributes = I->attributes;
        inst->addInput(mx_local);
        inst->addInput(mw_local);
        inst->addInput(I->getOutput(0));
        inst->addOutput(I->getOutput(0));
        inst->moveAfter(*pos);
        inst->setAttr("start cycle", start_cycle + cycle_per_rs * rs_cnt);
        inst->setAttr("end cycle", start_cycle + cycle_per_rs * (rs_cnt + 1));
        pos = inst;
      }
    }
  }
}


int Scheduler::run(Module &module) {
  Arch *A = module.getArchModel();
  int cycle = 0;
  for (auto &f : module) {
    for (auto &bb : f) {
      std::cout << bb.getName() << "\n";
      assign_engine(bb);
      add_true_dependency(bb);
      add_anti_dependency(bb);
      add_output_dependency(bb);
      get_latency(bb, A);
      cycle += inst_sched(bb, A);
      unroll_matmult(bb);  // codegen related : slow down the sorting, assign sync id without sorting instruction?
      insertion_sort(bb);
    }   
  }
  std::cout << "Total latency = " 
    << (float)cycle / A->getFreq() * 1000 << "ms (" << A->getFreq() << "Hz)\n";
  return 0;  
}