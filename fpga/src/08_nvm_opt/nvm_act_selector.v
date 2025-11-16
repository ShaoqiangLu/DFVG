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

module nvm_act_selector # (
    parameter     CUT                   = 27                ,
    parameter     DW                    = 16                ,
    parameter     NUM                   = 32
)(
    input                               clk                 ,
    input                               rst                 ,  
 
    input         [CUT-1:0][15-1:0]     PARAMETER_K_Q15     ,
    input         [CUT-1:0][17-1:0]     PARAMETER_X_Q17     ,
    input         [CUT-1:0][32-1:0]     PARAMETER_Y_Q32     ,
    input         [NUM-1:0][5 -1:0]     index               ,
    output  reg   [NUM-1:0][15-1:0]     K_sel =0            ,//2 cycle
    output  reg   [NUM-1:0][17-1:0]     X_sel =0            ,
    output  reg   [NUM-1:0][32-1:0]     Y_sel =0    
);


  integer i=0,j=0;


  (*max_fanout=16*)reg[15-1:0] PARAMETER_K[CUT-1:0]         ;
  (*max_fanout=16*)reg[17-1:0] PARAMETER_X[CUT-1:0]         ;
  (*max_fanout=16*)reg[32-1:0] PARAMETER_Y[CUT-1:0]         ;

  (*dont_touch="true",max_fanout=16*)reg[5-1:0]index0[NUM-1:0];
  (*dont_touch="true",max_fanout=16*)reg[5-1:0]index1[NUM-1:0];
  (*dont_touch="true",max_fanout=16*)reg[5-1:0]index2[NUM-1:0];
  (*dont_touch="true",max_fanout=16*)reg[5-1:0]index3[NUM-1:0];

  always @ (posedge clk)
  for(i=0;i<CUT;i=i+1)
  begin
    PARAMETER_K[i]<=PARAMETER_K_Q15[i]                      ;
    PARAMETER_X[i]<=PARAMETER_X_Q17[i]                      ;
    PARAMETER_Y[i]<=PARAMETER_Y_Q32[i]                      ;
  end

  always @ (posedge clk)
  for(i=0;i<NUM;i=i+1)
  begin
      index0[i]<=index[i]                                   ;
      index1[i]<=index[i]                                   ;
      index2[i]<=index[i]                                   ;
      index3[i]<=index[i]                                   ;
  end
  
  always @ (posedge clk)
  for(i=0;i<NUM;i=i+1)
  begin
      K_sel[i]<= PARAMETER_K[index0[i]]                     ;
      X_sel[i]<= PARAMETER_X[index1[i]]                     ;
      Y_sel[i]<={PARAMETER_Y[index2[i]][1*16+:16],
                 PARAMETER_Y[index3[i]][0*16+:16]}          ;
  end




  
endmodule
