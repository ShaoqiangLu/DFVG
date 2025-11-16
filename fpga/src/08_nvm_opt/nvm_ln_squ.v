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
module nvm_ln_squ # (
    parameter   DW_IN       = 17, // Input element data width
    parameter   NUM_ELEMS   = 32, // Number of input elements in a single cycle
    parameter   DLY_squ     = 32
) (
    input                              clk                 ,
    input                              rst                 ,

    input      [NUM_ELEMS*DW_IN-1:0]   ln_squ_in_data      ,
    input                              ln_squ_in_val       ,
    input                              ln_squ_in_done      ,

    output wire[NUM_ELEMS*2*DW_IN-1:0] ln_squ_result       ,
    output wire                        ln_squ_result_val   ,
    output wire                        ln_squ_result_done  ,

    output wire[NUM_ELEMS*17-1:0]      A_squ_out           ,
    output wire[NUM_ELEMS*17-1:0]      B_squ_out           ,
    input      [NUM_ELEMS*34-1:0]      P_squ_in                
);


    //------------------------------------------------------------------------------
    //The square of data is the product of two data
    //DSP is cycles
    //------------------------------------------------------------------------------

    (*dont_touch="true"*)reg [NUM_ELEMS*17-1:0] r_A_squ_out  =0     ;
    (*dont_touch="true"*)reg [NUM_ELEMS*17-1:0] r_B_squ_out  =0     ;
    (*dont_touch="true"*)reg [NUM_ELEMS*2*DW_IN-1:0]r_ln_squ_result=0;


`ifndef SIM_CODE
    always @(posedge clk)
    begin
        r_A_squ_out         <=  ln_squ_in_data                      ;
        r_B_squ_out         <=  ln_squ_in_data                      ;
        r_ln_squ_result     <=  P_squ_in                            ;
    end
`else
    always @(posedge clk)
    begin
        r_A_squ_out         <=~ln_squ_in_val?0:ln_squ_in_data       ;
        r_B_squ_out         <=~ln_squ_in_val?0:ln_squ_in_data       ;
        r_ln_squ_result     <=  P_squ_in                            ;
    end
`endif



    assign A_squ_out        =   r_A_squ_out                         ;
    assign B_squ_out        =   r_B_squ_out                         ;
    assign ln_squ_result    =   r_ln_squ_result                     ;
    
    
    //--------------------------------------------------------------------------
    //
    //--------------------------------------------------------------------------
    
    integer i=0,j=0;
    reg [2*DLY_squ-1:0] dly_dv =0                                   ;
    
    always @(posedge clk)
    for(i=0;i<DLY_squ;i=i+1)
    if(i==0)dly_dv[i*2+:2]<={ln_squ_in_val,ln_squ_in_done}          ;
    else    dly_dv[i*2+:2]<=dly_dv[(i-1)*2+:2]                      ;
    
    

    assign ln_squ_result_val  =dly_dv[(DLY_squ-1)*2+1]              ;
    assign ln_squ_result_done =dly_dv[(DLY_squ-1)*2+0]              ;
 


endmodule
