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

module nvm_sf_vmax #(parameter DATA_WIDTH=16, NUM_ELEMS=32) (
    input                                           clk,
    input   signed [NUM_ELEMS*DATA_WIDTH-1:0]       max_in ,
    output  signed [DATA_WIDTH-1:0]                 max_out
    );
    wire [DATA_WIDTH-1:0] max_left ;
    wire [DATA_WIDTH-1:0] max_right;

    generate 
        if (NUM_ELEMS == 2) begin:gen_maxLR
            assign max_left  = max_in[1*DATA_WIDTH+:DATA_WIDTH];
            assign max_right = max_in[0*DATA_WIDTH+:DATA_WIDTH];
        end else begin:gen_LR
            
            nvm_sf_vmax #(.DATA_WIDTH(DATA_WIDTH), .NUM_ELEMS(NUM_ELEMS/2)) L_sf_vmax (.clk(clk),.max_in(max_in[ NUM_ELEMS   *DATA_WIDTH-1  :(NUM_ELEMS/2)*DATA_WIDTH]), .max_out(max_left));
            
            nvm_sf_vmax #(.DATA_WIDTH(DATA_WIDTH), .NUM_ELEMS(NUM_ELEMS/2)) R_sf_vmax (.clk(clk),.max_in(max_in[(NUM_ELEMS/2)*DATA_WIDTH-1:              0*DATA_WIDTH]), .max_out(max_right));
        end
    endgenerate


    generate 
        if (NUM_ELEMS ==32 || NUM_ELEMS ==8|| NUM_ELEMS ==2) begin:gen_Pipe
        wire  [DATA_WIDTH-1:0] max_pi;
        reg   [DATA_WIDTH-1:0] max_po=0;
        assign max_pi= $signed(max_left)>$signed(max_right)?max_left:max_right;
         always @(posedge clk)max_po <= max_pi;
            assign max_out=max_po;
        end else begin:gen_noPipe
            assign max_out=$signed(max_left)>$signed(max_right)?max_left:max_right;
        end
    endgenerate




endmodule
