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

module nvm_ln_vsub 
#(
    parameter  DATA_WIDTH    = 16, 
    parameter  NUM_ELEMS     = 32
)(
    input                                           clk     ,
    input                                           rst     ,
    input  wire                                     A_done  ,
    input  wire				                        A_vld   ,
    input  wire   [NUM_ELEMS*DATA_WIDTH -1:0]       A_in    ,// Q16_9
    input  wire   [DATA_WIDTH-1:0] 		            B_in    ,// Q16_9
    output wire   [NUM_ELEMS*(DATA_WIDTH+1)-1:0]    C_out   ,// Q17_9
    output reg  				                    C_vld =0,
    output reg                                      C_done=0
);


    reg   [NUM_ELEMS*DATA_WIDTH -1:0]A_in_r=0; 
    (*dont_touch="true"*)reg   [4 *DATA_WIDTH-1:0] B_in_r=0;
    (*dont_touch="true"*)wire  [32*DATA_WIDTH-1:0] B_in_wire;
    always @(posedge clk)  A_in_r <=A_in;
    always @(posedge clk)  B_in_r <={4{B_in}};
    assign B_in_wire={8{B_in_r}};
    

    generate
    for(genvar i=0;i<NUM_ELEMS;i=i+1)
    begin :g
        (*keep_hierarchy="yes"*)SUB_LN SUB (
          .CLK  (clk), // input wire CLK
          .A    (A_in_r   [i* DATA_WIDTH+:    DATA_WIDTH]   ), // input wire [15 : 0] A
          .B    (B_in_wire[i* DATA_WIDTH+:    DATA_WIDTH]   ), // input wire [15 : 0] B
          .S    (C_out    [i*(DATA_WIDTH+1)+:(DATA_WIDTH+1)])  // output wire [16 : 0] S
        );
    end
    endgenerate
    
    
 
    reg  r0_C_vld      =0       ;
    reg  r0_C_done     =0       ;
    reg  r1_C_vld      =0       ;
    reg  r1_C_done     =0       ;
    always @(posedge clk)
    begin
        r0_C_vld   <=A_vld      ;
        r0_C_done  <=A_done     ;  
        
        r1_C_vld   <=r0_C_vld   ;
        r1_C_done  <=r0_C_done  ;
        
        C_vld      <=r1_C_vld   ;
        C_done     <=r1_C_done  ;
    end
    



    
endmodule
