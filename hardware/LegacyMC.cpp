#include "pass/LegacyMC.h"
#include "pass/MachineInst.h"
#include "bir/Instruction.h"
#include "bir/Function.h"
#include "bir/MemoryLocation.h"
#include <llvm/Support/Casting.h>

#include "nlohmann/json.hpp"

using Mty = MachineInstType;
using namespace bir;

void LegacyMC::init() {
  auto r0 = DefReg("dw_flag", /*bit width*/1);
  auto r1 = DefReg("dma_block_y_size", 7);
  auto r2 = DefReg("dma_block_x_size", 7);
  auto r3 = DefReg("fm_in_y_size", 10);
  auto r4 = DefReg("fm_in_x_size", 10);
  auto r5 = DefReg("channel_out", 11);
  auto r6 = DefReg("channel_in", 11);
  auto r7 = DefReg("ddr_fm_addr_ini", 25);
  auto r8 = DefReg("ddr_ker_addr_ini", 25);
  auto r9 = DefReg("ddr_bias_addr_ini", 25);
  auto r10 = DefReg("ddr_res_addr_ini", 25);
  auto r11 = DefReg("ddr_fm_read_num", 15);
  auto r12 = DefReg("ddr_ker_read_num", 15);
  auto r13 = DefReg("ddr_bias_read_num", 15);
  auto r14 = DefReg("ddr_fm_save_num", 15);
  auto r15 = DefReg("ddr_load_single", 1);
  auto r16 = DefReg("ker_on_board", 6);
  auto r17 = DefReg("ddr_load_start_trig", 3);
  auto r18 = DefReg("ddr_load_start_dma_num", 9);
  auto r19 = DefReg("ddr_load_type", 5);
  auto r20 = DefReg("dma_start_trig", 3);
  auto r21 = DefReg("y_max", 7);
  auto r22 = DefReg("y_min", 4);
  auto r23 = DefReg("x_max", 7);
  auto r24 = DefReg("x_min", 4);
  auto r25 = DefReg("ker_y_size", 4);
  auto r26 = DefReg("ker_x_size", 4);
  auto r27 = DefReg("read_y_stride", 3);
  auto r28 = DefReg("read_x_stride", 3);
  auto r29 = DefReg("ker_repeat", 5);
  auto r30 = DefReg("type", 3);
  auto r31 = DefReg("ker_round", 6);
  auto r32 = DefReg("output_num", 3);
  auto r33 = DefReg("copy_mode", 2);
  auto r34 = DefReg("ker_repeat_last", 5);
  auto r35 = DefReg("dma_shift", 4);
  auto r36 = DefReg("dma_shift_dir", 1);
  auto r37 = DefReg("ker_addr_e", 6);
  auto r38 = DefReg("ker_addr_s", 6);
  auto r39 = DefReg("output_channel", 7);
  auto r40 = DefReg("output_final_block", 1);
  auto r41 = DefReg("final_output", 1);
  auto r42 = DefReg("add_temp", 1);
  auto r43 = DefReg("add_bias", 1);
  auto r44 = DefReg("shift_num", 5);
  auto r45 = DefReg("cut_pos", 5);
  auto r46 = DefReg("trig_output_start", 4);
  auto r47 = DefReg("shift_num_fm", 5);
  auto zero20 = DefZero(20);
  auto r48 = DefReg("ddr_write_choice", 1);
  auto r49 = DefReg("padding_size", 3);
  auto r50 = DefReg("activation_type", 4);
  auto r51 = DefReg("pooling_y_stride", 3);
  auto r52 = DefReg("pooling_x_stride", 3);
  auto r53 = DefReg("pooling_type", 2);
  auto r54 = DefReg("pooling_y_size", 4);
  auto r55 = DefReg("pooling_x_size", 4);
  auto r56 = DefReg("pooling_decrapated", 1);
  auto r57 = DefReg("ddr_save_pos", 2);
  auto r58 = DefReg("ddr_save_des", 1);
  auto r59 = DefReg("ddr_save_start_trig", 3);
  auto r60 = DefReg("block_pool_y_size", 7);
  auto r61 = DefReg("block_pool_x_size", 7);
  auto r62 = DefReg("residual", 1);
  auto r63 = DefReg("upsample_output", 1);
  auto r64 = DefReg("activation", 1);
  auto r65 = DefReg("pooling", 1);
  auto r66 = DefReg("padding", 1);
  auto r67 = DefReg("fm_output_addr_ini", 25);
  auto r68 = DefReg("ddr_ins_addr_ini", 25);
  auto r69 = DefReg("network_done", 1);
  auto r70 = DefReg("output_block_y_size", 7);
  auto r71 = DefReg("output_block_x_size", 7);
  auto r72 = DefReg("ddr_save_mask_63_50", 25);
  auto r73 = DefReg("ddr_save_mask_49_25", 25);
  auto r74 = DefReg("ddr_save_mask_24_0", 25);
  auto r75 = DefReg("pooling_padding_l", 3);
  auto r76 = DefReg("pooling_padding_r", 3);
  auto r77 = DefReg("pooling_padding_u", 3);
  auto r78 = DefReg("pooling_padding_d", 3);
  auto r79 = DefReg("ddr_load_block_y_size", 7);
  auto r80 = DefReg("ddr_load_block_x_size", 7);
  auto r81 = DefReg("average_pool_para", 8);
  auto r82 = DefReg("ddr_save_block_y_size", 7);
  auto r83 = DefReg("ddr_save_block_x_size", 7);
  auto r84 = DefReg("default_flag", 1);
  auto r85 = DefReg("out_y_max", 7);
  auto r86 = DefReg("out_y_min", 4);
  auto r87 = DefReg("out_x_max", 7);
  auto r88 = DefReg("out_x_min", 4);
  auto r89 = DefReg("out_y_stride", 7);
  auto r90 = DefReg("out_x_stride", 7);
  auto r91 = DefReg("SE_stage", 3);
  auto r92 = DefReg("SE_fc_in_num", 3);
  auto r93 = DefReg("SE_fc_out_num", 8);
  auto r94 = DefReg("SE_fc_out_num", 8);
  auto r95 = DefReg("SE_fc_out_num", 8);
  auto r96 = DefReg("fm_out_y_size", 10);
  auto r97 = DefReg("fm_out_x_size", 10);
  auto sync = DefReg("sync", 1);
  
  DefInst(Mty::SET, /*opcode*/0, r2, r1, r0); /*LSB -> MSB*/
  DefInst(Mty::SET, 1, r4, r3);
  DefInst(Mty::SET, 2, r6, r5);
  DefInst(Mty::SET, 3, r7);
  DefInst(Mty::SET, 4, r8);
  DefInst(Mty::SET, 5, r9);
  DefInst(Mty::SET, 6, r10);
  DefInst(Mty::SET, 7, r11);
  DefInst(Mty::SET, 8, r12);
  DefInst(Mty::SET, 9, r13);
  DefInst(Mty::SET, 10, r14);
  DefInst(Mty::SET, 11, r19, r18, r17, r16, r15);
  DefInst(Mty::SET, 12, r24, r23, r22, r21, r20);
  DefInst(Mty::SET, 13, r29, r28, r27, r26, r25);
  DefInst(Mty::SET, 14, r32, r31, r30);
  DefInst(Mty::SET, 15, r38, r37, r36, r35, r34, r33);
  DefInst(Mty::SET, 16, r46, r45, r44, r43, r42, r41, r40, r39);
  DefInst(Mty::SET, 17, r97, r96, r47);
  DefInst(Mty::SET, 18, r56, r55, r54, r53, r52, r51, r50, r49, r48);
  DefInst(Mty::SET, 19, r66, r65, r64, r63, r62, r61, r60, r59, r58, r57);
  DefInst(Mty::SET, 20, r67);
  DefInst(Mty::SET, 21, r68);
  DefInst(Mty::SET, 22, r69);
  DefInst(Mty::SET, 23, r71, r70);
  DefInst(Mty::SET, 24, r72);
  DefInst(Mty::SET, 25, r73);
  DefInst(Mty::SET, 26, r74);
  DefInst(Mty::SET, 27, r78, r77, r76, r75);
  DefInst(Mty::SET, 28, r80, r79);
  DefInst(Mty::SET, 29, r83, r82, r81);
  DefInst(Mty::SET, 30, r88, r87, r86, r85, r84);
  DefInst(Mty::SET, 31, r90, r89);
  DefInst(Mty::SET, 32, r93, r92, r91);
  //DefInst(Mty::SET, 33, r97, r96);
  
}

