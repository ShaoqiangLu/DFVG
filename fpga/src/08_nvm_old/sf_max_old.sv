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

// recursively generate the comparators to find the maximum value of the input vector.
// NUM_ELEMS must be 2^N !!

module sf_max_old #(parameter DATA_WIDTH=16, NUM_ELEMS=2) (
    input       signed [NUM_ELEMS-1:0][DATA_WIDTH-1:0]  in ,
    output  reg signed [DATA_WIDTH-1:0]                 max,
    input                                               clk
);
    wire signed [DATA_WIDTH-1:0] left_half;
    wire signed [DATA_WIDTH-1:0] right_half;

    generate 
        if (NUM_ELEMS == 2) begin
            assign left_half  = in[1];
            assign right_half = in[0];
        end else begin
            sf_max_old #(.DATA_WIDTH(DATA_WIDTH), .NUM_ELEMS(NUM_ELEMS/2)) cm0 (.in(in[(NUM_ELEMS-1):(NUM_ELEMS/2)]), .max(left_half )   ,.clk(clk));
            sf_max_old #(.DATA_WIDTH(DATA_WIDTH), .NUM_ELEMS(NUM_ELEMS/2)) cm1 (.in(in[(NUM_ELEMS/2-1):0]          ), .max(right_half)   ,.clk(clk));
        end
    endgenerate




    generate 
        if (NUM_ELEMS ==32 || NUM_ELEMS ==8|| NUM_ELEMS ==2) begin:gen_Pipe
        wire  [DATA_WIDTH-1:0] max_pi;
        reg   [DATA_WIDTH-1:0] max_po=0;
        assign max_pi= $signed(left_half)>$signed(right_half)?left_half:right_half;
        
         always @(posedge clk)max_po <= max_pi;
            assign max=max_po;
            
        end else begin:gen_noPipe
            assign max= $signed(left_half)>$signed(right_half)?left_half:right_half;
        end
    endgenerate





    
endmodule
