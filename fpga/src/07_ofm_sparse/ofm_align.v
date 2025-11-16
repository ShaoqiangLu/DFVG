`timescale 1ns / 1ps
// -----------------------------------------------------------------------------
// Orgnization: UCLA EDA lab
// Design Name    : opu series
// Module Name    : output_ctrl_top
// Target Devices : k325t
// Tool Versions  : Vivado 2020.1, Modelsim 2019.4
// Description    : 
//    Add bias or temp results to finalize the calculation of one convolutional
//    layer.
// Revision       :
// Version        Date        Author          Description
// 1.0            2017-10-25  Chen Wu         Initial version
// 1.1            2020-02-04  Chen Wu         Modify code style
// 3.1            2021-02-01  Shan Shen       Change data width to 42 from 26
// 3.2            2021-04-07  Jinming Zhuang  Modify & specify the sequential 
//                                            relationship in internal signals
// 4.0            2021-04-26  Chen Wu         Add parameter & delete rearrange
// 4.1            2022-04--7  Chen Wu         Simplify for INT16 case, add pp
// 5.0            2022-09-14  Shaoqiang       Simulation 97 layers,and       
//                                            implementation on FPGA of U200.
// -----------------------------------------------------------------------------
`include "opu_parameter.vh"
module ofm_align#(
  parameter                          NUM  =   32          ,
  parameter                          PNUM =   4           ,
  parameter                          DW   =   37          ,
  localparam                         IDW  =   DW*PNUM+PNUM+1 
)(
  input                              clk            ,
  input                              reset          ,
  
  input      [NUM-1:0][(DW*PNUM)-1:0]ofm_din        ,
  input      [NUM-1:0][(PNUM)-1:0]   ofm_din_vld    ,
  input      [NUM-1:0]               ofm_din_meg    ,
  
  output reg [NUM-1:0][(DW*PNUM)-1:0]align_data    ='d0,
  output reg [NUM-1:0][(PNUM)-1:0]   align_data_vld='d0,
  output reg [NUM-1:0]               align_data_meg='d0            
);

//---------------------------------------------------
//
//---------------------------------------------------
integer i=0,j=0;

wire[   IDW-1:0] BUFFER31    ;
reg [ 1*IDW-1:0] BUFFER30='d0;
reg [ 2*IDW-1:0] BUFFER29='d0;
reg [ 3*IDW-1:0] BUFFER28='d0;
reg [ 4*IDW-1:0] BUFFER27='d0;
reg [ 5*IDW-1:0] BUFFER26='d0;
reg [ 6*IDW-1:0] BUFFER25='d0;
reg [ 7*IDW-1:0] BUFFER24='d0;
reg [ 8*IDW-1:0] BUFFER23='d0;
reg [ 9*IDW-1:0] BUFFER22='d0;
reg [10*IDW-1:0] BUFFER21='d0;
reg [11*IDW-1:0] BUFFER20='d0;
reg [12*IDW-1:0] BUFFER19='d0;
reg [13*IDW-1:0] BUFFER18='d0;
reg [14*IDW-1:0] BUFFER17='d0;
reg [15*IDW-1:0] BUFFER16='d0;
reg [16*IDW-1:0] BUFFER15='d0;
reg [17*IDW-1:0] BUFFER14='d0;
reg [18*IDW-1:0] BUFFER13='d0;
reg [19*IDW-1:0] BUFFER12='d0;
reg [20*IDW-1:0] BUFFER11='d0;
reg [21*IDW-1:0] BUFFER10='d0;
reg [22*IDW-1:0] BUFFER9 ='d0;
reg [23*IDW-1:0] BUFFER8 ='d0;
reg [24*IDW-1:0] BUFFER7 ='d0;
reg [25*IDW-1:0] BUFFER6 ='d0;
reg [26*IDW-1:0] BUFFER5 ='d0;
reg [27*IDW-1:0] BUFFER4 ='d0;
reg [28*IDW-1:0] BUFFER3 ='d0;
reg [29*IDW-1:0] BUFFER2 ='d0;
reg [30*IDW-1:0] BUFFER1 ='d0;
reg [31*IDW-1:0] BUFFER0 ='d0;
//---------------------------------------------------------
always @(posedge clk)
begin
//---------------------------------------------------------
BUFFER0[30*IDW+:IDW]<={ofm_din    [0],
                       ofm_din_vld[0],
                       ofm_din_meg[0]};for(i=29;i>=0;i=i-1)
