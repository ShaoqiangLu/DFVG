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
module nvm_ln_mac # (
    parameter           NUM_ELEMS       = 32,
    parameter           DW_IN           = 24,
    parameter           DW_b            = 40,
    parameter           DW_g            = 16,
    parameter           DW_OUT          = 16, // Input element data width
    parameter           DLY_mac         = 16
)(
    input                                               clk                 ,
    input                                               rst                 ,

    input               [12-1:0]                        nvm_gnum            ,
    input               [12-1:0]                        nvm_bnum            ,
    input               [12-1:0]                        nvm_xnum            ,
    input               [12-1:0]                        nvm_ynum            ,


    input                                               mac_in_vld          ,
    input                                               mac_in_done         ,
    input               [NUM_ELEMS-1:0][DW_IN-1:0]      mac_in_data         ,//Q24_15

    input                                               param_rvld          ,
    input               [NUM_ELEMS-1:0][DW_b-1:0]       beta_rdata          ,   
    input               [NUM_ELEMS-1:0][DW_g-1:0]       gamma_rdata         ,


    output                                              mac_out_vld         ,
    output                                              mac_out_done        ,
    output   reg        [NUM_ELEMS-1:0][DW_OUT-1:0]     mac_out_data =0     ,//Q24_15

    output   reg        [NUM_ELEMS-1:0][24-1:0]         A_mac_out    =0     ,
    output   reg        [NUM_ELEMS-1:0][16-1:0]         B_mac_out    =0     ,
    output   reg        [NUM_ELEMS-1:0][40-1:0]         C_mac_out    =0     ,
    output   reg        [NUM_ELEMS-1:0][24-1:0]         D_mac_out    =0     ,
    input               [NUM_ELEMS*40-1:0]              P_mac_in            //15+r0_gnum
);

    integer i=0,j=0;

`ifndef SIM_CODE
    always @(posedge clk)
    for(i=0;i<NUM_ELEMS;i=i+1) 
    begin
        A_mac_out   [i] <=mac_in_data [i]                       ;
        B_mac_out   [i] <=gamma_rdata [i]                       ;
        C_mac_out   [i] <=beta_rdata  [i]                       ;
        D_mac_out   [i] <=24'd0                                 ;    
    end
`else
    always @(posedge clk)
    for(i=0;i<NUM_ELEMS;i=i+1) 
    begin
        A_mac_out   [i] <=~mac_in_vld?0:mac_in_data [i]         ;
        B_mac_out   [i] <=~param_rvld?0:gamma_rdata [i]         ;
        C_mac_out   [i] <=~param_rvld?0:beta_rdata  [i]         ;
        D_mac_out   [i] <=24'd0                                 ;
    
    end
`endif

    (*dont_touch="true"*)reg [5-1:0] r0_ynum          =0        ;
    (*dont_touch="true"*)reg [5-1:0] r0_gnum          =0        ;
    (*dont_touch="true"*)reg [NUM_ELEMS* 5-1:0]r1_sfit_num=0    ;
    (*dont_touch="true"*)reg [NUM_ELEMS*40-1:0]r1_P_mac_in=0    ; 
    always @(posedge clk)
    begin
        r0_ynum<=   nvm_ynum[5-1:0]                             ;
        r0_gnum<=   nvm_gnum[5-1:0]                             ;
        for(i=0;i<NUM_ELEMS;i=i+1)
        r1_sfit_num[i*5+:5]<=15+r0_gnum-r0_ynum                 ;
    end

    always @(posedge clk)
    for(i=0;i<NUM_ELEMS;i=i+1)//layer6 Q16_9,layer 8 Q16_11
    begin
    r1_P_mac_in[i*40+:40]<=P_mac_in[i*40+:40]                   ;
    mac_out_data[i]<=r1_P_mac_in[i*40+:40]>>>r1_sfit_num[i*5+:5];
    end

    //------------------------------------------------------------------------------
    //
    //------------------------------------------------------------------------------
    reg [DLY_mac*2-1:0]  dly_dv  =0                             ;

    always @(posedge clk)
    for(i=0;i<DLY_mac;i=i+1)
    if(i==0)dly_dv[i*2+:2]<={mac_in_vld,mac_in_done}            ;
    else    dly_dv[i*2+:2]<=dly_dv[(i-1)*2+:2]                  ;

    assign  mac_out_vld    = dly_dv[(DLY_mac-1)*2+1]            ;
    assign  mac_out_done   = dly_dv[(DLY_mac-1)*2+0]            ;



endmodule
