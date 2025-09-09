#include "pass/Allocator.h"

#include "bir/MemoryLocation.h"
#include "bir/Instruction.h"
#include <fstream>

using namespace bir;

void assign_dram_addr(Instruction &I, std::unordered_map<std::string, int>& tensor_name_offset_map, Arch* A, int& w_addr) {
  std::vector<MemoryLocation*> ms;
  if (llvm::isa<LoadInst>(I)) {
    for (auto *m : I.input) {
      if (m->getType() == MemoryType::DRAM) {
        ms.push_back(m);  
      }  
    }
  } else if (llvm::isa<StoreInst>(I)) {
    for (auto *m : I.output) {
      if (m->getType() == MemoryType::DRAM) {
        ms.push_back(m);  
      }  
    }
  }
  int elements_per_dram_addr = A->getElementsPerDRAMAddr();
  for (auto *m : ms) {
    std::string tn = m->getName();
    auto it = tensor_name_offset_map.find(tn);
    if (it == tensor_name_offset_map.end()) continue;
    int offset = it->second;
    std::vector<int> shape = m->getTensorshape();
    std::vector<std::pair<int, int>> range = m->getAccessPatternRange();
    if (tn.find("x") != std::string::npos) {
      // shape: N x C(<=64) x H x W
      int h = shape[2];
      int w = shape[3];
      int c_lb = range[1].first;
      int c_ub = range[1].second;
      int h_lb = range[2].first;
      int h_ub = range[2].second;
      int w_lb = range[3].first;
      int w_ub = range[3].second;
      int offset_local = c_lb / elements_per_dram_addr * h * w + (h_lb * w + w_lb) + offset;
      m->setOffset(offset_local);
      m->setStepSize(w_ub - w_lb);
      m->setStride(h);
      m->setStep(h_ub - h_lb);
    } else if (tn.find("w") != std::string::npos) {
      // K(<=64) x C(<=64) x R x S
      int r_lb = range[2].first;
      int r_ub = range[2].second;
      int s_lb = range[3].first;
      int s_ub = range[3].second;
      int kz = range[0].second - range[0].first;
      int cz = range[1].second - range[1].first;
      int spatial_k = A->multipliers / elements_per_dram_addr;
      if (cz <= elements_per_dram_addr / 2)
        spatial_k *= 2;
      kz = ceil((float)kz / spatial_k) * spatial_k;
      if (cz < elements_per_dram_addr / 2) 
        cz = elements_per_dram_addr / 2;
      int addr_cnt = ceil((float)kz * cz / elements_per_dram_addr);
      m->setOffset(w_addr);
      w_addr += addr_cnt * (r_ub - r_lb) * (s_ub - s_lb) ; 
      m->setStepSize(addr_cnt);
      m->setStep((r_ub - r_lb) * (s_ub - s_lb) );
      m->setStride(addr_cnt);
    } else if (tn.find("b") != std::string::npos) {
      int k_lb = range[0].first;
      int k_ub = range[0].second;
      int unit_size = elements_per_dram_addr;  // == IPA max output number 64 
      int step_size = std::ceil((float)(k_ub - k_lb) / unit_size) * 2;
      int offset_local = offset + std::ceil((float)k_lb / unit_size) * 2;;
      m->setOffset(offset_local);
      m->setStepSize(step_size);
      m->setStep(1);
      m->setStride(1);  
    } 
  }
}


