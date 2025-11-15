#include "pass/LowerComplex.h"
#include "bir/LoopAxis.h"
#include "bir/MemoryLocation.h"
#include <limits>
#include <string>
#include <iostream>
#include <fstream>
#include <vector>

using namespace bir;

float ceil_div(int x, int y) {
  return ceil((float)x / (float)y);
}

float floor_div(int x, int y) {
  return x / y;
}

void LowerComplex::FindTilingFactorConv2D(bir::Conv2dInst *I, Arch *A, std::unordered_map<std::string, std::vector<int>> &tiling) {
  // Given dataflow, find tiling factors
  int elementsPerDRAMAddr =  A->getElementsPerDRAMAddr();  // 64 for 8-bit
  int simd = A->getSIMDParallelism();
  int fmap_buffer_depth = A->fmap_buffer_depth;

  int spatial_c = elementsPerDRAMAddr;
  int spatial_k = simd / elementsPerDRAMAddr;
  spatial_c = std::min(spatial_c, I->c);
  spatial_k = std::min(spatial_k, I->k);
  tiling["c"] = {spatial_c, 0 , 0};
  tiling["k"] = {std::min(elementsPerDRAMAddr, I->k), spatial_k , 0};

  int cycle_min = std::numeric_limits<int>::max();
  for (int h = std::min(I->r + 1, I->h); h <= I->h - I->r + 1; h++) {
    for (int w = h; w <= h; w++) {  // assume square tile
      int fmap_addr_num = (h + I->r - 1) * (w + I->s - 1);
      if (fmap_addr_num > fmap_buffer_depth) continue;
      int h_cnt = floor_div(I->h - I->r + 1, h);
      int h_residue = (I->h - I->r + 1) % h;
      int w_cnt = floor_div(I->w - I->s + 1, w);
      int w_residue = (I->w - I->s + 1) % w;

      float cycle = 0;
      float cycle_compute = I->r * I->s * ceil_div(h, I->stride) * ceil_div(w, I->stride) * elementsPerDRAMAddr / spatial_k;
      float cycle_memory = (float)((h + I->r - 1) * (w + I->s - 1) + I->r * I->s * elementsPerDRAMAddr * elementsPerDRAMAddr) / elementsPerDRAMAddr;
      cycle += h_cnt * w_cnt * ceil_div(I->c, spatial_c) * ceil_div(I->k, elementsPerDRAMAddr) * std::max(cycle_compute, cycle_memory);

      cycle_compute = I->r * I->s * ceil_div(h_residue, I->stride) * ceil_div(w, I->stride) * elementsPerDRAMAddr / spatial_k;
      cycle_memory = (float)((h_residue + I->r - 1) * (w + I->s - 1) + I->r * I->s * elementsPerDRAMAddr * elementsPerDRAMAddr) / elementsPerDRAMAddr;
      if (h_residue != 0)
        cycle += w_cnt * ceil_div(I->c, spatial_c) * ceil_div(I->k, elementsPerDRAMAddr) * std::max(cycle_compute, cycle_memory);

      cycle_compute = I->r * I->s * ceil_div(h, I->stride) * ceil_div(w_residue, I->stride) * elementsPerDRAMAddr / spatial_k;
      cycle_memory = (float)((h + I->r - 1) * (w_residue + I->s - 1) + I->r * I->s * elementsPerDRAMAddr * elementsPerDRAMAddr) / elementsPerDRAMAddr;
      if (w_residue != 0)
        cycle += h_cnt * ceil_div(I->c, spatial_c) * ceil_div(I->k, elementsPerDRAMAddr) * std::max(cycle_compute, cycle_memory);

      cycle_compute = I->r * I->s * ceil_div(h_residue, I->stride) * ceil_div(w_residue, I->stride) * elementsPerDRAMAddr / spatial_k;
      cycle_memory = (float)((h_residue + I->r - 1) * (w_residue + I->s - 1) + I->r * I->s * elementsPerDRAMAddr * elementsPerDRAMAddr) / elementsPerDRAMAddr;
      if (h_residue != 0 || w_residue != 0)
        cycle += ceil_div(I->c, spatial_c) * ceil_div(I->k, elementsPerDRAMAddr) * std::max(cycle_compute, cycle_memory);
      //std::cout << h << ": " << cycle << "\n";
      if (cycle <= cycle_min) {
        cycle_min = cycle;
        tiling["h"] = {h, h_cnt, h_residue};
        tiling["w"] = {w, w_cnt, w_residue};
      }
    }
  }
  std::cout << "tiling size h, w : " << tiling["h"][0] << ", " << tiling["w"][0] << "\n";
}

