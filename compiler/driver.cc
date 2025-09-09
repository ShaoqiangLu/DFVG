#include "accelerator.h"
/*
 * Top driver function for OPU simulation
 *
 * for each layer:
 *   dev->FetchInsn()  // fetch one instruction block
 *   dev->Run(#phases)  // run until no new events pop out by default
 *
 * dev->Run(N) runs N phases, which could include events in parallel
 * semantic. Events include IF (instruction fetch), LD (DDR load), ST
 * (DDR store), COMPUTE (pipeline : data fetch - compute - accumulate).
 * 
 *
 * for example, say the flow consists of 4 phases as follows
 * 
 * IF -- LD/IF -- LD/COMPUTE/IF -- COMPUTE/ST/IF
 *
 * dev->Run(4) simulates the flow above
 */

#define MANUAL_INSTRS
//#define SINGLE_LAYER

int main() {
  Device* dev = new Device();
  
#ifdef MANUAL_INSTRS
  auto load = dev->load_ins_;
  auto compute = dev->compute_ins_;
  auto store = dev->store_ins_;
  dev->dump = true;

  load->ddr_load_type = {0,1,2,4};  // load 0:fmap, 1:weight, 2:bias, 4:instruction
  load->ddr_fm_addr_ini = 819200;  // fmap destination address
  load->ddr_load_block_y_size = 38;  // fmap block size
  load->ddr_load_block_x_size = 38;
  load->ddr_fm_read_num = 1444;  // dram address count (64 bytes per address)
  load->fm_in_y_size = 416;
  load->fm_in_x_size = 416;
  load->ddr_ker_addr_ini = 3276800;
  load->ddr_ker_read_num = 16;
  load->ddr_bias_addr_ini = 6144000;
  load->ddr_bias_read_num = 2;
  load->ddr_load_single = 0;  // extra load for residue fmap
  dev->RunLoad(load);

  load->ddr_load_type = {0};
  load->ddr_fm_addr_ini = 819238;
  load->ddr_load_block_y_size = 38;
  load->ddr_load_block_x_size = 38;
  load->ddr_fm_read_num = 1444;
  load->fm_in_y_size = 416;
  load->fm_in_x_size = 416;
  load->ddr_ker_addr_ini = 3276800;
  load->ddr_ker_read_num = 16;
  load->ddr_bias_addr_ini = 6144000;
  load->ddr_bias_read_num = 2;
  load->ddr_load_single = 0;
  dev->RunLoad(load);

  compute->fm_ram_id = 0;  // source of data fetch
  compute->wgt_ram_id = 0;
  compute->bias_ram_id = 0;
  compute->type = 1;  // encoding for conv2d
  compute->dw_flag = 0;  // data fetch w/ w/o line buffer
  compute->ker_x_size = 1;  
  compute->ker_y_size = 1;
  compute->dma_block_x_size = 38;
  compute->dma_block_y_size = 38;
  compute->dma_x_min = 0;
  compute->dma_x_max = 37;
  compute->read_x_stride = 1;
  compute->dma_y_min = 0;
  compute->dma_y_max = 37;
  compute->read_y_stride = 1;
  compute->copy_mode = 1;
  compute->ker_round = 1;
  compute->ker_on_board = 0;
  compute->ker_repeat = 1;
  compute->ker_repeat_last = 1;
  compute->ker_addr_s = 0;
  compute->ker_addr_e = 0;
  #if PRECISION == 8
    compute->output_num = 4;
  #endif
  #if PRECISION == 16
    compute->output_num = 3;
  #endif
    compute->channel_out = 16;
  #if PRECISION == 8
    compute->output_channel = 32;
  #endif
  #if PRECISION == 16
    compute->output_channel = 16;
  #endif
  compute->shift_num_fm = 11;
  compute->shift_num_bias = 9;
  compute->add_bias = 1;
  compute->add_temp = 0;
  compute->final_output = 1;
  compute->output_block_y_size = 38;
  compute->output_block_x_size = 38;
  dev->RunCompute(compute);

  store->ddr_save_pos = 3;
  store->activation = 1;
  store->activation_type = 0;
  store->pooling = 1;
  store->pooling_type = 1;
  store->pooling_x_size = 2;
  store->pooling_y_size = 2;
  store->pooling_x_stride = 2;
  store->pooling_y_stride = 2;
  store->residual = 0;
  store->ddr_save_block_x_size = 38;
  store->ddr_save_block_y_size = 38;
  store->block_pool_x_size = 19;
  store->block_pool_y_size = 19;
  store->fm_output_addr_ini = 992467;
  store->ddr_save_fm_num = 361;
  store->ddr_save_des = 0;
  store->padding = 0;
  store->padding_size = 1;
  store->fm_out_x_size = 210;
  store->fm_out_y_size = 210;
  store->channel_out = 16;
  store->upsample_output = 0;
  store->out_y_max = 0;
  store->out_y_min = 0;
  store->out_x_max = 0;
  store->out_x_min = 0;
  store->out_y_stride = 0;
  store->out_x_stride = 0;
  dev->RunStore(store);
#else
  #ifdef SINGLE_LAYER
    dev->dump = true;
    dev->FetchInsn();
    dev->Run();
  #else
    for (int i = 0; ; i++) {
      if (i == LAYER_CNT - 1) dev->dump = true;
      if (dev->IsComplete())
        break;
      dev->FetchInsn();
      dev->Run();
    }
  #endif
#endif
  dev->os.close();
  return 0;
}
