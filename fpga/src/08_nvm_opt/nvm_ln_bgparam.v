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
module nvm_ln_bgparam# (
    parameter           NUM_ELEMS   = 32,// Number of input elements in a single cycle
    parameter           DATA_WIDTH  = 16, // Input element data width
    parameter           DW_b        = 40,
    parameter           DW_g        = 16,
    parameter           DLY_div     = 16,
    parameter           DLY_rbg     = 3
) (
    input                                               clk                     ,
    input                                               rst                     ,

    input               [NUM_ELEMS*DATA_WIDTH-1:0]      beta_wdata              ,
    input                                               beta_wvld               ,
    input                                               beta_wstart             ,
    input               [NUM_ELEMS*DATA_WIDTH-1: 0]     gamma_wdata             ,
    input                                               gamma_wvld              ,
    input                                               gamma_wstart            ,
    input               [12-1:0]                        nvm_gnum                ,
    input               [12-1:0]                        nvm_bnum                ,

    input                                               ln_in_vld               ,
    input                                               ln_in_done              ,

    output   wire [NUM_ELEMS*DW_b-1:0]                  beta_rdata              ,   
    output   wire [NUM_ELEMS*DW_g-1:0]                  gamma_rdata             ,
    output   wire                                       param_rvld                        
  
);

    //------------------------------------------------------------------------------
    //
    //------------------------------------------------------------------------------
    integer i=0,j=0;
    (*dont_touch="true"*)reg [NUM_ELEMS*DATA_WIDTH-1:0] r0_beta_wdata           ;
    (*dont_touch="true"*)reg                            r0_beta_wvld            ;
    (*dont_touch="true"*)reg                            r0_beta_wstart          ;
    (*dont_touch="true"*)reg [NUM_ELEMS*DATA_WIDTH-1:0] r0_gamma_wdata          ;
    (*dont_touch="true"*)reg                            r0_gamma_wvld           ;
    (*dont_touch="true"*)reg                            r0_gamma_wstart         ;
    always @(posedge clk)
    begin
            r0_beta_wdata       <=      beta_wdata                              ;
            r0_beta_wvld        <=      beta_wvld                               ;
            r0_beta_wstart      <=      beta_wstart                             ;
            r0_gamma_wdata      <=      gamma_wdata                             ;
            r0_gamma_wvld       <=      gamma_wvld                              ;
            r0_gamma_wstart     <=      gamma_wstart                            ;
    end



    //------------------------------------------------------------------------------
    //Shared Divider Calculation Results
    //------------------------------------------------------------------------------
    reg     [2*DLY_div-1:0]              dly_dv =0                              ;
    always @(posedge clk)
    for(i=0;i<DLY_div;i=i+1)
    if(i==0)  dly_dv[i*2+:2]<={ln_in_vld,ln_in_done}                            ;
    else      dly_dv[i*2+:2]<=dly_dv[(i-1)*2+:2]                                ;
    
    wire    r0_ln_in_vld  =  dly_dv[(DLY_div-1)*2+1]                            ;
    wire    r0_ln_in_done =  dly_dv[(DLY_div-1)*2+0]                            ;



    (*max_fanout=32*)   reg  [5-1:0]    beta_addr      =0                       ;
    (*max_fanout=32*)   reg  [5-1:0]    gamma_addr     =0                       ;
 
    always @(posedge clk)
    if(r0_beta_wstart)                  beta_addr      <=    0                  ;
    else if(r0_beta_wvld)               beta_addr      <=    beta_addr + 1      ;
    else if(r0_ln_in_done)              beta_addr      <=    0                  ;
    else if(r0_ln_in_vld)               beta_addr      <=    beta_addr + 1      ;
    else                                beta_addr      <=    0                  ;

    always @(posedge clk)
    if(r0_gamma_wstart)                 gamma_addr     <=    0                  ;
    else if(r0_gamma_wvld)              gamma_addr     <=    gamma_addr + 1     ;
    else if(r0_ln_in_done)              gamma_addr     <=    0                  ;
    else if(r0_ln_in_vld)               gamma_addr     <=    gamma_addr + 1     ;
    else                                gamma_addr     <=    0                  ;
    
   //---------------------------------------------------------------------------------
   //
   //---------------------------------------------------------------------------------

    localparam RAM_ADDR                 =   5                                   ;
    localparam RAM_DW                   =   512                                 ;
    localparam RAM_CYCLE                =   1                                   ;

    wire                     [NUM_ELEMS*DATA_WIDTH-1:0] r0_beta_rdata           ;   
    wire                     [NUM_ELEMS*DATA_WIDTH-1:0] r0_gamma_rdata          ;
    (*dont_touch="true"*)reg [NUM_ELEMS*DATA_WIDTH-1:0] r1_beta_rdata   =0      ;   
    (*dont_touch="true"*)reg [NUM_ELEMS*DATA_WIDTH-1:0] r1_gamma_rdata  =0      ;
    (*dont_touch="true"*)reg [NUM_ELEMS*DW_b-1:0]       r2_beta_rdata   =0      ;   
    (*dont_touch="true"*)reg [NUM_ELEMS*DW_g-1:0]       r2_gamma_rdata  =0      ;

    (*keep_hierarchy="yes"*)spram # (
        .ADDR_WIDTH                     ( RAM_ADDR                              ),
        .DATA_WIDTH                     ( RAM_DW                                ),
        .RD_DLY                         ( RAM_CYCLE                             ),      
        .MEM_TYPE                       ( "distributed"                         )
    ) BETA (
        .wea                            ( r0_beta_wvld                          ),    
        .addra                          ( beta_addr                             ),
        .dina                           ( r0_beta_wdata                         ),           
        .douta                          ( r0_beta_rdata                         ),
        .ena                            ( 1'b1                                  ),
        .clk                            ( clk                                   ),
        .reset                          ( 1'b0                                  )             
    );


    (*keep_hierarchy="yes"*)spram # (
      .ADDR_WIDTH                       ( RAM_ADDR                              ),
      .DATA_WIDTH                       ( RAM_DW                                ),
      .RD_DLY                           ( RAM_CYCLE                             ), 
      .MEM_TYPE                         ( "distributed"                         )
    ) GAMMA (
      .wea                              ( r0_gamma_wvld                         ),    
      .addra                            ( gamma_addr                            ),
      .dina                             ( r0_gamma_wdata                        ),           
      .douta                            ( r0_gamma_rdata                        ),
      .ena                              ( 1'b1                                  ),
      .clk                              ( clk                                   ),
      .reset                            ( 1'b0                                  )             
    );

   //---------------------------------------------------------------------------------
   //
   //---------------------------------------------------------------------------------
   
    (*dont_touch="true"*)reg [4-1:0]            r0_gnum =0                      ;
    (*dont_touch="true"*)reg [4-1:0]            r0_bnum =0                      ;
    (*dont_touch="true"*)reg [NUM_ELEMS*4-1:0]  r1_bnum =0                      ;
    always @(posedge clk) 
    begin
        r0_gnum<=nvm_gnum[4-1:0]                                                ;
        r0_bnum<=nvm_bnum[4-1:0]                                                ;
        
        for(i=0;i<NUM_ELEMS;i=i+1)
        r1_bnum[i*4+:4]<=15+r0_gnum-r0_bnum                                     ;
    end
    
    always @(posedge clk)
    for(i=0;i<NUM_ELEMS;i=i+1)
    begin
        r1_beta_rdata [i*DATA_WIDTH+:DATA_WIDTH] <= r0_beta_rdata [i*DATA_WIDTH+:DATA_WIDTH];
        r1_gamma_rdata[i*DATA_WIDTH+:DATA_WIDTH] <= r0_gamma_rdata[i*DATA_WIDTH+:DATA_WIDTH];

        r2_beta_rdata  [i*DW_b+:DW_b] <=$signed({{(DW_b-DATA_WIDTH)
        {r1_beta_rdata [i*DATA_WIDTH+ DATA_WIDTH-1]}},//ln1:Q40_28,ln2:Q40_30
         r1_beta_rdata [i*DATA_WIDTH+:DATA_WIDTH]  })<<<r1_bnum[i*4+:4];

        r2_gamma_rdata[i*DW_g+:DW_g]<=r1_gamma_rdata[i*DATA_WIDTH+:DATA_WIDTH]  ;
    end


    reg       [1*DLY_rbg-1:0]      dly_rb_reg =0                                ;
    always @(posedge clk)
    for(i=0;i<DLY_rbg;i=i+1)
    if(i==0)  dly_rb_reg[i*1+:1]<=r0_ln_in_vld                                  ;
    else      dly_rb_reg[i*1+:1]<=dly_rb_reg[(i-1)*1+:1]                        ;
    
    assign    param_rvld    =     dly_rb_reg[(DLY_rbg-1)*1+0]                   ;


`ifndef SIM_CODE
    assign    beta_rdata    =           r2_beta_rdata                           ;
    assign    gamma_rdata   =           r2_gamma_rdata                          ;
`else
    assign    beta_rdata    =~param_rvld?0:r2_beta_rdata                        ;
    assign    gamma_rdata   =~param_rvld?0:r2_gamma_rdata                       ;
`endif

endmodule
