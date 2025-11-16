// -----------------------------------------------------------------------------
// Copyright      : UCLA EDA LAB
// -----------------------------------------------------------------------------
// Engineer       : Chen Wu
// Design Name    : opu series
// Module Name    : topu_core_top
// Target Devices : 325t, Alveo U200
// Tool Versions  : Vivado 2020.1, Modelsim 2019.4
// Description    : 
//    The top module for transformer-opu core
//
// Revision       :
// Version        Date        Author        Descriptin
// 1.0            2022-04-07  Chen Wu       Initial version
// 2.0            2023-09-03  Shaoqiang     Simulation 97 layers,and
//                                          implementation on FPGA of U200.
// 3.0            2024-05-20  Shaoqiang     Testing and Implementation
//                2024-7-3    Shaoqiang     code number is 28811 row
// -----------------------------------------------------------------------------


`include "opu_parameter.vh"
`include "opu_instruction.vh"

module tb_debug_top();

//-------------------------------------------------------------------------------
// Overall parameters of debugging mode
//-------------------------------------------------------------------------------
localparam DEBUG_PATH    =`DEBUG_PATH                            ;
localparam DEBUG_MODEL   =`DEBUG_MODEL                           ;
localparam DEBUG_DIR_1   ={DEBUG_PATH,"core1/",DEBUG_MODEL,"/"}  ;
localparam DEBUG_DIR_2   ={DEBUG_PATH,"core2/",DEBUG_MODEL,"/"}  ;
localparam DEBUG_DIR_3   ={DEBUG_PATH,"core3/",DEBUG_MODEL,"/"}  ;
localparam DEBUG_DIR_4   ={DEBUG_PATH,"core4/",DEBUG_MODEL,"/"}  ;
//-----------------------------------------------------------------------------------------------------------------------
//Simulation core1
//-----------------------------------------------------------------------------------------------------------------------
`ifdef DEBUG_CORE1
generate for(genvar i=0;i<1;i=i+1)
begin: DEBUG1
  localparam        DEBUG_DIR             =DEBUG_DIR_1                                                                  ;
   //--------------------------------------------------------------------------------------------------------------------                                                                               ;
  wire              d_clk                 =OPU_TOP.CORE_TOP1.clk                                                        ;
  wire              d_reset               =OPU_TOP.CORE_TOP1.reset                                                      ;
  wire              d_layer_start         =OPU_TOP.CORE_TOP1.layer_start                                                ;
  wire              d_layer_done          =OPU_TOP.CORE_TOP1.layer_done                                                 ;
  wire [9:0]        d_layer_cnt           =OPU_TOP.CORE_TOP1.core_layer_cnt                                             ;
  wire [31:0]       d_latency_cnt         =OPU_TOP.CORE_TOP1.core_latency_cnt                                           ;
  wire              d_axi_util_load       =OPU_TOP.CORE_TOP1.axi_util_load                                              ;
  wire              d_axi_util_store      =OPU_TOP.CORE_TOP1.axi_util_store                                             ;
  wire [1024-1:0]   d_pe_act_val          =OPU_TOP.CORE_TOP1.u_pe_sparse_top.u_pe_sparse_array.pe_act_val               ;
  wire              d_nvm_total           =OPU_TOP.CORE_TOP1.u_nvm_top.debug_nvm_total                                  ;
  wire              d_nvm_dsp             =OPU_TOP.CORE_TOP1.u_nvm_top.debug_nvm_dsp                                    ;
  wire              d_nvm_div             =OPU_TOP.CORE_TOP1.u_nvm_top.debug_nvm_div                                    ;
  wire              d_nvm_sync            =OPU_TOP.CORE_TOP1.u_nvm_top.debug_nvm_sync                                   ;
  wire              d_nvm_back            =OPU_TOP.CORE_TOP1.u_nvm_top.debug_nvm_back                                   ;
  //---------------------------------------------------------------------------------------------------------------------
  wire              d_inst_rvld           =OPU_TOP.CORE_TOP1.u_inst_top.inst_rvld                                       ;
  wire [32-1:0]     d_inst_rdata          =OPU_TOP.CORE_TOP1.u_inst_top.inst_rdata                                      ;
  //---------------------------------------------------------------------------------------------------------------------
  wire              d_ddr_load_vld_ker    =OPU_TOP.CORE_TOP1.ddr_load_vld_ker[0]                                        ;
  wire [32*16-1:0]  d_ddr_load_data_ker   =OPU_TOP.CORE_TOP1.ddr_load_data_ker[512-1:0]                                 ;
  wire              d_ddr_load_vld_ifm    =OPU_TOP.CORE_TOP1.ddr_load_vld_ifm                                           ;
  wire [32*16-1:0]  d_ddr_load_data_ifm   =OPU_TOP.CORE_TOP1.ddr_load_data_ifm                                          ;
  wire              d_ifm_dma_vld         =OPU_TOP.CORE_TOP1.ifm_dma_vld                                                ;
  wire [32*16-1:0]  d_ifm_dma_data        =OPU_TOP.CORE_TOP1.ifm_dma_data                                               ;
  wire              d_ker_dma_vld         =OPU_TOP.CORE_TOP1.ker_dma_vld                                                ;
  wire [32*16-1:0]  d_ker_dma_data        =OPU_TOP.CORE_TOP1.ker_dma_data                                               ;  
  wire [32*8 -1:0]  d_bm_dma_data         =OPU_TOP.CORE_TOP1.bm_dma_data                                                ;
  wire [128-1:0]    d_pe_result_vld       =OPU_TOP.CORE_TOP1.pe_result_vld                                              ;
  wire [128*37-1:0] d_pe_result_data      =OPU_TOP.CORE_TOP1.pe_result_data                                             ;
  wire [128-1:0]    d_align_data_vld      =OPU_TOP.CORE_TOP1.u_ofm_top_sparse.align_data_vld                            ;
  wire [128*37-1:0] d_align_data          =OPU_TOP.CORE_TOP1.u_ofm_top_sparse.align_data                                ;
  wire [128-1:0]    d_merge_data_vld      =OPU_TOP.CORE_TOP1.u_ofm_top_sparse.merge_data_vld                            ;
  wire [128*37-1:0] d_merge_data          =OPU_TOP.CORE_TOP1.u_ofm_top_sparse.merge_data                                ;
  wire [128-1:0]    d_collect_data_vld    =OPU_TOP.CORE_TOP1.u_ofm_top_sparse.collect_data_vld                          ;
  wire [128*37-1:0] d_collect_data        =OPU_TOP.CORE_TOP1.u_ofm_top_sparse.collect_data                              ;
  wire [128-1:0]    d_concat_vld          =OPU_TOP.CORE_TOP1.u_ofm_top_sparse.concat_vld                                ;
  wire [128*37-1:0] d_concat_data         =OPU_TOP.CORE_TOP1.u_ofm_top_sparse.concat_data                               ;
  wire              d_adder_ina_vld       =OPU_TOP.CORE_TOP1.u_ofm_top_sparse.u_ofm_adder.r0_adder_result_vld           ;
  wire [128*42-1:0] d_adder_ina           =OPU_TOP.CORE_TOP1.u_ofm_top_sparse.u_ofm_adder.adder_ina                     ;
  wire [128*42-1:0] d_adder_inb           =OPU_TOP.CORE_TOP1.u_ofm_top_sparse.u_ofm_adder.adder_inb                     ;
  wire [128*42-1:0] d_adder_out           =OPU_TOP.CORE_TOP1.u_ofm_top_sparse.u_ofm_adder.adder_result                  ;
  wire              d_adder_out_vld       =OPU_TOP.CORE_TOP1.u_ofm_top_sparse.u_ofm_adder.adder_result_vld              ;
  wire              d_psum_data_vld       =OPU_TOP.CORE_TOP1.u_ofm_top_sparse.u_ofm_psum_cut.psum_data_vld              ;
  wire [128*32-1:0] d_psum_data           =OPU_TOP.CORE_TOP1.u_ofm_top_sparse.u_ofm_psum_cut.psum_data                  ;
  wire              d_psum_cut_data_vld   =OPU_TOP.CORE_TOP1.u_ofm_top_sparse.u_ofm_psum_cut.psum_cut_data_end          ;
  wire [128*32-1:0] d_psum_cut_data       =OPU_TOP.CORE_TOP1.u_ofm_top_sparse.u_ofm_psum_cut.psum_cut_data              ;
  wire              d_nvm_rdata_vld       =OPU_TOP.CORE_TOP1.u_nvm_top.nvm_rdata_vld                                    ;  
  wire [32*16-1:0]  d_nvm_rdata           =OPU_TOP.CORE_TOP1.u_nvm_top.nvm_rdata                                        ;
  wire              d_back_rdata_vld      =OPU_TOP.CORE_TOP1.u_nvm_top.back_rdata_vld                                   ;  
  wire [32*16-1:0]  d_back_rdata          =OPU_TOP.CORE_TOP1.u_nvm_top.back_rdata                                       ;
  wire              d_ddr_store_vld       =OPU_TOP.CORE_TOP1.ddr_store_vld                                              ;
  wire [32*16-1:0]  d_ddr_store_data      =OPU_TOP.CORE_TOP1.ddr_store_data                                             ;
  
  //---------------------------------------------------------------------------------------------------------------------
 `include "tb_display.vh"
  //---------------------------------------------------------------------------------------------------------------------
 end
 endgenerate
`endif//DEBUG_CORE1

    



endmodule