void LegacyMC::dump_txt(std::string filename) {
  std::stringstream ss;
  int i = 0;
  for (auto item : mc_bb) {
    MachineInst* mc_inst = item.first;
    ss << "opcode[" << mc_inst->opcode << "] set ";
    for (auto i = 0; i < item.second.size(); i++) {
      ss << mc_inst->fields[i]->GetName() << " " << item.second[i] << " ";
    }
    if (eob[i]) {
      ss << "immi " << 0 << "\n\n";
    } else {
      ss << "immi " << 1 << "\n";
    }
    i++;
  }
  //std::cout << ss.str() << "\n";
  std::ofstream os(filename, std::ofstream::out);
  os << ss.str();
  os.close();  
}

void LegacyMC::dump_bin_txt(std::string filename) {
  std::stringstream ss;
  int i = 0;
  for (auto item : mc_bb) {
    if (eob[i]) {
      ss << 0;
    } else {
      ss << 1;
    }
    MachineInst* mc_inst = item.first;
    mc_inst->values = item.second;
    ss << mc_inst->ToBinString() << "\n";
    i++;
  }
  std::ofstream os(filename, std::ofstream::out);
  os << ss.str();
  os.close();  
}

void LegacyMC::emitLayerGlobalRegTrace(BasicBlock &bb, Arch *A) {
  SetReg("network_done", 0); 
  SetReg("ddr_ins_addr_ini", A->dram_inst_addr_offset);
  
  bool has_activation = false;
  bool has_pool = false;
  int ho, wo, k_ub;
  Instruction *main = nullptr;
  for (auto *I : bb.complex_instructions) {
    std::cout << InstructionType2String(I->getOpcode()) << "\n";
    if (llvm::isa<Conv2dInst>(*I)) {
      auto conv2d = llvm::cast<Conv2dInst>(I);
      SetReg("fm_in_x_size", conv2d->w);
      SetReg("fm_in_y_size", conv2d->h);
      wo = ceil((float)(conv2d->w - I->getAttr("pre remove padding u") 
        - I->getAttr("pre remove padding d") - conv2d->s + 1) / conv2d->stride);
      ho = ceil((float)(conv2d->h - I->getAttr("pre remove padding l") 
        - I->getAttr("pre remove padding r") - conv2d->r + 1) / conv2d->stride);
      k_ub = conv2d->k;
      SetReg("channel_in", conv2d->c);
      SetReg("channel_out", conv2d->k);
      SetReg("ker_x_size", conv2d->r);
      SetReg("ker_y_size", conv2d->s);
      SetReg("ddr_load_start_dma_num", conv2d->r * conv2d->s);
      SetReg("read_x_stride", conv2d->stride);
      SetReg("read_y_stride", conv2d->stride);
      this->stride = conv2d->stride;
      SetReg("type", 1);
      SetReg("dw_flag", 0);
      SetReg("ker_repeat", 1);
      main = I;
    } else if (llvm::isa<ActivationInst>(*I)) {
      has_activation = true;
      auto act = llvm::cast<ActivationInst>(I);
      SetReg("activation", 1);  
      if (act->getType() == "ReLU") {
        SetReg("activation_type", OPU_ACTIVATION_RELU);
      } else {
        SetReg("activation_type", OPU_ACTIVATION_PRELU);  // leaky
      }
    } else if (llvm::isa<PoolingInst>(*I)) {
      has_pool = true;
      auto pool = llvm::cast<PoolingInst>(I);
      SetReg("pooling", 1);
      SetReg("average_pool_para", 0);
      SetReg("pooling_padding_u", 0); 
      SetReg("pooling_padding_d", 0);  
      SetReg("pooling_padding_l", 0);  
      SetReg("pooling_padding_r", 0);
      if (pool->getType() == "max") {
        SetReg("pooling_type", OPU_POOL_MAX);
      } else {
        SetReg("pooling_type", OPU_POOL_AVG);
      } 
      SetReg("pooling_x_size", pool->size_s);  
      SetReg("pooling_y_size", pool->size_r);  
      SetReg("pooling_x_stride", pool->stride_s);  
      SetReg("pooling_y_stride", pool->stride_r);
      wo = std::ceil(static_cast<float>(wo - pool->size_s + 1) / pool->stride_s);
      ho = std::ceil(static_cast<float>(ho - pool->size_r + 1) / pool->stride_r);
      this->has_pool = true;
      this->pool_r = pool->size_r;
      this->pool_s = pool->size_s;
      this->pool_stride_r = pool->stride_r;
      this->pool_stride_s = pool->stride_s;
    } else {
      std::cout << "[Abort] Unsupported InstructionType " 
        << InstructionType2String(I->getOpcode()) << "\n";
      //exit(1);
    }
  }
  if (!has_activation) {
    SetReg("activation", 0);  
    SetReg("activation_type", OPU_ACTIVATION_NONE);
  }
  
  if (!has_pool) {
    SetReg("pooling", 0);
    SetReg("average_pool_para", 0);
    SetReg("pooling_padding_u", 0); 
    SetReg("pooling_padding_d", 0);  
    SetReg("pooling_padding_l", 0);  
    SetReg("pooling_padding_r", 0);   
    SetReg("pooling_type", OPU_POOL_NONE);  
    SetReg("pooling_x_size", 1);  
    SetReg("pooling_y_size", 1);  
    SetReg("pooling_x_stride", 1);  
    SetReg("pooling_y_stride", 1);
    SetReg("block_pool_x_size", 0);
    SetReg("block_pool_y_size", 0);
  }
  if (main != nullptr) {
    // set from conv2d attrs later
    padding = main->getAttr("post padding");
    padding_size = main->getAttr("post padding size u");
    SetReg("padding_size", padding_size);
    ho += main->getAttr("post padding size u") + main->getAttr("post padding size d");
    wo += main->getAttr("post padding size l") + main->getAttr("post padding size r");
    padding_num = 
      wo * (main->getAttr("post padding size u") + main->getAttr("post padding size d")) +
      ho * (main->getAttr("post padding size l") + main->getAttr("post padding size r")) -
      main->getAttr("post padding size u") * main->getAttr("post padding size l") - 
      main->getAttr("post padding size u") * main->getAttr("post padding size r") - 
      main->getAttr("post padding size d") * main->getAttr("post padding size l") - 
      main->getAttr("post padding size d") * main->getAttr("post padding size r");
    padding_num *= std::ceil((float)k_ub / A->getElementsPerDRAMAddr());
    int pos = A->data_width_during_accumultation - (A->data_bytes * 8 - main->getAttr("output fraclen"));
    int cur_shift_num_fm = pos - (main->getAttr("weight fraclen") + main->getAttr("input fraclen"));
    int cur_shift_num = pos - main->getAttr("bias fraclen"); 
    assert(cur_shift_num_fm > 0);
		assert(cur_shift_num >= 0);
    SetReg("shift_num_fm", cur_shift_num_fm);
    SetReg("shift_num", cur_shift_num);
    SetReg("cut_pos", 0);
  }
  
  SetReg("padding", 0);
  SetReg("fm_out_x_size", wo);  // output size after post padding
  SetReg("fm_out_y_size", ho);
  SetReg("ddr_save_pos", main->getAttr("post order encoding"));
  SetReg("residual", 0);
  SetReg("ddr_load_single", 0);
  SetReg("upsample_output", 0);
  SetReg("ddr_save_des", 0); 
  SetReg("trig_output_start", 1);
  SetReg("pooling_decrapated", 0);
  SetReg("ker_repeat_last", 1);
  SetReg("dma_shift", 0);
  SetReg("dma_shift_dir", 0);
  SetReg("ddr_save_mask_63_50", 0);
  SetReg("ddr_save_mask_49_25", 0);
  SetReg("ddr_save_mask_24_0", 0);
  SetReg("ddr_write_choice", 0);
}