BUFFER0[i*IDW+:IDW]<=
BUFFER0[(i+1)*IDW+:IDW];
//---------------------------------------------------------
BUFFER1[29*IDW+:IDW]<={ofm_din    [1],
                       ofm_din_vld[1],
                       ofm_din_meg[1]};for(i=28;i>=0;i=i-1)
BUFFER1[i*IDW+:IDW]<=
BUFFER1[(i+1)*IDW+:IDW];
//---------------------------------------------------------
BUFFER2[28*IDW+:IDW]<={ofm_din    [2],
                       ofm_din_vld[2],
                       ofm_din_meg[2]};for(i=27;i>=0;i=i-1)
BUFFER2[i*IDW+:IDW]<=
BUFFER2[(i+1)*IDW+:IDW];
//---------------------------------------------------------
BUFFER3[27*IDW+:IDW]<={ofm_din    [3],
                       ofm_din_vld[3],
                       ofm_din_meg[3]};for(i=26;i>=0;i=i-1)
BUFFER3[i*IDW+:IDW]<=
BUFFER3[(i+1)*IDW+:IDW];
//---------------------------------------------------------
BUFFER4[26*IDW+:IDW]<={ofm_din    [4],
                       ofm_din_vld[4],
                       ofm_din_meg[4]};for(i=25;i>=0;i=i-1)
BUFFER4[i*IDW+:IDW]<=
BUFFER4[(i+1)*IDW+:IDW];
//---------------------------------------------------------
BUFFER5[25*IDW+:IDW]<={ofm_din    [5],
                       ofm_din_vld[5],
                       ofm_din_meg[5]};for(i=24;i>=0;i=i-1)
BUFFER5[i*IDW+:IDW]<=
BUFFER5[(i+1)*IDW+:IDW];
//---------------------------------------------------------
BUFFER6[24*IDW+:IDW]<={ofm_din    [6],
                       ofm_din_vld[6],
                       ofm_din_meg[6]};for(i=23;i>=0;i=i-1)
BUFFER6[i*IDW+:IDW]<=
BUFFER6[(i+1)*IDW+:IDW];
//---------------------------------------------------------
BUFFER7[23*IDW+:IDW]<={ofm_din    [7],
                       ofm_din_vld[7],
                       ofm_din_meg[7]};for(i=22;i>=0;i=i-1)
BUFFER7[i*IDW+:IDW]<=
BUFFER7[(i+1)*IDW+:IDW];
//---------------------------------------------------------
BUFFER8[22*IDW+:IDW]<={ofm_din    [8],
                       ofm_din_vld[8],
                       ofm_din_meg[8]};for(i=21;i>=0;i=i-1)
BUFFER8[i*IDW+:IDW]<=
BUFFER8[(i+1)*IDW+:IDW];
//---------------------------------------------------------
BUFFER9[21*IDW+:IDW]<={ofm_din    [9],
                       ofm_din_vld[9],
                       ofm_din_meg[9]};for(i=20;i>=0;i=i-1)
BUFFER9[i*IDW+:IDW]<=
BUFFER9[(i+1)*IDW+:IDW];
//---------------------------------------------------------
BUFFER10[20*IDW+:IDW]<={ofm_din    [10],
                        ofm_din_vld[10],
                        ofm_din_meg[10]};for(i=19;i>=0;i=i-1)
