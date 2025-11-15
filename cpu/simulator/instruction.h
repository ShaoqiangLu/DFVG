#include <sstream>
#include <iostream>
#include <unordered_map>
#include <utility>
#include <vector>

#include "./hw_spec.h"

#ifndef FSIM_INSTRUCTION_H_
#define FSIM_INSTRUCTION_H_

/*
 * Register file
 */
class OPURegFile {
 public:
  // 0
  bool dw_flag;
  int dma_block_x_size;  // used to generate dma address with x/y min/max
  int dma_block_y_size;
  // 1
  int fm_in_y_size;
  int fm_in_x_size;
  // 2
  int channel_in;
  int channel_out;
  // 3-6
  int ddr_fm_addr_ini;
  int ddr_ker_addr_ini;
  int ddr_bias_addr_ini;
  int ddr_res_addr_ini;
  // 7-10
  // have extra ddr_load_block_x/y_size
  // this num value is just for upbound checking on hw
  int ddr_fm_read_num;
  int ddr_ker_read_num;
  int ddr_bias_read_num;
  int ddr_save_fm_num;
  // 11
  bool ddr_load_single;
  int ker_on_board;
  int ddr_load_start_trig;
  int ddr_load_start_dma_num;
  std::vector<int> ddr_load_type;
  // 12
  int dma_start_trig;
  int dma_y_max;
  int dma_y_min;
  int dma_x_max;
  int dma_x_min;
  // 13
  int ker_y_size;
  int ker_x_size;
  int read_y_stride;
  int read_x_stride;
  int ker_repeat;
  // 14
  int layer_type;
  int ker_round;
  int output_num;
  // 15
  int copy_mode;
  int ker_repeat_last;
  int ker_addr_e;
  int ker_addr_s;
  // 16
  int output_channel_tot;
  bool output_final_block;  // used to trigger layer_done
  bool final_output;  // output control -> cut to 8bit
  bool add_temp;
  bool add_bias;
  int shift_num_bias;
  int cut_pos;
  bool trig_output_start;  // more
  // 17
  int shift_num_fm;
  int fm_out_y_size;
  int fm_out_x_size;
  // 18
  bool ddr_write_choice;
  int padding_size;
  int activation_type;
  int pooling_y_stride;
  int pooling_x_stride;
  int pooling_type;
  int pooling_y_size;
  int pooling_x_size;
  // 19
  int ddr_save_pos;
  int ddr_save_des;
  int ddr_save_start_trig;
  int block_pool_x_size;
  int block_pool_y_size;
  bool residual;
  bool upsample_output;
  bool activation;
  bool pooling;
  bool padding;
  // 20-21
  int fm_output_addr_ini;
  int ddr_ins_addr_ini;
  // 22
  bool network_done;
  // 23
  int output_block_y_size;
  int output_block_x_size;
  // 24-26
  uint64_t ddr_save_mask;
  // 27
  int pooling_padding_l;
  int pooling_padding_r;
  int pooling_padding_u;
  int pooling_padding_d;
  // 28
  int ddr_load_block_y_size;
  int ddr_load_block_x_size;
  // 29
  int average_pool_para;
  int ddr_save_block_y_size;
  int ddr_save_block_x_size;
  // 30
  int out_y_max;
  int out_y_min;
  int out_x_max;
  int out_x_min;
  // 31
  int out_y_stride;
  int out_x_stride;
  // 32
  int se_stage;
  int se_fc_in_num;
  int se_fc_out_num;
};

/*
 * 32-bit short instruction
 */
class OPUShortInsn {
 public:
  uint32_t* data_;
  bool immi;
  uint32_t opcode;
  explicit OPUShortInsn(uint32_t data) {
    data_ = new uint32_t(data);
  }
  uint32_t GetOpcode();
  uint32_t BitSelect(uint32_t x, int s, int e);
  uint32_t BitSelect(uint32_t x, int idx);
  void Decode(OPURegFile* reg);
};

