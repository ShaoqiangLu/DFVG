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
module nvm_layer_norm # (
    parameter   DATA_WIDTH  = 16, // Input element data width
    parameter   OUT_WIDTH   = 16, // Output element data width
    parameter   NUM_ELEMS   = 32, // Number of input elements in a single cycle
    parameter   MAX_PKG_LEN = 24  // Maximum number of NUM_ELEMS-sized packages 
                                  //(e.g. max vector size is NUM_ELEMS*MAX_PKG_LEN)
) (
    input                                               clk                     ,
    input                                               rst                     ,
    input                                               enable                  ,
    input               [    7-1 : 0]                   nvm_rstep               ,
    input               [NUM_ELEMS*DATA_WIDTH-1:0]      ln_mean_in_data         ,//ln1:Q16_14,ln2:Q16_9
    input                                               ln_mean_in_val          ,
    input                                               ln_mean_in_done         ,
    output                                              ln_mean_fifo_ren        ,
    input               [NUM_ELEMS*DATA_WIDTH-1:0]      ln_sub_in_data          ,//ln1:Q16_14,ln2:Q16_9
    input                                               ln_sub_in_val           ,
    input                                               ln_sub_in_done          ,
    output              [NUM_ELEMS*(DATA_WIDTH+1)-1:0]  ln_sub_out_data         ,//ln1:Q17_14,ln2:Q17_9
    output                                              ln_sub_out_val          ,
    output                                              ln_sub_out_done         ,
    output  wire                                        ln_sqrt_fifo_ren        ,
    output  wire        [NUM_ELEMS*24-1:0]              ln_sqrt_out_data        ,//ln1:Q32_14,ln2:Q32_9
    output  wire                                        ln_sqrt_out_vld         ,
    output  wire                                        ln_sqrt_out_done        ,
    input                                               ln_div_in_vld           ,
    input               [NUM_ELEMS*24-1:0]              ln_div_in_data          ,//Q24_15
    input                                               ln_div_in_done          ,

    input               [NUM_ELEMS*DATA_WIDTH-1:0]      beta_wdata              ,
    input                                               beta_wvld               ,
    input                                               beta_wstart             ,
    input               [NUM_ELEMS*DATA_WIDTH-1: 0]     gamma_wdata             ,
    input                                               gamma_wvld              ,
    input                                               gamma_wstart            ,
    input               [12-1:0]                        nvm_gnum                ,
    input               [12-1:0]                        nvm_bnum                ,
    input               [12-1:0]                        nvm_xnum                ,
    input               [12-1:0]                        nvm_ynum                ,
    input                                               sync_en                 ,
    output   wire       [2-1:0][40-1:0]                 ln_sum_tx               ,
    input    wire       [2-1:0][40-1:0]                 ln_sum_rx               ,

    output   reg        [NUM_ELEMS*OUT_WIDTH-1:0]       ln_dout_data =0         ,
    output   reg                                        ln_dout_vld  =0         ,
    output   reg                                        ln_dout_done =0         ,
    
    output   wire       [2-1:0][40-1:0]                 ln_mean_dividend        ,
    output   wire       [2-1:0][16-1:0]                 ln_mean_divisor         ,
    input    wire       [2-1:0][48-1:0]                 ln_mean_result          ,

    output   wire       [NUM_ELEMS-1:0][17-1:0]         A_squ_out               ,
    output   wire       [NUM_ELEMS-1:0][17-1:0]         B_squ_out               ,
    input    wire       [NUM_ELEMS-1:0][34-1:0]         P_squ_in                ,

    output   wire       [NUM_ELEMS-1:0][24-1:0]         A_mac_out               ,
    output   wire       [NUM_ELEMS-1:0][16-1:0]         B_mac_out               ,
    output   wire       [NUM_ELEMS-1:0][40-1:0]         C_mac_out               ,
    output   wire       [NUM_ELEMS-1:0][24-1:0]         D_mac_out               ,
    input               [NUM_ELEMS-1:0][40-1:0]         P_mac_in                

);

    //------------------------------------------------------------------------------
    //Calculate the average value of the input, 32 per cycle, 
    //and continuously calculate for 24 cycles
    //------------------------------------------------------------------------------
    localparam  DW_multi        =   40                      ;
    localparam  DW_PKG          =   16                      ;
    localparam  DW_b            =   40                      ;
    localparam  DW_g            =   16                      ;
    localparam  DLY_Mean_DIV    =   38                      ;
    localparam  DLY_SYNC_2      =   16                      ;
    localparam  DLY_SYNC_4      =   32                      ;    
    localparam  DLY_squ         =   10                      ;
    localparam  DLY_sqrt        =   12                      ;
    localparam  DLY_div         =   25                      ;
    localparam  DLY_mac         =   11                      ;

    integer i=0,j=0;
    wire    [DATA_WIDTH-1:0]mean0_result_data               ;
    wire                    mean0_result_val                ;
    wire                    mean0_result_done               ;

    (*keep_hierarchy="yes"*)nvm_ln_vmean #(
        .NUM_ELEMS          ( NUM_ELEMS                     ),
        .DW_IN              ( DATA_WIDTH                    ),
        .DW_multi           ( DW_multi                      ),
        .DW_PKG             ( DW_PKG                        ),
        .DW_OUT             ( DATA_WIDTH                    ),
        .DLY_Mean_DIV       ( DLY_Mean_DIV                  ),
        .DLY_SYNC_2         ( DLY_SYNC_2                    ),
        .DLY_SYNC_4         ( DLY_SYNC_4                    )             
    )u_ln_vmean0(
        .clk                ( clk                           ),
        .rst                ( rst                           ),
        .enable             ( enable                        ),
        .nvm_rstep          ( nvm_rstep                     ),
        .nvm_xnum           ( nvm_xnum                      ),
        .data_in            ( ln_mean_in_data               ),
        .data_in_val        ( ln_mean_in_val                ),
        .data_in_done       ( ln_mean_in_done               ),
        .mean_out           ( mean0_result_data             ),
        .mean_out_val       ( mean0_result_val              ),
        .mean_out_done      ( mean0_result_done             ),
        .mean_out_val_pre   ( ln_mean_fifo_ren              ),
        .ln_sum_tx          ( ln_sum_tx[0]                  ),
        .ln_sum_rx          ( ln_sum_rx[0]                  ),
        .ln_mean_dividend   ( ln_mean_dividend[0]           ),
        .ln_mean_divisor    ( ln_mean_divisor [0]           ),
        .ln_mean_result     ( ln_mean_result  [0]           )
    );


    
    //------------------------------------------------------------------------------
    //
    //------------------------------------------------------------------------------
    wire [NUM_ELEMS*(DATA_WIDTH+1)-1:0]sub_result_data      ;
    wire                               sub_result_val       ;
    wire                               sub_result_done      ;
    (*keep_hierarchy="yes"*)nvm_ln_vsub #(//C=A-B
        .DATA_WIDTH         ( DATA_WIDTH                    ),
        .NUM_ELEMS          ( NUM_ELEMS                     )
    )U_ln_vsub(
        .clk                ( clk                           ),
        .rst                ( 1'b0                          ),
        .A_done             ( ln_sub_in_done                ),
        .A_vld              ( ln_sub_in_val                 ),
        .A_in               ( ln_sub_in_data                ),
        .B_in               ( mean0_result_data             ),
        .C_out              ( sub_result_data               ),//ln1:Q17_14,ln2:Q17_9
        .C_vld              ( sub_result_val                ),
        .C_done             ( sub_result_done               )
    );
   

    //------------------------------------------------------------------------------
    //Output to external, save in fifo1
    //------------------------------------------------------------------------------
     assign  ln_sub_out_data    =   sub_result_data         ;//ln1:Q17_14,ln2:Q17_9
     assign  ln_sub_out_val     =   sub_result_val          ; 
     assign  ln_sub_out_done    =   sub_result_done         ;


    //------------------------------------------------------------------------------
    //The square of data is the product of two data
    //DSP is cycles
    //------------------------------------------------------------------------------
    wire[NUM_ELEMS*2*(DATA_WIDTH+1)-1:0]ln_squ_result       ;
    wire                                ln_squ_result_val   ;
    wire                                ln_squ_result_done  ;

    (*keep_hierarchy="yes"*)nvm_ln_squ # (
        .DW_IN              ( DATA_WIDTH+1                  ),
        .NUM_ELEMS          ( NUM_ELEMS                     ),
        .DLY_squ            ( DLY_squ                       )
    )u_ln_squ(
        .clk                ( clk                           ),
        .rst                ( rst                           ),
        .ln_squ_in_data     ( sub_result_data               ),
        .ln_squ_in_val      ( sub_result_val                ),
        .ln_squ_in_done     ( sub_result_done               ),
        .ln_squ_result      ( ln_squ_result                 ),
        .ln_squ_result_val  ( ln_squ_result_val             ),
        .ln_squ_result_done ( ln_squ_result_done            ),
        .A_squ_out          ( A_squ_out                     ),
        .B_squ_out          ( B_squ_out                     ),
        .P_squ_in           ( P_squ_in                      )    
    );




    //------------------------------------------------------------------------------
    //Calculate the average value of the input, 32 per cycle, 
    //and continuously calculate for  cycles
    //------------------------------------------------------------------------------
 
    wire [DW_multi-1:0]     mean1_result_data               ;
    wire                    mean1_result_val                ;
    wire                    mean1_result_done               ;

    (*keep_hierarchy="yes"*)nvm_ln_vmean #(
        .NUM_ELEMS          ( NUM_ELEMS                     ),
        .DW_IN              ( 2*(DATA_WIDTH+1)              ),
        .DW_multi           ( DW_multi                      ),
        .DW_PKG             ( DW_PKG                        ),
        .DW_OUT             ( DW_multi                      ),
        .DLY_Mean_DIV       ( DLY_Mean_DIV                  ),
        .DLY_SYNC_2         ( DLY_SYNC_2                    ),
        .DLY_SYNC_4         ( DLY_SYNC_4                    )         
    )u_ln_vmean1(
        .clk                ( clk                           ),
        .rst                ( rst                           ),
        .enable             ( enable                        ),
        .nvm_rstep          ( nvm_rstep                     ),
        .nvm_xnum           ( nvm_xnum                      ),
        .data_in            ( ln_squ_result                 ),
        .data_in_val        ( ln_squ_result_val             ),
        .data_in_done       ( ln_squ_result_done            ),
        .mean_out           ( mean1_result_data             ),
        .mean_out_val       ( mean1_result_val              ),
        .mean_out_done      ( mean1_result_done             ),
        .mean_out_val_pre   (                               ),
        .ln_sum_tx          ( ln_sum_tx[1]                  ),
        .ln_sum_rx          ( ln_sum_rx[1]                  ),
        .ln_mean_dividend   ( ln_mean_dividend[1]           ),
        .ln_mean_divisor    ( ln_mean_divisor [1]           ),
        .ln_mean_result     ( ln_mean_result  [1]           )
    );


    //------------------------------------------------------------------------------
    //calculation a root operation on data
    //open root is 13cycles
    //------------------------------------------------------------------------------

    (*keep_hierarchy="yes"*)nvm_ln_sqrt #(
        .DW_IN              ( DW_multi                      ),
        .NUM_ELEMS          ( NUM_ELEMS                     ),
        .DLY_sqrt           ( DLY_sqrt                      ) 
   )u_ln_sqrt(
        .clk                ( clk                           ),
        .rst                ( rst                           ),
        .sqrt_in_val        ( mean1_result_val              ),
        .sqrt_in_done       ( mean1_result_done             ),
        .sqrt_in_data       ( mean1_result_data             ),
        .ln_sqrt_out_data   ( ln_sqrt_out_data              ),//ln1:Q32_14,ln2:Q32_9
        .ln_sqrt_fifo_ren   ( ln_sqrt_fifo_ren              ),
        .ln_sqrt_out_vld    ( ln_sqrt_out_vld               ),
        .ln_sqrt_out_done   ( ln_sqrt_out_done              )             
   );


    //------------------------------------------------------------------------------
    //Shared Divider Calculation Results
    //------------------------------------------------------------------------------
    wire [NUM_ELEMS*DW_b-1:0]          beta_rdata           ;
    wire [NUM_ELEMS*DW_g-1:0]          gamma_rdata          ;
    wire                               param_rvld           ;


    (*keep_hierarchy="yes"*)nvm_ln_bgparam# (
        .NUM_ELEMS          ( NUM_ELEMS                     ),
        .DATA_WIDTH         ( DATA_WIDTH                    ),
        .DW_b               ( DW_b                          ),
        .DW_g               ( DW_g                          ),
        .DLY_div            ( DLY_div-3                     )
    )u_ln_param(
        .clk                ( clk                           ),
        .rst                ( rst                           ),
        .beta_wdata         ( beta_wdata                    ),
        .beta_wvld          ( beta_wvld                     ),
        .beta_wstart        ( beta_wstart                   ),
        .gamma_wdata        ( gamma_wdata                   ),
        .gamma_wvld         ( gamma_wvld                    ),
        .gamma_wstart       ( gamma_wstart                  ),
        .nvm_gnum           ( nvm_gnum                      ),
        .nvm_bnum           ( nvm_bnum                      ),
        .ln_in_vld          ( ln_sqrt_out_vld               ),
        .ln_in_done         ( ln_sqrt_out_done              ),
        .beta_rdata         ( beta_rdata                    ),   
        .gamma_rdata        ( gamma_rdata                   ),
        .param_rvld         ( param_rvld                    )
    );



    //------------------------------------------------------------------------------
    //Data storage for one cycle, as gamma and beta read data from the buffer
    //------------------------------------------------------------------------------
    wire[NUM_ELEMS*DATA_WIDTH-1:0]  mac_out_data            ;
    wire                            mac_out_vld             ;
    wire                            mac_out_done            ;

    (*keep_hierarchy="yes"*)nvm_ln_mac # (// Input element data width
        .NUM_ELEMS          ( NUM_ELEMS                     ),
        .DW_IN              ( 24                            ),
        .DW_b               ( DW_b                          ),
        .DW_g               ( DW_g                          ),
        .DW_OUT             ( DATA_WIDTH                    ), 
        .DLY_mac            ( DLY_mac                       )
    )u_ln_mac(
        .clk                ( clk                           ),
        .rst                ( rst                           ),
        .nvm_gnum           ( nvm_gnum                      ),
        .nvm_bnum           ( nvm_bnum                      ),
        .nvm_xnum           ( nvm_xnum                      ),
        .nvm_ynum           ( nvm_ynum                      ),
        .mac_in_vld         ( ln_div_in_vld                 ),
        .mac_in_done        ( ln_div_in_done                ),
        .mac_in_data        ( ln_div_in_data                ),//Q24_15
        .param_rvld         ( param_rvld                    ),
        .beta_rdata         ( beta_rdata                    ),   
        .gamma_rdata        ( gamma_rdata                   ),
        .mac_out_vld        ( mac_out_vld                   ),
        .mac_out_done       ( mac_out_done                  ),
        .mac_out_data       ( mac_out_data                  ),//Q24_15
   
        .A_mac_out          ( A_mac_out                     ),
        .B_mac_out          ( B_mac_out                     ),
        .C_mac_out          ( C_mac_out                     ),
        .D_mac_out          ( D_mac_out                     ),
        .P_mac_in           ( P_mac_in                      )
    );


