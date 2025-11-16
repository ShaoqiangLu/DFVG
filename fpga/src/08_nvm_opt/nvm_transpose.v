`timescale 1ns / 1ps
// -----------------------------------------------------------------------------
// Copyright      : UCLA EDA LAB
// -----------------------------------------------------------------------------
// Engineer       : Chen Wu
// Design Name    : opu series
// Module Name    : transpose
// Target Devices : 325t, Alveo U200
// Tool Versions  : Vivado 2020.1, Modelsim 2019.4
// Description    : 
//    Transpose a matrix.
//    Only support the case when ROW = COL
//
// Revision       :
// Version        Date        Author        Descriptin
// 1.0            2022-04-08  Chen Wu       Initial version
// 2.0            2023-08-25  Shaoqiang     Simulation 97 layers,and       
//                                          implementation on FPGA of U200.
// -----------------------------------------------------------------------------
//        cycle0   cycle1    cycle2    cycle3                     cycle0   cycle1    cycle2    cycle3
//highbit [3]      [7]       [11]      [14]                         [15]    [14]      [13]      [12]
//        [2]      [6]       [10]      [13]                         [11]    [10]      [9 ]      [8 ]
//        [1]      [5]       [9]       [12]                         [7 ]    [6 ]      [5 ]      [4 ]
//low-bit [0]      [4]       [8]       [11]                         [3 ]    [2 ]      [1 ]      [0 ]      
//         |        |         |         |         biffer    
//         |        |         |         ---->[15][14][13][12]        |
//         |        |         -------------->[11][10][9 ][8 ]        |
//         |        ------------------------>[7 ][6 ][5 ][4 ] --------
//         --------------------------------->[3 ][2 ][1 ][0 ]  
//                                           high     low

`include "opu_parameter.vh"
module nvm_transpose #(
  parameter    DW          =     16                ,
  parameter    NUM         =     32                                                 
) (
  input                          clk               ,
  input                          reset             ,  
  input                          tr_din_vld        ,
  input                          tr_din_done       ,
  input        [DW*NUM-1 : 0]    tr_din_data       ,
  
  output  reg  [DW*NUM-1 : 0]    tr_dout_data   =0 ,
  output  reg                    tr_dout_vld    =0 ,
  output  reg                    tr_dout_done   =0 
  
     
);
  localparam    TR_RAM_DEEP  =32;
  localparam    TR_RAM_CYCLE =1 ;
  localparam    TR_RAM_ADDR  =6 ;


  integer i=0,j=0;
  (*dont_touch="true"*)                     reg [TR_RAM_ADDR-1:0]           w0_cnt0=0;
  (*dont_touch="true"*)                     reg [TR_RAM_ADDR-1:0]           w0_cnt1=0;
                                            wire                            w0_ctrl0;
                                            wire                            w0_ctrl1;
  (*max_fanout=16,extract_enable="yes"*)    reg [TR_RAM_DEEP*NUM-1:0]       w1_wen0=0;
  (*max_fanout=16,extract_enable="yes"*)    reg [TR_RAM_DEEP*NUM-1:0]       w1_wen1=0;
  (*max_fanout=16*)                         reg [4*(DW*NUM)-1:0]            w1_din0_r=0;
  (*max_fanout=16*)                         reg [4*(DW*NUM)-1:0]            w1_din1_r=0; 
                                            wire[TR_RAM_DEEP*(DW*NUM)-1:0]  w1_din0={8{w1_din0_r}}; 
                                            wire[TR_RAM_DEEP*(DW*NUM)-1:0]  w1_din1={8{w1_din1_r}}; 
                                            
                                            
  (*ram_style="distributed"*)reg[DW-1:0]BUFFER0[TR_RAM_DEEP-1:0][NUM-1:0];
  (*ram_style="distributed"*)reg[DW-1:0]BUFFER1[TR_RAM_DEEP-1:0][NUM-1:0];   
  
  //--------------------------------------------------------------------------------------------------
  //write
  //--------------------------------------------------------------------------------------------------

  always @(posedge clk)
  if(tr_din_vld   )w0_cnt0<=
                   w0_cnt0+1;
  else             w0_cnt0<=0;

  always @(posedge clk)
  if(tr_din_vld   )w0_cnt1<=
                   w0_cnt1+1;
  else             w0_cnt1<=0;

  assign w0_ctrl0=w0_cnt0[(TR_RAM_ADDR-1)-1:0]==0&~w0_cnt0[TR_RAM_ADDR-1]&tr_din_vld;
  assign w0_ctrl1=w0_cnt1[(TR_RAM_ADDR-1)-1:0]==0& w0_cnt1[TR_RAM_ADDR-1]&tr_din_vld;


  always @(posedge clk)
  for(i=0;i<TR_RAM_DEEP;i=i+1)
  if(i==0) w1_wen0[ i*   NUM+:NUM]<={NUM{w0_ctrl0}};
  else     w1_wen0[ i*   NUM+:NUM]<=
           w1_wen0[(i-1)*NUM+:NUM];

  always @(posedge clk)
  for(i=0;i<TR_RAM_DEEP;i=i+1)
  if(i==0) w1_wen1[ i*   NUM+:NUM]<={NUM{w0_ctrl1}};
  else     w1_wen1[ i*   NUM+:NUM]<=
           w1_wen1[(i-1)*NUM+:NUM];

  always @(posedge clk)
  begin
  w1_din0_r<={4{tr_din_data}};
  w1_din1_r<={4{tr_din_data}};
  end

  always @(posedge clk)
  `ifdef SIM_CODE
  if(reset)begin
  for(i=0; i< TR_RAM_DEEP;i=i+1)
  for(j=0; j< NUM        ;j=j+1)
  BUFFER0[i][j]<=0;
  end else
  `endif
  begin
  for(i=0; i< TR_RAM_DEEP;i=i+1)
  for(j=0; j< NUM        ;j=j+1)
  if(w1_wen0[i*NUM+j+:1])
     BUFFER0[i][j]<=
     w1_din0[i*(DW*NUM)+j*DW+:DW];
  end

  always @(posedge clk)
  `ifdef SIM_CODE
  if(reset)begin
  for(i=0; i< TR_RAM_DEEP;i=i+1)
  for(j=0; j< NUM        ;j=j+1)
  BUFFER1[i][j]<=0;
  end else
  `endif
  for(i=0; i< TR_RAM_DEEP;i=i+1)
  for(j=0; j< NUM        ;j=j+1)
  if(w1_wen1[i*NUM+j+:1])
     BUFFER1[i][j]<=
     w1_din1[i*(DW*NUM)+j*DW+:DW];

  //--------------------------------------------------------------------------------------------------
  //read
  //--------------------------------------------------------------------------------------------------
  reg [NUM-1:0]r0_tr_din_vld =0;
  reg [NUM-1:0]r0_tr_din_done=0;
  always @(posedge clk)
  for(i=0;i<NUM;i=i+1)
  if(i==0)begin
      r0_tr_din_vld [i]<=tr_din_vld ;
      r0_tr_din_done[i]<=tr_din_done;
  end else begin
      r0_tr_din_vld [i]<=r0_tr_din_vld [i-1];
      r0_tr_din_done[i]<=r0_tr_din_done[i-1];
  end
 
  (*dont_touch="true"*)reg [TR_RAM_ADDR-1:0]r0_cnt0=0;
  (*dont_touch="true"*)reg [TR_RAM_ADDR-1:0]r0_cnt1=0;
  always @(posedge clk)
  if(r0_tr_din_vld[31])r0_cnt0<=
                       r0_cnt0+1;
  else                 r0_cnt0<=0;

  always @(posedge clk)
  if(r0_tr_din_vld[31])r0_cnt1<=
                       r0_cnt1+1;
  else                 r0_cnt1<=0;

  (*dont_touch="true"*)reg [  4*TR_RAM_ADDR-1:0]r1_cnt0=0;
  (*dont_touch="true"*)reg [  4*TR_RAM_ADDR-1:0]r1_cnt1=0;
  (*dont_touch="true"*)reg [NUM*TR_RAM_ADDR-1:0]r2_cnt0=0;
  (*dont_touch="true"*)reg [NUM*TR_RAM_ADDR-1:0]r2_cnt1=0;
  always @(posedge clk)
  begin
      r1_cnt0<={4{r0_cnt0}};
      r1_cnt1<={4{r0_cnt1}};
      r2_cnt0<={8{r1_cnt0}};
      r2_cnt1<={8{r1_cnt1}};
  end


  (*max_fanout=16*)reg [4  -1:0]r2_rpp=0;
  (*max_fanout=16*)reg [NUM-1:0]r3_rpp=0;
  always @(posedge clk)
  begin
  for(i=0;i<4;i=i+1)
  r2_rpp[i]<=r1_cnt0[i*TR_RAM_ADDR+TR_RAM_ADDR-1];
  
  r3_rpp<={8{r2_rpp}};
  end

  reg [DW*NUM-1:0] r3_data0=0;
  reg [DW*NUM-1:0] r3_data1=0;

  always @(posedge clk)
  for(i=0;i<NUM;i=i+1)
  r3_data0[i*DW+:DW]<=
   BUFFER0[i][
   r2_cnt0[i*TR_RAM_ADDR+:(TR_RAM_ADDR-1)]];

  
  always @(posedge clk)
  for(i=0;i<NUM;i=i+1)
  r3_data1[i*DW+:DW]<=
   BUFFER1[i][
   r2_cnt1[i*TR_RAM_ADDR+:(TR_RAM_ADDR-1)]];



  //------------------------------------------------------
  //
  //------------------------------------------------------

  reg  [3-1:0]r_tr_dout_vld =0;
  reg  [3-1:0]r_tr_dout_done=0;

  always @(posedge clk)
  begin
  r_tr_dout_vld [0]<=r0_tr_din_vld [31];
  r_tr_dout_done[0]<=r0_tr_din_done[31];
  
  r_tr_dout_vld [1]<=r_tr_dout_vld [0];
  r_tr_dout_done[1]<=r_tr_dout_done[0];

  r_tr_dout_vld [2]<=r_tr_dout_vld [1];
  r_tr_dout_done[2]<=r_tr_dout_done[1];

  tr_dout_vld      <=r_tr_dout_vld [2];
  tr_dout_done     <=r_tr_dout_done[2];
  end



`ifndef SIM_CODE
  always @(posedge clk)
  for(i=0;i<NUM;i=i+1)
  if(r3_rpp[i])tr_dout_data[i*DW+:DW]<=r3_data1[i*DW+:DW];
  else         tr_dout_data[i*DW+:DW]<=r3_data0[i*DW+:DW];

`else
  always @(posedge clk)
  for(i=0;i<NUM;i=i+1)
  if(r3_rpp[i])tr_dout_data[i*DW+:DW]<=~r_tr_dout_vld [2]?0:r3_data1[i*DW+:DW];
  else         tr_dout_data[i*DW+:DW]<=~r_tr_dout_vld [2]?0:r3_data0[i*DW+:DW];
`endif










endmodule