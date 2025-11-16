`timescale 1ps/1ps
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

//-------------------------------------------------------------------------------
// The top-level parameter definition
//-------------------------------------------------------------------------------

`include "opu_parameter.vh"
`include "opu_instruction.vh"
//--------------------------------------------------
// This parameter is controllerwise
// This parameter is controllerwise
// This parameter is controllerwise
// Width of all master and slave ID signals.// # = >= 1.
// Width of S_AXI_AWADDR, S_AXI_ARADDR, M_AXI_AWADDR and// M_AXI_ARADDR for all SI/MI slots. // # = 32.
// Width of WDATA and RDATA on SI slot.// Must be <= APP_DATA_WIDTH.// # = 32, 64, 128, 256.
module opu_top #
(
    parameter               nCK_PER_CLK             = 4             , 
    parameter               APP_DATA_WIDTH          = 512           , 
    parameter               APP_MASK_WIDTH          = 64            , 
    parameter               C_AXI_ID_WIDTH          = 4             ,    
    parameter               C_AXI_ADDR_WIDTH        = 34            , 
    parameter               C_AXI_DATA_WIDTH        = 512           ,           
    parameter               C_AXI_NBURST_SUPPORT    = 0             ,
    parameter               ECC                     = "ON"          ,
    parameter               SIMULATION              = "TRUE" 
)
(
    input                   c0_sys_rst                              ,
    input                   c0_sys_clk_p                            ,
    input                   c0_sys_clk_n                            ,
    output                  c0_ddr4_act_n                           ,
    output [16:0]           c0_ddr4_adr                             ,
    output [1 :0]           c0_ddr4_ba                              ,
    output [1 :0]           c0_ddr4_bg                              ,
    output                  c0_ddr4_cke                             ,
    output                  c0_ddr4_odt                             ,
    output                  c0_ddr4_cs_n                            ,
    output                  c0_ddr4_ck_t                            ,
    output                  c0_ddr4_ck_c                            ,
    output                  c0_ddr4_reset_n                         ,
    output                  c0_ddr4_parity                          ,
    inout  [71:0]           c0_ddr4_dq                              ,
    inout  [17:0]           c0_ddr4_dqs_t                           ,
    inout  [17:0]           c0_ddr4_dqs_c                           ,
    
`ifdef DESIGN_OPU_CORE2_OR_CORE4
    input                   c1_sys_rst                              ,
    input                   c1_sys_clk_p                            ,
    input                   c1_sys_clk_n                            ,
    output                  c1_ddr4_act_n                           ,
    output [16:0]           c1_ddr4_adr                             ,
    output [1 :0]           c1_ddr4_ba                              ,
    output [1 :0]           c1_ddr4_bg                              ,
    output                  c1_ddr4_cke                             ,
    output                  c1_ddr4_odt                             ,
    output                  c1_ddr4_cs_n                            ,
    output                  c1_ddr4_ck_t                            ,
    output                  c1_ddr4_ck_c                            ,
    output                  c1_ddr4_reset_n                         ,
    output                  c1_ddr4_parity                          ,
    inout  [71:0]           c1_ddr4_dq                              ,
    inout  [17:0]           c1_ddr4_dqs_t                           ,
    inout  [17:0]           c1_ddr4_dqs_c                           ,
`endif
  
`ifdef DESIGN_OPU_CORE4
    input                   c2_sys_rst                              ,
    input                   c2_sys_clk_p                            ,
    input                   c2_sys_clk_n                            ,
    output                  c2_ddr4_act_n                           ,
    output [16:0]           c2_ddr4_adr                             ,
    output [1 :0]           c2_ddr4_ba                              ,
    output [1 :0]           c2_ddr4_bg                              ,
    output                  c2_ddr4_cke                             ,
    output                  c2_ddr4_odt                             ,
    output                  c2_ddr4_cs_n                            ,
    output                  c2_ddr4_ck_t                            ,
    output                  c2_ddr4_ck_c                            ,
    output                  c2_ddr4_reset_n                         ,
    output                  c2_ddr4_parity                          ,
    inout  [71:0]           c2_ddr4_dq                              ,
    inout  [17:0]           c2_ddr4_dqs_t                           ,
    inout  [17:0]           c2_ddr4_dqs_c                           ,
    
    input                   c3_sys_rst                              ,
    input                   c3_sys_clk_p                            ,
    input                   c3_sys_clk_n                            ,
    output                  c3_ddr4_act_n                           ,
    output [16:0]           c3_ddr4_adr                             ,
    output [1 :0]           c3_ddr4_ba                              ,
    output [1 :0]           c3_ddr4_bg                              ,
    output                  c3_ddr4_cke                             ,
    output                  c3_ddr4_odt                             ,
    output                  c3_ddr4_cs_n                            ,
    output                  c3_ddr4_ck_t                            ,
    output                  c3_ddr4_ck_c                            ,
    output                  c3_ddr4_reset_n                         ,
    output                  c3_ddr4_parity                          ,
    inout  [71:0]           c3_ddr4_dq                              ,
    inout  [17:0]           c3_ddr4_dqs_t                           ,
    inout  [17:0]           c3_ddr4_dqs_c                           ,
`endif
    input                   pci_exp_rst_n                           ,
    input                   pci_exp_clk_p                           ,
    input                   pci_exp_clk_n                           ,
    output [15:0]           pci_exp_txp                             ,
    output [15:0]           pci_exp_txn                             ,
    input  [15:0]           pci_exp_rxp                             ,
    input  [15:0]           pci_exp_rxn                    
);



//----------------------------------------------------------------------------
// Asynchronous AXI Interconnection.
// The clocks of each DDR and each CORE are equal.
// M00:c0_DDR4,  M01:c1_DDR4,  M02:c2_DDR4,  M03:c3_DDR4
// S00:PCIE,     S01:CORE_1 ,  S02:CORE_2 ,  S03:CORE_3 ,  S04:CORE_4
//----------------------------------------------------------------------------
`ifdef DESIGN_OPU_CORE1
localparam                  MID            =5                       ;
localparam                  SID            =4                       ;
`elsif DESIGN_OPU_CORE2
localparam                  MID            =6                       ;
localparam                  SID            =4                       ;
`elsif DESIGN_OPU_CORE4
localparam                  MID            =7                       ;
localparam                  SID            =4                       ;
`endif
//---------------------------------------
wire                        M00_ACLK_0                              ;
wire                        M00_ARESETN_0                           ;
wire                        M00_AXI_0_arready                       ;
wire                        M00_AXI_0_arvalid                       ;
wire [63:0]                 M00_AXI_0_araddr                        ;
wire [7:0]                  M00_AXI_0_arlen                         ;
wire [2:0]                  M00_AXI_0_arsize                        ;
wire [1:0]                  M00_AXI_0_arburst                       ;
wire [MID-1:0]              M00_AXI_0_arid                          ;
wire [3:0]                  M00_AXI_0_arcache                       ;
wire [3:0]                  M00_AXI_0_arqos                         ;
wire [3:0]                  M00_AXI_0_arregion                      ;
wire [2:0]                  M00_AXI_0_arprot                        ;
wire                        M00_AXI_0_arlock                        ;
wire                        M00_AXI_0_rready                        ;
wire                        M00_AXI_0_rvalid                        ;
wire [511:0]                M00_AXI_0_rdata                         ;
wire [MID-1:0]              M00_AXI_0_rid                           ;
wire                        M00_AXI_0_rlast                         ;
wire [1:0]                  M00_AXI_0_rresp                         ;
wire                        M00_AXI_0_awready                       ;
wire                        M00_AXI_0_awvalid                       ;
wire [63:0]                 M00_AXI_0_awaddr                        ;
wire [7:0]                  M00_AXI_0_awlen                         ;
wire [2:0]                  M00_AXI_0_awsize                        ;
wire [1:0]                  M00_AXI_0_awburst                       ;
wire [MID-1:0]              M00_AXI_0_awid                          ;
wire [3:0]                  M00_AXI_0_awcache                       ;
wire [3:0]                  M00_AXI_0_awqos                         ;
wire [3:0]                  M00_AXI_0_awregion                      ;
wire [2:0]                  M00_AXI_0_awprot                        ;
wire                        M00_AXI_0_awlock                        ;
wire                        M00_AXI_0_wready                        ;
wire                        M00_AXI_0_wvalid                        ;
wire [511:0]                M00_AXI_0_wdata                         ;
wire [63:0]                 M00_AXI_0_wstrb                         ;
wire                        M00_AXI_0_wlast                         ;
wire                        M00_AXI_0_bready                        ;
wire                        M00_AXI_0_bvalid                        ;
wire [MID-1:0]              M00_AXI_0_bid                           ;
wire [1:0]                  M00_AXI_0_bresp                         ;
//
`ifdef DESIGN_OPU_CORE2_OR_CORE4
wire                        M01_ACLK_0                              ;
wire                        M01_ARESETN_0                           ;
wire                        M01_AXI_0_arready                       ;
wire                        M01_AXI_0_arvalid                       ;
wire [63:0]                 M01_AXI_0_araddr                        ;
wire [7:0]                  M01_AXI_0_arlen                         ;
wire [2:0]                  M01_AXI_0_arsize                        ;
wire [1:0]                  M01_AXI_0_arburst                       ;
wire [MID-1:0]              M01_AXI_0_arid                          ;
wire [3:0]                  M01_AXI_0_arcache                       ;
wire [3:0]                  M01_AXI_0_arqos                         ;
wire [3:0]                  M01_AXI_0_arregion                      ;
wire [2:0]                  M01_AXI_0_arprot                        ;
wire                        M01_AXI_0_arlock                        ;
wire                        M01_AXI_0_rready                        ;
wire                        M01_AXI_0_rvalid                        ;
wire [511:0]                M01_AXI_0_rdata                         ;
wire [MID-1:0]              M01_AXI_0_rid                           ;
wire                        M01_AXI_0_rlast                         ;
wire [1:0]                  M01_AXI_0_rresp                         ;
wire                        M01_AXI_0_awready                       ;
wire                        M01_AXI_0_awvalid                       ;
wire [63:0]                 M01_AXI_0_awaddr                        ;
wire [7:0]                  M01_AXI_0_awlen                         ;
wire [2:0]                  M01_AXI_0_awsize                        ;
wire [1:0]                  M01_AXI_0_awburst                       ;
wire [MID-1:0]              M01_AXI_0_awid                          ;
wire [3:0]                  M01_AXI_0_awcache                       ;
wire [3:0]                  M01_AXI_0_awqos                         ;
wire [3:0]                  M01_AXI_0_awregion                      ;
wire [2:0]                  M01_AXI_0_awprot                        ;
wire                        M01_AXI_0_awlock                        ;
wire                        M01_AXI_0_wready                        ;
wire                        M01_AXI_0_wvalid                        ;
wire [511:0]                M01_AXI_0_wdata                         ;
wire [63:0]                 M01_AXI_0_wstrb                         ;
wire                        M01_AXI_0_wlast                         ;
wire                        M01_AXI_0_bready                        ;
wire                        M01_AXI_0_bvalid                        ;
wire [MID-1:0]              M01_AXI_0_bid                           ;
wire [1:0]                  M01_AXI_0_bresp                         ;
`endif

`ifdef DESIGN_OPU_CORE4
wire                        M02_ACLK_0                              ;
wire                        M02_ARESETN_0                           ;
wire                        M02_AXI_0_arready                       ;
wire                        M02_AXI_0_arvalid                       ;
wire [63:0]                 M02_AXI_0_araddr                        ;
wire [7:0]                  M02_AXI_0_arlen                         ;
wire [2:0]                  M02_AXI_0_arsize                        ;
wire [1:0]                  M02_AXI_0_arburst                       ;
wire [MID-1:0]              M02_AXI_0_arid                          ;
wire [3:0]                  M02_AXI_0_arcache                       ;
wire [3:0]                  M02_AXI_0_arqos                         ;
wire [3:0]                  M02_AXI_0_arregion                      ;
wire [2:0]                  M02_AXI_0_arprot                        ;
wire                        M02_AXI_0_arlock                        ;
wire                        M02_AXI_0_rready                        ;
wire                        M02_AXI_0_rvalid                        ;
wire [511:0]                M02_AXI_0_rdata                         ;
wire [MID-1:0]              M02_AXI_0_rid                           ;
wire                        M02_AXI_0_rlast                         ;
wire [1:0]                  M02_AXI_0_rresp                         ;
wire                        M02_AXI_0_awready                       ;
wire                        M02_AXI_0_awvalid                       ;
wire [63:0]                 M02_AXI_0_awaddr                        ;
wire [7:0]                  M02_AXI_0_awlen                         ;
wire [2:0]                  M02_AXI_0_awsize                        ;
wire [1:0]                  M02_AXI_0_awburst                       ;
wire [MID-1:0]              M02_AXI_0_awid                          ;
wire [3:0]                  M02_AXI_0_awcache                       ;
wire [3:0]                  M02_AXI_0_awqos                         ;
wire [3:0]                  M02_AXI_0_awregion                      ;
wire [2:0]                  M02_AXI_0_awprot                        ;
wire                        M02_AXI_0_awlock                        ;
wire                        M02_AXI_0_wready                        ;
wire                        M02_AXI_0_wvalid                        ;
wire [511:0]                M02_AXI_0_wdata                         ;
wire [63:0]                 M02_AXI_0_wstrb                         ;
wire                        M02_AXI_0_wlast                         ;
wire                        M02_AXI_0_bready                        ;
wire                        M02_AXI_0_bvalid                        ;
wire [MID-1:0]              M02_AXI_0_bid                           ;
wire [1:0]                  M02_AXI_0_bresp                         ;

wire                        M03_ACLK_0                              ;
wire                        M03_ARESETN_0                           ;
wire                        M03_AXI_0_arready                       ;
wire                        M03_AXI_0_arvalid                       ;
wire [63:0]                 M03_AXI_0_araddr                        ;
wire [7:0]                  M03_AXI_0_arlen                         ;
wire [2:0]                  M03_AXI_0_arsize                        ;
wire [1:0]                  M03_AXI_0_arburst                       ;
wire [MID-1:0]              M03_AXI_0_arid                          ;
wire [3:0]                  M03_AXI_0_arcache                       ;
wire [3:0]                  M03_AXI_0_arqos                         ;
wire [3:0]                  M03_AXI_0_arregion                      ;
wire [2:0]                  M03_AXI_0_arprot                        ;
wire                        M03_AXI_0_arlock                        ;
wire                        M03_AXI_0_rready                        ;
wire                        M03_AXI_0_rvalid                        ;
wire [511:0]                M03_AXI_0_rdata                         ;
wire [MID-1:0]              M03_AXI_0_rid                           ;
wire                        M03_AXI_0_rlast                         ;
wire [1:0]                  M03_AXI_0_rresp                         ;
wire                        M03_AXI_0_awready                       ;
wire                        M03_AXI_0_awvalid                       ;
wire [63:0]                 M03_AXI_0_awaddr                        ;
wire [7:0]                  M03_AXI_0_awlen                         ;
wire [2:0]                  M03_AXI_0_awsize                        ;
wire [1:0]                  M03_AXI_0_awburst                       ;
wire [MID-1:0]              M03_AXI_0_awid                          ;
wire [3:0]                  M03_AXI_0_awcache                       ;
wire [3:0]                  M03_AXI_0_awqos                         ;
wire [3:0]                  M03_AXI_0_awregion                      ;
wire [2:0]                  M03_AXI_0_awprot                        ;
wire                        M03_AXI_0_awlock                        ;
wire                        M03_AXI_0_wready                        ;
wire                        M03_AXI_0_wvalid                        ;
wire [511:0]                M03_AXI_0_wdata                         ;
wire [63:0]                 M03_AXI_0_wstrb                         ;
wire                        M03_AXI_0_wlast                         ;
wire                        M03_AXI_0_bready                        ;
wire                        M03_AXI_0_bvalid                        ;
wire [MID-1:0]              M03_AXI_0_bid                           ;
wire [1:0]                  M03_AXI_0_bresp                         ;
`endif

//---------------------------------------
wire                        S00_ACLK_0                              ;
wire                        S00_ARESETN_0                           ;
wire                        S00_AXI_0_arready                       ;
wire                        S00_AXI_0_arvalid                       ;
wire [63:0]                 S00_AXI_0_araddr                        ;
wire [7:0]                  S00_AXI_0_arlen                         ;
wire [2:0]                  S00_AXI_0_arsize                        ;
wire [1:0]                  S00_AXI_0_arburst                       ;
wire [SID-1:0]              S00_AXI_0_arid                          ;
wire [3:0]                  S00_AXI_0_arcache                       ;
wire [3:0]                  S00_AXI_0_arqos                         ;
reg  [3:0]                  S00_AXI_0_arregion=0                    ;
wire [2:0]                  S00_AXI_0_arprot                        ;
wire                        S00_AXI_0_arlock                        ;
wire                        S00_AXI_0_rready                        ;
wire                        S00_AXI_0_rvalid                        ;
wire [511:0]                S00_AXI_0_rdata                         ;
wire                        S00_AXI_0_rlast                         ;
wire [SID-1:0]              S00_AXI_0_rid                           ;
wire [1:0]                  S00_AXI_0_rresp                         ;
wire                        S00_AXI_0_awready                       ;
wire                        S00_AXI_0_awvalid                       ;
wire [63:0]                 S00_AXI_0_awaddr                        ;
wire [7:0]                  S00_AXI_0_awlen                         ;
wire [2:0]                  S00_AXI_0_awsize                        ;
wire [1:0]                  S00_AXI_0_awburst                       ;
wire [SID-1:0]              S00_AXI_0_awid                          ;
wire [3:0]                  S00_AXI_0_awcache                       ;
wire [3:0]                  S00_AXI_0_awqos                         ;
reg  [3:0]                  S00_AXI_0_awregion=0                    ;
wire [2:0]                  S00_AXI_0_awprot                        ;
wire                        S00_AXI_0_awlock                        ;
wire                        S00_AXI_0_wready                        ;
wire                        S00_AXI_0_wvalid                        ;
wire [511:0]                S00_AXI_0_wdata                         ;
wire [63:0]                 S00_AXI_0_wstrb                         ;
wire                        S00_AXI_0_wlast                         ;
wire                        S00_AXI_0_bready                        ;
wire                        S00_AXI_0_bvalid                        ;
wire [SID-1:0]              S00_AXI_0_bid                           ;
wire [1:0]                  S00_AXI_0_bresp                         ;
//
wire                        S01_AXI_0_arready                       ;
wire                        S01_AXI_0_arvalid                       ;
wire [63:0]                 S01_AXI_0_araddr                        ;
wire [7:0]                  S01_AXI_0_arlen                         ;
wire [2:0]                  S01_AXI_0_arsize                        ;
wire [1:0]                  S01_AXI_0_arburst                       ;
wire [SID-1:0]              S01_AXI_0_arid                          ;
wire [3:0]                  S01_AXI_0_arcache                       ;
wire [3:0]                  S01_AXI_0_arqos                         ;
reg  [3:0]                  S01_AXI_0_arregion=0                    ;
wire [2:0]                  S01_AXI_0_arprot                        ;
wire                        S01_AXI_0_arlock                        ;
wire                        S01_AXI_0_rready                        ;
wire                        S01_AXI_0_rvalid                        ;
wire [511:0]                S01_AXI_0_rdata                         ;
wire                        S01_AXI_0_rlast                         ;
wire [SID-1:0]              S01_AXI_0_rid                           ;
wire [1:0]                  S01_AXI_0_rresp                         ;
wire                        S01_AXI_0_awready                       ;
wire                        S01_AXI_0_awvalid                       ;
wire [63:0]                 S01_AXI_0_awaddr                        ;
wire [7:0]                  S01_AXI_0_awlen                         ;
wire [2:0]                  S01_AXI_0_awsize                        ;
wire [1:0]                  S01_AXI_0_awburst                       ;
wire [SID-1:0]              S01_AXI_0_awid                          ;
wire [3:0]                  S01_AXI_0_awcache                       ;
wire [3:0]                  S01_AXI_0_awqos                         ;
reg  [3:0]                  S01_AXI_0_awregion=0                    ;
wire [2:0]                  S01_AXI_0_awprot                        ;
wire                        S01_AXI_0_awlock                        ;
wire                        S01_AXI_0_wready                        ;
wire                        S01_AXI_0_wvalid                        ;
wire [511:0]                S01_AXI_0_wdata                         ;
wire [63:0]                 S01_AXI_0_wstrb                         ;
wire                        S01_AXI_0_wlast                         ;
wire                        S01_AXI_0_bready                        ;
wire                        S01_AXI_0_bvalid                        ;
wire [SID-1:0]              S01_AXI_0_bid                           ;
wire [1:0]                  S01_AXI_0_bresp                         ;
//
`ifdef DESIGN_OPU_CORE2_OR_CORE4
wire                        S02_AXI_0_arready                       ;
wire                        S02_AXI_0_arvalid                       ;
wire [63:0]                 S02_AXI_0_araddr                        ;
wire [7:0]                  S02_AXI_0_arlen                         ;
wire [2:0]                  S02_AXI_0_arsize                        ;
wire [1:0]                  S02_AXI_0_arburst                       ;
wire [SID-1:0]              S02_AXI_0_arid                          ;
wire [3:0]                  S02_AXI_0_arcache                       ;
wire [3:0]                  S02_AXI_0_arqos                         ;
reg  [3:0]                  S02_AXI_0_arregion=0                    ;
wire [2:0]                  S02_AXI_0_arprot                        ;
wire                        S02_AXI_0_arlock                        ;
wire                        S02_AXI_0_rready                        ;
wire                        S02_AXI_0_rvalid                        ;
wire [511:0]                S02_AXI_0_rdata                         ;
wire                        S02_AXI_0_rlast                         ;
wire [SID-1:0]              S02_AXI_0_rid                           ;
wire [1:0]                  S02_AXI_0_rresp                         ;
wire                        S02_AXI_0_awready                       ;
wire                        S02_AXI_0_awvalid                       ;
wire [63:0]                 S02_AXI_0_awaddr                        ;
wire [7:0]                  S02_AXI_0_awlen                         ;
wire [2:0]                  S02_AXI_0_awsize                        ;
wire [1:0]                  S02_AXI_0_awburst                       ;
wire [SID-1:0]              S02_AXI_0_awid                          ;
wire [3:0]                  S02_AXI_0_awcache                       ;
wire [3:0]                  S02_AXI_0_awqos                         ;
reg  [3:0]                  S02_AXI_0_awregion=0                    ;
wire [2:0]                  S02_AXI_0_awprot                        ;
wire                        S02_AXI_0_awlock                        ;
wire                        S02_AXI_0_wready                        ;
wire                        S02_AXI_0_wvalid                        ;
wire [511:0]                S02_AXI_0_wdata                         ;
wire [63:0]                 S02_AXI_0_wstrb                         ;
wire                        S02_AXI_0_wlast                         ;
wire                        S02_AXI_0_bready                        ;
wire                        S02_AXI_0_bvalid                        ;
wire [SID-1:0]              S02_AXI_0_bid                           ;
wire [1:0]                  S02_AXI_0_bresp                         ;
`endif
//
`ifdef DESIGN_OPU_CORE4
wire                        S03_AXI_0_arready                       ;
wire                        S03_AXI_0_arvalid                       ;
wire [63:0]                 S03_AXI_0_araddr                        ;
wire [7:0]                  S03_AXI_0_arlen                         ;
wire [2:0]                  S03_AXI_0_arsize                        ;
wire [1:0]                  S03_AXI_0_arburst                       ;
wire [SID-1:0]              S03_AXI_0_arid                          ;
wire [3:0]                  S03_AXI_0_arcache                       ;
wire [3:0]                  S03_AXI_0_arqos                         ;
reg  [3:0]                  S03_AXI_0_arregion=0                    ;
wire [2:0]                  S03_AXI_0_arprot                        ;
wire                        S03_AXI_0_arlock                        ;
wire                        S03_AXI_0_rready                        ;
wire                        S03_AXI_0_rvalid                        ;
wire [511:0]                S03_AXI_0_rdata                         ;
wire                        S03_AXI_0_rlast                         ;
wire [SID-1:0]              S03_AXI_0_rid                           ;
wire [1:0]                  S03_AXI_0_rresp                         ;
wire                        S03_AXI_0_awready                       ;
wire                        S03_AXI_0_awvalid                       ;
wire [63:0]                 S03_AXI_0_awaddr                        ;
wire [7:0]                  S03_AXI_0_awlen                         ;
wire [2:0]                  S03_AXI_0_awsize                        ;
wire [1:0]                  S03_AXI_0_awburst                       ;
wire [SID-1:0]              S03_AXI_0_awid                          ;
wire [3:0]                  S03_AXI_0_awcache                       ;
wire [3:0]                  S03_AXI_0_awqos                         ;
reg  [3:0]                  S03_AXI_0_awregion=0                    ;
wire [2:0]                  S03_AXI_0_awprot                        ;
wire                        S03_AXI_0_awlock                        ;
wire                        S03_AXI_0_wready                        ;
wire                        S03_AXI_0_wvalid                        ;
wire [511:0]                S03_AXI_0_wdata                         ;
wire [63:0]                 S03_AXI_0_wstrb                         ;
wire                        S03_AXI_0_wlast                         ;
wire                        S03_AXI_0_bready                        ;
wire                        S03_AXI_0_bvalid                        ;
wire [SID-1:0]              S03_AXI_0_bid                           ;
wire [1:0]                  S03_AXI_0_bresp                         ;
//
wire                        S04_AXI_0_arready                       ;
wire                        S04_AXI_0_arvalid                       ;
wire [63:0]                 S04_AXI_0_araddr                        ;
wire [7:0]                  S04_AXI_0_arlen                         ;
wire [2:0]                  S04_AXI_0_arsize                        ;
wire [1:0]                  S04_AXI_0_arburst                       ;
wire [SID-1:0]              S04_AXI_0_arid                          ;
wire [3:0]                  S04_AXI_0_arcache                       ;
wire [3:0]                  S04_AXI_0_arqos                         ;
reg  [3:0]                  S04_AXI_0_arregion=0                    ;
wire [2:0]                  S04_AXI_0_arprot                        ;
wire                        S04_AXI_0_arlock                        ;
wire                        S04_AXI_0_rready                        ;
wire                        S04_AXI_0_rvalid                        ;
wire [511:0]                S04_AXI_0_rdata                         ;
wire                        S04_AXI_0_rlast                         ;
wire [SID-1:0]              S04_AXI_0_rid                           ;
wire [1:0]                  S04_AXI_0_rresp                         ;
wire                        S04_AXI_0_awready                       ;
wire                        S04_AXI_0_awvalid                       ;
wire [63:0]                 S04_AXI_0_awaddr                        ;
wire [7:0]                  S04_AXI_0_awlen                         ;
wire [2:0]                  S04_AXI_0_awsize                        ;
wire [1:0]                  S04_AXI_0_awburst                       ;
wire [SID-1:0]              S04_AXI_0_awid                          ;
wire [3:0]                  S04_AXI_0_awcache                       ;
wire [3:0]                  S04_AXI_0_awqos                         ;
reg  [3:0]                  S04_AXI_0_awregion=0                    ;
wire [2:0]                  S04_AXI_0_awprot                        ;
wire                        S04_AXI_0_awlock                        ;
wire                        S04_AXI_0_wready                        ;
wire                        S04_AXI_0_wvalid                        ;
wire [511:0]                S04_AXI_0_wdata                         ;
wire [63:0]                 S04_AXI_0_wstrb                         ;
wire                        S04_AXI_0_wlast                         ;
wire                        S04_AXI_0_bready                        ;
wire                        S04_AXI_0_bvalid                        ;
wire [SID-1:0]              S04_AXI_0_bid                           ;
wire [1:0]                  S04_AXI_0_bresp                         ;
`endif
wire [MID-1:0]              S01_AXI_0_arid_bus                      ;//i
wire [MID-1:0]              S01_AXI_0_awid_bus                      ;//i
wire [MID-1:0]              S01_AXI_0_rid_bus                       ;//o
wire [MID-1:0]              S01_AXI_0_bid_bus                       ;//o
assign S01_AXI_0_arid_bus   ={{(MID-SID){1'b0}},S01_AXI_0_arid}     ; 
assign S01_AXI_0_awid_bus   ={{(MID-SID){1'b0}},S01_AXI_0_awid}     ; 
assign S01_AXI_0_rid        =S01_AXI_0_rid_bus[SID-1:0]             ;
assign S01_AXI_0_bid        =S01_AXI_0_bid_bus[SID-1:0]             ;

`ifdef DESIGN_OPU_CORE1
`ifndef AXI_BYPASS
//----------------------------------------------
(*keep_hierarchy="yes"*)Block_AXI_M1S2 AXI_M1S2
(
    .M00_AXI_0_arid         (M00_AXI_0_arid                         ),//o
    .M00_AXI_0_awid         (M00_AXI_0_awid                         ),//o
    .M00_AXI_0_rid          (M00_AXI_0_rid                          ),//i
    .M00_AXI_0_bid          (M00_AXI_0_bid                          ),//i
    .M00_ACLK_0             (M00_ACLK_0                             ),
    .M00_ARESETN_0          (M00_ARESETN_0                          ),
    .M00_AXI_0_arready      (M00_AXI_0_arready                      ),
    .M00_AXI_0_arvalid      (M00_AXI_0_arvalid                      ),
    .M00_AXI_0_araddr       (M00_AXI_0_araddr                       ),
    .M00_AXI_0_arlen        (M00_AXI_0_arlen                        ),
    .M00_AXI_0_arsize       (M00_AXI_0_arsize                       ),
    .M00_AXI_0_arburst      (M00_AXI_0_arburst                      ),
    .M00_AXI_0_arcache      (M00_AXI_0_arcache                      ),
    .M00_AXI_0_arqos        (M00_AXI_0_arqos                        ),
    .M00_AXI_0_arregion     (M00_AXI_0_arregion                     ),
    .M00_AXI_0_arprot       (M00_AXI_0_arprot                       ),
    .M00_AXI_0_arlock       (M00_AXI_0_arlock                       ),
    .M00_AXI_0_rready       (M00_AXI_0_rready                       ),
    .M00_AXI_0_rvalid       (M00_AXI_0_rvalid                       ),
    .M00_AXI_0_rdata        (M00_AXI_0_rdata                        ),
    .M00_AXI_0_rlast        (M00_AXI_0_rlast                        ),
    .M00_AXI_0_rresp        (M00_AXI_0_rresp                        ),
    .M00_AXI_0_awready      (M00_AXI_0_awready                      ),
    .M00_AXI_0_awvalid      (M00_AXI_0_awvalid                      ),
    .M00_AXI_0_awaddr       (M00_AXI_0_awaddr                       ),
    .M00_AXI_0_awlen        (M00_AXI_0_awlen                        ),
    .M00_AXI_0_awsize       (M00_AXI_0_awsize                       ),
    .M00_AXI_0_awburst      (M00_AXI_0_awburst                      ),
    .M00_AXI_0_awcache      (M00_AXI_0_awcache                      ),
    .M00_AXI_0_awqos        (M00_AXI_0_awqos                        ),
    .M00_AXI_0_awregion     (M00_AXI_0_awregion                     ),
    .M00_AXI_0_awprot       (M00_AXI_0_awprot                       ),
    .M00_AXI_0_awlock       (M00_AXI_0_awlock                       ),
    .M00_AXI_0_wready       (M00_AXI_0_wready                       ),
    .M00_AXI_0_wvalid       (M00_AXI_0_wvalid                       ),
    .M00_AXI_0_wdata        (M00_AXI_0_wdata                        ),
    .M00_AXI_0_wstrb        (M00_AXI_0_wstrb                        ),
    .M00_AXI_0_wlast        (M00_AXI_0_wlast                        ),
    .M00_AXI_0_bready       (M00_AXI_0_bready                       ),
    .M00_AXI_0_bvalid       (M00_AXI_0_bvalid                       ),
    .M00_AXI_0_bresp        (M00_AXI_0_bresp                        ),
    //------------------------------------------
    .S00_AXI_0_arid         (S00_AXI_0_arid                         ),//i
    .S00_AXI_0_awid         (S00_AXI_0_awid                         ),//i
    .S00_AXI_0_rid          (S00_AXI_0_rid                          ),//o
    .S00_AXI_0_bid          (S00_AXI_0_bid                          ),//o
    .S00_ACLK_0             (S00_ACLK_0                             ),
    .S00_ARESETN_0          (S00_ARESETN_0                          ),
    .S00_AXI_0_arready      (S00_AXI_0_arready                      ),
    .S00_AXI_0_arvalid      (S00_AXI_0_arvalid                      ),
    .S00_AXI_0_araddr       (S00_AXI_0_araddr                       ),
    .S00_AXI_0_arlen        (S00_AXI_0_arlen                        ),
    .S00_AXI_0_arsize       (S00_AXI_0_arsize                       ),
    .S00_AXI_0_arburst      (S00_AXI_0_arburst                      ),
    .S00_AXI_0_arcache      (S00_AXI_0_arcache                      ),
    .S00_AXI_0_arqos        (S00_AXI_0_arqos                        ),
    .S00_AXI_0_arregion     (S00_AXI_0_arregion                     ),
    .S00_AXI_0_arprot       (S00_AXI_0_arprot                       ),
    .S00_AXI_0_arlock       (S00_AXI_0_arlock                       ),
    .S00_AXI_0_rready       (S00_AXI_0_rready                       ),
    .S00_AXI_0_rvalid       (S00_AXI_0_rvalid                       ),
    .S00_AXI_0_rdata        (S00_AXI_0_rdata                        ),
    .S00_AXI_0_rlast        (S00_AXI_0_rlast                        ),
    .S00_AXI_0_rresp        (S00_AXI_0_rresp                        ),
    .S00_AXI_0_awready      (S00_AXI_0_awready                      ),
    .S00_AXI_0_awvalid      (S00_AXI_0_awvalid                      ),
    .S00_AXI_0_awaddr       (S00_AXI_0_awaddr                       ),
    .S00_AXI_0_awlen        (S00_AXI_0_awlen                        ),
    .S00_AXI_0_awsize       (S00_AXI_0_awsize                       ),
    .S00_AXI_0_awburst      (S00_AXI_0_awburst                      ),
    .S00_AXI_0_awcache      (S00_AXI_0_awcache                      ),
    .S00_AXI_0_awqos        (S00_AXI_0_awqos                        ),
    .S00_AXI_0_awregion     (S00_AXI_0_awregion                     ),
    .S00_AXI_0_awprot       (S00_AXI_0_awprot                       ),
    .S00_AXI_0_awlock       (S00_AXI_0_awlock                       ),
    .S00_AXI_0_wready       (S00_AXI_0_wready                       ),
    .S00_AXI_0_wvalid       (S00_AXI_0_wvalid                       ),
    .S00_AXI_0_wdata        (S00_AXI_0_wdata                        ),
    .S00_AXI_0_wstrb        (S00_AXI_0_wstrb                        ),
    .S00_AXI_0_wlast        (S00_AXI_0_wlast                        ),
    .S00_AXI_0_bready       (S00_AXI_0_bready                       ),
    .S00_AXI_0_bvalid       (S00_AXI_0_bvalid                       ),
    .S00_AXI_0_bresp        (S00_AXI_0_bresp                        ),
    //
    .S01_AXI_0_arid         (S01_AXI_0_arid_bus                     ),//i
    .S01_AXI_0_awid         (S01_AXI_0_awid_bus                     ),//i
    .S01_AXI_0_rid          (S01_AXI_0_rid_bus                      ),//o
    .S01_AXI_0_bid          (S01_AXI_0_bid_bus                      ),//o
    .S01_AXI_0_arready      (S01_AXI_0_arready                      ),
    .S01_AXI_0_arvalid      (S01_AXI_0_arvalid                      ),
    .S01_AXI_0_araddr       (S01_AXI_0_araddr                       ),
    .S01_AXI_0_arlen        (S01_AXI_0_arlen                        ),
    .S01_AXI_0_arsize       (S01_AXI_0_arsize                       ),
    .S01_AXI_0_arburst      (S01_AXI_0_arburst                      ),
    .S01_AXI_0_arcache      (S01_AXI_0_arcache                      ),
    .S01_AXI_0_arqos        (S01_AXI_0_arqos                        ),
//  .S01_AXI_0_arregion     (S01_AXI_0_arregion                     ),//no
    .S01_AXI_0_arprot       (S01_AXI_0_arprot                       ),
    .S01_AXI_0_arlock       (S01_AXI_0_arlock                       ),
    .S01_AXI_0_rready       (S01_AXI_0_rready                       ),
    .S01_AXI_0_rvalid       (S01_AXI_0_rvalid                       ),
    .S01_AXI_0_rdata        (S01_AXI_0_rdata                        ),
    .S01_AXI_0_rlast        (S01_AXI_0_rlast                        ),
    .S01_AXI_0_rresp        (S01_AXI_0_rresp                        ),
    .S01_AXI_0_awready      (S01_AXI_0_awready                      ),
    .S01_AXI_0_awvalid      (S01_AXI_0_awvalid                      ),
    .S01_AXI_0_awaddr       (S01_AXI_0_awaddr                       ),
    .S01_AXI_0_awlen        (S01_AXI_0_awlen                        ),
    .S01_AXI_0_awsize       (S01_AXI_0_awsize                       ),
    .S01_AXI_0_awburst      (S01_AXI_0_awburst                      ),
    .S01_AXI_0_awcache      (S01_AXI_0_awcache                      ),
    .S01_AXI_0_awqos        (S01_AXI_0_awqos                        ),
//  .S01_AXI_0_awregion     (S01_AXI_0_awregion                     ),//no
    .S01_AXI_0_awprot       (S01_AXI_0_awprot                       ),
    .S01_AXI_0_awlock       (S01_AXI_0_awlock                       ),
    .S01_AXI_0_wready       (S01_AXI_0_wready                       ),
    .S01_AXI_0_wvalid       (S01_AXI_0_wvalid                       ),
    .S01_AXI_0_wdata        (S01_AXI_0_wdata                        ),
    .S01_AXI_0_wstrb        (S01_AXI_0_wstrb                        ),
    .S01_AXI_0_wlast        (S01_AXI_0_wlast                        ),
    .S01_AXI_0_bready       (S01_AXI_0_bready                       ),
    .S01_AXI_0_bvalid       (S01_AXI_0_bvalid                       ),
    .S01_AXI_0_bresp        (S01_AXI_0_bresp                        )
);
`else
opu_axi_bypass
#(.MID(MID),
  .SID(SID))
