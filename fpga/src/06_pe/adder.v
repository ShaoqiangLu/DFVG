`timescale 1ns / 1ps
// -----------------------------------------------------------------------------
// UCLA EDA LAB
// -----------------------------------------------------------------------------
// Engineer       : Chen Wu
// Design Name    : opu series
// Module Name    : adder
// Target Devices : 325t
// Tool Versions  : Vivado 2020.1, Modelsim 2019.4
// Description    : 
//    Perform signed addition with LUT adders.
//    s[DW : 0] = a[DW-1 : 0] + b[DW-1 : 0]
//
//    Delay: 1 cycle
//    Todo: Add support for using DSP.
//
// Revision       :
// Version        Date        Author        Descriptin
// 1.0            2021-04-04  Chen Wu       Initial version
// -----------------------------------------------------------------------------


module adder #(parameter DW=16) (
  output  reg signed    [  DW : 0]    s       ,

  input       signed    [DW-1 : 0]    a       ,
  input       signed    [DW-1 : 0]    b       ,

  input                               clk     ,
  input                               reset   
  );

 (*dont_touch="true"*)  reg reset_r=1;
  always @(posedge clk) reset_r<=reset;

  always @(posedge clk)
  if(reset_r) s<=0;
  else s <=  $signed(a) + $signed(b)   ;
endmodule