void LegacyMC::setSyncId(BasicBlock &bb) {
  // std::unordered_map<int, std::vector<Instruction*>>& sync_map
  int64_t clock = -1;
  int sync_id = 0;
  bool pred_load = false;
  std::unordered_map<std::string, Instruction*> ld_visited_;
  for (auto &I : bb) {
    if (I.isComplex()) continue;
    // merge loads for fm,weight,bias in codegen
    bool need_sync = true;
    if (llvm::isa<LoadInst>(I)) {
      std::string ld_des_s = MemoryType2String(I.getOutput(0)->getType());
      auto it = ld_visited_.find(ld_des_s);
      if (it == ld_visited_.end() && ld_visited_.size() > 0 && pred_load) {
        need_sync = false;
      } else {
        ld_visited_.clear();
      }
      ld_visited_[ld_des_s] = &I;
      pred_load = true;
    } else {
      pred_load = false;
    }
    // generate sync point according to scheduled clock (insert sync for new clock)
    if (I.getAttr("start cycle") != clock && need_sync) {
      clock = I.getAttr("start cycle");
      sync_id++;  
    }
    I.setAttr("sync id", sync_id);
    sync_map[sync_id].push_back(&I);
  }
}

void LegacyMC::setTriggerCondition(BasicBlock &bb) {
  // std::unordered_map<int, std::vector<Instruction*>>& sync_map
  int sync_id_max = sync_map.size();
  for (int id = 1; id <= sync_id_max; id++) {
    auto insts = sync_map[id];
    if (id == 1) {
      for (auto *inst : insts)
        inst->setAttr("trigger condition", OPU_DDRLD_TRIG_LAYER_START);
    } else {
      bool ld_in_pred = false;
      bool st_in_pred = false;
      bool c_in_pred = false;
      for (auto *inst : sync_map[id - 1]) {
        if (llvm::isa<LoadInst>(*inst))
          ld_in_pred = true;
        else if (llvm::isa<StoreInst>(*inst)) 
          st_in_pred = true;
        else if (llvm::isa<MatmultInst>(*inst))
          c_in_pred = true;
      }
      for (auto *inst : insts) {
        if (llvm::isa<LoadInst>(*inst)) {
          if (ld_in_pred && !c_in_pred && !st_in_pred) {
            inst->setAttr("trigger condition", OPU_DDRLD_TRIG_DDRLD);
          } else if (c_in_pred && ld_in_pred && !st_in_pred) {
            inst->setAttr("trigger condition", OPU_DDRLD_TRIG_DDRLD_DMA);
          } else if (st_in_pred && !c_in_pred && !ld_in_pred) {
            inst->setAttr("trigger condition", OPU_DDRLD_TRIG_DDRST);
          } else if (ld_in_pred && st_in_pred && !c_in_pred) {
            inst->setAttr("trigger condition", OPU_DDRLD_TRIG_DDRLD_DDRST);
          } else if (c_in_pred) {
            inst->setAttr("trigger condition", OPU_DDRLD_TRIG_DDRLD_DMA);
          } else {
            std::cout << "unexpected trigger for load\n";
            std::cout << id << "::" << ld_in_pred << ":" << st_in_pred << ":" << c_in_pred << "\n";
            exit(1);
          }
        } else if (llvm::isa<StoreInst>(*inst)) {
          if (ld_in_pred && st_in_pred && !c_in_pred) {
            inst->setAttr("trigger condition", OPU_DDRST_TRIG_DDRLD_DDRST);
          } else if (ld_in_pred && !st_in_pred && !c_in_pred) {
            inst->setAttr("trigger condition", OPU_DDRST_TRIG_DDRLD);
          } else if (!ld_in_pred && st_in_pred && !c_in_pred) {
            inst->setAttr("trigger condition", OPU_DDRST_TRIG_DDRST);
          } else if (/*ld_in_pred && */c_in_pred) {
            inst->setAttr("trigger condition", OPU_DDRST_TRIG_BRAMST_DDRLD); 
          } else {
            std::cout << "unexpected trigger for st\n";
            std::cout << ld_in_pred << ":" << st_in_pred << ":" << c_in_pred << "\n";
            std::cout << inst->toString() << "\n";
            exit(1);
          }
        } else if (llvm::isa<MatmultInst>(*inst)) {
          if (ld_in_pred && c_in_pred && !st_in_pred) {
            inst->setAttr("trigger condition", OPU_DMA_TRIG_DMA);//OPU_DMA_TRIG_DMA_DDRLD);
          } else if (ld_in_pred && !c_in_pred && !st_in_pred) {
            inst->setAttr("trigger condition", OPU_DMA_TRIG_DDRLD);
          } else if (c_in_pred && !ld_in_pred && !st_in_pred) {
            inst->setAttr("trigger condition", OPU_DMA_TRIG_DMA);
          } else if (st_in_pred && !c_in_pred && !ld_in_pred) {
            inst->setAttr("trigger condition", OPU_DMA_TRIG_DDRST_NOT_1_6);
          } else {
            std::cout << "unexpected trigger for compute\n";
            std::cout << ld_in_pred << ":" << st_in_pred << ":" << c_in_pred << "\n";
            std::cout << inst->toString() << "\n";
            exit(1);
          }
        }
      }
    }
  }
}