u0_bypass_m1s2
(
    .M00_ACLK_0             (M00_ACLK_0                             ),
    .M00_ARESETN_0          (M00_ARESETN_0                          ),
    .M00_AXI_0_arready      (M00_AXI_0_arready                      ),
    .M00_AXI_0_arvalid      (M00_AXI_0_arvalid                      ),
    .M00_AXI_0_araddr       (M00_AXI_0_araddr                       ),
    .M00_AXI_0_arlen        (M00_AXI_0_arlen                        ),
    .M00_AXI_0_arsize       (M00_AXI_0_arsize                       ),
    .M00_AXI_0_arburst      (M00_AXI_0_arburst                      ),
    .M00_AXI_0_arid         (M00_AXI_0_arid                         ),
    .M00_AXI_0_arcache      (M00_AXI_0_arcache                      ),
    .M00_AXI_0_arqos        (M00_AXI_0_arqos                        ),
    .M00_AXI_0_arregion     (M00_AXI_0_arregion                     ),
    .M00_AXI_0_arprot       (M00_AXI_0_arprot                       ),
    .M00_AXI_0_arlock       (M00_AXI_0_arlock                       ),
    .M00_AXI_0_rready       (M00_AXI_0_rready                       ),
    .M00_AXI_0_rvalid       (M00_AXI_0_rvalid                       ),
    .M00_AXI_0_rdata        (M00_AXI_0_rdata                        ),
    .M00_AXI_0_rid          (M00_AXI_0_rid                          ),
    .M00_AXI_0_rlast        (M00_AXI_0_rlast                        ),
    .M00_AXI_0_rresp        (M00_AXI_0_rresp                        ),
    .M00_AXI_0_awready      (M00_AXI_0_awready                      ),
    .M00_AXI_0_awvalid      (M00_AXI_0_awvalid                      ),
    .M00_AXI_0_awaddr       (M00_AXI_0_awaddr                       ),
    .M00_AXI_0_awlen        (M00_AXI_0_awlen                        ),
    .M00_AXI_0_awsize       (M00_AXI_0_awsize                       ),
    .M00_AXI_0_awburst      (M00_AXI_0_awburst                      ),
    .M00_AXI_0_awid         (M00_AXI_0_awid                         ),
    .M00_AXI_0_awcache      (M00_AXI_0_awcache                      ),
    .M00_AXI_0_awqos        (M00_AXI_0_awqos                        ),
    .M00_AXI_0_awregion     (M00_AXI_0_awregion                     ),
    .M00_AXI_0_awprot       (M00_AXI_0_awprot                       ),
    .M00_AXI_0_awlock       (M00_AXI_0_awlock                       ),
    .M00_AXI_0_wready       (M00_AXI_0_wready                       ),
    .M00_AXI_0_wvalid       (M00_AXI_0_wvalid                       ),
    .M00_AXI_0_wdata        (M00_AXI_0_wdata                        ),
    .M00_AXI_0_wstrb        (M00_AXI_0_wstrb                        ),
    .M00_AXI_0_wlast        (M00_AXI_0_wlast                        ),
    .M00_AXI_0_bready       (M00_AXI_0_bready                       ),
    .M00_AXI_0_bvalid       (M00_AXI_0_bvalid                       ),
    .M00_AXI_0_bid          (M00_AXI_0_bid                          ),
    .M00_AXI_0_bresp        (M00_AXI_0_bresp                        ),
    //------------------------------------------
    .S00_ACLK_0             (S00_ACLK_0                             ),
    .S00_ARESETN_0          (S00_ARESETN_0                          ),
    .S00_AXI_0_arready      (S00_AXI_0_arready                      ),
    .S00_AXI_0_arvalid      (S00_AXI_0_arvalid                      ),
    .S00_AXI_0_araddr       (S00_AXI_0_araddr                       ),
    .S00_AXI_0_arlen        (S00_AXI_0_arlen                        ),
    .S00_AXI_0_arsize       (S00_AXI_0_arsize                       ),
    .S00_AXI_0_arburst      (S00_AXI_0_arburst                      ),
    .S00_AXI_0_arid         (S00_AXI_0_arid                         ),
    .S00_AXI_0_arcache      (S00_AXI_0_arcache                      ),
    .S00_AXI_0_arqos        (S00_AXI_0_arqos                        ),
    .S00_AXI_0_arregion     (S00_AXI_0_arregion                     ),
    .S00_AXI_0_arprot       (S00_AXI_0_arprot                       ),
    .S00_AXI_0_arlock       (S00_AXI_0_arlock                       ),
    .S00_AXI_0_rready       (S00_AXI_0_rready                       ),
    .S00_AXI_0_rvalid       (S00_AXI_0_rvalid                       ),
    .S00_AXI_0_rdata        (S00_AXI_0_rdata                        ),
    .S00_AXI_0_rlast        (S00_AXI_0_rlast                        ),
    .S00_AXI_0_rid          (S00_AXI_0_rid                          ),
    .S00_AXI_0_rresp        (S00_AXI_0_rresp                        ),
    .S00_AXI_0_awready      (S00_AXI_0_awready                      ),
    .S00_AXI_0_awvalid      (S00_AXI_0_awvalid                      ),
    .S00_AXI_0_awaddr       (S00_AXI_0_awaddr                       ),
    .S00_AXI_0_awlen        (S00_AXI_0_awlen                        ),
    .S00_AXI_0_awsize       (S00_AXI_0_awsize                       ),
    .S00_AXI_0_awburst      (S00_AXI_0_awburst                      ),
    .S00_AXI_0_awid         (S00_AXI_0_awid                         ),
    .S00_AXI_0_awcache      (S00_AXI_0_awcache                      ),
    .S00_AXI_0_awqos        (S00_AXI_0_awqos                        ),
    .S00_AXI_0_awregion     (S00_AXI_0_awregion                     ),
    .S00_AXI_0_awprot       (S00_AXI_0_awprot                       ),
    .S00_AXI_0_awlock       (S00_AXI_0_awlock                       ),
    .S00_AXI_0_wready       (S00_AXI_0_wready                       ),
    .S00_AXI_0_wvalid       (S00_AXI_0_wvalid                       ),
    .S00_AXI_0_wdata        (S00_AXI_0_wdata                        ),
    .S00_AXI_0_wstrb        (S00_AXI_0_wstrb                        ),
    .S00_AXI_0_wlast        (S00_AXI_0_wlast                        ),
    .S00_AXI_0_bready       (S00_AXI_0_bready                       ),
    .S00_AXI_0_bvalid       (S00_AXI_0_bvalid                       ),
    .S00_AXI_0_bid          (S00_AXI_0_bid                          ),
    .S00_AXI_0_bresp        (S00_AXI_0_bresp                        ),
    //
    .S01_AXI_0_arready      (S01_AXI_0_arready                      ),
    .S01_AXI_0_arvalid      (S01_AXI_0_arvalid                      ),
    .S01_AXI_0_araddr       (S01_AXI_0_araddr                       ),
    .S01_AXI_0_arlen        (S01_AXI_0_arlen                        ),
    .S01_AXI_0_arsize       (S01_AXI_0_arsize                       ),
    .S01_AXI_0_arburst      (S01_AXI_0_arburst                      ),
    .S01_AXI_0_arid         (S01_AXI_0_arid                         ),
    .S01_AXI_0_arcache      (S01_AXI_0_arcache                      ),
    .S01_AXI_0_arqos        (S01_AXI_0_arqos                        ),
    .S01_AXI_0_arregion     (S01_AXI_0_arregion                     ),
    .S01_AXI_0_arprot       (S01_AXI_0_arprot                       ),
    .S01_AXI_0_arlock       (S01_AXI_0_arlock                       ),
    .S01_AXI_0_rready       (S01_AXI_0_rready                       ),
    .S01_AXI_0_rvalid       (S01_AXI_0_rvalid                       ),
    .S01_AXI_0_rdata        (S01_AXI_0_rdata                        ),
    .S01_AXI_0_rlast        (S01_AXI_0_rlast                        ),
    .S01_AXI_0_rid          (S01_AXI_0_rid_bus                      ),
    .S01_AXI_0_rresp        (S01_AXI_0_rresp                        ),
    .S01_AXI_0_awready      (S01_AXI_0_awready                      ),
    .S01_AXI_0_awvalid      (S01_AXI_0_awvalid                      ),
    .S01_AXI_0_awaddr       (S01_AXI_0_awaddr                       ),
    .S01_AXI_0_awlen        (S01_AXI_0_awlen                        ),
    .S01_AXI_0_awsize       (S01_AXI_0_awsize                       ),
    .S01_AXI_0_awburst      (S01_AXI_0_awburst                      ),
    .S01_AXI_0_awid         (S01_AXI_0_awid                         ),
    .S01_AXI_0_awcache      (S01_AXI_0_awcache                      ),
    .S01_AXI_0_awqos        (S01_AXI_0_awqos                        ),
    .S01_AXI_0_awregion     (S01_AXI_0_awregion                     ),
    .S01_AXI_0_awprot       (S01_AXI_0_awprot                       ),
    .S01_AXI_0_awlock       (S01_AXI_0_awlock                       ),
    .S01_AXI_0_wready       (S01_AXI_0_wready                       ),
    .S01_AXI_0_wvalid       (S01_AXI_0_wvalid                       ),
    .S01_AXI_0_wdata        (S01_AXI_0_wdata                        ),
    .S01_AXI_0_wstrb        (S01_AXI_0_wstrb                        ),
    .S01_AXI_0_wlast        (S01_AXI_0_wlast                        ),
    .S01_AXI_0_bready       (S01_AXI_0_bready                       ),
    .S01_AXI_0_bvalid       (S01_AXI_0_bvalid                       ),
    .S01_AXI_0_bid          (S01_AXI_0_bid_bus                      ),
    .S01_AXI_0_bresp        (S01_AXI_0_bresp                        )
);
`endif//sim
`endif//1core



