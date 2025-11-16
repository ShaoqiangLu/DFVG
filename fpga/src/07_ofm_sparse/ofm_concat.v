`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/19/2024 10:20:03 PM
// Design Name: 
// Module Name: concat
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

`include "opu_parameter.vh"

module ofm_concat# (
  parameter                         NUM  =   32             ,
  parameter                         PNUM =   4              ,
  parameter                         DW   =   37             ,
  parameter                         FIFO_WIDTH=128*38       ,
  parameter                         DWCNT=   4              ,
  localparam                        IDW  =   DW+1           ,
  localparam                        INUM =   NUM*PNUM       ,
  localparam                        INUM2=   NUM*PNUM*2                                         
) (
  input                             clk                     ,
  input                             reset                   ,
  input                             fifo_empty              ,
  output wire                       fifo_ren                ,
  input                             fifo_rvld               ,
  input       [FIFO_WIDTH -1:0]     fifo_rdata              ,
  output reg                        concat_vld  =0          ,
  output reg  [INUM-1:0][DW-1:0]    concat_data =0          
);

  localparam  RATIO                 =  8                    ; 
  localparam  CMAX                  = 16                    ; 
  localparam  CNUM                  = 256                   ;

  integer i=0;

  wire                  [CNUM*DWCNT-1:0] cnt0               ;
  wire                  [CNUM*DWCNT-1:0] cnt1               ;
  wire                  [CNUM-1:0]       sel                ; 

(*keep_hierarchy="no"*)
ofm_concat_cnt# (
      .DWCNT            (DWCNT                              ),
      .RATIO            (RATIO                              ),
      .CNUM             (CNUM                               ),
      .CMAX             (CMAX                               )                    
)u_cnt(
      .clk              (clk                                ),
      .rvld             (fifo_rvld                          ),
      .rdata            (fifo_rdata                         ),
    
      .cnt0             (cnt0                               ),
      .cnt1             (cnt1                               ),
      .sel              (sel                                ) 
);


//----------------------------------------------------------------------------------------
//
//----------------------------------------------------------------------------------------
assign fifo_ren         =~fifo_empty                        ;
wire[128*38-1:0]        shift_reg                           ;
wire                    shift_vld                           ;
(*keep_hierarchy="no"*)
ofm_concat_mux#(
      .DWCNT            (DWCNT                              ),
      .RATIO            (RATIO                              ),
      .IDW              (IDW                                ),
      .CNUM             (CNUM                               )                            
)u_mux(
      .clk              (clk                                ),
      .cnt0             (cnt0                               ),
      .cnt1             (cnt1                               ),
      .sel              (sel                                ),
      .rdata            (fifo_rdata                         ),
      .shift_vld        (shift_vld                          ),
      .shift_reg        (shift_reg                          )
);


always @(posedge clk)
begin
  concat_vld            <=shift_vld                         ;
  for(i=0;i<128;i=i+1)
  `ifndef SIM_CODE
  concat_data[i]        <=shift_reg[i*38+1+:37]             ;
  `else
  concat_data[i]<=~shift_vld?0:shift_reg[i*38+1+:37]        ;
  `endif
end


endmodule











