`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/11/23 13:04:14
// Design Name: 
// Module Name: GELU_driver
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
/* This file is updated using systemverilog.
   GELU_dirvier convert the scalar GELU active function to a vectorized function.
   NUM_ELEMS defines the elements in the vector.
   The GELU_act gets 2 cycles to compute the results, and the driver use 1 cycles to pass the results, y, to y_vec
*/


module GELU_driver
    #(parameter NUM_ELEMS=2)
(
    input                               clk      ,
    input                               rst      ,
    input                               enable   ,
    input       [NUM_ELEMS-1:0][15:0]   x_data   ,
    input                               x_vld    ,
    input                               x_done   ,
    output reg  [NUM_ELEMS-1:0][15:0]   y_data =0,  
    output wire                         y_vld    ,
    output wire                         y_done   
    );
    integer i;
    localparam   DATAPATH_WIDTH = NUM_ELEMS * 16;
    reg                                 enable_r  =0;    
    wire                         [15:0] y_data_r [NUM_ELEMS];
    reg         [NUM_ELEMS-1:0][15:0]   x_data_r =0;
    reg         [NUM_ELEMS-1:0][15:0]   x_data_d1 =0;
    reg         [NUM_ELEMS-1:0][15:0]   x_data_d2 =0;
    reg         [NUM_ELEMS-1:0][15:0]   x_data_d3 =0;
    reg         [NUM_ELEMS-1:0][15:0]   x_data_d4 =0;
    reg         [NUM_ELEMS-1:0][15:0]   x_data_d5 =0;
    reg         [NUM_ELEMS-1:0][15:0]   x_data_d6 =0;



    always @(posedge clk)
    begin
      enable_r     <=  enable     ;
      if(enable_r) x_data_r<= x_data;
      else         x_data_r<= 0   ;
      
      x_data_d1    <= x_data    ;
      x_data_d2    <= x_data_d1 ;
      x_data_d3    <= x_data_d2 ;
      x_data_d4    <= x_data_d3 ;
      x_data_d5    <= x_data_d4 ;
      x_data_d6    <= x_data_d5 ;
      
    end
     
    // generate GELU_act
    generate
        for (genvar i = 0; i < NUM_ELEMS; i=i+1)
        begin :G
            GELU_act_old g0(.clk(clk), .rst(rst), .enable(enable_r), .x(x_data_r[i]), .y(y_data_r[i]));
        end
    endgenerate
    
    always @(posedge clk or negedge rst)
    begin
        if (rst)  
            for (i = 0; i < NUM_ELEMS; i = i+1) y_data[i] <= 16'b0        ;
        else if ( enable_r ) 
            for (i = 0; i < NUM_ELEMS; i = i+1) y_data[i] <= y_data_r[i]  ;
        else 
            for (i = 0; i < NUM_ELEMS; i = i+1) y_data[i] <= x_data_d6[i] ;
     end



  dly_cell #(
    .DLY                        ( 7                               ),
    .DW                         ( 2                               )
  ) dly_gvd (
    .dout                       ( {y_vld  ,y_done }               ),
    .din                        ( {x_vld  ,x_done }               ),

    .clk                        ( clk                             ),
    .reset                      ( rst                             )
  );











endmodule
