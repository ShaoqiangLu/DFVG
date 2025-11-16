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
//    Write data (from ddr) to kernel buffer in ping-pong mode
//    Read data from input kernel buffer in ping-pong mode
//
// Revision       :
// Version        Date        Author        Descriptin
// 1.0            2022-03-31  Chen Wu       Initial version
// 2.0            2023-08-25  Shaoqiang     Simulation 97 layers,and       
//                                          implementation on FPGA of U200.
// 3.0            2024-05-30  Shaoqiang     For sparsity
// -----------------------------------------------------------------------------


`include "opu_parameter.vh"
module ker_buffer # (
  parameter  DW     = 16                        ,
  parameter  NUM    = 32                          
) (
  input                         clk             ,
  input                         reset           ,
  input      [NUM* NUM    -1:0] RAM_wen0        ,
  input      [NUM* NUM    -1:0] RAM_wen1        ,
  input      [NUM*(NUM*DW)-1:0] RAM_wdata0      ,
  input      [NUM*(NUM*DW)-1:0] RAM_wdata1      ,
  output reg [NUM-1:0][DW -1:0] RAM_rdata0=0    ,
  output reg [NUM-1:0][DW -1:0] RAM_rdata1=0    ,
  input      [NUM-1:0][5  -1:0] RAM_addr_cnt0   ,
  input      [NUM-1:0][5  -1:0] RAM_addr_cnt1   ,
  input      [NUM-1:0]          RAM_addr_vld
        
);



  localparam    KER_RAM_DEEP    =32             ;
  localparam    KER_RAM_CYCLE   =2              ;
  localparam    KER_RAM_ADDR    =5              ;

  integer i=0,j=0;
  reg[DW-1:0]BUFFER0[KER_RAM_DEEP-1:0][NUM-1:0] ;
  reg[DW-1:0]BUFFER1[KER_RAM_DEEP-1:0][NUM-1:0] ;

  always @(posedge clk)
  `ifdef SIM_CODE
  if(reset)
  for(i=0;i<KER_RAM_DEEP;i=i+1)
  for(j=0;j<NUM;j=j+1)   
  BUFFER0[i][j]<=0;else
  `endif
  begin
  for(i=0;i<KER_RAM_DEEP;i=i+1)
  for(j=0;j<NUM;j=j+1)  
  if(RAM_wen0[i*NUM+j*1+:1])
      BUFFER0[i][j]<=
   RAM_wdata0[i*(NUM*DW)+j*DW+:DW];
  end


  always @(posedge clk)
  `ifdef SIM_CODE
  if(reset)
  for(i=0;i<KER_RAM_DEEP;i=i+1)
  for(j=0;j<NUM;j=j+1)   
  BUFFER1[i][j]<=0;else
  `endif
  begin
  for(i=0;i<KER_RAM_DEEP;i=i+1)
  for(j=0;j<NUM;j=j+1)  
  if(RAM_wen1[i*NUM+j*1+:1])
      BUFFER1[i][j]<=
   RAM_wdata1[i*(NUM*DW)+j*DW+:DW];
    end

//----------------------------------------------------------------
always @(posedge clk) 
for(i=0;i<NUM;i=i+1)
`ifdef SIM_CODE
if(~RAM_addr_vld[i])
begin
    RAM_rdata0[i]<=0    ;
    RAM_rdata1[i]<=0    ;
end else
`endif
begin
    RAM_rdata0[i]<=BUFFER0[i][RAM_addr_cnt0[i]];
    RAM_rdata1[i]<=BUFFER1[i][RAM_addr_cnt1[i]];
end





endmodule
