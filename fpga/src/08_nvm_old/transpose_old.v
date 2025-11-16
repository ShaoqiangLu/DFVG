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
// -----------------------------------------------------------------------------


module transpose_old #(
  parameter           DW          =     16                                ,
  parameter           NUM         =     32                                ,

  localparam          ADW         =     DW*NUM                             
  ) (
  output  reg         [ADW-1 : 0]       tr_dout = 0                       ,
  output  reg                           tr_dout_vld = 0                   ,
  output  reg                           tr_dout_done= 0                   ,

  input               [ADW-1 : 0]       tr_din                            ,
  input                                 tr_din_vld                        ,
  input                                 tr_din_done                       ,

  input                                 enable                            ,
  input                                 clk                               ,
  input                                 reset                   
  );

  reg                [ADW-1 : 0]        r_tr_din      =0                  ;
  reg                                   r_tr_din_vld  =0                  ;
  reg                                   r_tr_din_done =0                  ;
  always @(posedge clk) begin
        r_tr_din      <= tr_din      ; 
        r_tr_din_vld  <= tr_din_vld  ;
        r_tr_din_done <= tr_din_done ;

  end


  localparam          CDW         =     $clog2(NUM)                       ;
  reg                 [  CDW : 0]       tr_din_cnt = 0                    ;
  reg                 [ADW-1 : 0]       TR_BUFFER[2*NUM-1:0]              ;
  wire                                  tr_pp                             ;
  wire                                  tr_dout_start                     ;
  reg                                   tr_dout_running =0                ;
  reg                 [CDW-1 : 0]       tr_dout_cnt     =0                ;
  wire                                  tr_cnt_done                       ;
  reg                                   enable_r        =0                ;

  always @(posedge clk) enable_r <= enable;
  



  always @(posedge clk) begin
    if ( r_tr_din_vld )
      tr_din_cnt            <=    tr_din_cnt + 1                          ;
  end


  integer i;
  always @(posedge clk) begin
  if(reset) for(i=0; i<=2*NUM;i=i+1) TR_BUFFER[i]<=0;
    else
    if ( r_tr_din_vld )
      TR_BUFFER[tr_din_cnt]    <=    r_tr_din                               ;
  end





  assign  tr_pp             =     tr_din_cnt >= NUM                       ;
  assign  tr_dout_start     =     ((tr_din_cnt + 1 == NUM) |
                                   (tr_din_cnt + 1 == NUM*2)) &r_tr_din_vld ;
  assign  tr_cnt_done       =      tr_dout_cnt + 1 == NUM                  ;
  
  
  always @(posedge clk) begin
    if ( reset )
      tr_dout_running       <=    1'b0                                    ;
    else if ( tr_cnt_done & (~tr_dout_start) )
      tr_dout_running       <=    1'b0                                    ;
    else if ( tr_dout_start )
      tr_dout_running       <=    1'b1                                    ;
  end


  always @(posedge clk) begin
    if ( reset )
      tr_dout_cnt           <=    0                                       ;
    else if ( tr_dout_running )
      tr_dout_cnt           <=    tr_dout_cnt + 1                         ;
  end







  //------------------------------------------------------------------------
  // output
  //------------------------------------------------------------------------
  generate for ( genvar i = 0; i < NUM; i = i + 1 ) begin
  reg         [DW-1 : 0]       buffer_dout = 0                            ;
    always @(posedge clk)
    if ( tr_pp )
        buffer_dout <= TR_BUFFER[NUM-1-i][(NUM-1-tr_dout_cnt)*DW +: DW]   ;
      else
        buffer_dout <= TR_BUFFER[NUM*2-1-i][(NUM-1-tr_dout_cnt)*DW +: DW] ;
 
    always @(posedge clk)
    if ( enable_r ) tr_dout[DW*i +: DW]<=buffer_dout;
    else            tr_dout[DW*i +: DW]<=0;
  end
  endgenerate








   reg                           r1_tr_dout_vld = 0                        ;
   reg                           r1_tr_dout_done= 0                        ;
   reg                           r2_tr_dout_vld = 0                        ;
   reg                           r2_tr_dout_done= 0                        ;
   always @(posedge clk)
   if(enable_r)begin
      r1_tr_dout_vld         <=tr_dout_running     ;
      r1_tr_dout_done        <=tr_cnt_done         ;
      r2_tr_dout_vld         <=r1_tr_dout_vld      ;
      r2_tr_dout_done        <=r1_tr_dout_done     ;
      tr_dout_vld            <=r2_tr_dout_vld      ;
      tr_dout_done           <=r2_tr_dout_done     ;



   end else begin
      r1_tr_dout_vld         <=0;
      r1_tr_dout_done        <=0;
      r2_tr_dout_vld         <=0;
      r2_tr_dout_done        <=0;
      tr_dout_vld            <=0;
      tr_dout_done           <=0;
   end



  

endmodule