void Allocator::dram_allocation(Function &f, Arch *A) {
  std::vector<MemoryLocation*> mem_locs = f.MemoryLocations();
  std::unordered_map<std::string, int> tensor_name_offset_map;
  // fmap
  int addr = A->dram_fmap_addr_offset;
  for (auto *m : mem_locs) {
    std::string name = m->getName();
    if (name.find("x") != std::string::npos) {
      m->setOffset(addr);
      tensor_name_offset_map[name] = addr;
      std::cout << name << " -> DRAM " << addr << "\n";
      auto shape = m->getTensorshape();
      int n = shape[0];
      int c = shape[1];
      int h = shape[2];
      int w = shape[3];
      c = ceil((float)c / A->getElementsPerDRAMAddr()) * A->getElementsPerDRAMAddr();
      addr += n * c * h * w / A->getElementsPerDRAMAddr();
    }
  }
  // weight
  addr = std::max(addr, A->dram_w_addr_offset);
  int w_addr = addr;
  for (auto *m : mem_locs) {
    std::string name = m->getName();
    if (name.find("w") != std::string::npos) {
      m->setOffset(addr);
      tensor_name_offset_map[name] = addr;
      std::cout << name << " -> DRAM " << addr << "\n";
      auto shape = m->getTensorshape();
      int k = shape[0];
      int c = shape[1];
      int r = shape[2];
      int s = shape[3];
      c = ceil((float)c / A->getElementsPerDRAMAddr()) * A->getElementsPerDRAMAddr();
      //k = ceil((float)k / A->getElementsPerDRAMAddr()) * A->getElementsPerDRAMAddr();
      //std::cout << k << ", " << c << ", " << r << ", " << s << "\n";//exit(1);
      addr += k * c * r * s / A->getElementsPerDRAMAddr();
    }
  }
  // bias
  addr = std::max(addr, A->dram_b_addr_offset);
  for (auto *m : mem_locs) {
    std::string name = m->getName();
    if (name.find("b") != std::string::npos) {
      m->setOffset(addr);
      tensor_name_offset_map[name] = addr;
      std::cout << name << " -> DRAM " << addr << "\n";
      auto shape = m->getTensorshape();
      int k = shape[0];
      int elements_per_addr = A->getElementsPerDRAMAddr();
      k = ceil((float)k / elements_per_addr) * elements_per_addr;
      addr += k / elements_per_addr * 2; // 2 = 16bit bias / 8bit fm
    }
  }
  // Calculate local dram load offset/step
  for (auto &bb : f) {
    for (auto &I : bb) {
      assign_dram_addr(I, tensor_name_offset_map, A, w_addr);
    }
  }
}

void Allocator::allocate_wb(BasicBlock &bb, Arch *A) {
  int wb_depth = A->getWBDepth();
  int elements_per_dram_addr = A->getElementsPerDRAMAddr();
  int offset = 0;
  int total_bank = A->getWBBank();  // 2
  int bank_id = 0;
  std::vector<std::pair<Instruction*, Instruction*>> mergeto;
  for (auto &I : bb) {
    if (!llvm::isa<LoadInst>(I)) continue;  
    for (auto *m : I.output) {
      if (m->getType() == MemoryType::WB) {
        // check w addr needed by m
        auto *mi = I.getInput(0);
        int dram_addr_cnt = mi->getStepSize();
        int wb_addr_cnt = dram_addr_cnt * elements_per_dram_addr / A->w_buffer_bw_bytes;
        // assign physical offset/step for m
        /* 
        if (offset + wb_addr_cnt * mi->getStep() > wb_depth) {
          offset = 0;
          bank_id = (bank_id + 1) % total_bank;  // modulo
        }
        */ 
        m->setOffset(/*offset*/0);  // for each load from DRAM to weight buffer, we simply start from 0 address each time --> not good buffer utilization --> totally depending on load merge
        m->setStepSize(wb_addr_cnt);
        m->setStep(mi->getStep());
        m->setStride(mi->getStep());
        m->setBankId(bank_id);
        bank_id = (bank_id + 1) % total_bank;  // switch for each load
        offset += wb_addr_cnt * mi->getStep();  
      }  
    } 
  }
}   

/*
 x0 <- Load(y0)
 z0 <- Matmult(x0, w0)
 x1 <- Load(y0)
 z1 <- Matmult(x1, w1)
   |
  \ /
 x0 <- Load(y0)
 z0 <- Matmult(x0, w0)
 z1 <- Matmult(x0, w1) 

 improve locality but do not consider spill

 depends on # bank !!!
*/
void Allocator::remove_same_dram_load(BasicBlock &bb, Arch *A, MemoryType Type) {
  std::unordered_map<MemoryLocation*, Instruction*> memloc_inst_map;
  std::vector<std::pair<Instruction*, Instruction*>> remove;
  for (auto &I : bb) {
    if (!llvm::isa<LoadInst>(I)) continue;  
    std::vector<MemoryLocation*> mb;  
    for (auto *m : I.output) {
      if (m->getType() == Type) {
        mb.push_back(I.getInput(0));  
      }  
    } 
    for (auto *m : mb) {
      bool eq = false;  
      for (auto item : memloc_inst_map) {
        if (m->equal(*item.first)) {
          eq = true;
          // merge
          remove.push_back({&I, item.second});
          break;  
        }
      }
      if (!eq) {
        memloc_inst_map[m] = &I;  
      }
    } 
  }
  std::cout << bb.getName() << " ";
  std::cout << "#instructions: " << bb.size() << " -> ";
  for (auto item : remove) {
    for (auto inst_succ : item.first->succ) {
      inst_succ->removeDependency(item.first);
      inst_succ->addDependency(item.second);
      inst_succ->removeInput(item.first->getOutput(0));
      inst_succ->addInput(item.second->getOutput(0));
    }
    bb.removeInstruction(*item.first);
  }
  std::cout << bb.size() << " after removing redundant load from DRAM to "
    << MemoryType2String(Type) << "\n";
}  