int LegacyMC::emitLoadRegTrace(LoadInst *inst) {   // TODO : when to load instruction?
  if (inst->hasAttr("trigger condition")) {
    //SetReg("ddr_load_start_trig", inst->getAttr("trigger condition"));
  }
  // Load from DRAM to on-chip buffer, we check each destination
  assert(inst->output.size() == 1);
  auto m = inst->getInput(0);
  auto mo = inst->getOutput(0);
  int type = 0;
  if (mo->getType() == MemoryType::FB) {
    // Get DRAM address to load + size
    SetReg("ddr_fm_addr_ini", m->getOffset());
    SetReg("ddr_fm_read_num", m->getStep() * m->getStepSize());
    SetReg("ddr_load_block_x_size", m->getStepSize());
    SetReg("ddr_load_block_y_size", m->getStep());
    type = OPU_MEM_ID_FM;
  } else if (mo->getType() == MemoryType::WB) {
    SetReg("ddr_ker_addr_ini", m->getOffset());
    SetReg("ddr_ker_read_num", m->getStepSize() * m->getStep());
    SetReg("ker_on_board", mo->getStepSize());  // TODO: not required for simulation but required for RTL to compare
    type = OPU_MEM_ID_WGT;
  } else if (mo->getType() == MemoryType::BB) {
    SetReg("ddr_bias_addr_ini", m->getOffset());
    SetReg("ddr_bias_read_num", m->getStepSize());
    type = OPU_MEM_ID_BIAS;
  }
  return 1 << type;
}

void LegacyMC::emitStoreRegTrace(StoreInst *inst) {
  if (inst->hasAttr("trigger condition")) {
    //SetReg("ddr_save_start_trig", inst->getAttr("trigger condition"));
  }
  auto mi = inst->getInput(0);  // psum
  SetReg("ddr_save_block_x_size", mi->getStepSize());  
  SetReg("ddr_save_block_y_size", mi->getStep());  
  auto m = inst->getOutput(0);
  SetReg("ddr_fm_save_num", m->getStep() * m->getStepSize());
  SetReg("fm_output_addr_ini", m->getOffset());  
}


