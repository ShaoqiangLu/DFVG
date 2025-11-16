`timescale 1ns / 1ps
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
// 2.0            2023-09-11  Shaoqiang     Simulation 97 layers,and
//                                          implementation on FPGA of U200.
// -----------------------------------------------------------------------------
//Number of layers of OPU operation
//1  //[1,64,64  ,12],1536   ,tr 
//2  //[1,64,64  ,12],1536   ,               
//3  //[1,64,64  ,12],1536   ,            
//4  //[1,64,64  ,12],128x12 ,sf               
//5  //[1,64,768 ,1 ],128x12 ,                
//6  //[1,64,768 ,1 ],1536   ,ln                  
//7  //[1,64,3072,1 ],1536x4 ,act                    
//8  //[1,64,768 ,1 ],1536   ,ln                   
//
//
`include "opu_parameter.vh"
module opu_core_top(
  input   wire                                      clk                         , 
  input                                             reset                       ,
  input                                             core_init_finish            ,
  input                   [  4-1:0]                 core_offset_high            ,
  input                   [ 25-1:0]                 core_offset                 ,
  input                                             core_start                  ,
  output  wire            [ 32-1:0]                 core_opcode_cnt             ,
  output  reg             [ 32-1:0]                 core_latency_cnt    =0      ,
  output  reg             [ 10-1:0]                 core_layer_cnt      =0      ,
  output  reg             [ 10-1:0]                 ifm_pp_cnt          =0      ,//sim
  output  reg             [ 10-1:0]                 ker_pp_cnt          =0      ,//sim
  output  wire                                      layer_start_init            ,
  input   wire                                      layer_start_sync            ,
  output  wire                                      nvm_start_init              ,
  input   wire                                      nvm_start_sync              ,
  output  wire            [128-1:0]                 nvm_sum_init                ,
  input   wire            [128-1:0]                 nvm_sum_sync                ,
  //aw
  output  wire                                      m_axi_aclk                  ,
  output  reg                                       m_axi_aresetn=0             ,
  output  wire            [  4-1:0]                 m_axi_awid                  ,
  output  wire                                      m_axi_awlock                ,
  output  wire            [  4-1:0]                 m_axi_awcache               ,
  output  wire            [  3-1:0]                 m_axi_awprot                ,
  output  wire            [  4-1:0]                 m_axi_awqos                 ,
  output  wire            [ 64-1:0]                 m_axi_awaddr                ,
  output  wire            [  8-1:0]                 m_axi_awlen                 ,
  output  wire            [  3-1:0]                 m_axi_awsize                ,
  output  wire            [  2-1:0]                 m_axi_awburst               ,
  output  wire                                      m_axi_awvalid               ,
  input                                             m_axi_awready               ,
  //w
  output  wire            [512-1:0]                 m_axi_wdata                 ,
  output  wire                                      m_axi_wlast                 ,
  output  wire                                      m_axi_wvalid                ,
  input                                             m_axi_wready                ,
  output  wire            [ 64-1:0]                 m_axi_wstrb                 ,
  //b
  input                   [  4-1:0]                 m_axi_bid                   ,
  input                   [  2-1:0]                 m_axi_bresp                 ,
  input                                             m_axi_bvalid                ,
  output  wire                                      m_axi_bready                ,
  //ar
  output  wire            [  4-1:0]                 m_axi_arid                  ,
  output  wire                                      m_axi_arlock                ,
  output  wire            [  4-1:0]                 m_axi_arcache               ,
  output  wire            [  3-1:0]                 m_axi_arprot                ,
  output  wire            [  4-1:0]                 m_axi_arqos                 ,
  output  wire            [ 64-1:0]                 m_axi_araddr                ,
  output  wire            [  8-1:0]                 m_axi_arlen                 ,
  output  wire            [  3-1:0]                 m_axi_arsize                ,
  output  wire            [  2-1:0]                 m_axi_arburst               ,
  output  wire                                      m_axi_arvalid               ,
  input                                             m_axi_arready               ,
  //r
  output  wire                                      m_axi_rready                ,
  input                   [512-1:0]                 m_axi_rdata                 ,
  input                                             m_axi_rvalid                ,
  input                                             m_axi_rlast                 ,
  input                   [  4-1:0]                 m_axi_rid                   ,
  input                   [  2-1:0]                 m_axi_rresp                       
);

 localparam               ID                        = 5                         ;
 localparam               CA                        = 1                         ;
 localparam               ME                        = 1                         ;
 localparam               BM                        = 1                         ;
 localparam               NUM                       = 32                        ;
 localparam               DW                        = 16                        ;
 localparam               DW_DDR                    = DW                        ;
 localparam               DW_IFM                    = DW                        ;
 localparam               DW_KER                    = DW                        ;
 localparam               DW_BM                     = ID+CA+ME+BM               ;
 localparam               DW_PE                     = 37                        ;
 localparam               DW_OFM                    = 37                        ;
 localparam               DW_BIAS                   = 32                        ;
 localparam               DW_NVM                    = DW                        ;
 localparam               DW_RES                    = DW                        ;
 localparam               PNUM                      = 4                         ;
 integer i=0,j=0;  
 reg                      [8 -1:0]                  rid_wstart    =0            ;
 wire                                               ddr_rstart                  ;
 wire                     [4 -1:0]                  ddr_rid                     ;
 wire                     [4 -1:0]                  ddr_roffset_high            ;
 wire                     [25-1:0]                  ddr_roffset                 ;
 wire                     [25-1:0]                  ddr_rstride                 ;
 wire                     [7 -1:0]                  ddr_rstep_num               ;
 wire                     [15-1:0]                  ddr_rstep                   ;
 wire                     [15-1:0]                  ddr_bm_num                  ;
 wire                                               ddr_bm_en                   ;
 reg                                                bm_no_ebale      =0         ;
 wire                                               ddr_wstart                  ;
 wire                     [4 -1:0]                  ddr_woffset_high            ;
 wire                     [25-1:0]                  ddr_woffset                 ;
 wire                     [25-1:0]                  ddr_wstride                 ;
 wire                     [7 -1:0]                  ddr_wstep_num               ;
 wire                     [15-1:0]                  ddr_wstep                   ;
 wire                                               ifm_rstart                  ;
 wire                     [7 -1:0]                  ifm_hmax                    ;
 wire                     [4 -1:0]                  ifm_hmin                    ; 
 wire                     [3 -1:0]                  ifm_hs                      ;
 wire                     [7 -1:0]                  ifm_h                       ;
 wire                     [7 -1:0]                  ifm_wmax                    ;  
 wire                     [4 -1:0]                  ifm_wmin                    ;
 wire                     [3 -1:0]                  ifm_ws                      ;
 wire                     [7 -1:0]                  ifm_w                       ;
 wire                     [6 -1:0]                  ifm_rkeep                   ;
 wire                     [2 -1:0]                  ifm_rsel                    ; 
 wire                                               ifm_pp                      ; 
 wire                                               ker_pp                      ;
 wire                     [6 -1:0]                  ker_eaddr                   ; 
 wire                     [6 -1:0]                  ker_saddr                   ; 
 wire                     [3 -1:0]                  pe_output_num               ;
 wire                                               bias_pp                     ;
 wire                     [3 -1:0]                  ofm_din_enc                 ;
 wire                                               ofm_bias_sel                ;  
 wire                     [10-1:0]                  ofm_bias_snum               ;   
 wire                     [7 -1:0]                  ofm_concat_num              ;  
 wire                                               ofm_tmp_sel                 ;  
 wire                                               ofm_output_sel              ;   
 wire                     [5 -1:0]                  ofm_din_snum                ; 
 wire                     [15-1:0]                  ofm_rbase                   ;
 wire                     [15-1:0]                  ofm_wbase                   ;  
 wire                                               ofm_pp                      ;  
 wire                                               ofm_rstart                  ; 
 wire                                               nvm_rstart                  ; 
 wire                                               nvm_res_en                  ;
 wire                                               nvm_act_en                  ; 
 wire                     [4 -1:0]                  nvm_act_type                ;
 wire                                               nvm_sf_en                   ;
 wire                                               nvm_ln_en                   ;  
 wire                                               nvm_tr_en                   ; 
 wire                     [11-1:0]                  nvm_rnum                    ;
 wire                     [7 -1:0]                  nvm_rstep                   ;
 wire                     [12-1:0]                  nvm_xnum                    ;
 wire                     [12-1:0]                  nvm_ynum                    ;
 wire                     [12-1:0]                  nvm_bnum                    ;
 wire                     [12-1:0]                  nvm_gnum                    ;
 wire                                               nvm_idir                    ;
 wire                     [ 6-1:0]                  nvm_inum                    ;
 wire                                               nvm_odir                    ;
 wire                     [ 6-1:0]                  nvm_onum                    ;
 wire                                               nvm_router                  ;
 wire                                               ddr_rdone                   ;  
 wire                                               ifm_rdone_inst              ;
 wire                                               ofm_rdone                   ;
 wire                                               ofm_rdone_final             ;
 wire                                               nvm_rdone                   ; 
 wire                                               ddr_wdone                   ; 
 wire                                               r_ddr_wdone                 ;  
//-------------------------------------------------------------------------------
 wire                                               ddr_load_vld_ifm            ; 
 wire                                               ddr_load_vld_bm             ; 
 wire                     [2-1:0]                   ddr_load_vld_ker            ;
 wire                                               ddr_load_vld_bias           ;
 wire                                               ddr_load_vld_res            ;
 wire                                               ddr_load_vld_ins            ;
 wire                                               ddr_load_vld_beta           ; 
 wire                                               ddr_load_vld_gamma          ; 
 wire                     [512-1:0]                 m_axi_rdata_reverse         ;
 (*dont_touch="true"*)reg [DW_DDR*NUM-1:0]          r_ddr_load_data_ifm  =0     ;
 (*dont_touch="true"*)reg [DW_DDR*NUM-1:0]          r_ddr_load_data_bm   =0     ;
 (*dont_touch="true"*)reg [DW_DDR*NUM*2-1:0]        r_ddr_load_data_ker  =0     ;
 (*dont_touch="true"*)reg [DW_DDR*NUM-1:0]          r_ddr_load_data_bias =0     ;
 (*dont_touch="true"*)reg [DW_DDR*NUM-1:0]          r_ddr_load_data_res  =0     ;
 (*dont_touch="true"*)reg [DW_DDR*NUM-1:0]          r_ddr_load_data_ins  =0     ;
 (*dont_touch="true"*)reg [DW_DDR*NUM-1:0]          r_ddr_load_data_beta =0     ;
 (*dont_touch="true"*)reg [DW_DDR*NUM-1:0]          r_ddr_load_data_gamma=0     ;
 wire                     [DW_DDR*NUM-1:0]          ddr_load_data_ifm           ;
 wire                     [DW_DDR*NUM-1:0]          ddr_load_data_bm            ;
 wire                     [DW_DDR*NUM*2-1:0]        ddr_load_data_ker           ;
 wire                     [DW_DDR*NUM-1:0]          ddr_load_data_bias          ;
 wire                     [DW_DDR*NUM-1:0]          ddr_load_data_res           ;
 wire                     [DW_DDR*NUM-1:0]          ddr_load_data_ins           ;
 wire                     [DW_DDR*NUM-1:0]          ddr_load_data_beta          ;
 wire                     [DW_DDR*NUM-1:0]          ddr_load_data_gamma         ;