BUFFER10[i*IDW+:IDW]<=
BUFFER10[(i+1)*IDW+:IDW];
//---------------------------------------------------------
BUFFER11[19*IDW+:IDW]<={ofm_din    [11],
                        ofm_din_vld[11],
                        ofm_din_meg[11]};for(i=18;i>=0;i=i-1)
BUFFER11[i*IDW+:IDW]<=
BUFFER11[(i+1)*IDW+:IDW];
//---------------------------------------------------------
BUFFER12[18*IDW+:IDW]<={ofm_din    [12],
                        ofm_din_vld[12],
                        ofm_din_meg[12]};for(i=17;i>=0;i=i-1)
BUFFER12[i*IDW+:IDW]<=
BUFFER12[(i+1)*IDW+:IDW];
//---------------------------------------------------------
BUFFER13[17*IDW+:IDW]<={ofm_din    [13],
                        ofm_din_vld[13],
                        ofm_din_meg[13]};for(i=16;i>=0;i=i-1)
BUFFER13[i*IDW+:IDW]<=
BUFFER13[(i+1)*IDW+:IDW];
//---------------------------------------------------------
BUFFER14[16*IDW+:IDW]<={ofm_din    [14],
                        ofm_din_vld[14],
                        ofm_din_meg[14]};for(i=15;i>=0;i=i-1)
BUFFER14[i*IDW+:IDW]<=
BUFFER14[(i+1)*IDW+:IDW];
//---------------------------------------------------------
BUFFER15[15*IDW+:IDW]<={ofm_din    [15],
                        ofm_din_vld[15],
                        ofm_din_meg[15]};for(i=14;i>=0;i=i-1)
BUFFER15[i*IDW+:IDW]<=
BUFFER15[(i+1)*IDW+:IDW];
//---------------------------------------------------------
BUFFER16[14*IDW+:IDW]<={ofm_din    [16],
                        ofm_din_vld[16],
                        ofm_din_meg[16]};for(i=13;i>=0;i=i-1)
BUFFER16[i*IDW+:IDW]<=
BUFFER16[(i+1)*IDW+:IDW];
//---------------------------------------------------------
BUFFER17[13*IDW+:IDW]<={ofm_din    [17],
                        ofm_din_vld[17],
                        ofm_din_meg[17]};for(i=12;i>=0;i=i-1)
BUFFER17[i*IDW+:IDW]<=
BUFFER17[(i+1)*IDW+:IDW];
//---------------------------------------------------------
BUFFER18[12*IDW+:IDW]<={ofm_din    [18],
                        ofm_din_vld[18],
                        ofm_din_meg[18]};for(i=11;i>=0;i=i-1)
BUFFER18[i*IDW+:IDW]<=
BUFFER18[(i+1)*IDW+:IDW];
//---------------------------------------------------------
BUFFER19[11*IDW+:IDW]<={ofm_din    [19],
                        ofm_din_vld[19],
                        ofm_din_meg[19]};for(i=10;i>=0;i=i-1)
BUFFER19[i*IDW+:IDW]<=
BUFFER19[(i+1)*IDW+:IDW];
//---------------------------------------------------------
BUFFER20[10*IDW+:IDW]<={ofm_din    [20],
                        ofm_din_vld[20],
                        ofm_din_meg[20]};for(i=9;i>=0;i=i-1)
BUFFER20[i*IDW+:IDW]<=
BUFFER20[(i+1)*IDW+:IDW];
//---------------------------------------------------------
BUFFER21[9*IDW+:IDW]<={ofm_din    [21],
                       ofm_din_vld[21],
                       ofm_din_meg[21]};for(i=8;i>=0;i=i-1)
BUFFER21[i*IDW+:IDW]<=
BUFFER21[(i+1)*IDW+:IDW];
//---------------------------------------------------------
BUFFER22[8*IDW+:IDW]<={ofm_din    [22],
                       ofm_din_vld[22],
                       ofm_din_meg[22]};for(i=7;i>=0;i=i-1)
