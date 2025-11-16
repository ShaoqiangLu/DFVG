`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/18/2024 09:39:53 AM
// Design Name: 
// Module Name: cnt_32to64
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


module ofm_cnt_32to64#(
  parameter                     NUM    = 128 , 
  parameter                     IDW    = 38 ,
  parameter                     DWCNT  = 5  ,
  parameter                     SELPRE = 32 ,
  parameter                     SELCUR = 64 ,
  localparam                    SELNUM = NUM/SELCUR 
)(
    input                             clk       ,
    input       [NUM*IDW-1:0]         data_in   ,
    output reg  [SELNUM-1:0][(DWCNT+1)-1:0]data_out =0 
  
);

  integer i=0,j=0;
  reg [DWCNT-1:0] sel_cnt0 [SELNUM-1:0];
  reg [DWCNT-1:0] sel_cnt1 [SELNUM-1:0];
  reg [DWCNT-1:0] sel_cnt2 [SELNUM-1:0];
  reg [DWCNT-1:0] sel_cnt3 [SELNUM-1:0];
  always @(posedge clk)
  for(i=0;i<SELNUM;i=i+1)
  begin
      data_out[i]<=
      sel_cnt3 [i]+
      sel_cnt2 [i]+               
      sel_cnt1 [i]+
      sel_cnt0 [i];
 //----------------------------------------------------

  sel_cnt3[i]<= data_in[((i*SELCUR+ 31)*IDW)+:1]+
                data_in[((i*SELCUR+ 30)*IDW)+:1]+
                data_in[((i*SELCUR+ 29)*IDW)+:1]+
                data_in[((i*SELCUR+ 28)*IDW)+:1]+
                data_in[((i*SELCUR+ 27)*IDW)+:1]+
                data_in[((i*SELCUR+ 26)*IDW)+:1]+
                data_in[((i*SELCUR+ 25)*IDW)+:1]+
                data_in[((i*SELCUR+ 24)*IDW)+:1];
  sel_cnt2[i]<= data_in[((i*SELCUR+ 23)*IDW)+:1]+
                data_in[((i*SELCUR+ 22)*IDW)+:1]+
                data_in[((i*SELCUR+ 21)*IDW)+:1]+
                data_in[((i*SELCUR+ 20)*IDW)+:1]+
                data_in[((i*SELCUR+ 19)*IDW)+:1]+
                data_in[((i*SELCUR+ 18)*IDW)+:1]+
                data_in[((i*SELCUR+ 17)*IDW)+:1]+
                data_in[((i*SELCUR+ 16)*IDW)+:1];
  sel_cnt1[i]<= data_in[((i*SELCUR+ 15)*IDW)+:1]+
                data_in[((i*SELCUR+ 14)*IDW)+:1]+
                data_in[((i*SELCUR+ 13)*IDW)+:1]+
                data_in[((i*SELCUR+ 12)*IDW)+:1]+
                data_in[((i*SELCUR+ 11)*IDW)+:1]+
                data_in[((i*SELCUR+ 10)*IDW)+:1]+
                data_in[((i*SELCUR+  9)*IDW)+:1]+
                data_in[((i*SELCUR+  8)*IDW)+:1];
  sel_cnt0[i]<= data_in[((i*SELCUR+  7)*IDW)+:1]+
                data_in[((i*SELCUR+  6)*IDW)+:1]+
                data_in[((i*SELCUR+  5)*IDW)+:1]+
                data_in[((i*SELCUR+  4)*IDW)+:1]+
                data_in[((i*SELCUR+  3)*IDW)+:1]+
                data_in[((i*SELCUR+  2)*IDW)+:1]+
                data_in[((i*SELCUR+  1)*IDW)+:1]+
                data_in[((i*SELCUR+  0)*IDW)+:1];

  end




endmodule

