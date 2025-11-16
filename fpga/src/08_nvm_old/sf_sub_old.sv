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

module sf_sub_old #(
parameter DATA_WIDTH = 16, 
parameter NUM_ELEMS  = 2
)(
    input                                           clk         ,
    input                                           rst         ,
    input                                           ina_vld     ,
    input                                           ina_done    ,
    input signed [NUM_ELEMS-1:0][DATA_WIDTH-1:0]    ina_data    ,// Q16_9
    input                                           inb_vld     ,
    input                                           inb_done    ,
    input signed [DATA_WIDTH-1:0]                   inb_data    ,// Q16_9

    output reg                                      out_vld   =0,
    output reg                                      out_done  =0,
    output reg signed[NUM_ELEMS-1:0][DATA_WIDTH:0]  out_data  =0 // Q17_9

);

    reg                                     r1_ina_vld  =0   ;
    reg                                     r1_ina_done =0   ;
    reg  [NUM_ELEMS-1:0][DATA_WIDTH-1:0]    r1_ina_data =0   ;
    reg                                     r1_inb_vld  =0   ;
    reg                                     r1_inb_done =0   ;
    reg  [DATA_WIDTH-1:0]                   r1_inb_data =0   ;
    always @(posedge clk)
    begin
        r1_ina_vld  <=  ina_vld  ;
        r1_ina_done <=  ina_done ;
        r1_ina_data <=  ina_data ;
        r1_inb_vld  <=  inb_vld  ;
        r1_inb_done <=  inb_done ;
        r1_inb_data <=  inb_data ;
    end

    reg signed [NUM_ELEMS-1:0][DATA_WIDTH:0] sub_result =0; // OUTPUT are regs, Q17_9

    always @(posedge clk)
    for (int i = 0; i < NUM_ELEMS; i++) 
    begin
        if(r1_ina_vld)sub_result[i]<={r1_ina_data[i][DATA_WIDTH-1],
        r1_ina_data[i]} - {r1_inb_data[DATA_WIDTH-1],r1_inb_data};
        else sub_result[i]<=0;
    
        out_data[i]<=sub_result[i];
    end
    
    reg r1_out_vld  =0;
    reg r1_out_done =0;
    
    
    always @(posedge clk)
    begin
    r1_out_vld  <= r1_ina_vld && r1_inb_vld ;
    r1_out_done <= r1_ina_done&& r1_inb_done;
    
    out_vld   <= r1_out_vld ;
    out_done  <= r1_out_done;
    
    end
    
    
 
    
endmodule
