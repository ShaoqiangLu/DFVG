#ifndef LEGACYMC_H
#define LEGACYMC_H

#include <string>
#include <math.h>

#include "pass/MCBase.h"
#include "bir/Instruction.h"
#include "bir/BasicBlock.h"
#include "Arch.h"

/*! Mem ID constant: input feature map memory */
#define OPU_MEM_ID_FM 0
/*! Mem ID constant: kernel memory */
#define OPU_MEM_ID_WGT 1
/*! Mem ID constant: bias memory */
#define OPU_MEM_ID_BIAS 2
/*! Mem ID constant: residual memory */
#define OPU_MEM_ID_RESIDUAL 3
/*! Mem ID constant: instruction memory */
#define OPU_MEM_ID_INS 4

/*! DDR load trigger constant */
#define OPU_DDRLD_TRIG_DDRLD 0
// dma done here means the completion of multiple consecutive dmas
#define OPU_DDRLD_TRIG_DDRLD_DMA 1
#define OPU_DDRLD_TRIG_LAYER_START 2
#define OPU_DDRLD_TRIG_DDRST 3
#define OPU_DDRLD_TERMINATION 4
#define OPU_DDRLD_TRIG_BRAMST 5
#define OPU_DDRLD_TRIG_BRAMWB_DDRLD 6
#define OPU_DDRLD_TRIG_DDRLD_DDRST 7

/*! COMPUTE trigger constant */
#define OPU_DMA_TRIG_DMA 0
#define OPU_DMA_TRIG_DDRLD 1
#define OPU_DMA_TRIG_DMA_DDRLD 2
#define OPU_DMA_TRIG_DDRST_NOT_1_6 3
#define OPU_DMA_TERMINATION 4
#define OPU_DMA_TRIG_DDRST 5

/*! DDR store trigger constant */
#define OPU_DDRST_TRIG_BRAMST_DDRLD 0
#define OPU_DDRST_TRIG_DDRST 1
#define OPU_DDRST_TRIG_BRAMWB_DDRLD 3
#define OPU_DDRST_TRIG_DDRLD 4
#define OPU_DDRST_TRIG_DDRLD_DDRST 5
#define OPU_DDRST_TRIG_SINGLE_DDRLD 6

/*! Layer type constant */
#define OPU_LAYER_FC 0
#define OPU_LAYER_CONV2D 1
#define OPU_LAYER_SINGLE_POOL 2
#define OPU_LAYER_SE 3
#define OPU_LAYER_ZTCONV 4
#define OPU_LAYER_NTCONV 5
#define OPU_LAYER_CONV3D 6

/*! Copy mode for local input buffer of compute engine */
#define OPU_COPY_MODE_REP_8 0
#define OPU_COPY_MODE_REP_16 1
#define OPU_COPY_MODE_REP_32 2

/*! Actiovation type */
#define OPU_ACTIVATION_NONE 2
#define OPU_ACTIVATION_RELU 1
#define OPU_ACTIVATION_PRELU 0
#define OPU_ACTIVATION_HSIGMOID 3
#define OPU_ACTIVATION_HSWISH 4
#define OPU_ACTIVATION_LUT 5

/*! Pooling type */
#define OPU_POOL_NONE 0
#define OPU_POOL_MAX 1
#define OPU_POOL_AVG 2

/*! IPA output number */
#define OPU_IPA_OUT_NUM_2 0
#define OPU_IPA_OUT_NUM_4 1
#define OPU_IPA_OUT_NUM_8 2
#define OPU_IPA_OUT_NUM_16 3
#define OPU_IPA_OUT_NUM_32 4
#define OPU_IPA_OUT_NUM_64 5

/*! DDR write destination */
#define OPU_DDRST_TO_DDR 0
#define OPU_DDRST_TO_BRAM 1

class LegacyMC : public MachineCodeGenerator {
 public:
  void init();

  void run(BasicBlock &bb, Arch *A);
  void emitLayerGlobalRegTrace(BasicBlock &bb, Arch *A);
  void emitRegTrace(BasicBlock &bb);
  int emitLoadRegTrace(LoadInst *I);
  void emitMatmultRegTrace(MatmultInst *I, bool sync=true);
  void emitStoreRegTrace(StoreInst *I);
  void instMatch();
  void dump_txt(std::string filename);
  void dump_bin_txt(std::string filename);
  void emitRegTrace(std::vector<Instruction*>& insts, bool sync=true);
  void setTriggerCondition(BasicBlock &bb);
  void setSyncId(BasicBlock &bb);
  void findLastMatmult(BasicBlock &bb);
  void insertTerminationTriggerCondition(BasicBlock &bb);
  void emitLayerEnding(BasicBlock &bb);
  void emitTriggerCondition(Instruction *inst);
  void emitTermination(Instruction *inst);
  void setSync() {SetReg("sync", global_sync_id++);}
  
  int stride;
  int global_sync_id = 0;
  std::unordered_map<int, std::vector<Instruction*>> sync_map;
  std::unordered_map<Instruction*, Instruction*> next_engine_inst;

  bool has_pool = false;
  int pool_r;
  int pool_s;
  int pool_stride_r = 1;
  int pool_stride_s = 1;

  int padding = 0;
  int padding_size = 0;
  int padding_num = 0;

  MatmultInst* layer_last_matmult;

  void exportSimJson(BasicBlock &bb, std::ofstream &os);
};

#endif
