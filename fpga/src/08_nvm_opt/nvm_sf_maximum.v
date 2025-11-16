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


module nvm_sf_maximum #(
  parameter     DATA_WIDTH                        = 16              , 
  parameter     NUM_ELEMS                         = 32              , 
  parameter     MAX_PKG_LEN                       = 24              ,
  parameter     NUM_SEGS                          = 32              , 
  parameter     POS_WIDTH                         = 8
) (
  input                                           clk               ,
  input                                           rst               ,
  input                                           enable            ,
  input         [7-1:0]                           nvm_rstep         ,
  input                                           sf_max_in_val     ,
  input                                           sf_max_in_done    ,
  input         [NUM_ELEMS*DATA_WIDTH-1:0]        sf_max_in_data    ,////Fix Q16_9
  output        [DATA_WIDTH-1:0]                  sf_max_out_data   ,////Fix Q16_9
  output                                          sf_max_out_val    ,
  output                                          sf_max_out_done   ,
  output                                          sf_max_fifo_ren   
);

 integer i=0,j=0;

 //--------------------------------------------------------------------
 //Comparison of 32 data within a single cycle. Requires 3 clocks
 //--------------------------------------------------------------------
  wire signed [DATA_WIDTH-1:0] max_single_cycle_data                ;//Fix Q16_9
  reg                          max_single_cycle_val  =0             ;
  reg                          max_single_cycle_done =0             ;
  
  (*keep_hierarchy="yes"*)nvm_sf_vmax #(
      .DATA_WIDTH           (DATA_WIDTH                             ), 
      .NUM_ELEMS            (NUM_ELEMS                              )
  )u_sf_vmax(
      .clk                  (clk                                    ),
      .max_in               (sf_max_in_data                         ),
      .max_out              (max_single_cycle_data                  )
  );

  (*dont_touch="true"*) reg [2*2-1:0]   dly_ms_val_done=0           ;
  always @(posedge clk)
  begin
      dly_ms_val_done[0*2+:2]<={sf_max_in_val,sf_max_in_done}       ;
      dly_ms_val_done[1*2+:2]<= dly_ms_val_done[0*2+:2]             ;
      {max_single_cycle_val,max_single_cycle_done}
      <=dly_ms_val_done[1*2+:2]                                     ;
  end

  //-------------------------------------------------------------------
  //Compare the max of the current cycle with the max of the next cycle
  //--------------------------------------------------------------------
  wire                        max_next_first                        ;
  reg signed [DATA_WIDTH-1:0] max_next_cycle_data =0                ;//Fix Q16_9
  (*max_fanout=16*)reg        max_next_cycle_val  =0                ;
  (*max_fanout=16*)reg        max_next_cycle_done =0                ;

  assign  max_next_first=max_single_cycle_val&(~max_next_cycle_val) ;
  
  always @(posedge clk)
  if (max_single_cycle_val) 
  begin
  if(max_next_cycle_done|max_next_first)
          max_next_cycle_data   <= max_single_cycle_data            ;
  else    max_next_cycle_data   <= 
        $signed(max_next_cycle_data)>$signed(max_single_cycle_data)? 
                max_next_cycle_data:max_single_cycle_data           ;  
  end else      max_next_cycle_data   <= 0                          ;

  always @(posedge clk)
  begin
    max_next_cycle_val  <=      max_single_cycle_val                ;
    max_next_cycle_done <=      max_single_cycle_done               ;
  end


  //------------------------------------------------------------------
  //At the end of each row, obtain the maximum value for that row.
  //reg  signed [DATA_WIDTH-1:0] max_data ;
  //-------------------------------------------------------------------
  reg signed [DATA_WIDTH-1:0] max_multi_cycle_data =0               ;//Fix Q16_9
  wire                        max_multi_cycle_val                   ;
  wire                        max_multi_cycle_done                  ;
  always @(posedge clk)
  begin
        if(max_next_cycle_done|max_multi_cycle_done)
           max_multi_cycle_data<=max_next_cycle_data                ;
  end


  (*dont_touch="true"*)reg [7-1:0]  r0_nvm_rstep =0                 ;
  (*dont_touch="true"*)reg [7-1:0]  r1_nvm_rstep =0                 ;
  always @(posedge clk)
  begin
        r0_nvm_rstep <= nvm_rstep                                   ;
        
        if(nvm_rstep>=2)
        r1_nvm_rstep <= nvm_rstep-2                                 ;
        else r1_nvm_rstep <=0;
  end



  (*keep_hierarchy="yes"*)nvm_dly_cnt #(
    .CDW                 (7                                         ),
    .DW                  (2                                         ),
    .DEEP                (64                                        )
  ) cnt_max_multi_vd(
    .dout                ({max_multi_cycle_val,max_multi_cycle_done }),
    .din                 ({max_next_cycle_val ,max_next_cycle_done  }),
    .cnt                 ( r0_nvm_rstep                                ),
    .clk                 (clk                                       ),
    .reset               (1'b0                                      )
  );


  //------------------------------------------------------------------
  //Instruct fifo1 to start reading data
  //Advance one cycle
  //-----------------------------------------------------------------
  (*keep_hierarchy="yes"*)nvm_dly_cnt #(
    .CDW                 ( 7                                        ),
    .DW                  ( 1                                        ),
    .DEEP                ( 64                                       )
  ) cnt_max_fifo_ren(
    .dout                ( sf_max_fifo_ren                          ),
    .din                 ( max_next_cycle_val                       ),
    .cnt                 ( r1_nvm_rstep                             ),
    .clk                 ( clk                                      ),
    .reset               ( 1'b0                                     )
  );

  assign            sf_max_out_data     = max_multi_cycle_data      ;
  assign            sf_max_out_val      = max_multi_cycle_val       ;
  assign            sf_max_out_done     = max_multi_cycle_done      ;


endmodule
