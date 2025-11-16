`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/11/17 21:02:04
// Design Name: 
// Module Name: exp_func
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

/* This module is for calculating exp function. We do non-uniform linear approximation 
   Input is Q16_9 and output is Q16_15 (pure decimal). It takes 3 cycles to get the results.
   In the first cycle, calculate x_sub = x - x0, in the next cycle, do multi = x_sub * k0,
   in the last cycle, finish the add up tmp_result = multi + y0.
*/

module sf_exp_base_old #(parameter DATA_WIDTH=16) (
    input                               clk         ,
    input                               rst         ,
    input                               in_vld      ,
    input  signed [DATA_WIDTH:0]        in_data     , // Q17_9
    output reg signed [DATA_WIDTH-1:0]  out_data   =0 // Q16_14
    );
    reg signed [DATA_WIDTH-1:0] x0 [4:0]          ; // Width of x0 should match that of input x, so it should be Q17_9
    reg signed [15:0]           k0 [4:0]          ;
    reg signed [15:0]           y0 [4:0]          ;
    reg        [3:0]            range_idx[1:0]    ; // We cache the index of x falling in which interval.
    reg signed [DATA_WIDTH:0]   x_sub           =0;
    reg signed [31:0]           multi           =0; // Q32_18
    reg signed [31:0]           tmp_result      =0; // Q32_18
    reg signed [31:0]           tmp_result1     =0; // Q32_18
    reg signed [31:0]           tmp_result2     =0; // Q32_18
    reg signed [31:0]           tmp_result3     =0; // Q32_18
    reg signed [31:0]           tmp_result4     =0; // Q32_18
    reg r1_in_vld=0;
    reg r2_in_vld=0;
    reg r3_in_vld=0;
    reg r4_in_vld=0;
    reg r5_in_vld=0;
    reg r6_in_vld=0;
    reg r7_in_vld=0;

    initial begin
    // do 5-segmented piecewise linear approximation.
    // Note that we truncate exp function when x < -6.2383,
    // since exp(x) is out of the range of that 9 fractional bits can stand for (1 / 2^9 = 0.002).
    // More precise approxmation can be done by interleaving with more intervals.
    // x0 = [-6.2383   -3.0000   -2.0000   -1.0000         0]
    // k0 = [ 0.0156    0.0859    0.2324    0.6328    0.6328]
    // k0 = [ 0.0020    0.0488    0.1348    0.3672    1.0000]
    x0[0] = 16'hf386; x0[1] = 16'hfa00; x0[2] = 16'hfc00; x0[3] = 16'hfe00; x0[4] = 16'h0000;
    k0[0] = 16'h0008; k0[1] = 16'h002c; k0[2] = 16'h0077; k0[3] = 16'h0144; k0[4] = 16'h0144; 
    y0[0] = 16'h0001; y0[1] = 16'h0019; y0[2] = 16'h0045; y0[3] = 16'h00bc; y0[4] = 16'h0200; 
    end


always @(posedge clk)
begin
    if (rst) begin
            multi           <= 32'h0;
            tmp_result      <= 32'h0;
            range_idx[0]    <= 4'd5;
            range_idx[1]    <= 4'd5;
     end 
     else
     begin
            //-------------------------------------------------------------------
            // 1st cycle: compare the input and the interval 
            // points and calculate x_sub  = x - x0
            //-------------------------------------------------------------------
            if (in_data > x0[3]) begin
                x_sub           <= in_data - x0[3];
                range_idx[0]    <= 4'd3; // 4'b0011
            end else if (in_data > x0[2]) begin
                x_sub           <= in_data - x0[2];
                range_idx[0]    <= 4'd2; // 4'b0010
            end else if (in_data > x0[1]) begin
                x_sub           <= in_data - x0[1];
                range_idx[0]    <= 4'd1; // 4'b0001
            end else if (in_data > x0[0]) begin
                x_sub           <= in_data - x0[0];
                range_idx[0]    <= 4'd0; // 4'b0100
            end else begin
                x_sub           <= 32'h0;
                range_idx[0]    <= 4'd4;
            end


            //-------------------------------------------------------------------
            // 2nd cycle: do the multiplication
            //-------------------------------------------------------------------
            range_idx[1] <= range_idx[0];
            case (range_idx[0])
                4'd3:
                    multi <= x_sub * k0[3];
                4'd2:
                    multi <= x_sub * k0[2];
                4'd1:
                    multi <= x_sub * k0[1];
                4'd0:
                    multi <= x_sub * k0[0];
                default:
                    multi <= 32'b0;
            endcase



            //-------------------------------------------------------------------
            // 3rd cycle: do the addition
            // ex_regtend Q16_9 to Q32_18
            //-------------------------------------------------------------------
            case (range_idx[1])
                4'd3:
                    tmp_result <= {y0[3], 9'b0} + multi; 
                4'd2:
                    tmp_result <= {y0[2], 9'b0} + multi;
                4'd1:
                    tmp_result <= {y0[1], 9'b0} + multi;
                4'd0:
                    tmp_result <= {y0[0], 9'b0} + multi;
               default:
                    tmp_result <= 32'b0;
            endcase
                
                
      tmp_result1<=tmp_result;
      tmp_result2<=tmp_result1;
      tmp_result3<=tmp_result2;
      tmp_result4<=tmp_result3;
                
                
   end
end


    // here we convert a Q32_18 number to a Q16_14 number.
    always @(posedge clk)
    begin
        r1_in_vld <=    in_vld;
        r2_in_vld <= r1_in_vld;
        r3_in_vld <= r2_in_vld;
        
        r4_in_vld <= r3_in_vld;
        r5_in_vld <= r4_in_vld;
        r6_in_vld <= r5_in_vld;
        r7_in_vld <= r6_in_vld;
    if(r7_in_vld)
            out_data <= {1'b0, tmp_result4[18:4]};
    else    out_data <=0;
    
    end


endmodule
