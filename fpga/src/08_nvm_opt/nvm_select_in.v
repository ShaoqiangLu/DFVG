`timescale 1ns / 1ps
// -----------------------------------------------------------------------------
// Copyright      : UCLA EDA LAB
// -----------------------------------------------------------------------------
// Engineer       : Chen Wu
// Design Name    : opu series
// Module Name    : nvm_top
// Target Devices : 325t, Alveo U200
// Tool Versions  : Vivado 2020.1, Modelsim 2019.4
// Description    : 
//    Post processes including: residual, GeLU, Softmax, LayerNormalization,
//    Transpose. Each feature can be enabled or not.
//    Attention   : In this design, DW * NUM must be 512 (DDR Datawidth)

`include "opu_parameter.vh"
module nvm_select_in #(
  parameter      DW  = 16     ,
  parameter      NUM = 32                       
) (
  input                       clk               ,
  input                       reset             ,
  input      [5-1:0]          nvm_index_en      ,
  
  input                       nvm_rdata_vld     ,
  input                       nvm_rdata_done    ,
  input      [NUM-1:0][DW-1:0]nvm_rdata         ,
  input      [NUM-1:0][DW-1:0]res_rdata         ,
  input                       res_rvld          ,

  output  reg                 tr_rdata_vld  =0  ,
  output  reg                 tr_rdata_done =0  ,
  output  reg                 sf_rdata_vld  =0  ,
  output  reg                 sf_rdata_done =0  ,
  output  reg                 ln_rdata_vld  =0  ,
  output  reg                 ln_rdata_done =0  ,
  output  reg                 res_rdata_vld =0  ,
  output  reg                 res_rdata_done=0  ,
  output  reg                 act_rdata_vld =0  ,
  output  reg                 act_rdata_done=0  ,
  output  reg                 out_rdata_vld =0  ,
  output  reg                 out_rdata_done=0  ,
 
  output  reg[NUM-1:0][DW-1:0]tr_rdata_in   =0  ,
  output  reg[NUM-1:0][DW-1:0]sf_rdata_in   =0  ,
  output  reg[NUM-1:0][DW-1:0]ln_rdata_in   =0  ,
  output  reg[NUM-1:0][DW-1:0]res_rdata_in  =0  ,  
  output  reg[NUM-1:0][DW-1:0]act_rdata_in  =0  ,  
  output  reg[NUM-1:0][DW-1:0]out_rdata_in  =0   
);



//-----------------------------------------------------------------
//
//-----------------------------------------------------------------
integer i=0,j=0;

(*max_fanout=16*)
reg [3-1:0]dec_eable=0;
always @(posedge clk)
case(nvm_index_en)
    5'b00001:dec_eable<=3'd1;
    5'b00010:dec_eable<=3'd2;
    5'b00100,
    5'b01100,
    5'b01000:dec_eable<=3'd3;
    5'b10000:dec_eable<=3'd4;
    default :dec_eable<=3'd0;
endcase


always @(posedge clk)
case(dec_eable)
3'd1:begin
    tr_rdata_vld   <= nvm_rdata_vld ;
    tr_rdata_done  <= nvm_rdata_done;  
    sf_rdata_vld   <= 0             ;
    sf_rdata_done  <= 0             ;  
    ln_rdata_vld   <= 0             ;
    ln_rdata_done  <= 0             ; 
    res_rdata_vld  <= 0             ;
    res_rdata_done <= 0             ; 
    act_rdata_vld  <= 0             ;
    act_rdata_done <= 0             ;  
    out_rdata_vld  <= 0             ;
    out_rdata_done <= 0             ; 
end
3'd2:begin
    tr_rdata_vld   <= 0             ;
    tr_rdata_done  <= 0             ;  
    sf_rdata_vld   <= nvm_rdata_vld ;
    sf_rdata_done  <= nvm_rdata_done;  
    ln_rdata_vld   <= 0             ;
    ln_rdata_done  <= 0             ; 
    res_rdata_vld  <= 0             ;
    res_rdata_done <= 0             ; 
    act_rdata_vld  <= 0             ;
    act_rdata_done <= 0             ;  
    out_rdata_vld  <= 0             ;
    out_rdata_done <= 0             ; 