void allocate_fb(BasicBlock &bb, Arch* A) { 
  int total_bank = A->getFBBank();  // 2
  int bank_id = 0;
  for (auto &I : bb) {
    if (!llvm::isa<LoadInst>(I)) continue;  
    for (auto *m : I.output) {
      if (m->getType() == MemoryType::FB) {
        m->setOffset(0);
        auto mi = I.getOutput(0);
        m->setStepSize(mi->getStep() * mi->getStepSize());
        m->setStep(1);
        m->setStride(1);
        m->setBankId(bank_id);
        bank_id = (bank_id + 1) % total_bank;  // modulo
      }  
    } 
  } 
}

void allocate_bb(BasicBlock &bb, Arch* A) {
  int total_bank = A->getBBBank();  // 2
  int bank_id = 0;
  for (auto &I : bb) {
    if (!llvm::isa<LoadInst>(I)) continue;  
    for (auto *m : I.output) {
      if (m->getType() == MemoryType::BB) {
        m->setOffset(0);
        m->setStepSize(1);
        m->setStep(1);
        m->setStride(1);
        m->setBankId(bank_id);
        bank_id = (bank_id + 1) % total_bank;  // modulo
      }  
    } 
  } 
}

void allocate_psum(BasicBlock &bb, Arch* A) {
  int total_bank = A->getPSUMBank();  // 1
  int bank_id = 0;
  for (auto &I : bb) {
    for (auto *m : I.output) {
      if (m->getType() == MemoryType::PSUM) {
        assert(llvm::isa<MatmultInst>(I));
        auto *matmultinst = llvm::cast<MatmultInst>(&I);
        MemoryLocation *mx;
        MemoryLocation *mw;
        for (auto *mi : I.input) {
          if (mi->getType() == MemoryType::FB) mx = mi;
          else if (mi->getType() == MemoryType::WB) mw = mi;
        }
        std::vector<std::pair<int, int>> range = mx->getAccessPatternRange();  // NCHW
        int h_range = range[2].second - range[2].first;
        int w_range = range[3].second - range[3].first;
        range = mw->getAccessPatternRange();  // KCRS
        int r_range = range[2].second - range[2].first;
        int s_range = range[3].second - range[3].first;
        int ho_range = std::ceil((float)(h_range - r_range + 1) / matmultinst->getStride());
        int wo_range = std::ceil((float)(w_range - s_range + 1) / matmultinst->getStride());
        m->setOffset(0);
        m->setStepSize(wo_range);
        m->setStep(ho_range);
        m->setStride(wo_range);
        m->setBankId(bank_id);
        bank_id = (bank_id + 1) % total_bank;  // modulo
      }  
    } 
  } 
}

int Allocator::run(Module &module) {
  Arch *A = module.getArchModel();
  for (auto &f : module) {
    for (auto &bb : f) {
      remove_same_dram_load(bb, A, MemoryType::BB);
      remove_same_dram_load(bb, A, MemoryType::WB); 
      //remove_same_dram_load(bb, A, MemoryType::FB);
    }  
  }
  for (auto &f : module) {
    dram_allocation(f, A);
  } 
  for (auto &f : module) {
    for (auto &bb : f) {
      allocate_wb(bb, A);
      allocate_fb(bb, A);
      allocate_bb(bb, A);
      allocate_psum(bb, A);
    }  
  }
  return 0;  
}