void LowerComplex::LowerConv2d(bir::Conv2dInst *I, Arch *A) {
  std::cout << "shape : " << I->h << "," << I->w << "," << I->k << "," << I->c << "," << I->r << "," << I->s << "\n";
  // Build a loopnest
  std::string op_name = I->getName();
  LoopAxis* loop_n = new LoopAxis(op_name + "_n");
  loop_n->setUb(I->n);
  LoopAxis* loop_h = new LoopAxis(op_name + "_h");
  loop_h->setUb(I->h);
  loop_h->setStride(I->stride);
  LoopAxis* loop_w = new LoopAxis(op_name + "_w");
  loop_w->setUb(I->w);
  loop_h->setStride(I->stride);
  LoopAxis* loop_k = new LoopAxis(op_name + "_k");
  loop_k->setUb(I->k);
  LoopAxis* loop_c = new LoopAxis(op_name + "_c");
  loop_c->setUb(I->c);
  LoopAxis* loop_r = new LoopAxis(op_name + "_r");
  loop_r->setUb(I->r);
  LoopAxis* loop_s = new LoopAxis(op_name + "_s");
  loop_s->setUb(I->s);
  
  std::unordered_map<std::string, std::vector<int>> tiling;
  FindTilingFactorConv2D(I, A, tiling);

  if (I->getName() == "op_4") {
    //tiling["h"][0] = 26;
    //tiling["w"][0] = 26;
  }
  
  auto pair = loop_h->tile(tiling["h"][0]);
  LoopAxis* loop_h_0 = pair.first;
  LoopAxis* loop_h_1 = pair.second;
  pair = loop_w->tile(tiling["w"][0]);
  LoopAxis* loop_w_0 = pair.first;
  LoopAxis* loop_w_1 = pair.second;
  pair = loop_c->tile(tiling["c"][0]);
  LoopAxis* loop_c_0 = pair.first;
  LoopAxis* loop_c_1 = pair.second;
  pair = loop_k->tile(tiling["k"][0]);
  LoopAxis* loop_k_0 = pair.first;
  LoopAxis* loop_k_1 = pair.second;
  pair = loop_k_1->tile(tiling["k"][1]);
  LoopAxis* loop_k_1_0 = pair.first;
  LoopAxis* loop_k_1_1 = pair.second;
  std::vector<LoopAxis*> loopnest = 
  //  {loop_n, loop_h_0, loop_w_0, loop_c_0, loop_k_0, loop_r, loop_s, loop_h_1, loop_w_1, loop_k_1_0, loop_k_1_1, loop_c_1};
    {loop_n, loop_h_0, loop_w_0, loop_k_0, loop_c_0, loop_r, loop_s, loop_h_1, loop_w_1, loop_k_1_0, loop_k_1_1, loop_c_1};
  loop_r->isOnChip = true;
  loop_k_1_1->isParallel = true;
  loop_c_1->isParallel = true;
  auto idx_n = new AffineExpr(loop_n);
  auto idx_h = new AffineExpr(loop_h_0, loop_h_1);
  auto idx_w = new AffineExpr(loop_w_0, loop_w_1);
  auto idx_c = new AffineExpr(loop_c_0, loop_c_1);
  auto idx_k = new AffineExpr(loop_k_0, loop_k_1_0, loop_k_1_1);
  auto idx_r = new AffineExpr(loop_r);
  auto idx_s = new AffineExpr(loop_s);
  auto mx = I->getInput(0);
  mx->setAccessPattern(idx_n, idx_c, idx_h->add(idx_r), idx_w->add(idx_s));
  auto mw = I->getInput(1);
  mw->setAccessPattern(idx_k, idx_c, idx_r, idx_s);
  auto mb = I->getInput(2);
  mb->setAccessPattern(idx_k);
  auto my = I->getOutput(0);
  my->setAccessPattern(idx_n, idx_k, idx_h, idx_w);
  
  for (auto i = 0; i < loopnest.size(); i++) {
    //std::cout << loopnest[i]->toString(i) << "\n";  
  }
  loopmap values;
  LowerConv2dToInstruction(I, loopnest, values, 0);
  //BasicBlock *bb = I->getParent();
  //bb->removeInstruction(*I);
  //bb->dump(std::cout);
}