`ifdef DESIGN_OPU_CORE2
`ifndef AXI_BYPASS
//----------------------------------------------
(*keep_hierarchy="yes"*)Block_AXI_M2S3 AXI_M2S3
(
    .M00_AXI_0_arid         (M00_AXI_0_arid                         ),//o
    .M00_AXI_0_awid         (M00_AXI_0_awid                         ),//o
    .M00_AXI_0_rid          (M00_AXI_0_rid                          ),//i
    .M00_AXI_0_bid          (M00_AXI_0_bid                          ),//i
    .M00_ACLK_0             (M00_ACLK_0                             ),
    .M00_ARESETN_0          (M00_ARESETN_0                          ),
    .M00_AXI_0_arready      (M00_AXI_0_arready                      ),
    .M00_AXI_0_arvalid      (M00_AXI_0_arvalid                      ),
    .M00_AXI_0_araddr       (M00_AXI_0_araddr                       ),
    .M00_AXI_0_arlen        (M00_AXI_0_arlen                        ),
    .M00_AXI_0_arsize       (M00_AXI_0_arsize                       ),
    .M00_AXI_0_arburst      (M00_AXI_0_arburst                      ),
    .M00_AXI_0_arcache      (M00_AXI_0_arcache                      ),
    .M00_AXI_0_arqos        (M00_AXI_0_arqos                        ),
    .M00_AXI_0_arregion     (M00_AXI_0_arregion                     ),
    .M00_AXI_0_arprot       (M00_AXI_0_arprot                       ),
    .M00_AXI_0_arlock       (M00_AXI_0_arlock                       ),
    .M00_AXI_0_rready       (M00_AXI_0_rready                       ),
    .M00_AXI_0_rvalid       (M00_AXI_0_rvalid                       ),
    .M00_AXI_0_rdata        (M00_AXI_0_rdata                        ),
    .M00_AXI_0_rlast        (M00_AXI_0_rlast                        ),
    .M00_AXI_0_rresp        (M00_AXI_0_rresp                        ),
    .M00_AXI_0_awready      (M00_AXI_0_awready                      ),
    .M00_AXI_0_awvalid      (M00_AXI_0_awvalid                      ),
    .M00_AXI_0_awaddr       (M00_AXI_0_awaddr                       ),
    .M00_AXI_0_awlen        (M00_AXI_0_awlen                        ),
    .M00_AXI_0_awsize       (M00_AXI_0_awsize                       ),
    .M00_AXI_0_awburst      (M00_AXI_0_awburst                      ),
    .M00_AXI_0_awcache      (M00_AXI_0_awcache                      ),
    .M00_AXI_0_awqos        (M00_AXI_0_awqos                        ),
    .M00_AXI_0_awregion     (M00_AXI_0_awregion                     ),
    .M00_AXI_0_awprot       (M00_AXI_0_awprot                       ),
    .M00_AXI_0_awlock       (M00_AXI_0_awlock                       ),
    .M00_AXI_0_wready       (M00_AXI_0_wready                       ),
    .M00_AXI_0_wvalid       (M00_AXI_0_wvalid                       ),
    .M00_AXI_0_wdata        (M00_AXI_0_wdata                        ),
    .M00_AXI_0_wstrb        (M00_AXI_0_wstrb                        ),
    .M00_AXI_0_wlast        (M00_AXI_0_wlast                        ),
    .M00_AXI_0_bready       (M00_AXI_0_bready                       ),
    .M00_AXI_0_bvalid       (M00_AXI_0_bvalid                       ),
    .M00_AXI_0_bresp        (M00_AXI_0_bresp                        ),
    //
    .M01_AXI_0_arid         (M01_AXI_0_arid                         ),//o
    .M01_AXI_0_awid         (M01_AXI_0_awid                         ),//o
    .M01_AXI_0_rid          (M01_AXI_0_rid                          ),//i
    .M01_AXI_0_bid          (M01_AXI_0_bid                          ),//i
    .M01_ACLK_0             (M01_ACLK_0                             ),
    .M01_ARESETN_0          (M01_ARESETN_0                          ),
    .M01_AXI_0_arready      (M01_AXI_0_arready                      ),
    .M01_AXI_0_arvalid      (M01_AXI_0_arvalid                      ),
    .M01_AXI_0_araddr       (M01_AXI_0_araddr                       ),
    .M01_AXI_0_arlen        (M01_AXI_0_arlen                        ),
    .M01_AXI_0_arsize       (M01_AXI_0_arsize                       ),
    .M01_AXI_0_arburst      (M01_AXI_0_arburst                      ),
    .M01_AXI_0_arcache      (M01_AXI_0_arcache                      ),
    .M01_AXI_0_arqos        (M01_AXI_0_arqos                        ),
    .M01_AXI_0_arregion     (M01_AXI_0_arregion                     ),
    .M01_AXI_0_arprot       (M01_AXI_0_arprot                       ),
    .M01_AXI_0_arlock       (M01_AXI_0_arlock                       ),
    .M01_AXI_0_rready       (M01_AXI_0_rready                       ),
    .M01_AXI_0_rvalid       (M01_AXI_0_rvalid                       ),
    .M01_AXI_0_rdata        (M01_AXI_0_rdata                        ),
    .M01_AXI_0_rlast        (M01_AXI_0_rlast                        ),
    .M01_AXI_0_rresp        (M01_AXI_0_rresp                        ),
    .M01_AXI_0_awready      (M01_AXI_0_awready                      ),
    .M01_AXI_0_awvalid      (M01_AXI_0_awvalid                      ),
    .M01_AXI_0_awaddr       (M01_AXI_0_awaddr                       ),
    .M01_AXI_0_awlen        (M01_AXI_0_awlen                        ),
    .M01_AXI_0_awsize       (M01_AXI_0_awsize                       ),
    .M01_AXI_0_awburst      (M01_AXI_0_awburst                      ),
    .M01_AXI_0_awcache      (M01_AXI_0_awcache                      ),
    .M01_AXI_0_awqos        (M01_AXI_0_awqos                        ),
    .M01_AXI_0_awregion     (M01_AXI_0_awregion                     ),
    .M01_AXI_0_awprot       (M01_AXI_0_awprot                       ),
    .M01_AXI_0_awlock       (M01_AXI_0_awlock                       ),
    .M01_AXI_0_wready       (M01_AXI_0_wready                       ),
    .M01_AXI_0_wvalid       (M01_AXI_0_wvalid                       ),
    .M01_AXI_0_wdata        (M01_AXI_0_wdata                        ),
    .M01_AXI_0_wstrb        (M01_AXI_0_wstrb                        ),
    .M01_AXI_0_wlast        (M01_AXI_0_wlast                        ),
    .M01_AXI_0_bready       (M01_AXI_0_bready                       ),
    .M01_AXI_0_bvalid       (M01_AXI_0_bvalid                       ),
    .M01_AXI_0_bresp        (M01_AXI_0_bresp                        ),
    //------------------------------------------
    .S00_AXI_0_arid         (S00_AXI_0_arid                         ),//i
    .S00_AXI_0_awid         (S00_AXI_0_awid                         ),//i
    .S00_AXI_0_rid          (S00_AXI_0_rid                          ),//o
    .S00_AXI_0_bid          (S00_AXI_0_bid                          ),//o
    .S00_ACLK_0             (S00_ACLK_0                             ),
    .S00_ARESETN_0          (S00_ARESETN_0                          ),
    .S00_AXI_0_arready      (S00_AXI_0_arready                      ),
    .S00_AXI_0_arvalid      (S00_AXI_0_arvalid                      ),
    .S00_AXI_0_araddr       (S00_AXI_0_araddr                       ),
    .S00_AXI_0_arlen        (S00_AXI_0_arlen                        ),
    .S00_AXI_0_arsize       (S00_AXI_0_arsize                       ),
    .S00_AXI_0_arburst      (S00_AXI_0_arburst                      ),
    .S00_AXI_0_arcache      (S00_AXI_0_arcache                      ),
    .S00_AXI_0_arqos        (S00_AXI_0_arqos                        ),
    .S00_AXI_0_arregion     (S00_AXI_0_arregion                     ),
    .S00_AXI_0_arprot       (S00_AXI_0_arprot                       ),
    .S00_AXI_0_arlock       (S00_AXI_0_arlock                       ),
    .S00_AXI_0_rready       (S00_AXI_0_rready                       ),
    .S00_AXI_0_rvalid       (S00_AXI_0_rvalid                       ),
    .S00_AXI_0_rdata        (S00_AXI_0_rdata                        ),
    .S00_AXI_0_rlast        (S00_AXI_0_rlast                        ),
    .S00_AXI_0_rresp        (S00_AXI_0_rresp                        ),
    .S00_AXI_0_awready      (S00_AXI_0_awready                      ),
    .S00_AXI_0_awvalid      (S00_AXI_0_awvalid                      ),
    .S00_AXI_0_awaddr       (S00_AXI_0_awaddr                       ),
    .S00_AXI_0_awlen        (S00_AXI_0_awlen                        ),
    .S00_AXI_0_awsize       (S00_AXI_0_awsize                       ),
    .S00_AXI_0_awburst      (S00_AXI_0_awburst                      ),
    .S00_AXI_0_awcache      (S00_AXI_0_awcache                      ),
    .S00_AXI_0_awqos        (S00_AXI_0_awqos                        ),
    .S00_AXI_0_awregion     (S00_AXI_0_awregion                     ),
    .S00_AXI_0_awprot       (S00_AXI_0_awprot                       ),
    .S00_AXI_0_awlock       (S00_AXI_0_awlock                       ),
    .S00_AXI_0_wready       (S00_AXI_0_wready                       ),
    .S00_AXI_0_wvalid       (S00_AXI_0_wvalid                       ),
    .S00_AXI_0_wdata        (S00_AXI_0_wdata                        ),
    .S00_AXI_0_wstrb        (S00_AXI_0_wstrb                        ),
    .S00_AXI_0_wlast        (S00_AXI_0_wlast                        ),
    .S00_AXI_0_bready       (S00_AXI_0_bready                       ),
    .S00_AXI_0_bvalid       (S00_AXI_0_bvalid                       ),
    .S00_AXI_0_bresp        (S00_AXI_0_bresp                        ),
    //
    .S01_AXI_0_arid         (S01_AXI_0_arid_bus                     ),//i
    .S01_AXI_0_awid         (S01_AXI_0_awid_bus                     ),//i
    .S01_AXI_0_rid          (S01_AXI_0_rid_bus                      ),//o
    .S01_AXI_0_bid          (S01_AXI_0_bid_bus                      ),//o
    .S01_AXI_0_arready      (S01_AXI_0_arready                      ),
    .S01_AXI_0_arvalid      (S01_AXI_0_arvalid                      ),
    .S01_AXI_0_araddr       (S01_AXI_0_araddr                       ),
    .S01_AXI_0_arlen        (S01_AXI_0_arlen                        ),
    .S01_AXI_0_arsize       (S01_AXI_0_arsize                       ),
    .S01_AXI_0_arburst      (S01_AXI_0_arburst                      ),
    .S01_AXI_0_arcache      (S01_AXI_0_arcache                      ),
    .S01_AXI_0_arqos        (S01_AXI_0_arqos                        ),
//  .S01_AXI_0_arregion     (S01_AXI_0_arregion                     ),//no
    .S01_AXI_0_arprot       (S01_AXI_0_arprot                       ),
    .S01_AXI_0_arlock       (S01_AXI_0_arlock                       ),
    .S01_AXI_0_rready       (S01_AXI_0_rready                       ),
    .S01_AXI_0_rvalid       (S01_AXI_0_rvalid                       ),
    .S01_AXI_0_rdata        (S01_AXI_0_rdata                        ),
    .S01_AXI_0_rlast        (S01_AXI_0_rlast                        ),
    .S01_AXI_0_rresp        (S01_AXI_0_rresp                        ),
    .S01_AXI_0_awready      (S01_AXI_0_awready                      ),
    .S01_AXI_0_awvalid      (S01_AXI_0_awvalid                      ),
    .S01_AXI_0_awaddr       (S01_AXI_0_awaddr                       ),
    .S01_AXI_0_awlen        (S01_AXI_0_awlen                        ),
    .S01_AXI_0_awsize       (S01_AXI_0_awsize                       ),
    .S01_AXI_0_awburst      (S01_AXI_0_awburst                      ),
    .S01_AXI_0_awcache      (S01_AXI_0_awcache                      ),
    .S01_AXI_0_awqos        (S01_AXI_0_awqos                        ),
//  .S01_AXI_0_awregion     (S01_AXI_0_awregion                     ),//no
    .S01_AXI_0_awprot       (S01_AXI_0_awprot                       ),
    .S01_AXI_0_awlock       (S01_AXI_0_awlock                       ),
    .S01_AXI_0_wready       (S01_AXI_0_wready                       ),
    .S01_AXI_0_wvalid       (S01_AXI_0_wvalid                       ),
    .S01_AXI_0_wdata        (S01_AXI_0_wdata                        ),
    .S01_AXI_0_wstrb        (S01_AXI_0_wstrb                        ),
    .S01_AXI_0_wlast        (S01_AXI_0_wlast                        ),
    .S01_AXI_0_bready       (S01_AXI_0_bready                       ),
    .S01_AXI_0_bvalid       (S01_AXI_0_bvalid                       ),
    .S01_AXI_0_bresp        (S01_AXI_0_bresp                        ),
    //
    .S02_AXI_0_arid         (S02_AXI_0_arid                         ),//i
    .S02_AXI_0_awid         (S02_AXI_0_awid                         ),//i
    .S02_AXI_0_rid          (S02_AXI_0_rid                          ),//o
    .S02_AXI_0_bid          (S02_AXI_0_bid                          ),//o
    .S02_AXI_0_arready      (S02_AXI_0_arready                      ),
    .S02_AXI_0_arvalid      (S02_AXI_0_arvalid                      ),
    .S02_AXI_0_araddr       (S02_AXI_0_araddr                       ),
    .S02_AXI_0_arlen        (S02_AXI_0_arlen                        ),
    .S02_AXI_0_arsize       (S02_AXI_0_arsize                       ),
    .S02_AXI_0_arburst      (S02_AXI_0_arburst                      ),
    .S02_AXI_0_arcache      (S02_AXI_0_arcache                      ),
    .S02_AXI_0_arqos        (S02_AXI_0_arqos                        ),
    .S02_AXI_0_arregion     (S02_AXI_0_arregion                     ),
    .S02_AXI_0_arprot       (S02_AXI_0_arprot                       ),
    .S02_AXI_0_arlock       (S02_AXI_0_arlock                       ),
    .S02_AXI_0_rready       (S02_AXI_0_rready                       ),
    .S02_AXI_0_rvalid       (S02_AXI_0_rvalid                       ),
    .S02_AXI_0_rdata        (S02_AXI_0_rdata                        ),
    .S02_AXI_0_rlast        (S02_AXI_0_rlast                        ),
    .S02_AXI_0_rresp        (S02_AXI_0_rresp                        ),
    .S02_AXI_0_awready      (S02_AXI_0_awready                      ),
    .S02_AXI_0_awvalid      (S02_AXI_0_awvalid                      ),
    .S02_AXI_0_awaddr       (S02_AXI_0_awaddr                       ),
    .S02_AXI_0_awlen        (S02_AXI_0_awlen                        ),
    .S02_AXI_0_awsize       (S02_AXI_0_awsize                       ),
    .S02_AXI_0_awburst      (S02_AXI_0_awburst                      ),
    .S02_AXI_0_awcache      (S02_AXI_0_awcache                      ),
    .S02_AXI_0_awqos        (S02_AXI_0_awqos                        ),
    .S02_AXI_0_awregion     (S02_AXI_0_awregion                     ),
    .S02_AXI_0_awprot       (S02_AXI_0_awprot                       ),
    .S02_AXI_0_awlock       (S02_AXI_0_awlock                       ),
    .S02_AXI_0_wready       (S02_AXI_0_wready                       ),
    .S02_AXI_0_wvalid       (S02_AXI_0_wvalid                       ),
    .S02_AXI_0_wdata        (S02_AXI_0_wdata                        ),
    .S02_AXI_0_wstrb        (S02_AXI_0_wstrb                        ),
    .S02_AXI_0_wlast        (S02_AXI_0_wlast                        ),
    .S02_AXI_0_bready       (S02_AXI_0_bready                       ),
    .S02_AXI_0_bvalid       (S02_AXI_0_bvalid                       ),
    .S02_AXI_0_bresp        (S02_AXI_0_bresp                        )
);
`else
u_opu_axi_bypass
#(.MID(MID),
  .SID(SID))
u0_bypass_m2s3
(
    .M00_ACLK_0             (M00_ACLK_0                             ),
    .M00_ARESETN_0          (M00_ARESETN_0                          ),
    .M00_AXI_0_arready      (M00_AXI_0_arready                      ),
    .M00_AXI_0_arvalid      (M00_AXI_0_arvalid                      ),
    .M00_AXI_0_araddr       (M00_AXI_0_araddr                       ),
    .M00_AXI_0_arlen        (M00_AXI_0_arlen                        ),
    .M00_AXI_0_arsize       (M00_AXI_0_arsize                       ),
    .M00_AXI_0_arburst      (M00_AXI_0_arburst                      ),
    .M00_AXI_0_arid         (M00_AXI_0_arid                         ),
    .M00_AXI_0_arcache      (M00_AXI_0_arcache                      ),
    .M00_AXI_0_arqos        (M00_AXI_0_arqos                        ),
    .M00_AXI_0_arregion     (M00_AXI_0_arregion                     ),
    .M00_AXI_0_arprot       (M00_AXI_0_arprot                       ),
    .M00_AXI_0_arlock       (M00_AXI_0_arlock                       ),
    .M00_AXI_0_rready       (M00_AXI_0_rready                       ),
    .M00_AXI_0_rvalid       (M00_AXI_0_rvalid                       ),
    .M00_AXI_0_rdata        (M00_AXI_0_rdata                        ),
    .M00_AXI_0_rid          (M00_AXI_0_rid                          ),
    .M00_AXI_0_rlast        (M00_AXI_0_rlast                        ),
    .M00_AXI_0_rresp        (M00_AXI_0_rresp                        ),
    .M00_AXI_0_awready      (M00_AXI_0_awready                      ),
    .M00_AXI_0_awvalid      (M00_AXI_0_awvalid                      ),
    .M00_AXI_0_awaddr       (M00_AXI_0_awaddr                       ),
    .M00_AXI_0_awlen        (M00_AXI_0_awlen                        ),
    .M00_AXI_0_awsize       (M00_AXI_0_awsize                       ),
    .M00_AXI_0_awburst      (M00_AXI_0_awburst                      ),
    .M00_AXI_0_awid         (M00_AXI_0_awid                         ),
    .M00_AXI_0_awcache      (M00_AXI_0_awcache                      ),
    .M00_AXI_0_awqos        (M00_AXI_0_awqos                        ),
    .M00_AXI_0_awregion     (M00_AXI_0_awregion                     ),
    .M00_AXI_0_awprot       (M00_AXI_0_awprot                       ),
    .M00_AXI_0_awlock       (M00_AXI_0_awlock                       ),
    .M00_AXI_0_wready       (M00_AXI_0_wready                       ),
    .M00_AXI_0_wvalid       (M00_AXI_0_wvalid                       ),
    .M00_AXI_0_wdata        (M00_AXI_0_wdata                        ),
    .M00_AXI_0_wstrb        (M00_AXI_0_wstrb                        ),
    .M00_AXI_0_wlast        (M00_AXI_0_wlast                        ),
    .M00_AXI_0_bready       (M00_AXI_0_bready                       ),
    .M00_AXI_0_bvalid       (M00_AXI_0_bvalid                       ),
    .M00_AXI_0_bid          (M00_AXI_0_bid                          ),
    .M00_AXI_0_bresp        (M00_AXI_0_bresp                        ),
    //
    .M01_ACLK_0             (M01_ACLK_0                             ),
    .M01_ARESETN_0          (M01_ARESETN_0                          ),
    .M01_AXI_0_arready      (M01_AXI_0_arready                      ),
    .M01_AXI_0_arvalid      (M01_AXI_0_arvalid                      ),
    .M01_AXI_0_araddr       (M01_AXI_0_araddr                       ),
    .M01_AXI_0_arlen        (M01_AXI_0_arlen                        ),
    .M01_AXI_0_arsize       (M01_AXI_0_arsize                       ),
    .M01_AXI_0_arburst      (M01_AXI_0_arburst                      ),
    .M01_AXI_0_arid         (M01_AXI_0_arid                         ),
    .M01_AXI_0_arcache      (M01_AXI_0_arcache                      ),
    .M01_AXI_0_arqos        (M01_AXI_0_arqos                        ),
    .M01_AXI_0_arregion     (M01_AXI_0_arregion                     ),
    .M01_AXI_0_arprot       (M01_AXI_0_arprot                       ),
    .M01_AXI_0_arlock       (M01_AXI_0_arlock                       ),
    .M01_AXI_0_rready       (M01_AXI_0_rready                       ),
    .M01_AXI_0_rvalid       (M01_AXI_0_rvalid                       ),
    .M01_AXI_0_rdata        (M01_AXI_0_rdata                        ),
    .M01_AXI_0_rid          (M01_AXI_0_rid                          ),
    .M01_AXI_0_rlast        (M01_AXI_0_rlast                        ),
    .M01_AXI_0_rresp        (M01_AXI_0_rresp                        ),
    .M01_AXI_0_awready      (M01_AXI_0_awready                      ),
    .M01_AXI_0_awvalid      (M01_AXI_0_awvalid                      ),
    .M01_AXI_0_awaddr       (M01_AXI_0_awaddr                       ),
    .M01_AXI_0_awlen        (M01_AXI_0_awlen                        ),
    .M01_AXI_0_awsize       (M01_AXI_0_awsize                       ),
    .M01_AXI_0_awburst      (M01_AXI_0_awburst                      ),
    .M01_AXI_0_awid         (M01_AXI_0_awid                         ),
    .M01_AXI_0_awcache      (M01_AXI_0_awcache                      ),
    .M01_AXI_0_awqos        (M01_AXI_0_awqos                        ),
    .M01_AXI_0_awregion     (M01_AXI_0_awregion                     ),
    .M01_AXI_0_awprot       (M01_AXI_0_awprot                       ),
    .M01_AXI_0_awlock       (M01_AXI_0_awlock                       ),
    .M01_AXI_0_wready       (M01_AXI_0_wready                       ),
    .M01_AXI_0_wvalid       (M01_AXI_0_wvalid                       ),
    .M01_AXI_0_wdata        (M01_AXI_0_wdata                        ),
    .M01_AXI_0_wstrb        (M01_AXI_0_wstrb                        ),
    .M01_AXI_0_wlast        (M01_AXI_0_wlast                        ),
    .M01_AXI_0_bready       (M01_AXI_0_bready                       ),
    .M01_AXI_0_bvalid       (M01_AXI_0_bvalid                       ),
    .M01_AXI_0_bid          (M01_AXI_0_bid                          ),
    .M01_AXI_0_bresp        (M01_AXI_0_bresp                        ),
    //------------------------------------------
    .S00_ACLK_0             (S00_ACLK_0                             ),
    .S00_ARESETN_0          (S00_ARESETN_0                          ),
    .S00_AXI_0_arready      (S00_AXI_0_arready                      ),
    .S00_AXI_0_arvalid      (S00_AXI_0_arvalid                      ),
    .S00_AXI_0_araddr       (S00_AXI_0_araddr                       ),
    .S00_AXI_0_arlen        (S00_AXI_0_arlen                        ),
    .S00_AXI_0_arsize       (S00_AXI_0_arsize                       ),
    .S00_AXI_0_arburst      (S00_AXI_0_arburst                      ),
    .S00_AXI_0_arid         (S00_AXI_0_arid                         ),
    .S00_AXI_0_arcache      (S00_AXI_0_arcache                      ),
    .S00_AXI_0_arqos        (S00_AXI_0_arqos                        ),
    .S00_AXI_0_arregion     (S00_AXI_0_arregion                     ),
    .S00_AXI_0_arprot       (S00_AXI_0_arprot                       ),
    .S00_AXI_0_arlock       (S00_AXI_0_arlock                       ),
    .S00_AXI_0_rready       (S00_AXI_0_rready                       ),
    .S00_AXI_0_rvalid       (S00_AXI_0_rvalid                       ),
    .S00_AXI_0_rdata        (S00_AXI_0_rdata                        ),
    .S00_AXI_0_rlast        (S00_AXI_0_rlast                        ),
    .S00_AXI_0_rid          (S00_AXI_0_rid                          ),
    .S00_AXI_0_rresp        (S00_AXI_0_rresp                        ),
    .S00_AXI_0_awready      (S00_AXI_0_awready                      ),
    .S00_AXI_0_awvalid      (S00_AXI_0_awvalid                      ),
    .S00_AXI_0_awaddr       (S00_AXI_0_awaddr                       ),
    .S00_AXI_0_awlen        (S00_AXI_0_awlen                        ),
    .S00_AXI_0_awsize       (S00_AXI_0_awsize                       ),
    .S00_AXI_0_awburst      (S00_AXI_0_awburst                      ),
    .S00_AXI_0_awid         (S00_AXI_0_awid                         ),
    .S00_AXI_0_awcache      (S00_AXI_0_awcache                      ),
    .S00_AXI_0_awqos        (S00_AXI_0_awqos                        ),
    .S00_AXI_0_awregion     (S00_AXI_0_awregion                     ),
    .S00_AXI_0_awprot       (S00_AXI_0_awprot                       ),
    .S00_AXI_0_awlock       (S00_AXI_0_awlock                       ),
    .S00_AXI_0_wready       (S00_AXI_0_wready                       ),
    .S00_AXI_0_wvalid       (S00_AXI_0_wvalid                       ),
    .S00_AXI_0_wdata        (S00_AXI_0_wdata                        ),
    .S00_AXI_0_wstrb        (S00_AXI_0_wstrb                        ),
    .S00_AXI_0_wlast        (S00_AXI_0_wlast                        ),
    .S00_AXI_0_bready       (S00_AXI_0_bready                       ),
    .S00_AXI_0_bvalid       (S00_AXI_0_bvalid                       ),
    .S00_AXI_0_bid          (S00_AXI_0_bid                          ),
    .S00_AXI_0_bresp        (S00_AXI_0_bresp                        ),
    //
    .S01_AXI_0_arready      (S01_AXI_0_arready                      ),
    .S01_AXI_0_arvalid      (S01_AXI_0_arvalid                      ),
    .S01_AXI_0_araddr       (S01_AXI_0_araddr                       ),
    .S01_AXI_0_arlen        (S01_AXI_0_arlen                        ),
    .S01_AXI_0_arsize       (S01_AXI_0_arsize                       ),
    .S01_AXI_0_arburst      (S01_AXI_0_arburst                      ),
    .S01_AXI_0_arid         (S01_AXI_0_arid                         ),
    .S01_AXI_0_arcache      (S01_AXI_0_arcache                      ),
    .S01_AXI_0_arqos        (S01_AXI_0_arqos                        ),
    .S01_AXI_0_arregion     (S01_AXI_0_arregion                     ),
    .S01_AXI_0_arprot       (S01_AXI_0_arprot                       ),
    .S01_AXI_0_arlock       (S01_AXI_0_arlock                       ),
    .S01_AXI_0_rready       (S01_AXI_0_rready                       ),
    .S01_AXI_0_rvalid       (S01_AXI_0_rvalid                       ),
    .S01_AXI_0_rdata        (S01_AXI_0_rdata                        ),
    .S01_AXI_0_rlast        (S01_AXI_0_rlast                        ),
    .S01_AXI_0_rid          (S01_AXI_0_rid_bus                      ),
    .S01_AXI_0_rresp        (S01_AXI_0_rresp                        ),
    .S01_AXI_0_awready      (S01_AXI_0_awready                      ),
    .S01_AXI_0_awvalid      (S01_AXI_0_awvalid                      ),
    .S01_AXI_0_awaddr       (S01_AXI_0_awaddr                       ),
    .S01_AXI_0_awlen        (S01_AXI_0_awlen                        ),
    .S01_AXI_0_awsize       (S01_AXI_0_awsize                       ),
    .S01_AXI_0_awburst      (S01_AXI_0_awburst                      ),
    .S01_AXI_0_awid         (S01_AXI_0_awid                         ),
    .S01_AXI_0_awcache      (S01_AXI_0_awcache                      ),
    .S01_AXI_0_awqos        (S01_AXI_0_awqos                        ),
    .S01_AXI_0_awregion     (S01_AXI_0_awregion                     ),
    .S01_AXI_0_awprot       (S01_AXI_0_awprot                       ),
    .S01_AXI_0_awlock       (S01_AXI_0_awlock                       ),
    .S01_AXI_0_wready       (S01_AXI_0_wready                       ),
    .S01_AXI_0_wvalid       (S01_AXI_0_wvalid                       ),
    .S01_AXI_0_wdata        (S01_AXI_0_wdata                        ),
    .S01_AXI_0_wstrb        (S01_AXI_0_wstrb                        ),
    .S01_AXI_0_wlast        (S01_AXI_0_wlast                        ),
    .S01_AXI_0_bready       (S01_AXI_0_bready                       ),
    .S01_AXI_0_bvalid       (S01_AXI_0_bvalid                       ),
    .S01_AXI_0_bid          (S01_AXI_0_bid_bus                      ),
    .S01_AXI_0_bresp        (S01_AXI_0_bresp                        ),
    //
    .S02_AXI_0_arready      (S02_AXI_0_arready                      ),
    .S02_AXI_0_arvalid      (S02_AXI_0_arvalid                      ),
    .S02_AXI_0_araddr       (S02_AXI_0_araddr                       ),
    .S02_AXI_0_arlen        (S02_AXI_0_arlen                        ),
    .S02_AXI_0_arsize       (S02_AXI_0_arsize                       ),
    .S02_AXI_0_arburst      (S02_AXI_0_arburst                      ),
    .S02_AXI_0_arid         (S02_AXI_0_arid                         ),
    .S02_AXI_0_arcache      (S02_AXI_0_arcache                      ),
    .S02_AXI_0_arqos        (S02_AXI_0_arqos                        ),
    .S02_AXI_0_arregion     (S02_AXI_0_arregion                     ),
    .S02_AXI_0_arprot       (S02_AXI_0_arprot                       ),
    .S02_AXI_0_arlock       (S02_AXI_0_arlock                       ),
    .S02_AXI_0_rready       (S02_AXI_0_rready                       ),
    .S02_AXI_0_rvalid       (S02_AXI_0_rvalid                       ),
    .S02_AXI_0_rdata        (S02_AXI_0_rdata                        ),
    .S02_AXI_0_rlast        (S02_AXI_0_rlast                        ),
    .S02_AXI_0_rid          (S02_AXI_0_rid                          ),
    .S02_AXI_0_rresp        (S02_AXI_0_rresp                        ),
    .S02_AXI_0_awready      (S02_AXI_0_awready                      ),
    .S02_AXI_0_awvalid      (S02_AXI_0_awvalid                      ),
    .S02_AXI_0_awaddr       (S02_AXI_0_awaddr                       ),
    .S02_AXI_0_awlen        (S02_AXI_0_awlen                        ),
    .S02_AXI_0_awsize       (S02_AXI_0_awsize                       ),
    .S02_AXI_0_awburst      (S02_AXI_0_awburst                      ),
    .S02_AXI_0_awid         (S02_AXI_0_awid                         ),
    .S02_AXI_0_awcache      (S02_AXI_0_awcache                      ),
    .S02_AXI_0_awqos        (S02_AXI_0_awqos                        ),
    .S02_AXI_0_awregion     (S02_AXI_0_awregion                     ),
    .S02_AXI_0_awprot       (S02_AXI_0_awprot                       ),
    .S02_AXI_0_awlock       (S02_AXI_0_awlock                       ),
    .S02_AXI_0_wready       (S02_AXI_0_wready                       ),
    .S02_AXI_0_wvalid       (S02_AXI_0_wvalid                       ),
    .S02_AXI_0_wdata        (S02_AXI_0_wdata                        ),
    .S02_AXI_0_wstrb        (S02_AXI_0_wstrb                        ),
    .S02_AXI_0_wlast        (S02_AXI_0_wlast                        ),
    .S02_AXI_0_bready       (S02_AXI_0_bready                       ),
    .S02_AXI_0_bvalid       (S02_AXI_0_bvalid                       ),
    .S02_AXI_0_bid          (S02_AXI_0_bid                          ),
    .S02_AXI_0_bresp        (S02_AXI_0_bresp                        )
);
`endif//sim
`endif//2core



`ifdef DESIGN_OPU_CORE4
`ifndef AXI_BYPASS
//-----------------------------------------------
(*keep_hierarchy="yes"*)Block_AXI_M4S5 AXI_M4S5
(
    .M00_AXI_0_arid         (M00_AXI_0_arid                         ),//o
    .M00_AXI_0_awid         (M00_AXI_0_awid                         ),//o
    .M00_AXI_0_rid          (M00_AXI_0_rid                          ),//i
    .M00_AXI_0_bid          (M00_AXI_0_bid                          ),//i
    .M00_ACLK_0             (M00_ACLK_0                             ),//
    .M00_ARESETN_0          (M00_ARESETN_0                          ),//
    .M00_AXI_0_arready      (M00_AXI_0_arready                      ),
    .M00_AXI_0_arvalid      (M00_AXI_0_arvalid                      ),
    .M00_AXI_0_araddr       (M00_AXI_0_araddr                       ),
    .M00_AXI_0_arlen        (M00_AXI_0_arlen                        ),
    .M00_AXI_0_arsize       (M00_AXI_0_arsize                       ),
    .M00_AXI_0_arburst      (M00_AXI_0_arburst                      ),
    .M00_AXI_0_arcache      (M00_AXI_0_arcache                      ),
    .M00_AXI_0_arqos        (M00_AXI_0_arqos                        ),
    .M00_AXI_0_arregion     (M00_AXI_0_arregion                     ),
    .M00_AXI_0_arprot       (M00_AXI_0_arprot                       ),
    .M00_AXI_0_arlock       (M00_AXI_0_arlock                       ),
    .M00_AXI_0_rready       (M00_AXI_0_rready                       ),
    .M00_AXI_0_rvalid       (M00_AXI_0_rvalid                       ),
    .M00_AXI_0_rdata        (M00_AXI_0_rdata                        ),
    .M00_AXI_0_rlast        (M00_AXI_0_rlast                        ),
    .M00_AXI_0_rresp        (M00_AXI_0_rresp                        ),
    .M00_AXI_0_awready      (M00_AXI_0_awready                      ),
    .M00_AXI_0_awvalid      (M00_AXI_0_awvalid                      ),
    .M00_AXI_0_awaddr       (M00_AXI_0_awaddr                       ),
    .M00_AXI_0_awlen        (M00_AXI_0_awlen                        ),
    .M00_AXI_0_awsize       (M00_AXI_0_awsize                       ),
    .M00_AXI_0_awburst      (M00_AXI_0_awburst                      ),
    .M00_AXI_0_awcache      (M00_AXI_0_awcache                      ),
    .M00_AXI_0_awqos        (M00_AXI_0_awqos                        ),
    .M00_AXI_0_awregion     (M00_AXI_0_awregion                     ),
    .M00_AXI_0_awprot       (M00_AXI_0_awprot                       ),
    .M00_AXI_0_awlock       (M00_AXI_0_awlock                       ),
    .M00_AXI_0_wready       (M00_AXI_0_wready                       ),
    .M00_AXI_0_wvalid       (M00_AXI_0_wvalid                       ),
    .M00_AXI_0_wdata        (M00_AXI_0_wdata                        ),
    .M00_AXI_0_wstrb        (M00_AXI_0_wstrb                        ),
    .M00_AXI_0_wlast        (M00_AXI_0_wlast                        ),
    .M00_AXI_0_bready       (M00_AXI_0_bready                       ),
    .M00_AXI_0_bvalid       (M00_AXI_0_bvalid                       ),
    .M00_AXI_0_bresp        (M00_AXI_0_bresp                        ),
    //
    .M01_AXI_0_arid         (M01_AXI_0_arid                         ),//o
    .M01_AXI_0_awid         (M01_AXI_0_awid                         ),//o
    .M01_AXI_0_rid          (M01_AXI_0_rid                          ),//i
    .M01_AXI_0_bid          (M01_AXI_0_bid                          ),//i
    .M01_ACLK_0             (M01_ACLK_0                             ),
    .M01_ARESETN_0          (M01_ARESETN_0                          ),
    .M01_AXI_0_arready      (M01_AXI_0_arready                      ),
    .M01_AXI_0_arvalid      (M01_AXI_0_arvalid                      ),
    .M01_AXI_0_araddr       (M01_AXI_0_araddr                       ),
    .M01_AXI_0_arlen        (M01_AXI_0_arlen                        ),
    .M01_AXI_0_arsize       (M01_AXI_0_arsize                       ),
    .M01_AXI_0_arburst      (M01_AXI_0_arburst                      ),
    .M01_AXI_0_arcache      (M01_AXI_0_arcache                      ),
    .M01_AXI_0_arqos        (M01_AXI_0_arqos                        ),
    .M01_AXI_0_arregion     (M01_AXI_0_arregion                     ),
    .M01_AXI_0_arprot       (M01_AXI_0_arprot                       ),
    .M01_AXI_0_arlock       (M01_AXI_0_arlock                       ),
    .M01_AXI_0_rready       (M01_AXI_0_rready                       ),
    .M01_AXI_0_rvalid       (M01_AXI_0_rvalid                       ),
    .M01_AXI_0_rdata        (M01_AXI_0_rdata                        ),
    .M01_AXI_0_rlast        (M01_AXI_0_rlast                        ),
    .M01_AXI_0_rresp        (M01_AXI_0_rresp                        ),
    .M01_AXI_0_awready      (M01_AXI_0_awready                      ),
    .M01_AXI_0_awvalid      (M01_AXI_0_awvalid                      ),
    .M01_AXI_0_awaddr       (M01_AXI_0_awaddr                       ),
    .M01_AXI_0_awlen        (M01_AXI_0_awlen                        ),
    .M01_AXI_0_awsize       (M01_AXI_0_awsize                       ),
    .M01_AXI_0_awburst      (M01_AXI_0_awburst                      ),
    .M01_AXI_0_awcache      (M01_AXI_0_awcache                      ),
    .M01_AXI_0_awqos        (M01_AXI_0_awqos                        ),
    .M01_AXI_0_awregion     (M01_AXI_0_awregion                     ),
    .M01_AXI_0_awprot       (M01_AXI_0_awprot                       ),
    .M01_AXI_0_awlock       (M01_AXI_0_awlock                       ),
    .M01_AXI_0_wready       (M01_AXI_0_wready                       ),
    .M01_AXI_0_wvalid       (M01_AXI_0_wvalid                       ),
    .M01_AXI_0_wdata        (M01_AXI_0_wdata                        ),
    .M01_AXI_0_wstrb        (M01_AXI_0_wstrb                        ),
    .M01_AXI_0_wlast        (M01_AXI_0_wlast                        ),
    .M01_AXI_0_bready       (M01_AXI_0_bready                       ),
    .M01_AXI_0_bvalid       (M01_AXI_0_bvalid                       ),
    .M01_AXI_0_bresp        (M01_AXI_0_bresp                        ),
    //
    .M02_AXI_0_arid         (M02_AXI_0_arid                         ),//o
    .M02_AXI_0_awid         (M02_AXI_0_awid                         ),//o
    .M02_AXI_0_rid          (M02_AXI_0_rid                          ),//i
    .M02_AXI_0_bid          (M02_AXI_0_bid                          ),//i
    .M02_ACLK_0             (M02_ACLK_0                             ),
    .M02_ARESETN_0          (M02_ARESETN_0                          ),
    .M02_AXI_0_arready      (M02_AXI_0_arready                      ),
    .M02_AXI_0_arvalid      (M02_AXI_0_arvalid                      ),
    .M02_AXI_0_araddr       (M02_AXI_0_araddr                       ),
    .M02_AXI_0_arlen        (M02_AXI_0_arlen                        ),
    .M02_AXI_0_arsize       (M02_AXI_0_arsize                       ),
    .M02_AXI_0_arburst      (M02_AXI_0_arburst                      ),
    .M02_AXI_0_arcache      (M02_AXI_0_arcache                      ),
    .M02_AXI_0_arqos        (M02_AXI_0_arqos                        ),
    .M02_AXI_0_arregion     (M02_AXI_0_arregion                     ),
    .M02_AXI_0_arprot       (M02_AXI_0_arprot                       ),
    .M02_AXI_0_arlock       (M02_AXI_0_arlock                       ),
    .M02_AXI_0_rready       (M02_AXI_0_rready                       ),
    .M02_AXI_0_rvalid       (M02_AXI_0_rvalid                       ),
    .M02_AXI_0_rdata        (M02_AXI_0_rdata                        ),
    .M02_AXI_0_rlast        (M02_AXI_0_rlast                        ),
    .M02_AXI_0_rresp        (M02_AXI_0_rresp                        ),
    .M02_AXI_0_awready      (M02_AXI_0_awready                      ),
    .M02_AXI_0_awvalid      (M02_AXI_0_awvalid                      ),
    .M02_AXI_0_awaddr       (M02_AXI_0_awaddr                       ),
    .M02_AXI_0_awlen        (M02_AXI_0_awlen                        ),
    .M02_AXI_0_awsize       (M02_AXI_0_awsize                       ),
    .M02_AXI_0_awburst      (M02_AXI_0_awburst                      ),
    .M02_AXI_0_awcache      (M02_AXI_0_awcache                      ),
    .M02_AXI_0_awqos        (M02_AXI_0_awqos                        ),
    .M02_AXI_0_awregion     (M02_AXI_0_awregion                     ),
    .M02_AXI_0_awprot       (M02_AXI_0_awprot                       ),
    .M02_AXI_0_awlock       (M02_AXI_0_awlock                       ),
    .M02_AXI_0_wready       (M02_AXI_0_wready                       ),
    .M02_AXI_0_wvalid       (M02_AXI_0_wvalid                       ),
    .M02_AXI_0_wdata        (M02_AXI_0_wdata                        ),
    .M02_AXI_0_wstrb        (M02_AXI_0_wstrb                        ),
    .M02_AXI_0_wlast        (M02_AXI_0_wlast                        ),
    .M02_AXI_0_bready       (M02_AXI_0_bready                       ),
    .M02_AXI_0_bvalid       (M02_AXI_0_bvalid                       ),
    .M02_AXI_0_bresp        (M02_AXI_0_bresp                        ),
    //
    .M03_AXI_0_arid         (M03_AXI_0_arid                         ),//o
    .M03_AXI_0_awid         (M03_AXI_0_awid                         ),//o
    .M03_AXI_0_rid          (M03_AXI_0_rid                          ),//i
    .M03_AXI_0_bid          (M03_AXI_0_bid                          ),//i
    .M03_ACLK_0             (M03_ACLK_0                             ),
    .M03_ARESETN_0          (M03_ARESETN_0                          ),
    .M03_AXI_0_arready      (M03_AXI_0_arready                      ),
    .M03_AXI_0_arvalid      (M03_AXI_0_arvalid                      ),
    .M03_AXI_0_araddr       (M03_AXI_0_araddr                       ),
    .M03_AXI_0_arlen        (M03_AXI_0_arlen                        ),
    .M03_AXI_0_arsize       (M03_AXI_0_arsize                       ),
    .M03_AXI_0_arburst      (M03_AXI_0_arburst                      ),
    .M03_AXI_0_arcache      (M03_AXI_0_arcache                      ),
    .M03_AXI_0_arqos        (M03_AXI_0_arqos                        ),
    .M03_AXI_0_arregion     (M03_AXI_0_arregion                     ),
    .M03_AXI_0_arprot       (M03_AXI_0_arprot                       ),
    .M03_AXI_0_arlock       (M03_AXI_0_arlock                       ),
    .M03_AXI_0_rready       (M03_AXI_0_rready                       ),
    .M03_AXI_0_rvalid       (M03_AXI_0_rvalid                       ),
    .M03_AXI_0_rdata        (M03_AXI_0_rdata                        ),
    .M03_AXI_0_rlast        (M03_AXI_0_rlast                        ),
    .M03_AXI_0_rresp        (M03_AXI_0_rresp                        ),
    .M03_AXI_0_awready      (M03_AXI_0_awready                      ),
    .M03_AXI_0_awvalid      (M03_AXI_0_awvalid                      ),
    .M03_AXI_0_awaddr       (M03_AXI_0_awaddr                       ),
    .M03_AXI_0_awlen        (M03_AXI_0_awlen                        ),
    .M03_AXI_0_awsize       (M03_AXI_0_awsize                       ),
    .M03_AXI_0_awburst      (M03_AXI_0_awburst                      ),
    .M03_AXI_0_awcache      (M03_AXI_0_awcache                      ),
    .M03_AXI_0_awqos        (M03_AXI_0_awqos                        ),
    .M03_AXI_0_awregion     (M03_AXI_0_awregion                     ),
    .M03_AXI_0_awprot       (M03_AXI_0_awprot                       ),
    .M03_AXI_0_awlock       (M03_AXI_0_awlock                       ),
    .M03_AXI_0_wready       (M03_AXI_0_wready                       ),
    .M03_AXI_0_wvalid       (M03_AXI_0_wvalid                       ),
    .M03_AXI_0_wdata        (M03_AXI_0_wdata                        ),
    .M03_AXI_0_wstrb        (M03_AXI_0_wstrb                        ),
    .M03_AXI_0_wlast        (M03_AXI_0_wlast                        ),
    .M03_AXI_0_bready       (M03_AXI_0_bready                       ),
    .M03_AXI_0_bvalid       (M03_AXI_0_bvalid                       ),
    .M03_AXI_0_bresp        (M03_AXI_0_bresp                        ),
    //------------------------------------------
    .S00_AXI_0_arid         (S00_AXI_0_arid                         ),//i
    .S00_AXI_0_awid         (S00_AXI_0_awid                         ),//i
    .S00_AXI_0_rid          (S00_AXI_0_rid                          ),//o
    .S00_AXI_0_bid          (S00_AXI_0_bid                          ),//o
    .S00_ACLK_0             (S00_ACLK_0                             ),
    .S00_ARESETN_0          (S00_ARESETN_0                          ),
    .S00_AXI_0_arready      (S00_AXI_0_arready                      ),
    .S00_AXI_0_arvalid      (S00_AXI_0_arvalid                      ),
    .S00_AXI_0_araddr       (S00_AXI_0_araddr                       ),
    .S00_AXI_0_arlen        (S00_AXI_0_arlen                        ),
    .S00_AXI_0_arsize       (S00_AXI_0_arsize                       ),
    .S00_AXI_0_arburst      (S00_AXI_0_arburst                      ),
    .S00_AXI_0_arcache      (S00_AXI_0_arcache                      ),
    .S00_AXI_0_arqos        (S00_AXI_0_arqos                        ),
    .S00_AXI_0_arregion     (S00_AXI_0_arregion                     ),
    .S00_AXI_0_arprot       (S00_AXI_0_arprot                       ),
    .S00_AXI_0_arlock       (S00_AXI_0_arlock                       ),
    .S00_AXI_0_rready       (S00_AXI_0_rready                       ),
    .S00_AXI_0_rvalid       (S00_AXI_0_rvalid                       ),
    .S00_AXI_0_rdata        (S00_AXI_0_rdata                        ),
    .S00_AXI_0_rlast        (S00_AXI_0_rlast                        ),
    .S00_AXI_0_rresp        (S00_AXI_0_rresp                        ),
    .S00_AXI_0_awready      (S00_AXI_0_awready                      ),
    .S00_AXI_0_awvalid      (S00_AXI_0_awvalid                      ),
    .S00_AXI_0_awaddr       (S00_AXI_0_awaddr                       ),
    .S00_AXI_0_awlen        (S00_AXI_0_awlen                        ),
    .S00_AXI_0_awsize       (S00_AXI_0_awsize                       ),
    .S00_AXI_0_awburst      (S00_AXI_0_awburst                      ),
    .S00_AXI_0_awcache      (S00_AXI_0_awcache                      ),
    .S00_AXI_0_awqos        (S00_AXI_0_awqos                        ),
    .S00_AXI_0_awregion     (S00_AXI_0_awregion                     ),
    .S00_AXI_0_awprot       (S00_AXI_0_awprot                       ),
    .S00_AXI_0_awlock       (S00_AXI_0_awlock                       ),
    .S00_AXI_0_wready       (S00_AXI_0_wready                       ),
    .S00_AXI_0_wvalid       (S00_AXI_0_wvalid                       ),
    .S00_AXI_0_wdata        (S00_AXI_0_wdata                        ),
    .S00_AXI_0_wstrb        (S00_AXI_0_wstrb                        ),
    .S00_AXI_0_wlast        (S00_AXI_0_wlast                        ),
    .S00_AXI_0_bready       (S00_AXI_0_bready                       ),
    .S00_AXI_0_bvalid       (S00_AXI_0_bvalid                       ),
    .S00_AXI_0_bresp        (S00_AXI_0_bresp                        ),
    //
    .S01_AXI_0_arid         (S01_AXI_0_arid_bus                     ),//i=7bit
    .S01_AXI_0_awid         (S01_AXI_0_awid_bus                     ),//i=7bit
    .S01_AXI_0_rid          (S01_AXI_0_rid_bus                      ),//o=7bit
    .S01_AXI_0_bid          (S01_AXI_0_bid_bus                      ),//o=7bit
    .S01_AXI_0_arready      (S01_AXI_0_arready                      ),
    .S01_AXI_0_arvalid      (S01_AXI_0_arvalid                      ),
    .S01_AXI_0_araddr       (S01_AXI_0_araddr                       ),
    .S01_AXI_0_arlen        (S01_AXI_0_arlen                        ),
    .S01_AXI_0_arsize       (S01_AXI_0_arsize                       ),
    .S01_AXI_0_arburst      (S01_AXI_0_arburst                      ),
    .S01_AXI_0_arcache      (S01_AXI_0_arcache                      ),
    .S01_AXI_0_arqos        (S01_AXI_0_arqos                        ),
//  .S01_AXI_0_arregion     (S01_AXI_0_arregion                     ),//no
    .S01_AXI_0_arprot       (S01_AXI_0_arprot                       ),
    .S01_AXI_0_arlock       (S01_AXI_0_arlock                       ),
    .S01_AXI_0_rready       (S01_AXI_0_rready                       ),
    .S01_AXI_0_rvalid       (S01_AXI_0_rvalid                       ),
    .S01_AXI_0_rdata        (S01_AXI_0_rdata                        ),
    .S01_AXI_0_rlast        (S01_AXI_0_rlast                        ),
    .S01_AXI_0_rresp        (S01_AXI_0_rresp                        ),
    .S01_AXI_0_awready      (S01_AXI_0_awready                      ),
    .S01_AXI_0_awvalid      (S01_AXI_0_awvalid                      ),
    .S01_AXI_0_awaddr       (S01_AXI_0_awaddr                       ),
    .S01_AXI_0_awlen        (S01_AXI_0_awlen                        ),
    .S01_AXI_0_awsize       (S01_AXI_0_awsize                       ),
    .S01_AXI_0_awburst      (S01_AXI_0_awburst                      ),
    .S01_AXI_0_awcache      (S01_AXI_0_awcache                      ),
    .S01_AXI_0_awqos        (S01_AXI_0_awqos                        ),
//  .S01_AXI_0_awregion     (S01_AXI_0_awregion                     ),//no
    .S01_AXI_0_awprot       (S01_AXI_0_awprot                       ),
    .S01_AXI_0_awlock       (S01_AXI_0_awlock                       ),
    .S01_AXI_0_wready       (S01_AXI_0_wready                       ),
    .S01_AXI_0_wvalid       (S01_AXI_0_wvalid                       ),
    .S01_AXI_0_wdata        (S01_AXI_0_wdata                        ),
    .S01_AXI_0_wstrb        (S01_AXI_0_wstrb                        ),
    .S01_AXI_0_wlast        (S01_AXI_0_wlast                        ),
    .S01_AXI_0_bready       (S01_AXI_0_bready                       ),
    .S01_AXI_0_bvalid       (S01_AXI_0_bvalid                       ),
    .S01_AXI_0_bresp        (S01_AXI_0_bresp                        ),
    //
    .S02_AXI_0_arid         (S02_AXI_0_arid                         ),//i
    .S02_AXI_0_awid         (S02_AXI_0_awid                         ),//i
    .S02_AXI_0_rid          (S02_AXI_0_rid                          ),//o
    .S02_AXI_0_bid          (S02_AXI_0_bid                          ),//o
    .S02_AXI_0_arready      (S02_AXI_0_arready                      ),
    .S02_AXI_0_arvalid      (S02_AXI_0_arvalid                      ),
    .S02_AXI_0_araddr       (S02_AXI_0_araddr                       ),
    .S02_AXI_0_arlen        (S02_AXI_0_arlen                        ),
    .S02_AXI_0_arsize       (S02_AXI_0_arsize                       ),
    .S02_AXI_0_arburst      (S02_AXI_0_arburst                      ),
    .S02_AXI_0_arcache      (S02_AXI_0_arcache                      ),
    .S02_AXI_0_arqos        (S02_AXI_0_arqos                        ),
    .S02_AXI_0_arregion     (S02_AXI_0_arregion                     ),
    .S02_AXI_0_arprot       (S02_AXI_0_arprot                       ),
    .S02_AXI_0_arlock       (S02_AXI_0_arlock                       ),
    .S02_AXI_0_rready       (S02_AXI_0_rready                       ),
    .S02_AXI_0_rvalid       (S02_AXI_0_rvalid                       ),
    .S02_AXI_0_rdata        (S02_AXI_0_rdata                        ),
    .S02_AXI_0_rlast        (S02_AXI_0_rlast                        ),
    .S02_AXI_0_rresp        (S02_AXI_0_rresp                        ),
    .S02_AXI_0_awready      (S02_AXI_0_awready                      ),
    .S02_AXI_0_awvalid      (S02_AXI_0_awvalid                      ),
    .S02_AXI_0_awaddr       (S02_AXI_0_awaddr                       ),
    .S02_AXI_0_awlen        (S02_AXI_0_awlen                        ),
    .S02_AXI_0_awsize       (S02_AXI_0_awsize                       ),
    .S02_AXI_0_awburst      (S02_AXI_0_awburst                      ),
    .S02_AXI_0_awcache      (S02_AXI_0_awcache                      ),
    .S02_AXI_0_awqos        (S02_AXI_0_awqos                        ),
    .S02_AXI_0_awregion     (S02_AXI_0_awregion                     ),
    .S02_AXI_0_awprot       (S02_AXI_0_awprot                       ),
    .S02_AXI_0_awlock       (S02_AXI_0_awlock                       ),
    .S02_AXI_0_wready       (S02_AXI_0_wready                       ),
    .S02_AXI_0_wvalid       (S02_AXI_0_wvalid                       ),
    .S02_AXI_0_wdata        (S02_AXI_0_wdata                        ),
    .S02_AXI_0_wstrb        (S02_AXI_0_wstrb                        ),
    .S02_AXI_0_wlast        (S02_AXI_0_wlast                        ),
    .S02_AXI_0_bready       (S02_AXI_0_bready                       ),
    .S02_AXI_0_bvalid       (S02_AXI_0_bvalid                       ),
    .S02_AXI_0_bresp        (S02_AXI_0_bresp                        ),
    //
    .S03_AXI_0_arid         (S03_AXI_0_arid                         ),//i
    .S03_AXI_0_awid         (S03_AXI_0_awid                         ),//i
    .S03_AXI_0_rid          (S03_AXI_0_rid                          ),//o
    .S03_AXI_0_bid          (S03_AXI_0_bid                          ),//o
    .S03_AXI_0_arready      (S03_AXI_0_arready                      ),
    .S03_AXI_0_arvalid      (S03_AXI_0_arvalid                      ),
    .S03_AXI_0_araddr       (S03_AXI_0_araddr                       ),
    .S03_AXI_0_arlen        (S03_AXI_0_arlen                        ),
    .S03_AXI_0_arsize       (S03_AXI_0_arsize                       ),
    .S03_AXI_0_arburst      (S03_AXI_0_arburst                      ),
    .S03_AXI_0_arcache      (S03_AXI_0_arcache                      ),
    .S03_AXI_0_arqos        (S03_AXI_0_arqos                        ),
    .S03_AXI_0_arregion     (S03_AXI_0_arregion                     ),
    .S03_AXI_0_arprot       (S03_AXI_0_arprot                       ),
    .S03_AXI_0_arlock       (S03_AXI_0_arlock                       ),
    .S03_AXI_0_rready       (S03_AXI_0_rready                       ),
    .S03_AXI_0_rvalid       (S03_AXI_0_rvalid                       ),
    .S03_AXI_0_rdata        (S03_AXI_0_rdata                        ),
    .S03_AXI_0_rlast        (S03_AXI_0_rlast                        ),
    .S03_AXI_0_rresp        (S03_AXI_0_rresp                        ),
    .S03_AXI_0_awready      (S03_AXI_0_awready                      ),
    .S03_AXI_0_awvalid      (S03_AXI_0_awvalid                      ),
    .S03_AXI_0_awaddr       (S03_AXI_0_awaddr                       ),
    .S03_AXI_0_awlen        (S03_AXI_0_awlen                        ),
    .S03_AXI_0_awsize       (S03_AXI_0_awsize                       ),
    .S03_AXI_0_awburst      (S03_AXI_0_awburst                      ),
    .S03_AXI_0_awcache      (S03_AXI_0_awcache                      ),
    .S03_AXI_0_awqos        (S03_AXI_0_awqos                        ),
    .S03_AXI_0_awregion     (S03_AXI_0_awregion                     ),
    .S03_AXI_0_awprot       (S03_AXI_0_awprot                       ),
    .S03_AXI_0_awlock       (S03_AXI_0_awlock                       ),
    .S03_AXI_0_wready       (S03_AXI_0_wready                       ),
    .S03_AXI_0_wvalid       (S03_AXI_0_wvalid                       ),
    .S03_AXI_0_wdata        (S03_AXI_0_wdata                        ),
    .S03_AXI_0_wstrb        (S03_AXI_0_wstrb                        ),
    .S03_AXI_0_wlast        (S03_AXI_0_wlast                        ),
    .S03_AXI_0_bready       (S03_AXI_0_bready                       ),
    .S03_AXI_0_bvalid       (S03_AXI_0_bvalid                       ),
    .S03_AXI_0_bresp        (S03_AXI_0_bresp                        ),
    //
    .S04_AXI_0_arid         (S04_AXI_0_arid                         ),//i
    .S04_AXI_0_awid         (S04_AXI_0_awid                         ),//i
    .S04_AXI_0_rid          (S04_AXI_0_rid                          ),//o
    .S04_AXI_0_bid          (S04_AXI_0_bid                          ),//o
    .S04_AXI_0_arready      (S04_AXI_0_arready                      ),
    .S04_AXI_0_arvalid      (S04_AXI_0_arvalid                      ),
    .S04_AXI_0_araddr       (S04_AXI_0_araddr                       ),
    .S04_AXI_0_arlen        (S04_AXI_0_arlen                        ),
    .S04_AXI_0_arsize       (S04_AXI_0_arsize                       ),
    .S04_AXI_0_arburst      (S04_AXI_0_arburst                      ),
    .S04_AXI_0_arcache      (S04_AXI_0_arcache                      ),
    .S04_AXI_0_arqos        (S04_AXI_0_arqos                        ),
    .S04_AXI_0_arregion     (S04_AXI_0_arregion                     ),
    .S04_AXI_0_arprot       (S04_AXI_0_arprot                       ),
    .S04_AXI_0_arlock       (S04_AXI_0_arlock                       ),
    .S04_AXI_0_rready       (S04_AXI_0_rready                       ),
    .S04_AXI_0_rvalid       (S04_AXI_0_rvalid                       ),
    .S04_AXI_0_rdata        (S04_AXI_0_rdata                        ),
    .S04_AXI_0_rlast        (S04_AXI_0_rlast                        ),
    .S04_AXI_0_rresp        (S04_AXI_0_rresp                        ),
    .S04_AXI_0_awready      (S04_AXI_0_awready                      ),
    .S04_AXI_0_awvalid      (S04_AXI_0_awvalid                      ),
    .S04_AXI_0_awaddr       (S04_AXI_0_awaddr                       ),
    .S04_AXI_0_awlen        (S04_AXI_0_awlen                        ),
    .S04_AXI_0_awsize       (S04_AXI_0_awsize                       ),
    .S04_AXI_0_awburst      (S04_AXI_0_awburst                      ),
    .S04_AXI_0_awcache      (S04_AXI_0_awcache                      ),
    .S04_AXI_0_awqos        (S04_AXI_0_awqos                        ),
    .S04_AXI_0_awregion     (S04_AXI_0_awregion                     ),
    .S04_AXI_0_awprot       (S04_AXI_0_awprot                       ),
    .S04_AXI_0_awlock       (S04_AXI_0_awlock                       ),
    .S04_AXI_0_wready       (S04_AXI_0_wready                       ),
    .S04_AXI_0_wvalid       (S04_AXI_0_wvalid                       ),
    .S04_AXI_0_wdata        (S04_AXI_0_wdata                        ),
    .S04_AXI_0_wstrb        (S04_AXI_0_wstrb                        ),
    .S04_AXI_0_wlast        (S04_AXI_0_wlast                        ),
    .S04_AXI_0_bready       (S04_AXI_0_bready                       ),
    .S04_AXI_0_bvalid       (S04_AXI_0_bvalid                       ),
    .S04_AXI_0_bresp        (S04_AXI_0_bresp                        ) 
);
`else
opu_axi_bypass
#(.MID(MID),
  .SID(SID))