//-------------------------------------------------------------------------------
 wire                                               ifm_dma_vld                 ;
 wire                                               ifm_dma_done                ;
 wire                     [DW_IFM*NUM-1:0]          ifm_dma_data                ; 
 (*dont_touch="true"*)reg [DW_IFM*NUM-1:0]          r_ifm_dma_data      =0      ;
 (*dont_touch="true"*)reg                           r_ifm_dma_vld       =0      ;
 (*dont_touch="true"*)reg                           r_ifm_dma_done      =0      ;
//-------------------------------------------------------------------------------
 wire                     [NUM-1:0]                 ker_dma_addr_vld            ;
 wire                     [NUM*5-1:0]               ker_dma_addr_cnt            ;
 wire                     [NUM-1:0]                 ker_dma_addr_rpp            ;
 wire                                               ker_dma_start               ;  
 wire                                               ker_dma_vld                 ;
 wire                     [NUM*DW_KER-1:0]          ker_dma_data                ;
 wire                     [NUM*DW_BM-1:0]           bm_dma_data                 ; 
 (*dont_touch="true"*)reg [NUM*DW_KER-1:0]          r_ker_dma_data    =0        ;
 (*dont_touch="true"*)reg [NUM*DW_BM-1:0]           r_bm_dma_data     =0        ;
 (*dont_touch="true"*)reg                           r_ker_dma_vld     =0        ;
 (*dont_touch="true"*)reg                           r_ker_dma_start   =0        ;
//-------------------------------------------------------------------------------
 wire                     [NUM*PNUM-1:0]            pe_result_vld               ;
 wire                     [NUM-1:0]                 pe_result_meg               ;
 wire                     [NUM*(DW_PE*PNUM)-1:0]    pe_result_data              ;
 (*dont_touch="true"*)reg [NUM*(DW_PE*PNUM)-1:0]    r_pe_result_data =0         ;
 (*dont_touch="true"*)reg [NUM*PNUM-1:0]            r_pe_result_vld  =0         ;
 (*dont_touch="true"*)reg [NUM-1:0]                 r_pe_result_meg  =0         ;
 reg                                                pe_mode      =0             ;
 reg                      [3-1:0]                   pe_trunc_pos =0             ;
//-------------------------------------------------------------------------------
 wire                     [NUM*(DW_BIAS*PNUM)-1:0]  bias_dma_data               ; 
 (*dont_touch="true"*)reg [NUM*(DW_BIAS*PNUM)-1:0]  r_bias_dma_data =0          ;  
 reg                      [11-1:0]                  ofm_roffset  =0             ;
 reg                      [11-1:0]                  ofm_woffset  =0             ;
//-------------------------------------------------------------------------------
 reg                                                nvm_res_raddr_vld =0        ;
 reg                      [11-1:0]                  nvm_res_raddr     =0        ;
 wire                     [NUM*DW_RES-1:0]          nvm_res_rdata               ; 
 wire                                               nvm_res_rdata_vld           ; 
 (*dont_touch="true"*)reg [NUM*DW_RES-1:0]          r_nvm_res_rdata    =0       ; 
 (*dont_touch="true"*)reg                           r_nvm_res_rdata_vld=0       ; 
 
 
 wire                     [15-1:0]                  nvm_raddr                   ;
 wire                                               nvm_raddr_vld               ;
 wire                                               nvm_raddr_done              ;
 wire                                               nvm_rdata_vld               ;
 wire                                               nvm_rdata_done              ;
 wire                     [NUM*DW_NVM-1:0]          nvm_rdata                   ;
 (*dont_touch="true"*)reg [NUM*DW_NVM-1:0]          r_nvm_rdata=0               ;
 (*dont_touch="true"*)reg                           r_nvm_rdata_vld =0          ;
 (*dont_touch="true"*)reg                           r_nvm_rdata_done=0          ;
 reg                                                nvm_back_en=0               ; 
 wire                     [15-1:0]                  nvm_back_waddr              ;                      
 wire                                               nvm_back_wvld               ;
 wire                                               nvm_back_wdone              ;
 wire                     [NUM*DW_NVM-1:0]          nvm_back_wdata              ;
 (*dont_touch="true"*)reg [NUM*DW_NVM-1:0]          r_nvm_back_wdata=0          ; 
 (*dont_touch="true"*)reg [15-1:0]                  r_nvm_back_waddr=0          ;                      
 (*dont_touch="true"*)reg [4-1:0]                   r_nvm_back_wvld =0          ;
 (*dont_touch="true"*)reg                           r_nvm_back_wdone=0          ;
 wire                     [15-1:0]                  nvm_back_raddr              ; 
 wire                                               nvm_back_raddr_vld          ;                
 wire                                               nvm_back_rdata_vld          ; 
 wire                     [NUM*DW_NVM-1:0]          nvm_back_rdata              ;
 (*dont_touch="true"*)reg [NUM*DW_NVM-1:0]          r_nvm_back_rdata =0         ;
 (*dont_touch="true"*)reg                           r_nvm_back_rvld  =0         ; 
 //-----------------------------------------------------------------------------
 wire                                               ddr_store_vld               ;
 wire                     [NUM*DW_DDR-1:0]          ddr_store_data              ;
 (*dont_touch="true"*)reg [NUM*DW_DDR-1:0]          r_ddr_store_data=0          ;
 (*dont_touch="true"*)reg                           r_ddr_store_vld =0          ;
