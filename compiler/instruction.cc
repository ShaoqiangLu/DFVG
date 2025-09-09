#include "./instruction.h"

uint32_t OPUShortInsn::GetOpcode() {
  return *data_ & 0x3F;
}
uint32_t OPUShortInsn::BitSelect(uint32_t x, int idx) {
  return BitSelect(x, idx, idx);
}

uint32_t OPUShortInsn::BitSelect(uint32_t x, int s, int e) {
  uint32_t mask = 0xFFFFFFFF;
  mask = ~((mask << (s+1)) | ~(mask << e));
  return (mask & x) >> e;
}

void OPUShortInsn::Decode(OPURegFile* reg) {
  std::stringstream os;
  immi = static_cast<bool>((*data_ & (1 << 31)) >> 31);
  opcode = GetOpcode();
  os << "***DECODE***\n";
  os << "OPCODE: " << opcode << "\n";
  switch (opcode) {
    case 0:
      reg->dw_flag = static_cast<bool>(BitSelect(*data_, 20));
      reg->dma_block_x_size = static_cast<int>(BitSelect(*data_, 12, 6));
      reg->dma_block_y_size = static_cast<int>(BitSelect(*data_, 19, 13));
      os << "dw_flag: " << reg->dw_flag << "\n";
      os << "dma_block_y_size: " << reg->dma_block_y_size << "\n";
      os << "dma_block_x_size: " << reg->dma_block_x_size << "\n";
      break;
    case 1:
      reg->fm_in_y_size = static_cast<int>(BitSelect(*data_, 29, 18));
      reg->fm_in_x_size = static_cast<int>(BitSelect(*data_, 17, 6));
      os << "fm_in_y_size: " << reg->fm_in_y_size << "\n";
      os << "fm_in_x_size: " << reg->fm_in_x_size << "\n";
      break;
    case 2:
      reg->channel_out = static_cast<int>(BitSelect(*data_, 27, 17));
      reg->channel_in = static_cast<int>(BitSelect(*data_, 16, 6));
      os << "channel_out: " << reg->channel_out << "\n";
      os << "channel_in: " << reg->channel_in << "\n";
      break;
    case 3:
      reg->ddr_fm_addr_ini = static_cast<int>(BitSelect(*data_, 30, 6));
      os << "ddr_fm_addr_ini: " << reg->ddr_fm_addr_ini << "\n";
      break;
    case 4:
      reg->ddr_ker_addr_ini = static_cast<int>(BitSelect(*data_, 30, 6));
      os << "ddr_ker_addr_ini: " << reg->ddr_ker_addr_ini << "\n";
      break;
    case 5:
      reg->ddr_bias_addr_ini = static_cast<int>(BitSelect(*data_, 30, 6));
      os << "ddr_bias_addr_ini: " << reg->ddr_bias_addr_ini << "\n";
      break;
    case 6:
      reg->ddr_res_addr_ini = static_cast<int>(BitSelect(*data_, 30, 6));
      os << "ddr_res_addr_ini: " << reg->ddr_res_addr_ini << "\n";
      break;
    case 7:
      reg->ddr_fm_read_num = static_cast<int>(BitSelect(*data_, 20, 6));
      os << "ddr_fm_read_num: " << reg->ddr_fm_read_num << "\n";
      break;
    case 8:
      reg->ddr_ker_read_num = static_cast<int>(BitSelect(*data_, 20, 6));
      os << "ddr_ker_read_num: " << reg->ddr_ker_read_num << "\n";
      break;
    case 9:
      reg->ddr_bias_read_num = static_cast<int>(BitSelect(*data_, 20, 6));
      os << "ddr_bias_read_num: " << reg->ddr_bias_read_num << "\n";
      break;
    case 10:
      reg->ddr_save_fm_num = static_cast<int>(BitSelect(*data_, 20, 6));
      os << "ddr_save_fm_num: " << reg->ddr_save_fm_num << "\n";
      break;
    case 11:
      reg->ddr_load_single = static_cast<bool>(BitSelect(*data_, 29));
      reg->ker_on_board = static_cast<int>(BitSelect(*data_, 28, 23));
      reg->ddr_load_start_trig = static_cast<int>(BitSelect(*data_, 22, 20));
      reg->ddr_load_start_dma_num = static_cast<int>(BitSelect(*data_, 19, 11));
      reg->ddr_load_type.clear();
      if (BitSelect(*data_, 10, 6) & 0x1) {
        reg->ddr_load_type.push_back(OPU_MEM_ID_FM);
      }
      if (BitSelect(*data_, 10, 6) & 0x2) {
        reg->ddr_load_type.push_back(OPU_MEM_ID_WGT);
      }
      if (BitSelect(*data_, 10, 6) & 0x4) {
        reg->ddr_load_type.push_back(OPU_MEM_ID_BIAS);
      }
      if (BitSelect(*data_, 10, 6) & 0x8) {
        reg->ddr_load_type.push_back(OPU_MEM_ID_RESIDUAL);
      }
      if (BitSelect(*data_, 10, 6) & 0x10) {
        reg->ddr_load_type.push_back(OPU_MEM_ID_INS);
      }
      os << "ddr_load_single: " << reg->ddr_load_single << "\n";
      os << "ker_on_board: " << reg->ker_on_board << "\n";
      os << "ddr_load_start_trig: " << reg->ddr_load_start_trig << "\n";
      os << "ddr_load_start_dma_num: " << reg->ddr_load_start_dma_num << "\n";
      os << "ddr_load_type: " << BitSelect(*data_, 10, 6) << "\n";
      break;
    case 12:
      reg->dma_start_trig = static_cast<int>(BitSelect(*data_, 30, 28));
      reg->dma_y_max = static_cast<int>(BitSelect(*data_, 27, 21));
      reg->dma_y_min = static_cast<int>(BitSelect(*data_, 20, 17));
      reg->dma_x_max = static_cast<int>(BitSelect(*data_, 16, 10));
      reg->dma_x_min = static_cast<int>(BitSelect(*data_, 9, 6));
      os << "dma_start_trig: " << reg->dma_start_trig << "\n";
      os << "dma_y_max: " << reg->dma_y_max << "\n";
      os << "dma_y_min: " << reg->dma_y_min << "\n";
      os << "dma_x_max: " << reg->dma_x_max << "\n";
      os << "dma_x_min: " << reg->dma_x_min << "\n";
      break;
    case 13:
      reg->ker_y_size = static_cast<int>(BitSelect(*data_, 24, 21));
      reg->ker_x_size = static_cast<int>(BitSelect(*data_, 20, 17));
      reg->read_y_stride = static_cast<int>(BitSelect(*data_, 16, 14));
      reg->read_x_stride = static_cast<int>(BitSelect(*data_, 13, 11));
      reg->ker_repeat = static_cast<int>(BitSelect(*data_, 10, 6));
      os << "ker_y_size: " << reg->ker_y_size << "\n";
      os << "ker_x_size: " << reg->ker_x_size << "\n";
      os << "read_y_stride: " << reg->read_y_stride << "\n";
      os << "read_x_stride: " << reg->read_x_stride << "\n";
      os << "ker_repeat: " << reg->ker_repeat << "\n";
      break;
    case 14:
      reg->layer_type = static_cast<int>(BitSelect(*data_, 17, 15));
      reg->ker_round = static_cast<int>(BitSelect(*data_, 14, 9));
      reg->output_num = static_cast<int>(BitSelect(*data_, 8, 6));
      os << "layer_type: " << reg->layer_type << "\n";
      os << "ker_round: " << reg->ker_round << "\n";
      os << "output_num: " << reg->output_num << "\n";
      break;
    case 15:
      reg->copy_mode = static_cast<int>(BitSelect(*data_, 29, 28));
      reg->ker_repeat_last = static_cast<int>(BitSelect(*data_, 27, 23));
      reg->ker_addr_e = static_cast<int>(BitSelect(*data_, 17, 12));
      reg->ker_addr_s = static_cast<int>(BitSelect(*data_, 11, 6));
      os << "copy_mode: " << reg->copy_mode << "\n";
      os << "ker_repeat_last: " << reg->ker_repeat_last << "\n";
      os << "ker_addr_e: " << reg->ker_addr_e << "\n";
      os << "ker_addr_s: " << reg->ker_addr_s << "\n";
      break;
    case 16:
      reg->output_channel_tot = static_cast<int>(BitSelect(*data_, 30, 24));
      reg->output_final_block = static_cast<bool>(BitSelect(*data_, 23));
      reg->final_output = static_cast<bool>(BitSelect(*data_, 22));
      reg->add_temp = static_cast<bool>(BitSelect(*data_, 21));
      reg->add_bias = static_cast<bool>(BitSelect(*data_, 20));
      reg->shift_num_bias = static_cast<int>(BitSelect(*data_, 19, 15));
      reg->cut_pos = static_cast<int>(BitSelect(*data_, 14, 10));
      // RTL 1 bit only?
      reg->trig_output_start = static_cast<int>(BitSelect(*data_, 9, 6));
      os << "output_channel: " << reg->output_channel_tot << "\n";
      os << "output_final_block: " << reg->output_final_block << "\n";
      os << "final_output: " << reg->final_output << "\n";
      os << "add_temp: " << reg->add_temp << "\n";
      os << "add_bias: " << reg->add_bias << "\n";
      os << "shift_num: " << reg->shift_num_bias << "\n";
      os << "cut_pos: " << reg->cut_pos << "\n";
      os << "trig_output_start: " << reg->trig_output_start << "\n";
      break;
    case 17:
      reg->shift_num_fm = static_cast<int>(BitSelect(*data_, 30, 26));
      os << "shift_num_fm: " << reg->shift_num_fm << "\n";
      /*reg->fm_out_y_size = static_cast<int>(BitSelect(*data_, 25, 16));
      reg->fm_out_x_size = static_cast<int>(BitSelect(*data_, 15, 6));
      os << "fm_out_y_size: " << reg->fm_out_y_size << "\n";
      os << "fm_out_x_size: " << reg->fm_out_x_size << "\n";*/
      break;
    case 33:
      reg->fm_out_y_size = static_cast<int>(BitSelect(*data_, 29, 18));
      reg->fm_out_x_size = static_cast<int>(BitSelect(*data_, 17, 6));
      os << "fm_out_y_size: " << reg->fm_out_y_size << "\n";
      os << "fm_out_x_size: " << reg->fm_out_x_size << "\n";
      break;
    case 18:
      reg->ddr_write_choice = static_cast<bool>(BitSelect(*data_, 30));
      reg->padding_size = static_cast<int>(BitSelect(*data_, 29, 27));
      reg->activation_type = static_cast<int>(BitSelect(*data_, 26, 23));
      reg->pooling_y_stride = static_cast<int>(BitSelect(*data_, 22, 20));
      reg->pooling_x_stride = static_cast<int>(BitSelect(*data_, 19, 17));
      reg->pooling_type = static_cast<int>(BitSelect(*data_, 16, 15));
      reg->pooling_y_size = static_cast<int>(BitSelect(*data_, 14, 11));
      reg->pooling_x_size = static_cast<int>(BitSelect(*data_, 10, 7));
      os << "ddr_write_choice: " << reg->ddr_write_choice << "\n";
      os << "padding_size: " << reg->padding_size << "\n";
      os << "activation_type: " << reg->activation_type << "\n";
      os << "pooling_y_stride: " << reg->pooling_y_stride << "\n";
      os << "pooling_x_stride: " << reg->pooling_x_stride << "\n";
      os << "pooling_type: " << reg->pooling_type << "\n";
      os << "pooling_y_size: " << reg->pooling_y_size << "\n";
      os << "pooling_x_size: " << reg->pooling_x_size << "\n";
      break;
    case 19:
      reg->ddr_save_pos = static_cast<int>(BitSelect(*data_, 30, 29));
      reg->ddr_save_des = static_cast<bool>(BitSelect(*data_, 28));
      reg->ddr_save_start_trig = static_cast<int>(BitSelect(*data_, 27, 25));
      reg->block_pool_y_size = static_cast<int>(BitSelect(*data_, 24, 18));
      reg->block_pool_x_size = static_cast<int>(BitSelect(*data_, 17, 11));
      reg->residual = static_cast<bool>(BitSelect(*data_, 10));
      reg->upsample_output = static_cast<bool>(BitSelect(*data_, 9));
      reg->activation = static_cast<bool>(BitSelect(*data_, 8));
      reg->pooling = static_cast<bool>(BitSelect(*data_, 7));
      reg->padding = static_cast<bool>(BitSelect(*data_, 6));
      os << "ddr_save_pos: " << reg->ddr_save_pos << "\n";
      os << "ddr_save_des: " << reg->ddr_save_des << "\n";
      os << "ddr_save_start_trig: " << reg->ddr_save_start_trig << "\n";
      os << "block_pool_y_size: " << reg->block_pool_y_size << "\n";
      os << "block_pool_x_size: " << reg->block_pool_x_size << "\n";
      os << "residual: " << reg->residual << "\n";
      os << "upsample_output: " << reg->upsample_output << "\n";
      os << "activation: " << reg->activation << "\n";
      os << "pooling: " << reg->pooling << "\n";
      os << "padding: " << reg->padding << "\n";
      break;
    case 20:
      reg->fm_output_addr_ini = static_cast<int>(BitSelect(*data_, 30, 6));
      os << "fm_output_addr_ini: " << reg->fm_output_addr_ini << "\n";
      break;
    case 21:
      reg->ddr_ins_addr_ini = static_cast<int>(BitSelect(*data_, 30, 6));
      os << "ddr_ins_addr_ini: " << reg->ddr_ins_addr_ini << "\n";
      break;
    case 22:
      reg->network_done = static_cast<bool>(BitSelect(*data_, 6));
      os << "network_done: " << reg->network_done << "\n";
      break;
    case 23:
      reg->output_block_y_size = static_cast<int>(BitSelect(*data_, 19, 13));
      reg->output_block_x_size = static_cast<int>(BitSelect(*data_, 12, 6));
      os << "output_block_y_size: " << reg->output_block_y_size << "\n";
      os << "output_block_x_size: " << reg->output_block_x_size << "\n";
      break;
    case 24:
      reg->ddr_save_mask |=
        static_cast<uint64_t>(BitSelect(*data_, 30, 6)) << 39;
      os << "ddr_save_mask[63:39]: " << BitSelect(*data_, 30, 6) << "\n";
      break;
    case 25:
      reg->ddr_save_mask |=
        static_cast<uint64_t>(BitSelect(*data_, 30, 6)) << 14;
      os << "ddr_save_mask[38:14]: " << BitSelect(*data_, 30, 6) << "\n";
      break;
    case 26:
      reg->ddr_save_mask |=
        static_cast<uint64_t>(BitSelect(*data_, 19, 6));
      os << "ddr_save_mask[13:0]: " << BitSelect(*data_, 19, 6) << "\n";
      break;
    case 27:
      reg->pooling_padding_l = static_cast<int>(BitSelect(*data_, 17, 15));
      reg->pooling_padding_r = static_cast<int>(BitSelect(*data_, 14, 12));
      reg->pooling_padding_u = static_cast<int>(BitSelect(*data_, 11, 9));
      reg->pooling_padding_d = static_cast<int>(BitSelect(*data_, 8, 6));
      os << "pooling_padding_l: " << reg->pooling_padding_l << "\n";
      os << "pooling_padding_r: " << reg->pooling_padding_r << "\n";
      os << "pooling_padding_u: " << reg->pooling_padding_u << "\n";
      os << "pooling_padding_d: " << reg->pooling_padding_d << "\n";
      break;
    case 28:
      reg->ddr_load_block_y_size = static_cast<int>(BitSelect(*data_, 19, 13));
      reg->ddr_load_block_x_size = static_cast<int>(BitSelect(*data_, 12, 6));
      os << "ddr_load_block_y_size: " << reg->ddr_load_block_y_size << "\n";
      os << "ddr_load_block_x_size: " << reg->ddr_load_block_x_size << "\n";
      break;
    case 29:
      reg->average_pool_para = static_cast<int>(BitSelect(*data_, 27, 20));
      reg->ddr_save_block_y_size = static_cast<int>(BitSelect(*data_, 19, 13));
      reg->ddr_save_block_x_size = static_cast<int>(BitSelect(*data_, 12, 6));
      os << "average_pool_para: " << reg->average_pool_para << "\n";
      os << "ddr_save_block_y_size: " << reg->ddr_save_block_y_size << "\n";
      os << "ddr_save_block_x_size: " << reg->ddr_save_block_x_size << "\n";
      break;
    case 30:
      reg->out_y_max = static_cast<int>(BitSelect(*data_, 27, 21));
      reg->out_y_min = static_cast<int>(BitSelect(*data_, 20, 17));
      reg->out_x_max = static_cast<int>(BitSelect(*data_, 16, 10));
      reg->out_x_min = static_cast<int>(BitSelect(*data_, 9, 6));
      os << "out_y_max: " << reg->out_y_max << "\n";
      os << "out_y_min: " << reg->out_y_min << "\n";
      os << "out_x_max: " << reg->out_x_max << "\n";
      os << "out_x_min: " << reg->out_x_min << "\n";
      break;
    case 31:
      reg->out_y_stride = static_cast<int>(BitSelect(*data_, 19, 13));
      reg->out_x_stride = static_cast<int>(BitSelect(*data_, 12, 6));
      os << "out_y_stride: " << reg->out_y_stride << "\n";
      os << "out_x_stride: " << reg->out_x_stride << "\n";
      break;
    case 32:
      reg->se_stage = static_cast<int>(BitSelect(*data_, 19, 17));
      reg->se_fc_in_num = static_cast<int>(BitSelect(*data_, 16, 14));
      reg->se_fc_out_num = static_cast<int>(BitSelect(*data_, 13, 6));
      os << "se_stage: " << reg->se_stage << "\n";
      os << "se_fc_in_num: " << reg->se_fc_in_num << "\n";
      os << "se_fc_out_num: " << reg->se_fc_out_num << "\n";
      break;
    default:
      std::cout << "Unrecognized opcode = " << opcode << "\n";
      exit(1);
      break;
  }
  std::cout << os.str();
}

/*
 * Configure control flow with decoded trigger conditions
 *
 * example:
 *
 * ddr_ld -> compute -> ddr_st
 *  /\                    |
 *  |                     |
 *   - - - - - - - - - - - 
 */
void OPUGenericInsn::SetPred(std::vector<OPUGenericInsn*> pred) {
  std::vector<OPUGenericInsn*> elist;
  for (auto& item : pred_) {
    auto it = std::find(pred.begin(), pred.end(), item.first);
    if (it == pred.end()) {
      elist.push_back(item.first);
    }
  }
  for (auto ins : elist) {
    pred_.erase(pred_.find(ins));
  }
  for (auto p : pred) {
    if (pred_.find(p) == pred_.end()) {
      pred_[p] = false;
    }
  }
}

/*
 * Handle extra assertions for certain pre-condition
 *
 * example:
 * 
 * ddr_ad -> compute x 9 ----------------------> ddr_st
 *                       assert(compute_cnt==9)
 */
void OPUGenericInsn::SetAssert(std::vector<std::pair<void*, int>> pred_assert) {
  assert_ = std::move(pred_assert);
}
