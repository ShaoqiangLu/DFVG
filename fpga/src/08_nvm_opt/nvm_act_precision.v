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

module nvm_act_precision # (
    parameter CUT = 27,
    parameter DW  = 16,
    parameter NUM = 32
)(
    input                           clk                 ,
    input                           rst                 ,
    input                  [4 -1:0] x_num               ,
    output  reg   [CUT-1:0][15-1:0] PARAMETER_K_Q15=0   ,
    output  reg   [CUT-1:0][17-1:0] PARAMETER_X_Q17=0   ,
    output  reg   [CUT-1:0][32-1:0] PARAMETER_Y_Q32=0     
);
`include "act_parameter.vh"
//reg [CUT*15-1:0]PARAMETER_K_Q15_fixed12;
//reg [CUT*17-1:0]PARAMETER_X_Q17_from0_to16 [16:0];
//reg [CUT*32-1:0]PARAMETER_Y_Q32_from12_to28[28:12];
//localparam PRAM_X0_fraclen=11;
//localparam PRAM_K0_fraclen=12;
//localparam PRAM_Y0_fraclen=23;
  integer i=0,j=0;
  (*dont_touch="true"*)reg [4-1:0] x_num0=0;
  (*dont_touch="true"*)reg [4-1:0] x_num1=0;
  (*dont_touch="true"*)reg [4-1:0] x_num2=0;
  (*dont_touch="true"*)reg [4-1:0] r0_x_num[CUT-1:0];
  (*dont_touch="true"*)reg [5-1:0] r0_y_num[CUT-1:0];
  (*dont_touch="true"*)reg [5-1:0] r1_y_num[CUT-1:0];
  
  always @ (posedge clk)
  begin
    x_num0    <=x_num;
    x_num1    <=x_num;
    x_num2    <=x_num;
    for(i=0;i<CUT;i=i+1)
    begin
    r0_x_num[i]<=x_num0;
    r0_y_num[i]<=x_num1+PRAM_K0_fraclen;
    r1_y_num[i]<=x_num2+PRAM_K0_fraclen;
    end
    
  end
 
  always @ (posedge clk)
  for(i=0;i<CUT;i=i+1)
  begin
      PARAMETER_K_Q15[i]<= PARAMETER_K_Q15_fixed12                 [i*15+:15];
      PARAMETER_X_Q17[i]<= PARAMETER_X_Q17_from0_to16 [r0_x_num[i]][i*17+:17];
      PARAMETER_Y_Q32[i]<={PARAMETER_Y_Q32_from12_to28[r0_y_num[i]][i*32+1*16+:16],
                           PARAMETER_Y_Q32_from12_to28[r1_y_num[i]][i*32+0*16+:16]};
  end






  
endmodule
