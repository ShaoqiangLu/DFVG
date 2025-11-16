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
module nvm_soft_max #(
  parameter     DATA_WIDTH    =     16                              , 
  parameter     NUM_ELEMS     =     32                              , 
  parameter     MAX_PKG_LEN   =     24                              ,
  parameter     NUM_SEGS      =     32                              , 
  parameter     POS_WIDTH     =     8
) (
  input                                           clk               ,
  input                                           rst               ,
  input                                           enable            ,
  input         [7-1:0]                           nvm_rstep         ,
  input         [NUM_ELEMS*DATA_WIDTH-1:0]        sf_max_in_data    ,////Fix Q16_9
  input                                           sf_max_in_val     ,
  input                                           sf_max_in_done    ,
  
  output                                          sf_max_fifo_ren   ,
  input         [NUM_ELEMS*DATA_WIDTH-1:0]        sf_sub_in_data    ,//Fix Q16_9
  input                                           sf_sub_in_val     ,
  input                                           sf_sub_in_done    ,
  
  output        [NUM_ELEMS*DATA_WIDTH-1:0]        sf_exp_out_data   ,//Fix Q16_14
  output                                          sf_exp_out_val    ,
  output                                          sf_exp_out_done   ,

  output                                          sf_sum_fifo_ren   ,
  output  wire  [NUM_ELEMS*24-1:0]                sf_sum_out_data   ,//Fix Q32_14
  output  wire                                    sf_sum_out_vld    ,
  output  wire                                    sf_sum_out_done   ,

  input                                           sf_div_in_vld     ,
  input         [NUM_ELEMS*24-1:0]                sf_div_in_data    ,//Fix Q25_15
  input                                           sf_div_in_done    ,
  
  output        [NUM_ELEMS*DATA_WIDTH-1:0]        sf_shfto_data_o   ,//Fix Q16_15
  output                                          sf_shfto_vld_o    ,
  output                                          sf_shfto_done_o   ,
  
  input         [NUM_ELEMS*DATA_WIDTH-1:0]        sf_shfto_data_i   ,
  input                                           sf_shfto_vld_i    ,
  input                                           sf_shfto_done_i   ,

  output  reg   [NUM_ELEMS*DATA_WIDTH-1:0]        sf_dout_data =0   , 
  output  reg                                     sf_dout_vld  =0   ,
  output  reg                                     sf_dout_done =0   ,
  
  output        [NUM_ELEMS*17-1:0]                A_exp_out         ,
  output        [NUM_ELEMS*15-1:0]                B_exp_out         ,
  output        [NUM_ELEMS*32-1:0]                C_exp_out         ,
  output        [NUM_ELEMS*17-1:0]                D_exp_out         ,
  input         [NUM_ELEMS*32-1:0]                P_exp_in  
);

  integer i=0,j=0;
 
  //--------------------------------------------------------------------------
  //
  //--------------------------------------------------------------------------

  wire signed [DATA_WIDTH-1:0]sf_max_out_data                       ;//Fix Q16_9
  wire                        sf_max_out_val                        ;
  wire                        sf_max_out_done                       ;

  (*keep_hierarchy="yes"*)nvm_sf_maximum #(
      .DATA_WIDTH           (16                                     ), 
      .NUM_ELEMS            (32                                     ) 
  )u_sf_maximum(
      .clk                  (clk                                    ),
      .rst                  (rst                                    ),
      .enable               (enable                                 ),
      .nvm_rstep            (nvm_rstep                              ),
      .sf_max_in_val        (sf_max_in_val                          ),
      .sf_max_in_done       (sf_max_in_done                         ),
      .sf_max_in_data       (sf_max_in_data                         ),////Fix Q16_9
      .sf_max_out_data      (sf_max_out_data                        ),////Fix Q16_9
      .sf_max_out_val       (sf_max_out_val                         ),
      .sf_max_out_done      (sf_max_out_done                        ),
      .sf_max_fifo_ren      (sf_max_fifo_ren                        )
  );


  //--------------------------------------------------------------------------
  //
  //--------------------------------------------------------------------------

 wire signed [NUM_ELEMS*(DATA_WIDTH+1)-1:0] sub_result_data         ;//Fix Q17_9
 wire                                       sub_result_val          ;
 wire                                       sub_result_done         ;
 //C=A-B
 (*keep_hierarchy="yes"*)nvm_sf_vsub #(
     .DATA_WIDTH         ( DATA_WIDTH                               ),
     .NUM_ELEMS          ( NUM_ELEMS                                )
 )sf_vsub(
     .clk                ( clk                                      ),
     .rst                ( 1'b0                                     ),
     .A_done             ( sf_sub_in_done                           ),
     .A_vld              ( sf_sub_in_val                            ),
     .A_in               ( sf_sub_in_data                           ),//Fix Q16_9
     .B_in               ( sf_max_out_data                          ),//Fix Q16_9
     .C_out              ( sub_result_data                          ),
     .C_vld              ( sub_result_val                           ),
     .C_done             ( sub_result_done                          )
 );


  //--------------------------------------------------------------------------
  //Calculate the exp index and make a linear approximation of exp
  //--------------------------------------------------------------------------


  wire signed [NUM_ELEMS*DATA_WIDTH-1:0]    sf_exp_result_data      ;//Fix Q16_14
  wire                                      sf_exp_result_vld       ;
  wire                                      sf_exp_result_done      ;

  //(A+D)*B+C
  (*keep_hierarchy="yes"*)nvm_sf_exp #(
    .NUM_ELEMS          (NUM_ELEMS                                  ), 
    .DATA_WIDTH         (DATA_WIDTH                                 ),
    .DLY                (15 )
 )sf_exp(
    .clk                (clk                                        ), 
    .rst                (1'b0                                       ), 
    .x_val              (sub_result_val                             ),
    .x_done             (sub_result_done                            ),
    .x_data             (sub_result_data                            ),//Fix Q17_9
    .y_val              (sf_exp_result_vld                          ),
    .y_done             (sf_exp_result_done                         ),
    .y_data             (sf_exp_result_data                         ),//Fix Q16_14
    .A_exp_out          (A_exp_out                                  ),
    .B_exp_out          (B_exp_out                                  ),
    .C_exp_out          (C_exp_out                                  ),
    .D_exp_out          (D_exp_out                                  ),
    .P_exp_in           (P_exp_in                                   )
  );

  `ifndef SIM_CODE
  assign  sf_exp_out_data   = sf_exp_result_data                    ;//Fix Q16_14
  `else
  assign  sf_exp_out_data   =~sf_exp_out_val?0:sf_exp_result_data   ;//Fix Q16_14
  `endif
  assign  sf_exp_out_val    = sf_exp_result_vld                     ;
  assign  sf_exp_out_done   = sf_exp_result_done                    ;



  //----------------------------------------------------------------------------
  //Add 32 data within a cycle
  //2**5=32,  SUM_WIDTH=16+5=21
  //----------------------------------------------------------------------------

  (*keep_hierarchy="yes"*)nvm_sf_summation #(
      .NUM_ELEMS        (NUM_ELEMS                                  ),
      .DW_IN            (DATA_WIDTH                                 ),
      .DW_OUT           (24                                         )
  )u_sf_summation(
      .clk              (clk                                        ),
      .rst              (rst                                        ),
      .nvm_rstep        (nvm_rstep                                  ),
      .sf_sum_in_data   (sf_exp_result_data                         ),////Fix Q16_9
      .sf_sum_in_val    (sf_exp_result_vld                          ),
      .sf_sum_in_done   (sf_exp_result_done                         ),
      .sf_sum_out_data  (sf_sum_out_data                            ),//Fix Q16_15
      .sf_sum_out_vld   (sf_sum_out_vld                             ),
      .sf_sum_out_done  (sf_sum_out_done                            ),
      .sf_sum_fifo_ren  (sf_sum_fifo_ren                            )
 );

 //--------------------------------------------------------------------
 //Cut the bit width of data: sf is Fix Q24_15--->Fix Q16_14
 //--------------------------------------------------------------------
  reg[NUM_ELEMS*DATA_WIDTH-1:0] div_result_data=0                   ;
  reg                           div_result_vld =0                   ;
  reg                           div_result_done=0                   ;

  always @(posedge clk)
  for(i=0; i<NUM_ELEMS; i=i+1) 
     div_result_data[i*DATA_WIDTH+:DATA_WIDTH]
     <={sf_div_in_data[i*24+24-1],sf_div_in_data[i*24+1+:15]}         ;
  always @(posedge clk)
  begin
      div_result_vld    <=  sf_div_in_vld                           ; 
      div_result_done   <=  sf_div_in_done                          ;
  end


 //----------------------------------------------------------------------
 //Shift operation according to the 
 //accuracy requirements of output data
 //init is Fix Q16_15
 //----------------------------------------------------------------------
 wire [NUM_ELEMS*DATA_WIDTH-1:0]shfto_result                        ;
 wire                           shfto_vld                           ;
 wire                           shfto_done                          ;
 
 `ifndef SIM_CODE
 assign sf_shfto_data_o  =  div_result_data                         ;//Fix Q16_14
 `else
 assign sf_shfto_data_o  = ~div_result_vld?0:div_result_data        ;
 `endif
 assign sf_shfto_vld_o   =  div_result_vld                          ;
 assign sf_shfto_done_o  =  div_result_done                         ;

 assign shfto_result     =  sf_shfto_data_i                         ;
 assign shfto_vld        =  sf_shfto_vld_i                          ;
 assign shfto_done       =  sf_shfto_done_i                         ;


 //----------------------------------------------------------
 //Final data output
 always @(posedge clk)
 begin
    `ifndef SIM_CODE
     sf_dout_data   <=       shfto_result                           ;
     `else
     sf_dout_data   <=~enable?0:shfto_result                        ;
     `endif
     sf_dout_vld    <=  enable&shfto_vld                            ;
     sf_dout_done   <=  enable&shfto_done                           ;
 end



endmodule
