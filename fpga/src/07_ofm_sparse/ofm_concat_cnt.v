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


module ofm_concat_cnt# (
  parameter                                 DWCNT       =  4    ,
  parameter                                 RATIO       =  8    ,
  parameter                                 CNUM        =  512  ,
  parameter                                 CMAX        =  16                      
) (
  input                                     clk                 ,
  input                                     rvld                ,
  input         [128*38 -1:0]               rdata               ,
  output reg    [CNUM-1:0][DWCNT-1:0]       cnt0        =   0   ,
  output reg    [CNUM-1:0][DWCNT-1:0]       cnt1        =   0   ,
  output reg    [CNUM-1:0]                  sel         =   0           
);

  integer i=0,j=0;
  (*max_fanout=16*)reg [CNUM     -1:0]      r_vld0      =   0   ;
  (*max_fanout=16*)reg [(DWCNT+1)-1:0]      r_cnt0[CNUM-1:0]    ;
  (*max_fanout=16*)reg [CNUM     -1:0]      r_vld1      =   0   ;  
  (*max_fanout=16*)reg [(DWCNT+1)-1:0]      r_cnt1[CNUM-1:0]    ;

  always @(posedge clk)
  for(i=0;i<CNUM/2;i=i+1)
  if(r_vld0[i])begin
       cnt0[i]<= cnt0[i]+r_cnt0[i]                              ;
       sel [i]<=(cnt0[i]+r_cnt0[i])>=16                         ;
  end 
  else begin 
       cnt0[i]<=0                                               ;
       sel [i]<=0                                               ;
  end

  always @(posedge clk)
  for(i=CNUM/2;i<CNUM;i=i+1)
  if(r_vld0[i])begin
       cnt0[i]<= cnt0[i]+r_cnt0[i]                              ;
  //   sel [i]<=(cnt0[i]+r_cnt0[i])>=16                         ;
  end 
  else begin 
       cnt0[i]<=0                                               ;
  //   sel [i]<=0                                               ;
  end
  //-------------------------------------------------------------
  always @(posedge clk)
  for(i=0;i<CNUM/2;i=i+1)
  if(r_vld1[i])begin
       cnt1[i]<= cnt1[i]+r_cnt1[i]                              ;
  //   sel [i]<=(cnt1[i]+r_cnt1[i)>=16                          ;
  end 
  else begin 
       cnt1[i]<=0                                               ;
  //   sel [i]<=0                                               ;
  end

  always @(posedge clk)
  for(i=CNUM/2;i<CNUM;i=i+1)
  if(r_vld1[i])begin
       cnt1[i]<= cnt1[i]+r_cnt1[i]                              ;
       sel [i]<=(cnt1[i]+r_cnt1[i])>=16                         ;
  end 
  else begin 
       cnt1[i]<=0                                               ;
       sel [i]<=0                                               ;
  end

  reg [(DWCNT+1)-1:0]rcnt_reg[2-1:0]                            ;
  reg [2        -1:0]rvld_reg       =0                          ;

 always @(posedge clk)
 begin
   rvld_reg <=  {2{rvld}}                                       ;
 
   rcnt_reg[0]<=
      rdata[(RATIO*1 -1)*38+:1]                                 +//7
      rdata[(RATIO*2 -1)*38+:1]                                 +//15
      rdata[(RATIO*3 -1)*38+:1]                                 +
      rdata[(RATIO*4 -1)*38+:1]                                 +
      rdata[(RATIO*5 -1)*38+:1]                                 +
      rdata[(RATIO*6 -1)*38+:1]                                 +
      rdata[(RATIO*7 -1)*38+:1]                                 +
      rdata[(RATIO*8 -1)*38+:1]                                 +
      rdata[(RATIO*9 -1)*38+:1]                                 +
      rdata[(RATIO*10-1)*38+:1]                                 +
      rdata[(RATIO*11-1)*38+:1]                                 +
      rdata[(RATIO*12-1)*38+:1]                                 +
      rdata[(RATIO*13-1)*38+:1]                                 +
      rdata[(RATIO*14-1)*38+:1]                                 +
      rdata[(RATIO*15-1)*38+:1]                                 +
      rdata[(RATIO*16-1)*38+:1]                                 ;//127
      
   rcnt_reg[1]<=
      rdata[(RATIO*1 -1)*38+:1]                                 +//7
      rdata[(RATIO*2 -1)*38+:1]                                 +//15
      rdata[(RATIO*3 -1)*38+:1]                                 +
      rdata[(RATIO*4 -1)*38+:1]                                 +
      rdata[(RATIO*5 -1)*38+:1]                                 +
      rdata[(RATIO*6 -1)*38+:1]                                 +
      rdata[(RATIO*7 -1)*38+:1]                                 +
      rdata[(RATIO*8 -1)*38+:1]                                 +
      rdata[(RATIO*9 -1)*38+:1]                                 +
      rdata[(RATIO*10-1)*38+:1]                                 +
      rdata[(RATIO*11-1)*38+:1]                                 +
      rdata[(RATIO*12-1)*38+:1]                                 +
      rdata[(RATIO*13-1)*38+:1]                                 +
      rdata[(RATIO*14-1)*38+:1]                                 +
      rdata[(RATIO*15-1)*38+:1]                                 +
      rdata[(RATIO*16-1)*38+:1]                                 ;//127
  end
 
 
  always @(posedge clk)
  for(i=0;i<CNUM;i=i+1)
  begin
      r_vld0[i]     <=  rvld_reg[0]                             ;
      r_cnt0[i]     <=  rcnt_reg[0]                             ;
      r_vld1[i]     <=  rvld_reg[0]                             ;
      r_cnt1[i]     <=  rcnt_reg[1]                             ;
  end



endmodule