end
3'd3:begin
    tr_rdata_vld   <= 0             ;
    tr_rdata_done  <= 0             ;  
    sf_rdata_vld   <= 0             ;
    sf_rdata_done  <= 0             ;  
    ln_rdata_vld   <= nvm_rdata_vld ;
    ln_rdata_done  <= nvm_rdata_done; 
    res_rdata_vld  <= res_rvld      ;
    res_rdata_done <= nvm_rdata_done; 
    act_rdata_vld  <= 0             ;
    act_rdata_done <= 0             ;  
    out_rdata_vld  <= 0             ;
    out_rdata_done <= 0             ; 
end
3'd4:begin
    tr_rdata_vld   <= 0             ;
    tr_rdata_done  <= 0             ;  
    sf_rdata_vld   <= 0             ;
    sf_rdata_done  <= 0             ;  
    ln_rdata_vld   <= 0             ;
    ln_rdata_done  <= 0             ; 
    res_rdata_vld  <= 0             ;
    res_rdata_done <= 0             ; 
    act_rdata_vld  <= nvm_rdata_vld ;
    act_rdata_done <= nvm_rdata_done;  
    out_rdata_vld  <= 0             ;
    out_rdata_done <= 0             ; 
end
default:begin
    tr_rdata_vld   <= 0             ;
    tr_rdata_done  <= 0             ;  
    sf_rdata_vld   <= 0             ;
    sf_rdata_done  <= 0             ;  
    ln_rdata_vld   <= 0             ;
    ln_rdata_done  <= 0             ; 
    res_rdata_vld  <= 0             ;
    res_rdata_done <= 0             ; 
    act_rdata_vld  <= 0             ;
    act_rdata_done <= 0             ;  
    out_rdata_vld  <= nvm_rdata_vld ;
    out_rdata_done <= nvm_rdata_done; 
end
endcase


`ifndef SIM_CODE
always @(posedge clk)
for(i=0;i<NUM;i=i+1)
begin
    tr_rdata_in [i]<= nvm_rdata[i]  ;
    sf_rdata_in [i]<= nvm_rdata[i]  ;
    ln_rdata_in [i]<= nvm_rdata[i]  ;
    res_rdata_in[i]<= res_rdata[i]  ;
    act_rdata_in[i]<= nvm_rdata[i]  ;
    out_rdata_in[i]<= nvm_rdata[i]  ;
end
`else//------------------------------------------
always @(posedge clk)
for(i=0;i<NUM;i=i+1)
case(dec_eable)
3'd1:begin
    tr_rdata_in [i]<=~nvm_rdata_vld?0:nvm_rdata[i];
    sf_rdata_in [i]<=0                ;
    ln_rdata_in [i]<=0                ;
    res_rdata_in[i]<=0                ;
    act_rdata_in[i]<=0                ;
    out_rdata_in[i]<=0                ;
end
3'd2:begin
    tr_rdata_in [i]<=0                ;
    sf_rdata_in [i]<=~nvm_rdata_vld?0:nvm_rdata[i];
    ln_rdata_in [i]<=0                ;
    res_rdata_in[i]<=0                ;
    act_rdata_in[i]<=0                ;
    out_rdata_in[i]<=0                ;
end
3'd3:begin
    tr_rdata_in [i]<=0                ;
    sf_rdata_in [i]<=0                ;
    ln_rdata_in [i]<=~nvm_rdata_vld?0:nvm_rdata[i];
    res_rdata_in[i]<=~res_rvld     ?0:res_rdata[i];
    act_rdata_in[i]<=0                ;
    out_rdata_in[i]<=0                ;
end
3'd4:begin
    tr_rdata_in [i]<=0                ;
    sf_rdata_in [i]<=0                ;
    ln_rdata_in [i]<=0                ;
    res_rdata_in[i]<=0                ;
    act_rdata_in[i]<=~nvm_rdata_vld?0:nvm_rdata[i];
    out_rdata_in[i]<=0                ; 
end
default:begin
    tr_rdata_in [i]<=0                ;
    sf_rdata_in [i]<=0                ;
    ln_rdata_in [i]<=0                ;
    res_rdata_in[i]<=0                ;
    act_rdata_in[i]<=0                ;
    out_rdata_in[i]<=~nvm_rdata_vld?0:nvm_rdata[i]; 
end
endcase//------------------------------------------
`endif




endmodule