void LegacyMC::emitMatmultRegTrace(MatmultInst *I, bool sync) {
  MemoryLocation *mx = nullptr;
  MemoryLocation *mw = nullptr;
  MemoryLocation *mb = nullptr;
  for (auto *m : I->input) {
    if (m->getType() == MemoryType::FB) {
      mx = m;
    } else if (m->getType() == MemoryType::WB) {
      mw = m;
    } else if (m->getType() == MemoryType::BB) {
      mb = m;
    } 
  }
  std::vector<std::pair<int, int>> range = mx->getAccessPatternRange();
  int c_max_local = range[1].second;
  int c = range[1].second - range[1].first;
  int h = range[2].second - range[2].first;
  int w = range[3].second - range[3].first;
  range = mw->getAccessPatternRange();
  int k = range[0].second - range[0].first;
  int r_lb = range[2].first;  // local idx e.g., [0:1) inside [0:3)
  int r_ub = range[2].second;
  int s_lb = range[3].first;
  int s_ub = range[3].second;
  auto wshape = mw->getTensorshape();
  int c_max = wshape[1];
  int r = wshape[2];
  int s = wshape[3];
  int ho = h / stride;
  int wo = w / stride;
  SetReg("dma_block_x_size", w + s - 1);
  SetReg("dma_block_y_size", h + r - 1);
  SetReg("output_block_x_size", wo);
  SetReg("output_block_y_size", ho);
  int wb_addr_offset = mw->getOffset();
  int wb_addr_cnt_per_rs = mw->getStepSize();
  SetReg("ker_addr_s", wb_addr_offset);
  SetReg("ker_addr_e", wb_addr_offset + wb_addr_cnt_per_rs - 1);
  int co_tile = I->getAttr("output_num");
  if (wshape[0] > co_tile) co_tile = 64;
  SetReg("output_channel", co_tile);  // k aligned
  SetReg("output_num", (int)std::log2((double)I->getAttr("output_num")) - 1);  // from scheduler
  SetReg("ker_round", I->getAttr("ker_round"));
  SetReg("copy_mode", (int)std::log2((double)I->getAttr("output_num")) - 4); // rep num = 8 << copy_mode
  if (this->has_pool) {
    SetReg("block_pool_x_size", std::ceil((float)(wo - this->pool_s + 1) / this->pool_stride_s));
    SetReg("block_pool_y_size", std::ceil((float)(ho - this->pool_r + 1) / this->pool_stride_r));
  }
  if (I->hasAttr("trigger condition")) {
    //SetReg("dma_start_trig", I->getAttr("trigger condition"));
  }
  SetReg("y_min", r_lb);
  SetReg("y_max", h + r_lb - 1);
  SetReg("x_min", s_lb);
  SetReg("x_max", w + s_lb - 1);
  if (r_lb == r - 1 && s_lb == s - 1 && (c_max == c_max_local /*|| c_max_local % 64 == 0*/)) {
    SetReg("final_output", 1);
  } else {
    SetReg("final_output", 0);
  }
  if (r_lb == r - 1 && s_lb == s - 1 && I == layer_last_matmult) {
    SetReg("output_final_block", 1);  // trigger layer_done on hardware
  } else {
    SetReg("output_final_block", 0);
  }
  if (mb != nullptr) {
    SetReg("add_bias", 1);
    SetReg("add_temp", 0); 
  } else {
    SetReg("add_bias", 0);
    SetReg("add_temp", 1); 
    SetReg("ddr_load_start_trig", OPU_DDRLD_TRIG_DDRST);  // 
  }
}

void LegacyMC::emitRegTrace(std::vector<Instruction*>& insts, bool sync) {
  int load_flag = 0;
  for (auto *inst : insts) {
    if (llvm::isa<LoadInst>(*inst)) {
      load_flag += emitLoadRegTrace(llvm::cast<LoadInst>(inst));
    } else if (llvm::isa<MatmultInst>(*inst)) {
      emitMatmultRegTrace(llvm::cast<MatmultInst>(inst), sync);
    } else if (llvm::isa<StoreInst>(*inst)) {
      emitStoreRegTrace(llvm::cast<StoreInst>(inst));
    }
  }
  if (load_flag != 0) {
    SetReg("ddr_load_type", load_flag);
  }
}

void LegacyMC::emitTriggerCondition(Instruction *inst) {
  if (inst->hasAttr("trigger condition")) {
    if (llvm::isa<LoadInst>(*inst)) {
      SetReg("ddr_load_start_trig", inst->getAttr("trigger condition"));
    } else if (llvm::isa<MatmultInst>(*inst)) {
      SetReg("dma_start_trig", inst->getAttr("trigger condition"));
    } else if (llvm::isa<StoreInst>(*inst)) {
      SetReg("ddr_save_start_trig", inst->getAttr("trigger condition"));
    }
  }
}

void LegacyMC::emitTermination(Instruction *inst) {
  if (llvm::isa<LoadInst>(*inst)) {
    SetReg("ddr_load_start_trig", OPU_DDRLD_TERMINATION);
  } else if (llvm::isa<MatmultInst>(*inst)) {
    SetReg("dma_start_trig", OPU_DMA_TERMINATION);
  } else if (llvm::isa<StoreInst>(*inst)) {
    SetReg("ddr_save_start_trig", 2);
  }
}

void LegacyMC::emitRegTrace(BasicBlock &bb) {
  // emit first load, compute, store
  std::unordered_map<std::string, std::vector<std::vector<Instruction*>>> queue;
  for (int id = 1; id <= sync_map.size(); id++) {
    std::unordered_map<std::string, std::vector<Instruction*>> tmp;
    for (auto *inst : sync_map[id]) {
      tmp[InstructionType2String(inst->getOpcode())].push_back(inst);
    }
    for (auto item : tmp) {
      queue[item.first].push_back(item.second);
    }
  }
  std::vector<std::string> engine_names;
  for (auto item : queue) {
    engine_names.push_back(item.first);
  }

  // 
  for (auto item : queue) {
    for (int i = 0; i < item.second.size() - 1; i++) {
      for (auto *inst : item.second[i]) {
        for (auto *next : item.second[i+1]) {
          next_engine_inst[inst] = next;
        }
      }
    }
  }

  // emit register assignment trace for first inst on each engine
  std::unordered_map<Instruction*, bool> emitted;
  for (auto name : engine_names) {
    auto &insts = queue[name].front();
    //emitRegTrace(insts, false);
    for (auto *inst : insts) {
      //emitted[inst] = true;
      emitTriggerCondition(inst);
    }
  }
  //SetReg("sync", global_sync_id++);
  
  
  // emit the rest along sync id
  for (int id = 1; id <= sync_map.size(); id++) {
    auto insts = sync_map[id];
    std::vector<Instruction*> tmp;
    for (auto *inst : insts) {
      if (emitted.find(inst) != emitted.end())
        continue;
      tmp.push_back(inst);
      emitted[inst] = true;
    }
    if (!tmp.empty()) {
      emitRegTrace(tmp);
      for (auto *inst : tmp) {
        emitTriggerCondition(inst);
      }
      bool has_load = false;
      bool has_store = false;
      bool has_mm = false;
      for (auto *inst : tmp) {
        if (llvm::isa<LoadInst>(*inst)) {
          has_load = true;
        } else if (llvm::isa<MatmultInst>(*inst)) {
          has_mm = true;
        } else if (llvm::isa<StoreInst>(*inst)) {
          has_store = true;
        }
      }
      if (!has_load) SetReg("ddr_load_start_trig", OPU_DDRLD_TERMINATION);
      if (!has_mm) {
        bool stop_matmult = true;
        if (stop_matmult) {
          SetReg("dma_start_trig", OPU_DMA_TERMINATION);
        }
      }
      //if (!has_store && /*this is hardcode*/id < sync_map.size() - 1) SetReg("ddr_save_start_trig", 2);
    } 
    SetReg("sync", global_sync_id++);
    //if (id == 3)break;
  } 
}