//------------------------------------------------------------------------------
 (*dont_touch="true"*)reg [10-1:0]r_reset={11{1'b1}}                            ;
 wire                     layer_start                                           ;
 wire                     layer_done                                            ;
 reg                      latency_ctrl =0                                       ;
 wire                     layer_final                                           ;
 `ifdef SIM_CODE
 reg                      [NUM-1:0]            test_ddr_load_data_bm[DW_DDR-1:0]; 
 reg                      [DW_DDR-1:0]         test_ddr_load_data_ker[NUM-1:0]  ;
 reg                      [DW_DDR-1:0]         test_ddr_load_data_ifm[NUM-1:0]  ;
 //
 reg                      [DW_IFM-1:0]         test_ifm_dma_data[NUM-1:0]       ;
 reg                      [DW_KER-1:0]         test_ker_dma_data[NUM-1:0]       ;
 reg                      [ID-1:0]             test_bm_dma_data_ID [NUM-1:0]    ; 
 reg                      [CA-1:0]             test_bm_dma_data_CA [NUM-1:0]    ; 
 reg                      [ME-1:0]             test_bm_dma_data_ME [NUM-1:0]    ; 
 reg                      [BM-1:0]             test_bm_dma_data_BM [NUM-1:0]    ;
 //
 reg                      [DW_PE-1:0]   test_pe_result_data[NUM-1:0][PNUM-1:0]  ;
 reg                      [PNUM -1:0]   test_pe_result_vld[NUM-1:0]             ;
 reg                      [NUM  -1:0]   test_pe_result_meg                      ;
`endif


//----------------------------------------------------------------------------------

 assign layer_done=(layer_start&&core_layer_cnt!=0)||layer_final                ;
  
 always @(posedge clk)
 begin
    if(core_start)                  core_layer_cnt<=0                           ;
    else if(layer_start|layer_final)core_layer_cnt<=core_layer_cnt+1            ;

    if(layer_start)                 latency_ctrl<=1                             ;
    else if(layer_final)            latency_ctrl<=0                             ;

    if(core_start)                  core_latency_cnt<=0                         ;
    else if(latency_ctrl)           core_latency_cnt<=core_latency_cnt+1        ;
 end
 
 
`ifdef ON_CHIP_DECODE
`ifdef DESIGN_OPU_CORE4
 assign ddr_wdone=nvm_rdone;
`else
 assign ddr_wdone=(core_layer_cnt==4||core_layer_cnt==5||
                   core_layer_cnt==6||core_layer_cnt==8)?
                   nvm_rdone:(r_ddr_wdone);
`endif
`else
 assign ddr_wdone=r_ddr_wdone;
`endif

 //axi
 assign m_axi_aclk                      = clk                                   ;
 always @(posedge clk)m_axi_aresetn    <=~reset                                 ;

 always @(posedge clk)r_reset<={10{reset}}                                      ;
 always @(posedge clk)
 begin
       rid_wstart[1] <= ddr_rstart && (ddr_rid==1)                              ;
       rid_wstart[2] <= ddr_rstart && (ddr_rid==2)                              ;
       rid_wstart[3] <= ddr_rstart && (ddr_rid==3)                              ;
       rid_wstart[4] <= ddr_rstart && (ddr_rid==4)                              ;
       rid_wstart[5] <= ddr_rstart && (ddr_rid==5)                              ;
       rid_wstart[6] <= ddr_rstart && (ddr_rid==6)                              ;
       rid_wstart[7] <= ddr_rstart && (ddr_rid==7)                              ;
       
       if(ddr_rstart && ddr_rid==2)
            bm_no_ebale<=~(ddr_bm_en&&ddr_bm_num!=0)                            ;
       else bm_no_ebale<=0;
 end
//----------------------------------------------------------------------------------
// ddr read and write form ddr by axi bus
//----------------------------------------------------------------------------------
 (*keep_hierarchy="yes"*)ddr_top u_ddr_top ( 
    .core_init_finish             ( core_init_finish                            ),
    .m_axi_awid                   ( m_axi_awid                                  ),
    .m_axi_awlock                 ( m_axi_awlock                                ),
    .m_axi_awcache                ( m_axi_awcache                               ),
    .m_axi_awprot                 ( m_axi_awprot                                ),
    .m_axi_awqos                  ( m_axi_awqos                                 ),
    .m_axi_awaddr                 ( m_axi_awaddr                                ),
    .m_axi_awlen                  ( m_axi_awlen                                 ),
    .m_axi_awsize                 ( m_axi_awsize                                ),
    .m_axi_awburst                ( m_axi_awburst                               ),
    .m_axi_awvalid                ( m_axi_awvalid                               ),
    .m_axi_awready                ( m_axi_awready                               ),
    .m_axi_wdata                  ( m_axi_wdata                                 ),
    .m_axi_wlast                  ( m_axi_wlast                                 ),
    .m_axi_wvalid                 ( m_axi_wvalid                                ),
    .m_axi_wready                 ( m_axi_wready                                ),
    .m_axi_wstrb                  ( m_axi_wstrb                                 ),
    .m_axi_bid                    ( m_axi_bid                                   ),
    .m_axi_bresp                  ( m_axi_bresp                                 ),
    .m_axi_bvalid                 ( m_axi_bvalid                                ),
    .m_axi_bready                 ( m_axi_bready                                ),
    .m_axi_arid                   ( m_axi_arid                                  ),
    .m_axi_arlock                 ( m_axi_arlock                                ),
    .m_axi_arcache                ( m_axi_arcache                               ),
    .m_axi_arprot                 ( m_axi_arprot                                ),
    .m_axi_arqos                  ( m_axi_arqos                                 ),
    .m_axi_araddr                 ( m_axi_araddr                                ),
    .m_axi_arlen                  ( m_axi_arlen                                 ),
    .m_axi_arsize                 ( m_axi_arsize                                ),
    .m_axi_arburst                ( m_axi_arburst                               ),
    .m_axi_arvalid                ( m_axi_arvalid                               ),
    .m_axi_arready                ( m_axi_arready                               ),
    .m_axi_rready                 ( m_axi_rready                                ),
    .m_axi_rvalid                 ( m_axi_rvalid                                ),
    .m_axi_rlast                  ( m_axi_rlast                                 ),
    .m_axi_rid                    ( m_axi_rid                                   ),
    .m_axi_rresp                  ( m_axi_rresp                                 ),
    
    .ddr_load_vld_ins             ( ddr_load_vld_ins                            ),
    .ddr_load_vld_ifm             ( ddr_load_vld_ifm                            ),
    .ddr_load_vld_ker             ( ddr_load_vld_ker                            ), 
    .ddr_load_vld_bm              ( ddr_load_vld_bm                             ), 
    .ddr_load_vld_bias            ( ddr_load_vld_bias                           ), 
    .ddr_load_vld_res             ( ddr_load_vld_res                            ),
    .ddr_load_vld_beta            ( ddr_load_vld_beta                           ),
    .ddr_load_vld_gamma           ( ddr_load_vld_gamma                          ),
     
    .ddr_rdone                    ( ddr_rdone                                   ),
    .ddr_bm_num                   ( ddr_bm_num                                  ),
    .ddr_bm_en                    ( ddr_bm_en                                   ),
    .ddr_rid                      ( ddr_rid                                     ),
    .ddr_roffset                  ( ddr_roffset                                 ),
    .ddr_roffset_high             ( ddr_roffset_high                            ),
    .ddr_rstep                    ( ddr_rstep                                   ),
    .ddr_rstep_num                ( ddr_rstep_num                               ),
    .ddr_rstride                  ( ddr_rstride                                 ),
    .ddr_rstart                   ( ddr_rstart                                  ),
    .ddr_woffset_high             ( ddr_woffset_high                            ),
    .ddr_woffset                  ( ddr_woffset                                 ),
    .ddr_wstep                    ( ddr_wstep                                   ),
    .ddr_wstep_num                ( ddr_wstep_num                               ),
    .ddr_wstride                  ( ddr_wstride                                 ),
    .ddr_wstart                   ( ddr_wstart                                  ),
    .ddr_wdone                    ( r_ddr_wdone                                 ),   
    .ddr_store_data               ( r_ddr_store_data                            ),
    .ddr_store_vld                ( r_ddr_store_vld                             ),
    .reset                        ( r_reset[0]                                  ),
    .clk                          ( clk                                         )
  );

  assign m_axi_rdata_reverse={
         m_axi_rdata[15*32+0+:16],m_axi_rdata[15*32+16+:16]                     ,
         m_axi_rdata[14*32+0+:16],m_axi_rdata[14*32+16+:16]                     ,
         m_axi_rdata[13*32+0+:16],m_axi_rdata[13*32+16+:16]                     ,
         m_axi_rdata[12*32+0+:16],m_axi_rdata[12*32+16+:16]                     ,
         m_axi_rdata[11*32+0+:16],m_axi_rdata[11*32+16+:16]                     ,
         m_axi_rdata[10*32+0+:16],m_axi_rdata[10*32+16+:16]                     ,
         m_axi_rdata[ 9*32+0+:16],m_axi_rdata[ 9*32+16+:16]                     ,
         m_axi_rdata[ 8*32+0+:16],m_axi_rdata[ 8*32+16+:16]                     ,
         m_axi_rdata[ 7*32+0+:16],m_axi_rdata[ 7*32+16+:16]                     ,
         m_axi_rdata[ 6*32+0+:16],m_axi_rdata[ 6*32+16+:16]                     ,
         m_axi_rdata[ 5*32+0+:16],m_axi_rdata[ 5*32+16+:16]                     ,
         m_axi_rdata[ 4*32+0+:16],m_axi_rdata[ 4*32+16+:16]                     ,
         m_axi_rdata[ 3*32+0+:16],m_axi_rdata[ 3*32+16+:16]                     ,
         m_axi_rdata[ 2*32+0+:16],m_axi_rdata[ 2*32+16+:16]                     ,
         m_axi_rdata[ 1*32+0+:16],m_axi_rdata[ 1*32+16+:16]                     ,
         m_axi_rdata[ 0*32+0+:16],m_axi_rdata[ 0*32+16+:16]                     
  };





  always @(posedge clk)
  begin
       r_ddr_load_data_bm       <={
       
       m_axi_rdata_reverse[32*15+0 ],m_axi_rdata_reverse[32*15+1 ],m_axi_rdata_reverse[32*15+2 ],m_axi_rdata_reverse[32*15+3 ],
       m_axi_rdata_reverse[32*15+4 ],m_axi_rdata_reverse[32*15+5 ],m_axi_rdata_reverse[32*15+6 ],m_axi_rdata_reverse[32*15+7 ],
       m_axi_rdata_reverse[32*15+8 ],m_axi_rdata_reverse[32*15+9 ],m_axi_rdata_reverse[32*15+10],m_axi_rdata_reverse[32*15+11],
       m_axi_rdata_reverse[32*15+12],m_axi_rdata_reverse[32*15+13],m_axi_rdata_reverse[32*15+14],m_axi_rdata_reverse[32*15+15],
       m_axi_rdata_reverse[32*15+16],m_axi_rdata_reverse[32*15+17],m_axi_rdata_reverse[32*15+18],m_axi_rdata_reverse[32*15+19],
       m_axi_rdata_reverse[32*15+20],m_axi_rdata_reverse[32*15+21],m_axi_rdata_reverse[32*15+22],m_axi_rdata_reverse[32*15+23],
       m_axi_rdata_reverse[32*15+24],m_axi_rdata_reverse[32*15+25],m_axi_rdata_reverse[32*15+26],m_axi_rdata_reverse[32*15+27],
       m_axi_rdata_reverse[32*15+28],m_axi_rdata_reverse[32*15+29],m_axi_rdata_reverse[32*15+30],m_axi_rdata_reverse[32*15+31],

       m_axi_rdata_reverse[32*14+0 ],m_axi_rdata_reverse[32*14+1 ],m_axi_rdata_reverse[32*14+2 ],m_axi_rdata_reverse[32*14+3 ],
       m_axi_rdata_reverse[32*14+4 ],m_axi_rdata_reverse[32*14+5 ],m_axi_rdata_reverse[32*14+6 ],m_axi_rdata_reverse[32*14+7 ],
       m_axi_rdata_reverse[32*14+8 ],m_axi_rdata_reverse[32*14+9 ],m_axi_rdata_reverse[32*14+10],m_axi_rdata_reverse[32*14+11],
       m_axi_rdata_reverse[32*14+12],m_axi_rdata_reverse[32*14+13],m_axi_rdata_reverse[32*14+14],m_axi_rdata_reverse[32*14+15],
       m_axi_rdata_reverse[32*14+16],m_axi_rdata_reverse[32*14+17],m_axi_rdata_reverse[32*14+18],m_axi_rdata_reverse[32*14+19],
       m_axi_rdata_reverse[32*14+20],m_axi_rdata_reverse[32*14+21],m_axi_rdata_reverse[32*14+22],m_axi_rdata_reverse[32*14+23],
       m_axi_rdata_reverse[32*14+24],m_axi_rdata_reverse[32*14+25],m_axi_rdata_reverse[32*14+26],m_axi_rdata_reverse[32*14+27],
       m_axi_rdata_reverse[32*14+28],m_axi_rdata_reverse[32*14+29],m_axi_rdata_reverse[32*14+30],m_axi_rdata_reverse[32*14+31],

       m_axi_rdata_reverse[32*13+0 ],m_axi_rdata_reverse[32*13+1 ],m_axi_rdata_reverse[32*13+2 ],m_axi_rdata_reverse[32*13+3 ],
       m_axi_rdata_reverse[32*13+4 ],m_axi_rdata_reverse[32*13+5 ],m_axi_rdata_reverse[32*13+6 ],m_axi_rdata_reverse[32*13+7 ],
       m_axi_rdata_reverse[32*13+8 ],m_axi_rdata_reverse[32*13+9 ],m_axi_rdata_reverse[32*13+10],m_axi_rdata_reverse[32*13+11],
       m_axi_rdata_reverse[32*13+12],m_axi_rdata_reverse[32*13+13],m_axi_rdata_reverse[32*13+14],m_axi_rdata_reverse[32*13+15],
       m_axi_rdata_reverse[32*13+16],m_axi_rdata_reverse[32*13+17],m_axi_rdata_reverse[32*13+18],m_axi_rdata_reverse[32*13+19],
       m_axi_rdata_reverse[32*13+20],m_axi_rdata_reverse[32*13+21],m_axi_rdata_reverse[32*13+22],m_axi_rdata_reverse[32*13+23],
       m_axi_rdata_reverse[32*13+24],m_axi_rdata_reverse[32*13+25],m_axi_rdata_reverse[32*13+26],m_axi_rdata_reverse[32*13+27],
       m_axi_rdata_reverse[32*13+28],m_axi_rdata_reverse[32*13+29],m_axi_rdata_reverse[32*13+30],m_axi_rdata_reverse[32*13+31],

       m_axi_rdata_reverse[32*12+0 ],m_axi_rdata_reverse[32*12+1 ],m_axi_rdata_reverse[32*12+2 ],m_axi_rdata_reverse[32*12+3 ],
       m_axi_rdata_reverse[32*12+4 ],m_axi_rdata_reverse[32*12+5 ],m_axi_rdata_reverse[32*12+6 ],m_axi_rdata_reverse[32*12+7 ],
       m_axi_rdata_reverse[32*12+8 ],m_axi_rdata_reverse[32*12+9 ],m_axi_rdata_reverse[32*12+10],m_axi_rdata_reverse[32*12+11],
       m_axi_rdata_reverse[32*12+12],m_axi_rdata_reverse[32*12+13],m_axi_rdata_reverse[32*12+14],m_axi_rdata_reverse[32*12+15],
       m_axi_rdata_reverse[32*12+16],m_axi_rdata_reverse[32*12+17],m_axi_rdata_reverse[32*12+18],m_axi_rdata_reverse[32*12+19],
       m_axi_rdata_reverse[32*12+20],m_axi_rdata_reverse[32*12+21],m_axi_rdata_reverse[32*12+22],m_axi_rdata_reverse[32*12+23],
       m_axi_rdata_reverse[32*12+24],m_axi_rdata_reverse[32*12+25],m_axi_rdata_reverse[32*12+26],m_axi_rdata_reverse[32*12+27],
       m_axi_rdata_reverse[32*12+28],m_axi_rdata_reverse[32*12+29],m_axi_rdata_reverse[32*12+30],m_axi_rdata_reverse[32*12+31],
       
       m_axi_rdata_reverse[32*11+0 ],m_axi_rdata_reverse[32*11+1 ],m_axi_rdata_reverse[32*11+2 ],m_axi_rdata_reverse[32*11+3 ],
       m_axi_rdata_reverse[32*11+4 ],m_axi_rdata_reverse[32*11+5 ],m_axi_rdata_reverse[32*11+6 ],m_axi_rdata_reverse[32*11+7 ],
       m_axi_rdata_reverse[32*11+8 ],m_axi_rdata_reverse[32*11+9 ],m_axi_rdata_reverse[32*11+10],m_axi_rdata_reverse[32*11+11],
       m_axi_rdata_reverse[32*11+12],m_axi_rdata_reverse[32*11+13],m_axi_rdata_reverse[32*11+14],m_axi_rdata_reverse[32*11+15],
       m_axi_rdata_reverse[32*11+16],m_axi_rdata_reverse[32*11+17],m_axi_rdata_reverse[32*11+18],m_axi_rdata_reverse[32*11+19],
       m_axi_rdata_reverse[32*11+20],m_axi_rdata_reverse[32*11+21],m_axi_rdata_reverse[32*11+22],m_axi_rdata_reverse[32*11+23],
       m_axi_rdata_reverse[32*11+24],m_axi_rdata_reverse[32*11+25],m_axi_rdata_reverse[32*11+26],m_axi_rdata_reverse[32*11+27],
       m_axi_rdata_reverse[32*11+28],m_axi_rdata_reverse[32*11+29],m_axi_rdata_reverse[32*11+30],m_axi_rdata_reverse[32*11+31],

       m_axi_rdata_reverse[32*10+0 ],m_axi_rdata_reverse[32*10+1 ],m_axi_rdata_reverse[32*10+2 ],m_axi_rdata_reverse[32*10+3 ],
       m_axi_rdata_reverse[32*10+4 ],m_axi_rdata_reverse[32*10+5 ],m_axi_rdata_reverse[32*10+6 ],m_axi_rdata_reverse[32*10+7 ],
       m_axi_rdata_reverse[32*10+8 ],m_axi_rdata_reverse[32*10+9 ],m_axi_rdata_reverse[32*10+10],m_axi_rdata_reverse[32*10+11],
       m_axi_rdata_reverse[32*10+12],m_axi_rdata_reverse[32*10+13],m_axi_rdata_reverse[32*10+14],m_axi_rdata_reverse[32*10+15],
       m_axi_rdata_reverse[32*10+16],m_axi_rdata_reverse[32*10+17],m_axi_rdata_reverse[32*10+18],m_axi_rdata_reverse[32*10+19],
       m_axi_rdata_reverse[32*10+20],m_axi_rdata_reverse[32*10+21],m_axi_rdata_reverse[32*10+22],m_axi_rdata_reverse[32*10+23],
       m_axi_rdata_reverse[32*10+24],m_axi_rdata_reverse[32*10+25],m_axi_rdata_reverse[32*10+26],m_axi_rdata_reverse[32*10+27],
       m_axi_rdata_reverse[32*10+28],m_axi_rdata_reverse[32*10+29],m_axi_rdata_reverse[32*10+30],m_axi_rdata_reverse[32*10+31],

       m_axi_rdata_reverse[32* 9+0 ],m_axi_rdata_reverse[32* 9+1 ],m_axi_rdata_reverse[32* 9+2 ],m_axi_rdata_reverse[32* 9+3 ],
       m_axi_rdata_reverse[32* 9+4 ],m_axi_rdata_reverse[32* 9+5 ],m_axi_rdata_reverse[32* 9+6 ],m_axi_rdata_reverse[32* 9+7 ],
       m_axi_rdata_reverse[32* 9+8 ],m_axi_rdata_reverse[32* 9+9 ],m_axi_rdata_reverse[32* 9+10],m_axi_rdata_reverse[32* 9+11],
       m_axi_rdata_reverse[32* 9+12],m_axi_rdata_reverse[32* 9+13],m_axi_rdata_reverse[32* 9+14],m_axi_rdata_reverse[32* 9+15],
       m_axi_rdata_reverse[32* 9+16],m_axi_rdata_reverse[32* 9+17],m_axi_rdata_reverse[32* 9+18],m_axi_rdata_reverse[32* 9+19],
       m_axi_rdata_reverse[32* 9+20],m_axi_rdata_reverse[32* 9+21],m_axi_rdata_reverse[32* 9+22],m_axi_rdata_reverse[32* 9+23],
       m_axi_rdata_reverse[32* 9+24],m_axi_rdata_reverse[32* 9+25],m_axi_rdata_reverse[32* 9+26],m_axi_rdata_reverse[32* 9+27],
       m_axi_rdata_reverse[32* 9+28],m_axi_rdata_reverse[32* 9+29],m_axi_rdata_reverse[32* 9+30],m_axi_rdata_reverse[32* 9+31],

       m_axi_rdata_reverse[32* 8+0 ],m_axi_rdata_reverse[32* 8+1 ],m_axi_rdata_reverse[32* 8+2 ],m_axi_rdata_reverse[32* 8+3 ],
       m_axi_rdata_reverse[32* 8+4 ],m_axi_rdata_reverse[32* 8+5 ],m_axi_rdata_reverse[32* 8+6 ],m_axi_rdata_reverse[32* 8+7 ],
       m_axi_rdata_reverse[32* 8+8 ],m_axi_rdata_reverse[32* 8+9 ],m_axi_rdata_reverse[32* 8+10],m_axi_rdata_reverse[32* 8+11],
       m_axi_rdata_reverse[32* 8+12],m_axi_rdata_reverse[32* 8+13],m_axi_rdata_reverse[32* 8+14],m_axi_rdata_reverse[32* 8+15],
       m_axi_rdata_reverse[32* 8+16],m_axi_rdata_reverse[32* 8+17],m_axi_rdata_reverse[32* 8+18],m_axi_rdata_reverse[32* 8+19],
       m_axi_rdata_reverse[32* 8+20],m_axi_rdata_reverse[32* 8+21],m_axi_rdata_reverse[32* 8+22],m_axi_rdata_reverse[32* 8+23],
       m_axi_rdata_reverse[32* 8+24],m_axi_rdata_reverse[32* 8+25],m_axi_rdata_reverse[32* 8+26],m_axi_rdata_reverse[32* 8+27],
       m_axi_rdata_reverse[32* 8+28],m_axi_rdata_reverse[32* 8+29],m_axi_rdata_reverse[32* 8+30],m_axi_rdata_reverse[32* 8+31],
       
       m_axi_rdata_reverse[32* 7+0 ],m_axi_rdata_reverse[32* 7+1 ],m_axi_rdata_reverse[32* 7+2 ],m_axi_rdata_reverse[32* 7+3 ],
       m_axi_rdata_reverse[32* 7+4 ],m_axi_rdata_reverse[32* 7+5 ],m_axi_rdata_reverse[32* 7+6 ],m_axi_rdata_reverse[32* 7+7 ],
       m_axi_rdata_reverse[32* 7+8 ],m_axi_rdata_reverse[32* 7+9 ],m_axi_rdata_reverse[32* 7+10],m_axi_rdata_reverse[32* 7+11],
       m_axi_rdata_reverse[32* 7+12],m_axi_rdata_reverse[32* 7+13],m_axi_rdata_reverse[32* 7+14],m_axi_rdata_reverse[32* 7+15],
       m_axi_rdata_reverse[32* 7+16],m_axi_rdata_reverse[32* 7+17],m_axi_rdata_reverse[32* 7+18],m_axi_rdata_reverse[32* 7+19],
       m_axi_rdata_reverse[32* 7+20],m_axi_rdata_reverse[32* 7+21],m_axi_rdata_reverse[32* 7+22],m_axi_rdata_reverse[32* 7+23],
       m_axi_rdata_reverse[32* 7+24],m_axi_rdata_reverse[32* 7+25],m_axi_rdata_reverse[32* 7+26],m_axi_rdata_reverse[32* 7+27],
       m_axi_rdata_reverse[32* 7+28],m_axi_rdata_reverse[32* 7+29],m_axi_rdata_reverse[32* 7+30],m_axi_rdata_reverse[32* 7+31],

       m_axi_rdata_reverse[32* 6+0 ],m_axi_rdata_reverse[32* 6+1 ],m_axi_rdata_reverse[32* 6+2 ],m_axi_rdata_reverse[32* 6+3 ],
       m_axi_rdata_reverse[32* 6+4 ],m_axi_rdata_reverse[32* 6+5 ],m_axi_rdata_reverse[32* 6+6 ],m_axi_rdata_reverse[32* 6+7 ],
       m_axi_rdata_reverse[32* 6+8 ],m_axi_rdata_reverse[32* 6+9 ],m_axi_rdata_reverse[32* 6+10],m_axi_rdata_reverse[32* 6+11],
       m_axi_rdata_reverse[32* 6+12],m_axi_rdata_reverse[32* 6+13],m_axi_rdata_reverse[32* 6+14],m_axi_rdata_reverse[32* 6+15],
       m_axi_rdata_reverse[32* 6+16],m_axi_rdata_reverse[32* 6+17],m_axi_rdata_reverse[32* 6+18],m_axi_rdata_reverse[32* 6+19],
       m_axi_rdata_reverse[32* 6+20],m_axi_rdata_reverse[32* 6+21],m_axi_rdata_reverse[32* 6+22],m_axi_rdata_reverse[32* 6+23],
       m_axi_rdata_reverse[32* 6+24],m_axi_rdata_reverse[32* 6+25],m_axi_rdata_reverse[32* 6+26],m_axi_rdata_reverse[32* 6+27],
       m_axi_rdata_reverse[32* 6+28],m_axi_rdata_reverse[32* 6+29],m_axi_rdata_reverse[32* 6+30],m_axi_rdata_reverse[32* 6+31],

       m_axi_rdata_reverse[32* 5+0 ],m_axi_rdata_reverse[32* 5+1 ],m_axi_rdata_reverse[32* 5+2 ],m_axi_rdata_reverse[32* 5+3 ],
       m_axi_rdata_reverse[32* 5+4 ],m_axi_rdata_reverse[32* 5+5 ],m_axi_rdata_reverse[32* 5+6 ],m_axi_rdata_reverse[32* 5+7 ],
       m_axi_rdata_reverse[32* 5+8 ],m_axi_rdata_reverse[32* 5+9 ],m_axi_rdata_reverse[32* 5+10],m_axi_rdata_reverse[32* 5+11],
       m_axi_rdata_reverse[32* 5+12],m_axi_rdata_reverse[32* 5+13],m_axi_rdata_reverse[32* 5+14],m_axi_rdata_reverse[32* 5+15],
       m_axi_rdata_reverse[32* 5+16],m_axi_rdata_reverse[32* 5+17],m_axi_rdata_reverse[32* 5+18],m_axi_rdata_reverse[32* 5+19],
       m_axi_rdata_reverse[32* 5+20],m_axi_rdata_reverse[32* 5+21],m_axi_rdata_reverse[32* 5+22],m_axi_rdata_reverse[32* 5+23],
       m_axi_rdata_reverse[32* 5+24],m_axi_rdata_reverse[32* 5+25],m_axi_rdata_reverse[32* 5+26],m_axi_rdata_reverse[32* 5+27],
       m_axi_rdata_reverse[32* 5+28],m_axi_rdata_reverse[32* 5+29],m_axi_rdata_reverse[32* 5+30],m_axi_rdata_reverse[32* 5+31],

       m_axi_rdata_reverse[32* 4+0 ],m_axi_rdata_reverse[32* 4+1 ],m_axi_rdata_reverse[32* 4+2 ],m_axi_rdata_reverse[32* 4+3 ],
       m_axi_rdata_reverse[32* 4+4 ],m_axi_rdata_reverse[32* 4+5 ],m_axi_rdata_reverse[32* 4+6 ],m_axi_rdata_reverse[32* 4+7 ],
       m_axi_rdata_reverse[32* 4+8 ],m_axi_rdata_reverse[32* 4+9 ],m_axi_rdata_reverse[32* 4+10],m_axi_rdata_reverse[32* 4+11],
       m_axi_rdata_reverse[32* 4+12],m_axi_rdata_reverse[32* 4+13],m_axi_rdata_reverse[32* 4+14],m_axi_rdata_reverse[32* 4+15],
       m_axi_rdata_reverse[32* 4+16],m_axi_rdata_reverse[32* 4+17],m_axi_rdata_reverse[32* 4+18],m_axi_rdata_reverse[32* 4+19],
       m_axi_rdata_reverse[32* 4+20],m_axi_rdata_reverse[32* 4+21],m_axi_rdata_reverse[32* 4+22],m_axi_rdata_reverse[32* 4+23],
       m_axi_rdata_reverse[32* 4+24],m_axi_rdata_reverse[32* 4+25],m_axi_rdata_reverse[32* 4+26],m_axi_rdata_reverse[32* 4+27],
       m_axi_rdata_reverse[32* 4+28],m_axi_rdata_reverse[32* 4+29],m_axi_rdata_reverse[32* 4+30],m_axi_rdata_reverse[32* 4+31],
       
       m_axi_rdata_reverse[32* 3+0 ],m_axi_rdata_reverse[32* 3+1 ],m_axi_rdata_reverse[32* 3+2 ],m_axi_rdata_reverse[32* 3+3 ],
       m_axi_rdata_reverse[32* 3+4 ],m_axi_rdata_reverse[32* 3+5 ],m_axi_rdata_reverse[32* 3+6 ],m_axi_rdata_reverse[32* 3+7 ],
       m_axi_rdata_reverse[32* 3+8 ],m_axi_rdata_reverse[32* 3+9 ],m_axi_rdata_reverse[32* 3+10],m_axi_rdata_reverse[32* 3+11],
       m_axi_rdata_reverse[32* 3+12],m_axi_rdata_reverse[32* 3+13],m_axi_rdata_reverse[32* 3+14],m_axi_rdata_reverse[32* 3+15],
       m_axi_rdata_reverse[32* 3+16],m_axi_rdata_reverse[32* 3+17],m_axi_rdata_reverse[32* 3+18],m_axi_rdata_reverse[32* 3+19],
       m_axi_rdata_reverse[32* 3+20],m_axi_rdata_reverse[32* 3+21],m_axi_rdata_reverse[32* 3+22],m_axi_rdata_reverse[32* 3+23],
       m_axi_rdata_reverse[32* 3+24],m_axi_rdata_reverse[32* 3+25],m_axi_rdata_reverse[32* 3+26],m_axi_rdata_reverse[32* 3+27],
       m_axi_rdata_reverse[32* 3+28],m_axi_rdata_reverse[32* 3+29],m_axi_rdata_reverse[32* 3+30],m_axi_rdata_reverse[32* 3+31],

       m_axi_rdata_reverse[32* 2+0 ],m_axi_rdata_reverse[32* 2+1 ],m_axi_rdata_reverse[32* 2+2 ],m_axi_rdata_reverse[32* 2+3 ],
       m_axi_rdata_reverse[32* 2+4 ],m_axi_rdata_reverse[32* 2+5 ],m_axi_rdata_reverse[32* 2+6 ],m_axi_rdata_reverse[32* 2+7 ],
       m_axi_rdata_reverse[32* 2+8 ],m_axi_rdata_reverse[32* 2+9 ],m_axi_rdata_reverse[32* 2+10],m_axi_rdata_reverse[32* 2+11],
       m_axi_rdata_reverse[32* 2+12],m_axi_rdata_reverse[32* 2+13],m_axi_rdata_reverse[32* 2+14],m_axi_rdata_reverse[32* 2+15],
       m_axi_rdata_reverse[32* 2+16],m_axi_rdata_reverse[32* 2+17],m_axi_rdata_reverse[32* 2+18],m_axi_rdata_reverse[32* 2+19],
       m_axi_rdata_reverse[32* 2+20],m_axi_rdata_reverse[32* 2+21],m_axi_rdata_reverse[32* 2+22],m_axi_rdata_reverse[32* 2+23],
       m_axi_rdata_reverse[32* 2+24],m_axi_rdata_reverse[32* 2+25],m_axi_rdata_reverse[32* 2+26],m_axi_rdata_reverse[32* 2+27],
       m_axi_rdata_reverse[32* 2+28],m_axi_rdata_reverse[32* 2+29],m_axi_rdata_reverse[32* 2+30],m_axi_rdata_reverse[32* 2+31],

       m_axi_rdata_reverse[32* 1+0 ],m_axi_rdata_reverse[32* 1+1 ],m_axi_rdata_reverse[32* 1+2 ],m_axi_rdata_reverse[32* 1+3 ],
       m_axi_rdata_reverse[32* 1+4 ],m_axi_rdata_reverse[32* 1+5 ],m_axi_rdata_reverse[32* 1+6 ],m_axi_rdata_reverse[32* 1+7 ],
       m_axi_rdata_reverse[32* 1+8 ],m_axi_rdata_reverse[32* 1+9 ],m_axi_rdata_reverse[32* 1+10],m_axi_rdata_reverse[32* 1+11],
       m_axi_rdata_reverse[32* 1+12],m_axi_rdata_reverse[32* 1+13],m_axi_rdata_reverse[32* 1+14],m_axi_rdata_reverse[32* 1+15],
       m_axi_rdata_reverse[32* 1+16],m_axi_rdata_reverse[32* 1+17],m_axi_rdata_reverse[32* 1+18],m_axi_rdata_reverse[32* 1+19],
       m_axi_rdata_reverse[32* 1+20],m_axi_rdata_reverse[32* 1+21],m_axi_rdata_reverse[32* 1+22],m_axi_rdata_reverse[32* 1+23],
       m_axi_rdata_reverse[32* 1+24],m_axi_rdata_reverse[32* 1+25],m_axi_rdata_reverse[32* 1+26],m_axi_rdata_reverse[32* 1+27],
       m_axi_rdata_reverse[32* 1+28],m_axi_rdata_reverse[32* 1+29],m_axi_rdata_reverse[32* 1+30],m_axi_rdata_reverse[32* 1+31],

       m_axi_rdata_reverse[32* 0+0 ],m_axi_rdata_reverse[32* 0+1 ],m_axi_rdata_reverse[32* 0+2 ],m_axi_rdata_reverse[32* 0+3 ],
       m_axi_rdata_reverse[32* 0+4 ],m_axi_rdata_reverse[32* 0+5 ],m_axi_rdata_reverse[32* 0+6 ],m_axi_rdata_reverse[32* 0+7 ],
       m_axi_rdata_reverse[32* 0+8 ],m_axi_rdata_reverse[32* 0+9 ],m_axi_rdata_reverse[32* 0+10],m_axi_rdata_reverse[32* 0+11],
       m_axi_rdata_reverse[32* 0+12],m_axi_rdata_reverse[32* 0+13],m_axi_rdata_reverse[32* 0+14],m_axi_rdata_reverse[32* 0+15],
       m_axi_rdata_reverse[32* 0+16],m_axi_rdata_reverse[32* 0+17],m_axi_rdata_reverse[32* 0+18],m_axi_rdata_reverse[32* 0+19],
       m_axi_rdata_reverse[32* 0+20],m_axi_rdata_reverse[32* 0+21],m_axi_rdata_reverse[32* 0+22],m_axi_rdata_reverse[32* 0+23],
       m_axi_rdata_reverse[32* 0+24],m_axi_rdata_reverse[32* 0+25],m_axi_rdata_reverse[32* 0+26],m_axi_rdata_reverse[32* 0+27],
       m_axi_rdata_reverse[32* 0+28],m_axi_rdata_reverse[32* 0+29],m_axi_rdata_reverse[32* 0+30],m_axi_rdata_reverse[32* 0+31]
      
       };

       r_ddr_load_data_ker      <={2{m_axi_rdata}}                              ;
       r_ddr_load_data_ifm      <=m_axi_rdata                                   ;
       r_ddr_load_data_bias     <=m_axi_rdata_reverse                           ; 
       r_ddr_load_data_res      <=m_axi_rdata                                   ;
       r_ddr_load_data_ins      <=m_axi_rdata_reverse                           ; 
       r_ddr_load_data_beta     <=m_axi_rdata                                   ;
       r_ddr_load_data_gamma    <=m_axi_rdata                                   ;
  end

`ifndef SIM_CODE
      assign ddr_load_data_ifm  =r_ddr_load_data_ifm                            ;
      assign ddr_load_data_bm   =r_ddr_load_data_bm                             ;
      assign ddr_load_data_ker  =r_ddr_load_data_ker                            ;
      assign ddr_load_data_bias =r_ddr_load_data_bias                           ;
      assign ddr_load_data_res  =r_ddr_load_data_res                            ;
      assign ddr_load_data_ins  =r_ddr_load_data_ins                            ;
      assign ddr_load_data_beta =r_ddr_load_data_beta                           ;
  assign ddr_load_data_gamma    =r_ddr_load_data_gamma                          ;
`else
  wire [512-1:0]                random_data                                     ;
  tb_random   
  u_random (
    .clk                        (clk                                            ), 
    .reset                      (reset                                          ),
    .random_data                (random_data                                    )          
  );

  assign ddr_load_data_ifm   =~ddr_load_vld_ifm   ?0:r_ddr_load_data_ifm;//r_ddr_load_data_ifm   ;//0;//
  assign ddr_load_data_bm    =~ddr_load_vld_bm    ?0:r_ddr_load_data_bm    ;
  assign ddr_load_data_ker   =~ddr_load_vld_ker[0]?0:r_ddr_load_data_ker ;//r_ddr_load_data_ker   ;//{2{random_data}};//r_ddr_load_data_ker   ;//0;//
  assign ddr_load_data_bias  =~ddr_load_vld_bias  ?0:r_ddr_load_data_bias;//r_ddr_load_data_bias  ;//0;//
  assign ddr_load_data_res   =~ddr_load_vld_res   ?0:r_ddr_load_data_res ;//r_ddr_load_data_res   ;//0;//
  assign ddr_load_data_ins   =~ddr_load_vld_ins   ?0:r_ddr_load_data_ins   ;
  assign ddr_load_data_beta  =~ddr_load_vld_beta  ?0:r_ddr_load_data_beta;//r_ddr_load_data_beta  ;//0;//
  assign ddr_load_data_gamma =~ddr_load_vld_gamma ?0:r_ddr_load_data_gamma;//r_ddr_load_data_gamma ;//0;//
`endif



//----------------------------------------------------------------------------------
// the inst ctrl for core
//----------------------------------------------------------------------------------
  (*keep_hierarchy="yes"*)
  inst_top u_inst_top ( 
    .inst_wstart                  ( rid_wstart[5]                               ),
    .inst_wvld                    ( ddr_load_vld_ins                            ),//i
    .inst_wdata                   ( ddr_load_data_ins                           ),//i
    .ddr_rstart                   ( ddr_rstart                                  ),
    .ddr_rid                      ( ddr_rid                                     ),   
    .ddr_roffset_high             ( ddr_roffset_high                            ),    
    .ddr_roffset                  ( ddr_roffset                                 ),
    .ddr_rstride                  ( ddr_rstride                                 ),
    .ddr_rstep_num                ( ddr_rstep_num                               ),    
    .ddr_rstep                    ( ddr_rstep                                   ),
    .ddr_bm_num                   ( ddr_bm_num                                  ),
    .ddr_bm_en                    ( ddr_bm_en                                   ),
    .ddr_wstart                   ( ddr_wstart                                  ),
    .ddr_woffset_high             ( ddr_woffset_high                            ),
    .ddr_woffset                  ( ddr_woffset                                 ),
    .ddr_wstride                  ( ddr_wstride                                 ),
    .ddr_wstep_num                ( ddr_wstep_num                               ),
    .ddr_wstep                    ( ddr_wstep                                   ),
    .ifm_rstart                   ( ifm_rstart                                  ),
    .ifm_hmax                     ( ifm_hmax                                    ),
    .ifm_hmin                     ( ifm_hmin                                    ),
    .ifm_hs                       ( ifm_hs                                      ),
    .ifm_h                        ( ifm_h                                       ),
    .ifm_wmax                     ( ifm_wmax                                    ),
    .ifm_wmin                     ( ifm_wmin                                    ),
    .ifm_ws                       ( ifm_ws                                      ),
    .ifm_w                        ( ifm_w                                       ),
    .ifm_rkeep                    ( ifm_rkeep                                   ),
    .ifm_rsel                     ( ifm_rsel                                    ),
    .ifm_pp                       ( ifm_pp                                      ),
    .ker_eaddr                    ( ker_eaddr                                   ),
    .ker_saddr                    ( ker_saddr                                   ),
    .ker_pp                       ( ker_pp                                      ),
    .pe_output_num                ( pe_output_num                               ), 
    .bias_pp                      ( bias_pp                                     ),
    .ofm_din_enc                  ( ofm_din_enc                                 ),
    .ofm_bias_sel                 ( ofm_bias_sel                                ),
    .ofm_bias_snum                ( ofm_bias_snum                               ),
    .ofm_concat_num               ( ofm_concat_num                              ),    
    .ofm_tmp_sel                  ( ofm_tmp_sel                                 ),
    .ofm_output_sel               ( ofm_output_sel                              ),
    .ofm_din_snum                 ( ofm_din_snum                                ),
    .ofm_rbase                    ( ofm_rbase                                   ),
    .ofm_wbase                    ( ofm_wbase                                   ),
    .ofm_pp                       ( ofm_pp                                      ),
    .ofm_rstart                   ( ofm_rstart                                  ),
    .nvm_rstart                   ( nvm_rstart                                  ),
    .nvm_res_en                   ( nvm_res_en                                  ),
    .nvm_act_en                   ( nvm_act_en                                  ),
    .nvm_act_type                 ( nvm_act_type                                ),
    .nvm_sf_en                    ( nvm_sf_en                                   ),
    .nvm_ln_en                    ( nvm_ln_en                                   ),
    .nvm_tr_en                    ( nvm_tr_en                                   ),
    .nvm_rnum                     ( nvm_rnum                                    ),
    .nvm_rstep                    ( nvm_rstep                                   ),
    .nvm_xnum                     ( nvm_xnum                                    ),
    .nvm_ynum                     ( nvm_ynum                                    ),
    .nvm_bnum                     ( nvm_bnum                                    ),
    .nvm_gnum                     ( nvm_gnum                                    ),
    .nvm_idir                     ( nvm_idir                                    ),
    .nvm_inum                     ( nvm_inum                                    ),
    .nvm_odir                     ( nvm_odir                                    ),
    .nvm_onum                     ( nvm_onum                                    ),
    .nvm_router                   ( nvm_router                                  ),
    .ddr_rdone                    ( ddr_rdone                                   ),
    .ifm_rdone_inst               ( ifm_rdone_inst                              ),
    .ofm_rdone                    ( ofm_rdone                                   ),
    .ofm_rdone_final              ( ofm_rdone_final                             ), 
    .nvm_rdone                    ( nvm_rdone                                   ),    
    .ddr_wdone                    ( ddr_wdone                                   ),
    //----------------------------
    .layer_final                  ( layer_final                                 ),
    .layer_start                  ( layer_start                                 ),
    .layer_start_init             ( layer_start_init                            ),
    .layer_start_sync             ( layer_start_sync                            ),
    .opcode_cnt                   ( core_opcode_cnt                             ),
    .core_offset                  ( core_offset                                 ),
    .core_offset_high             ( core_offset_high                            ),   
    .core_start                   ( core_start                                  ), 
    .clk                          ( clk                                         ),
    .reset                        ( r_reset[1]                                  ) 
  );


//----------------------------------------------------------------------------------
// input feature map data
//----------------------------------------------------------------------------------

  (*keep_hierarchy="yes"*)ifm_top_sparse #( 
    .DW                           ( DW                                          ),
    .NUM                          ( NUM                                         ),    
    .CYCLE_NUM                    ( 64                                          ) 
  ) u_ifm_top_sparse (
    .clk                          ( clk                                         ),
    .reset                        ( r_reset[2]                                  ),
    .ifm_wstart                   ( rid_wstart[1]                               ),       
    .ifm_wdata                    ( ddr_load_data_ifm                           ),
    .ifm_wvld                     ( ddr_load_vld_ifm                            ),    
    .ifm_pp                       ( ifm_pp                                      ),    
    .ifm_rstart                   ( ifm_rstart                                  ),
    .ifm_rkeep                    ( ifm_rkeep                                   ),
    .ifm_wmin                     ( ifm_wmin                                    ),
    .ifm_wmax                     ( ifm_wmax                                    ),
    .ifm_ws                       ( ifm_ws                                      ),
    .ifm_hmin                     ( ifm_hmin                                    ),
    .ifm_hmax                     ( ifm_hmax                                    ),
    .ifm_hs                       ( ifm_hs                                      ),
    .ifm_rsel                     ( ifm_rsel                                    ),
    .ifm_rdone_inst               ( ifm_rdone_inst                              ),
    .ifm_rdata                    ( ifm_dma_data                                ),
    .ifm_rdata_vld                ( ifm_dma_vld                                 ),
    .ifm_rdata_done               ( ifm_dma_done                                )
  );

  always @(posedge clk)
  //------------------------------
  `ifdef SIM_CODE
  if(reset)begin
    r_ifm_dma_data                <=0                                           ;
    r_ifm_dma_vld                 <=0                                           ;
    r_ifm_dma_done                <=0                                           ;
  end else
  `endif
  //------------------------------
  begin
    r_ifm_dma_data                <=ifm_dma_data                                ;
    r_ifm_dma_vld                 <=ifm_dma_vld                                 ;
    r_ifm_dma_done                <=ifm_dma_done                                ;
  end

`ifdef PE_SPARSE
  (*keep_hierarchy="yes"*)ker_top_sparse #(
    .DW                           ( DW                                          ),
    .NUM                          ( NUM                                         )
  ) u_ker_top_sparse              ( 
    .clk                          ( clk                                         ),
    .reset                        ( r_reset[3]                                  ),
    .ker_wstart                   ( rid_wstart[2]                               ),
    .ker_wdata                    ( ddr_load_data_ker                           ),
    .ker_wvld                     ( ddr_load_vld_ker                            ),
    .ker_pp                       ( ker_pp                                      ),
    .ker_rstart                   ( ifm_rstart                                  ),
    .ker_hold                     ( ifm_wmax                                    ),
    .ker_addr_vld                 ( ker_dma_addr_vld                            ),
    .ker_addr_cnt                 ( ker_dma_addr_cnt                            ),
    .ker_addr_rpp                 ( ker_dma_addr_rpp                            ),
    .ker_rdata                    ( ker_dma_data                                ),
    .ker_rdata_vld                ( ker_dma_vld                                 ),    
    .ker_rdata_start              ( ker_dma_start                               )            
);

  always @(posedge clk)
  //------------------------------
  `ifdef SIM_CODE
  if(reset)begin
    r_ker_dma_data                <=0                                           ;
    r_ker_dma_vld                 <=0                                           ;
    r_ker_dma_start               <=0                                           ;
  end else
  `endif
  //------------------------------
  begin
    r_ker_dma_data                <=ker_dma_data                                ;
    r_ker_dma_vld                 <=ker_dma_vld                                 ;
    r_ker_dma_start               <=ker_dma_start                               ;
  end

  (*keep_hierarchy="yes"*)bm_bitmask_top# (
    .NUM                          ( 16                                          ),
    .IDW                          ( 32                                          ),
    .ODW                          ( DW_BM                                       ), 
    .ID                           ( ID                                          ),
    .CA                           ( CA                                          ), 
    .ME                           ( ME                                          ),
    .BM                           ( BM                                          )       
  )u_bm_bitmask_top(
    .clk                          ( clk                                         ),
    .reset                        ( r_reset[4]                                  ),
    .bm_no_ebale                  ( bm_no_ebale                                 ),
    .bm_wstart                    ( rid_wstart[2]                               ),
    .bm_pp                        ( ker_pp                                      ),
    .bm_wvld                      ( ddr_load_vld_bm                             ),
    .bm_wdata                     ( ddr_load_data_bm                            ),//ddr_load_vld_bm?{512{1'b1}}:0                                      
    .ker_addr_vld                 ( ker_dma_addr_vld                            ),  
    .ker_addr_cnt                 ( ker_dma_addr_cnt                            ),       
    .ker_addr_rpp                 ( ker_dma_addr_rpp                            ),
    .bm_rdata                     ( bm_dma_data                                 )
  );
  always @(posedge clk)
  //------------------------------
  `ifdef SIM_CODE
  if(reset)r_bm_dma_data          <=0                                           ; 
  else
  `endif
  //------------------------------
   r_bm_dma_data                  <=bm_dma_data                                 ;