u0_bypass_m4s5
(
    .M00_ACLK_0             (M00_ACLK_0                             ),
    .M00_ARESETN_0          (M00_ARESETN_0                          ),
    .M00_AXI_0_arready      (M00_AXI_0_arready                      ),
    .M00_AXI_0_arvalid      (M00_AXI_0_arvalid                      ),
    .M00_AXI_0_araddr       (M00_AXI_0_araddr                       ),
    .M00_AXI_0_arlen        (M00_AXI_0_arlen                        ),
    .M00_AXI_0_arsize       (M00_AXI_0_arsize                       ),
    .M00_AXI_0_arburst      (M00_AXI_0_arburst                      ),
    .M00_AXI_0_arid         (M00_AXI_0_arid                         ),
    .M00_AXI_0_arcache      (M00_AXI_0_arcache                      ),
    .M00_AXI_0_arqos        (M00_AXI_0_arqos                        ),
    .M00_AXI_0_arregion     (M00_AXI_0_arregion                     ),
    .M00_AXI_0_arprot       (M00_AXI_0_arprot                       ),
    .M00_AXI_0_arlock       (M00_AXI_0_arlock                       ),
    .M00_AXI_0_rready       (M00_AXI_0_rready                       ),
    .M00_AXI_0_rvalid       (M00_AXI_0_rvalid                       ),
    .M00_AXI_0_rdata        (M00_AXI_0_rdata                        ),
    .M00_AXI_0_rid          (M00_AXI_0_rid                          ),
    .M00_AXI_0_rlast        (M00_AXI_0_rlast                        ),
    .M00_AXI_0_rresp        (M00_AXI_0_rresp                        ),
    .M00_AXI_0_awready      (M00_AXI_0_awready                      ),
    .M00_AXI_0_awvalid      (M00_AXI_0_awvalid                      ),
    .M00_AXI_0_awaddr       (M00_AXI_0_awaddr                       ),
    .M00_AXI_0_awlen        (M00_AXI_0_awlen                        ),
    .M00_AXI_0_awsize       (M00_AXI_0_awsize                       ),
    .M00_AXI_0_awburst      (M00_AXI_0_awburst                      ),
    .M00_AXI_0_awid         (M00_AXI_0_awid                         ),
    .M00_AXI_0_awcache      (M00_AXI_0_awcache                      ),
    .M00_AXI_0_awqos        (M00_AXI_0_awqos                        ),
    .M00_AXI_0_awregion     (M00_AXI_0_awregion                     ),
    .M00_AXI_0_awprot       (M00_AXI_0_awprot                       ),
    .M00_AXI_0_awlock       (M00_AXI_0_awlock                       ),
    .M00_AXI_0_wready       (M00_AXI_0_wready                       ),
    .M00_AXI_0_wvalid       (M00_AXI_0_wvalid                       ),
    .M00_AXI_0_wdata        (M00_AXI_0_wdata                        ),
    .M00_AXI_0_wstrb        (M00_AXI_0_wstrb                        ),
    .M00_AXI_0_wlast        (M00_AXI_0_wlast                        ),
    .M00_AXI_0_bready       (M00_AXI_0_bready                       ),
    .M00_AXI_0_bvalid       (M00_AXI_0_bvalid                       ),
    .M00_AXI_0_bid          (M00_AXI_0_bid                          ),
    .M00_AXI_0_bresp        (M00_AXI_0_bresp                        ),
    //
    .M01_ACLK_0             (M01_ACLK_0                             ),
    .M01_ARESETN_0          (M01_ARESETN_0                          ),
    .M01_AXI_0_arready      (M01_AXI_0_arready                      ),
    .M01_AXI_0_arvalid      (M01_AXI_0_arvalid                      ),
    .M01_AXI_0_araddr       (M01_AXI_0_araddr                       ),
    .M01_AXI_0_arlen        (M01_AXI_0_arlen                        ),
    .M01_AXI_0_arsize       (M01_AXI_0_arsize                       ),
    .M01_AXI_0_arburst      (M01_AXI_0_arburst                      ),
    .M01_AXI_0_arid         (M01_AXI_0_arid                         ),
    .M01_AXI_0_arcache      (M01_AXI_0_arcache                      ),
    .M01_AXI_0_arqos        (M01_AXI_0_arqos                        ),
    .M01_AXI_0_arregion     (M01_AXI_0_arregion                     ),
    .M01_AXI_0_arprot       (M01_AXI_0_arprot                       ),
    .M01_AXI_0_arlock       (M01_AXI_0_arlock                       ),
    .M01_AXI_0_rready       (M01_AXI_0_rready                       ),
    .M01_AXI_0_rvalid       (M01_AXI_0_rvalid                       ),
    .M01_AXI_0_rdata        (M01_AXI_0_rdata                        ),
    .M01_AXI_0_rid          (M01_AXI_0_rid                          ),
    .M01_AXI_0_rlast        (M01_AXI_0_rlast                        ),
    .M01_AXI_0_rresp        (M01_AXI_0_rresp                        ),
    .M01_AXI_0_awready      (M01_AXI_0_awready                      ),
    .M01_AXI_0_awvalid      (M01_AXI_0_awvalid                      ),
    .M01_AXI_0_awaddr       (M01_AXI_0_awaddr                       ),
    .M01_AXI_0_awlen        (M01_AXI_0_awlen                        ),
    .M01_AXI_0_awsize       (M01_AXI_0_awsize                       ),
    .M01_AXI_0_awburst      (M01_AXI_0_awburst                      ),
    .M01_AXI_0_awid         (M01_AXI_0_awid                         ),
    .M01_AXI_0_awcache      (M01_AXI_0_awcache                      ),
    .M01_AXI_0_awqos        (M01_AXI_0_awqos                        ),
    .M01_AXI_0_awregion     (M01_AXI_0_awregion                     ),
    .M01_AXI_0_awprot       (M01_AXI_0_awprot                       ),
    .M01_AXI_0_awlock       (M01_AXI_0_awlock                       ),
    .M01_AXI_0_wready       (M01_AXI_0_wready                       ),
    .M01_AXI_0_wvalid       (M01_AXI_0_wvalid                       ),
    .M01_AXI_0_wdata        (M01_AXI_0_wdata                        ),
    .M01_AXI_0_wstrb        (M01_AXI_0_wstrb                        ),
    .M01_AXI_0_wlast        (M01_AXI_0_wlast                        ),
    .M01_AXI_0_bready       (M01_AXI_0_bready                       ),
    .M01_AXI_0_bvalid       (M01_AXI_0_bvalid                       ),
    .M01_AXI_0_bid          (M01_AXI_0_bid                          ),
    .M01_AXI_0_bresp        (M01_AXI_0_bresp                        ),
    //
    .M02_ACLK_0             (M02_ACLK_0                             ),
    .M02_ARESETN_0          (M02_ARESETN_0                          ),
    .M02_AXI_0_arready      (M02_AXI_0_arready                      ),
    .M02_AXI_0_arvalid      (M02_AXI_0_arvalid                      ),
    .M02_AXI_0_araddr       (M02_AXI_0_araddr                       ),
    .M02_AXI_0_arlen        (M02_AXI_0_arlen                        ),
    .M02_AXI_0_arsize       (M02_AXI_0_arsize                       ),
    .M02_AXI_0_arburst      (M02_AXI_0_arburst                      ),
    .M02_AXI_0_arid         (M02_AXI_0_arid                         ),
    .M02_AXI_0_arcache      (M02_AXI_0_arcache                      ),
    .M02_AXI_0_arqos        (M02_AXI_0_arqos                        ),
    .M02_AXI_0_arregion     (M02_AXI_0_arregion                     ),
    .M02_AXI_0_arprot       (M02_AXI_0_arprot                       ),
    .M02_AXI_0_arlock       (M02_AXI_0_arlock                       ),
    .M02_AXI_0_rready       (M02_AXI_0_rready                       ),
    .M02_AXI_0_rvalid       (M02_AXI_0_rvalid                       ),
    .M02_AXI_0_rdata        (M02_AXI_0_rdata                        ),
    .M02_AXI_0_rid          (M02_AXI_0_rid                          ),
    .M02_AXI_0_rlast        (M02_AXI_0_rlast                        ),
    .M02_AXI_0_rresp        (M02_AXI_0_rresp                        ),
    .M02_AXI_0_awready      (M02_AXI_0_awready                      ),
    .M02_AXI_0_awvalid      (M02_AXI_0_awvalid                      ),
    .M02_AXI_0_awaddr       (M02_AXI_0_awaddr                       ),
    .M02_AXI_0_awlen        (M02_AXI_0_awlen                        ),
    .M02_AXI_0_awsize       (M02_AXI_0_awsize                       ),
    .M02_AXI_0_awburst      (M02_AXI_0_awburst                      ),
    .M02_AXI_0_awid         (M02_AXI_0_awid                         ),
    .M02_AXI_0_awcache      (M02_AXI_0_awcache                      ),
    .M02_AXI_0_awqos        (M02_AXI_0_awqos                        ),
    .M02_AXI_0_awregion     (M02_AXI_0_awregion                     ),
    .M02_AXI_0_awprot       (M02_AXI_0_awprot                       ),
    .M02_AXI_0_awlock       (M02_AXI_0_awlock                       ),
    .M02_AXI_0_wready       (M02_AXI_0_wready                       ),
    .M02_AXI_0_wvalid       (M02_AXI_0_wvalid                       ),
    .M02_AXI_0_wdata        (M02_AXI_0_wdata                        ),
    .M02_AXI_0_wstrb        (M02_AXI_0_wstrb                        ),
    .M02_AXI_0_wlast        (M02_AXI_0_wlast                        ),
    .M02_AXI_0_bready       (M02_AXI_0_bready                       ),
    .M02_AXI_0_bvalid       (M02_AXI_0_bvalid                       ),
    .M02_AXI_0_bid          (M02_AXI_0_bid                          ),
    .M02_AXI_0_bresp        (M02_AXI_0_bresp                        ),
    //
    .M03_ACLK_0             (M03_ACLK_0                             ),
    .M03_ARESETN_0          (M03_ARESETN_0                          ),
    .M03_AXI_0_arready      (M03_AXI_0_arready                      ),
    .M03_AXI_0_arvalid      (M03_AXI_0_arvalid                      ),
    .M03_AXI_0_araddr       (M03_AXI_0_araddr                       ),
    .M03_AXI_0_arlen        (M03_AXI_0_arlen                        ),
    .M03_AXI_0_arsize       (M03_AXI_0_arsize                       ),
    .M03_AXI_0_arburst      (M03_AXI_0_arburst                      ),
    .M03_AXI_0_arid         (M03_AXI_0_arid                         ),
    .M03_AXI_0_arcache      (M03_AXI_0_arcache                      ),
    .M03_AXI_0_arqos        (M03_AXI_0_arqos                        ),
    .M03_AXI_0_arregion     (M03_AXI_0_arregion                     ),
    .M03_AXI_0_arprot       (M03_AXI_0_arprot                       ),
    .M03_AXI_0_arlock       (M03_AXI_0_arlock                       ),
    .M03_AXI_0_rready       (M03_AXI_0_rready                       ),
    .M03_AXI_0_rvalid       (M03_AXI_0_rvalid                       ),
    .M03_AXI_0_rdata        (M03_AXI_0_rdata                        ),
    .M03_AXI_0_rid          (M03_AXI_0_rid                          ),
    .M03_AXI_0_rlast        (M03_AXI_0_rlast                        ),
    .M03_AXI_0_rresp        (M03_AXI_0_rresp                        ),
    .M03_AXI_0_awready      (M03_AXI_0_awready                      ),
    .M03_AXI_0_awvalid      (M03_AXI_0_awvalid                      ),
    .M03_AXI_0_awaddr       (M03_AXI_0_awaddr                       ),
    .M03_AXI_0_awlen        (M03_AXI_0_awlen                        ),
    .M03_AXI_0_awsize       (M03_AXI_0_awsize                       ),
    .M03_AXI_0_awburst      (M03_AXI_0_awburst                      ),
    .M03_AXI_0_awid         (M03_AXI_0_awid                         ),
    .M03_AXI_0_awcache      (M03_AXI_0_awcache                      ),
    .M03_AXI_0_awqos        (M03_AXI_0_awqos                        ),
    .M03_AXI_0_awregion     (M03_AXI_0_awregion                     ),
    .M03_AXI_0_awprot       (M03_AXI_0_awprot                       ),
    .M03_AXI_0_awlock       (M03_AXI_0_awlock                       ),
    .M03_AXI_0_wready       (M03_AXI_0_wready                       ),
    .M03_AXI_0_wvalid       (M03_AXI_0_wvalid                       ),
    .M03_AXI_0_wdata        (M03_AXI_0_wdata                        ),
    .M03_AXI_0_wstrb        (M03_AXI_0_wstrb                        ),
    .M03_AXI_0_wlast        (M03_AXI_0_wlast                        ),
    .M03_AXI_0_bready       (M03_AXI_0_bready                       ),
    .M03_AXI_0_bvalid       (M03_AXI_0_bvalid                       ),
    .M03_AXI_0_bid          (M03_AXI_0_bid                          ),
    .M03_AXI_0_bresp        (M03_AXI_0_bresp                        ),
    //------------------------------------------
    .S00_ACLK_0             (S00_ACLK_0                             ),
    .S00_ARESETN_0          (S00_ARESETN_0                          ),
    .S00_AXI_0_arready      (S00_AXI_0_arready                      ),
    .S00_AXI_0_arvalid      (S00_AXI_0_arvalid                      ),
    .S00_AXI_0_araddr       (S00_AXI_0_araddr                       ),
    .S00_AXI_0_arlen        (S00_AXI_0_arlen                        ),
    .S00_AXI_0_arsize       (S00_AXI_0_arsize                       ),
    .S00_AXI_0_arburst      (S00_AXI_0_arburst                      ),
    .S00_AXI_0_arid         (S00_AXI_0_arid                         ),
    .S00_AXI_0_arcache      (S00_AXI_0_arcache                      ),
    .S00_AXI_0_arqos        (S00_AXI_0_arqos                        ),
    .S00_AXI_0_arregion     (S00_AXI_0_arregion                     ),
    .S00_AXI_0_arprot       (S00_AXI_0_arprot                       ),
    .S00_AXI_0_arlock       (S00_AXI_0_arlock                       ),
    .S00_AXI_0_rready       (S00_AXI_0_rready                       ),
    .S00_AXI_0_rvalid       (S00_AXI_0_rvalid                       ),
    .S00_AXI_0_rdata        (S00_AXI_0_rdata                        ),
    .S00_AXI_0_rlast        (S00_AXI_0_rlast                        ),
    .S00_AXI_0_rid          (S00_AXI_0_rid                          ),
    .S00_AXI_0_rresp        (S00_AXI_0_rresp                        ),
    .S00_AXI_0_awready      (S00_AXI_0_awready                      ),
    .S00_AXI_0_awvalid      (S00_AXI_0_awvalid                      ),
    .S00_AXI_0_awaddr       (S00_AXI_0_awaddr                       ),
    .S00_AXI_0_awlen        (S00_AXI_0_awlen                        ),
    .S00_AXI_0_awsize       (S00_AXI_0_awsize                       ),
    .S00_AXI_0_awburst      (S00_AXI_0_awburst                      ),
    .S00_AXI_0_awid         (S00_AXI_0_awid                         ),
    .S00_AXI_0_awcache      (S00_AXI_0_awcache                      ),
    .S00_AXI_0_awqos        (S00_AXI_0_awqos                        ),
    .S00_AXI_0_awregion     (S00_AXI_0_awregion                     ),
    .S00_AXI_0_awprot       (S00_AXI_0_awprot                       ),
    .S00_AXI_0_awlock       (S00_AXI_0_awlock                       ),
    .S00_AXI_0_wready       (S00_AXI_0_wready                       ),
    .S00_AXI_0_wvalid       (S00_AXI_0_wvalid                       ),
    .S00_AXI_0_wdata        (S00_AXI_0_wdata                        ),
    .S00_AXI_0_wstrb        (S00_AXI_0_wstrb                        ),
    .S00_AXI_0_wlast        (S00_AXI_0_wlast                        ),
    .S00_AXI_0_bready       (S00_AXI_0_bready                       ),
    .S00_AXI_0_bvalid       (S00_AXI_0_bvalid                       ),
    .S00_AXI_0_bid          (S00_AXI_0_bid                          ),
    .S00_AXI_0_bresp        (S00_AXI_0_bresp                        ),
    //
    .S01_AXI_0_arready      (S01_AXI_0_arready                      ),
    .S01_AXI_0_arvalid      (S01_AXI_0_arvalid                      ),
    .S01_AXI_0_araddr       (S01_AXI_0_araddr                       ),
    .S01_AXI_0_arlen        (S01_AXI_0_arlen                        ),
    .S01_AXI_0_arsize       (S01_AXI_0_arsize                       ),
    .S01_AXI_0_arburst      (S01_AXI_0_arburst                      ),
    .S01_AXI_0_arid         (S01_AXI_0_arid                         ),
    .S01_AXI_0_arcache      (S01_AXI_0_arcache                      ),
    .S01_AXI_0_arqos        (S01_AXI_0_arqos                        ),
    .S01_AXI_0_arregion     (S01_AXI_0_arregion                     ),
    .S01_AXI_0_arprot       (S01_AXI_0_arprot                       ),
    .S01_AXI_0_arlock       (S01_AXI_0_arlock                       ),
    .S01_AXI_0_rready       (S01_AXI_0_rready                       ),
    .S01_AXI_0_rvalid       (S01_AXI_0_rvalid                       ),
    .S01_AXI_0_rdata        (S01_AXI_0_rdata                        ),
    .S01_AXI_0_rlast        (S01_AXI_0_rlast                        ),
    .S01_AXI_0_rid          (S01_AXI_0_rid_bus                      ),
    .S01_AXI_0_rresp        (S01_AXI_0_rresp                        ),
    .S01_AXI_0_awready      (S01_AXI_0_awready                      ),
    .S01_AXI_0_awvalid      (S01_AXI_0_awvalid                      ),
    .S01_AXI_0_awaddr       (S01_AXI_0_awaddr                       ),
    .S01_AXI_0_awlen        (S01_AXI_0_awlen                        ),
    .S01_AXI_0_awsize       (S01_AXI_0_awsize                       ),
    .S01_AXI_0_awburst      (S01_AXI_0_awburst                      ),
    .S01_AXI_0_awid         (S01_AXI_0_awid                         ),
    .S01_AXI_0_awcache      (S01_AXI_0_awcache                      ),
    .S01_AXI_0_awqos        (S01_AXI_0_awqos                        ),
    .S01_AXI_0_awregion     (S01_AXI_0_awregion                     ),
    .S01_AXI_0_awprot       (S01_AXI_0_awprot                       ),
    .S01_AXI_0_awlock       (S01_AXI_0_awlock                       ),
    .S01_AXI_0_wready       (S01_AXI_0_wready                       ),
    .S01_AXI_0_wvalid       (S01_AXI_0_wvalid                       ),
    .S01_AXI_0_wdata        (S01_AXI_0_wdata                        ),
    .S01_AXI_0_wstrb        (S01_AXI_0_wstrb                        ),
    .S01_AXI_0_wlast        (S01_AXI_0_wlast                        ),
    .S01_AXI_0_bready       (S01_AXI_0_bready                       ),
    .S01_AXI_0_bvalid       (S01_AXI_0_bvalid                       ),
    .S01_AXI_0_bid          (S01_AXI_0_bid_bus                      ),
    .S01_AXI_0_bresp        (S01_AXI_0_bresp                        ),
    //
    .S02_AXI_0_arready      (S02_AXI_0_arready                      ),
    .S02_AXI_0_arvalid      (S02_AXI_0_arvalid                      ),
    .S02_AXI_0_araddr       (S02_AXI_0_araddr                       ),
    .S02_AXI_0_arlen        (S02_AXI_0_arlen                        ),
    .S02_AXI_0_arsize       (S02_AXI_0_arsize                       ),
    .S02_AXI_0_arburst      (S02_AXI_0_arburst                      ),
    .S02_AXI_0_arid         (S02_AXI_0_arid                         ),
    .S02_AXI_0_arcache      (S02_AXI_0_arcache                      ),
    .S02_AXI_0_arqos        (S02_AXI_0_arqos                        ),
    .S02_AXI_0_arregion     (S02_AXI_0_arregion                     ),
    .S02_AXI_0_arprot       (S02_AXI_0_arprot                       ),
    .S02_AXI_0_arlock       (S02_AXI_0_arlock                       ),
    .S02_AXI_0_rready       (S02_AXI_0_rready                       ),
    .S02_AXI_0_rvalid       (S02_AXI_0_rvalid                       ),
    .S02_AXI_0_rdata        (S02_AXI_0_rdata                        ),
    .S02_AXI_0_rlast        (S02_AXI_0_rlast                        ),
    .S02_AXI_0_rid          (S02_AXI_0_rid                          ),
    .S02_AXI_0_rresp        (S02_AXI_0_rresp                        ),
    .S02_AXI_0_awready      (S02_AXI_0_awready                      ),
    .S02_AXI_0_awvalid      (S02_AXI_0_awvalid                      ),
    .S02_AXI_0_awaddr       (S02_AXI_0_awaddr                       ),
    .S02_AXI_0_awlen        (S02_AXI_0_awlen                        ),
    .S02_AXI_0_awsize       (S02_AXI_0_awsize                       ),
    .S02_AXI_0_awburst      (S02_AXI_0_awburst                      ),
    .S02_AXI_0_awid         (S02_AXI_0_awid                         ),
    .S02_AXI_0_awcache      (S02_AXI_0_awcache                      ),
    .S02_AXI_0_awqos        (S02_AXI_0_awqos                        ),
    .S02_AXI_0_awregion     (S02_AXI_0_awregion                     ),
    .S02_AXI_0_awprot       (S02_AXI_0_awprot                       ),
    .S02_AXI_0_awlock       (S02_AXI_0_awlock                       ),
    .S02_AXI_0_wready       (S02_AXI_0_wready                       ),
    .S02_AXI_0_wvalid       (S02_AXI_0_wvalid                       ),
    .S02_AXI_0_wdata        (S02_AXI_0_wdata                        ),
    .S02_AXI_0_wstrb        (S02_AXI_0_wstrb                        ),
    .S02_AXI_0_wlast        (S02_AXI_0_wlast                        ),
    .S02_AXI_0_bready       (S02_AXI_0_bready                       ),
    .S02_AXI_0_bvalid       (S02_AXI_0_bvalid                       ),
    .S02_AXI_0_bid          (S02_AXI_0_bid                          ),
    .S02_AXI_0_bresp        (S02_AXI_0_bresp                        ),
    //
    .S03_AXI_0_arready      (S03_AXI_0_arready                      ),
    .S03_AXI_0_arvalid      (S03_AXI_0_arvalid                      ),
    .S03_AXI_0_araddr       (S03_AXI_0_araddr                       ),
    .S03_AXI_0_arlen        (S03_AXI_0_arlen                        ),
    .S03_AXI_0_arsize       (S03_AXI_0_arsize                       ),
    .S03_AXI_0_arburst      (S03_AXI_0_arburst                      ),
    .S03_AXI_0_arid         (S03_AXI_0_arid                         ),
    .S03_AXI_0_arcache      (S03_AXI_0_arcache                      ),
    .S03_AXI_0_arqos        (S03_AXI_0_arqos                        ),
    .S03_AXI_0_arregion     (S03_AXI_0_arregion                     ),
    .S03_AXI_0_arprot       (S03_AXI_0_arprot                       ),
    .S03_AXI_0_arlock       (S03_AXI_0_arlock                       ),
    .S03_AXI_0_rready       (S03_AXI_0_rready                       ),
    .S03_AXI_0_rvalid       (S03_AXI_0_rvalid                       ),
    .S03_AXI_0_rdata        (S03_AXI_0_rdata                        ),
    .S03_AXI_0_rlast        (S03_AXI_0_rlast                        ),
    .S03_AXI_0_rid          (S03_AXI_0_rid                          ),
    .S03_AXI_0_rresp        (S03_AXI_0_rresp                        ),
    .S03_AXI_0_awready      (S03_AXI_0_awready                      ),
    .S03_AXI_0_awvalid      (S03_AXI_0_awvalid                      ),
    .S03_AXI_0_awaddr       (S03_AXI_0_awaddr                       ),
    .S03_AXI_0_awlen        (S03_AXI_0_awlen                        ),
    .S03_AXI_0_awsize       (S03_AXI_0_awsize                       ),
    .S03_AXI_0_awburst      (S03_AXI_0_awburst                      ),
    .S03_AXI_0_awid         (S03_AXI_0_awid                         ),
    .S03_AXI_0_awcache      (S03_AXI_0_awcache                      ),
    .S03_AXI_0_awqos        (S03_AXI_0_awqos                        ),
    .S03_AXI_0_awregion     (S03_AXI_0_awregion                     ),
    .S03_AXI_0_awprot       (S03_AXI_0_awprot                       ),
    .S03_AXI_0_awlock       (S03_AXI_0_awlock                       ),
    .S03_AXI_0_wready       (S03_AXI_0_wready                       ),
    .S03_AXI_0_wvalid       (S03_AXI_0_wvalid                       ),
    .S03_AXI_0_wdata        (S03_AXI_0_wdata                        ),
    .S03_AXI_0_wstrb        (S03_AXI_0_wstrb                        ),
    .S03_AXI_0_wlast        (S03_AXI_0_wlast                        ),
    .S03_AXI_0_bready       (S03_AXI_0_bready                       ),
    .S03_AXI_0_bvalid       (S03_AXI_0_bvalid                       ),
    .S03_AXI_0_bid          (S03_AXI_0_bid                          ),
    .S03_AXI_0_bresp        (S03_AXI_0_bresp                        ),
    //
    .S04_AXI_0_arready      (S04_AXI_0_arready                      ),
    .S04_AXI_0_arvalid      (S04_AXI_0_arvalid                      ),
    .S04_AXI_0_araddr       (S04_AXI_0_araddr                       ),
    .S04_AXI_0_arlen        (S04_AXI_0_arlen                        ),
    .S04_AXI_0_arsize       (S04_AXI_0_arsize                       ),
    .S04_AXI_0_arburst      (S04_AXI_0_arburst                      ),
    .S04_AXI_0_arid         (S04_AXI_0_arid                         ),
    .S04_AXI_0_arcache      (S04_AXI_0_arcache                      ),
    .S04_AXI_0_arqos        (S04_AXI_0_arqos                        ),
    .S04_AXI_0_arregion     (S04_AXI_0_arregion                     ),
    .S04_AXI_0_arprot       (S04_AXI_0_arprot                       ),
    .S04_AXI_0_arlock       (S04_AXI_0_arlock                       ),
    .S04_AXI_0_rready       (S04_AXI_0_rready                       ),
    .S04_AXI_0_rvalid       (S04_AXI_0_rvalid                       ),
    .S04_AXI_0_rdata        (S04_AXI_0_rdata                        ),
    .S04_AXI_0_rlast        (S04_AXI_0_rlast                        ),
    .S04_AXI_0_rid          (S04_AXI_0_rid                          ),
    .S04_AXI_0_rresp        (S04_AXI_0_rresp                        ),
    .S04_AXI_0_awready      (S04_AXI_0_awready                      ),
    .S04_AXI_0_awvalid      (S04_AXI_0_awvalid                      ),
    .S04_AXI_0_awaddr       (S04_AXI_0_awaddr                       ),
    .S04_AXI_0_awlen        (S04_AXI_0_awlen                        ),
    .S04_AXI_0_awsize       (S04_AXI_0_awsize                       ),
    .S04_AXI_0_awburst      (S04_AXI_0_awburst                      ),
    .S04_AXI_0_awid         (S04_AXI_0_awid                         ),
    .S04_AXI_0_awcache      (S04_AXI_0_awcache                      ),
    .S04_AXI_0_awqos        (S04_AXI_0_awqos                        ),
    .S04_AXI_0_awregion     (S04_AXI_0_awregion                     ),
    .S04_AXI_0_awprot       (S04_AXI_0_awprot                       ),
    .S04_AXI_0_awlock       (S04_AXI_0_awlock                       ),
    .S04_AXI_0_wready       (S04_AXI_0_wready                       ),
    .S04_AXI_0_wvalid       (S04_AXI_0_wvalid                       ),
    .S04_AXI_0_wdata        (S04_AXI_0_wdata                        ),
    .S04_AXI_0_wstrb        (S04_AXI_0_wstrb                        ),
    .S04_AXI_0_wlast        (S04_AXI_0_wlast                        ),
    .S04_AXI_0_bready       (S04_AXI_0_bready                       ),
    .S04_AXI_0_bvalid       (S04_AXI_0_bvalid                       ),
    .S04_AXI_0_bid          (S04_AXI_0_bid                          ),
    .S04_AXI_0_bresp        (S04_AXI_0_bresp                        )  
);
`endif//sim
`endif//4core


