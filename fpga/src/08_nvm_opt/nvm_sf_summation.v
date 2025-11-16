`timescale 1ns / 1ps
// -----------------------------------------------------------------------------
// Copyright      : UCLA EDA LAB
// -----------------------------------------------------------------------------
// Engineer       : Chen Wu
// Design Name    : opu series
// Module Name    : ifm_top
// Target Devices : 325t, Alveo U200
// Tool Versions  : Vivado 2020.1, Modelsim 2019.4
// Description    : 
//    This is pipelined soft_max module in NPE, with a 16 elements 16-bit vector 
//    input and the same sized output.
//    x_i is Q16_9,  y is Q16_14. 
//    The input data transfer is done by set pkg_done signal. 
//    The vector length should be N*16.
//    The NUM_ELEMS is the number of fixed-points handled per cycle,
//    MAX_PKG_LEN is the maximum number of row buffers can be used. 
//    x_neg is the intermediate results where x_neg = x - x_max,
//    exp[i] is the results from linear approximation module, 
//    sum_y is the sum of exp[i]. 
//                exp(Xij-Max)
//    Softmax=----------------------------
//                sum{exp(Xij-Max)}
// Revision       :
// Version        Date        Author        Descriptin
// 1.0            2020-11-06  Yiheng Jian   Initial version
// 1.1            2022-04-04  Chen Wu       Align definition, change stype
// 1.2            2022-07-19  Lushaoqiang   whit LN module share buffer and divider
// -----------------------------------------------------------------------------

`include "opu_parameter.vh"
module nvm_sf_summation #(
  parameter     NUM_ELEMS                   = 32                    ,
  parameter     DW_IN                       = 16                    ,
  parameter     DW_OUT                      = 24                    
)(
  input                                     clk                     ,
  input                                     rst                     ,

  input         [7-1:0]                     nvm_rstep               ,
  input         [NUM_ELEMS-1:0][DW_IN-1:0]  sf_sum_in_data          ,////Fix Q16_9
  input                                     sf_sum_in_val           ,
  input                                     sf_sum_in_done          ,

  output  reg   [NUM_ELEMS-1:0][DW_OUT-1:0] sf_sum_out_data =0      ,//Fix Q16_15
  output  reg                               sf_sum_out_vld  =0      ,
  output  reg                               sf_sum_out_done =0      ,
  output  reg                               sf_sum_fifo_ren =0      
);

  integer i=0,j=0;

  localparam SUM_WIDTH = DW_IN + $clog2(NUM_ELEMS)                  ;
  wire[SUM_WIDTH-1:0]       sum_single_cycle_data                   ;
  reg                       sum_single_cycle_val  =0                ; 
  reg                       sum_single_cycle_done =0                ; 
  (*keep_hierarchy="yes"*)nvm_sf_vsum # (
        .IN_WIDTH           ( DW_IN                                 ),
        .NUM_ELEMS          ( NUM_ELEMS                             )
  )sf_vsum(
        .clk                ( clk                                   ),
        .data               ( sf_sum_in_data                        ),
        .sum                ( sum_single_cycle_data                 )//Fix Q21_14
  );

  reg [2*2-1:0] dly_vd=0; 
  
  always @(posedge clk)
  begin
      dly_vd[0*2+:2]<={sf_sum_in_val,sf_sum_in_done}                ;
      dly_vd[1*2+:2]<=dly_vd[0*2+:2]                                ;
      {sum_single_cycle_val,sum_single_cycle_done}<=dly_vd[1*2+:2]  ;
  end
  
  //-------------------------------------------------------------------
  //The accumulation of the current cycle and the next cycle
  //-------------------------------------------------------------------
  wire                              sum_next_cycle_first            ;
  reg signed [DW_OUT-1:0]           sum_next_cycle_data =0          ;//Fix Q32_14
  reg                               sum_next_cycle_val  =0          ;
  (*max_fanout=16*)reg              sum_next_cycle_done =0          ;
  
  assign sum_next_cycle_first=sum_single_cycle_val&(~sum_next_cycle_val);
  
  always @(posedge clk)
  if(sum_single_cycle_val)begin
  if(sum_next_cycle_done|sum_next_cycle_first)
         sum_next_cycle_data<={{(DW_OUT-SUM_WIDTH)
          {sum_single_cycle_data[SUM_WIDTH-1]}}, 
           sum_single_cycle_data}                                   ;
  
  else   sum_next_cycle_data<={{(DW_OUT-SUM_WIDTH)
          {sum_single_cycle_data[SUM_WIDTH-1]}}, 
           sum_single_cycle_data}+sum_next_cycle_data               ;
  end else sum_next_cycle_data<='b0                                 ;
  
  always @(posedge clk)
  begin
    sum_next_cycle_val  <=  sum_single_cycle_val                    ;
    sum_next_cycle_done <=  sum_single_cycle_done                   ;
  end


 //--------------------------------------------------------------------
 //At the end of each line. Record current data
 //--------------------------------------------------------------------
  (*dont_touch="true"*)reg signed [4*DW_OUT-1:0] 
                              sum_multi_cycle_data =0               ;//Fix Q32_14
  wire [32*DW_OUT-1:0]        sum_multi_cycle_data_wire             ;
  wire                        sum_multi_cycle_val                   ;
  wire                        sum_multi_cycle_done                  ;
  always @(posedge clk)
  if(sum_next_cycle_done|sum_multi_cycle_done) 
         sum_multi_cycle_data<={4{sum_next_cycle_data}}             ;
  
  assign sum_multi_cycle_data_wire={8{sum_multi_cycle_data}}        ;


  //--------------------------------------------------------------------
  //
  //--------------------------------------------------------------------

  (*dont_touch="true"*)reg   [7-1:0]     r0_nvm_rstep    =0         ;
  (*dont_touch="true"*)reg   [7-1:0]     r1_nvm_rstep    =0         ;
  always @(posedge clk)
  begin
                    r0_nvm_rstep<=nvm_rstep                         ;
    if(nvm_rstep>=2)r1_nvm_rstep<=nvm_rstep-2                       ;
    else            r1_nvm_rstep<=0                                 ;
  end    

  (*keep_hierarchy="yes"*)nvm_dly_cnt #(
    .CDW                ( 7                                         ),
    .DW                 ( 2                                         ),
    .DEEP               ( 64                                        )
  ) cnt_sum_multi_vd(
    .dout               ({sum_multi_cycle_val,sum_multi_cycle_done} ),
    .din                ({sum_next_cycle_val ,sum_next_cycle_done } ),
    .cnt                ( r0_nvm_rstep                              ),
    .clk                ( clk                                       ),
    .reset              ( rst                                       )
  );

 wire r0_sf_sum_fifo_ren    ;
 (*keep_hierarchy="yes"*)nvm_dly_cnt #(
    .CDW                 ( 7                                        ),
    .DW                  ( 1                                        ),
    .DEEP                ( 64                                       )
  ) cnt_sum_fifo_ren_dly(
    .dout                ( r0_sf_sum_fifo_ren                       ),
    .din                 ( sum_next_cycle_val                       ),
    .cnt                 ( r1_nvm_rstep                             ),
    .clk                 ( clk                                      ),
    .reset               ( rst                                      )
  );


 //----------------------------------------------------------------------
 //Output to external for division calculation   
 //Fix Q32_14-->Fix Q24_14 
 //----------------------------------------------------------------------
 
 always @(posedge clk)
 begin 
        `ifndef SIM_CODE
        for(i=0; i<NUM_ELEMS; i=i+1) 
        sf_sum_out_data[i]<= sum_multi_cycle_data_wire[i*DW_OUT+:DW_OUT]; 
        `else
        for(i=0; i<NUM_ELEMS; i=i+1)
        sf_sum_out_data[i]<=~sum_multi_cycle_val?0:
                             sum_multi_cycle_data_wire[i*DW_OUT+:DW_OUT]; 
        `endif
        sf_sum_out_vld    <=sum_multi_cycle_val                     ;
        sf_sum_out_done   <=sum_multi_cycle_done                    ;
        sf_sum_fifo_ren   <=r0_sf_sum_fifo_ren                      ;
 end



endmodule