void LowerComplex::LowerConv2dToInstruction(Conv2dInst *I, std::vector<LoopAxis*>& loopnest, loopmap& values, int level) {
  BasicBlock *bb = I->getParent();
  AffineExpr* idx_h = I->getInput(0)->getAccessPattern(2);
  AffineExpr* idx_w = I->getInput(0)->getAccessPattern(3);
  AffineExpr* idx_c = I->getInput(0)->getAccessPattern(1);
  AffineExpr* idx_k = I->getInput(1)->getAccessPattern(0);
  AffineExpr* idx_ho = I->getOutput(0)->getAccessPattern(2);
  AffineExpr* idx_wo = I->getOutput(0)->getAccessPattern(3);
  LoopAxis* loop = loopnest[level];
  if (loop->isOnChip) {
    //std::cout << "[tile " << ++cnt << "]\n";
    //std::cout << values[loop] << "\n";
    // Find dim range for each tile
    for (int i = level; i < loopnest.size(); i++) 
      values[loopnest[i]] = loopnest[i]->getLb();
    int h_st = idx_h->eval(values);
    int w_st = idx_w->eval(values);
    int c_st = idx_c->eval(values);
    int k_st = idx_k->eval(values);
    int ho_st = idx_ho->eval(values);
    int wo_st = idx_wo->eval(values);
    for (int i = level; i < loopnest.size(); i++)
      values[loopnest[i]] = loopnest[i]->getUb() - 1;  // upbound is not included e.g., [0, 64)
    int h_ed = idx_h->eval(values) + 1;  // + 1 to get upbound
    int w_ed = idx_w->eval(values) + 1;
    int c_ed = idx_c->eval(values) + 1;
    int k_ed = idx_k->eval(values) + 1;
    int ho_ed = idx_ho->eval(values) + 1;
    int wo_ed = idx_wo->eval(values) + 1;
    h_ed = std::min(h_ed, I->h);
    w_ed = std::min(w_ed, I->w);
    c_ed = std::min(c_ed, I->c);
    k_ed = std::min(k_ed, I->k);
    ho_ed = std::min(ho_ed, (I->h - I->r + 1) / I->stride);
    wo_ed = std::min(wo_ed, (I->w - I->s + 1) / I->stride);
    if (h_ed - h_st < I->r || w_ed - w_st < I->s) return;

    h_st += I->getAttr("pre remove padding u");
    w_st += I->getAttr("pre remove padding l");
    ho_ed -= I->getAttr("pre remove padding u");
    wo_ed -= I->getAttr("pre remove padding l");

    //std::cout << "[" << h_st << ", " << h_ed << ")x";
    //std::cout << "[" << w_st << ", " << w_ed << ")\n";
    // Update ap of each memory location
    std::string name = "t_";
    for (auto i = 0; i < level; i++) name += std::to_string(values[loopnest[i]]) + "_";
    LoopAxis* loop_h = new LoopAxis(name + "h", h_st, h_ed, I->stride);
    LoopAxis* loop_w = new LoopAxis(name + "w", w_st, w_ed, I->stride);
    LoopAxis* loop_c = new LoopAxis(name + "c", c_st, c_ed);
    LoopAxis* loop_k = new LoopAxis(name + "k", k_st, k_ed);
    if (I->getAttr("pooling type") > 0) {
      ho_st = (ho_st / I->getAttr("pool stride r"));
      wo_st = (wo_st / I->getAttr("pool stride s"));
      ho_ed = std::ceil((float)(ho_ed - I->getAttr("pool size r") + 1) / I->getAttr("pool stride r"));
      wo_ed = std::ceil((float)(wo_ed - I->getAttr("pool size s") + 1) / I->getAttr("pool stride s"));
      //std::cout << "shape after pooling: ";
      //std::cout << "[" << ho_st << ", " << ho_ed << ")x";
      //std::cout << "[" << wo_st << ", " << wo_ed << ")\n";
    }
    if (I->getAttr("post padding")) {
      ho_st += I->getAttr("post padding size u");
      wo_st += I->getAttr("post padding size l");
      ho_ed += I->getAttr("post padding size u");
      wo_ed += I->getAttr("post padding size l");
    }
    LoopAxis* loop_ho = new LoopAxis(name + "ho", ho_st, ho_ed);
    LoopAxis* loop_wo = new LoopAxis(name + "wo", wo_st, wo_ed);
    auto idx_h = new AffineExpr(loop_h);
    auto idx_w = new AffineExpr(loop_w);    
    auto idx_c = new AffineExpr(loop_c);
    auto idx_k = new AffineExpr(loop_k);
    auto idx_ho = new AffineExpr(loop_ho);
    auto idx_wo = new AffineExpr(loop_wo);  
    MemoryLocation* mx = I->getInput(0)->clone();
    mx->setAP(1, idx_c);
    mx->setAP(2, idx_h);
    mx->setAP(3, idx_w);
    MemoryLocation* mw = I->getInput(1)->clone();
    mw->setAP(0, idx_k);
    mw->setAP(1, idx_c);
    MemoryLocation* mb = I->getInput(2)->clone();
    mb->setAP(0, idx_k);
    MemoryLocation* my = I->getOutput(0)->clone();
    my->setAP(1, idx_k);
    my->setAP(2, idx_ho);
    my->setAP(3, idx_wo);
    
    // Generate BIR instructions
    // Load 
    auto load_x = &bb->addInstruction<LoadInst>(name + "load_x");
    load_x->addInput(mx);
    MemoryLocation* mx_local = mx->clone();
    mx_local->setName(name + "fb");
    mx_local->setType(MemoryType::FB);
    load_x->addOutput(mx_local);

    auto load_w = &bb->addInstruction<LoadInst>(name + "load_w");
    load_w->addInput(mw);
    MemoryLocation* mw_local = mw->clone();
    mw_local->setName(name + "wb");
    mw_local->setType(MemoryType::WB);
    load_w->addOutput(mw_local);

    bool add_bias = c_st == 0;
    bool store_to_dram = c_ed == I->c;
    if (add_bias) {
      auto load_b = &bb->addInstruction<LoadInst>(name + "load_b");
      load_b->addInput(mb);
      MemoryLocation* mb_local = mb->clone();
      mb_local->setName(name + "bb");
      mb_local->setType(MemoryType::BB);
      load_b->addOutput(mb_local);
      // Compute
      auto compute = &bb->addInstruction<MatmultInst>(name + "matmult");
      compute->addInput(mx_local);
      compute->addInput(mw_local);
      compute->addInput(mb_local);
      MemoryLocation* psum = new MemoryLocation(name + "psum", MemoryType::PSUM);
      compute->addOutput(psum);
      compute->setStride(I->stride);
      // Dependency
      compute->addDependency(load_x);
      compute->addDependency(load_w);
      compute->addDependency(load_b);
      if (store_to_dram) {
        // Store
        auto store = &bb->addInstruction<StoreInst>(name + "store");
        store->addInput(psum);
        store->addOutput(my);
        store->addDependency(compute);
      }     
    } else {
      Instruction *pred_matmult = nullptr;
      for (auto &I : *bb) {
        if (llvm::isa<MatmultInst>(I)) {
          std::vector<std::pair<int, int>> wrange = I.getInput(1)->getAccessPatternRange();
          if (wrange[0].first == k_st &&
              wrange[0].second == k_ed &&
              wrange[1].second == c_st) {
            pred_matmult = &I;
          }
        }
      }
      MemoryLocation* psum = pred_matmult->getOutput(0);
      // Compute
      auto compute = &bb->addInstruction<MatmultInst>(name + "matmult");
      compute->addInput(mx_local);
      compute->addInput(mw_local);    
      compute->addInput(psum);
      compute->addOutput(psum);
      compute->setStride(I->stride);
      // Dependency
      compute->addDependency(load_x);
      compute->addDependency(load_w);
      compute->addDependency(pred_matmult);
      if (store_to_dram) {
        // Store
        auto store = &bb->addInstruction<StoreInst>(name + "store");
        store->addInput(psum);
        store->addOutput(my);
        store->addDependency(compute);
      }     
    }
    return;
  }
  for (int i = loop->lb; i < loop->ub; i += loop->stride) {
    values[loopnest[level]] = i;
    LowerConv2dToInstruction(I, loopnest, values, level + 1);  
  }
}