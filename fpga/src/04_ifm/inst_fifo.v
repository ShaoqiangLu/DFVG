`timescale 1ns / 1ps
// -----------------------------------------------------------------------------
// Copyright      : UCLA EDA LAB
// -----------------------------------------------------------------------------
// Engineer       : Chen Wu
// Design Name    : opu series
// Module Name    : fifo_w512_r32
// Target Devices : 325t, Alveo U200
// Tool Versions  : Vivado 2020.1, Modelsim 2019.4
// Description    : 
//    First word fall through
//    Write 512 bits, read 32 bits
//
// Revision       :
// Version        Date        Author        Descriptin
// 1.0            2021-08-15  Chen Wu       Initial version
// 2.0            2023-08-25  Shaoqiang     Implementation on FPGA of U200.   
// ---------------------------------------------------------------------------


module inst_fifo (
  input   wire                din_rstart                        ,
  input   wire  [511 : 0]     din                               ,
  input   wire                din_vld                           ,
  output  reg   [ 31 : 0]     dout                              ,
  output  reg                 dout_vld                          ,
  input                       clk                               ,
  input                       reset               
  );

  reg [511:0]                 din_r        =0                   ;
  reg                         din_vld_r    =0                   ;
  reg [10 :0]                 din_64_cnt   =0                   ;
  reg                         ren_256_start=0                   ;
  reg [10 :0]                 ren_256_cnt  =0                   ;
  reg                         ren_256      =0                   ;
  wire[255:0]                 dout_256_r                        ;
  reg [255:0]                 dout_256     =0                   ;
  reg                         wen_256_r    =0                   ;
  reg                         wen_256      =0                   ;
  reg                         wen_256_r1   =0                   ;
  wire                        ren_32_start                      ;
  reg [10 :0]                 ren_32_cnt   =0                   ;
  reg                         ren_32       =0                   ;
  wire[31 :0]                 dout_r                            ;


  always @(posedge clk) din_r<=din;
  always @(posedge clk) din_vld_r<=din_vld;
  reg reset_r1=1;always @(posedge clk) reset_r1<=reset;
  FIFO_inst_w512r256 FIFO0 (
      .din                      (din_r              ), // input wire [511 : 0] din
      .wr_en                    (din_vld_r          ), // input wire wr_en  
      .empty                    (                   ), // output wire empty,empty_256
 
      .dout                     (dout_256_r         ), // output wire [255 : 0] dout  
      .rd_en                    (ren_256            ), // input wire rd_en          
      .full                     (                   ), // output wire full      
  
      .wr_rst_busy              (                   ), // output wire wr_rst_busy
      .rd_rst_busy              (                   ), // output wire rd_rst_busy
      .clk                      (clk                ), // input wire clk
      .srst                     (reset_r1           )  // input wire srst
  );

  //-------------------------------------------------
  always @(posedge clk)
  if(din_rstart) din_64_cnt <=64                    ;
  else if(din_64_cnt==0) din_64_cnt<=0              ;
  else if(din_vld_r) din_64_cnt<=din_64_cnt-1       ;
  
  
  
  always @(posedge clk) 
  if(din_vld_r)   ren_256_start <=din_64_cnt==1     ;
  else ren_256_start<=0                             ;




  always @(posedge clk)
  if(reset)                ren_256_cnt<=128        ;
  else if(ren_256_start)   ren_256_cnt<=0          ;
  else if(ren_256_cnt==128)ren_256_cnt<=ren_256_cnt;
  else                     ren_256_cnt<=ren_256_cnt+1;
  
  always @(posedge clk)
  if(reset)                ren_256<=0              ;
  else if(ren_256_cnt==128)ren_256<=0              ;
  else                     ren_256<=1              ;
  always @(posedge clk)    dout_256<=dout_256_r    ;
  
  always @(posedge clk)    
  if(reset)                wen_256_r <= 0          ;
  else                     wen_256_r <= ren_256    ;
  always @(posedge clk)    
  if(reset)                wen_256   <= 0          ;
  else                     wen_256   <= wen_256_r  ;
  
  
  always @(posedge clk)    
  if(reset)                wen_256_r1<= 0          ;
  else                     wen_256_r1<= wen_256    ;
  
  
  assign ren_32_start =wen_256 && (~wen_256_r1)    ;
  
  
  always @(posedge clk)
  if(reset)                ren_32_cnt<=1024        ;
  else if(ren_32_start)    ren_32_cnt<=0           ;
  else if(ren_32_cnt==1024)ren_32_cnt<=ren_32_cnt  ;
  else                     ren_32_cnt<=ren_32_cnt+1;
  always @(posedge clk)
  if(reset)                ren_32 <=0              ;
  else if(ren_32_cnt==1024)ren_32 <=0              ;
  else                     ren_32 <=1              ;
  reg reset_r2 =1;always @(posedge clk) reset_r2<=reset;
  FIFO_inst_w256r32 FIFO1 (
      .din                      (dout_256           ), // input wire [255 : 0] din
      .wr_en                    (wen_256            ), // input wire wr_en  
      .empty                    (                   ), // output wire empty
      
      .dout                     (dout_r             ), // output wire [31 : 0] dout  
      .rd_en                    (ren_32             ), // input wire rd_en          
      .full                     (                   ), // output wire full      
  
      .wr_rst_busy              (                   ), // output wire wr_rst_busy
      .rd_rst_busy              (                   ), // output wire rd_rst_busy
      .clk                      (clk                ), // input wire clk
      .srst                     (reset_r2           )  // input wire srst
    );

  reg dout_vld_r=0;
  always @(posedge clk)
  if(reset)        dout_vld_r <= 0                  ;
  else             dout_vld_r <= ren_32             ;
  always @(posedge clk) dout_vld<=dout_vld_r        ;

  always @(posedge clk) dout<=dout_r                ;



endmodule