`timescale 1ns / 1ps
// -----------------------------------------------------------------------------
// Copyright      : UCLA EDA LAB
// -----------------------------------------------------------------------------
// Engineer       : Chen Wu
// Design Name    : opu series
// Module Name    : ddr_top
// Target Devices : 325t, Alveo U200
// Tool Versions  : Vivado 2020.1, Modelsim 2019.4
// Description    : 
//    Read DDR in burst mode several times
//    Write DDR in burst mode several times 
//
// Revision       :
// Version        Date        Author        Descriptin
// 1.0            2022-03-30  Chen Wu       Initial version
// 2.0            2023-08-25  Shaoqiang     Simulation 97 layers,and
//                                          implementation on FPGA of U200.
// -----------------------------------------------------------------------------

module ddr_top (
  input                             clk                         ,
  input                             reset                       ,
  input                             core_init_finish            ,
  //aw
  output  wire  [    4  -1 : 0]     m_axi_awid                  ,
  output  wire                      m_axi_awlock                ,
  output  wire  [    4  -1 : 0]     m_axi_awcache               ,
  output  wire  [    3  -1 : 0]     m_axi_awprot                ,
  output  wire  [    4  -1 : 0]     m_axi_awqos                 ,
  output  wire  [    64 -1 : 0]     m_axi_awaddr                ,
  output  wire  [    8  -1 : 0]     m_axi_awlen                 ,
  output  wire  [    3  -1 : 0]     m_axi_awsize                ,
  output  wire  [    2  -1 : 0]     m_axi_awburst               ,
  output  wire                      m_axi_awvalid               ,
  input                             m_axi_awready               ,  
  //w
  output  wire  [    512-1 : 0]     m_axi_wdata                 ,
  output  wire                      m_axi_wlast                 ,
  output  wire                      m_axi_wvalid                ,
  input                             m_axi_wready                ,
  output  wire  [    64- 1 : 0]     m_axi_wstrb                 ,
  //b
  input         [    4  -1 : 0]     m_axi_bid                   ,
  input         [    2  -1 : 0]     m_axi_bresp                 ,
  input                             m_axi_bvalid                ,
  output  wire                      m_axi_bready                ,
  //ar
  output  wire                      m_axi_arlock                ,
  output  wire  [    4  -1 : 0]     m_axi_arcache               ,
  output  wire  [    3  -1 : 0]     m_axi_arprot                ,
  output  wire  [    4  -1 : 0]     m_axi_arqos                 ,
  output  wire  [    4  -1 : 0]     m_axi_arid                  ,
  output  wire  [    64 -1 : 0]     m_axi_araddr                ,
  output  wire  [    8  -1 : 0]     m_axi_arlen                 ,
  output  wire  [    3  -1 : 0]     m_axi_arsize                ,
  output  wire  [    2  -1 : 0]     m_axi_arburst               ,
  output  wire                      m_axi_arvalid               ,
  input                             m_axi_arready               ,
  //r
  output  wire                      m_axi_rready                ,
  
  input                             m_axi_rvalid                ,
  input                             m_axi_rlast                 ,
  input         [    4  -1 : 0]     m_axi_rid                   ,
  input         [    2  -1 : 0]     m_axi_rresp                 ,

  output  wire                      ddr_load_vld_ifm            , 
  output  wire                      ddr_load_vld_bm             , 
  output  wire  [2-1:0]             ddr_load_vld_ker            ,
  output  wire                      ddr_load_vld_bias           ,
  output  wire                      ddr_load_vld_res            ,
  output  wire                      ddr_load_vld_ins            ,
  output  wire                      ddr_load_vld_beta           , 
  output  wire                      ddr_load_vld_gamma          , 
  
  output  wire                      ddr_rdone                   ,
  input                             ddr_rstart                  ,
  input         [      4-1 : 0]     ddr_roffset_high            ,
  input         [     25-1 : 0]     ddr_roffset                 ,
  input         [     25-1 : 0]     ddr_rstride                 ,
  input         [     7 -1 : 0]     ddr_rstep_num               ,  
  input         [     15-1 : 0]     ddr_rstep                   ,
  input         [      4-1 : 0]     ddr_rid                     ,
  input         [     15-1 : 0]     ddr_bm_num                  ,
  input                             ddr_bm_en                   ,
  
  output  wire                      ddr_wdone                   ,
  input         [     25-1 : 0]     ddr_woffset                 ,
  input         [      4-1 : 0]     ddr_woffset_high            ,
  input         [     15-1 : 0]     ddr_wstep                   ,
  input         [      7-1 : 0]     ddr_wstep_num               ,
  input         [     25-1 : 0]     ddr_wstride                 ,
  input                             ddr_wstart                  ,
  input         [    512-1 : 0]     ddr_store_data              ,
  input                             ddr_store_vld                  
  );

  (*keep_hierarchy="yes"*)ddr_load u0_ddr_load(
  .clk                          ( clk                           ),
  .reset                        ( reset                         ),
  .core_init_finish             ( core_init_finish              ),   
  .m_axi_arlock                 ( m_axi_arlock                  ),
  .m_axi_arcache                ( m_axi_arcache                 ),
  .m_axi_arprot                 ( m_axi_arprot                  ),
  .m_axi_arqos                  ( m_axi_arqos                   ),
  .m_axi_arid                   ( m_axi_arid                    ),
  .m_axi_araddr                 ( m_axi_araddr                  ),
  .m_axi_arlen                  ( m_axi_arlen                   ),
  .m_axi_arsize                 ( m_axi_arsize                  ),
  .m_axi_arburst                ( m_axi_arburst                 ),
  .m_axi_arvalid                ( m_axi_arvalid                 ),
  .m_axi_arready                ( m_axi_arready                 ),
  .m_axi_rready                 ( m_axi_rready                  ),
  
  .m_axi_rvalid                 ( m_axi_rvalid                  ),
  .m_axi_rlast                  ( m_axi_rlast                   ),
  .m_axi_rid                    ( m_axi_rid                     ),
  .m_axi_rresp                  ( m_axi_rresp                   ),
  .ddr_load_vld_ifm             ( ddr_load_vld_ifm              ),
  .ddr_load_vld_bm              ( ddr_load_vld_bm               ),
  .ddr_load_vld_ker             ( ddr_load_vld_ker              ),
  .ddr_load_vld_bias            ( ddr_load_vld_bias             ),
  .ddr_load_vld_res             ( ddr_load_vld_res              ),
  .ddr_load_vld_ins             ( ddr_load_vld_ins              ),
  .ddr_load_vld_beta            ( ddr_load_vld_beta             ),
  .ddr_load_vld_gamma           ( ddr_load_vld_gamma            ),
  
  .ddr_rdone                    ( ddr_rdone                     ),
  .ddr_rstart                   ( ddr_rstart                    ),
  .ddr_roffset_high             ( ddr_roffset_high              ),
  .ddr_roffset                  ( ddr_roffset                   ),
  .ddr_rstride                  ( ddr_rstride                   ),
  .ddr_rstep_num                ( ddr_rstep_num                 ), 
  .ddr_rstep                    ( ddr_rstep                     ),
  .ddr_rid                      ( ddr_rid                       ),
  .ddr_bm_num                   ( ddr_bm_num                    ),
  .ddr_bm_en                    ( ddr_bm_en                     )
  );

  (*keep_hierarchy="yes"*)ddr_store u0_ddr_store (
    .clk                        ( clk                           ),
    .reset                      ( reset                         ),
    .core_init_finish           ( core_init_finish              ),
    .m_axi_awid                 ( m_axi_awid                    ),
    .m_axi_awlock               ( m_axi_awlock                  ),
    .m_axi_awcache              ( m_axi_awcache                 ),
    .m_axi_awprot               ( m_axi_awprot                  ),
    .m_axi_awqos                ( m_axi_awqos                   ),
    .m_axi_awaddr               ( m_axi_awaddr                  ),
    .m_axi_awlen                ( m_axi_awlen                   ),
    .m_axi_awsize               ( m_axi_awsize                  ),
    .m_axi_awburst              ( m_axi_awburst                 ),
    .m_axi_awvalid              ( m_axi_awvalid                 ),
    .m_axi_awready              ( m_axi_awready                 ),
    .m_axi_wdata                ( m_axi_wdata                   ),
    .m_axi_wlast                ( m_axi_wlast                   ),
    .m_axi_wvalid               ( m_axi_wvalid                  ),
    .m_axi_wready               ( m_axi_wready                  ),
    .m_axi_wstrb                ( m_axi_wstrb                   ),
    .m_axi_bid                  ( m_axi_bid                     ),
    .m_axi_bresp                ( m_axi_bresp                   ),
    .m_axi_bvalid               ( m_axi_bvalid                  ),
    .m_axi_bready               ( m_axi_bready                  ),
    .ddr_wdone                  ( ddr_wdone                     ),
    .ddr_woffset                ( ddr_woffset                   ),
    .ddr_woffset_high           ( ddr_woffset_high              ),
    .ddr_wstep                  ( ddr_wstep                     ),
    .ddr_wstep_num              ( ddr_wstep_num                 ),
    .ddr_wstride                ( ddr_wstride                   ),
    .ddr_wstart                 ( ddr_wstart                    ),
    .ddr_store_data             ( ddr_store_data                ),
    .ddr_store_vld              ( ddr_store_vld                 )
  );

  
  




endmodule 