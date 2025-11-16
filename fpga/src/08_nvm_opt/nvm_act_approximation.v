`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/11/23 13:04:14
// Design Name: 
// Module Name: GELU_driver
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: Gaussian Error Linear Unit
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
/* This file is updated using systemverilog.
   GELU_dirvier convert the scalar GELU active function to a vectorized function.
   NUM_ELEMS defines the elements in the vector.
   The GELU_act gets 2 cycles to compute the results, and the driver use 1 cycles to pass the results, y, to y_vec
*/
`include "opu_parameter.vh"
module nvm_act_approximation # (
    parameter DW  = 16,
    parameter NUM = 32
)(
    input                          clk          ,
    input                          rst          ,
    input                          act_vld      ,
    
    input         [4-1:0]          x_num        ,
    input         [4-1:0]          y_num        ,
    
    input         [NUM-1:0][15-1:0]K_sel        ,
    input         [NUM-1:0][17-1:0]X_sel        ,
    input         [NUM-1:0][32-1:0]Y_sel        ,

    input         [NUM*DW-1:0]     x_data       ,
    output reg    [NUM-1:0][DW-1:0]y_data   =0  ,

    output reg    [NUM-1:0][17-1:0]A_act_out=0  , 
    output reg    [NUM-1:0][15-1:0]B_act_out=0  , 
    output reg    [NUM-1:0][32-1:0]C_act_out=0  , 
    output reg    [NUM-1:0][17-1:0]D_act_out=0  , 
    input  signed [NUM-1:0][32-1:0]P_act_in      
);

  integer i=0,j=0;

  reg [NUM*(DW+1)-1:0] r0_x_data=0;
  reg [NUM*(DW+1)-1:0] r1_x_data=0;
  reg [NUM*(DW+1)-1:0] r2_x_data=0;
  reg [NUM*(DW+1)-1:0] r3_x_data=0;
  reg [NUM*(DW+1)-1:0] r4_x_data=0;
  always @(posedge clk)
  begin
      for(i=0;i<NUM;i=i+1)
      r0_x_data[ i*(DW+1)+:(DW+1)]<=
      {x_data[i*DW +DW-1],
       x_data[i*DW+:DW]};
       
      r1_x_data <= r0_x_data;
      r2_x_data <= r1_x_data;
      r3_x_data <= r2_x_data;
      r4_x_data <= r3_x_data;
  end
//------------------------------------------------------
//
//------------------------------------------------------

  always @(posedge clk)
  for(i=0;i<NUM;i=i+1)
  begin
   `ifndef SIM_CODE
     A_act_out[i]<=  r4_x_data[i*(DW+1)+:(DW+1)];
     B_act_out[i]<=  K_sel    [i] ;
     C_act_out[i]<=  Y_sel    [i] ;
     D_act_out[i]<=(-X_sel    [i]); 
   `else
     A_act_out[i]<=~act_vld?0:  r4_x_data[i*(DW+1)+:(DW+1)];
     B_act_out[i]<=~act_vld?0:  K_sel    [i] ;
     C_act_out[i]<=~act_vld?0:  Y_sel    [i] ;
     D_act_out[i]<=~act_vld?0:(-X_sel    [i]);  
   `endif
  end  




  (*max_fanout=16*)reg [NUM*4 -1:0] y_sft  =0;
  (*max_fanout=16*)reg [4-1:0]      r_x_num=0;
  (*max_fanout=16*)reg [4-1:0]      r_y_num=0;
  always @(posedge clk)
  begin
      r_x_num<=x_num;
      r_y_num<=y_num;
  end
  
  always @(posedge clk)
  for(i=0;i<NUM;i=i+1)
  y_sft[i*4+:4]<=12+r_x_num-r_y_num;

//------------------------------------------------------
//
//------------------------------------------------------

 reg [NUM*32-1:0] P_act_result=0;
  always @(posedge clk)
  for(i=0;i<NUM;i=i+1)
  begin
      P_act_result[i*32+:32]<=P_act_in[i];
      y_data[i]<=$signed(P_act_result[i*32+:32])>>>y_sft[i*4+:4];
  end


endmodule