//------------------------------------------------------------------------------
//Layer normalization completed, data output
//------------------------------------------------------------------------------

    always @(posedge clk)
    begin
`ifndef SIM_CODE    
        ln_dout_data<=          mac_out_data                ;
`else        
        ln_dout_data<=~enable?0:mac_out_data                ;
`endif        
        ln_dout_vld <= enable&  mac_out_vld                 ;
        ln_dout_done<= enable&  mac_out_done                ;
    end



//------------------------------------------------------------------------------
//
//------------------------------------------------------------------------------

`ifdef SIM_CODE    
    reg [DATA_WIDTH-1:0]      test_ln_mean_in_data  [NUM_ELEMS-1:0] ;
    reg [DATA_WIDTH-1:0]      test_mean0_result_data                ;
    reg [DATA_WIDTH-1:0]      test_ln_sub_in_data   [NUM_ELEMS-1:0] ;
    reg [(DATA_WIDTH+1)-1:0]  test_sub_result_data  [NUM_ELEMS-1:0] ;
    reg [2*(DATA_WIDTH+1)-1:0]test_ln_squ_result    [NUM_ELEMS-1:0] ;
    reg [DW_multi-1:0]        test_mean1_result_data                ;
    reg [24-1:0]              test_ln_sqrt_out_data [NUM_ELEMS-1:0] ;
    reg [24-1:0]              test_ln_div_in_data   [NUM_ELEMS-1:0] ;
    reg [DATA_WIDTH-1:0]      test_beta_wdata       [NUM_ELEMS-1:0] ;
    reg [DATA_WIDTH-1: 0]     test_gamma_wdata      [NUM_ELEMS-1:0] ;
    reg [DW_b-1:0]            test_beta_rdata       [NUM_ELEMS-1:0] ;
    reg [DW_g-1:0]            test_gamma_rdata      [NUM_ELEMS-1:0] ;

    always @(*)
    for(i=0;i<NUM_ELEMS;i=i+1)
    begin
    test_ln_mean_in_data  [i]<=ln_mean_in_data  [i*DATA_WIDTH+:DATA_WIDTH];
    test_mean0_result_data   <=mean0_result_data;
    test_ln_sub_in_data   [i]<=ln_sub_in_data   [i*DATA_WIDTH+:DATA_WIDTH];
    test_sub_result_data  [i]<=sub_result_data  [i*(DATA_WIDTH+1)+:(DATA_WIDTH+1)];
    test_ln_squ_result    [i]<=ln_squ_result    [i*2*(DATA_WIDTH+1)+:2*(DATA_WIDTH+1)];
    test_mean1_result_data   <=mean1_result_data;
    test_ln_sqrt_out_data [i]<=ln_sqrt_out_data [i*24+:24];
    test_ln_div_in_data   [i]<=ln_div_in_data   [i*24+:24];
    test_beta_wdata       [i]<=beta_wdata       [i*DATA_WIDTH+:DATA_WIDTH];
    test_gamma_wdata      [i]<=gamma_wdata      [i*DATA_WIDTH+:DATA_WIDTH];
    test_beta_rdata       [i]<=beta_rdata       [i*DW_b+:DW_b];
    test_gamma_rdata      [i]<=gamma_rdata      [i*DW_g+:DW_g];
    end

`endif 




endmodule