/*
 * Base class for complex instruction
 *   sub classes
 *     - OPUDDRLDInsn
 *     - OPUComputeInsn
 *     - OPUDDRSTInsn
 */
class OPUGenericInsn {
 public:
  std::unordered_map<OPUGenericInsn*, bool> pred_;
  std::vector<OPUGenericInsn*> succ_;
  std::vector<std::pair<void*, int>> assert_;

  void SetPred(std::vector<OPUGenericInsn*> pred);
  void SetAssert(std::vector<std::pair<void*, int>> pred_assert);

  virtual ~OPUGenericInsn() {}
  template<typename TargetName>
  inline bool IsInstance() {
    OPUGenericInsn* self = this;
    if (self != nullptr) {
      // dynamic_cast checks all the inheritance
      // thus inefficient when inhertance becomes complex
      // acceptable here since we only have three
      if (dynamic_cast<TargetName*>(self)) {
        return true;
      }
    }
    return false;
  }
};

class OPUDDRLDInsn : public OPUGenericInsn {
 public:
  // Load choices
  std::vector<int> ddr_load_type;
  // Load feature map from DDR
  int ddr_fm_addr_ini;
  int ddr_load_block_y_size;
  int ddr_load_block_x_size;
  int ddr_fm_read_num;
  int fm_in_y_size;
  int fm_in_x_size;
  // Load weight from DDR
  int ddr_ker_addr_ini;
  int ddr_ker_read_num;
  // Load bias from DDR
  int ddr_bias_addr_ini;
  int ddr_bias_read_num;
  // Load residual
  bool ddr_load_single;

  void ReadFrom(OPURegFile* reg) {
    ddr_load_type = reg->ddr_load_type;
    ddr_fm_addr_ini = reg->ddr_fm_addr_ini;
    ddr_load_block_y_size = reg->ddr_load_block_y_size;
    ddr_load_block_x_size = reg->ddr_load_block_x_size;
    ddr_fm_read_num = reg->ddr_fm_read_num;
    fm_in_y_size = reg->fm_in_y_size;
    fm_in_x_size = reg->fm_in_x_size;
    ddr_ker_addr_ini = reg->ddr_ker_addr_ini;
    ddr_ker_read_num = reg->ddr_ker_read_num;
    ddr_bias_addr_ini = reg->ddr_bias_addr_ini;
    ddr_bias_read_num = reg->ddr_bias_read_num;
    ddr_load_single = reg->ddr_load_single;
  }
};

class OPUComputeInsn : public OPUGenericInsn {
 public:
   // number of pe
  int pe_num;
  int type;
  // Data fetch (line buffer)
  bool dw_flag;
  int ker_x_size;
  int ker_y_size;
  // Data fetch (regular mode)
  int dma_block_x_size;
  int dma_block_y_size;
  int dma_x_min;
  int dma_x_max;
  int read_x_stride;
  int dma_y_min;
  int dma_y_max;
  int read_y_stride;
  int copy_mode;
  int ker_round;
  int ker_on_board;
  int ker_repeat;
  int ker_repeat_last;
  int ker_addr_s;
  int ker_addr_e;
  // Output control
  int output_num;
  int channel_out;
  int output_channel;  // for output control : 64
  int shift_num_fm;
  int shift_num_bias;
  bool add_bias;
  bool add_temp;
  bool final_output;
  int output_block_y_size;
  int output_block_x_size;

