`timescale 1ns / 1ps
// -----------------------------------------------------------------------------
// Orgnization: UCLA EDA lab
// Design Name    : opu series
// Module Name    : output_ctrl_top
// Target Devices : k325t
// Tool Versions  : Vivado 2020.1, Modelsim 2019.4
// Description    : 
//    Add bias or temp results to finalize the calculation of one convolutional
//    layer.
// Revision       :
// Version        Date        Author          Description
// 1.0            2017-10-25  Chen Wu         Initial version
// 1.1            2020-02-04  Chen Wu         Modify code style
// 3.1            2021-02-01  Shan Shen       Change data width to 42 from 26
// 3.2            2021-04-07  Jinming Zhuang  Modify & specify the sequential 
//                                            relationship in internal signals
// 4.0            2021-04-26  Chen Wu         Add parameter & delete rearrange
// 4.1            2022-04--7  Chen Wu         Simplify for INT16 case, add pp
// 5.0            2022-09-14  Shaoqiang       Simulation 97 layers,and       
//                                            implementation on FPGA of U200.
// -----------------------------------------------------------------------------
//for example:
// din:Q37_33   din_sum =10, <<< become is  Q37_43
//bias:Q32_34   bias_sum=9 , <<< become is  Q37_43  
// adder out is Q38_43
// psum is ,(38-32) >>> become Q32_37
// tmp_psum is Q32_37 <<< become Q37_43
// psum_cut is Q16_17
module ofm_shift #(
  parameter  NUM            =               32              ,
  parameter  PNUM           =               4               ,
  parameter  DW_OFM         =               37              ,
  parameter  DW_BIAS        =               32              ,
  parameter  DW_ADD         =               42     
)(
  input                                     clk             ,
  input                                     reset           ,
  input      [5-1:0]                        ofm_din_snum    ,
  input      [5-1:0]                        ofm_bias_snum   ,
  
  input                                     ofm_vld_in      ,
  input      [NUM*PNUM-1:0][DW_OFM -1:0]    ofm_data_in     ,
  input      [NUM*PNUM-1:0][DW_BIAS-1:0]    ofm_bias_in     ,
  output wire[NUM*PNUM*     DW_ADD -1:0]    ofm_data_out    ,
  output wire[NUM*PNUM*     DW_ADD -1:0]    ofm_bias_out    , 
  output reg                                ofm_vld_out =0

);

(*keep_hierarchy="yes"*)
ofm_shift_unit #(
  .NUM              (NUM*PNUM               ),
  .IDW              (DW_OFM                 ),
  .ODW              (DW_ADD                 )     
)u_ofm_shift_unit_din(
  .clk              (clk                    ),
  .reset            (reset                  ),
  .shift_num        (ofm_din_snum           ),
  .shift_in         (ofm_data_in            ),
  .shift_out        (ofm_data_out           )
);

(*keep_hierarchy="yes"*)
ofm_shift_unit #(
  .NUM              (NUM*PNUM               ),
  .IDW              (DW_BIAS                ),
  .ODW              (DW_ADD                 )     
)u_ofm_shift_unit_bias(
  .clk              (clk                    ),
  .reset            (reset                  ),
  .shift_num        (ofm_bias_snum          ),
  .shift_in         (ofm_bias_in            ),
  .shift_out        (ofm_bias_out           )
);

//----------------------------------------------------
//
//----------------------------------------------------

reg [2-1:0] r0_ofm_vld_in=0;
always @(posedge clk)
begin
    r0_ofm_vld_in[0]    <=  ofm_vld_in      ;
    r0_ofm_vld_in[1]    <=  r0_ofm_vld_in[0];
    ofm_vld_out         <=  r0_ofm_vld_in[1];
end



endmodule