`endif



//-----------------------------------------------------------------------------------
// Matrix compute array.
//-----------------------------------------------------------------------------------

`ifdef PE_SPARSE
  (*keep_hierarchy="yes"*)pe_sparse_top #(
    .ROW                          ( 32                                          ),
    .COL                          ( 32                                          ),
    .NUM                          ( NUM                                         ),
    .IDW                          ( DW                                          ),
    .ODW                          ( DW_PE                                       ),
    .ID                           ( ID                                          ),
    .CA                           ( CA                                          ), 
    .ME                           ( ME                                          ),
    .BM                           ( BM                                          ), 
    .PNUM                         ( PNUM                                        )
  ) u_pe_sparse_top (
    .clk                          ( clk                                         ),
    .reset                        ( r_reset[5]                                  ),
    .dina                         ( r_ifm_dma_data                              ),
    .dina_vld                     ( r_ifm_dma_vld                               ),
    .dina_done                    ( r_ifm_dma_done                              ), 
    .dinb                         ( r_ker_dma_data                              ),
    .dinb_bm                      ( r_bm_dma_data                               ),
    .dinb_vld                     ( r_ker_dma_vld                               ),
    .dinb_start                   ( r_ker_dma_start                             ),

    .dout                         ( pe_result_data                              ),
    .dout_vld                     ( pe_result_vld                               ),
    .dout_meg                     ( pe_result_meg                               )
  );
  always @(posedge clk)
  //------------------------------
  `ifdef SIM_CODE
  if(reset)begin
    r_pe_result_data              <=0                                           ;
    r_pe_result_vld               <=0                                           ;
    r_pe_result_meg               <=0                                           ;
  end else
  `endif
  //------------------------------
  begin
    r_pe_result_data             <=pe_result_data                               ;
    r_pe_result_vld              <=pe_result_vld                                ;
    r_pe_result_meg              <=pe_result_meg                                ;
  end