BUFFER22[i*IDW+:IDW]<=
BUFFER22[(i+1)*IDW+:IDW];
//---------------------------------------------------------
BUFFER23[7*IDW+:IDW]<={ofm_din    [23],
                       ofm_din_vld[23],
                       ofm_din_meg[23]};for(i=6;i>=0;i=i-1)
BUFFER23[i*IDW+:IDW]<=
BUFFER23[(i+1)*IDW+:IDW];
//---------------------------------------------------------
BUFFER24[6*IDW+:IDW]<={ofm_din    [24],
                       ofm_din_vld[24],
                       ofm_din_meg[24]};for(i=5;i>=0;i=i-1)
BUFFER24[i*IDW+:IDW]<=
BUFFER24[(i+1)*IDW+:IDW];
//---------------------------------------------------------
BUFFER25[5*IDW+:IDW]<={ofm_din    [25],
                       ofm_din_vld[25],
                       ofm_din_meg[25]};for(i=4;i>=0;i=i-1)
BUFFER25[i*IDW+:IDW]<=
BUFFER25[(i+1)*IDW+:IDW];
//---------------------------------------------------------
BUFFER26[4*IDW+:IDW]<={ofm_din    [26],
                       ofm_din_vld[26],
                       ofm_din_meg[26]};for(i=3;i>=0;i=i-1)
BUFFER26[i*IDW+:IDW]<=
BUFFER26[(i+1)*IDW+:IDW];
//---------------------------------------------------------
BUFFER27[3*IDW+:IDW]<={ofm_din    [27],
                       ofm_din_vld[27],
                       ofm_din_meg[27]};for(i=2;i>=0;i=i-1)
BUFFER27[i*IDW+:IDW]<=
BUFFER27[(i+1)*IDW+:IDW];
//---------------------------------------------------------
BUFFER28[2*IDW+:IDW]<={ofm_din    [28],
                       ofm_din_vld[28],
                       ofm_din_meg[28]};for(i=1;i>=0;i=i-1)
BUFFER28[i*IDW+:IDW]<=
BUFFER28[(i+1)*IDW+:IDW];
//---------------------------------------------------------
BUFFER29[1*IDW+:IDW]<={ofm_din    [29],
                       ofm_din_vld[29],
                       ofm_din_meg[29]};
BUFFER29[0*IDW+:IDW]<=
BUFFER29[1*IDW+:IDW];
//---------------------------------------------------------
BUFFER30[0*IDW+:IDW]<={ofm_din    [30],
                       ofm_din_vld[30],
                       ofm_din_meg[30]};
//---------------------------------------------------------
end
assign BUFFER31[0*IDW+:IDW]={ofm_din    [31],
                             ofm_din_vld[31],
                             ofm_din_meg[31]};
//---------------------------------------------------------

//for(i=0;i<NUM;i=i+1)


always @(posedge clk)
`ifdef SIM_CODE
if(~BUFFER0[1])
begin
    align_data    <=0;
    align_data_vld<=0;
    align_data_meg<=0;
end else 
`endif
begin
{align_data    [0],
 align_data_vld[0],
 align_data_meg[0]}<=
          BUFFER0[0*IDW+:IDW];
//----------------------------
{align_data    [1],
 align_data_vld[1],
 align_data_meg[1]}<=
          BUFFER1[0*IDW+:IDW];
//----------------------------
{align_data    [2],
 align_data_vld[2],
 align_data_meg[2]}<=
          BUFFER2[0*IDW+:IDW];
//----------------------------
{align_data    [3],
 align_data_vld[3],
 align_data_meg[3]}<=
          BUFFER3[0*IDW+:IDW];
//----------------------------
{align_data    [4],
 align_data_vld[4],
 align_data_meg[4]}<=
          BUFFER4[0*IDW+:IDW];
//----------------------------
{align_data    [5],
 align_data_vld[5],
 align_data_meg[5]}<=
          BUFFER5[0*IDW+:IDW];
//----------------------------
{align_data    [6],
 align_data_vld[6],
 align_data_meg[6]}<=
          BUFFER6[0*IDW+:IDW];
