#ifndef ARCH_H
#define ARCH_H

#include <math.h>

class Arch {
 public:
  int DRAM_bw_bytes = 64; 
  int data_bytes = 1;  // 8-bit
  
  int multipliers = 1024;

  int fmap_buffer_bw_bytes = 64;
  int fmap_buffer_depth = 1444;//1600;

  int w_buffer_bw_bytes = 64 * 16;
  int w_buffer_depth = 36;

  int dram_fmap_addr_offset = 819200;//0;
  int dram_w_addr_offset = 3276800;//1638400;
  int dram_b_addr_offset = 6144000;
  int dram_inst_addr_offset = 7372800;
  
  int input_buffer_bank = 2;
  int compute_engine = 1;
  int psum_bank = 1;
  int dram_bank = 1;

  int dram_access_latency = 0;//30;  // cycles
  int pe_latency = 0;//std::log2((double)multipliers);

  int operation_frequency = 200000000;  // 200Mhz

  int data_width_during_accumultation = 26; // bits

  int getElementsPerDRAMAddr() {
    return DRAM_bw_bytes / data_bytes;  
  }

  int getSIMDParallelism() {
    return multipliers;
  }

  int getFmapBufferBytes() {
    return fmap_buffer_bw_bytes * fmap_buffer_depth;
  }

  int getWBufferBytes() {
    return w_buffer_bw_bytes * w_buffer_depth;  
  }

  int getWBDepth() {return w_buffer_depth;}

  int getFBBank() {return input_buffer_bank;}
  int getWBBank() {return input_buffer_bank;}
  int getBBBank() {return input_buffer_bank;}
  int getPSUMBank() {return psum_bank;}
  int getDRAMBank() {return dram_bank;}
  int getComputeEngineCnt() {return compute_engine;}

  int getDRAMLatency() {return dram_access_latency;}
  int getPELatency() {return pe_latency;}

  int getFreq() {return operation_frequency;}
};

#endif