`endif


//-----------------------------------------------------------------------------------
// bias data
//-----------------------------------------------------------------------------------

  (*keep_hierarchy="yes"*)bias_top_sparse #(
    .NUM                          ( NUM                                         ),
    .DW                           ( DW                                          ),
    .PNUM                         ( PNUM                                        ),
    .BDW                          ( DW_BIAS                                     )
  ) u_bias_top_sparse (
    .bias_wstart                  ( rid_wstart[3]                               ),
    .bias_wvld                    ( ddr_load_vld_bias                           ),    
    .bias_wdata                   ( ddr_load_data_bias                          ),
    .bias_pp                      ( bias_pp                                     ),
    .bias_rdata                   ( bias_dma_data                               ),
    .clk                          ( clk                                         ),
    .reset                        ( r_reset[6]                                  )
  );
  always @(posedge clk)            r_bias_dma_data<=bias_dma_data               ;



//-----------------------------------------------------------------------------------
// output buffer map
//-----------------------------------------------------------------------------------
  always @(posedge clk)
  begin
      nvm_res_raddr_vld         <= nvm_res_en&nvm_raddr_vld                     ;
      nvm_res_raddr             <= nvm_raddr                                    ;
      r_nvm_res_rdata           <= nvm_res_rdata                                ;
      r_nvm_res_rdata_vld       <= nvm_res_rdata_vld                            ;
  end

  (*keep_hierarchy="yes"*)ofm_top_sparse #(
    .NUM                          ( NUM                                         ),
    .PNUM                         ( PNUM                                        ),
    .DW_PE                        ( DW_PE                                       ),
    .DW_OFM                       ( 37                                          ),
    .DW_BIAS                      ( DW_BIAS                                     ),
    .DW_NVM                       ( DW_NVM                                      ) 
  ) u_ofm_top_sparse (
    .clk                          ( clk                                         ),
    .reset                        ( r_reset[7]                                  ),  
    
    .ofm_din_enc                  ( ofm_din_enc                                 ),
    .ofm_concat_num               ( ofm_concat_num                              ),
    .ofm_din_snum                 ( ofm_din_snum                                ),
    .ofm_bias_snum                ( ofm_bias_snum                               ),
    .ofm_rstart                   ( ofm_rstart                                  ),
    .ofm_wbase                    ( ofm_wbase                                   ),
    .ofm_rbase                    ( ofm_rbase                                   ),    
    .ofm_pp                       ( ofm_pp                                      ),
    .ofm_bias_sel                 ( ofm_bias_sel                                ),
    .ofm_tmp_sel                  ( ofm_tmp_sel                                 ),
    .ofm_output_sel               ( ofm_output_sel                              ),
    .ofm_bias_data                ( r_bias_dma_data                             ),
    .ofm_din                      ( r_pe_result_data                            ),
    .ofm_din_vld                  ( r_pe_result_vld                             ),
    .ofm_din_meg                  ( r_pe_result_meg                             ),
    .ofm_rdone                    ( ofm_rdone                                   ),
    .ofm_rdone_final              ( ofm_rdone_final                             ),
    .nvm_res_en                   ( nvm_res_en                                  ),
    .res_load_data                ( ddr_load_data_res                           ),
    .res_load_vld                 ( ddr_load_vld_res                            ),
    .res_load_done                ( ddr_load_vld_res&ddr_rdone                  ),
    .nvm_res_rdata                ( nvm_res_rdata                               ), 
    .nvm_res_rdata_vld            ( nvm_res_rdata_vld                           ),
    .nvm_raddr                    ( nvm_raddr                                   ),
    .nvm_raddr_vld                ( nvm_raddr_vld                               ),
    .nvm_raddr_done               ( nvm_raddr_done                              ),
    .nvm_rdata                    ( nvm_rdata                                   ),
    .nvm_rdata_vld                ( nvm_rdata_vld                               ),
    .nvm_rdata_done               ( nvm_rdata_done                              ),
    .back_waddr                   ( r_nvm_back_waddr                            ),                     
    .back_wdata                   ( r_nvm_back_wdata                            ),
    .back_wvld                    ( r_nvm_back_wvld                             ),
    .back_wdone                   ( r_nvm_back_wdone                            ),
    .back_raddr                   ( nvm_back_raddr                              ),
    .back_raddr_vld               ( nvm_back_raddr_vld                          ),
    .back_rdata                   ( nvm_back_rdata                              ),
    .back_rdata_vld               ( nvm_back_rdata_vld                          ) 
  );


//-----------------------------------------------------------------------------------
// post proess
//-----------------------------------------------------------------------------------
  assign  nvm_start_init  =nvm_rstart                                           ;
  always @(posedge clk)nvm_back_en
  <=~(nvm_tr_en|nvm_act_en|(nvm_res_en&&(~nvm_ln_en))
  |((~nvm_tr_en)&&(~nvm_res_en)&&(~nvm_ln_en)
   &&(~nvm_act_en)&&(~nvm_sf_en)&&(~nvm_sf_en)))                                ;  

  wire [NUM*1 -1:0]        nvm_divisor_tvalid                                   ;
  wire [NUM*24-1:0]        nvm_divisor_tdata                                    ;
  wire [NUM*1 -1:0]        nvm_dividend_tvalid                                  ;
  wire [NUM*24-1:0]        nvm_dividend_tdata                                   ;
  wire [NUM*1 -1:0]        nvm_dout_tvalid                                      ;
  wire [NUM*40-1:0]        nvm_dout_tdata                                       ;

  (*dont_touch="true"*)reg [NUM*1 -1:0] r_nvm_divisor_tvalid =0                 ;
  (*dont_touch="true"*)reg [NUM*24-1:0] r_nvm_divisor_tdata  =0                 ;
  (*dont_touch="true"*)reg [NUM*1 -1:0] r_nvm_dividend_tvalid=0                 ;
  (*dont_touch="true"*)reg [NUM*24-1:0] r_nvm_dividend_tdata =0                 ;
  (*dont_touch="true"*)reg [NUM*1 -1:0] r_nvm_dout_tvalid    =0                 ;
  (*dont_touch="true"*)reg [NUM*40-1:0] r_nvm_dout_tdata     =0                 ;

  wire [NUM*24-1:0]        nvm_A_dsp0_out                                       ; 
  wire [NUM*16-1:0]        nvm_B_dsp0_out                                       ; 
  wire [NUM*40-1:0]        nvm_C_dsp0_out                                       ; 
  wire [NUM*24-1:0]        nvm_D_dsp0_out                                       ; 
  wire [NUM*40-1:0]        nvm_P_dsp0_in                                        ;
  wire [NUM*17-1:0]        nvm_A_dsp1_out                                       ; 
  wire [NUM*17-1:0]        nvm_B_dsp1_out                                       ; 
  wire [NUM*34-1:0]        nvm_C_dsp1_out                                       ; 
  wire [NUM*17-1:0]        nvm_D_dsp1_out                                       ; 
  wire [NUM*34-1:0]        nvm_P_dsp1_in                                        ;

  (*dont_touch="true"*)reg [NUM*24-1:0]r_nvm_A_dsp0_out=0                       ; 
  (*dont_touch="true"*)reg [NUM*16-1:0]r_nvm_B_dsp0_out=0                       ; 
  (*dont_touch="true"*)reg [NUM*40-1:0]r_nvm_C_dsp0_out=0                       ; 
  (*dont_touch="true"*)reg [NUM*24-1:0]r_nvm_D_dsp0_out=0                       ; 
  (*dont_touch="true"*)reg [NUM*40-1:0]r_nvm_P_dsp0_in =0                       ;
  (*dont_touch="true"*)reg [NUM*17-1:0]r_nvm_A_dsp1_out=0                       ; 
  (*dont_touch="true"*)reg [NUM*17-1:0]r_nvm_B_dsp1_out=0                       ; 
  (*dont_touch="true"*)reg [NUM*34-1:0]r_nvm_C_dsp1_out=0                       ; 
  (*dont_touch="true"*)reg [NUM*17-1:0]r_nvm_D_dsp1_out=0                       ; 
  (*dont_touch="true"*)reg [NUM*34-1:0]r_nvm_P_dsp1_in =0                       ;


  wire [2*40-1:0]          ln_mean_dividend                                     ;
  wire [2*16-1:0]          ln_mean_divisor                                      ;
  wire [2*48-1:0]          ln_mean_result                                       ;
  (*dont_touch="true"*)reg [2*40-1:0] r_ln_mean_dividend =0                     ;
  (*dont_touch="true"*)reg [2*16-1:0] r_ln_mean_divisor  =0                     ;
  (*dont_touch="true"*)reg [2*48-1:0] r_ln_mean_result   =0                     ;



  always @(posedge clk)
  begin
    r_nvm_rdata          <=nvm_rdata                                            ;
    r_nvm_rdata_vld      <=nvm_rdata_vld                                        ;
    r_nvm_rdata_done     <=nvm_rdata_done                                       ;
    r_nvm_back_waddr     <=nvm_back_waddr                                       ;
    r_nvm_back_wdata     <=nvm_back_wdata                                       ;
    r_nvm_back_wvld      <={4{nvm_back_wvld}}                                   ;
    r_nvm_back_wdone     <=nvm_back_wdone                                       ;
    r_nvm_back_rdata     <=nvm_back_rdata                                       ;
    r_nvm_back_rvld      <=nvm_back_rdata_vld                                   ;
    r_ddr_store_data     <=ddr_store_data                                       ;
    r_ddr_store_vld      <=ddr_store_vld                                        ;
  end

  always @(posedge clk)
  begin
    r_nvm_divisor_tvalid <=nvm_divisor_tvalid                                   ;
    r_nvm_divisor_tdata  <=nvm_divisor_tdata                                    ;
    r_nvm_dividend_tvalid<=nvm_dividend_tvalid                                  ;
    r_nvm_dividend_tdata <=nvm_dividend_tdata                                   ;
    r_nvm_dout_tvalid    <=nvm_dout_tvalid                                      ;
    r_nvm_dout_tdata     <=nvm_dout_tdata                                       ;
  end

  always @(posedge clk)
  begin
    r_nvm_A_dsp0_out     <=nvm_A_dsp0_out                                       ;
    r_nvm_B_dsp0_out     <=nvm_B_dsp0_out                                       ;
    r_nvm_C_dsp0_out     <=nvm_C_dsp0_out                                       ;
    r_nvm_D_dsp0_out     <=nvm_D_dsp0_out                                       ;
    r_nvm_P_dsp0_in      <=nvm_P_dsp0_in                                        ;
    r_nvm_A_dsp1_out     <=nvm_A_dsp1_out                                       ;
    r_nvm_B_dsp1_out     <=nvm_B_dsp1_out                                       ;
    r_nvm_C_dsp1_out     <=nvm_C_dsp1_out                                       ;
    r_nvm_D_dsp1_out     <=nvm_D_dsp1_out                                       ;
    r_nvm_P_dsp1_in      <=nvm_P_dsp1_in                                        ;
  end

  always @(posedge clk)
  begin
    r_ln_mean_dividend   <=ln_mean_dividend                                     ;
    r_ln_mean_divisor    <=ln_mean_divisor                                      ;
    r_ln_mean_result     <=ln_mean_result                                       ;
  end

  assign nvm_sum_init[128-1:80]    =0                                           ;

  (*keep_hierarchy="yes"*)nvm_top #(
    .DW                           ( DW                                          ),
    .NUM                          ( NUM                                         ),
    .PLEN                         ( 24                                          ) 
  ) u_nvm_top (
    .clk                          ( clk                                         ),
    .reset                        ( r_reset[8]                                  ),
    .layer_cnt                    ( core_layer_cnt                              ),
    .nvm_back_en                  ( nvm_back_en                                 ),//nvm_back_en
    .nvm_rnum                     ( nvm_rnum                                    ),//nvm_rnum   
    .nvm_rstep                    ( nvm_rstep                                   ),//nvm_rstep  
    .nvm_xnum                     ( nvm_xnum                                    ),//nvm_xnum   
    .nvm_ynum                     ( nvm_ynum                                    ),//nvm_ynum   
    .nvm_bnum                     ( nvm_bnum                                    ),
    .nvm_gnum                     ( nvm_gnum                                    ),
    .nvm_sync                     ( nvm_router                                  ),
    .nvm_idir                     ( nvm_idir                                    ),
    .nvm_inum                     ( nvm_inum                                    ),
    .nvm_odir                     ( nvm_odir                                    ),
    .nvm_onum                     ( nvm_onum                                    ),
    .nvm_sum_tx                   ( nvm_sum_init[80-1:0]                        ),
    .nvm_sum_rx                   ( nvm_sum_sync[80-1:0]                        ),
    .tr_en                        ( nvm_tr_en                                   ),//nvm_tr_en   
    .res_en                       ( nvm_res_en                                  ),//nvm_res_en  
    .ln_en                        ( nvm_ln_en                                   ),//nvm_ln_en   
    .act_en                       ( nvm_act_en                                  ),//nvm_act_en  
    .sf_en                        ( nvm_sf_en                                   ),//nvm_sf_en   
    .act_type                     ( nvm_act_type                                ),//nvm_act_type 
    .nvm_start                    ( nvm_start_sync                              ),//nvm_start_sync,core_start
    .nvm_done                     ( nvm_rdone                                   ),
    .nvm_raddr                    ( nvm_raddr                                   ),
    .nvm_raddr_vld                ( nvm_raddr_vld                               ),
    .nvm_raddr_done               ( nvm_raddr_done                              ),
    .nvm_rdata                    ( r_nvm_rdata                                 ),
    .nvm_rdata_vld                ( r_nvm_rdata_vld                             ),
    .nvm_rdata_done               ( r_nvm_rdata_done                            ),
    .res_rdata                    ( r_nvm_res_rdata                             ),
    .res_rvld                     ( r_nvm_res_rdata_vld                         ),
    .gamma_wdata                  ( ddr_load_data_gamma                         ),
    .gamma_wvld                   ( ddr_load_vld_gamma                          ),
    .gamma_wstart                 ( rid_wstart[7]                               ),
    .beta_wdata                   ( ddr_load_data_beta                          ),
    .beta_wvld                    ( ddr_load_vld_beta                           ),
    .beta_wstart                  ( rid_wstart[6]                               ), 
      
    .back_waddr                   ( nvm_back_waddr                              ),              
    .back_wdata                   ( nvm_back_wdata                              ),
    .back_wvld                    ( nvm_back_wvld                               ),
    .back_wdone                   ( nvm_back_wdone                              ),
    
    .back_raddr                   ( nvm_back_raddr                              ),
    .back_raddr_vld               ( nvm_back_raddr_vld                          ),
    
    .back_rdata                   ( r_nvm_back_rdata                            ),
    .back_rdata_vld               ( r_nvm_back_rvld                             ),
    
    .ddr_wdata                    ( ddr_store_data                              ),
    .ddr_wvld                     ( ddr_store_vld                               ),
    .s_axis_divisor_tvalid        (   nvm_divisor_tvalid                        ),
    .s_axis_divisor_tdata         (   nvm_divisor_tdata                         ),
    .s_axis_dividend_tvalid       (   nvm_dividend_tvalid                       ),
    .s_axis_dividend_tdata        (   nvm_dividend_tdata                        ),
    .m_axis_dout_tvalid           ( r_nvm_dout_tvalid                           ),
    .m_axis_dout_tdata            ( r_nvm_dout_tdata                            ),
    .A_dsp0_out                   (   nvm_A_dsp0_out                            ),
    .B_dsp0_out                   (   nvm_B_dsp0_out                            ),
    .C_dsp0_out                   (   nvm_C_dsp0_out                            ),
    .D_dsp0_out                   (   nvm_D_dsp0_out                            ),
    .P_dsp0_in                    ( r_nvm_P_dsp0_in                             ),
    .A_dsp1_out                   (   nvm_A_dsp1_out                            ),
    .B_dsp1_out                   (   nvm_B_dsp1_out                            ),
    .C_dsp1_out                   (   nvm_C_dsp1_out                            ),
    .D_dsp1_out                   (   nvm_D_dsp1_out                            ),
    .P_dsp1_in                    ( r_nvm_P_dsp1_in                             ),
    .ln_mean_dividend             (   ln_mean_dividend                          ),
    .ln_mean_divisor              (   ln_mean_divisor                           ),
    .ln_mean_result               ( r_ln_mean_result                            )
  );

(*keep_hierarchy="yes"*)nvm_div_top#(
.IDW(24),.ODW(40),.NUM(32)                        
)u_nvm_div(
    .aclk                         ( clk                                         ),
    .aresetn                      ( r_reset[9]                                  ),
    .s_axis_divisor_tvalid        ( r_nvm_divisor_tvalid                        ),
    .s_axis_divisor_tdata         ( r_nvm_divisor_tdata                         ),
    .s_axis_dividend_tvalid       ( r_nvm_dividend_tvalid                       ),
    .s_axis_dividend_tdata        ( r_nvm_dividend_tdata                        ),
    .m_axis_dout_tvalid           (   nvm_dout_tvalid                           ),
    .m_axis_dout_tdata            (   nvm_dout_tdata                            ),
    .ln_mean_dividend             ( r_ln_mean_dividend                          ),
    .ln_mean_divisor              ( r_ln_mean_divisor                           ),
    .ln_mean_result               (   ln_mean_result                            )    
);

(*keep_hierarchy="yes"*)nvm_dsp_top #(
    .NUM(32) 
)u_nvm_dsp(
    .clk                          ( clk                                         ),    
    .A_dsp0                       ( r_nvm_A_dsp0_out                            ), 
    .B_dsp0                       ( r_nvm_B_dsp0_out                            ), 
    .C_dsp0                       ( r_nvm_C_dsp0_out                            ), 
    .D_dsp0                       ( r_nvm_D_dsp0_out                            ), 
    .P_dsp0                       (   nvm_P_dsp0_in                             ),
    .A_dsp1                       ( r_nvm_A_dsp1_out                            ), 
    .B_dsp1                       ( r_nvm_B_dsp1_out                            ), 
    .C_dsp1                       ( r_nvm_C_dsp1_out                            ), 
    .D_dsp1                       ( r_nvm_D_dsp1_out                            ), 
    .P_dsp1                       (   nvm_P_dsp1_in                             )
);


//----------------------------------------------------------------------------------
//
//----------------------------------------------------------------------------------
//(*keep_hierarchy="yes"*)
//kvcache_top u_kvcache_top
//(
//);




//----------------------------------------------------------------------------------
// util for debug
//----------------------------------------------------------------------------------
`ifdef SIM_CODE
 reg            axi_util_load =0                                                ;
 reg            axi_util_store=0                                                ;
 always @(posedge clk)
 begin
     if(m_axi_arvalid&&m_axi_arready)   axi_util_load <=1                       ;
     else if(m_axi_rlast&&m_axi_rvalid) axi_util_load <=0                       ;
 
     if(m_axi_bvalid&&m_axi_bready)     axi_util_store<=0                       ;
     else if(m_axi_wvalid)              axi_util_store<=1                       ;
 end
