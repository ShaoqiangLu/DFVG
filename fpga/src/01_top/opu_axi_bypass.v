`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/20/2024 04:12:07 PM
// Design Name: 
// Module Name: axi_sim
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module opu_axi_bypass
#(
parameter   MID = 7,
parameter   SID = 4,
parameter   M00_START = 64'h0000_0000_0000_0000,
parameter   M01_START = 64'h0000_0004_0000_0000,
parameter   M02_START = 64'h0000_0008_0000_0000,
parameter   M03_START = 64'h0000_000C_0000_0000
)(

  input  wire           M00_ACLK_0          ,
  input  wire           M00_ARESETN_0       ,
  input  wire           M00_AXI_0_arready   ,
  output wire           M00_AXI_0_arvalid   ,
  output wire   [63:0]  M00_AXI_0_araddr    ,
  output wire   [7:0]   M00_AXI_0_arlen     ,
  output wire   [2:0]   M00_AXI_0_arsize    , 
  output wire   [1:0]   M00_AXI_0_arburst   ,
  output wire [MID-1:0] M00_AXI_0_arid      ,
  output wire   [3:0]   M00_AXI_0_arcache   ,
  output wire   [3:0]   M00_AXI_0_arqos     , 
  output wire   [3:0]   M00_AXI_0_arregion  ,
  output wire   [2:0]   M00_AXI_0_arprot    ,
  output wire           M00_AXI_0_arlock    ,
  output wire           M00_AXI_0_rready    ,
  input  wire           M00_AXI_0_rvalid    ,
  input  wire   [511:0] M00_AXI_0_rdata     ,
  input  wire [MID-1:0] M00_AXI_0_rid       ,  
  input  wire           M00_AXI_0_rlast     ,
  input  wire   [1:0]   M00_AXI_0_rresp     ,
  input  wire           M00_AXI_0_awready   ,
  output wire           M00_AXI_0_awvalid   ,
  output wire   [63:0]  M00_AXI_0_awaddr    ,
  output wire   [7:0]   M00_AXI_0_awlen     ,
  output wire   [2:0]   M00_AXI_0_awsize    , 
  output wire   [1:0]   M00_AXI_0_awburst   ,
  output wire [MID-1:0] M00_AXI_0_awid      ,
  output wire   [3:0]   M00_AXI_0_awcache   ,
  output wire   [3:0]   M00_AXI_0_awqos     ,
  output wire   [3:0]   M00_AXI_0_awregion  ,
  output wire   [2:0]   M00_AXI_0_awprot    ,
  output wire           M00_AXI_0_awlock    ,
  input  wire           M00_AXI_0_wready    ,
  output wire           M00_AXI_0_wvalid    ,
  output wire   [511:0] M00_AXI_0_wdata     ,
  output wire   [63:0]  M00_AXI_0_wstrb     ,
  output wire           M00_AXI_0_wlast     ,
  output wire           M00_AXI_0_bready    ,
  input  wire           M00_AXI_0_bvalid    ,
  input  wire [MID-1:0] M00_AXI_0_bid       ,
  input  wire   [1:0]   M00_AXI_0_bresp     ,
  //
  input  wire           M01_ACLK_0          ,
  input  wire           M01_ARESETN_0       ,
  input  wire           M01_AXI_0_arready   ,
  output wire           M01_AXI_0_arvalid   ,
  output wire   [63:0]  M01_AXI_0_araddr    ,
  output wire   [7:0]   M01_AXI_0_arlen     ,
  output wire   [2:0]   M01_AXI_0_arsize    , 
  output wire   [1:0]   M01_AXI_0_arburst   ,
  output wire [MID-1:0] M01_AXI_0_arid      ,
  output wire   [3:0]   M01_AXI_0_arcache   ,
  output wire   [3:0]   M01_AXI_0_arqos     , 
  output wire   [3:0]   M01_AXI_0_arregion  ,
  output wire   [2:0]   M01_AXI_0_arprot    ,
  output wire           M01_AXI_0_arlock    ,
  output wire           M01_AXI_0_rready    ,
  input  wire           M01_AXI_0_rvalid    ,
  input  wire   [511:0] M01_AXI_0_rdata     ,
  input  wire [MID-1:0] M01_AXI_0_rid       ,  
  input  wire           M01_AXI_0_rlast     ,
  input  wire   [1:0]   M01_AXI_0_rresp     ,
  input  wire           M01_AXI_0_awready   ,
  output wire           M01_AXI_0_awvalid   ,
  output wire   [63:0]  M01_AXI_0_awaddr    ,
  output wire   [7:0]   M01_AXI_0_awlen     ,
  output wire   [2:0]   M01_AXI_0_awsize    , 
  output wire   [1:0]   M01_AXI_0_awburst   ,
  output wire [MID-1:0] M01_AXI_0_awid      ,
  output wire   [3:0]   M01_AXI_0_awcache   ,
  output wire   [3:0]   M01_AXI_0_awqos     ,
  output wire   [3:0]   M01_AXI_0_awregion  ,
  output wire   [2:0]   M01_AXI_0_awprot    ,
  output wire           M01_AXI_0_awlock    ,
  input  wire           M01_AXI_0_wready    ,
  output wire           M01_AXI_0_wvalid    ,
  output wire   [511:0] M01_AXI_0_wdata     ,
  output wire   [63:0]  M01_AXI_0_wstrb     ,
  output wire           M01_AXI_0_wlast     ,
  output wire           M01_AXI_0_bready    ,
  input  wire           M01_AXI_0_bvalid    ,
  input  wire [MID-1:0] M01_AXI_0_bid       ,
  input  wire   [1:0]   M01_AXI_0_bresp     ,
  //
  input  wire           M02_ACLK_0          ,
  input  wire           M02_ARESETN_0       ,
  input  wire           M02_AXI_0_arready   ,
  output wire           M02_AXI_0_arvalid   ,
  output wire   [63:0]  M02_AXI_0_araddr    ,
  output wire   [7:0]   M02_AXI_0_arlen     ,
  output wire   [2:0]   M02_AXI_0_arsize    , 
  output wire   [1:0]   M02_AXI_0_arburst   ,
  output wire [MID-1:0] M02_AXI_0_arid      ,
  output wire   [3:0]   M02_AXI_0_arcache   ,
  output wire   [3:0]   M02_AXI_0_arqos     , 
  output wire   [3:0]   M02_AXI_0_arregion  ,
  output wire   [2:0]   M02_AXI_0_arprot    ,
  output wire           M02_AXI_0_arlock    ,
  output wire           M02_AXI_0_rready    ,
  input  wire           M02_AXI_0_rvalid    ,
  input  wire   [511:0] M02_AXI_0_rdata     ,
  input  wire [MID-1:0] M02_AXI_0_rid       ,  
  input  wire           M02_AXI_0_rlast     ,
  input  wire   [1:0]   M02_AXI_0_rresp     ,
  input  wire           M02_AXI_0_awready   ,
  output wire           M02_AXI_0_awvalid   ,
  output wire   [63:0]  M02_AXI_0_awaddr    ,
  output wire   [7:0]   M02_AXI_0_awlen     ,
  output wire   [2:0]   M02_AXI_0_awsize    , 
  output wire   [1:0]   M02_AXI_0_awburst   ,
  output wire [MID-1:0] M02_AXI_0_awid      ,
  output wire   [3:0]   M02_AXI_0_awcache   ,
  output wire   [3:0]   M02_AXI_0_awqos     ,
  output wire   [3:0]   M02_AXI_0_awregion  ,
  output wire   [2:0]   M02_AXI_0_awprot    ,
  output wire           M02_AXI_0_awlock    ,
  input  wire           M02_AXI_0_wready    ,
  output wire           M02_AXI_0_wvalid    ,
  output wire   [511:0] M02_AXI_0_wdata     ,
  output wire   [63:0]  M02_AXI_0_wstrb     ,
  output wire           M02_AXI_0_wlast     ,
  output wire           M02_AXI_0_bready    ,
  input  wire           M02_AXI_0_bvalid    ,
  input  wire [MID-1:0] M02_AXI_0_bid       ,
  input  wire   [1:0]   M02_AXI_0_bresp     ,  
  //
  input  wire           M03_ACLK_0          ,
  input  wire           M03_ARESETN_0       ,
  input  wire           M03_AXI_0_arready   ,
  output wire           M03_AXI_0_arvalid   ,
  output wire   [63:0]  M03_AXI_0_araddr    ,
  output wire   [7:0]   M03_AXI_0_arlen     ,
  output wire   [2:0]   M03_AXI_0_arsize    , 
  output wire   [1:0]   M03_AXI_0_arburst   ,
  output wire [MID-1:0] M03_AXI_0_arid      ,
  output wire   [3:0]   M03_AXI_0_arcache   ,
  output wire   [3:0]   M03_AXI_0_arqos     , 
  output wire   [3:0]   M03_AXI_0_arregion  ,
  output wire   [2:0]   M03_AXI_0_arprot    ,
  output wire           M03_AXI_0_arlock    ,
  output wire           M03_AXI_0_rready    ,
  input  wire           M03_AXI_0_rvalid    ,
  input  wire   [511:0] M03_AXI_0_rdata     ,
  input  wire [MID-1:0] M03_AXI_0_rid       ,  
  input  wire           M03_AXI_0_rlast     ,
  input  wire   [1:0]   M03_AXI_0_rresp     ,
  input  wire           M03_AXI_0_awready   ,
  output wire           M03_AXI_0_awvalid   ,
  output wire   [63:0]  M03_AXI_0_awaddr    ,
  output wire   [7:0]   M03_AXI_0_awlen     ,
  output wire   [2:0]   M03_AXI_0_awsize    , 
  output wire   [1:0]   M03_AXI_0_awburst   ,
  output wire [MID-1:0] M03_AXI_0_awid      ,
  output wire   [3:0]   M03_AXI_0_awcache   ,
  output wire   [3:0]   M03_AXI_0_awqos     ,
  output wire   [3:0]   M03_AXI_0_awregion  ,
  output wire   [2:0]   M03_AXI_0_awprot    ,
  output wire           M03_AXI_0_awlock    ,
  input  wire           M03_AXI_0_wready    ,
  output wire           M03_AXI_0_wvalid    ,
  output wire   [511:0] M03_AXI_0_wdata     ,
  output wire   [63:0]  M03_AXI_0_wstrb     ,
  output wire           M03_AXI_0_wlast     ,
  output wire           M03_AXI_0_bready    ,
  input  wire           M03_AXI_0_bvalid    ,
  input  wire [MID-1:0] M03_AXI_0_bid       ,
  input  wire   [1:0]   M03_AXI_0_bresp     , 
//-------------------------------------------
  input  wire           S00_ACLK_0          ,
  input  wire           S00_ARESETN_0       ,
  output reg            S00_AXI_0_arready   =0,
  input  wire           S00_AXI_0_arvalid   ,
  input  wire   [63:0]  S00_AXI_0_araddr    ,
  input  wire   [7:0]   S00_AXI_0_arlen     ,
  input  wire   [2:0]   S00_AXI_0_arsize    ,
  input  wire   [1:0]   S00_AXI_0_arburst   ,
  input  wire [SID-1:0] S00_AXI_0_arid      ,
  input  wire   [3:0]   S00_AXI_0_arcache   ,
  input  wire   [3:0]   S00_AXI_0_arqos     ,
  input  wire   [3:0]   S00_AXI_0_arregion  ,
  input  wire   [2:0]   S00_AXI_0_arprot    ,
  input  wire           S00_AXI_0_arlock    ,
  input  wire           S00_AXI_0_rready    ,
  output reg            S00_AXI_0_rvalid    =0,
  output reg    [511:0] S00_AXI_0_rdata     =0,
  output reg            S00_AXI_0_rlast     =0,
  output reg  [SID-1:0] S00_AXI_0_rid       =0,
  output reg    [1:0]   S00_AXI_0_rresp     =0,
  output reg            S00_AXI_0_awready   =0,
  input  wire           S00_AXI_0_awvalid   ,
  input  wire   [63:0]  S00_AXI_0_awaddr    ,
  input  wire   [7:0]   S00_AXI_0_awlen     ,
  input  wire   [2:0]   S00_AXI_0_awsize    ,
  input  wire   [1:0]   S00_AXI_0_awburst   ,
  input  wire [SID-1:0] S00_AXI_0_awid      ,
  input  wire   [3:0]   S00_AXI_0_awcache   ,
  input  wire   [3:0]   S00_AXI_0_awqos     ,
  input  wire   [3:0]   S00_AXI_0_awregion  ,
  input  wire   [2:0]   S00_AXI_0_awprot    ,
  input  wire           S00_AXI_0_awlock    ,
  output reg            S00_AXI_0_wready    =0,
  input  wire           S00_AXI_0_wvalid    ,
  input  wire   [511:0] S00_AXI_0_wdata     ,
  input  wire   [63:0]  S00_AXI_0_wstrb     ,
  input  wire           S00_AXI_0_wlast     ,
  input  wire           S00_AXI_0_bready    ,
  output reg            S00_AXI_0_bvalid    =0,
  output reg  [SID-1:0] S00_AXI_0_bid       =0,
  output reg    [1:0]   S00_AXI_0_bresp     =0,
  //


  output wire           S01_AXI_0_arready   ,
  input  wire           S01_AXI_0_arvalid   ,
  input  wire   [63:0]  S01_AXI_0_araddr    ,
  input  wire   [7:0]   S01_AXI_0_arlen     ,
  input  wire   [2:0]   S01_AXI_0_arsize    ,
  input  wire   [1:0]   S01_AXI_0_arburst   ,
  input  wire [SID-1:0] S01_AXI_0_arid      ,
  input  wire   [3:0]   S01_AXI_0_arcache   ,
  input  wire   [3:0]   S01_AXI_0_arqos     ,
  input  wire   [3:0]   S01_AXI_0_arregion  ,
  input  wire   [2:0]   S01_AXI_0_arprot    ,
  input  wire           S01_AXI_0_arlock    ,
  input  wire           S01_AXI_0_rready    ,
  output wire           S01_AXI_0_rvalid    ,
  output wire   [511:0] S01_AXI_0_rdata     ,
  output wire           S01_AXI_0_rlast     ,
  output wire [SID-1:0] S01_AXI_0_rid       ,
  output wire   [1:0]   S01_AXI_0_rresp     ,
  output wire           S01_AXI_0_awready   ,
  input  wire           S01_AXI_0_awvalid   ,
  input  wire   [63:0]  S01_AXI_0_awaddr    ,
  input  wire   [7:0]   S01_AXI_0_awlen     ,
  input  wire   [2:0]   S01_AXI_0_awsize    ,
  input  wire   [1:0]   S01_AXI_0_awburst   ,
  input  wire [SID-1:0] S01_AXI_0_awid      ,
  input  wire   [3:0]   S01_AXI_0_awcache   ,
  input  wire   [3:0]   S01_AXI_0_awqos     ,
  input  wire   [3:0]   S01_AXI_0_awregion  ,
  input  wire   [2:0]   S01_AXI_0_awprot    ,
  input  wire           S01_AXI_0_awlock    ,
  output wire           S01_AXI_0_wready    ,
  input  wire           S01_AXI_0_wvalid    ,
  input  wire   [511:0] S01_AXI_0_wdata     ,
  input  wire   [63:0]  S01_AXI_0_wstrb     ,
  input  wire           S01_AXI_0_wlast     ,
  input  wire           S01_AXI_0_bready    ,
  output wire           S01_AXI_0_bvalid    ,
  output wire [SID-1:0] S01_AXI_0_bid       ,
  output wire   [1:0]   S01_AXI_0_bresp     ,
  //

  output reg            S02_AXI_0_arready   =0,
  input  wire           S02_AXI_0_arvalid   ,
  input  wire   [63:0]  S02_AXI_0_araddr    ,
  input  wire   [7:0]   S02_AXI_0_arlen     ,
  input  wire   [2:0]   S02_AXI_0_arsize    ,
  input  wire   [1:0]   S02_AXI_0_arburst   ,
  input  wire [SID-1:0] S02_AXI_0_arid      ,
  input  wire   [3:0]   S02_AXI_0_arcache   ,
  input  wire   [3:0]   S02_AXI_0_arqos     ,
  input  wire   [3:0]   S02_AXI_0_arregion  ,
  input  wire   [2:0]   S02_AXI_0_arprot    ,
  input  wire           S02_AXI_0_arlock    ,
  input  wire           S02_AXI_0_rready    ,
  output reg            S02_AXI_0_rvalid    =0,
  output reg    [511:0] S02_AXI_0_rdata     =0,
  output reg            S02_AXI_0_rlast     =0,
  output reg  [SID-1:0] S02_AXI_0_rid       =0,
  output reg    [1:0]   S02_AXI_0_rresp     =0,
  output wire           S02_AXI_0_awready   ,
  input  wire           S02_AXI_0_awvalid   ,
  input  wire   [63:0]  S02_AXI_0_awaddr    ,
  input  wire   [7:0]   S02_AXI_0_awlen     ,
  input  wire   [2:0]   S02_AXI_0_awsize    ,
  input  wire   [1:0]   S02_AXI_0_awburst   ,
  input  wire [SID-1:0] S02_AXI_0_awid      ,
  input  wire   [3:0]   S02_AXI_0_awcache   ,
  input  wire   [3:0]   S02_AXI_0_awqos     ,
  input  wire   [3:0]   S02_AXI_0_awregion  ,
  input  wire   [2:0]   S02_AXI_0_awprot    ,
  input  wire           S02_AXI_0_awlock    ,
  output wire           S02_AXI_0_wready    ,
  input  wire           S02_AXI_0_wvalid    ,
  input  wire   [511:0] S02_AXI_0_wdata     ,
  input  wire   [63:0]  S02_AXI_0_wstrb     ,
  input  wire           S02_AXI_0_wlast     ,
  input  wire           S02_AXI_0_bready    ,
  output wire           S02_AXI_0_bvalid    ,
  output wire [SID-1:0] S02_AXI_0_bid       ,
  output wire   [1:0]   S02_AXI_0_bresp     ,
  //
  output reg            S03_AXI_0_arready   =0,
  input  wire           S03_AXI_0_arvalid   ,
  input  wire   [63:0]  S03_AXI_0_araddr    ,
  input  wire   [7:0]   S03_AXI_0_arlen     ,
  input  wire   [2:0]   S03_AXI_0_arsize    ,
  input  wire   [1:0]   S03_AXI_0_arburst   ,
  input  wire [SID-1:0] S03_AXI_0_arid      ,
  input  wire   [3:0]   S03_AXI_0_arcache   ,
  input  wire   [3:0]   S03_AXI_0_arqos     ,
  input  wire   [3:0]   S03_AXI_0_arregion  ,
  input  wire   [2:0]   S03_AXI_0_arprot    ,
  input  wire           S03_AXI_0_arlock    ,
  input  wire           S03_AXI_0_rready    ,
  output reg            S03_AXI_0_rvalid    =0,
  output reg    [511:0] S03_AXI_0_rdata     =0,
  output reg            S03_AXI_0_rlast     =0,
  output reg  [SID-1:0] S03_AXI_0_rid       =0,
  output reg    [1:0]   S03_AXI_0_rresp     =0,
  output wire           S03_AXI_0_awready   ,
  input  wire           S03_AXI_0_awvalid   ,
  input  wire   [63:0]  S03_AXI_0_awaddr    ,
  input  wire   [7:0]   S03_AXI_0_awlen     ,
  input  wire   [2:0]   S03_AXI_0_awsize    ,
  input  wire   [1:0]   S03_AXI_0_awburst   ,
  input  wire [SID-1:0] S03_AXI_0_awid      ,
  input  wire   [3:0]   S03_AXI_0_awcache   ,
  input  wire   [3:0]   S03_AXI_0_awqos     ,
  input  wire   [3:0]   S03_AXI_0_awregion  ,
  input  wire   [2:0]   S03_AXI_0_awprot    ,
  input  wire           S03_AXI_0_awlock    ,
  output wire           S03_AXI_0_wready    ,
  input  wire           S03_AXI_0_wvalid    ,
  input  wire   [511:0] S03_AXI_0_wdata     ,
  input  wire   [63:0]  S03_AXI_0_wstrb     ,
  input  wire           S03_AXI_0_wlast     ,
  input  wire           S03_AXI_0_bready    ,
  output wire           S03_AXI_0_bvalid    ,
  output wire [SID-1:0] S03_AXI_0_bid       ,
  output wire   [1:0]   S03_AXI_0_bresp     ,
  //
  output reg            S04_AXI_0_arready   =0,
  input  wire           S04_AXI_0_arvalid   ,
  input  wire   [63:0]  S04_AXI_0_araddr    ,
  input  wire   [7:0]   S04_AXI_0_arlen     ,
  input  wire   [2:0]   S04_AXI_0_arsize    ,
  input  wire   [1:0]   S04_AXI_0_arburst   ,
  input  wire [SID-1:0] S04_AXI_0_arid      ,
  input  wire   [3:0]   S04_AXI_0_arcache   ,
  input  wire   [3:0]   S04_AXI_0_arqos     ,
  input  wire   [3:0]   S04_AXI_0_arregion  ,
  input  wire   [2:0]   S04_AXI_0_arprot    ,
  input  wire           S04_AXI_0_arlock    ,
  input  wire           S04_AXI_0_rready    ,
  output reg            S04_AXI_0_rvalid    =0,
  output reg    [511:0] S04_AXI_0_rdata     =0,
  output reg            S04_AXI_0_rlast     =0,
  output reg  [SID-1:0] S04_AXI_0_rid       =0,
  output reg    [1:0]   S04_AXI_0_rresp     =0,
  output wire           S04_AXI_0_awready   ,
  input  wire           S04_AXI_0_awvalid   ,
  input  wire   [63:0]  S04_AXI_0_awaddr    ,
  input  wire   [7:0]   S04_AXI_0_awlen     ,
  input  wire   [2:0]   S04_AXI_0_awsize    ,
  input  wire   [1:0]   S04_AXI_0_awburst   ,
  input  wire [SID-1:0] S04_AXI_0_awid      ,
  input  wire   [3:0]   S04_AXI_0_awcache   ,
  input  wire   [3:0]   S04_AXI_0_awqos     ,
  input  wire   [3:0]   S04_AXI_0_awregion  ,
  input  wire   [2:0]   S04_AXI_0_awprot    ,
  input  wire           S04_AXI_0_awlock    ,
  output wire           S04_AXI_0_wready    ,
  input  wire           S04_AXI_0_wvalid    ,
  input  wire   [511:0] S04_AXI_0_wdata     ,
  input  wire   [63:0]  S04_AXI_0_wstrb     ,
  input  wire           S04_AXI_0_wlast     ,
  input  wire           S04_AXI_0_bready    ,
  output wire           S04_AXI_0_bvalid    ,
  output wire [SID-1:0] S04_AXI_0_bid       ,
  output wire   [1:0]   S04_AXI_0_bresp     
);


localparam   M00_END = M00_START+64'h0000_0003_FFFF_FFFF;
localparam   M01_END = M01_START+64'h0000_0003_FFFF_FFFF;
localparam   M02_END = M02_START+64'h0000_0003_FFFF_FFFF;
localparam   M03_END = M03_START+64'h0000_0003_FFFF_FFFF;




wire              S01_M00_arvld     =S01_AXI_0_arvalid&&(S01_AXI_0_araddr>=M00_START && S01_AXI_0_araddr<=M00_END);
reg               S01_M00_runing    =0  ;
wire              S01_M01_arvld     =S01_AXI_0_arvalid&&(S01_AXI_0_araddr>=M01_START && S01_AXI_0_araddr<=M01_END);
reg               S01_M01_runing    =0  ;
wire              S01_M02_arvld     =S01_AXI_0_arvalid&&(S01_AXI_0_araddr>=M02_START && S01_AXI_0_araddr<=M02_END);
reg               S01_M02_runing    =0  ;
wire              S01_M03_arvld     =S01_AXI_0_arvalid&&(S01_AXI_0_araddr>=M03_START && S01_AXI_0_araddr<=M03_END);
reg               S01_M03_runing    =0  ;

always @ (posedge S01_M00_arvld or negedge   M00_AXI_0_rlast)
               if(S01_M00_arvld)
                  S01_M00_runing<=1;else if(!M00_AXI_0_rlast)
                  S01_M00_runing<=0;

always @ (posedge S01_M01_arvld or negedge   M01_AXI_0_rlast)
               if(S01_M01_arvld)
                  S01_M01_runing<=1;else if(!M01_AXI_0_rlast)
                  S01_M01_runing<=0;

always @ (posedge S01_M02_arvld or negedge   M02_AXI_0_rlast)
               if(S01_M02_arvld)
                  S01_M02_runing<=1;else if(!M02_AXI_0_rlast)
                  S01_M02_runing<=0;

always @ (posedge S01_M03_arvld or negedge   M03_AXI_0_rlast)
               if(S01_M03_arvld)
                  S01_M03_runing<=1;else if(!M03_AXI_0_rlast)
                  S01_M03_runing<=0;

  assign  S01_AXI_0_arready = 1'b1;//
  assign  M00_AXI_0_arvalid = S01_M00_arvld?                   S01_AXI_0_arvalid :0 ;
  assign  M00_AXI_0_araddr  = S01_M00_arvld?                   S01_AXI_0_araddr  :0 ;
  assign  M00_AXI_0_arlen   = S01_M00_arvld?                   S01_AXI_0_arlen   :0 ;
  assign  M00_AXI_0_arsize  = S01_M00_arvld?                   S01_AXI_0_arsize  :0 ; 
  assign  M00_AXI_0_arburst = S01_M00_arvld?                   S01_AXI_0_arburst :0 ;
  assign  M00_AXI_0_arid    = S01_M00_arvld?{{(MID-SID){1'b0}},S01_AXI_0_arid}   :0 ;
  assign  M00_AXI_0_arcache =0 ;
  assign  M00_AXI_0_arqos   =0 ; 
  assign  M00_AXI_0_arregion=0 ;
  assign  M00_AXI_0_arprot  =0 ;
  assign  M00_AXI_0_arlock  =0 ;

  assign  M01_AXI_0_arvalid = S01_M01_arvld?                   S01_AXI_0_arvalid :0 ;
  assign  M01_AXI_0_araddr  = S01_M01_arvld?                   S01_AXI_0_araddr  :0 ;
  assign  M01_AXI_0_arlen   = S01_M01_arvld?                   S01_AXI_0_arlen   :0 ;
  assign  M01_AXI_0_arsize  = S01_M01_arvld?                   S01_AXI_0_arsize  :0 ; 
  assign  M01_AXI_0_arburst = S01_M01_arvld?                   S01_AXI_0_arburst :0 ;
  assign  M01_AXI_0_arid    = S01_M01_arvld?{{(MID-SID){1'b0}},S01_AXI_0_arid}   :0 ;
  assign  M01_AXI_0_arcache =0 ;
  assign  M01_AXI_0_arqos   =0 ; 
  assign  M01_AXI_0_arregion=0 ;
  assign  M01_AXI_0_arprot  =0 ;
  assign  M01_AXI_0_arlock  =0 ;

  assign  M02_AXI_0_arvalid = S01_M02_arvld?                   S01_AXI_0_arvalid :0 ;
  assign  M02_AXI_0_araddr  = S01_M02_arvld?                   S01_AXI_0_araddr  :0 ;
  assign  M02_AXI_0_arlen   = S01_M02_arvld?                   S01_AXI_0_arlen   :0 ;
  assign  M02_AXI_0_arsize  = S01_M02_arvld?                   S01_AXI_0_arsize  :0 ; 
  assign  M02_AXI_0_arburst = S01_M02_arvld?                   S01_AXI_0_arburst :0 ;
  assign  M02_AXI_0_arid    = S01_M02_arvld?                   S01_AXI_0_arid    :0 ;
  assign  M02_AXI_0_arcache =0 ;
  assign  M02_AXI_0_arqos   =0 ; 
  assign  M02_AXI_0_arregion=0 ;
  assign  M02_AXI_0_arprot  =0 ;
  assign  M02_AXI_0_arlock  =0 ;

  assign  M03_AXI_0_arvalid = S01_M03_arvld?                   S01_AXI_0_arvalid :0 ;
  assign  M03_AXI_0_araddr  = S01_M03_arvld?                   S01_AXI_0_araddr  :0 ;
  assign  M03_AXI_0_arlen   = S01_M03_arvld?                   S01_AXI_0_arlen   :0 ;
  assign  M03_AXI_0_arsize  = S01_M03_arvld?                   S01_AXI_0_arsize  :0 ; 
  assign  M03_AXI_0_arburst = S01_M03_arvld?                   S01_AXI_0_arburst :0 ;
  assign  M03_AXI_0_arid    = S01_M03_arvld?                   S01_AXI_0_arid    :0 ;
  assign  M03_AXI_0_arcache =0 ;
  assign  M03_AXI_0_arqos   =0 ; 
  assign  M03_AXI_0_arregion=0 ;
  assign  M03_AXI_0_arprot  =0 ;
  assign  M03_AXI_0_arlock  =0 ;


//----------------------------------------------------------------------------------
  assign  M00_AXI_0_rready =1'b1;
  assign  M01_AXI_0_rready =1'b1;
  assign  M02_AXI_0_rready =1'b1;
  assign  M03_AXI_0_rready =1'b1;

  assign  S01_AXI_0_rvalid =S01_M00_runing?M00_AXI_0_rvalid : S01_M01_runing?M01_AXI_0_rvalid :S01_M02_runing?M02_AXI_0_rvalid :S01_M03_runing?M03_AXI_0_rvalid :0;
  assign  S01_AXI_0_rdata  =S01_M00_runing?M00_AXI_0_rdata  : S01_M01_runing?M01_AXI_0_rdata  :S01_M02_runing?M02_AXI_0_rdata  :S01_M03_runing?M03_AXI_0_rdata  :0;
  assign  S01_AXI_0_rid    =S01_M00_runing?M00_AXI_0_rid    : S01_M01_runing?M01_AXI_0_rid    :S01_M02_runing?M02_AXI_0_rid    :S01_M03_runing?M03_AXI_0_rid    :0;
  assign  S01_AXI_0_rlast  =S01_M00_runing?M00_AXI_0_rlast  : S01_M01_runing?M01_AXI_0_rlast  :S01_M02_runing?M02_AXI_0_rlast  :S01_M03_runing?M03_AXI_0_rlast  :0;
  assign  S01_AXI_0_rresp  =S01_M00_runing?M00_AXI_0_rresp  : S01_M01_runing?M01_AXI_0_rresp  :S01_M02_runing?M02_AXI_0_rresp  :S01_M03_runing?M03_AXI_0_rresp  :0;

  //--------------------------------------------------------
  // write
  //--------------------------------------------------------
  assign  M00_AXI_0_awvalid  =                    S01_AXI_0_awvalid   ;
  assign  M00_AXI_0_awaddr   =                    S01_AXI_0_awaddr    ;
  assign  M00_AXI_0_awlen    =                    S01_AXI_0_awlen     ;
  assign  M00_AXI_0_awsize   =                    S01_AXI_0_awsize    ;    
  assign  M00_AXI_0_awburst  =                    S01_AXI_0_awburst   ;
  assign  M00_AXI_0_awid     = {{(MID-SID){1'b0}},S01_AXI_0_awid}     ;
  assign  M00_AXI_0_awcache  =                    S01_AXI_0_awcache   ;
  assign  M00_AXI_0_awlock   =                    S01_AXI_0_awlock    ;
  assign  M00_AXI_0_awprot   =                    S01_AXI_0_awprot    ;
  assign  M00_AXI_0_awqos    =                    S01_AXI_0_awqos     ;
  assign  M00_AXI_0_awregion =                    S01_AXI_0_awregion  ;
  assign  M00_AXI_0_wvalid   =                    S01_AXI_0_wvalid    ;
  assign  M00_AXI_0_wdata    =                    S01_AXI_0_wdata     ;
  assign  M00_AXI_0_wlast    =                    S01_AXI_0_wlast     ;
  assign  M00_AXI_0_wstrb    =                    S01_AXI_0_wstrb     ;  
  assign  M00_AXI_0_bready   =                    S01_AXI_0_bready    ;
  assign  S01_AXI_0_awready  =                    M00_AXI_0_awready   ;
  assign  S01_AXI_0_wready   =                    M00_AXI_0_wready    ;
  assign  S01_AXI_0_bvalid   =                    M00_AXI_0_bvalid    ;  
  assign  S01_AXI_0_bid      =                    M00_AXI_0_bid[2:0]  ;
  assign  S01_AXI_0_bresp    =                    M00_AXI_0_bresp     ; 

  assign  M01_AXI_0_awvalid  =                    S02_AXI_0_awvalid   ;
  assign  M01_AXI_0_awaddr   =                    S02_AXI_0_awaddr    ;
  assign  M01_AXI_0_awlen    =                    S02_AXI_0_awlen     ;
  assign  M01_AXI_0_awsize   =                    S02_AXI_0_awsize    ;    
  assign  M01_AXI_0_awburst  =                    S02_AXI_0_awburst   ;
  assign  M01_AXI_0_awid     = {{(MID-SID){1'b0}},S02_AXI_0_awid}     ;
  assign  M01_AXI_0_awcache  =                    S02_AXI_0_awcache   ;
  assign  M01_AXI_0_awlock   =                    S02_AXI_0_awlock    ;
  assign  M01_AXI_0_awprot   =                    S02_AXI_0_awprot    ;
  assign  M01_AXI_0_awqos    =                    S02_AXI_0_awqos     ;
  assign  M01_AXI_0_awregion =                    S02_AXI_0_awregion  ;
  assign  M01_AXI_0_wvalid   =                    S02_AXI_0_wvalid    ;
  assign  M01_AXI_0_wdata    =                    S02_AXI_0_wdata     ;
  assign  M01_AXI_0_wlast    =                    S02_AXI_0_wlast     ;
  assign  M01_AXI_0_wstrb    =                    S02_AXI_0_wstrb     ;  
  assign  M01_AXI_0_bready   =                    S02_AXI_0_bready    ;
  assign  S02_AXI_0_awready  =                    M01_AXI_0_awready   ;
  assign  S02_AXI_0_wready   =                    M01_AXI_0_wready    ;
  assign  S02_AXI_0_bvalid   =                    M01_AXI_0_bvalid    ;  
  assign  S02_AXI_0_bid      =                    M01_AXI_0_bid[2:0]  ;
  assign  S02_AXI_0_bresp    =                    M01_AXI_0_bresp     ; 

  assign  M02_AXI_0_awvalid  =                    S03_AXI_0_awvalid   ;
  assign  M02_AXI_0_awaddr   =                    S03_AXI_0_awaddr    ;
  assign  M02_AXI_0_awlen    =                    S03_AXI_0_awlen     ;
  assign  M02_AXI_0_awsize   =                    S03_AXI_0_awsize    ;    
  assign  M02_AXI_0_awburst  =                    S03_AXI_0_awburst   ;
  assign  M02_AXI_0_awid     = {{(MID-SID){1'b0}},S03_AXI_0_awid}     ;
  assign  M02_AXI_0_awcache  =                    S03_AXI_0_awcache   ;
  assign  M02_AXI_0_awlock   =                    S03_AXI_0_awlock    ;
  assign  M02_AXI_0_awprot   =                    S03_AXI_0_awprot    ;
  assign  M02_AXI_0_awqos    =                    S03_AXI_0_awqos     ;
  assign  M02_AXI_0_awregion =                    S03_AXI_0_awregion  ;
  assign  M02_AXI_0_wvalid   =                    S03_AXI_0_wvalid    ;
  assign  M02_AXI_0_wdata    =                    S03_AXI_0_wdata     ;
  assign  M02_AXI_0_wlast    =                    S03_AXI_0_wlast     ;
  assign  M02_AXI_0_wstrb    =                    S03_AXI_0_wstrb     ;  
  assign  M02_AXI_0_bready   =                    S03_AXI_0_bready    ;
  assign  S03_AXI_0_awready  =                    M02_AXI_0_awready   ;
  assign  S03_AXI_0_wready   =                    M02_AXI_0_wready    ;
  assign  S03_AXI_0_bvalid   =                    M02_AXI_0_bvalid    ;  
  assign  S03_AXI_0_bid      =                    M02_AXI_0_bid[2:0]  ;
  assign  S03_AXI_0_bresp    =                    M02_AXI_0_bresp     ; 

  assign  M03_AXI_0_awvalid  =                    S04_AXI_0_awvalid   ;
  assign  M03_AXI_0_awaddr   =                    S04_AXI_0_awaddr    ;
  assign  M03_AXI_0_awlen    =                    S04_AXI_0_awlen     ;
  assign  M03_AXI_0_awsize   =                    S04_AXI_0_awsize    ;    
  assign  M03_AXI_0_awburst  =                    S04_AXI_0_awburst   ;
  assign  M03_AXI_0_awid     = {{(MID-SID){1'b0}},S04_AXI_0_awid}     ;
  assign  M03_AXI_0_awcache  =                    S04_AXI_0_awcache   ;
  assign  M03_AXI_0_awlock   =                    S04_AXI_0_awlock    ;
  assign  M03_AXI_0_awprot   =                    S04_AXI_0_awprot    ;
  assign  M03_AXI_0_awqos    =                    S04_AXI_0_awqos     ;
  assign  M03_AXI_0_awregion =                    S04_AXI_0_awregion  ;
  assign  M03_AXI_0_wvalid   =                    S04_AXI_0_wvalid    ;
  assign  M03_AXI_0_wdata    =                    S04_AXI_0_wdata     ;
  assign  M03_AXI_0_wlast    =                    S04_AXI_0_wlast     ;
  assign  M03_AXI_0_wstrb    =                    S04_AXI_0_wstrb     ;  
  assign  M03_AXI_0_bready   =                    S04_AXI_0_bready    ;
  assign  S04_AXI_0_awready  =                    M03_AXI_0_awready   ;
  assign  S04_AXI_0_wready   =                    M03_AXI_0_wready    ;
  assign  S04_AXI_0_bvalid   =                    M03_AXI_0_bvalid    ;  
  assign  S04_AXI_0_bid      =                    M03_AXI_0_bid[2:0]  ;
  assign  S04_AXI_0_bresp    =                    M03_AXI_0_bresp     ; 



endmodule
