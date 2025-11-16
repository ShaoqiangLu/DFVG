`timescale 1ns / 1ps
// -----------------------------------------------------------------------------
// Copyright      : UCLA EDA LAB
// -----------------------------------------------------------------------------
// Engineer       : Chen Wu
// Design Name    : opu series
// Module Name    : nvm_top
// Target Devices : 325t, Alveo U200
// Tool Versions  : Vivado 2020.1, Modelsim 2019.4
// Description    : 
//    Post processes including: residual, GeLU, Softmax, LayerNormalization,
//    Transpose. Each feature can be enabled or not.
//    Attention   : In this design, DW * NUM must be 512 (DDR Datawidth)

module nvm_sf_factor #(
  parameter   DW                = 16                ,
  parameter   NUM               = 32     
) (
  input                         clk                 ,
  input                         reset               ,                   
  input       [4-1:0]           fct_num             ,
  input                         fct_in_vld          ,
  input                         fct_in_done         ,
  input       [NUM*DW-1:0]      fct_in_data         ,
  output  reg [NUM-1:0][DW-1:0] fct_out_data=0      ,
  output  reg                   fct_out_vld =0      ,
  output  reg                   fct_out_done=0   
);


  integer i=0,j=0;
  always @ (posedge clk)
  for(i=0;i<NUM;i=i+1)
  fct_out_data[i]<=
  {{3{fct_in_data[DW*i+DW-1]}},
      fct_in_data[DW*i+DW-1-:DW-3]};         



  always @ (posedge clk)
  begin
    fct_out_vld  <= fct_in_vld  ;
    fct_out_done <= fct_in_done ;
  end
  



endmodule