`endif


`ifdef SIM_CODE
 reg    test_ifm_pp     =   0                                                   ;
 reg    test_ker_pp     =   0                                                   ;
 wire   test_ifm_rstart =   ifm_rstart&&(test_ifm_pp!=ifm_pp)                   ;
 wire   test_ker_rstart =   ifm_rstart&&(test_ker_pp!=ker_pp)                   ;
 
 always @(posedge clk)
 begin
     test_ifm_pp        <=  ifm_pp                                              ;
     test_ker_pp        <=  ker_pp                                              ;
 end
 
 always @(*)
 if(ddr_wdone)
 begin
        ifm_pp_cnt      =   0                                                   ;
        ker_pp_cnt      =   0                                                   ;
 end 
 else if(test_ifm_rstart)
 begin
        ifm_pp_cnt      =   ifm_pp_cnt+1                                        ;
        ker_pp_cnt      =   1                                                   ;
 end 
 else if(test_ker_rstart)
 begin
        ifm_pp_cnt      =   ifm_pp_cnt                                          ;
        ker_pp_cnt      =   ker_pp_cnt+1                                        ;
 end

 always @(*)for(i=0;i<DW_DDR;i=i+1)test_ddr_load_data_bm[i] <=ddr_load_data_bm[i*NUM+:NUM]                  ;
 always @(*)for(i=0;i<NUM ;i=i+1)test_ddr_load_data_ker[i]  <=ddr_load_data_ker[i*DW_DDR+:DW_DDR]           ;
 always @(*)for(i=0;i<NUM ;i=i+1)test_ddr_load_data_ifm[i]  <=ddr_load_data_ifm[i*DW_DDR+:DW_DDR]           ;
 
 always @(*)for(i=0;i<NUM ;i=i+1)test_ifm_dma_data[i]       <=ifm_dma_data[i*DW_IFM+:DW_IFM]                ;
 always @(*)for(i=0;i<NUM ;i=i+1)test_ker_dma_data[i]       <=ker_dma_data[i*DW_KER+:DW_KER]                ;
 
 always @(*)for(i=0;i<NUM ;i=i+1)test_bm_dma_data_ID[i]     <=bm_dma_data [i*DW_BM+BM+ME+CA+:ID]            ;
 always @(*)for(i=0;i<NUM ;i=i+1)test_bm_dma_data_CA[i]     <=bm_dma_data [i*DW_BM+BM+ME   +:CA]            ;
 always @(*)for(i=0;i<NUM ;i=i+1)test_bm_dma_data_ME[i]     <=bm_dma_data [i*DW_BM+BM      +:ME]            ;
 always @(*)for(i=0;i<NUM ;i=i+1)test_bm_dma_data_BM[i]     <=bm_dma_data [i*DW_BM         +:BM]            ;

 always @(*)for(i=0;i<NUM ;i=i+1)
            for(j=0;j<PNUM;j=j+1)test_pe_result_data[i][j]  <=pe_result_data[i*(PNUM*DW_PE)+j*DW_PE+:DW_PE] ;
 always @(*)for(i=0;i<NUM ;i=i+1)test_pe_result_vld [i]     <=pe_result_vld[i*PNUM+:PNUM]                   ;
 always @(*)for(i=0;i<NUM ;i=i+1)test_pe_result_meg [i]     <=pe_result_meg[i]                              ;
`endif



endmodule
