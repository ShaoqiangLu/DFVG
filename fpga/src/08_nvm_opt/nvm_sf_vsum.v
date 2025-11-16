`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/11/24 16:57:15
// Design Name: 
// Module Name: comparator
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

// This module recursively generates an adder tree with full-precision bit growth
// Note: we assume here that the number of elements is a power of 2

module nvm_sf_vsum # (
    parameter   IN_WIDTH  = 16,
    parameter   NUM_ELEMS = 32,
    localparam  OUT_WIDTH = IN_WIDTH + $clog2(NUM_ELEMS)
) (
    input                                      clk,
    input  wire [NUM_ELEMS*IN_WIDTH-1:0]       data,
    output wire [OUT_WIDTH-1:0]                sum
);
    wire  [OUT_WIDTH-2:0] sum_left ;  // 1 bit narrower that sum
    wire  [OUT_WIDTH-2:0] sum_right;

    
    generate 
        if (NUM_ELEMS == 2)
            begin:gen_onLR
                assign sum_left  = data[0*IN_WIDTH+:IN_WIDTH];
                assign sum_right = data[1*IN_WIDTH+:IN_WIDTH];
            end
        else
            begin :gen_LR
                
                (*keep_hierarchy="yes"*)nvm_sf_vsum #(// Left half adder tree,
                    .IN_WIDTH (IN_WIDTH),
                    .NUM_ELEMS(NUM_ELEMS/2)
                ) u0_L (
                    .clk (clk),
                    .data(data[NUM_ELEMS*IN_WIDTH-1:(NUM_ELEMS/2)*IN_WIDTH]),
                    .sum (sum_left)
                );
                
                
                (*keep_hierarchy="yes"*)nvm_sf_vsum #(// Right half adder tree
                    .IN_WIDTH (IN_WIDTH),
                    .NUM_ELEMS(NUM_ELEMS/2)
                ) u1_R (
                    .clk (clk),
                    .data(data[(NUM_ELEMS/2)*IN_WIDTH-1:0*IN_WIDTH]),
                    .sum (sum_right)
                );
        end
    endgenerate


    generate 
        if (NUM_ELEMS ==32 || NUM_ELEMS ==8|| NUM_ELEMS ==2) begin:gen_Pipe
        wire [OUT_WIDTH-1:0] sum_pi    ;
        reg  [OUT_WIDTH-1:0] sum_po=0  ;
        assign sum_pi= {sum_left[OUT_WIDTH-2], sum_left} + {sum_right[OUT_WIDTH-2], sum_right};
        always @(posedge clk)sum_po <= sum_pi;
            assign sum=sum_po;
        end else begin:gen_noPipe
            assign sum={sum_left[OUT_WIDTH-2], sum_left} + {sum_right[OUT_WIDTH-2], sum_right};
        end
    endgenerate




endmodule