//---------------------------------------------------------------------------
//DDR4 example
//Read data:21 cycle
//---------------------------------------------------------------------------
wire [63:0] M00_AXI_0_awaddr_ddr =M00_AXI_0_awaddr-AXI_M00_ADDR     ;
wire [63:0] M00_AXI_0_araddr_ddr =M00_AXI_0_araddr-AXI_M00_ADDR     ;
`ifndef SIM_MIG
wire        c0_ddr4_ui_rst                                          ;
wire        c0_ddr4_ui_clk                                          ;
wire        c0_init_calib_complete                                  ;
assign      M00_ACLK_0   = c0_ddr4_ui_clk                           ;
assign      M00_ARESETN_0=~c0_ddr4_ui_rst                           ;
wire [7-1:0]M00_AXI_0_awid_mig                                      ;//i
wire [7-1:0]M00_AXI_0_arid_mig                                      ;//i
wire [7-1:0]M00_AXI_0_bid_mig                                       ;//o
wire [7-1:0]M00_AXI_0_rid_mig                                       ;//o
assign      M00_AXI_0_awid_mig ={{(7-MID){1'b0}},M00_AXI_0_awid}    ;
assign      M00_AXI_0_arid_mig ={{(7-MID){1'b0}},M00_AXI_0_arid}    ;
assign      M00_AXI_0_bid      = M00_AXI_0_bid_mig[MID-1:0]         ;                          
assign      M00_AXI_0_rid      = M00_AXI_0_rid_mig[MID-1:0]         ;
(*keep_hierarchy="yes"*)
c0_DDR4_mig MIG0
(
    .sys_rst                         (c0_sys_rst                    ),// input  wire          sys_rst
    .c0_sys_clk_p                    (c0_sys_clk_p                  ),// input  wire          c0_sys_clk_p
    .c0_sys_clk_n                    (c0_sys_clk_n                  ),// input  wire          c0_sys_clk_n
    .c0_init_calib_complete          (c0_init_calib_complete        ),// output wire          c0_init_calib_complete
    .c0_ddr4_ui_clk_sync_rst         (c0_ddr4_ui_rst                ),// output wire          c0_ddr4_ui_clk_sync_rst       
    .c0_ddr4_ui_clk                  (c0_ddr4_ui_clk                ),// output wire          c0_ddr4_ui_clk
    .c0_ddr4_interrupt               (                              ),// output wire          c0_ddr4_interrupt
    .dbg_bus                         (                              ),// output wire [511:0]  dbg_bus 
    .dbg_clk                         (                              ),// output wire          dbg_clk
    .c0_ddr4_act_n                   (c0_ddr4_act_n                 ),// output wire          c0_ddr4_act_n
    .c0_ddr4_adr                     (c0_ddr4_adr                   ),// output wire [16 : 0] c0_ddr4_adr   
    .c0_ddr4_ba                      (c0_ddr4_ba                    ),// output wire [1  : 0] c0_ddr4_ba   
    .c0_ddr4_bg                      (c0_ddr4_bg                    ),// output wire [1  : 0] c0_ddr4_bg  
    .c0_ddr4_cke                     (c0_ddr4_cke                   ),// output wire [0  : 0] c0_ddr4_cke  
    .c0_ddr4_odt                     (c0_ddr4_odt                   ),// output wire [0  : 0] c0_ddr4_odt
    .c0_ddr4_cs_n                    (c0_ddr4_cs_n                  ),// output wire [0  : 0] c0_ddr4_cs_n 
    .c0_ddr4_ck_t                    (c0_ddr4_ck_t                  ),// output wire [0  : 0] c0_ddr4_ck_t
    .c0_ddr4_ck_c                    (c0_ddr4_ck_c                  ),// output wire [0  : 0] c0_ddr4_ck_c
    .c0_ddr4_reset_n                 (c0_ddr4_reset_n               ),// output wire          c0_ddr4_reset_n
    .c0_ddr4_parity                  (c0_ddr4_parity                ),// output wire          c0_ddr4_parity
    .c0_ddr4_dq                      (c0_ddr4_dq                    ),// inout  wire [71 : 0] c0_ddr4_dq 
    .c0_ddr4_dqs_c                   (c0_ddr4_dqs_c                 ),// inout  wire [17 : 0] c0_ddr4_dqs_c
    .c0_ddr4_dqs_t                   (c0_ddr4_dqs_t                 ),// inout  wire [17 : 0] c0_ddr4_dqs_t
    .c0_ddr4_s_axi_ctrl_awvalid      (1'b0                          ),// input  wire          c0_ddr4_s_axi_ctrl_awvalid
    .c0_ddr4_s_axi_ctrl_awready      (                              ),// output wire          c0_ddr4_s_axi_ctrl_awready
    .c0_ddr4_s_axi_ctrl_awaddr       (32'b0                         ),// input  wire [31 : 0] c0_ddr4_s_axi_ctrl_awaddr 
    .c0_ddr4_s_axi_ctrl_wvalid       (1'b0                          ),// input  wire          c0_ddr4_s_axi_ctrl_wvalid 
    .c0_ddr4_s_axi_ctrl_wready       (                              ),// output wire          c0_ddr4_s_axi_ctrl_wready 
    .c0_ddr4_s_axi_ctrl_wdata        (32'b0                         ),// input  wire [31 : 0] c0_ddr4_s_axi_ctrl_wdata  
    .c0_ddr4_s_axi_ctrl_bvalid       (                              ),// output wire          c0_ddr4_s_axi_ctrl_bvalid 
    .c0_ddr4_s_axi_ctrl_bready       (1'b1                          ),// input  wire          c0_ddr4_s_axi_ctrl_bready 
    .c0_ddr4_s_axi_ctrl_bresp        (                              ),// output wire [1 : 0]  c0_ddr4_s_axi_ctrl_bresp  
    .c0_ddr4_s_axi_ctrl_arvalid      (1'b0                          ),// input  wire          c0_ddr4_s_axi_ctrl_arvalid
    .c0_ddr4_s_axi_ctrl_arready      (                              ),// output wire          c0_ddr4_s_axi_ctrl_arready
    .c0_ddr4_s_axi_ctrl_araddr       (32'b0                         ),// input  wire [31 : 0] c0_ddr4_s_axi_ctrl_araddr 
    .c0_ddr4_s_axi_ctrl_rvalid       (                              ),// output wire          c0_ddr4_s_axi_ctrl_rvalid 
    .c0_ddr4_s_axi_ctrl_rready       (1'b1                          ),// input  wire          c0_ddr4_s_axi_ctrl_rready 
    .c0_ddr4_s_axi_ctrl_rdata        (                              ),// output wire [31 : 0] c0_ddr4_s_axi_ctrl_rdata  
    .c0_ddr4_s_axi_ctrl_rresp        (                              ),// output wire [1  : 0] c0_ddr4_s_axi_ctrl_rresp  
    .c0_ddr4_aresetn                 (M00_ARESETN_0                 ),// input  wire          c0_ddr4_aresetn
    .c0_ddr4_s_axi_awid              (M00_AXI_0_awid_mig            ),// input  wire [3  : 0] c0_ddr4_s_axi_awid
    .c0_ddr4_s_axi_arid              (M00_AXI_0_arid_mig            ),// input  wire [3  : 0] c0_ddr4_s_axi_arid
    .c0_ddr4_s_axi_bid               (M00_AXI_0_bid_mig             ),// output wire [3  : 0] c0_ddr4_s_axi_bid 
    .c0_ddr4_s_axi_rid               (M00_AXI_0_rid_mig             ),// output wire [3  : 0] c0_ddr4_s_axi_rid 
    .c0_ddr4_s_axi_awaddr            (M00_AXI_0_awaddr_ddr[33:0]    ),// input  wire [33 : 0] c0_ddr4_s_axi_awaddr 
    .c0_ddr4_s_axi_araddr            (M00_AXI_0_araddr_ddr[33:0]    ),// input  wire [33 : 0] c0_ddr4_s_axi_araddr 
    .c0_ddr4_s_axi_awlock            (M00_AXI_0_awlock              ),// input  wire [0  : 0] c0_ddr4_s_axi_awlock 
    .c0_ddr4_s_axi_awcache           (M00_AXI_0_awcache             ),// input  wire [3  : 0] c0_ddr4_s_axi_awcache
    .c0_ddr4_s_axi_awprot            (M00_AXI_0_awprot              ),// input  wire [2  : 0] c0_ddr4_s_axi_awprot 
    .c0_ddr4_s_axi_awqos             (M00_AXI_0_awqos               ),// input  wire [3  : 0] c0_ddr4_s_axi_awqos     
    .c0_ddr4_s_axi_awlen             (M00_AXI_0_awlen               ),// input  wire [7  : 0] c0_ddr4_s_axi_awlen  
    .c0_ddr4_s_axi_awsize            (M00_AXI_0_awsize              ),// input  wire [2  : 0] c0_ddr4_s_axi_awsize 
    .c0_ddr4_s_axi_awburst           (M00_AXI_0_awburst             ),// input  wire [1  : 0] c0_ddr4_s_axi_awburst
    .c0_ddr4_s_axi_awvalid           (M00_AXI_0_awvalid             ),// input  wire          c0_ddr4_s_axi_awvalid
    .c0_ddr4_s_axi_awready           (M00_AXI_0_awready             ),// output wire          c0_ddr4_s_axi_awready
    .c0_ddr4_s_axi_wdata             (M00_AXI_0_wdata               ),// input  wire [511: 0] c0_ddr4_s_axi_wdata 
    .c0_ddr4_s_axi_wstrb             (M00_AXI_0_wstrb               ),// input  wire [63 : 0] c0_ddr4_s_axi_wstrb 
    .c0_ddr4_s_axi_wlast             (M00_AXI_0_wlast               ),// input  wire          c0_ddr4_s_axi_wlast 
    .c0_ddr4_s_axi_wvalid            (M00_AXI_0_wvalid              ),// input  wire          c0_ddr4_s_axi_wvalid
    .c0_ddr4_s_axi_wready            (M00_AXI_0_wready              ),// output wire          c0_ddr4_s_axi_wready
    .c0_ddr4_s_axi_bresp             (M00_AXI_0_bresp               ),// output wire [1  : 0] c0_ddr4_s_axi_bresp 
    .c0_ddr4_s_axi_bvalid            (M00_AXI_0_bvalid              ),// output wire          c0_ddr4_s_axi_bvalid
    .c0_ddr4_s_axi_bready            (M00_AXI_0_bready              ),// input  wire          c0_ddr4_s_axi_bready
    .c0_ddr4_s_axi_arlock            (M00_AXI_0_arlock              ),// input  wire [0  : 0] c0_ddr4_s_axi_arlock  
    .c0_ddr4_s_axi_arcache           (M00_AXI_0_arcache             ),// input  wire [3  : 0] c0_ddr4_s_axi_arcache  
    .c0_ddr4_s_axi_arprot            (M00_AXI_0_arprot              ),// input  wire [2  : 0] c0_ddr4_s_axi_arprot  
    .c0_ddr4_s_axi_arqos             (M00_AXI_0_arqos               ),// input  wire [3  : 0] c0_ddr4_s_axi_arqos    
    .c0_ddr4_s_axi_arlen             (M00_AXI_0_arlen               ),// input  wire [7  : 0] c0_ddr4_s_axi_arlen  
    .c0_ddr4_s_axi_arsize            (M00_AXI_0_arsize              ),// input  wire [2  : 0] c0_ddr4_s_axi_arsize 
    .c0_ddr4_s_axi_arburst           (M00_AXI_0_arburst             ),// input  wire [1  : 0] c0_ddr4_s_axi_arburst
    .c0_ddr4_s_axi_arvalid           (M00_AXI_0_arvalid             ),// input  wire          c0_ddr4_s_axi_arvalid
    .c0_ddr4_s_axi_arready           (M00_AXI_0_arready             ),// output wire          c0_ddr4_s_axi_arready
    .c0_ddr4_s_axi_rdata             (M00_AXI_0_rdata               ),// output wire [511: 0] c0_ddr4_s_axi_rdata
    .c0_ddr4_s_axi_rresp             (M00_AXI_0_rresp               ),// output wire [1  : 0] c0_ddr4_s_axi_rresp
    .c0_ddr4_s_axi_rlast             (M00_AXI_0_rlast               ),// output wire          c0_ddr4_s_axi_rlast 
    .c0_ddr4_s_axi_rvalid            (M00_AXI_0_rvalid              ),// output wire          c0_ddr4_s_axi_rvalid
    .c0_ddr4_s_axi_rready            (M00_AXI_0_rready              ) // input  wire          c0_ddr4_s_axi_rready
);
`else
assign       c0_ddr4_act_n           ='b0                           ;
assign       c0_ddr4_adr             ='b0                           ;
assign       c0_ddr4_ba              ='b0                           ;
assign       c0_ddr4_bg              ='b0                           ;
assign       c0_ddr4_cke             ='b0                           ;
assign       c0_ddr4_odt             ='b0                           ;
assign       c0_ddr4_cs_n            ='b0                           ;
assign       c0_ddr4_ck_t            ='b0                           ;
assign       c0_ddr4_ck_c            ='b0                           ;
assign       c0_ddr4_reset_n         ='b0                           ;
assign       c0_ddr4_parity          ='b0                           ;
assign       c0_ddr4_dq              ='b0                           ;
assign       c0_ddr4_dqs_c           ='b0                           ;
assign       c0_ddr4_dqs_t           ='b0                           ;
wire         c0_ddr4_ui_rst                                         ;
wire         c0_ddr4_ui_clk                                         ;
reg          c0_init_calib_complete                                 ;
assign       c0_ddr4_ui_clk          = c0_sys_clk_p                 ;
assign       c0_ddr4_ui_rst          = c0_sys_rst                   ;
assign      M00_ACLK_0               = c0_ddr4_ui_clk               ;
assign      M00_ARESETN_0            =~c0_ddr4_ui_rst               ;
wire        M00_ctrl                 =M00_AXI_0_arvalid &
                                     M00_AXI_0_arready;
initial
   begin
             c0_init_calib_complete=0;repeat (DDR4_DONE_CYCLE) 
   @(posedge c0_ddr4_ui_clk);c0_init_calib_complete  =1             ;
end
tb_fake_ddr4 #(
    .ddr_file                        (INST_FILE1                    ),
    .ID_DW                           (MID                           )
) c0_fake_ddr4 (
    .m_axi_awid                      (M00_AXI_0_awid                ),             
    .m_axi_awlock                    (M00_AXI_0_awlock              ),           
    .m_axi_awcache                   (M00_AXI_0_awcache             ),          
    .m_axi_awprot                    (M00_AXI_0_awprot              ),           
    .m_axi_awqos                     (M00_AXI_0_awqos               ),            
    .m_axi_awaddr                    (M00_AXI_0_awaddr_ddr          ),           
    .m_axi_awlen                     (M00_AXI_0_awlen               ),            
    .m_axi_awsize                    (M00_AXI_0_awsize              ),           
    .m_axi_awburst                   (M00_AXI_0_awburst             ),          
    .m_axi_awvalid                   (M00_AXI_0_awvalid             ),          
    .m_axi_awready                   (M00_AXI_0_awready             ),          
    .m_axi_wdata                     (M00_AXI_0_wdata               ),            
    .m_axi_wlast                     (M00_AXI_0_wlast               ),            
    .m_axi_wvalid                    (M00_AXI_0_wvalid              ),            
    .m_axi_wready                    (M00_AXI_0_wready              ),           
    .m_axi_wstrb                     (M00_AXI_0_wstrb               ),           
    .m_axi_bid                       (M00_AXI_0_bid                 ),              
    .m_axi_bresp                     (M00_AXI_0_bresp               ),            
    .m_axi_bvalid                    (M00_AXI_0_bvalid              ),           
    .m_axi_bready                    (M00_AXI_0_bready              ),           
    .m_axi_arid                      (M00_ctrl?M00_AXI_0_arid   :0  ),             
    .m_axi_arlock                    (M00_ctrl?M00_AXI_0_arlock :0  ),           
    .m_axi_arcache                   (M00_ctrl?M00_AXI_0_arcache:0  ),          
    .m_axi_arprot                    (M00_ctrl?M00_AXI_0_arprot :0  ),           
    .m_axi_arqos                     (M00_ctrl?M00_AXI_0_arqos  :0  ),            
    .m_axi_araddr                    (M00_ctrl?M00_AXI_0_araddr_ddr:0),           
    .m_axi_arlen                     (M00_ctrl?M00_AXI_0_arlen  :0  ),            
    .m_axi_arsize                    (M00_ctrl?M00_AXI_0_arsize :0  ),           
    .m_axi_arburst                   (M00_ctrl?M00_AXI_0_arburst:0  ),          
    .m_axi_arvalid                   (M00_ctrl                      ),          
    .m_axi_arready                   (M00_AXI_0_arready             ),          
    .m_axi_rready                    (M00_AXI_0_rready              ),              
    .m_axi_rdata                     (M00_AXI_0_rdata               ),            
    .m_axi_rvalid                    (M00_AXI_0_rvalid              ),            
    .m_axi_rlast                     (M00_AXI_0_rlast               ),            
    .m_axi_rid                       (M00_AXI_0_rid                 ),           
    .m_axi_rresp                     (M00_AXI_0_rresp               ),           
    .clk                             (c0_ddr4_ui_clk                ),
    .reset                           (c0_ddr4_ui_rst                )
);
`endif

 
//---------------------------------------------------------------------------
//DDR4 example
//Read data:21 cycle
//---------------------------------------------------------------------------
`ifdef DESIGN_OPU_CORE2_OR_CORE4
wire [63:0] M01_AXI_0_awaddr_ddr =M01_AXI_0_awaddr-AXI_M01_ADDR     ;
wire [63:0] M01_AXI_0_araddr_ddr =M01_AXI_0_araddr-AXI_M01_ADDR     ;
`ifndef SIM_MIG
wire        c1_ddr4_ui_rst                                          ;
wire        c1_ddr4_ui_clk                                          ;
wire        c1_init_calib_complete                                  ;
assign      M01_ACLK_0    = c1_ddr4_ui_clk                          ;
assign      M01_ARESETN_0 =~c1_ddr4_ui_rst                          ;
wire [7-1:0]M01_AXI_0_awid_mig                                      ;//i
wire [7-1:0]M01_AXI_0_arid_mig                                      ;//i
wire [7-1:0]M01_AXI_0_bid_mig                                       ;//o
wire [7-1:0]M01_AXI_0_rid_mig                                       ;//o
assign      M01_AXI_0_awid_mig ={{(7-MID){1'b0}},M01_AXI_0_awid}    ;
assign      M01_AXI_0_arid_mig ={{(7-MID){1'b0}},M01_AXI_0_arid}    ;
assign      M01_AXI_0_bid = M01_AXI_0_bid_mig[MID-1:0]              ;                          
assign      M01_AXI_0_rid = M01_AXI_0_rid_mig[MID-1:0]              ;
(*keep_hierarchy="yes"*)c1_DDR4_mig MIG1
(
    .sys_rst                         (c1_sys_rst                    ),// input  wire          sys_rst
    .c0_sys_clk_p                    (c1_sys_clk_p                  ),// input  wire          c0_sys_clk_p
    .c0_sys_clk_n                    (c1_sys_clk_n                  ),// input  wire          c0_sys_clk_n
    .c0_init_calib_complete          (c1_init_calib_complete        ),// output wire          c0_init_calib_complete
    .c0_ddr4_ui_clk_sync_rst         (c1_ddr4_ui_rst                ),// output wire          c0_ddr4_ui_clk_sync_rst       
    .c0_ddr4_ui_clk                  (c1_ddr4_ui_clk                ),// output wire          c0_ddr4_ui_clk
    .c0_ddr4_interrupt               (                              ),// output wire          c0_ddr4_interrupt
    .dbg_bus                         (                              ),// output wire [511:0]  dbg_bus 
    .dbg_clk                         (                              ),// output wire          dbg_clk
    .c0_ddr4_act_n                   (c1_ddr4_act_n                 ),// output wire          c0_ddr4_act_n
    .c0_ddr4_adr                     (c1_ddr4_adr                   ),// output wire [16 : 0] c0_ddr4_adr   
    .c0_ddr4_ba                      (c1_ddr4_ba                    ),// output wire [1  : 0] c0_ddr4_ba   
    .c0_ddr4_bg                      (c1_ddr4_bg                    ),// output wire [1  : 0] c0_ddr4_bg  
    .c0_ddr4_cke                     (c1_ddr4_cke                   ),// output wire [0  : 0] c0_ddr4_cke  
    .c0_ddr4_odt                     (c1_ddr4_odt                   ),// output wire [0  : 0] c0_ddr4_odt
    .c0_ddr4_cs_n                    (c1_ddr4_cs_n                  ),// output wire [0  : 0] c0_ddr4_cs_n 
    .c0_ddr4_ck_t                    (c1_ddr4_ck_t                  ),// output wire [0  : 0] c0_ddr4_ck_t
    .c0_ddr4_ck_c                    (c1_ddr4_ck_c                  ),// output wire [0  : 0] c0_ddr4_ck_c
    .c0_ddr4_reset_n                 (c1_ddr4_reset_n               ),// output wire          c0_ddr4_reset_n
    .c0_ddr4_parity                  (c1_ddr4_parity                ),// output wire          c0_ddr4_parity
    .c0_ddr4_dq                      (c1_ddr4_dq                    ),// inout  wire [71 : 0] c0_ddr4_dq 
    .c0_ddr4_dqs_c                   (c1_ddr4_dqs_c                 ),// inout  wire [17 : 0] c0_ddr4_dqs_c
    .c0_ddr4_dqs_t                   (c1_ddr4_dqs_t                 ),// inout  wire [17 : 0] c0_ddr4_dqs_t
    .c0_ddr4_s_axi_ctrl_awvalid      (1'b0                          ),// input  wire          c0_ddr4_s_axi_ctrl_awvalid
    .c0_ddr4_s_axi_ctrl_awready      (                              ),// output wire          c0_ddr4_s_axi_ctrl_awready
    .c0_ddr4_s_axi_ctrl_awaddr       (32'b0                         ),// input  wire [31 : 0] c0_ddr4_s_axi_ctrl_awaddr 
    .c0_ddr4_s_axi_ctrl_wvalid       (1'b0                          ),// input  wire          c0_ddr4_s_axi_ctrl_wvalid 
    .c0_ddr4_s_axi_ctrl_wready       (                              ),// output wire          c0_ddr4_s_axi_ctrl_wready 
    .c0_ddr4_s_axi_ctrl_wdata        (32'b0                         ),// input  wire [31 : 0] c0_ddr4_s_axi_ctrl_wdata  
    .c0_ddr4_s_axi_ctrl_bvalid       (                              ),// output wire          c0_ddr4_s_axi_ctrl_bvalid 
    .c0_ddr4_s_axi_ctrl_bready       (1'b1                          ),// input  wire          c0_ddr4_s_axi_ctrl_bready 
    .c0_ddr4_s_axi_ctrl_bresp        (                              ),// output wire [1 : 0]  c0_ddr4_s_axi_ctrl_bresp  
    .c0_ddr4_s_axi_ctrl_arvalid      (1'b0                          ),// input  wire          c0_ddr4_s_axi_ctrl_arvalid
    .c0_ddr4_s_axi_ctrl_arready      (                              ),// output wire          c0_ddr4_s_axi_ctrl_arready
    .c0_ddr4_s_axi_ctrl_araddr       (32'b0                         ),// input  wire [31 : 0] c0_ddr4_s_axi_ctrl_araddr 
    .c0_ddr4_s_axi_ctrl_rvalid       (                              ),// output wire          c0_ddr4_s_axi_ctrl_rvalid 
    .c0_ddr4_s_axi_ctrl_rready       (1'b1                          ),// input  wire          c0_ddr4_s_axi_ctrl_rready 
    .c0_ddr4_s_axi_ctrl_rdata        (                              ),// output wire [31 : 0] c0_ddr4_s_axi_ctrl_rdata  
    .c0_ddr4_s_axi_ctrl_rresp        (                              ),// output wire [1  : 0] c0_ddr4_s_axi_ctrl_rresp  
    .c0_ddr4_aresetn                 (M01_ARESETN_0                 ),// input  wire          c0_ddr4_aresetn
    .c0_ddr4_s_axi_awid              (M01_AXI_0_awid_mig            ),// input  wire [3  : 0] c0_ddr4_s_axi_awid  
    .c0_ddr4_s_axi_arid              (M01_AXI_0_arid_mig            ),// input  wire [3  : 0] c0_ddr4_s_axi_arid 
    .c0_ddr4_s_axi_bid               (M01_AXI_0_bid_mig             ),// output wire [3  : 0] c0_ddr4_s_axi_bid 
    .c0_ddr4_s_axi_rid               (M01_AXI_0_rid_mig             ),// output wire [3  : 0] c0_ddr4_s_axi_rid 
    .c0_ddr4_s_axi_awaddr            (M01_AXI_0_awaddr_ddr[33:0]    ),// input  wire [33 : 0] c0_ddr4_s_axi_awaddr 
    .c0_ddr4_s_axi_araddr            (M01_AXI_0_araddr_ddr[33:0]    ),// input  wire [33 : 0] c0_ddr4_s_axi_araddr 
    .c0_ddr4_s_axi_awlock            (M01_AXI_0_awlock              ),// input  wire [0  : 0] c0_ddr4_s_axi_awlock 
    .c0_ddr4_s_axi_awcache           (M01_AXI_0_awcache             ),// input  wire [3  : 0] c0_ddr4_s_axi_awcache
    .c0_ddr4_s_axi_awprot            (M01_AXI_0_awprot              ),// input  wire [2  : 0] c0_ddr4_s_axi_awprot 
    .c0_ddr4_s_axi_awqos             (M01_AXI_0_awqos               ),// input  wire [3  : 0] c0_ddr4_s_axi_awqos     
    .c0_ddr4_s_axi_awlen             (M01_AXI_0_awlen               ),// input  wire [7  : 0] c0_ddr4_s_axi_awlen  
    .c0_ddr4_s_axi_awsize            (M01_AXI_0_awsize              ),// input  wire [2  : 0] c0_ddr4_s_axi_awsize 
    .c0_ddr4_s_axi_awburst           (M01_AXI_0_awburst             ),// input  wire [1  : 0] c0_ddr4_s_axi_awburst
    .c0_ddr4_s_axi_awvalid           (M01_AXI_0_awvalid             ),// input  wire          c0_ddr4_s_axi_awvalid
    .c0_ddr4_s_axi_awready           (M01_AXI_0_awready             ),// output wire          c0_ddr4_s_axi_awready
    .c0_ddr4_s_axi_wdata             (M01_AXI_0_wdata               ),// input  wire [511: 0] c0_ddr4_s_axi_wdata 
    .c0_ddr4_s_axi_wstrb             (M01_AXI_0_wstrb               ),// input  wire [63 : 0] c0_ddr4_s_axi_wstrb 
    .c0_ddr4_s_axi_wlast             (M01_AXI_0_wlast               ),// input  wire          c0_ddr4_s_axi_wlast 
    .c0_ddr4_s_axi_wvalid            (M01_AXI_0_wvalid              ),// input  wire          c0_ddr4_s_axi_wvalid
    .c0_ddr4_s_axi_wready            (M01_AXI_0_wready              ),// output wire          c0_ddr4_s_axi_wready
    .c0_ddr4_s_axi_bresp             (M01_AXI_0_bresp               ),// output wire [1  : 0] c0_ddr4_s_axi_bresp 
    .c0_ddr4_s_axi_bvalid            (M01_AXI_0_bvalid              ),// output wire          c0_ddr4_s_axi_bvalid
    .c0_ddr4_s_axi_bready            (M01_AXI_0_bready              ),// input  wire          c0_ddr4_s_axi_bready
    .c0_ddr4_s_axi_arlock            (M01_AXI_0_arlock              ),// input  wire [0  : 0] c0_ddr4_s_axi_arlock  
    .c0_ddr4_s_axi_arcache           (M01_AXI_0_arcache             ),// input  wire [3  : 0] c0_ddr4_s_axi_arcache  
    .c0_ddr4_s_axi_arprot            (M01_AXI_0_arprot              ),// input  wire [2  : 0] c0_ddr4_s_axi_arprot  
    .c0_ddr4_s_axi_arqos             (M01_AXI_0_arqos               ),// input  wire [3  : 0] c0_ddr4_s_axi_arqos    
    .c0_ddr4_s_axi_arlen             (M01_AXI_0_arlen               ),// input  wire [7  : 0] c0_ddr4_s_axi_arlen  
    .c0_ddr4_s_axi_arsize            (M01_AXI_0_arsize              ),// input  wire [2  : 0] c0_ddr4_s_axi_arsize 
    .c0_ddr4_s_axi_arburst           (M01_AXI_0_arburst             ),// input  wire [1  : 0] c0_ddr4_s_axi_arburst
    .c0_ddr4_s_axi_arvalid           (M01_AXI_0_arvalid             ),// input  wire          c0_ddr4_s_axi_arvalid
    .c0_ddr4_s_axi_arready           (M01_AXI_0_arready             ),// output wire          c0_ddr4_s_axi_arready
    .c0_ddr4_s_axi_rdata             (M01_AXI_0_rdata               ),// output wire [511: 0] c0_ddr4_s_axi_rdata
    .c0_ddr4_s_axi_rresp             (M01_AXI_0_rresp               ),// output wire [1  : 0] c0_ddr4_s_axi_rresp
    .c0_ddr4_s_axi_rlast             (M01_AXI_0_rlast               ),// output wire          c0_ddr4_s_axi_rlast 
    .c0_ddr4_s_axi_rvalid            (M01_AXI_0_rvalid              ),// output wire          c0_ddr4_s_axi_rvalid
    .c0_ddr4_s_axi_rready            (M01_AXI_0_rready              ) // input  wire          c0_ddr4_s_axi_rready
);
`else
assign       c1_ddr4_act_n           ='b0                           ;
assign       c1_ddr4_adr             ='b0                           ;
assign       c1_ddr4_ba              ='b0                           ;
assign       c1_ddr4_bg              ='b0                           ;
assign       c1_ddr4_cke             ='b0                           ;
assign       c1_ddr4_odt             ='b0                           ;
assign       c1_ddr4_cs_n            ='b0                           ;
assign       c1_ddr4_ck_t            ='b0                           ;
assign       c1_ddr4_ck_c            ='b0                           ;
assign       c1_ddr4_reset_n         ='b0                           ;
assign       c1_ddr4_parity          ='b0                           ;
assign       c1_ddr4_dq              ='b0                           ;
assign       c1_ddr4_dqs_c           ='b0                           ;
assign       c1_ddr4_dqs_t           ='b0                           ;
wire         c1_ddr4_ui_rst                                         ;
wire         c1_ddr4_ui_clk                                         ;
reg          c1_init_calib_complete                                 ;
assign       c1_ddr4_ui_clk          = c1_sys_clk_p                 ;
assign       c1_ddr4_ui_rst          = c1_sys_rst                   ;
assign      M01_ACLK_0               = c1_ddr4_ui_clk               ;
assign      M01_ARESETN_0            =~c1_ddr4_ui_rst               ;
wire        M01_ctrl                 =M01_AXI_0_arvalid             &  
                                      M01_AXI_0_arready             ;