  void ReadFrom(OPURegFile* reg) {
    type = reg->layer_type;
    dw_flag = reg->dw_flag;
    ker_x_size = reg->ker_x_size;
    ker_y_size = reg->ker_y_size;
    dma_block_x_size = reg->dma_block_x_size;
    dma_block_y_size = reg->dma_block_y_size;
    dma_x_min = reg->dma_x_min;
    dma_x_max = reg->dma_x_max;
    read_x_stride = reg->read_x_stride;
    dma_y_min = reg->dma_y_min;
    dma_y_max = reg->dma_y_max;
    read_y_stride = reg->read_y_stride;
    copy_mode = reg->copy_mode;
    ker_round = reg->ker_round;
    ker_on_board = reg->ker_on_board;
    ker_repeat = reg->ker_repeat;
    ker_repeat_last = reg->ker_repeat_last;
    ker_addr_s = reg->ker_addr_s;
    ker_addr_e = reg->ker_addr_e;
    output_num = reg->output_num;
    channel_out = reg->channel_out;
    shift_num_fm = reg->shift_num_fm;
    shift_num_bias = reg->shift_num_bias;
    add_bias = reg->add_bias;
    add_temp = reg->add_temp;
    final_output = reg->final_output;
    output_channel = reg->output_channel_tot;
    output_block_y_size = reg->output_block_y_size;
    output_block_x_size = reg->output_block_x_size;
  }

  int fm_ram_id;
  int wgt_ram_id;
  int bias_ram_id;
  void SwitchUpdate(int fid, int wid, int bid) {
    fm_ram_id = fid;
    wgt_ram_id = wid;
    bias_ram_id = bid;
  }
  void FmSwitchUpdate(int fid) {
    fm_ram_id = fid;
  }
  void WgtSwitchUpdate(int wid) {
    wgt_ram_id = wid;
  }
  void BiasSwitchUpdate(int bid) {
    bias_ram_id = bid;
  }
};

class OPUDDRSTInsn : public OPUGenericInsn {
 public:
  // Post processing order
  int ddr_save_pos;
  // Actiovation
  bool activation;
  int activation_type;
  // Pooling
  bool pooling;
  int pooling_type;
  int pooling_x_size;
  int pooling_y_size;
  int pooling_x_stride;
  int pooling_y_stride;
  // Residual
  bool residual;
  // Store
  int ddr_save_block_x_size;
  int ddr_save_block_y_size;
  int block_pool_x_size;
  int block_pool_y_size;
  int fm_output_addr_ini;
  int ddr_save_fm_num;
  int ddr_save_des;
  // Padding
  int padding;
  int padding_size;
  int fm_out_x_size;
  int fm_out_y_size;
  int channel_out;
  // Upsampling
  bool upsample_output;
  int out_y_max;
  int out_y_min;
  int out_x_max;
  int out_x_min;
  int out_y_stride;
  int out_x_stride;

  void ReadFrom(OPURegFile* reg) {
    ddr_save_pos = reg->ddr_save_pos;
    activation = reg->activation;
    activation_type = reg->activation_type;
    pooling = reg->pooling;
    pooling_type = reg->pooling_type;
    pooling_x_size = reg->pooling_x_size;
    pooling_y_size = reg->pooling_y_size;
    pooling_x_stride = 
      reg->pooling_x_stride == 0 ? 1 : reg->pooling_x_stride;
    pooling_y_stride = 
      reg->pooling_y_stride == 0 ? 1 : reg->pooling_y_stride;
    residual = reg->residual;
    ddr_save_block_x_size = reg->ddr_save_block_x_size;
    ddr_save_block_y_size = reg->ddr_save_block_y_size;
    block_pool_x_size = reg->block_pool_x_size;
    block_pool_y_size = reg->block_pool_y_size;
    fm_output_addr_ini = reg->fm_output_addr_ini;
    ddr_save_fm_num = reg->ddr_save_fm_num;
    ddr_save_des = reg->ddr_save_des;
    padding = reg->padding;
    padding_size = reg->padding_size;
    fm_out_x_size = reg->fm_out_x_size;
    fm_out_y_size = reg->fm_out_y_size;
    channel_out = reg->channel_out;
    upsample_output = reg->upsample_output;
    out_y_max = reg->out_y_max;
    out_y_min = reg->out_y_min;
    out_x_max = reg->out_x_max;
    out_x_min = reg->out_x_min;
    out_y_stride = reg->out_y_stride;
    out_x_stride = reg->out_x_stride;
  }
};

#endif  // FSIM_INSTRUCTION_H_
