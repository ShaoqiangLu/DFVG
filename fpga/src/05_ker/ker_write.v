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


module ker_write # (
  parameter   DW                            = 16                ,
  parameter   NUM                           = 32                ,
  parameter   KER_RAM_DEEP                  = 32             
) (
  input                                     clk                 ,
  input                                     reset               ,
  input                                     ker_wstart          ,
  input       [2-1:0][NUM*DW-1:0]           ker_wdata           ,
  input       [2-1:0]                       ker_wvld            ,
  input                                     ker_pp              ,
  output wire [KER_RAM_DEEP*(NUM*DW)-1:0]   RAM_wdata0          ,
  output wire [KER_RAM_DEEP*(NUM*DW)-1:0]   RAM_wdata1          ,
  output wire [KER_RAM_DEEP* NUM-1:0]       RAM_wen0            ,
  output wire [KER_RAM_DEEP* NUM-1:0]       RAM_wen1                    
);

  integer i=0;
  //-------------------------------------------------------------------------
  //Write
  //-------------------------------------------------------------------------
  (*dont_touch="true"*)reg                                    [2-1:0]                w_wait   =0;
  (*dont_touch="true"*)reg                                    [2-1:0]                w_ker_pp =0;
  (*dont_touch="true",max_fanout=16*)reg                      [4*NUM*DW-1:0]         w0_wdata =0;
  (*dont_touch="true",max_fanout=16*)reg                      [4*NUM*DW-1:0]         w1_wdata =0;
  (*dont_touch="true",extract_enable="yes",max_fanout=16*)reg [KER_RAM_DEEP*NUM-1:0] w0_wen   =0;
  (*dont_touch="true",extract_enable="yes",max_fanout=16*)reg [KER_RAM_DEEP*NUM-1:0] w1_wen   =0;

  always @(posedge clk)
  if(ker_wstart)       w_wait  <={2{1'b1}}       ;
  else if(ker_wvld[0]) w_wait  <=0               ;
  always @(posedge clk)w_ker_pp<={ker_pp,~ker_pp};

  always @(posedge clk)
  for(i=0;i<KER_RAM_DEEP;i=i+1)
  if( i==0) w0_wen[i*NUM+:NUM]<={NUM{w_wait[0]&ker_wvld[0]&w_ker_pp[0]}};
  else      w0_wen[i*NUM+:NUM]<=w0_wen[(i-1)*NUM+:NUM]                  ;

  always @(posedge clk)
  for(i=0;i<KER_RAM_DEEP;i=i+1)
  if( i==0) w1_wen[i*NUM+:NUM]<={NUM{w_wait[1]&ker_wvld[0]&w_ker_pp[1]}};
  else      w1_wen[i*NUM+:NUM]<=w1_wen[(i-1)*NUM+:NUM]                  ;

  always @(posedge clk)
  begin
      w0_wdata<={4{ker_wdata[0]}}   ;
      w1_wdata<={4{ker_wdata[1]}}   ;
  end


  assign RAM_wdata0={8{w0_wdata}}   ;
  assign RAM_wdata1={8{w1_wdata}}   ;
  assign RAM_wen0  =w0_wen          ;
  assign RAM_wen1  =w1_wen          ;



endmodule