void LegacyMC::findLastMatmult(BasicBlock &bb) {
  for (auto &I : bb) {
    if (llvm::isa<MatmultInst>(I)) {
      layer_last_matmult = llvm::cast<MatmultInst>(&I);
    }
  }
}

void LegacyMC::insertTerminationTriggerCondition(BasicBlock &bb) {
  // std::vector<std::pair<Register*, int>> reg_trace
  std::vector<std::pair<Register*, int>>::iterator last_load_trig_it;
  auto it = reg_trace.begin();
  for (; it != reg_trace.end(); it++) {
    if (it->first->GetName() == "ddr_load_start_trig") {
      last_load_trig_it = it;
    }
  }
  for (it = last_load_trig_it; it != reg_trace.end(); it++) {
    if (it->first->GetName() == "sync") {
      it++;
      Register *reg = GetRegister("ddr_load_start_trig");
      reg_trace.insert(it, {reg, OPU_DDRLD_TERMINATION});
      break;
    }
  }
  /*std::vector<std::pair<Register*, int>>::iterator last_dma_trig_it;
  it = reg_trace.begin();
  for (; it != reg_trace.end(); it++) {
    if (it->first->GetName() == "dma_start_trig") {
      last_dma_trig_it = it;
    }
  }
  for (it = last_dma_trig_it; it != reg_trace.end(); it++) {
    if (it->first->GetName() == "sync") {
      it++;
      Register *reg = GetRegister("dma_start_trig");
      reg_trace.insert(it, {reg, OPU_DMA_TERMINATION});
      break;
    }
  }*/
}

void LegacyMC::emitLayerEnding(BasicBlock &bb) {
  //SetReg("ddr_load_start_trig", OPU_DDRLD_TERMINATION);
  //SetReg("dma_start_trig", OPU_DMA_TERMINATION);
  //SetReg("sync", global_sync_id++); 
  // post padding 
  if (padding == 1) {
    SetReg("ddr_save_start_trig", OPU_DDRST_TRIG_DDRST);  // last ins must be store
    SetReg("sync", global_sync_id++); 
    SetReg("padding", 1);
    SetReg("ddr_fm_save_num", padding_num);
    Function *f = bb.getParent();
    std::vector<MemoryLocation*> mem_locs = f->MemoryLocations();
    // assume only one output tensor for each layer
    for (auto &I : bb) {
      if (llvm::isa<StoreInst>(I)) {
        auto *mo = I.getOutput(0);
        for (auto *m : mem_locs) {
          if (m->getName() == mo->getName()) {
            SetReg("fm_output_addr_ini", m->getOffset());
            break;
          }
        }
        break;
      }
    }
    SetReg("sync", global_sync_id++); 
  }
  SetReg("ddr_save_start_trig", 2);
  //SetReg("network_done", 1);
  SetReg("sync", global_sync_id++); 
}



void LegacyMC::run(BasicBlock &bb, Arch *A) {
  sync_map.clear();
  reg_trace.clear();
  next_engine_inst.clear();

  findLastMatmult(bb);
  emitLayerGlobalRegTrace(bb, A);
  setSyncId(bb);
  setTriggerCondition(bb);
  emitRegTrace(bb);
  emitLayerEnding(bb);
  //instMatch();
  //dump_txt("output/isa_txt_" + bb.getName() + ".txt");
  //dump_bin_txt("output/isa_bin_txt_" + bb.getName() + ".txt");
}

void LegacyMC::instMatch() {
  std::unordered_map<int, bool> matched;
  for (auto i = 0; i< reg_trace.size(); i++) {
    matched[i] = false;
  }
  for (auto i = 0; i< reg_trace.size(); i++) {
    if (matched[i]) continue;
    Register* reg = reg_trace[i].first;
    std::string reg_name = reg->GetName();
    int value = reg_trace[i].second;
    //std::cout << "SET " << reg_name << " " << value << "\n";
    if (reg->GetValue() == value) continue;
    reg->value = value;
    if (reg_name == "sync") {
      eob.back() = true;
      continue;//break;
    }
    
    // greedily match the inst before the next sync point
    MachineInst* mc_inst = reg_inst_map_[reg_name];
    //std::cout << "  " << mc_inst->fields.size() << "\n";
    std::unordered_map<std::string, bool> visited;
    visited[reg_name] = true;
    std::string name_tmp = "";
    int j = i + 1;
    while (mc_inst->fields.size() >= 1) {
      Register* tmp = reg_trace[j].first;
      if (matched[j]) {
        j++;
        continue;
      }
      name_tmp = tmp->GetName();
      bool reach_sync = name_tmp == "sync";
      auto it = std::find(mc_inst->fields.begin(), mc_inst->fields.end(), tmp);
      if (it != mc_inst->fields.end() || reach_sync) {
        bool contradictive_value = (visited.find(name_tmp) != visited.end()) && (reg_trace[j].second != tmp->value);
        //std::cout << "  check " << name_tmp << "\n";
        if (visited.find(name_tmp) == visited.end() && !reach_sync) {
          visited[name_tmp] = true;
          tmp->value = reg_trace[j].second;
          matched[j] = true;
          //std::cout << "  in inst[" << mc_inst->opcode << "] and unvisited\n";
          //std::cout << "  " << visited.size() << "/" << mc_inst->fields.size() << "\n";
        }
        if (visited.size() == mc_inst->fields.size() ||
            contradictive_value ||
            reach_sync) {
          visited.clear();
          std::vector<int> vals;
          for (auto item : mc_inst->fields) {
            vals.push_back(item->value);
          }
          mc_bb.push_back({mc_inst, vals});
          eob.push_back(false);
          //std::cout << (visited.size() == mc_inst->fields.size()) << ":" << contradictive_value << ":" << reach_sync;
          //std::cout << " --> " << mc_inst->ToString() << "\n";
          break;
        }
      }
      if (reach_sync) break;
      j++;
    }

  }
}

