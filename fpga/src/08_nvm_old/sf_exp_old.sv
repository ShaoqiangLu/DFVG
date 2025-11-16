`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/12/07 12:07:45
// Design Name: 
// Module Name: Vexe
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

/* This is a vectorizing wrapper for exp_func. */

module sf_exp_old #(parameter NUM_ELEMS=2, DATA_WIDTH=16) (
    input                                           clk ,
    input                                           rst ,
    input signed  [NUM_ELEMS-1:0][DATA_WIDTH:0]     in_data ,// Q17_9
    input                                           in_vld  ,
    input                                           in_done ,
    
    output signed [NUM_ELEMS-1:0][DATA_WIDTH-1:0]   out_data ,// Q16_14
    output                                          out_vld  ,
    output                                          out_done 
   
    );
    
   generate for (genvar i = 0; i < NUM_ELEMS; i++)
   begin
           sf_exp_base_old #(
           .DATA_WIDTH  (DATA_WIDTH     )
           ) EXP(
           .clk         (clk            ), 
           .rst         (rst            ), 
           .in_vld      (in_vld         ),
           .in_data     (in_data[i]     ), 
           .out_data    (out_data[i]    )
           
           );
  end
  endgenerate


 


  dly_cell #(
    .DLY      ( 8               ),
    .DW       ( 2               )
  ) dly_ed (
    .dout     ( {out_vld,out_done}),
    .din      ( {in_vld ,in_done }),

    .clk      ( clk             ),
    .reset    ( rst             )
  );





endmodule
