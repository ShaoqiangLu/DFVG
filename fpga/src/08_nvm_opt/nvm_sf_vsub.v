`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/11/16 21:50:15
// Design Name: 
// Module Name: subtract
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

/* The subtract module consists of combination logic to do (x - x_max), which takes 1 cycle.
   The NUM_ELEMS could be 2, 4, 8, and 16. Input is Q16_9 and output should be 1 bit wider than input, Q17_9.
   Finding maximum value in the vector is done by generating combination logic recursively. */

module nvm_sf_vsub 
#(
    parameter DATA_WIDTH    = 16, 
    parameter NUM_ELEMS     = 32,
    parameter DLY_SUB       = 3
)(
    input                                                   clk      ,
    input                                                   rst      ,
    input  wire				                                A_done   ,
    input  wire				                                A_vld    ,
    input  wire signed [NUM_ELEMS-1:0][DATA_WIDTH  -1:0]    A_in     , // Q16_9
    input  wire signed                [DATA_WIDTH  -1:0] 	B_in     , // Q16_9
    output wire        [NUM_ELEMS-1:0][DATA_WIDTH+1-1:0]    C_out    , // Q17_9
    output wire 				                            C_vld    ,
    output wire 				                            C_done  
);
    integer i=0,j=0;
    
    (*max_fanout=16*)reg  signed [DATA_WIDTH-1:0]A_in_r[NUM_ELEMS-1:0];  // Q16_9
    (*max_fanout=16*)reg  signed [DATA_WIDTH-1:0]B_in_r[NUM_ELEMS-1:0];  // Q16_9
    always @(posedge clk) 
    for(i=0;i<NUM_ELEMS;i=i+1)
    begin
        A_in_r[i]<=A_in[i];
        B_in_r[i]<=B_in   ;
    end


    generate
    for(genvar i=0;i<NUM_ELEMS;i=i+1)
    begin:g
        (*keep_hierarchy="yes"*)
        SUB_SF SUB
        (
              .CLK  (clk), 
              .A    (A_in_r[i]      ), // input wire  [15 : 0] A
              .B    (B_in_r[i]      ), // input wire  [15 : 0] B
              .S    (C_out [i]      )  // output wire [16 : 0] S
        );
    end
    endgenerate
   
   //---------------------------------------------------------------
   //
   //---------------------------------------------------------------
   reg [DLY_SUB*2-1:0] dly_dv   =0;
   always @(posedge clk) 
   for(i=0;i<DLY_SUB;i=i+1)
   if(i==0)dly_dv[i*2+:2]<={A_vld,A_done};
   else    dly_dv[i*2+:2]<=dly_dv[(i-1)*2+:2];
   
   assign  C_vld  = dly_dv[(DLY_SUB-1)*2+1];
   assign  C_done = dly_dv[(DLY_SUB-1)*2+0];
   

endmodule
