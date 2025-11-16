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

//`define OFM_PARAMETER
`include "opu_parameter.vh"

module bias_read # (
  parameter     NUM = 32          ,
  parameter     DW  = 16          ,
  parameter     PNUM= 4           ,
  parameter     BDW = 32          ,
  parameter     CYCLE_NUM = 4     
) (
  input                                     clk               ,
  input                                     reset             ,
  input                                     bias_pp           ,
  input         [CYCLE_NUM*NUM-1:0][DW-1:0] bias_rdata0       ,
  input         [CYCLE_NUM*NUM-1:0][DW-1:0] bias_rdata1       ,
  output  reg   [CYCLE_NUM*NUM*DW*2 -1:0]   bias_rdata =0                
);

  integer i=0,j=0;
  localparam OFM_DLY_BIAS  = `OFM_DLY_BIAS;
  

  
  (*max_fanout=32*)reg [8-1:0]r0_bias_pp=0;
  (*max_fanout=32*)reg [CYCLE_NUM*NUM-1:0]r1_bias_pp=0;
  always @(posedge clk)
  begin
      r0_bias_pp<={8{bias_pp}};
      r1_bias_pp<={16{r0_bias_pp}};
  end
  


 
  (*ram_style="distributed"*)
  reg[(CYCLE_NUM*NUM*DW)*OFM_DLY_BIAS-1:0]BUFFER=0;

  always @(posedge clk)
  for(i=0;i<OFM_DLY_BIAS;i=i+1)
  if(i==0)begin
  for(j=0;j<(CYCLE_NUM*NUM);j=j+1)//128
  if(r1_bias_pp[j])BUFFER[ i   *(CYCLE_NUM*NUM*DW)+j*DW+:DW]<=bias_rdata0[j];
  else             BUFFER[ i   *(CYCLE_NUM*NUM*DW)+j*DW+:DW]<=bias_rdata1[j];
  end else         BUFFER[ i   *(CYCLE_NUM*NUM*DW)+:(CYCLE_NUM*NUM*DW)]<=
                   BUFFER[(i-1)*(CYCLE_NUM*NUM*DW)+:(CYCLE_NUM*NUM*DW)]     ;
  
  always @(posedge clk)
  bias_rdata<={2{BUFFER[(OFM_DLY_BIAS-1)*(CYCLE_NUM*NUM*DW)+:(CYCLE_NUM*NUM*DW)]}};






endmodule
