`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/11/12 20:27:32
// Design Name: 
// Module Name: GELU_act
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
//

/* This module takes two cycles to finish the GELU(x) active function,
   Input x is Q16_8 and output is Q16_8 as well.
   We do the linear approximation: the first cycle to calculate the fixed-point multiplication multi = (x-x0)*k0,
   while the next cycle do right shift to get the fixed number with the same fractional bit width and add up to tmp_result = multi + y0.
   Output is a wire connecting to reg tmp_result. */

module GELU_act_old( 
    input                       clk,
    input                       rst,
    input                       enable,
    input       signed [15:0]   x, // Q16_8
    output wire signed [15:0]   y // Q16_8
    );
    parameter FRAC_WIDTH = 8;
    reg signed [15:0] x_d = 0 ;
    reg signed [10:0] x0 [4:0]; // Q11_8
    reg signed [15:0] k0 [3:0]; // Q16_14
    reg signed [15:0] y0 [3:0]; // Q16_14
    reg signed [31:0] multi;    // Q32_22
    reg signed [21:0] tmp_result;// Q22_14
    
    initial begin
    multi = 32'b0;
    tmp_result = 32'b0;
    // x0 =[ -3    -1     0     1     3]; 
    // y0 = [-0.0040   -0.1587         0    0.8413]
    // k0 = [-0.0773    0.1587    0.8413    1.0773]
    x0[0] = 11'hfd00; x0[1] = 11'hff00; x0[2] = 11'h0000; x0[3] = 11'h0100; x0[4] = 11'h0300; 
    k0[0] = 16'hfb0d; k0[1] = 16'h0a27; k0[2] = 16'h35d9; k0[3] = 16'h44f2;
    y0[0] = 16'hffbe; y0[1] = 16'hf5d9; y0[2] = 16'h0000; y0[3] = 16'h35d9;
    end
    
    assign y = tmp_result[21:6];

    // changed by chen, need to keep x and multi at the same cycle 
    // when getting tmp_result
    always @(posedge clk) begin
      x_d               <=    x                                   ;
    end

    always @(posedge clk) begin
      if ( rst )
        multi           <=    0                                   ;
      else if ( enable ) begin
        if ( ~x[15] ) begin
          if ( x > x0[4] )
            multi       <=    0                                   ;
          else if ( x > x0[3] )
            multi       <=    (x - x0[3]) * k0[3]                 ;
          else
            multi       <=    (x - x0[2]) * k0[2]                 ;
        end else begin
          if ( x < x0[0] )
            multi       <=    0                                   ;
          else if ( x < x0[1] )
            multi       <=    (x - x0[0]) * k0[0]                 ;
          else
            multi       <=    (x - x0[1]) * k0[1]                 ;
        end
      end
    end

    always @(posedge clk) begin
      if ( rst )
        tmp_result      <=    0                                   ;
      else if ( enable ) begin
        if ( ~x_d[15] ) begin
          if ( x_d > x0[4] )
            tmp_result  <=    {x_d, 6'h0}                         ;
          else if ( x_d > x0[3] )
            tmp_result  <=    y0[3] + (multi >>> FRAC_WIDTH)      ;
          else
            tmp_result  <=    y0[2] + (multi >>> FRAC_WIDTH)      ;
        end else begin
          if ( x_d < x0[0] )
            tmp_result  <=    0                                   ;
          else if ( x_d < x0[1] )
            tmp_result  <=    y0[0] + (multi >>> FRAC_WIDTH)      ;
          else
            tmp_result  <=    y0[1] + (multi >>> FRAC_WIDTH)      ;
        end
      end
    end
    
    // always @(posedge clk) begin
    //     if(rst) begin
    //         multi <= 32'b0;
    //         tmp_result <= 32'b0;
    //     end
    //     else if (enable)
    //         // y = GELU(x) = k0 * (x - x0) + y0
    //         // compare the input and the interval points
    //         if (~x[15]) // x is positive
    //             if (x > x0[4])
    //                 // we need to extend the franctional bits of x, aligned with tmp_result
    //                 tmp_result <= {x,6'b0};
    //             else if (x > x0[3]) begin
    //                 multi <= (x - x0[3]) * k0[3];
    //                 tmp_result <= y0[3] + (multi >>> FRAC_WIDTH);
    //             end else begin
    //                 multi <= (x - x0[2]) * k0[2];
    //                 tmp_result <= y0[2] + (multi >>> FRAC_WIDTH);
    //             end
    //         else   // x is negative
    //             if (x < x0[0]) begin
    //                 multi <= 32'h0;
    //                 tmp_result <= 32'h0;
    //             end else if (x < x0[1]) begin
    //                 multi <= (x - x0[0]) * k0[0];
    //                 tmp_result <= y0[0] + (multi >>> FRAC_WIDTH);
    //             end else begin
    //                 multi <= (x - x0[1]) * k0[1];
    //                 tmp_result <= y0[1] + (multi >>> FRAC_WIDTH);
    //             end
    // end
endmodule