using namespace nlohmann;

void LegacyMC::exportSimJson(BasicBlock &bb, std::ofstream &os) {
  for (int id = 1; id <= sync_map.size(); id++) {
    Instruction *load_x = nullptr;
    Instruction *load_w = nullptr;
    Instruction *load_b = nullptr;
    MemoryLocation *mx = nullptr;
    MemoryLocation *mw = nullptr;
    MemoryLocation *mb = nullptr;
    MemoryLocation *psum = nullptr;
    for (auto *inst : sync_map[id]) {
      if (llvm::isa<LoadInst>(*inst)) {
        MemoryLocation *mo = inst->getOutput(0);
        if (mo->getType() == MemoryType::FB) {
          load_x = inst;
        } else if (mo->getType() == MemoryType::WB) {
          load_w = inst;
        } else if (mo->getType() == MemoryType::BB) {
          load_b = inst;
        } else {
          assert(0);
        }
      } else if (llvm::isa<MatmultInst>(*inst)) {
        json j;
        j["opcode"] = "compute";
        j["name"] = inst->getName();
        j["sync id"] = inst->getAttr("sync id");
        j["basicblock name"] = bb.getName();
        for (auto *m : inst->input) {
          if (m->getType() == MemoryType::FB) {
            mx = m;
          } else if (m->getType() == MemoryType::WB) {
            mw = m;
          } else if (m->getType() == MemoryType::BB) {
            mb = m;
          } else if (m->getType() == MemoryType::PSUM) {
            psum = m;
          } else {
            assert(0);
          }
        }
        j["fm_bank_id"] = mx->getBankId();
        j["wgt_bank_id"] = mw->getBankId();
        if (mb != nullptr)
          j["bias_bank_id"] = mb->getBankId();
        int type = GetRegister("type")->GetValue();
        j["type"] = type;
        j["dw_flag"] = type == 2 ? true : false;
        int r = GetRegister("ker_x_size")->GetValue();
        int s = GetRegister("ker_y_size")->GetValue();
        j["ker_x_size"] = r;
        j["ker_y_size"] = s;
        std::vector<std::pair<int, int>> range = mx->getAccessPatternRange();
        int c_max_local = range[1].second;
        int c = range[1].second - range[1].first;
        int h = range[2].second - range[2].first;
        int w = range[3].second - range[3].first;
        range = mw->getAccessPatternRange();
        int k = range[0].second - range[0].first;
        int r_lb = range[2].first;  // local idx e.g., [0:1) inside [0:3)
        int r_ub = range[2].second;
        int s_lb = range[3].first;
        int s_ub = range[3].second;
        auto wshape = mw->getTensorshape();
        int c_max = wshape[1];
        int ho = h /  GetRegister("read_x_stride")->GetValue();
        int wo = w /  GetRegister("read_y_stride")->GetValue();
        j["dma_block_x_size"] = w + s - 1;
        j["dma_block_y_size"] = h + r - 1;
        j["read_x_stride"] = GetRegister("read_x_stride")->GetValue();
        j["read_y_stride"] = GetRegister("read_y_stride")->GetValue();
        j["y_min"] = r_lb;
        j["y_max"] = h + r_lb - 1;
        j["x_min"] = s_lb;
        j["x_max"] = w + s_lb - 1;
        j["copy_mode"] = (int)std::log2((double)inst->getAttr("output_num")) - 4;
        j["ker_round"] = inst->getAttr("ker_round");
        j["output_num"] = (int)std::log2((double)inst->getAttr("output_num")) - 1;
        j["output_channel"] = inst->getAttr("output_num")/*co tile*/ * inst->getAttr("ker_round");
        j["channel_out"] = GetRegister("channel_out")->GetValue();
        j["output_block_x_size"] = wo;
        j["output_block_y_size"] = ho;
        if (r_lb == r - 1 && s_lb == s - 1 && (c_max == c_max_local /*|| c_max_local % 64 == 0*/)) {
          j["final_output"] = true;
        } else {
          j["final_output"] = false;
        }
        if (mb != nullptr) {
          j["add_bias"] = true;
          j["add_temp"] = false; 
        } else {
          j["add_bias"] = false;
          j["add_temp"] = true; 
        }
        j["ker_addr_s"] = mw->getOffset();
        j["ker_addr_e"] = mw->getOffset() + mw->getStepSize() - 1;
        j["shift_num_fm"] = GetRegister("shift_num_fm")->GetValue();
        j["shift_num_bias"] = GetRegister("shift_num")->GetValue();
        /*
        j["ker_on_board"] = 0;
        j["ker_repeat"] = 1;
        j["ker_repeat_last"] = 1;
        */
        os << j << "\n";
      } else if (llvm::isa<StoreInst>(*inst)) {
        json j;
        j["opcode"] = "store";
        j["name"] = inst->getName();
        j["sync id"] = inst->getAttr("sync id");
        j["basicblock name"] = bb.getName();

        j["ddr_save_pos"] = 3;
        j["ddr_save_des"] = false;
        j["activation"] = static_cast<bool>(GetRegister("activation")->GetValue());
        j["activation_type"] = GetRegister("activation_type")->GetValue();
        j["pooling"] = static_cast<bool>(GetRegister("pooling")->GetValue());
        j["pooling_type"] = GetRegister("pooling_type")->GetValue();
        j["pooling_x_size"] = GetRegister("pooling_x_size")->GetValue();
        j["pooling_y_size"] = GetRegister("pooling_y_size")->GetValue();
        j["pooling_x_stride"] = GetRegister("pooling_x_stride")->GetValue();
        j["pooling_y_stride"] = GetRegister("pooling_y_stride")->GetValue();
        j["residual"] = static_cast<bool>(GetRegister("residual")->GetValue());
        //j["block_pool_x_size"] = GetRegister("block_pool_x_size")->GetValue();
        //j["block_pool_y_size"] = GetRegister("block_pool_y_size")->GetValue();
        j["fm_out_x_size"] = GetRegister("fm_out_x_size")->GetValue();
        j["fm_out_y_size"] = GetRegister("fm_out_y_size")->GetValue();
        j["channel_out"] = GetRegister("channel_out")->GetValue();
        j["upsample_output"] = static_cast<bool>(GetRegister("upsample_output")->GetValue());
        j["padding"] = false;
        j["padding_size"] = 0;
        auto mi = inst->getInput(0);  // psum
        j["ddr_save_block_x_size"] = mi->getStepSize();  
        j["ddr_save_block_y_size"] = mi->getStep();  
        auto m = inst->getOutput(0);
        j["ddr_save_fm_num"] = m->getStep() * m->getStepSize();
        j["fm_output_addr_ini"] = m->getOffset(); 
        os << j << "\n";
      }
    }
    // load
    json j;
    int type = 0;
    std::string load_name = "compound-load";
    int load_sync_id = 0;
    if (load_x != nullptr) {
      j["ddr_fm_addr_ini"] = load_x->getInput(0)->getOffset();
      j["ddr_fm_read_num"] = load_x->getInput(0)->getStep() * load_x->getInput(0)->getStepSize();
      j["ddr_load_block_x_size"] = load_x->getInput(0)->getStepSize();
      j["ddr_load_block_y_size"] = load_x->getInput(0)->getStep();
      j["fm_bank_id"] = static_cast<size_t>(load_x->getOutput(0)->getBankId());
      j["fm_in_y_size"] = GetRegister("fm_in_y_size")->GetValue();
      j["fm_in_x_size"] = GetRegister("fm_in_x_size")->GetValue();
      type += 1 << OPU_MEM_ID_FM;
      load_name += "-" + load_x->getName();
      load_sync_id = load_x->getAttr("sync id");
    }
    if (load_w != nullptr) {
      j["ddr_ker_addr_ini"] = load_w->getInput(0)->getOffset();
      j["ddr_ker_read_num"] = load_w->getInput(0)->getStepSize() * load_w->getInput(0)->getStep();
      j["ker_on_board"] = load_w->getInput(0)->getStepSize();  // TODO: not required for simulation but required for RTL to compare
      j["wgt_bank_id"] = static_cast<size_t>(load_w->getOutput(0)->getBankId());
      type += 1 << OPU_MEM_ID_WGT;
      load_name += "-" + load_w->getName();
      load_sync_id = load_w->getAttr("sync id");
    }
    if (load_b != nullptr) {
      j["ddr_bias_addr_ini"] = load_b->getInput(0)->getOffset();
      j["ddr_bias_read_num"] = load_b->getInput(0)->getStepSize();
      j["bias_bank_id"] = static_cast<size_t>(load_b->getOutput(0)->getBankId());
      type += 1 << OPU_MEM_ID_BIAS;
      load_name += "-" + load_b->getName();
      load_sync_id = load_b->getAttr("sync id");
    }
    j["ddr_load_single"] = static_cast<bool>(GetRegister("ddr_load_single")->GetValue());
    if (type > 0) {
      j["opcode"] = "load";
      j["name"] = load_name;
      j["sync id"] = load_sync_id;
      j["basicblock name"] = bb.getName();
      j["ddr_load_type"] = type;
      os << j << "\n";
    } 
  }
  // Post padding
  if (padding == 1) {
    json j;
    j["opcode"] = "store";
    j["name"] = bb.getName() + "-PostPadding";
    j["sync id"] = -1;
    j["basicblock name"] = bb.getName();

    j["ddr_save_pos"] = 3;
    j["ddr_save_des"] = false;
    j["activation"] = static_cast<bool>(GetRegister("activation")->GetValue());
    j["activation_type"] = GetRegister("activation_type")->GetValue();
    j["pooling"] = static_cast<bool>(GetRegister("pooling")->GetValue());
    j["pooling_type"] = GetRegister("pooling_type")->GetValue();
    j["pooling_x_size"] = GetRegister("pooling_x_size")->GetValue();
    j["pooling_y_size"] = GetRegister("pooling_y_size")->GetValue();
    j["pooling_x_stride"] = GetRegister("pooling_x_stride")->GetValue();
    j["pooling_y_stride"] = GetRegister("pooling_y_stride")->GetValue();
    j["residual"] = static_cast<bool>(GetRegister("residual")->GetValue());
    j["fm_out_x_size"] = GetRegister("fm_out_x_size")->GetValue();
    j["fm_out_y_size"] = GetRegister("fm_out_y_size")->GetValue();
    j["channel_out"] = GetRegister("channel_out")->GetValue();
    j["upsample_output"] = static_cast<bool>(GetRegister("upsample_output")->GetValue());
    j["padding"] = true;
    j["padding_size"] = GetRegister("padding_size")->GetValue();
    j["ddr_save_block_x_size"] = 0;  
    j["ddr_save_block_y_size"] = 0;  
    j["ddr_save_fm_num"] = padding_num;
    std::vector<MemoryLocation*> mem_locs = bb.getParent()->MemoryLocations();
    for (auto &I : bb) {
      if (llvm::isa<StoreInst>(I)) {
        auto *mo = I.getOutput(0);
        for (auto *m : mem_locs) {
          if (m->getName() == mo->getName()) {
            j["fm_output_addr_ini"] = m->getOffset();
            break;
          }
        }
        break;
      }
    }
    os << j << "\n";
  }
  json j;
  j["opcode"] = "barrier";
  os << j << "\n";
}