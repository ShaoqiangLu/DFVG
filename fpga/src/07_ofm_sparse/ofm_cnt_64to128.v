`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/18/2024 09:40:49 AM
// Design Name: 
// Module Name: cnt_64to128
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


module ofm_cnt_64to128#(
  parameter                     NUM    = 128, 
  parameter                     IDW    = 38 ,
  parameter                     DWCNT  = 6  ,
  parameter                     SELPRE = 64 ,
  parameter                     SELCUR = 128,
  localparam                    SELNUM = NUM/SELCUR  
)
(
    input       [NUM*IDW-1:0]         data_in   ,
    output reg  [SELNUM-1:0][(DWCNT+1)-1:0]data_out=0,
    input                             clk       
);
  integer i=0,j=0;
  reg [DWCNT-1:0] sel_cnt0 [SELNUM-1:0];
  reg [DWCNT-1:0] sel_cnt1 [SELNUM-1:0];
  reg [DWCNT-1:0] sel_cnt2 [SELNUM-1:0];
  reg [DWCNT-1:0] sel_cnt3 [SELNUM-1:0];
  reg [DWCNT-1:0] sel_cnt4 [SELNUM-1:0];
  reg [DWCNT-1:0] sel_cnt5 [SELNUM-1:0];
  reg [DWCNT-1:0] sel_cnt6 [SELNUM-1:0];
  reg [DWCNT-1:0] sel_cnt7 [SELNUM-1:0];

  always @(posedge clk)
  for(i=0;i<SELNUM;i=i+1)
  begin
      data_out[i]<=   
      sel_cnt7 [i]+
      sel_cnt6 [i]+
      sel_cnt5 [i]+
      sel_cnt4 [i]+
      sel_cnt3 [i]+
      sel_cnt2 [i]+               
      sel_cnt1 [i]+
      sel_cnt0 [i];
 //----------------------------------------------------
  sel_cnt7[i]<= data_in[((i*SELCUR+ 63)*IDW)+:1]+
                data_in[((i*SELCUR+ 62)*IDW)+:1]+
                data_in[((i*SELCUR+ 61)*IDW)+:1]+
                data_in[((i*SELCUR+ 60)*IDW)+:1]+
                data_in[((i*SELCUR+ 59)*IDW)+:1]+
                data_in[((i*SELCUR+ 58)*IDW)+:1]+
                data_in[((i*SELCUR+ 57)*IDW)+:1]+
                data_in[((i*SELCUR+ 56)*IDW)+:1];
  sel_cnt6[i]<= data_in[((i*SELCUR+ 55)*IDW)+:1]+
                data_in[((i*SELCUR+ 54)*IDW)+:1]+
                data_in[((i*SELCUR+ 53)*IDW)+:1]+
                data_in[((i*SELCUR+ 52)*IDW)+:1]+
                data_in[((i*SELCUR+ 51)*IDW)+:1]+
                data_in[((i*SELCUR+ 50)*IDW)+:1]+
                data_in[((i*SELCUR+ 49)*IDW)+:1]+
                data_in[((i*SELCUR+ 48)*IDW)+:1];
  sel_cnt5[i]<= data_in[((i*SELCUR+ 47)*IDW)+:1]+
                data_in[((i*SELCUR+ 46)*IDW)+:1]+
                data_in[((i*SELCUR+ 45)*IDW)+:1]+
                data_in[((i*SELCUR+ 44)*IDW)+:1]+
                data_in[((i*SELCUR+ 43)*IDW)+:1]+
                data_in[((i*SELCUR+ 42)*IDW)+:1]+
                data_in[((i*SELCUR+ 41)*IDW)+:1]+
                data_in[((i*SELCUR+ 40)*IDW)+:1];
  sel_cnt4[i]<= data_in[((i*SELCUR+ 39)*IDW)+:1]+
                data_in[((i*SELCUR+ 38)*IDW)+:1]+
                data_in[((i*SELCUR+ 37)*IDW)+:1]+
                data_in[((i*SELCUR+ 36)*IDW)+:1]+
                data_in[((i*SELCUR+ 35)*IDW)+:1]+
                data_in[((i*SELCUR+ 34)*IDW)+:1]+
                data_in[((i*SELCUR+ 33)*IDW)+:1]+
                data_in[((i*SELCUR+ 32)*IDW)+:1];
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
