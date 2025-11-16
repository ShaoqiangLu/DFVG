`timescale 1ns / 1ps
// -----------------------------------------------------------------------------
// Copyright      : UCLA EDA LAB
// -----------------------------------------------------------------------------
// Engineer       : Chen Wu
// Design Name    : opu series
// Module Name    : ifm_top
// Target Devices : 325t, Alveo U200
// Tool Versions  : Vivado 2020.1, Modelsim 2019.4
// Description    : 
//    Write data (from ddr) to bias buffer in ping-pong mode
//    Read data from input bias buffer in ping-pong mode
//
// Revision       :
// Version        Date        Author        Descriptin
// 1.0            2022-03-31  Chen Wu       Initial version
// 2.0            2023-08-25  Shaoqiang     Simulation 97 layers,and       
//                                          implementation on FPGA of U200.
// -----------------------------------------------------------------------------

module bias_write # (
  parameter                           NUM = 32                      ,
  parameter                           DW  = 16                      ,
  parameter                           CYCLE_NUM = 4                 
) (
  input                               clk                           ,
  input                               reset                         ,
  input                               bias_wstart                   ,
  input           [NUM*DW-1 : 0]      bias_wdata                    ,
  input                               bias_wvld                     ,
  input                               bias_pp                       ,
  output  reg     [CYCLE_NUM-1:0]     bias_wen0=0                   ,
  output  reg     [CYCLE_NUM-1:0]     bias_wen1=0                   ,
  output  wire [CYCLE_NUM*NUM*DW-1:0] bias_wdata0                   ,
  output  wire [CYCLE_NUM*NUM*DW-1:0] bias_wdata1                   

);

  integer i=0,j=0;
  reg                       [2-1:0]                 bias_wcnt=0     ;
  wire                      [  NUM*DW-1:0]          bias_wdata_in   ;
  (*dont_touch="true"*)reg  [2*NUM*DW-1:0]          r_bias_wdata0=0 ;
  (*dont_touch="true"*)reg  [2*NUM*DW-1:0]          r_bias_wdata1=0 ;

  always @(posedge clk)
  if (bias_wstart)      bias_wcnt     <=       0                    ;
  else if (bias_wvld )  bias_wcnt     <=    bias_wcnt+1             ;
  
  always @(posedge clk)
  for(i=0;i<CYCLE_NUM;i=i+1)
  begin
      bias_wen0[i]<=(~bias_pp)&&bias_wvld&&(bias_wcnt==i);
      bias_wen1[i]<=( bias_pp)&&bias_wvld&&(bias_wcnt==i);
  end

  assign bias_wdata_in={
   bias_wdata[15*32+0+:16],bias_wdata[15*32+16+:16],
   bias_wdata[14*32+0+:16],bias_wdata[14*32+16+:16],
   bias_wdata[13*32+0+:16],bias_wdata[13*32+16+:16],
   bias_wdata[12*32+0+:16],bias_wdata[12*32+16+:16],
   bias_wdata[11*32+0+:16],bias_wdata[11*32+16+:16],
   bias_wdata[10*32+0+:16],bias_wdata[10*32+16+:16],
   bias_wdata[ 9*32+0+:16],bias_wdata[ 9*32+16+:16],
   bias_wdata[ 8*32+0+:16],bias_wdata[ 8*32+16+:16],
   bias_wdata[ 7*32+0+:16],bias_wdata[ 7*32+16+:16],
   bias_wdata[ 6*32+0+:16],bias_wdata[ 6*32+16+:16],
   bias_wdata[ 5*32+0+:16],bias_wdata[ 5*32+16+:16],
   bias_wdata[ 4*32+0+:16],bias_wdata[ 4*32+16+:16],
   bias_wdata[ 3*32+0+:16],bias_wdata[ 3*32+16+:16],
   bias_wdata[ 2*32+0+:16],bias_wdata[ 2*32+16+:16],
   bias_wdata[ 1*32+0+:16],bias_wdata[ 1*32+16+:16],
   bias_wdata[ 0*32+0+:16],bias_wdata[ 0*32+16+:16]};




  always @(posedge clk)
  begin
      r_bias_wdata0<={2{bias_wdata}};
      r_bias_wdata1<={2{bias_wdata}};
  end
  
  assign bias_wdata0={2{r_bias_wdata0}};
  assign bias_wdata1={2{r_bias_wdata1}};


endmodule