initial
   begin
             c1_init_calib_complete  =0;repeat (DDR4_DONE_CYCLE) 
   @(posedge c1_ddr4_ui_clk);c1_init_calib_complete  =1             ;
end
tb_fake_ddr4 #(
    .ddr_file                        (INST_FILE2                    ),
    .ID_DW                           (MID                           )
) c1_fake_ddr4 (
    .m_axi_awid                      (M01_AXI_0_awid                ),             
    .m_axi_awlock                    (M01_AXI_0_awlock              ),           
    .m_axi_awcache                   (M01_AXI_0_awcache             ),          
    .m_axi_awprot                    (M01_AXI_0_awprot              ),           
    .m_axi_awqos                     (M01_AXI_0_awqos               ),            
    .m_axi_awaddr                    (M01_AXI_0_awaddr_ddr          ),           
    .m_axi_awlen                     (M01_AXI_0_awlen               ),            
    .m_axi_awsize                    (M01_AXI_0_awsize              ),           
    .m_axi_awburst                   (M01_AXI_0_awburst             ),          
    .m_axi_awvalid                   (M01_AXI_0_awvalid             ),          
    .m_axi_awready                   (M01_AXI_0_awready             ),          
    .m_axi_wdata                     (M01_AXI_0_wdata               ),            
    .m_axi_wlast                     (M01_AXI_0_wlast               ),            
    .m_axi_wvalid                    (M01_AXI_0_wvalid              ),            
    .m_axi_wready                    (M01_AXI_0_wready              ),           
    .m_axi_wstrb                     (M01_AXI_0_wstrb               ),           
    .m_axi_bid                       (M01_AXI_0_bid                 ),              
    .m_axi_bresp                     (M01_AXI_0_bresp               ),            
    .m_axi_bvalid                    (M01_AXI_0_bvalid              ),           
    .m_axi_bready                    (M01_AXI_0_bready              ),           
    .m_axi_arid                      (M01_ctrl?M01_AXI_0_arid   :0  ),             
    .m_axi_arlock                    (M01_ctrl?M01_AXI_0_arlock :0  ),           
    .m_axi_arcache                   (M01_ctrl?M01_AXI_0_arcache:0  ),          
    .m_axi_arprot                    (M01_ctrl?M01_AXI_0_arprot :0  ),           
    .m_axi_arqos                     (M01_ctrl?M01_AXI_0_arqos  :0  ),            
    .m_axi_araddr                    (M01_ctrl?M01_AXI_0_araddr_ddr:0),           
    .m_axi_arlen                     (M01_ctrl?M01_AXI_0_arlen  :0  ),            
    .m_axi_arsize                    (M01_ctrl?M01_AXI_0_arsize :0  ),           
    .m_axi_arburst                   (M01_ctrl?M01_AXI_0_arburst:0  ),          
    .m_axi_arvalid                   (M01_ctrl                      ),          
    .m_axi_arready                   (M01_AXI_0_arready             ),          
    .m_axi_rready                    (M01_AXI_0_rready              ),              
    .m_axi_rdata                     (M01_AXI_0_rdata               ),            
    .m_axi_rvalid                    (M01_AXI_0_rvalid              ),            
    .m_axi_rlast                     (M01_AXI_0_rlast               ),            
    .m_axi_rid                       (M01_AXI_0_rid                 ),           
    .m_axi_rresp                     (M01_AXI_0_rresp               ),           
    .clk                             (c1_ddr4_ui_clk                ),
    .reset                           (c1_ddr4_ui_rst                )
);
`endif//sim
`endif//core2 or 4

