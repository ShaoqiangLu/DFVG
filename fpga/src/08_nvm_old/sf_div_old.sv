`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/12/07 12:58:43
// Design Name: 
// Module Name: Vdiv
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

/* This is a vectorizing wrapper for dividers. */

  
  
module sf_div_old 
#(NUM_ELEMS     =2,
  DATA_WIDTH    =16,
  SF_DIV_DLY    =16
)(
    input                                             clk,
    input                                             divisor_vld     ,
    input signed [2*DATA_WIDTH-1:0]                   divisor_data    , // Q32_14
    input                                             dividend_vld    ,
    input                                             dividend_done   ,
    input signed  [NUM_ELEMS-1:0][DATA_WIDTH-1:0]     dividend_data   ,// Q16_14
    output                                            div_result_vld  ,
    output                                            div_result_done ,
    output reg signed [NUM_ELEMS-1:0][DATA_WIDTH-1:0] div_result_data  // Q16_14

);
    

    //------------------------------------------------------------
    // divisor 23:0
    // dividend 15:0
    // dout 31:0
    // this divider uses fully-pipelined Radix-2 solution taken 2 cycles to do 
    // its job with 30-bit width dividend and 32-bit width  
    // and 32 bit-width output containing 14+2 fractional bits.
    // // bitshift 14 times 
    //------------------------------------------------------------

    generate
        for (genvar i = 0; i < NUM_ELEMS; i++) begin:gd
           wire signed [31:0]              div_out;

           sf_div SF_DIV(
             .aclk                  (clk                ), 
             .s_axis_divisor_tvalid (1'b1               ), 
             .s_axis_divisor_tdata  (divisor_data[23:0]  ), 
             .s_axis_dividend_tvalid(1'b1               ), 
             .s_axis_dividend_tdata (dividend_data[i]    ), 
             .m_axis_dout_tvalid    (                   ), 
             .m_axis_dout_tdata     (div_out            )
            );
           //-----------------------------------------------------------------------
           // the signed bit, the integer bit, and fractional bits of  are used
           always @(posedge clk) div_result_data[i] <= {div_out[31], div_out[14:0]}; 
        end
    endgenerate





  // division IP delay: 2 cycles
  dly_cell #(
    .DLY      ( SF_DIV_DLY+1    ),
    .DW       ( 2               )
  ) dly_ed (
    .dout     ( {div_result_vld
                ,div_result_done}),
    .din      ( {dividend_vld,
                 dividend_done} ),

    .clk      ( clk             ),
    .reset    ( 1'b0            )
  );





endmodule
