`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/11/24 16:57:15
// Design Name: 
// Module Name: comparator
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
 //----------------------------------------------------------------------------
 //Calculate the length of the data packet
 //dout=dividend/divisor
 //Quotient is the lowest 16bit, and the rest are the divisor results
 //DIV_mean out is[95:0],
 //integer is  [95:32]Q64_0,
 //fraction is [31:0 ]Q32_31
 //Q64_14  / Q16_0   =[95:32]Q64_14,[31:0]Q32_31>>>(31-14)
 //Q64_28  / Q16_0   =[95:32]Q64_28,[31:0]Q32_31>>>(31-28)
 //DIV_mean :The integer   is [79:16]_Q64_0 ,
 //          The remainder is [15:0 ]_Q16_15
 //----------------------------------------------------------------------------
`include "opu_parameter.vh"
module nvm_ln_vmean_div #(    
    parameter           DW_multi            = 40                ,
    parameter           DW_PKG              = 16                ,
    parameter           DW_OUT              = 16                ,
    parameter           DLY_Mean_DIV        = 16                
)(
    input                                   clk                 ,
    input                                   rst                 ,
    input               [12-1:0]            nvm_xnum            ,
    input               [DW_multi-1:0]      sum_sync            ,
    input                                   sum_sync_val        ,
    input                                   sum_sync_done       ,
    input               [DW_PKG-1:0]        pkg_sync_acc        ,

    output wire         [DW_OUT-1:0]        mean_out            ,
    output wire                             mean_out_val        ,
    output wire                             mean_out_done       ,
    output wire                             mean_out_val_pre    ,

    output reg          [40-1:0]            ln_mean_dividend=0  ,
    output reg          [16-1:0]            ln_mean_divisor =0  ,
    input  wire         [48-1:0]            ln_mean_result          
);


  always @(posedge clk) 
  begin
    ln_mean_dividend        <=    sum_sync                      ;
    ln_mean_divisor         <=    pkg_sync_acc                  ;
  end
  
  (*dont_touch="true"*)reg [48-1:0]       r0_mean_result    =0  ;
  (*dont_touch="true"*)reg [DW_multi-1:0] r1_mean_result_int=0  ;//integer, Q24_15
  (*dont_touch="true"*)reg [DW_multi-1:0] r1_mean_result_poi=0  ;//point  , Q24_15
  (*dont_touch="true"*)reg [DW_multi-1:0] r2_mean_result    =0  ;//-------->Q24_15

  (*dont_touch="true"*)reg [5-1:0]        r0_xnum =0            ;

  


  always @(posedge clk) 
  begin
    r0_xnum             <=  31-nvm_xnum                         ;
  
    r0_mean_result      <=  ln_mean_result                      ;
    r1_mean_result_int  <=  $signed(r0_mean_result[8+:DW_multi]);//<<<nvm_xnum2;;
    r1_mean_result_poi  <=  $signed({{(DW_multi-8){r0_mean_result[7]}},
                             r0_mean_result[0+:8]})>>>r0_xnum   ;
    r2_mean_result      <=  r1_mean_result_int                  ;
  end
  
  `ifndef SIM_CODE
  assign mean_out       =   r2_mean_result[0+:DW_OUT]           ;
  `else
  assign mean_out=~mean_out_val?0:r2_mean_result[0+:DW_OUT]     ;
  `endif
  //----------------------------------------------------------------
  //
  //----------------------------------------------------------------
  integer i=0,j=0;
  
  reg [2*DLY_Mean_DIV-1:0] dly_vd =0;
  always @(posedge clk) 
  for(i=0;i<DLY_Mean_DIV;i=i+1)
  if(i==0)dly_vd[i*2+:2]    <=  {sum_sync_val,sum_sync_done}    ;
  else    dly_vd[i*2+:2]    <=  dly_vd[(i-1)*2+:2];
  
  assign mean_out_val        =  dly_vd[(DLY_Mean_DIV-1)*2+1]    ; 
  assign mean_out_done       =  dly_vd[(DLY_Mean_DIV-1)*2+0]    ;
  assign mean_out_val_pre    =  dly_vd[(DLY_Mean_DIV-3)*2+1]    ;
  
  
  
endmodule
