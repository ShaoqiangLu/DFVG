`timescale 1ns / 1ps
// -----------------------------------------------------------------------------
// Copyright      : UCLA EDA LAB
// -----------------------------------------------------------------------------
// Engineer       : Chen Wu
// Design Name    : opu series
// Module Name    : dly_cnt
// Target Devices : 
// Tool Versions  : Vivado 2020.1, Modelsim 2019.4
// Description    : 
//    Delay unit.
// Revision       :
// Version        Date        Author        Descriptin
// 1.0            2020-05-27  Chen Wu       Initial version
// 2.0            2023-09-10  Shaoqiang     Use a counter approach for latency, 
//                                          as there are some areas where latency needs to be changed.
// -----------------------------------------------------------------------------


module nvm_dly_cnt #(
    parameter       CDW         =7          ,
    parameter       DW          =1          ,
    parameter       DEEP        =64
)(
    output  wire   [DW-1 : 0]   dout        ,
    input          [DW-1 : 0]   din         ,
    input   wire   [CDW-1: 0]   cnt         ,
    input                       clk         ,
    input                       reset     
);
//---------------------------------------------------
//---------------------------------------------------
integer i=0,j=0;
(*ram_style="distributed"*)
reg[DW-1:0]BUFFER[DEEP:1]                   ;
//---------------------------------------------------
//---------------------------------------------------
always @(posedge clk)
for(i=1;i<=DEEP;i=i+1) 
if(i==1)begin
if(reset)BUFFER[i]<=0                       ;
else     BUFFER[i]<=din                     ; 
end else BUFFER[i]<=BUFFER[(i-1)]           ;

//---------------------------------------------------
//---------------------------------------------------
(*dont_touch="true"*)reg [DW -1:0]r_dout=0  ;
(*dont_touch="true"*)reg [CDW-1:0]r_cnt =1  ;
always @(posedge clk)
if(cnt>=2)r_cnt<=cnt-1                      ;
else      r_cnt<=1                          ;

always @(posedge clk)
if(reset)r_dout <= 0                        ;
else     r_dout <= BUFFER[r_cnt]            ;


//---------------------------------------------------
//---------------------------------------------------
(*dont_touch="true"*)reg [3-1:0]out_ctrl=0  ;
always @(posedge clk)
begin
    out_ctrl[0]<=   cnt ==0                 ;
    out_ctrl[1]<=   cnt ==1                 ;
    out_ctrl[2]<=   cnt >=2                 ;
end


assign dout=out_ctrl[0]  ?   din
           :out_ctrl[1]  ?   BUFFER[1]
           :out_ctrl[2]  ?   r_dout:0       ;
         
endmodule