//---------------------------------------------------------------------------
//DDR4 example
//Read data:21 cycle
//---------------------------------------------------------------------------
`ifdef DESIGN_OPU_CORE4
wire [63:0] M02_AXI_0_awaddr_ddr =M02_AXI_0_awaddr-AXI_M02_ADDR     ;
wire [63:0] M02_AXI_0_araddr_ddr =M02_AXI_0_araddr-AXI_M02_ADDR     ;
`ifndef SIM_MIG
wire        c2_ddr4_ui_rst                                          ;
wire        c2_ddr4_ui_clk                                          ;
wire        c2_init_calib_complete                                  ;
assign      M02_ACLK_0    = c2_ddr4_ui_clk                          ;
assign      M02_ARESETN_0 =~c2_ddr4_ui_rst                          ;
wire [7-1:0]M02_AXI_0_awid_mig                                      ;//i
wire [7-1:0]M02_AXI_0_arid_mig                                      ;//i
wire [7-1:0]M02_AXI_0_bid_mig                                       ;//o
wire [7-1:0]M02_AXI_0_rid_mig                                       ;//o
assign      M02_AXI_0_awid_mig ={{(7-MID){1'b0}},M02_AXI_0_awid}    ;
assign      M02_AXI_0_arid_mig ={{(7-MID){1'b0}},M02_AXI_0_arid}    ;
assign      M02_AXI_0_bid = M02_AXI_0_bid_mig[MID-1:0]              ;                          
assign      M02_AXI_0_rid = M02_AXI_0_rid_mig[MID-1:0]              ;
(*keep_hierarchy="yes"*)c2_DDR4_mig MIG2
(
    .sys_rst                         (c2_sys_rst                    ),// input  wire          sys_rst
    .c0_sys_clk_p                    (c2_sys_clk_p                  ),// input  wire          c0_sys_clk_p
    .c0_sys_clk_n                    (c2_sys_clk_n                  ),// input  wire          c0_sys_clk_n
    .c0_init_calib_complete          (c2_init_calib_complete        ),// output wire          c0_init_calib_complete
    .c0_ddr4_ui_clk_sync_rst         (c2_ddr4_ui_rst                ),// output wire          c0_ddr4_ui_clk_sync_rst       
    .c0_ddr4_ui_clk                  (c2_ddr4_ui_clk                ),// output wire          c0_ddr4_ui_clk
    .c0_ddr4_interrupt               (                              ),// output wire          c0_ddr4_interrupt
    .dbg_bus                         (                              ),// output wire [511:0]  dbg_bus 
    .dbg_clk                         (                              ),// output wire          dbg_clk
    .c0_ddr4_act_n                   (c2_ddr4_act_n                 ),// output wire          c0_ddr4_act_n
    .c0_ddr4_adr                     (c2_ddr4_adr                   ),// output wire [16 : 0] c0_ddr4_adr   
    .c0_ddr4_ba                      (c2_ddr4_ba                    ),// output wire [1  : 0] c0_ddr4_ba   
    .c0_ddr4_bg                      (c2_ddr4_bg                    ),// output wire [1  : 0] c0_ddr4_bg  
    .c0_ddr4_cke                     (c2_ddr4_cke                   ),// output wire [0  : 0] c0_ddr4_cke  
    .c0_ddr4_odt                     (c2_ddr4_odt                   ),// output wire [0  : 0] c0_ddr4_odt
    .c0_ddr4_cs_n                    (c2_ddr4_cs_n                  ),// output wire [0  : 0] c0_ddr4_cs_n 
    .c0_ddr4_ck_t                    (c2_ddr4_ck_t                  ),// output wire [0  : 0] c0_ddr4_ck_t
    .c0_ddr4_ck_c                    (c2_ddr4_ck_c                  ),// output wire [0  : 0] c0_ddr4_ck_c
    .c0_ddr4_reset_n                 (c2_ddr4_reset_n               ),// output wire          c0_ddr4_reset_n
    .c0_ddr4_parity                  (c2_ddr4_parity                ),// output wire          c0_ddr4_parity
    .c0_ddr4_dq                      (c2_ddr4_dq                    ),// inout  wire [71 : 0] c0_ddr4_dq 
    .c0_ddr4_dqs_c                   (c2_ddr4_dqs_c                 ),// inout  wire [17 : 0] c0_ddr4_dqs_c
    .c0_ddr4_dqs_t                   (c2_ddr4_dqs_t                 ),// inout  wire [17 : 0] c0_ddr4_dqs_t
    .c0_ddr4_s_axi_ctrl_awvalid      (1'b0                          ),// input  wire          c0_ddr4_s_axi_ctrl_awvalid
    .c0_ddr4_s_axi_ctrl_awready      (                              ),// output wire          c0_ddr4_s_axi_ctrl_awready
    .c0_ddr4_s_axi_ctrl_awaddr       (32'b0                         ),// input  wire [31 : 0] c0_ddr4_s_axi_ctrl_awaddr 
    .c0_ddr4_s_axi_ctrl_wvalid       (1'b0                          ),// input  wire          c0_ddr4_s_axi_ctrl_wvalid 
    .c0_ddr4_s_axi_ctrl_wready       (                              ),// output wire          c0_ddr4_s_axi_ctrl_wready 
    .c0_ddr4_s_axi_ctrl_wdata        (32'b0                         ),// input  wire [31 : 0] c0_ddr4_s_axi_ctrl_wdata  
    .c0_ddr4_s_axi_ctrl_bvalid       (                              ),// output wire          c0_ddr4_s_axi_ctrl_bvalid 
    .c0_ddr4_s_axi_ctrl_bready       (1'b1                          ),// input  wire          c0_ddr4_s_axi_ctrl_bready 
    .c0_ddr4_s_axi_ctrl_bresp        (                              ),// output wire [1 : 0]  c0_ddr4_s_axi_ctrl_bresp  
    .c0_ddr4_s_axi_ctrl_arvalid      (1'b0                          ),// input  wire          c0_ddr4_s_axi_ctrl_arvalid
    .c0_ddr4_s_axi_ctrl_arready      (                              ),// output wire          c0_ddr4_s_axi_ctrl_arready
    .c0_ddr4_s_axi_ctrl_araddr       (32'b0                         ),// input  wire [31 : 0] c0_ddr4_s_axi_ctrl_araddr 
    .c0_ddr4_s_axi_ctrl_rvalid       (                              ),// output wire          c0_ddr4_s_axi_ctrl_rvalid 
    .c0_ddr4_s_axi_ctrl_rready       (1'b1                          ),// input  wire          c0_ddr4_s_axi_ctrl_rready 
    .c0_ddr4_s_axi_ctrl_rdata        (                              ),// output wire [31 : 0] c0_ddr4_s_axi_ctrl_rdata  
    .c0_ddr4_s_axi_ctrl_rresp        (                              ),// output wire [1  : 0] c0_ddr4_s_axi_ctrl_rresp  
    .c0_ddr4_aresetn                 (M02_ARESETN_0                 ),// input  wire          c0_ddr4_aresetn
    .c0_ddr4_s_axi_awid              (M02_AXI_0_awid_mig            ),// input  wire [3  : 0] c0_ddr4_s_axi_awid 
    .c0_ddr4_s_axi_arid              (M02_AXI_0_arid_mig            ),// input  wire [3  : 0] c0_ddr4_s_axi_arid  
    .c0_ddr4_s_axi_bid               (M02_AXI_0_bid_mig             ),// output wire [3  : 0] c0_ddr4_s_axi_bid  
    .c0_ddr4_s_axi_rid               (M02_AXI_0_rid_mig             ),// output wire [3  : 0] c0_ddr4_s_axi_rid
    .c0_ddr4_s_axi_awaddr            (M02_AXI_0_awaddr_ddr[33:0]    ),// input  wire [33 : 0] c0_ddr4_s_axi_awaddr 
    .c0_ddr4_s_axi_araddr            (M02_AXI_0_araddr_ddr[33:0]    ),// input  wire [33 : 0] c0_ddr4_s_axi_araddr 
    .c0_ddr4_s_axi_awlock            (M02_AXI_0_awlock              ),// input  wire [0  : 0] c0_ddr4_s_axi_awlock 
    .c0_ddr4_s_axi_awcache           (M02_AXI_0_awcache             ),// input  wire [3  : 0] c0_ddr4_s_axi_awcache
    .c0_ddr4_s_axi_awprot            (M02_AXI_0_awprot              ),// input  wire [2  : 0] c0_ddr4_s_axi_awprot 
    .c0_ddr4_s_axi_awqos             (M02_AXI_0_awqos               ),// input  wire [3  : 0] c0_ddr4_s_axi_awqos     
    .c0_ddr4_s_axi_awlen             (M02_AXI_0_awlen               ),// input  wire [7  : 0] c0_ddr4_s_axi_awlen  
    .c0_ddr4_s_axi_awsize            (M02_AXI_0_awsize              ),// input  wire [2  : 0] c0_ddr4_s_axi_awsize 
    .c0_ddr4_s_axi_awburst           (M02_AXI_0_awburst             ),// input  wire [1  : 0] c0_ddr4_s_axi_awburst
    .c0_ddr4_s_axi_awvalid           (M02_AXI_0_awvalid             ),// input  wire          c0_ddr4_s_axi_awvalid
    .c0_ddr4_s_axi_awready           (M02_AXI_0_awready             ),// output wire          c0_ddr4_s_axi_awready
    .c0_ddr4_s_axi_wdata             (M02_AXI_0_wdata               ),// input  wire [511: 0] c0_ddr4_s_axi_wdata 
    .c0_ddr4_s_axi_wstrb             (M02_AXI_0_wstrb               ),// input  wire [63 : 0] c0_ddr4_s_axi_wstrb 
    .c0_ddr4_s_axi_wlast             (M02_AXI_0_wlast               ),// input  wire          c0_ddr4_s_axi_wlast 
    .c0_ddr4_s_axi_wvalid            (M02_AXI_0_wvalid              ),// input  wire          c0_ddr4_s_axi_wvalid
    .c0_ddr4_s_axi_wready            (M02_AXI_0_wready              ),// output wire          c0_ddr4_s_axi_wready
    .c0_ddr4_s_axi_bresp             (M02_AXI_0_bresp               ),// output wire [1  : 0] c0_ddr4_s_axi_bresp 
    .c0_ddr4_s_axi_bvalid            (M02_AXI_0_bvalid              ),// output wire          c0_ddr4_s_axi_bvalid
    .c0_ddr4_s_axi_bready            (M02_AXI_0_bready              ),// input  wire          c0_ddr4_s_axi_bready
    .c0_ddr4_s_axi_arlock            (M02_AXI_0_arlock              ),// input  wire [0  : 0] c0_ddr4_s_axi_arlock  
    .c0_ddr4_s_axi_arcache           (M02_AXI_0_arcache             ),// input  wire [3  : 0] c0_ddr4_s_axi_arcache  
    .c0_ddr4_s_axi_arprot            (M02_AXI_0_arprot              ),// input  wire [2  : 0] c0_ddr4_s_axi_arprot  
    .c0_ddr4_s_axi_arqos             (M02_AXI_0_arqos               ),// input  wire [3  : 0] c0_ddr4_s_axi_arqos    
    .c0_ddr4_s_axi_arlen             (M02_AXI_0_arlen               ),// input  wire [7  : 0] c0_ddr4_s_axi_arlen  
    .c0_ddr4_s_axi_arsize            (M02_AXI_0_arsize              ),// input  wire [2  : 0] c0_ddr4_s_axi_arsize 
    .c0_ddr4_s_axi_arburst           (M02_AXI_0_arburst             ),// input  wire [1  : 0] c0_ddr4_s_axi_arburst
    .c0_ddr4_s_axi_arvalid           (M02_AXI_0_arvalid             ),// input  wire          c0_ddr4_s_axi_arvalid
    .c0_ddr4_s_axi_arready           (M02_AXI_0_arready             ),// output wire          c0_ddr4_s_axi_arready
    .c0_ddr4_s_axi_rdata             (M02_AXI_0_rdata               ),// output wire [511: 0] c0_ddr4_s_axi_rdata
    .c0_ddr4_s_axi_rresp             (M02_AXI_0_rresp               ),// output wire [1  : 0] c0_ddr4_s_axi_rresp
    .c0_ddr4_s_axi_rlast             (M02_AXI_0_rlast               ),// output wire          c0_ddr4_s_axi_rlast 
    .c0_ddr4_s_axi_rvalid            (M02_AXI_0_rvalid              ),// output wire          c0_ddr4_s_axi_rvalid
    .c0_ddr4_s_axi_rready            (M02_AXI_0_rready              ) // input  wire          c0_ddr4_s_axi_rready
);
`else
assign       c2_ddr4_act_n           ='b0                           ;
assign       c2_ddr4_adr             ='b0                           ;
assign       c2_ddr4_ba              ='b0                           ;
assign       c2_ddr4_bg              ='b0                           ;
assign       c2_ddr4_cke             ='b0                           ;
assign       c2_ddr4_odt             ='b0                           ;
assign       c2_ddr4_cs_n            ='b0                           ;
assign       c2_ddr4_ck_t            ='b0                           ;
assign       c2_ddr4_ck_c            ='b0                           ;
assign       c2_ddr4_reset_n         ='b0                           ;
assign       c2_ddr4_parity          ='b0                           ;
assign       c2_ddr4_dq              ='b0                           ;
assign       c2_ddr4_dqs_c           ='b0                           ;
assign       c2_ddr4_dqs_t           ='b0                           ;
wire         c2_ddr4_ui_rst                                         ;
wire         c2_ddr4_ui_clk                                         ;
reg          c2_init_calib_complete                                 ;
assign       c2_ddr4_ui_clk          = c2_sys_clk_p                 ;
assign       c2_ddr4_ui_rst          = c2_sys_rst                   ;
assign      M02_ACLK_0               = c2_ddr4_ui_clk               ;
assign      M02_ARESETN_0            =~c2_ddr4_ui_rst               ;
wire        M02_ctrl                 =M02_AXI_0_arvalid             &
                                      M02_AXI_0_arready             ;
initial
   begin
             c2_init_calib_complete  =0;repeat (DDR4_DONE_CYCLE) 
   @(posedge c2_ddr4_ui_clk);c2_init_calib_complete  =1             ;
end
tb_fake_ddr4 #(
    .ddr_file                        (INST_FILE3                    ),
    .ID_DW                           (MID                           )
) c2_fake_ddr4 (
    .m_axi_awid                      (M02_AXI_0_awid                ),             
    .m_axi_awlock                    (M02_AXI_0_awlock              ),           
    .m_axi_awcache                   (M02_AXI_0_awcache             ),          
    .m_axi_awprot                    (M02_AXI_0_awprot              ),           
    .m_axi_awqos                     (M02_AXI_0_awqos               ),            
    .m_axi_awaddr                    (M02_AXI_0_awaddr_ddr          ),           
    .m_axi_awlen                     (M02_AXI_0_awlen               ),            
    .m_axi_awsize                    (M02_AXI_0_awsize              ),           
    .m_axi_awburst                   (M02_AXI_0_awburst             ),          
    .m_axi_awvalid                   (M02_AXI_0_awvalid             ),          
    .m_axi_awready                   (M02_AXI_0_awready             ),          
    .m_axi_wdata                     (M02_AXI_0_wdata               ),            
    .m_axi_wlast                     (M02_AXI_0_wlast               ),            
    .m_axi_wvalid                    (M02_AXI_0_wvalid              ),            
    .m_axi_wready                    (M02_AXI_0_wready              ),           
    .m_axi_wstrb                     (M02_AXI_0_wstrb               ),           
    .m_axi_bid                       (M02_AXI_0_bid                 ),              
    .m_axi_bresp                     (M02_AXI_0_bresp               ),            
    .m_axi_bvalid                    (M02_AXI_0_bvalid              ),           
    .m_axi_bready                    (M02_AXI_0_bready              ),           
    .m_axi_arid                      (M02_ctrl?M02_AXI_0_arid   :0  ),             
    .m_axi_arlock                    (M02_ctrl?M02_AXI_0_arlock :0  ),           
    .m_axi_arcache                   (M02_ctrl?M02_AXI_0_arcache:0  ),          
    .m_axi_arprot                    (M02_ctrl?M02_AXI_0_arprot :0  ),           
    .m_axi_arqos                     (M02_ctrl?M02_AXI_0_arqos  :0  ),            
    .m_axi_araddr                    (M02_ctrl?M02_AXI_0_araddr_ddr:0),           
    .m_axi_arlen                     (M02_ctrl?M02_AXI_0_arlen  :0  ),            
    .m_axi_arsize                    (M02_ctrl?M02_AXI_0_arsize :0  ),           
    .m_axi_arburst                   (M02_ctrl?M02_AXI_0_arburst:0  ),          
    .m_axi_arvalid                   (M02_ctrl                      ),          
    .m_axi_arready                   (M02_AXI_0_arready             ),          
    .m_axi_rready                    (M02_AXI_0_rready              ),              
    .m_axi_rdata                     (M02_AXI_0_rdata               ),            
    .m_axi_rvalid                    (M02_AXI_0_rvalid              ),            
    .m_axi_rlast                     (M02_AXI_0_rlast               ),            
    .m_axi_rid                       (M02_AXI_0_rid                 ),           
    .m_axi_rresp                     (M02_AXI_0_rresp               ),           
    .clk                             (c2_ddr4_ui_clk                ),
    .reset                           (c2_ddr4_ui_rst                )
);
`endif//sim
`endif//core2 or 4


//---------------------------------------------------------------------------
//DDR4 example
//Read data:21 cycle
//---------------------------------------------------------------------------
`ifdef DESIGN_OPU_CORE4
wire [63:0] M03_AXI_0_awaddr_ddr =M03_AXI_0_awaddr-AXI_M03_ADDR     ;
wire [63:0] M03_AXI_0_araddr_ddr =M03_AXI_0_araddr-AXI_M03_ADDR     ;
`ifndef SIM_MIG
wire        c3_ddr4_ui_rst                                          ;
wire        c3_ddr4_ui_clk                                          ;
wire        c3_init_calib_complete                                  ;
assign      M03_ACLK_0    = c3_ddr4_ui_clk                          ;
assign      M03_ARESETN_0 =~c3_ddr4_ui_rst                          ;
wire [7-1:0]M03_AXI_0_awid_mig                                      ;//i
wire [7-1:0]M03_AXI_0_arid_mig                                      ;//i
wire [7-1:0]M03_AXI_0_bid_mig                                       ;//o
wire [7-1:0]M03_AXI_0_rid_mig                                       ;//o
assign      M03_AXI_0_awid_mig ={{(7-MID){1'b0}},M03_AXI_0_awid}    ;
assign      M03_AXI_0_arid_mig ={{(7-MID){1'b0}},M03_AXI_0_arid}    ;
assign      M03_AXI_0_bid = M03_AXI_0_bid_mig[MID-1:0]              ;                          
assign      M03_AXI_0_rid = M03_AXI_0_rid_mig[MID-1:0]              ;
(*keep_hierarchy="yes"*)
c3_DDR4_mig MIG3
(
    .sys_rst                         (c3_sys_rst                    ),// input  wire          sys_rst
    .c0_sys_clk_p                    (c3_sys_clk_p                  ),// input  wire          c0_sys_clk_p
    .c0_sys_clk_n                    (c3_sys_clk_n                  ),// input  wire          c0_sys_clk_n
    .c0_init_calib_complete          (c3_init_calib_complete        ),// output wire          c0_init_calib_complete
    .c0_ddr4_ui_clk_sync_rst         (c3_ddr4_ui_rst                ),// output wire          c0_ddr4_ui_clk_sync_rst       
    .c0_ddr4_ui_clk                  (c3_ddr4_ui_clk                ),// output wire          c0_ddr4_ui_clk
    .c0_ddr4_interrupt               (                              ),// output wire          c0_ddr4_interrupt
    .dbg_bus                         (                              ),// output wire [511:0]  dbg_bus 
    .dbg_clk                         (                              ),// output wire          dbg_clk
    .c0_ddr4_act_n                   (c3_ddr4_act_n                 ),// output wire          c0_ddr4_act_n
    .c0_ddr4_adr                     (c3_ddr4_adr                   ),// output wire [16 : 0] c0_ddr4_adr   
    .c0_ddr4_ba                      (c3_ddr4_ba                    ),// output wire [1  : 0] c0_ddr4_ba   
    .c0_ddr4_bg                      (c3_ddr4_bg                    ),// output wire [1  : 0] c0_ddr4_bg  
    .c0_ddr4_cke                     (c3_ddr4_cke                   ),// output wire [0  : 0] c0_ddr4_cke  
    .c0_ddr4_odt                     (c3_ddr4_odt                   ),// output wire [0  : 0] c0_ddr4_odt
    .c0_ddr4_cs_n                    (c3_ddr4_cs_n                  ),// output wire [0  : 0] c0_ddr4_cs_n 
    .c0_ddr4_ck_t                    (c3_ddr4_ck_t                  ),// output wire [0  : 0] c0_ddr4_ck_t
    .c0_ddr4_ck_c                    (c3_ddr4_ck_c                  ),// output wire [0  : 0] c0_ddr4_ck_c
    .c0_ddr4_reset_n                 (c3_ddr4_reset_n               ),// output wire          c0_ddr4_reset_n
    .c0_ddr4_parity                  (c3_ddr4_parity                ),// output wire          c0_ddr4_parity
    .c0_ddr4_dq                      (c3_ddr4_dq                    ),// inout  wire [71 : 0] c0_ddr4_dq 
    .c0_ddr4_dqs_c                   (c3_ddr4_dqs_c                 ),// inout  wire [17 : 0] c0_ddr4_dqs_c
    .c0_ddr4_dqs_t                   (c3_ddr4_dqs_t                 ),// inout  wire [17 : 0] c0_ddr4_dqs_t
    .c0_ddr4_s_axi_ctrl_awvalid      (1'b0                          ),// input  wire          c0_ddr4_s_axi_ctrl_awvalid
    .c0_ddr4_s_axi_ctrl_awready      (                              ),// output wire          c0_ddr4_s_axi_ctrl_awready
    .c0_ddr4_s_axi_ctrl_awaddr       (32'b0                         ),// input  wire [31 : 0] c0_ddr4_s_axi_ctrl_awaddr 
    .c0_ddr4_s_axi_ctrl_wvalid       (1'b0                          ),// input  wire          c0_ddr4_s_axi_ctrl_wvalid 
    .c0_ddr4_s_axi_ctrl_wready       (                              ),// output wire          c0_ddr4_s_axi_ctrl_wready 
    .c0_ddr4_s_axi_ctrl_wdata        (32'b0                         ),// input  wire [31 : 0] c0_ddr4_s_axi_ctrl_wdata  
    .c0_ddr4_s_axi_ctrl_bvalid       (                              ),// output wire          c0_ddr4_s_axi_ctrl_bvalid 
    .c0_ddr4_s_axi_ctrl_bready       (1'b1                          ),// input  wire          c0_ddr4_s_axi_ctrl_bready 
    .c0_ddr4_s_axi_ctrl_bresp        (                              ),// output wire [1 : 0]  c0_ddr4_s_axi_ctrl_bresp  
    .c0_ddr4_s_axi_ctrl_arvalid      (1'b0                          ),// input  wire          c0_ddr4_s_axi_ctrl_arvalid
    .c0_ddr4_s_axi_ctrl_arready      (                              ),// output wire          c0_ddr4_s_axi_ctrl_arready
    .c0_ddr4_s_axi_ctrl_araddr       (32'b0                         ),// input  wire [31 : 0] c0_ddr4_s_axi_ctrl_araddr 
    .c0_ddr4_s_axi_ctrl_rvalid       (                              ),// output wire          c0_ddr4_s_axi_ctrl_rvalid 
    .c0_ddr4_s_axi_ctrl_rready       (1'b1                          ),// input  wire          c0_ddr4_s_axi_ctrl_rready 
    .c0_ddr4_s_axi_ctrl_rdata        (                              ),// output wire [31 : 0] c0_ddr4_s_axi_ctrl_rdata  
    .c0_ddr4_s_axi_ctrl_rresp        (                              ),// output wire [1  : 0] c0_ddr4_s_axi_ctrl_rresp  
    .c0_ddr4_aresetn                 (M03_ARESETN_0                 ),// input  wire          c0_ddr4_aresetn
    .c0_ddr4_s_axi_awid              (M03_AXI_0_awid_mig            ),// input  wire [3  : 0] c0_ddr4_s_axi_awid 
    .c0_ddr4_s_axi_arid              (M03_AXI_0_arid_mig            ),// input  wire [3  : 0] c0_ddr4_s_axi_arid   
    .c0_ddr4_s_axi_bid               (M03_AXI_0_bid_mig             ),// output wire [3  : 0] c0_ddr4_s_axi_bid 
    .c0_ddr4_s_axi_rid               (M03_AXI_0_rid_mig             ),// output wire [3  : 0] c0_ddr4_s_axi_rid
    .c0_ddr4_s_axi_awaddr            (M03_AXI_0_awaddr_ddr[33:0]    ),// input  wire [33 : 0] c0_ddr4_s_axi_awaddr 
    .c0_ddr4_s_axi_araddr            (M03_AXI_0_araddr_ddr[33:0]    ),// input  wire [33 : 0] c0_ddr4_s_axi_araddr 
    .c0_ddr4_s_axi_awlock            (M03_AXI_0_awlock              ),// input  wire [0  : 0] c0_ddr4_s_axi_awlock 
    .c0_ddr4_s_axi_awcache           (M03_AXI_0_awcache             ),// input  wire [3  : 0] c0_ddr4_s_axi_awcache
    .c0_ddr4_s_axi_awprot            (M03_AXI_0_awprot              ),// input  wire [2  : 0] c0_ddr4_s_axi_awprot 
    .c0_ddr4_s_axi_awqos             (M03_AXI_0_awqos               ),// input  wire [3  : 0] c0_ddr4_s_axi_awqos     
    .c0_ddr4_s_axi_awlen             (M03_AXI_0_awlen               ),// input  wire [7  : 0] c0_ddr4_s_axi_awlen  
    .c0_ddr4_s_axi_awsize            (M03_AXI_0_awsize              ),// input  wire [2  : 0] c0_ddr4_s_axi_awsize 
    .c0_ddr4_s_axi_awburst           (M03_AXI_0_awburst             ),// input  wire [1  : 0] c0_ddr4_s_axi_awburst
    .c0_ddr4_s_axi_awvalid           (M03_AXI_0_awvalid             ),// input  wire          c0_ddr4_s_axi_awvalid
    .c0_ddr4_s_axi_awready           (M03_AXI_0_awready             ),// output wire          c0_ddr4_s_axi_awready
    .c0_ddr4_s_axi_wdata             (M03_AXI_0_wdata               ),// input  wire [511: 0] c0_ddr4_s_axi_wdata 
    .c0_ddr4_s_axi_wstrb             (M03_AXI_0_wstrb               ),// input  wire [63 : 0] c0_ddr4_s_axi_wstrb 
    .c0_ddr4_s_axi_wlast             (M03_AXI_0_wlast               ),// input  wire          c0_ddr4_s_axi_wlast 
    .c0_ddr4_s_axi_wvalid            (M03_AXI_0_wvalid              ),// input  wire          c0_ddr4_s_axi_wvalid
    .c0_ddr4_s_axi_wready            (M03_AXI_0_wready              ),// output wire          c0_ddr4_s_axi_wready
    .c0_ddr4_s_axi_bresp             (M03_AXI_0_bresp               ),// output wire [1  : 0] c0_ddr4_s_axi_bresp 
    .c0_ddr4_s_axi_bvalid            (M03_AXI_0_bvalid              ),// output wire          c0_ddr4_s_axi_bvalid
    .c0_ddr4_s_axi_bready            (M03_AXI_0_bready              ),// input  wire          c0_ddr4_s_axi_bready
    .c0_ddr4_s_axi_arlock            (M03_AXI_0_arlock              ),// input  wire [0  : 0] c0_ddr4_s_axi_arlock  
    .c0_ddr4_s_axi_arcache           (M03_AXI_0_arcache             ),// input  wire [3  : 0] c0_ddr4_s_axi_arcache  
    .c0_ddr4_s_axi_arprot            (M03_AXI_0_arprot              ),// input  wire [2  : 0] c0_ddr4_s_axi_arprot  
    .c0_ddr4_s_axi_arqos             (M03_AXI_0_arqos               ),// input  wire [3  : 0] c0_ddr4_s_axi_arqos    
    .c0_ddr4_s_axi_arlen             (M03_AXI_0_arlen               ),// input  wire [7  : 0] c0_ddr4_s_axi_arlen  
    .c0_ddr4_s_axi_arsize            (M03_AXI_0_arsize              ),// input  wire [2  : 0] c0_ddr4_s_axi_arsize 
    .c0_ddr4_s_axi_arburst           (M03_AXI_0_arburst             ),// input  wire [1  : 0] c0_ddr4_s_axi_arburst
    .c0_ddr4_s_axi_arvalid           (M03_AXI_0_arvalid             ),// input  wire          c0_ddr4_s_axi_arvalid
    .c0_ddr4_s_axi_arready           (M03_AXI_0_arready             ),// output wire          c0_ddr4_s_axi_arready
    .c0_ddr4_s_axi_rdata             (M03_AXI_0_rdata               ),// output wire [511: 0] c0_ddr4_s_axi_rdata
    .c0_ddr4_s_axi_rresp             (M03_AXI_0_rresp               ),// output wire [1  : 0] c0_ddr4_s_axi_rresp
    .c0_ddr4_s_axi_rlast             (M03_AXI_0_rlast               ),// output wire          c0_ddr4_s_axi_rlast 
    .c0_ddr4_s_axi_rvalid            (M03_AXI_0_rvalid              ),// output wire          c0_ddr4_s_axi_rvalid
    .c0_ddr4_s_axi_rready            (M03_AXI_0_rready              ) // input  wire          c0_ddr4_s_axi_rready
);
`else
assign       c3_ddr4_act_n           ='b0                           ;
assign       c3_ddr4_adr             ='b0                           ;
assign       c3_ddr4_ba              ='b0                           ;
assign       c3_ddr4_bg              ='b0                           ;
assign       c3_ddr4_cke             ='b0                           ;
assign       c3_ddr4_odt             ='b0                           ;
assign       c3_ddr4_cs_n            ='b0                           ;
assign       c3_ddr4_ck_t            ='b0                           ;
assign       c3_ddr4_ck_c            ='b0                           ;
assign       c3_ddr4_reset_n         ='b0                           ;
assign       c3_ddr4_parity          ='b0                           ;
assign       c3_ddr4_dq              ='b0                           ;
assign       c3_ddr4_dqs_c           ='b0                           ;
assign       c3_ddr4_dqs_t           ='b0                           ;
wire         c3_ddr4_ui_rst                                         ;
wire         c3_ddr4_ui_clk                                         ;
reg          c3_init_calib_complete                                 ;
assign       c3_ddr4_ui_clk          = c3_sys_clk_p                 ;
assign       c3_ddr4_ui_rst          = c3_sys_rst                   ;
assign      M03_ACLK_0               = c3_ddr4_ui_clk               ;
assign      M03_ARESETN_0            =~c3_ddr4_ui_rst               ;
wire        M03_ctrl                 =M03_AXI_0_arvalid             & 
                                      M03_AXI_0_arready             ;
initial
   begin
             c3_init_calib_complete=0;repeat (DDR4_DONE_CYCLE) 
   @(posedge c3_ddr4_ui_clk)         ;c3_init_calib_complete=1      ;
end
tb_fake_ddr4 #(
    .ddr_file                        (INST_FILE4                    ),
    .ID_DW                           (MID                           )
) c3_fake_ddr4 (
    .m_axi_awid                      (M03_AXI_0_awid                ),             
    .m_axi_awlock                    (M03_AXI_0_awlock              ),           
    .m_axi_awcache                   (M03_AXI_0_awcache             ),          
    .m_axi_awprot                    (M03_AXI_0_awprot              ),           
    .m_axi_awqos                     (M03_AXI_0_awqos               ),            
    .m_axi_awaddr                    (M03_AXI_0_awaddr_ddr          ),           
    .m_axi_awlen                     (M03_AXI_0_awlen               ),            
    .m_axi_awsize                    (M03_AXI_0_awsize              ),           
    .m_axi_awburst                   (M03_AXI_0_awburst             ),          
    .m_axi_awvalid                   (M03_AXI_0_awvalid             ),          
    .m_axi_awready                   (M03_AXI_0_awready             ),          
    .m_axi_wdata                     (M03_AXI_0_wdata               ),            
    .m_axi_wlast                     (M03_AXI_0_wlast               ),            
    .m_axi_wvalid                    (M03_AXI_0_wvalid              ),            
    .m_axi_wready                    (M03_AXI_0_wready              ),           
    .m_axi_wstrb                     (M03_AXI_0_wstrb               ),           
    .m_axi_bid                       (M03_AXI_0_bid                 ),              
    .m_axi_bresp                     (M03_AXI_0_bresp               ),            
    .m_axi_bvalid                    (M03_AXI_0_bvalid              ),           
    .m_axi_bready                    (M03_AXI_0_bready              ),           
    .m_axi_arid                      (M03_ctrl?M03_AXI_0_arid    :0 ),             
    .m_axi_arlock                    (M03_ctrl?M03_AXI_0_arlock  :0 ),           
    .m_axi_arcache                   (M03_ctrl?M03_AXI_0_arcache :0 ),          
    .m_axi_arprot                    (M03_ctrl?M03_AXI_0_arprot  :0 ),           
    .m_axi_arqos                     (M03_ctrl?M03_AXI_0_arqos   :0 ),            
    .m_axi_araddr                    (M03_ctrl?M03_AXI_0_araddr_ddr:0),           
    .m_axi_arlen                     (M03_ctrl?M03_AXI_0_arlen   :0 ),            
    .m_axi_arsize                    (M03_ctrl?M03_AXI_0_arsize  :0 ),           
    .m_axi_arburst                   (M03_ctrl?M03_AXI_0_arburst :0 ),          
    .m_axi_arvalid                   (M03_ctrl                      ),          
    .m_axi_arready                   (M03_AXI_0_arready             ),          
    .m_axi_rready                    (M03_AXI_0_rready              ),              
    .m_axi_rdata                     (M03_AXI_0_rdata               ),            
    .m_axi_rvalid                    (M03_AXI_0_rvalid              ),            
    .m_axi_rlast                     (M03_AXI_0_rlast               ),            
    .m_axi_rid                       (M03_AXI_0_rid                 ),           
    .m_axi_rresp                     (M03_AXI_0_rresp               ),           
    .clk                             (c3_ddr4_ui_clk                ),
    .reset                           (c3_ddr4_ui_rst                )
);
`endif//sim
`endif//core2 or 4




//---------------------------------------------------------------------------
//PCIE example
//--------------------------------------------------------------------------- 
`ifndef SIM_XDMA
wire                                pci_exp_user_clk                ;
wire                                pci_exp_user_resetn             ;
wire                                pci_exp_done                    ;
(*keep_hierarchy="yes"*)
pcie_top   PCIE_TOP
(
    .pci_exp_rst_n                  (pci_exp_rst_n                  ),
    .pci_exp_clk_p                  (pci_exp_clk_p                  ),
    .pci_exp_clk_n                  (pci_exp_clk_n                  ),
    .pci_exp_txp                    (pci_exp_txp                    ),
    .pci_exp_txn                    (pci_exp_txn                    ),
    .pci_exp_rxp                    (pci_exp_rxp                    ),
    .pci_exp_rxn                    (pci_exp_rxn                    ), 
    .pci_exp_user_clk               (pci_exp_user_clk               ),
    .pci_exp_user_resetn            (pci_exp_user_resetn            ),
    .pci_exp_done                   (pci_exp_done                   ),
    .m_axi_awid                     (S00_AXI_0_awid                 ),//o
    .m_axi_arid                     (S00_AXI_0_arid                 ),//o
    .m_axi_bid                      (S00_AXI_0_bid                  ),//i
    .m_axi_rid                      (S00_AXI_0_rid                  ),//i
    .m_axi_aclk                     (S00_ACLK_0                     ),
    .m_axi_aresetn                  (S00_ARESETN_0                  ),
    .m_axi_awready                  (S00_AXI_0_awready              ), 
    .m_axi_awvalid                  (S00_AXI_0_awvalid              ),  
    .m_axi_awaddr                   (S00_AXI_0_awaddr               ),   
    .m_axi_awlen                    (S00_AXI_0_awlen                ),   
    .m_axi_awsize                   (S00_AXI_0_awsize               ),   
    .m_axi_awburst                  (S00_AXI_0_awburst              ),  
    .m_axi_awprot                   (S00_AXI_0_awprot               ),
    .m_axi_awcache                  (S00_AXI_0_awcache              ),
    .m_axi_awlock                   (S00_AXI_0_awlock               ),
    .m_axi_awqos                    (S00_AXI_0_awqos                ),
    .m_axi_wready                   (S00_AXI_0_wready               ),
    .m_axi_wvalid                   (S00_AXI_0_wvalid               ), 
    .m_axi_wlast                    (S00_AXI_0_wlast                ),
    .m_axi_wstrb                    (S00_AXI_0_wstrb                ),   
    .m_axi_wdata                    (S00_AXI_0_wdata                ),
    .m_axi_bready                   (S00_AXI_0_bready               ),
    .m_axi_bvalid                   (S00_AXI_0_bvalid               ),
    .m_axi_bresp                    (S00_AXI_0_bresp                ),
    .m_axi_arready                  (S00_AXI_0_arready              ),
    .m_axi_arvalid                  (S00_AXI_0_arvalid              ),  
    .m_axi_araddr                   (S00_AXI_0_araddr               ),  
    .m_axi_arlen                    (S00_AXI_0_arlen                ),  
    .m_axi_arsize                   (S00_AXI_0_arsize               ),
    .m_axi_arburst                  (S00_AXI_0_arburst              ),
    .m_axi_arprot                   (S00_AXI_0_arprot               ),
    .m_axi_arlock                   (S00_AXI_0_arlock               ),
    .m_axi_arcache                  (S00_AXI_0_arcache              ),
    .m_axi_arqos                    (S00_AXI_0_arqos                ),
    .m_axi_rready                   (S00_AXI_0_rready               ),
    .m_axi_rvalid                   (S00_AXI_0_rvalid               ),
    .m_axi_rlast                    (S00_AXI_0_rlast                ),
    .m_axi_rdata                    (S00_AXI_0_rdata                ),
    .m_axi_rresp                    (S00_AXI_0_rresp                )

);
`else
reg    pci_exp_user_clk             =  0                            ;
reg    pci_exp_user_resetn          =  0                            ;
reg    pci_exp_done                 =  0                            ;
assign pci_exp_txp                  =  0                            ; 
assign pci_exp_txn                  =  0                            ;
assign S00_AXI_0_awvalid            =  0                            ;      
assign S00_AXI_0_awaddr             =  0                            ;      
assign S00_AXI_0_awlen              =  0                            ;      
assign S00_AXI_0_awsize             =  0                            ;      
assign S00_AXI_0_awburst            =  0                            ;      
assign S00_AXI_0_awid               =  0                            ;      
assign S00_AXI_0_awprot             =  0                            ;      
assign S00_AXI_0_awcache            =  0                            ;      
assign S00_AXI_0_awlock             =  0                            ;      
assign S00_AXI_0_awqos              =  0                            ;      
assign S00_AXI_0_wvalid             =  0                            ;       
assign S00_AXI_0_wlast              =  0                            ;       
assign S00_AXI_0_wstrb              =  0                            ;       
assign S00_AXI_0_wdata              =  0                            ;   
assign S00_AXI_0_bready             =  1                            ;   
assign S00_AXI_0_arvalid            =  0                            ;       
assign S00_AXI_0_araddr             =  0                            ;       
assign S00_AXI_0_arlen              =  0                            ;       
assign S00_AXI_0_arsize             =  0                            ;       
assign S00_AXI_0_arburst            =  0                            ;       
assign S00_AXI_0_arid               =  0                            ;       
assign S00_AXI_0_arprot             =  0                            ;       
assign S00_AXI_0_arlock             =  0                            ;       
assign S00_AXI_0_arcache            =  0                            ;       
assign S00_AXI_0_arqos              =  0                            ;
assign S00_AXI_0_rready             =  1                            ;
initial pci_exp_user_clk            =  0                            ;
assign S00_ACLK_0                   =  pci_exp_user_clk             ;  
assign S00_ARESETN_0                =  pci_exp_user_resetn          ;  
always  pci_exp_user_clk            = 
#(PCIE_CLOK_CYCLE/2) ~pci_exp_user_clk                              ;
initial begin
    pci_exp_user_resetn             =0                              ;
    repeat (50) @(posedge pci_exp_user_clk)                         ;
    pci_exp_user_resetn             =1                              ;
end   
initial begin
    pci_exp_done                    =0                              ;              
    repeat (PCIE_DONE_CYCLE)
    @(posedge pci_exp_user_clk)                                     ;
    pci_exp_done                    =1                              ;
    repeat (1) 
    @(posedge pci_exp_user_clk)                                     ;
    pci_exp_done                    =0                              ;
end 
`endif

//---------------------------------------------------------------------------
// The signal of each core. They are asynchronous.
//---------------------------------------------------------------------------
wire             core1_clk                                          ;
wire             core1_reset                                        ;
(*ASYNC_REG="TRUE"*)reg   core1_init_finish   =0                    ;
(*max_fanout=16*)reg      core1_start         =0                    ;
(*max_fanout=16*)reg[24:0]core1_offset        =0                    ;
(*max_fanout=16*)reg[3:0] core1_offset_high   =0                    ;
wire [9 :0]      core1_layer_cnt                                    ;
wire [31:0]      core1_opcode_cnt                                   ;
wire [31:0]      core1_latency_cnt                                  ;
assign           core1_clk  =  M00_ACLK_0                           ;//
assign           core1_reset= ~M00_ARESETN_0                        ;//
always @(posedge core1_clk) 
if(pci_exp_done) core1_init_finish<=1                               ;
reg  [7:0]       core1_start_cnt=100                                ;
always @(posedge core1_clk)
begin if(        core1_init_finish)
    begin if(    core1_start_cnt==0) 
                 core1_start_cnt<=0                                 ;
        else     core1_start_cnt<=
                 core1_start_cnt-1                                  ;
    end if(      core1_start_cnt==1)begin
                 core1_start      <=INST_START1                     ;//
                 core1_offset     <=INST_OFFSET1                    ;//
                 core1_offset_high<=INST_HIGH1                      ;//
end else begin   core1_start      <=0                               ;
                 core1_offset     <=0                               ;
                 core1_offset_high<=0                               ;
   end   
end
//---------------------------------------------------------
`ifdef DESIGN_OPU_CORE2_OR_CORE4
wire             core2_clk                                          ;
wire             core2_reset                                        ;
(*ASYNC_REG="TRUE"*)reg      core2_init_finish   =0                 ;
(*max_fanout=16*)reg         core2_start         =0                 ;
(*max_fanout=16*)reg  [24:0] core2_offset        =0                 ;
(*max_fanout=16*)reg  [3 :0] core2_offset_high   =0                 ;
wire [9 :0]      core2_layer_cnt                                    ;
wire [31:0]      core2_opcode_cnt                                   ;
wire [31:0]      core2_latency_cnt                                  ;
assign           core2_clk  =  M01_ACLK_0                           ;//
assign           core2_reset= ~M01_ARESETN_0                        ;//
always @(posedge core2_clk) 
if(pci_exp_done) core2_init_finish<=1                               ;
reg  [7:0]       core2_start_cnt=100                                ;
always @(posedge core2_clk)
begin if(        core2_init_finish)
    begin if(    core2_start_cnt==0) 
                 core2_start_cnt<=0                                 ;
        else     core2_start_cnt<=
                 core2_start_cnt-1                                  ;
    end if(      core2_start_cnt==1)begin
                 core2_start      <=INST_START2                     ;//
                 core2_offset     <=INST_OFFSET2                    ;//
                 core2_offset_high<=INST_HIGH2                      ;//
end else begin   core2_start      <=0                               ;
                 core2_offset     <=0                               ;
                 core2_offset_high<=0                               ;
   end   
end
`endif
//---------------------------------------------------------
`ifdef DESIGN_OPU_CORE4
wire             core3_clk                                          ;
wire             core3_reset                                        ;
(*ASYNC_REG="TRUE"*)reg      core3_init_finish   =0                 ;
(*max_fanout=16*)reg         core3_start         =0                 ;
(*max_fanout=16*)reg  [24:0] core3_offset        =0                 ;
(*max_fanout=16*)reg  [3 :0] core3_offset_high   =0                 ;
wire [9 :0]      core3_layer_cnt                                    ;
wire [31:0]      core3_opcode_cnt                                   ;
wire [31:0]      core3_latency_cnt                                  ;
assign           core3_clk  =  M02_ACLK_0                           ;//
assign           core3_reset= ~M02_ARESETN_0                        ;//
always @(posedge core3_clk) 
if(pci_exp_done) core3_init_finish<=1                               ;
reg  [7:0]       core3_start_cnt=100                                ;
always @(posedge core3_clk)
begin if(        core3_init_finish)
    begin if(    core3_start_cnt==0) 
                 core3_start_cnt<=0                                 ;
        else     core3_start_cnt<=
                 core3_start_cnt-1                                  ;
    end if(      core3_start_cnt==1)begin
                 core3_start      <=INST_START3                     ;//
                 core3_offset     <=INST_OFFSET3                    ;//
                 core3_offset_high<=INST_HIGH3                      ;//
end else begin   core3_start      <=0                               ;
                 core3_offset     <=0                               ;
                 core3_offset_high<=0                               ;
   end   
end
//---------------------------------------------------------------------
wire             core4_clk                                          ;
wire             core4_reset                                        ;
(*ASYNC_REG="TRUE"*)reg      core4_init_finish  =0                  ;
(*max_fanout=16*)reg         core4_start        =0                  ;
(*max_fanout=16*)reg  [24:0] core4_offset       =0                  ;
(*max_fanout=16*)reg  [3 :0] core4_offset_high  =0                  ;
wire [9 :0]      core4_layer_cnt                                    ;
wire [31:0]      core4_opcode_cnt                                   ;
wire [31:0]      core4_latency_cnt                                  ;
assign           core4_clk  =  M03_ACLK_0                           ;//
assign           core4_reset= ~M03_ARESETN_0                        ;//
always @(posedge core4_clk) 
if(pci_exp_done) core4_init_finish<=1                               ;
reg  [7:0]       core4_start_cnt=100                                ;
always @(posedge core4_clk)
begin if(        core4_init_finish)
    begin if(    core4_start_cnt==0) 
                 core4_start_cnt<=0                                 ;
        else     core4_start_cnt<=
                 core4_start_cnt-1                                  ;
    end if(      core4_start_cnt==1)begin
                 core4_start      <=INST_START4                     ;//
                 core4_offset     <=INST_OFFSET4                    ;//
                 core4_offset_high<=INST_HIGH4                      ;//
end else begin   core4_start      <=0                               ;
                 core4_offset     <=0                               ;
                 core4_offset_high<=0                               ;
   end   
end
`endif
//------------------------------------------------------------------------


//------------------------------------------------------------------------------------------
// The synchronization of single bit data is initiated at the same time.
//------------------------------------------------------------------------------------------
`ifdef DESIGN_OPU_CORE1//-------------------------------------------------------------------
(*dont_touch="true"*)wire          core1_layer_start_init           ;
(*dont_touch="true"*)wire          core1_layer_start_sync           ;
(*dont_touch="true"*)wire          core1_nvm_start_init             ;
(*dont_touch="true"*)wire          core1_nvm_start_sync             ;
(*dont_touch="true"*)wire [127:0]  core1_nvm_sum_init               ;
(*dont_touch="true"*)wire [127:0]  core1_nvm_sum_sync               ;
assign core1_layer_start_sync    = core1_layer_start_init           ;
assign core1_nvm_start_sync      = core1_nvm_start_init             ;
assign core1_nvm_sum_sync        = core1_nvm_sum_init               ;
`elsif DESIGN_OPU_CORE2//---------------------------------------------------------------
(*dont_touch="true"*)wire          core1_layer_start_init           ;
(*dont_touch="true"*)wire          core1_layer_start_sync           ;
(*dont_touch="true"*)wire          core1_nvm_start_init             ;
(*dont_touch="true"*)wire          core1_nvm_start_sync             ;
(*dont_touch="true"*)wire [127:0]  core1_nvm_sum_init               ;
(*dont_touch="true"*)wire [127:0]  core1_nvm_sum_sync               ;
(*dont_touch="true"*)wire          core2_layer_start_init           ;
(*dont_touch="true"*)wire          core2_layer_start_sync           ;
(*dont_touch="true"*)wire          core2_nvm_start_init             ;
(*dont_touch="true"*)wire          core2_nvm_start_sync             ;
(*dont_touch="true"*)wire [127:0]  core2_nvm_sum_init               ;
(*dont_touch="true"*)wire [127:0]  core2_nvm_sum_sync               ;

`ifdef SYNC_RUN
reg [3:0] BUFFER_SYNC_RUN_init     =0                               ;
always @(posedge core1_clk)
begin  if(core1_layer_start_sync)  BUFFER_SYNC_RUN_init[0]<=0       ;
  else if(core1_layer_start_init)  BUFFER_SYNC_RUN_init[0]<=1       ;
       if(core1_nvm_start_sync)    BUFFER_SYNC_RUN_init[2]<=0       ;
  else if(core1_nvm_start_init  )  BUFFER_SYNC_RUN_init[2]<=1   ;end
 assign   core1_layer_start_sync =&BUFFER_SYNC_RUN_init[1:0]        ;    
 assign   core1_nvm_start_sync   =&BUFFER_SYNC_RUN_init[3:2]        ;   
always @(posedge core2_clk)
begin  if(core2_layer_start_sync)  BUFFER_SYNC_RUN_init[1]<=0       ;
  else if(core2_layer_start_init)  BUFFER_SYNC_RUN_init[1]<=1       ;
       if(core2_nvm_start_sync)    BUFFER_SYNC_RUN_init[3]<=0       ;
  else if(core2_nvm_start_init  )  BUFFER_SYNC_RUN_init[3]<=1   ;end
 assign   core2_layer_start_sync =&BUFFER_SYNC_RUN_init[1:0]        ;    
 assign   core2_nvm_start_sync   =&BUFFER_SYNC_RUN_init[3:2]        ;  
`else
 assign   core1_layer_start_sync  =core1_layer_start_init           ;
 assign   core1_nvm_start_sync    =core1_nvm_start_init             ;
 assign   core2_layer_start_sync  =core2_layer_start_init           ;
 assign   core2_nvm_start_sync    =core2_nvm_start_init             ;
`endif

//--------------------------------------------------------------------
// // Synchronization is used to exchange NVM summation data.
//--------------------------------------------------------------------
`ifdef ROUTER_SYNC
reg [128*4-1:0] BUFFER_SYNC_ROUTER_in                               ;
reg [128*4-1:0] BUFFER_SYNC_ROUTER_in_r                             ;
wire[128*4-1:0] BUFFER_SYNC_ROUTER_ou                               ;
always @(posedge core1_clk)
if(core1_reset) begin
    BUFFER_SYNC_ROUTER_in  [0*128+:128]<=0                          ;
    BUFFER_SYNC_ROUTER_in_r[0*128+:128]<=0                          ;    
    BUFFER_SYNC_ROUTER_in  [1*128+:128]<=0                          ;
    BUFFER_SYNC_ROUTER_in_r[1*128+:128]<=0                          ;
end else begin
    BUFFER_SYNC_ROUTER_in  [0*128+:128]<=0                          ;
    BUFFER_SYNC_ROUTER_in_r[0*128+:128]<=
    BUFFER_SYNC_ROUTER_in  [0*128+:128]                             ;    
    BUFFER_SYNC_ROUTER_in  [1*128+:128]<=
    BUFFER_SYNC_ROUTER_ou  [2*128+:128]                             ;
    BUFFER_SYNC_ROUTER_in_r[1*128+:128]<=
    BUFFER_SYNC_ROUTER_in  [1*128+:128]                             ;
end
always @(posedge core2_clk)
if(core2_reset) begin
    BUFFER_SYNC_ROUTER_in  [2*128+:128]<=0                          ;
    BUFFER_SYNC_ROUTER_in_r[2*128+:128]<=0                          ;    
    BUFFER_SYNC_ROUTER_in  [3*128+:128]<=0                          ;
    BUFFER_SYNC_ROUTER_in_r[3*128+:128]<=0                          ;
end else begin
    BUFFER_SYNC_ROUTER_in  [2*128+:128]<=
    BUFFER_SYNC_ROUTER_ou  [0*128+:128]                             ;
    BUFFER_SYNC_ROUTER_in_r[2*128+:128]<=
    BUFFER_SYNC_ROUTER_in  [2*128+:128]                             ;    
    BUFFER_SYNC_ROUTER_in  [3*128+:128]<=
    BUFFER_SYNC_ROUTER_ou  [1*128+:128]                             ;
    BUFFER_SYNC_ROUTER_in_r[3*128+:128]<=
    BUFFER_SYNC_ROUTER_in  [3*128+:128]                             ;
end

(*keep_hierarchy="yes"*)
router_sync u1_router(
    .clk        (core1_clk                                          ),
    .rst        (core1_reset                                        ),
    .left_rx1   (BUFFER_SYNC_ROUTER_in_r[0*128+:128]                ),
    .left_rx2   (BUFFER_SYNC_ROUTER_in_r[1*128+:128]                ),
    .right_tx1  (BUFFER_SYNC_ROUTER_ou  [0*128+:128]                ),
    .right_tx2  (BUFFER_SYNC_ROUTER_ou  [1*128+:128]                ),
    .local_rx   (core1_nvm_sum_init                                 ),
    .local_tx   (core1_nvm_sum_sync                                 )    
);
(*keep_hierarchy="yes"*)
router_sync u2_router(
    .clk        (core2_clk                                          ),
    .rst        (core2_reset                                        ),
    .left_rx1   (BUFFER_SYNC_ROUTER_in_r[2*128+:128]                ),
    .left_rx2   (BUFFER_SYNC_ROUTER_in_r[3*128+:128]                ),
    .right_tx1  (BUFFER_SYNC_ROUTER_ou  [2*128+:128]                ),
    .right_tx2  (BUFFER_SYNC_ROUTER_ou  [3*128+:128]                ),
    .local_rx   (core2_nvm_sum_init                                 ),
    .local_tx   (core2_nvm_sum_sync                                 )    
);
`else
assign  core1_nvm_sum_sync   =     core1_nvm_sum_init               ;
assign  core2_nvm_sum_sync   =     core2_nvm_sum_init               ;
`endif



`elsif DESIGN_OPU_CORE4//-------------------------------------------------------------------
(*dont_touch="true"*)wire          core1_layer_start_init           ;
(*dont_touch="true"*)wire          core1_layer_start_sync           ;
(*dont_touch="true"*)wire          core1_nvm_start_init             ;
(*dont_touch="true"*)wire          core1_nvm_start_sync             ;
(*dont_touch="true"*)wire [127:0]  core1_nvm_sum_init               ;
(*dont_touch="true"*)wire [127:0]  core1_nvm_sum_sync               ;
(*dont_touch="true"*)wire          core2_layer_start_init           ;
(*dont_touch="true"*)wire          core2_layer_start_sync           ;
(*dont_touch="true"*)wire          core2_nvm_start_init             ;
(*dont_touch="true"*)wire          core2_nvm_start_sync             ;
(*dont_touch="true"*)wire [127:0]  core2_nvm_sum_init               ;
(*dont_touch="true"*)wire [127:0]  core2_nvm_sum_sync               ;
(*dont_touch="true"*)wire          core3_layer_start_init           ;
(*dont_touch="true"*)wire          core3_layer_start_sync           ;
(*dont_touch="true"*)wire          core3_nvm_start_init             ;
(*dont_touch="true"*)wire          core3_nvm_start_sync             ;
(*dont_touch="true"*)wire [127:0]  core3_nvm_sum_init               ;
(*dont_touch="true"*)wire [127:0]  core3_nvm_sum_sync               ;
(*dont_touch="true"*)wire          core4_layer_start_init           ;
(*dont_touch="true"*)wire          core4_layer_start_sync           ;
(*dont_touch="true"*)wire          core4_nvm_start_init             ;
(*dont_touch="true"*)wire          core4_nvm_start_sync             ;
(*dont_touch="true"*)wire [127:0]  core4_nvm_sum_init               ;
(*dont_touch="true"*)wire [127:0]  core4_nvm_sum_sync               ;
`ifdef SYNC_RUN
reg [7:0] BUFFER_SYNC_RUN_init =0                                   ;
always @(posedge core1_clk)
begin  if(core1_layer_start_sync)  BUFFER_SYNC_RUN_init[0]<=0       ;
  else if(core1_layer_start_init)  BUFFER_SYNC_RUN_init[0]<=1       ;
       if(core1_nvm_start_sync)    BUFFER_SYNC_RUN_init[4]<=0       ;
  else if(core1_nvm_start_init  )  BUFFER_SYNC_RUN_init[4]<=1   ;end
 assign   core1_layer_start_sync =&BUFFER_SYNC_RUN_init[3:0]        ;    
 assign   core1_nvm_start_sync   =&BUFFER_SYNC_RUN_init[7:4]        ;   
always @(posedge core2_clk)
begin  if(core2_layer_start_sync)  BUFFER_SYNC_RUN_init[1]<=0       ;
  else if(core2_layer_start_init)  BUFFER_SYNC_RUN_init[1]<=1       ;
       if(core2_nvm_start_sync)    BUFFER_SYNC_RUN_init[5]<=0       ;
  else if(core2_nvm_start_init  )  BUFFER_SYNC_RUN_init[5]<=1   ;end
 assign   core2_layer_start_sync =&BUFFER_SYNC_RUN_init[3:0]        ;    
 assign   core2_nvm_start_sync   =&BUFFER_SYNC_RUN_init[7:4]        ; 
 always @(posedge core3_clk)
begin  if(core3_layer_start_sync)  BUFFER_SYNC_RUN_init[2]<=0       ;
  else if(core3_layer_start_init)  BUFFER_SYNC_RUN_init[2]<=1       ;
       if(core3_nvm_start_sync)    BUFFER_SYNC_RUN_init[6]<=0       ;
  else if(core3_nvm_start_init  )  BUFFER_SYNC_RUN_init[6]<=1   ;end
 assign   core3_layer_start_sync =&BUFFER_SYNC_RUN_init[3:0]        ;    
 assign   core3_nvm_start_sync   =&BUFFER_SYNC_RUN_init[7:4]        ;   
always @(posedge core4_clk)
begin  if(core4_layer_start_sync)  BUFFER_SYNC_RUN_init[3]<=0       ;
  else if(core4_layer_start_init)  BUFFER_SYNC_RUN_init[3]<=1       ;
       if(core4_nvm_start_sync)    BUFFER_SYNC_RUN_init[7]<=0       ;
  else if(core4_nvm_start_init  )  BUFFER_SYNC_RUN_init[7]<=1   ;end
 assign   core4_layer_start_sync =&BUFFER_SYNC_RUN_init[3:0]        ;    
 assign   core4_nvm_start_sync   =&BUFFER_SYNC_RUN_init[7:4]        ;  
`else
 assign   core1_layer_start_sync  =core1_layer_start_init           ;
 assign   core1_nvm_start_sync    =core1_nvm_start_init             ;
 assign   core2_layer_start_sync  =core2_layer_start_init           ;
 assign   core2_nvm_start_sync    =core2_nvm_start_init             ;
 assign   core3_layer_start_sync  =core3_layer_start_init           ;
 assign   core3_nvm_start_sync    =core3_nvm_start_init             ;
 assign   core4_layer_start_sync  =core4_layer_start_init           ;
 assign   core4_nvm_start_sync    =core4_nvm_start_init             ;
`endif

//-----------------------------------------------------------------------
// // Synchronization is used to exchange NVM summation data.
//-----------------------------------------------------------------------
`ifdef ROUTER_SYNC
reg [128*8-1:0] BUFFER_SYNC_ROUTER_in                               ;
reg [128*8-1:0] BUFFER_SYNC_ROUTER_in_r                             ;
wire[128*8-1:0] BUFFER_SYNC_ROUTER_ou                               ;
always @(posedge core1_clk)
if(core1_reset) begin
    BUFFER_SYNC_ROUTER_in  [0*128+:128]<=0                          ;
    BUFFER_SYNC_ROUTER_in_r[0*128+:128]<=0                          ;    
    BUFFER_SYNC_ROUTER_in  [1*128+:128]<=0                          ;
    BUFFER_SYNC_ROUTER_in_r[1*128+:128]<=0                          ;
end else begin
    BUFFER_SYNC_ROUTER_in  [0*128+:128]<=0                          ;
    BUFFER_SYNC_ROUTER_in_r[0*128+:128]<=
    BUFFER_SYNC_ROUTER_in  [0*128+:128]                             ;    
    BUFFER_SYNC_ROUTER_in  [1*128+:128]<=
    BUFFER_SYNC_ROUTER_ou  [6*128+:128]                             ;
    BUFFER_SYNC_ROUTER_in_r[1*128+:128]<=
    BUFFER_SYNC_ROUTER_in  [1*128+:128]                             ;
end
always @(posedge core2_clk)
if(core2_reset) begin
    BUFFER_SYNC_ROUTER_in  [2*128+:128]<=0                          ;
    BUFFER_SYNC_ROUTER_in_r[2*128+:128]<=0                          ;    
    BUFFER_SYNC_ROUTER_in  [3*128+:128]<=0                          ;
    BUFFER_SYNC_ROUTER_in_r[3*128+:128]<=0                          ;
end else begin
    BUFFER_SYNC_ROUTER_in  [2*128+:128]<=
    BUFFER_SYNC_ROUTER_ou  [0*128+:128]                             ;
    BUFFER_SYNC_ROUTER_in_r[2*128+:128]<=
    BUFFER_SYNC_ROUTER_in  [2*128+:128]                             ;    
    BUFFER_SYNC_ROUTER_in  [3*128+:128]<=
    BUFFER_SYNC_ROUTER_ou  [1*128+:128]                             ;
    BUFFER_SYNC_ROUTER_in_r[3*128+:128]<=
    BUFFER_SYNC_ROUTER_in  [3*128+:128]                             ;
end

always @(posedge core3_clk)
if(core3_reset) begin
    BUFFER_SYNC_ROUTER_in  [4*128+:128]<=0                          ;
    BUFFER_SYNC_ROUTER_in_r[4*128+:128]<=0                          ;    
    BUFFER_SYNC_ROUTER_in  [5*128+:128]<=0                          ;
    BUFFER_SYNC_ROUTER_in_r[5*128+:128]<=0                          ;
end else begin
    BUFFER_SYNC_ROUTER_in  [4*128+:128]<=
    BUFFER_SYNC_ROUTER_ou  [2*128+:128]                             ;
    BUFFER_SYNC_ROUTER_in_r[4*128+:128]<=
    BUFFER_SYNC_ROUTER_in  [4*128+:128]                             ;    
    BUFFER_SYNC_ROUTER_in  [5*128+:128]<=
    BUFFER_SYNC_ROUTER_ou  [3*128+:128]                             ;
    BUFFER_SYNC_ROUTER_in_r[5*128+:128]<=
    BUFFER_SYNC_ROUTER_in  [5*128+:128]                             ;
end

always @(posedge core4_clk)
if(core4_reset) begin
    BUFFER_SYNC_ROUTER_in  [6*128+:128]<=0                          ;
    BUFFER_SYNC_ROUTER_in_r[6*128+:128]<=0                          ;    
    BUFFER_SYNC_ROUTER_in  [7*128+:128]<=0                          ;
    BUFFER_SYNC_ROUTER_in_r[7*128+:128]<=0                          ;
end else begin
    BUFFER_SYNC_ROUTER_in  [6*128+:128]<=
    BUFFER_SYNC_ROUTER_ou  [4*128+:128]                             ;
    BUFFER_SYNC_ROUTER_in_r[6*128+:128]<=
    BUFFER_SYNC_ROUTER_in  [6*128+:128]                             ;    
    BUFFER_SYNC_ROUTER_in  [7*128+:128]<=
    BUFFER_SYNC_ROUTER_ou  [5*128+:128]                             ;
    BUFFER_SYNC_ROUTER_in_r[7*128+:128]<=
    BUFFER_SYNC_ROUTER_in  [7*128+:128]                             ;
end


(*keep_hierarchy="yes"*)
opu_router_sync u1_router(
    .clk        (core1_clk                                          ),
    .rst        (core1_reset                                        ),
    .left_rx1   (BUFFER_SYNC_ROUTER_in_r[0*128+:128]                ),
    .left_rx2   (BUFFER_SYNC_ROUTER_in_r[1*128+:128]                ),
    .right_tx1  (BUFFER_SYNC_ROUTER_ou  [0*128+:128]                ),
    .right_tx2  (BUFFER_SYNC_ROUTER_ou  [1*128+:128]                ),
    .local_rx   (core1_nvm_sum_init                                 ),
    .local_tx   (core1_nvm_sum_sync                                 )    
);
(*keep_hierarchy="yes"*)
opu_router_sync u2_router(
    .clk        (core2_clk                                          ),
    .rst        (core2_reset                                        ),
    .left_rx1   (BUFFER_SYNC_ROUTER_in_r[2*128+:128]                ),
    .left_rx2   (BUFFER_SYNC_ROUTER_in_r[3*128+:128]                ),
    .right_tx1  (BUFFER_SYNC_ROUTER_ou  [2*128+:128]                ),
    .right_tx2  (BUFFER_SYNC_ROUTER_ou  [3*128+:128]                ),
    .local_rx   (core2_nvm_sum_init                                 ),
    .local_tx   (core2_nvm_sum_sync                                 )    
);
(*keep_hierarchy="yes"*)
opu_router_sync u3_router(
    .clk        (core3_clk                                          ),
    .rst        (core3_reset                                        ),
    .left_rx1   (BUFFER_SYNC_ROUTER_in_r[4*128+:128]                ),
    .left_rx2   (BUFFER_SYNC_ROUTER_in_r[5*128+:128]                ),
    .right_tx1  (BUFFER_SYNC_ROUTER_ou  [4*128+:128]                ),
    .right_tx2  (BUFFER_SYNC_ROUTER_ou  [5*128+:128]                ),
    .local_rx   (core3_nvm_sum_init                                 ),
    .local_tx   (core3_nvm_sum_sync                                 )    
);
(*keep_hierarchy="yes"*)
opu_router_sync u4_router(
    .clk        (core4_clk                                          ),
    .rst        (core4_reset                                        ),
    .left_rx1   (BUFFER_SYNC_ROUTER_in_r[6*128+:128]                ),
    .left_rx2   (BUFFER_SYNC_ROUTER_in_r[7*128+:128]                ),
    .right_tx1  (BUFFER_SYNC_ROUTER_ou  [6*128+:128]                ),
    .right_tx2  (BUFFER_SYNC_ROUTER_ou  [7*128+:128]                ),
    .local_rx   (core4_nvm_sum_init                                 ),
    .local_tx   (core4_nvm_sum_sync                                 )    
);

`else
assign          core1_nvm_sum_sync   =   core1_nvm_sum_init         ;
assign          core2_nvm_sum_sync   =   core2_nvm_sum_init         ;
assign          core3_nvm_sum_sync   =   core3_nvm_sum_init         ;
assign          core4_nvm_sum_sync   =   core4_nvm_sum_init         ;
`endif

`endif//core4


//-----------------------------------------------------------------------------
// Core1
//-----------------------------------------------------------------------------
wire [4-1:0]   S01_AXI_0_awid_core                                  ;//o
wire [4-1:0]   S01_AXI_0_arid_core                                  ;//o
wire [4-1:0]   S01_AXI_0_bid_core                                   ;//i
wire [4-1:0]   S01_AXI_0_rid_core                                   ;//i
wire           S01_AXI_0_rlast_core=S01_AXI_0_rvalid                &
                                    S01_AXI_0_rlast                 ;
assign         S01_AXI_0_awid      =S01_AXI_0_awid_core             ;//+AXI_S01_WRID;
assign         S01_AXI_0_arid      =S01_AXI_0_arid_core             ;//+AXI_S01_WRID;
assign         S01_AXI_0_bid_core  =S01_AXI_0_bid[3:0]              ; 
assign         S01_AXI_0_rid_core  =S01_AXI_0_rid[3:0]              ; 
(*keep_hierarchy="yes"*)
opu_core_top CORE_TOP1
(  
    .clk                            (core1_clk                      ),            
    .reset                          (core1_reset                    ),
    .core_init_finish               (core1_init_finish              ),
    .core_start                     (core1_start                    ),
    .core_offset                    (core1_offset                   ),
    .core_offset_high               (core1_offset_high              ),
    .core_layer_cnt                 (core1_layer_cnt                ),
    .core_opcode_cnt                (core1_opcode_cnt               ),
    .core_latency_cnt               (core1_latency_cnt              ),
    .layer_start_init               (core1_layer_start_init         ),
    .layer_start_sync               (core1_layer_start_sync         ),
    .nvm_start_init                 (core1_nvm_start_init           ),
    .nvm_start_sync                 (core1_nvm_start_sync           ),
    .nvm_sum_init                   (core1_nvm_sum_init             ),
    .nvm_sum_sync                   (core1_nvm_sum_sync             ),
    .m_axi_awid                     (S01_AXI_0_awid_core            ),//o
    .m_axi_arid                     (S01_AXI_0_arid_core            ),//o
    .m_axi_bid                      (S01_AXI_0_bid_core             ),//i
    .m_axi_rid                      (S01_AXI_0_rid_core             ),//i
    .m_axi_rlast                    (S01_AXI_0_rlast_core           ),//i
    .m_axi_aclk                     (S01_ACLK_0                     ),
    .m_axi_aresetn                  (S01_ARESETN_0                  ),
    .m_axi_awlock                   (S01_AXI_0_awlock               ),
    .m_axi_awcache                  (S01_AXI_0_awcache              ),
    .m_axi_awprot                   (S01_AXI_0_awprot               ),
    .m_axi_awqos                    (S01_AXI_0_awqos                ),
    .m_axi_awaddr                   (S01_AXI_0_awaddr               ),
    .m_axi_awlen                    (S01_AXI_0_awlen                ),
    .m_axi_awsize                   (S01_AXI_0_awsize               ),
    .m_axi_awburst                  (S01_AXI_0_awburst              ),
    .m_axi_awvalid                  (S01_AXI_0_awvalid              ),
    .m_axi_awready                  (S01_AXI_0_awready              ),
    .m_axi_wdata                    (S01_AXI_0_wdata                ),
    .m_axi_wlast                    (S01_AXI_0_wlast                ),
    .m_axi_wvalid                   (S01_AXI_0_wvalid               ),
    .m_axi_wready                   (S01_AXI_0_wready               ),
    .m_axi_wstrb                    (S01_AXI_0_wstrb                ),
    .m_axi_bresp                    (S01_AXI_0_bresp                ),
    .m_axi_bvalid                   (S01_AXI_0_bvalid               ),
    .m_axi_bready                   (S01_AXI_0_bready               ),
    .m_axi_arlock                   (S01_AXI_0_arlock               ),
    .m_axi_arcache                  (S01_AXI_0_arcache              ),
    .m_axi_arprot                   (S01_AXI_0_arprot               ),
    .m_axi_arqos                    (S01_AXI_0_arqos                ),
    .m_axi_araddr                   (S01_AXI_0_araddr               ),
    .m_axi_arlen                    (S01_AXI_0_arlen                ),
    .m_axi_arsize                   (S01_AXI_0_arsize               ),
    .m_axi_arburst                  (S01_AXI_0_arburst              ),
    .m_axi_arvalid                  (S01_AXI_0_arvalid              ),
    .m_axi_arready                  (S01_AXI_0_arready              ),
    .m_axi_rready                   (S01_AXI_0_rready               ),
    .m_axi_rdata                    (S01_AXI_0_rdata                ),
    .m_axi_rvalid                   (S01_AXI_0_rvalid               ),
    .m_axi_rresp                    (S01_AXI_0_rresp                )
);

//-----------------------------------------------------------------------------
// Core2
//-----------------------------------------------------------------------------


`ifdef DESIGN_OPU_CORE2_OR_CORE4
wire [4-1:0]   S02_AXI_0_awid_core                                  ;//o
wire [4-1:0]   S02_AXI_0_arid_core                                  ;//o
wire [4-1:0]   S02_AXI_0_bid_core                                   ;//i
wire [4-1:0]   S02_AXI_0_rid_core                                   ;//i
wire           S02_AXI_0_rlast_core=S02_AXI_0_rvalid                &
                                    S02_AXI_0_rlast                 ;
assign         S02_AXI_0_awid      =S02_AXI_0_awid_core+AXI_S02_WRID;
assign         S02_AXI_0_arid      =S02_AXI_0_arid_core+AXI_S02_WRID;
assign         S02_AXI_0_bid_core  =S02_AXI_0_bid[3:0]              ; 
assign         S02_AXI_0_rid_core  =S02_AXI_0_rid[3:0]              ; 
(*keep_hierarchy="yes"*)
opu_core_top CORE_TOP2
(  
    .clk                            (core2_clk                      ),            
    .reset                          (core2_reset                    ),
    .core_init_finish               (core2_init_finish              ),
    .core_start                     (core2_start                    ),
    .core_offset                    (core2_offset                   ),
    .core_offset_high               (core2_offset_high              ),
    .core_layer_cnt                 (core2_layer_cnt                ),
    .core_opcode_cnt                (core2_opcode_cnt               ),
    .core_latency_cnt               (core2_latency_cnt              ),
    .layer_start_init               (core2_layer_start_init         ),
    .layer_start_sync               (core2_layer_start_sync         ),
    .nvm_start_init                 (core2_nvm_start_init           ),
    .nvm_start_sync                 (core2_nvm_start_sync           ),
    .nvm_sum_init                   (core2_nvm_sum_init             ),
    .nvm_sum_sync                   (core2_nvm_sum_sync             ),
    .m_axi_awid                     (S02_AXI_0_awid_core            ),//o
    .m_axi_arid                     (S02_AXI_0_arid_core            ),//o
    .m_axi_bid                      (S02_AXI_0_bid_core             ),//i
    .m_axi_rid                      (S02_AXI_0_rid_core             ),//i
    .m_axi_rlast                    (S02_AXI_0_rlast_core           ),//i
    .m_axi_aclk                     (S02_ACLK_0                     ),
    .m_axi_aresetn                  (S02_ARESETN_0                  ),
    .m_axi_awlock                   (S02_AXI_0_awlock               ),
    .m_axi_awcache                  (S02_AXI_0_awcache              ),
    .m_axi_awprot                   (S02_AXI_0_awprot               ),
    .m_axi_awqos                    (S02_AXI_0_awqos                ),
    .m_axi_awaddr                   (S02_AXI_0_awaddr               ),
    .m_axi_awlen                    (S02_AXI_0_awlen                ),
    .m_axi_awsize                   (S02_AXI_0_awsize               ),
    .m_axi_awburst                  (S02_AXI_0_awburst              ),
    .m_axi_awvalid                  (S02_AXI_0_awvalid              ),
    .m_axi_awready                  (S02_AXI_0_awready              ),
    .m_axi_wdata                    (S02_AXI_0_wdata                ),
    .m_axi_wlast                    (S02_AXI_0_wlast                ),
    .m_axi_wvalid                   (S02_AXI_0_wvalid               ),
    .m_axi_wready                   (S02_AXI_0_wready               ),
    .m_axi_wstrb                    (S02_AXI_0_wstrb                ),
    .m_axi_bresp                    (S02_AXI_0_bresp                ),
    .m_axi_bvalid                   (S02_AXI_0_bvalid               ),
    .m_axi_bready                   (S02_AXI_0_bready               ),
    .m_axi_arlock                   (S02_AXI_0_arlock               ),
    .m_axi_arcache                  (S02_AXI_0_arcache              ),
    .m_axi_arprot                   (S02_AXI_0_arprot               ),
    .m_axi_arqos                    (S02_AXI_0_arqos                ),
    .m_axi_araddr                   (S02_AXI_0_araddr               ),
    .m_axi_arlen                    (S02_AXI_0_arlen                ),
    .m_axi_arsize                   (S02_AXI_0_arsize               ),
    .m_axi_arburst                  (S02_AXI_0_arburst              ),
    .m_axi_arvalid                  (S02_AXI_0_arvalid              ),
    .m_axi_arready                  (S02_AXI_0_arready              ),
    .m_axi_rready                   (S02_AXI_0_rready               ),
    .m_axi_rdata                    (S02_AXI_0_rdata                ),
    .m_axi_rvalid                   (S02_AXI_0_rvalid               ),
    .m_axi_rresp                    (S02_AXI_0_rresp                )
);
`endif
//-----------------------------------------------------------------------------
// Core3
//-----------------------------------------------------------------------------
`ifdef DESIGN_OPU_CORE4
wire [4-1:0]   S03_AXI_0_awid_core                                  ;//o
wire [4-1:0]   S03_AXI_0_arid_core                                  ;//o
wire [4-1:0]   S03_AXI_0_bid_core                                   ;//i
wire [4-1:0]   S03_AXI_0_rid_core                                   ;//i
wire           S03_AXI_0_rlast_core=S03_AXI_0_rvalid                & 
                                    S03_AXI_0_rlast                 ;
assign         S03_AXI_0_awid      =S03_AXI_0_awid_core+AXI_S03_WRID;
assign         S03_AXI_0_arid      =S03_AXI_0_arid_core+AXI_S03_WRID;
assign         S03_AXI_0_bid_core  =S03_AXI_0_bid[3:0]              ; 
assign         S03_AXI_0_rid_core  =S03_AXI_0_rid[3:0]              ; 
(*keep_hierarchy="yes"*)
opu_core_top CORE_TOP3
(  
    .clk                            (core3_clk                      ),             
    .reset                          (core3_reset                    ),
    .core_init_finish               (core3_init_finish              ),
    .core_start                     (core3_start                    ),
    .core_offset                    (core3_offset                   ),
    .core_offset_high               (core3_offset_high              ),
    .core_layer_cnt                 (core3_layer_cnt                ),
    .core_opcode_cnt                (core3_opcode_cnt               ),
    .core_latency_cnt               (core3_latency_cnt              ),
    .layer_start_init               (core3_layer_start_init         ),
    .layer_start_sync               (core3_layer_start_sync         ),
    .nvm_start_init                 (core3_nvm_start_init           ),
    .nvm_start_sync                 (core3_nvm_start_sync           ),
    .nvm_sum_init                   (core3_nvm_sum_init             ),
    .nvm_sum_sync                   (core3_nvm_sum_sync             ),
    .m_axi_awid                     (S03_AXI_0_awid_core            ),//o
    .m_axi_arid                     (S03_AXI_0_arid_core            ),//o
    .m_axi_bid                      (S03_AXI_0_bid_core             ),//i
    .m_axi_rid                      (S03_AXI_0_rid_core             ),//i
    .m_axi_rlast                    (S03_AXI_0_rlast_core           ),//i
    .m_axi_aclk                     (S03_ACLK_0                     ),
    .m_axi_aresetn                  (S03_ARESETN_0                  ),
    .m_axi_awlock                   (S03_AXI_0_awlock               ),
    .m_axi_awcache                  (S03_AXI_0_awcache              ),
    .m_axi_awprot                   (S03_AXI_0_awprot               ),
    .m_axi_awqos                    (S03_AXI_0_awqos                ),
    .m_axi_awaddr                   (S03_AXI_0_awaddr               ),
    .m_axi_awlen                    (S03_AXI_0_awlen                ),
    .m_axi_awsize                   (S03_AXI_0_awsize               ),
    .m_axi_awburst                  (S03_AXI_0_awburst              ),
    .m_axi_awvalid                  (S03_AXI_0_awvalid              ),
    .m_axi_awready                  (S03_AXI_0_awready              ),
    .m_axi_wdata                    (S03_AXI_0_wdata                ),
    .m_axi_wlast                    (S03_AXI_0_wlast                ),
    .m_axi_wvalid                   (S03_AXI_0_wvalid               ),
    .m_axi_wready                   (S03_AXI_0_wready               ),
    .m_axi_wstrb                    (S03_AXI_0_wstrb                ),
    .m_axi_bresp                    (S03_AXI_0_bresp                ),
    .m_axi_bvalid                   (S03_AXI_0_bvalid               ),
    .m_axi_bready                   (S03_AXI_0_bready               ),
    .m_axi_arlock                   (S03_AXI_0_arlock               ),
    .m_axi_arcache                  (S03_AXI_0_arcache              ),
    .m_axi_arprot                   (S03_AXI_0_arprot               ),
    .m_axi_arqos                    (S03_AXI_0_arqos                ),
    .m_axi_araddr                   (S03_AXI_0_araddr               ),
    .m_axi_arlen                    (S03_AXI_0_arlen                ),
    .m_axi_arsize                   (S03_AXI_0_arsize               ),
    .m_axi_arburst                  (S03_AXI_0_arburst              ),
    .m_axi_arvalid                  (S03_AXI_0_arvalid              ),
    .m_axi_arready                  (S03_AXI_0_arready              ),
    .m_axi_rready                   (S03_AXI_0_rready               ),
    .m_axi_rdata                    (S03_AXI_0_rdata                ),
    .m_axi_rvalid                   (S03_AXI_0_rvalid               ),
    .m_axi_rresp                    (S03_AXI_0_rresp                )
);
`endif

//-----------------------------------------------------------------------------
// Core4
//-----------------------------------------------------------------------------
`ifdef DESIGN_OPU_CORE4
wire [4-1:0]   S04_AXI_0_awid_core                                  ;//o
wire [4-1:0]   S04_AXI_0_arid_core                                  ;//o
wire [4-1:0]   S04_AXI_0_bid_core                                   ;//i
wire [4-1:0]   S04_AXI_0_rid_core                                   ;//i
wire           S04_AXI_0_rlast_core=S04_AXI_0_rvalid                & 
                                    S04_AXI_0_rlast                 ;
assign         S04_AXI_0_awid      =S04_AXI_0_awid_core+AXI_S04_WRID;
assign         S04_AXI_0_arid      =S04_AXI_0_arid_core+AXI_S04_WRID;
assign         S04_AXI_0_bid_core  =S04_AXI_0_bid[3:0]              ; 
assign         S04_AXI_0_rid_core  =S04_AXI_0_rid[3:0]              ; 

(*keep_hierarchy="yes"*)
opu_core_top CORE_TOP4
(  
    .clk                            (core4_clk                      ),            
    .reset                          (core4_reset                    ),
    .core_init_finish               (core4_init_finish              ),
    .core_start                     (core4_start                    ),
    .core_offset                    (core4_offset                   ),
    .core_offset_high               (core4_offset_high              ),
    .core_layer_cnt                 (core4_layer_cnt                ),
    .core_opcode_cnt                (core4_opcode_cnt               ),
    .core_latency_cnt               (core4_latency_cnt              ),
    .layer_start_init               (core4_layer_start_init         ),
    .layer_start_sync               (core4_layer_start_sync         ),
    .nvm_start_init                 (core4_nvm_start_init           ),
    .nvm_start_sync                 (core4_nvm_start_sync           ),
    .nvm_sum_init                   (core4_nvm_sum_init             ),
    .nvm_sum_sync                   (core4_nvm_sum_sync             ),
    .m_axi_awid                     (S04_AXI_0_awid_core            ),//o
    .m_axi_arid                     (S04_AXI_0_arid_core            ),//o
    .m_axi_bid                      (S04_AXI_0_bid_core             ),//i
    .m_axi_rid                      (S04_AXI_0_rid_core             ),//i
    .m_axi_rlast                    (S04_AXI_0_rlast_core           ),//i
    .m_axi_aclk                     (S04_ACLK_0                     ),
    .m_axi_aresetn                  (S04_ARESETN_0                  ),
    .m_axi_awlock                   (S04_AXI_0_awlock               ),
    .m_axi_awcache                  (S04_AXI_0_awcache              ),
    .m_axi_awprot                   (S04_AXI_0_awprot               ),
    .m_axi_awqos                    (S04_AXI_0_awqos                ),
    .m_axi_awaddr                   (S04_AXI_0_awaddr               ),
    .m_axi_awlen                    (S04_AXI_0_awlen                ),
    .m_axi_awsize                   (S04_AXI_0_awsize               ),
    .m_axi_awburst                  (S04_AXI_0_awburst              ),
    .m_axi_awvalid                  (S04_AXI_0_awvalid              ),
    .m_axi_awready                  (S04_AXI_0_awready              ),
    .m_axi_wdata                    (S04_AXI_0_wdata                ),
    .m_axi_wlast                    (S04_AXI_0_wlast                ),
    .m_axi_wvalid                   (S04_AXI_0_wvalid               ),
    .m_axi_wready                   (S04_AXI_0_wready               ),
    .m_axi_wstrb                    (S04_AXI_0_wstrb                ),
    .m_axi_bresp                    (S04_AXI_0_bresp                ),
    .m_axi_bvalid                   (S04_AXI_0_bvalid               ),
    .m_axi_bready                   (S04_AXI_0_bready               ),
    .m_axi_arlock                   (S04_AXI_0_arlock               ),
    .m_axi_arcache                  (S04_AXI_0_arcache              ),
    .m_axi_arprot                   (S04_AXI_0_arprot               ),
    .m_axi_arqos                    (S04_AXI_0_arqos                ),
    .m_axi_araddr                   (S04_AXI_0_araddr               ),
    .m_axi_arlen                    (S04_AXI_0_arlen                ),
    .m_axi_arsize                   (S04_AXI_0_arsize               ),
    .m_axi_arburst                  (S04_AXI_0_arburst              ),
    .m_axi_arvalid                  (S04_AXI_0_arvalid              ),
    .m_axi_arready                  (S04_AXI_0_arready              ),
    .m_axi_rready                   (S04_AXI_0_rready               ),
    .m_axi_rdata                    (S04_AXI_0_rdata                ),
    .m_axi_rvalid                   (S04_AXI_0_rvalid               ),
    .m_axi_rresp                    (S04_AXI_0_rresp                )
);
`endif











endmodule






