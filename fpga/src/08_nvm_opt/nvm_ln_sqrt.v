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
//    This module is the mean function for layer_normalization. 
//    The NUM_ELEMS is the number of input elements.
//    It first compute the mean and the variance.
//    The variance is adding with a epsilon(a small count), then square root.
//    Then, substract the mean , variance division, for each elements.
//    
//    The root is implemented by LUT.
//    Next optimizing direction is using division, root IP, using pipline.
//                            Xij-Mean
//   Layer_Norm=-------------------------------
//                { Sum(Xij-Mean)^2 /n  }^(1/2)
// Revision       :
// Version        Date        Author        Descriptin
// 1.0            2021-03-31  Yiheng Jian   Initial version
// 1.1            2022-04-04  Chen Wu       Add beta, gamma, shift
// 2.0            2022-05-08  Chen Wu       Delete BG to reduce resource
// 2.1            2022-07-18  LuShaoqiang   Shared divider with sf module,Reduce Buffer
// -----------------------------------------------------------------------------

`include "opu_parameter.vh"
module nvm_ln_sqrt # (
    parameter   DW_IN           =   48,
    parameter   DW_OUT          =   24, // Input element data width
    parameter   NUM_ELEMS       =   32, // Number of input elements in a single cycle
    parameter   DLY_sqrt        =   15 
) (
    input                                       clk                 ,
    input                                       rst                 ,
    input                                       sqrt_in_val         ,
    input                                       sqrt_in_done        ,
    input       [DW_IN-1:0]                     sqrt_in_data        ,
    output  wire[NUM_ELEMS*DW_OUT-1:0]          ln_sqrt_out_data    ,//ln1:Q32_14,ln2:Q32_9
    output  reg                                 ln_sqrt_fifo_ren  =0,
    output  reg                                 ln_sqrt_out_vld   =0,
    output  reg                                 ln_sqrt_out_done  =0             
);

    //------------------------------------------------------------------------------
    //calculation a root operation on data
    //open root is 13cycles
    //------------------------------------------------------------------------------
    (*dont_touch="true"*)reg [DW_IN   -1:0]    r0_sqrt_in_data  =0  ;
    wire                     [DW_OUT  -1:0]    r0_sqrt_out_data     ;
    (*dont_touch="true"*)reg [DW_OUT*4-1:0]    r1_sqrt_out_data =0  ;
    
    always @(posedge clk)
    begin
        r0_sqrt_in_data        <=sqrt_in_data                       ;
        r1_sqrt_out_data       <={4{r0_sqrt_out_data}}              ;
    end
    
    assign ln_sqrt_out_data={8{r1_sqrt_out_data}}                   ;
    
    //------------------------------------------------------------------------------
    //
    //------------------------------------------------------------------------------
    (*keep_hierarchy="yes"*)Sqrt_cordic ln_sqrt(
      .aclk                         ( clk                           ),
      .s_axis_cartesian_tdata       ( r0_sqrt_in_data               ),  
      .s_axis_cartesian_tvalid      ( 1'b1                          ),
      .m_axis_dout_tdata            ( r0_sqrt_out_data              ),//ln1:Q32_14,ln2:Q32_9
      .m_axis_dout_tvalid           (                               )
    );

    integer     i=0,j=0;
    reg     [2*DLY_sqrt-1:0]        dly_dv   =0                     ;
    
    always @(posedge clk)
    for(i=0;i<DLY_sqrt;i=i+1)
    if(i==0)dly_dv[i*2+:2]<=      {sqrt_in_val,sqrt_in_done}        ;
     else   dly_dv[i*2+:2]<=      dly_dv[(i-1)*2+:2]                ;
             
     always @(posedge clk)
     begin
         ln_sqrt_out_vld    <=      dly_dv[(DLY_sqrt-1)*2+1]        ;
         ln_sqrt_fifo_ren   <=      dly_dv[(DLY_sqrt-3)*2+1]        ;
         ln_sqrt_out_done   <=      dly_dv[(DLY_sqrt-1)*2+0]        ;
     end

 



endmodule