//----------------------------
{align_data    [7],
 align_data_vld[7],
 align_data_meg[7]}<=
          BUFFER7[0*IDW+:IDW];
//----------------------------
{align_data    [8],
 align_data_vld[8],
 align_data_meg[8]}<=
          BUFFER8[0*IDW+:IDW];
//----------------------------
{align_data    [9],
 align_data_vld[9],
 align_data_meg[9]}<=
          BUFFER9[0*IDW+:IDW];
//----------------------------
{align_data    [10],
 align_data_vld[10],
 align_data_meg[10]}<=
          BUFFER10[0*IDW+:IDW];
//----------------------------
{align_data    [11],
 align_data_vld[11],
 align_data_meg[11]}<=
          BUFFER11[0*IDW+:IDW];
//----------------------------
{align_data    [12],
 align_data_vld[12],
 align_data_meg[12]}<=
          BUFFER12[0*IDW+:IDW];
//----------------------------
{align_data    [13],
 align_data_vld[13],
 align_data_meg[13]}<=
          BUFFER13[0*IDW+:IDW];
//----------------------------
{align_data    [14],
 align_data_vld[14],
 align_data_meg[14]}<=
          BUFFER14[0*IDW+:IDW];
//----------------------------
{align_data    [15],
 align_data_vld[15],
 align_data_meg[15]}<=
          BUFFER15[0*IDW+:IDW];
//----------------------------
{align_data    [16],
 align_data_vld[16],
 align_data_meg[16]}<=
          BUFFER16[0*IDW+:IDW];
//----------------------------
{align_data    [17],
 align_data_vld[17],
 align_data_meg[17]}<=
          BUFFER17[0*IDW+:IDW];
//----------------------------
{align_data    [18],
 align_data_vld[18],
 align_data_meg[18]}<=
          BUFFER18[0*IDW+:IDW];
//----------------------------
{align_data    [19],
 align_data_vld[19],
 align_data_meg[19]}<=
          BUFFER19[0*IDW+:IDW];
//----------------------------
{align_data    [20],
 align_data_vld[20],
 align_data_meg[20]}<=
          BUFFER20[0*IDW+:IDW];
//----------------------------
{align_data    [21],
 align_data_vld[21],
 align_data_meg[21]}<=
          BUFFER21[0*IDW+:IDW];
//----------------------------
{align_data    [22],
 align_data_vld[22],
 align_data_meg[22]}<=
          BUFFER22[0*IDW+:IDW];
//----------------------------
{align_data    [23],
 align_data_vld[23],
 align_data_meg[23]}<=
          BUFFER23[0*IDW+:IDW];
//----------------------------
{align_data    [24],
 align_data_vld[24],
 align_data_meg[24]}<=
          BUFFER24[0*IDW+:IDW];
//----------------------------
{align_data    [25],
 align_data_vld[25],
 align_data_meg[25]}<=
          BUFFER25[0*IDW+:IDW];
//----------------------------
{align_data    [26],
 align_data_vld[26],
 align_data_meg[26]}<=
          BUFFER26[0*IDW+:IDW];
//----------------------------
{align_data    [27],
 align_data_vld[27],
 align_data_meg[27]}<=
          BUFFER27[0*IDW+:IDW];
//----------------------------
{align_data    [28],
 align_data_vld[28],
 align_data_meg[28]}<=
          BUFFER28[0*IDW+:IDW];
//----------------------------
{align_data    [29],
 align_data_vld[29],
 align_data_meg[29]}<=
          BUFFER29[0*IDW+:IDW];
//----------------------------
{align_data    [30],
 align_data_vld[30],
 align_data_meg[30]}<=
          BUFFER30[0*IDW+:IDW];
//----------------------------
{align_data    [31],
 align_data_vld[31],
 align_data_meg[31]}<=
          BUFFER31[0*IDW+:IDW];
//----------------------------
end



endmodule
