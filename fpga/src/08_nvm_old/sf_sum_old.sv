`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/11/25 14:14:24
// Design Name: 
// Module Name: vec_adder
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

/* This module do vectorial add up by generating a add up tree. 
   The output is 1 bit wider than the input, so OUT_WIDTH must larger than IN_WIDTH !
   NUM_ELEMS must be 2^N ! 
*/

module sf_sum_old #(
    parameter IN_WIDTH  =16, 
    parameter OUT_WIDTH =17, 
    parameter NUM_ELEMS =2
) (
    input                                       clk,
    input  signed [NUM_ELEMS-1:0][IN_WIDTH-1:0] in_data,
    output signed [OUT_WIDTH-1:0]               out_data
);
    wire signed [OUT_WIDTH-2:0] sum_left; // 1 bit narrower that 
    wire signed [OUT_WIDTH-2:0] sum_right;

    generate
        if (NUM_ELEMS == 2) begin
            if (OUT_WIDTH == IN_WIDTH+1) begin
                assign sum_left  = in_data[1];
                assign sum_right = in_data[0];
            end else begin// it also works fine when OUT_WIDTH > IN_WIDTH+1
                assign sum_left  = in_data[1];
                assign sum_right = in_data[0];
                //$error("input width %d doesn't match output width %d", IN_WIDTH, OUT_WIDTH);
            end
        end else begin
            sf_sum_old #(
                .IN_WIDTH       (IN_WIDTH), 
                .OUT_WIDTH      (OUT_WIDTH-1), 
                .NUM_ELEMS      (NUM_ELEMS/2)) 
            va0 (
                .clk            (clk),
                .in_data        (in_data[NUM_ELEMS-1:(NUM_ELEMS/2)]), 
                .out_data       (sum_left)
             );
            
            
            sf_sum_old #(
                .IN_WIDTH       (IN_WIDTH), 
                .OUT_WIDTH      (OUT_WIDTH-1), 
                .NUM_ELEMS      (NUM_ELEMS/2)) 
            va1 (
                .clk            (clk),
                .in_data        (in_data[(NUM_ELEMS/2-1):0]), 
                .out_data       (sum_right)
            );
        end
    endgenerate

    



    generate 
        if (NUM_ELEMS ==32 || NUM_ELEMS ==8|| NUM_ELEMS ==2) begin:gen_Pipe
        wire  [OUT_WIDTH-1:0] sum_pi;
        reg   [OUT_WIDTH-1:0] sum_po=0;
        assign sum_pi= {sum_left[OUT_WIDTH-2],sum_left} + {sum_right[OUT_WIDTH-2],sum_right}; // add 1 MSB 
        
            always @(posedge clk)sum_po <= sum_pi;
            assign out_data=sum_po;
            
        end else begin:gen_noPipe
            assign out_data= {sum_left[OUT_WIDTH-2],sum_left} + {sum_right[OUT_WIDTH-2],sum_right}; // add 1 MSB 
        end
    endgenerate









endmodule
