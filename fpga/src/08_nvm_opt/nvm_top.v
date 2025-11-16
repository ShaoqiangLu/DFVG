`timescale 1ns / 1ps
// -----------------------------------------------------------------------------
// Copyright      : UCLA EDA LAB
// -----------------------------------------------------------------------------
// Engineer       : Chen Wu
// Design Name    : opu series
// Module Name    : nvm_top
// Target Devices : 325t, Alveo U200
// Tool Versions  : Vivado 2020.1, Modelsim 2019.4
// Description    : 
//    Post processes including: residual, GeLU, Softmax, LayerNormalization,
//    Transpose. Each feature can be enabled or not.
//    Attention   : In this design, DW * NUM must be 512 (DDR Datawidth)
//------------------------------------------------------------------------------
//layer_cnt=1:tr_en,transpose[0,2,3,1]                                   
//layer_cnt=2:      transpose[0,2,1,3]
//layer_cnt=3:      transpose[0,2,1,3]      
//layer_cnt=4:div_en,sf_en
//layer_cnt=5:      transpose[0,2,1,3]  
//layer_cnt=6:res_en,ln_en                         
//layer_cnt=7:gelu                
//layer_cnt=8:res_en,ln_en                                     
//------------------------------------------------------------------------------
// Revision       :
// Version        Date        Author        Descriptin
// 1.0            2022-04-08  Chen Wu       Initial version
// 2.0            2022-07-18  Lu Shaoqiang  optimization
//                1) Share divider resources of sf and ln
//                2) The row and row are divided into 3-stage pipeline processing
//                3) Merge redundant buffers to reduce latency
// 2.1            2023-08-25  Shaoqiang     Simulation 97 layers,and       
//                                          implementation on FPGA of U200
// -----------------------------------------------------------------------------

`include "opu_parameter.vh"

module nvm_top #(
  parameter             DW        =     16                        ,
  parameter             NUM       =     32                        ,
  parameter             PLEN      =     32                        ,
  parameter             POS_WIDTH =     8                         ,
  parameter             NUM_SEGS  =     32                        ,
  localparam            ADW       =     NUM*DW                    
) (
  input                               clk                         ,
  input                               reset                       ,
  input         [ 10-1: 0]            layer_cnt                   ,
  input                               nvm_back_en                 ,
  input         [ 11-1: 0]            nvm_rnum                    ,//inside=64
  input         [ 7 -1: 0]            nvm_rstep                   ,//ouside=24
  input         [ 12-1: 0]            nvm_xnum                    ,
  input         [ 12-1: 0]            nvm_ynum                    ,
  input         [ 12-1: 0]            nvm_bnum                    ,
  input         [ 12-1: 0]            nvm_gnum                    ,
  input                               nvm_sync                    ,
  input                               nvm_idir                    ,
  input         [ 6 -1: 0]            nvm_inum                    ,
  input                               nvm_odir                    ,
  input         [ 6 -1: 0]            nvm_onum                    ,

  input                               tr_en                       ,//1
  input                               sf_en                       ,//2
  input                               ln_en                       ,//3
  input                               res_en                      ,//4
  input                               act_en                      ,//5
  input         [  4-1 : 0]           act_type                    ,  
  
  input                               nvm_start                   ,  
  output  wire                        nvm_done                    ,

  output  wire  [ 80-1: 0]            nvm_sum_tx                  ,
  input   wire  [ 80-1: 0]            nvm_sum_rx                  ,

  output  wire  [ 15-1 : 0]           nvm_raddr                   ,
  output  wire                        nvm_raddr_vld               ,
  output  wire                        nvm_raddr_done              ,
  
  input                               nvm_rdata_vld               ,
  input                               nvm_rdata_done              ,
  input         [NUM-1:0][DW-1:0]     nvm_rdata                   ,
  input         [NUM-1:0][DW-1:0]     res_rdata                   , 
  input                               res_rvld                    , 
  input                               beta_wvld                   ,
  input                               beta_wstart                 ,
  input         [NUM-1:0][DW-1:0]     beta_wdata                  ,
  input         [NUM-1:0][DW-1:0]     gamma_wdata                 ,
  input                               gamma_wvld                  ,
  input                               gamma_wstart                ,
                    
  
  output  wire  [ 15-1 : 0]           back_waddr                  ,  
  output  wire                        back_wvld                   ,
  output  wire                        back_wdone                  ,
  output  wire  [ADW-1 : 0]           back_wdata                  ,
  input   wire  [NUM-1:0][DW-1:0]     back_rdata                  ,
  output  wire  [ 15-1 : 0]           back_raddr                  ,
  output  wire                        back_raddr_vld              ,
  input   wire                        back_rdata_vld              , 
  output  wire  [ADW-1 : 0]           ddr_wdata                   ,
  output  wire                        ddr_wvld                    ,
  //
  output  wire [NUM*24-1:0]           A_dsp0_out                  , 
  output  wire [NUM*16-1:0]           B_dsp0_out                  , 
  output  wire [NUM*40-1:0]           C_dsp0_out                  , 
  output  wire [NUM*24-1:0]           D_dsp0_out                  , 
  input   wire [NUM*40-1:0]           P_dsp0_in                   ,
  output  wire [NUM*17-1:0]           A_dsp1_out                  , 
  output  wire [NUM*17-1:0]           B_dsp1_out                  , 
  output  wire [NUM*34-1:0]           C_dsp1_out                  , 
  output  wire [NUM*17-1:0]           D_dsp1_out                  , 
  input   wire [NUM*34-1:0]           P_dsp1_in                   ,
  output  wire [NUM*1 -1:0]           s_axis_divisor_tvalid       ,
  output  wire [NUM*24-1:0]           s_axis_divisor_tdata        ,
  output  wire [NUM*1 -1:0]           s_axis_dividend_tvalid      ,
  output  wire [NUM*24-1:0]           s_axis_dividend_tdata       ,            
  input   wire [NUM*1 -1:0]           m_axis_dout_tvalid          ,
  input   wire [NUM*40-1:0]           m_axis_dout_tdata           ,

  output  wire [2*40-1:0]             ln_mean_dividend            ,
  output  wire [2*16-1:0]             ln_mean_divisor             ,
  input   wire [2*48-1:0]             ln_mean_result              
);
  integer i=0,j=0;
  reg           [5-1:0]               nvm_index_en      =0        ;
  //---------------------------------------------------------------
  wire                                tr_rdata_vld                ;
  wire                                tr_rdata_done               ;
  wire                                sf_rdata_vld                ;
  wire                                sf_rdata_done               ;
  wire                                ln_rdata_vld                ;
  wire                                ln_rdata_done               ;
  wire                                res_rdata_vld               ;
  wire                                res_rdata_done              ;
  wire                                act_rdata_vld               ;
  wire                                act_rdata_done              ;
  wire                                out_rdata_vld               ;
  wire                                out_rdata_done              ;
  wire          [ADW-1 : 0]           tr_rdata_in                 ;
  wire          [ADW-1 : 0]           sf_rdata_in                 ;
  wire          [ADW-1 : 0]           ln_rdata_in                 ;
  wire          [ADW-1 : 0]           res_rdata_in                ;
  wire          [ADW-1 : 0]           act_rdata_in                ;
  wire          [ADW-1 : 0]           out_rdata_in                ;
  //---------------------------------------------------------------
  wire          [ADW-1 : 0]           tr_dout_data                ;
  wire                                tr_dout_vld                 ;
  wire                                tr_dout_done                ;
  wire          [ADW-1 : 0]           sf_dout_data                ;
  wire                                sf_dout_vld                 ;
  wire                                sf_dout_done                ;   
  wire          [ADW-1 : 0]           ln_dout_data                ;
  wire                                ln_dout_vld                 ;
  wire                                ln_dout_done                ;   
  wire          [ADW-1 : 0]           res_dout_data               ;
  wire                                res_dout_vld                ;
  wire                                res_dout_done               ;   
  wire          [ADW-1 : 0]           act_dout_data               ;
  wire                                act_dout_vld                ;
  wire                                act_dout_done               ;
  wire                                back_row_wvld               ;
  wire                                back_row_wdone              ;
  //---------------------------------------------------------------
  wire                                sf_factor_vld               ;
  wire                                sf_factor_done              ;
  wire          [ADW-1 : 0]           sf_factor_data              ;
  wire          [ADW-1 : 0]           sf_factor_shift_data        ;
  wire                                sf_factor_shift_vld         ;
  wire                                sf_factor_shift_done        ;
  
  wire                                sf_max_fifo_ren             ;
  wire          [NUM*DW-1:0]          sf_sub_in_data              ;
  wire                                sf_sub_in_val               ;
  wire                                sf_sub_in_done              ;
  
  wire          [NUM*DW-1:0]          sf_exp_out_data             ;
  wire                                sf_exp_out_val              ;
  wire                                sf_exp_out_done             ;

  wire          [NUM*(DW+1)-1:0]      sf_exp_fifo_data            ;
  wire                                sf_exp_fifo_val             ;
  wire                                sf_exp_fifo_done            ;


  wire                                sf_sum_fifo_ren             ;
  wire          [NUM*24-1:0]          sf_sum_out_data             ;
  wire                                sf_sum_out_vld              ;
  wire                                sf_sum_out_done             ;

  wire                                sf_div_result_vld           ;
  wire                                sf_div_result_done          ;
  wire          [NUM*24-1:0]          sf_div_result_data          ;

  wire          [ADW-1 : 0]           sf_shfto_data_o             ;
  wire                                sf_shfto_vld_o              ;
  wire                                sf_shfto_done_o             ;
  
  wire          [ADW-1 : 0]           sf_shfto_data_i             ;
  wire                                sf_shfto_vld_i              ;
  wire                                sf_shfto_done_i             ;
  //----------------------------------------------------------------

  wire                                res_rdata_sh_vld            ;
  wire                                res_rdata_sh_done           ;
  wire          [ADW-1 : 0]           res_rdata_sh_in             ;



  wire          [ADW-1 :0]            ln_input_data               ;
  wire                                ln_input_val                ;
  wire                                ln_input_done               ;

  wire                                ln_mean_fifo_ren            ;
  wire          [ADW-1 : 0]           ln_sub_in_data              ;
  wire                                ln_sub_in_val               ;
  wire                                ln_sub_in_done              ;
  
  wire          [NUM*(DW+1)-1:0]      ln_sub_out_data             ;
  wire                                ln_sub_out_val              ;
  wire                                ln_sub_out_done             ;

  wire          [NUM*(DW+1)-1:0]      ln_sub_fifo_data            ;
  wire                                ln_sub_fifo_val             ;
  wire                                ln_sub_fifo_done            ;
  
  wire                                ln_sqrt_fifo_ren            ;
  wire          [NUM*24-1:0]          ln_sqrt_out_data            ;
  wire                                ln_sqrt_out_vld             ;
  wire                                ln_sqrt_out_done            ;

  wire          [NUM*24-1:0]          ln_div_result_data          ;
  wire                                ln_div_result_vld           ;
  wire                                ln_div_result_done          ;
  
  //----------------------------------------------------------------
  wire  [NUM*17-1:0]    A_squ_out       ; 
  wire  [NUM*17-1:0]    B_squ_out       ; 
  wire  [NUM*34-1:0]    P_squ_in        ;
  
  wire  [NUM*17-1:0]    A_act_out       ; 
  wire  [NUM*15-1:0]    B_act_out       ; 
  wire  [NUM*32-1:0]    C_act_out       ; 
  wire  [NUM*17-1:0]    D_act_out       ; 
  wire  [NUM*32-1:0]    P_act_in        ;
  
  wire  [NUM*17-1:0]    A_exp_out       ;
  wire  [NUM*15-1:0]    B_exp_out       ; 
  wire  [NUM*32-1:0]    C_exp_out       ; 
  wire  [NUM*17-1:0]    D_exp_out       ; 
  wire  [NUM*32-1:0]    P_exp_in        ; 
  
  wire  [NUM*24-1:0]    A_mac_out       ;
  wire  [NUM*16-1:0]    B_mac_out       ;
  wire  [NUM*40-1:0]    C_mac_out       ;
  wire  [NUM*24-1:0]    D_mac_out       ;
  wire  [NUM*40-1:0]    P_mac_in        ;

//-----------------------------------------------------------------
//Generate Read Address from ofm_top
//-----------------------------------------------------------------
(*keep_hierarchy="yes"*)
  nvm_load_addr
u_load_addr
(
  .clk              (clk                ),
  .reset            (reset              ),
  .layer_cnt        (layer_cnt          ),
  .nvm_back_en      (nvm_back_en        ),
  .nvm_start        (nvm_start          ),
  .nvm_rstep        (nvm_rstep          ),
  .nvm_rnum         (nvm_rnum           ),
  .nvm_raddr        (nvm_raddr          ),
  .nvm_raddr_vld    (nvm_raddr_vld      ),
  .nvm_raddr_done   (nvm_raddr_done     ),
  .ddr_wvld         (ddr_wvld           ),//i
  .nvm_done         (nvm_done           ) //o
);

//-----------------------------------------------------------------
//
//-----------------------------------------------------------------

always @(posedge clk)
begin
nvm_index_en 
<={ act_en,//5      
    res_en,//4 
    ln_en ,//3
    sf_en ,//2
    tr_en  //1
};
end

(*keep_hierarchy="no"*)
nvm_select_in#(
  .DW (DW ),
  .NUM(NUM)                  
)u_select_in(
  .clk              (clk                ),
  .reset            (reset              ),
  .nvm_index_en     (nvm_index_en       ),
  
  .nvm_rdata_vld    (nvm_rdata_vld      ),
  .nvm_rdata_done   (nvm_rdata_done     ),
  .nvm_rdata        (nvm_rdata          ),  
  .res_rdata        (res_rdata          ),
  .res_rvld         (res_rvld           ),
  
    
  .tr_rdata_vld     (tr_rdata_vld       ),
  .tr_rdata_done    (tr_rdata_done      ),
  .sf_rdata_vld     (sf_rdata_vld       ),
  .sf_rdata_done    (sf_rdata_done      ),
  .ln_rdata_vld     (ln_rdata_vld       ),
  .ln_rdata_done    (ln_rdata_done      ),
  .res_rdata_vld    (res_rdata_vld      ),
  .res_rdata_done   (res_rdata_done     ),
  .act_rdata_vld    (act_rdata_vld      ),
  .act_rdata_done   (act_rdata_done     ),
  .out_rdata_vld    (out_rdata_vld      ),
  .out_rdata_done   (out_rdata_done     ),
  
  .tr_rdata_in      (tr_rdata_in        ),
  .sf_rdata_in      (sf_rdata_in        ),
  .ln_rdata_in      (ln_rdata_in        ),
  .res_rdata_in     (res_rdata_in       ),  
  .act_rdata_in     (act_rdata_in       ),  
  .out_rdata_in     (out_rdata_in       ) 
);

//-----------------------------------------------------------------
//
//-----------------------------------------------------------------
(*keep_hierarchy="yes"*)
nvm_transpose #(
  .DW               (DW                 ),
  .NUM              (NUM                )                                 
)u_transpose(
  .tr_din_vld       (tr_rdata_vld       ),
  .tr_din_done      (tr_rdata_done      ),
  .tr_din_data      (tr_rdata_in        ),
  .tr_dout_data     (tr_dout_data       ),
  .tr_dout_vld      (tr_dout_vld        ),
  .tr_dout_done     (tr_dout_done       ),
  .clk              (clk                ),
  .reset            (reset              )      
);



//--------------------------------------------------------------
//Piecewise linear approximation of Gelu activation function
//--------------------------------------------------------------
(*keep_hierarchy="yes"*)
nvm_act_function #(
.DW                 ( DW                ),
.NUM                ( NUM               )  
)u_act_function( 
  .clk              ( clk               ),
  .rst              ( reset             ),
  .enable           ( act_en            ),
  .act_type         ( act_type          ),
  .nvm_xnum         ( nvm_xnum[4-1:0]   ),
  .nvm_ynum         ( nvm_ynum[4-1:0]   ),
  .x_data           ( act_rdata_in      ),
  .x_vld            ( act_rdata_vld     ),
  .x_done           ( act_rdata_done    ),
  .y_data           ( act_dout_data     ),
  .y_vld            ( act_dout_vld      ),
  .y_done           ( act_dout_done     ),
  .A_act_out        ( A_act_out         ), 
  .B_act_out        ( B_act_out         ), 
  .C_act_out        ( C_act_out         ), 
  .D_act_out        ( D_act_out         ), 
  .P_act_in         ( P_act_in          )
);


//--------------------------------------------------------------
//Add of residual layers
//--------------------------------------------------------------
(*keep_hierarchy="yes"*)nvm_residual#(
  .NUM              ( NUM               ),
  .DW               ( DW                ) 
)u_residual( 
  .clk              ( clk               ),
  .reset            ( reset             ),
  .res_en           ( res_en            ),
  
  .res_din_done     ( res_rdata_sh_done ),
  .res_din_vld      ( res_rdata_sh_vld  ),
  .res_din_data     ( res_rdata_sh_in   ),//ln1 Q16_14
  
  .nvm_din_data     ( ln_rdata_in       ),//ln1 Q16_14
  .nvm_din_vld      ( ln_rdata_vld      ),
  .nvm_din_done     ( ln_rdata_done     ),
  
  .res_dout_vld     ( res_dout_vld      ),
  .res_dout_done    ( res_dout_done     ),
  .res_dout_data    ( res_dout_data     )//ln1 Q16_14
);

//--------------------------------------------------------------
//divisor factor:8=2^3，>>>Signed data, arithmetic shift
//-------------------------------------------------------------- 
(*keep_hierarchy="yes"*)
nvm_sf_factor#(
  .DW (DW ),
  .NUM(NUM)
)u_sf_factor(
  .clk              (clk                ),
  .reset            (reset              ),                   
  .fct_num          (4'd8               ),
  .fct_in_vld       (sf_rdata_vld       ),
  .fct_in_done      (sf_rdata_done      ),
  .fct_in_data      (sf_rdata_in        ),
  .fct_out_data     (sf_factor_data     ),
  .fct_out_vld      (sf_factor_vld      ),
  .fct_out_done     (sf_factor_done     )
);

//--------------------------------------------------------------
//Input shifter：shiteri
//-------------------------------------------------------------- 

(*keep_hierarchy="yes"*)
nvm_shifter#(
   .DW   (DW ),
   .NUM  (NUM)
)u_shift_0(
   .clk               (clk                  ),
   .rst               (reset                ),
   .shift_sel         (res_en               ),//=1--->in1
   .shift_in0_init_num(nvm_xnum[4-1:0]      ),
   .shift_in0_post_num(4'd9                 ),
   .shift_in1_nvm_dir (1'b1                 ),//nvm_idir
   .shift_in1_nvm_num (4'd4                 ),//nvm_inum[4-1:0]
   
   .shift_in0_vld     (sf_factor_vld        ),
   .shift_in0_done    (sf_factor_done       ),
   .shift_in0_data    (sf_factor_data       ),
   
   .shift_in1_vld     (res_rdata_vld        ),
   .shift_in1_done    (res_rdata_done       ),
   .shift_in1_data    (res_rdata_in         ),
   
   .shift_out0_data   (sf_factor_shift_data ),
   .shift_out0_vld    (sf_factor_shift_vld  ),
   .shift_out0_done   (sf_factor_shift_done ),
   
   .shift_out1_data   (res_rdata_sh_in      ),
   .shift_out1_vld    (res_rdata_sh_vld     ),
   .shift_out1_done   (res_rdata_sh_done    )
);





//--------------------------------------------------------------
//fifo 0：Store data for sf_max or ln_mean
//--------------------------------------------------------------
(*keep_hierarchy="yes"*)
nvm_fifo_share#(
  .FIFO_DELAY       (1                  ),
  .FIFO_DEEP        (512                ),
  .FIFO_WIDTH       (NUM*DW+1           )
)u_fifo_0(
  .clk              (clk                ),
  .reset            (reset              ),
  .sf_en            (sf_en              ),
  .ln_en            (ln_en              ),    
            
  .sf_in_done       (sf_factor_shift_done),
  .sf_in_vld        (sf_factor_shift_vld ),
  .sf_in_data       (sf_factor_shift_data),
  
  .ln_in_data       (ln_input_data      ), 
  .ln_in_vld        (ln_input_val       ),
  .ln_in_done       (ln_input_done      ),
  
  .sf_in_ren        (sf_max_fifo_ren    ),
  .ln_in_ren        (ln_mean_fifo_ren   ),

  .sf_out_done      (sf_sub_in_done     ),
  .sf_out_vld       (sf_sub_in_val      ),
  .sf_out_data      (sf_sub_in_data     ),

  .ln_out_data      (ln_sub_in_data     ), 
  .ln_out_vld       (ln_sub_in_val      ),
  .ln_out_done      (ln_sub_in_done     )
);



//----------------------------------------------------------------
//divide and Soft-Max
//----------------------------------------------------------------
(*keep_hierarchy="yes"*)nvm_soft_max #(
  .DATA_WIDTH       ( DW                    ), 
  .NUM_ELEMS        ( NUM                   ), 
  .MAX_PKG_LEN      ( PLEN                  )
)u_soft_max(
  .clk              ( clk                   ),
  .rst              ( reset                 ),
  .enable           ( sf_en                 ),
  .nvm_rstep        ( nvm_rstep             ),
  .sf_max_in_data   ( sf_factor_shift_data  ),//Fix Q16_9
  .sf_max_in_val    ( sf_factor_shift_vld   ),
  .sf_max_in_done   ( sf_factor_shift_done  ),
  .sf_max_fifo_ren  ( sf_max_fifo_ren       ),

  .sf_sub_in_data   ( sf_sub_in_data        ),//Fix Q16_9
  .sf_sub_in_val    ( sf_sub_in_val         ),
  .sf_sub_in_done   ( sf_sub_in_done        ),
 
  .sf_exp_out_data  ( sf_exp_out_data       ),//Fix Q16_14
  .sf_exp_out_val   ( sf_exp_out_val        ),
  .sf_exp_out_done  ( sf_exp_out_done       ),
 
  .sf_sum_fifo_ren  ( sf_sum_fifo_ren       ),
  .sf_sum_out_data  ( sf_sum_out_data       ),//Fix Q32_14
  .sf_sum_out_vld   ( sf_sum_out_vld        ),
  .sf_sum_out_done  ( sf_sum_out_done       ),
 
  .sf_div_in_vld    ( sf_div_result_vld     ),
  .sf_div_in_data   ( sf_div_result_data    ),//Fix Q24_15
  .sf_div_in_done   ( sf_div_result_done    ),
 
  .sf_shfto_data_o  ( sf_shfto_data_o       ),//Fix Q16_14
  .sf_shfto_vld_o   ( sf_shfto_vld_o        ),
  .sf_shfto_done_o  ( sf_shfto_done_o       ),
 
  .sf_shfto_data_i  ( sf_shfto_data_i       ),
  .sf_shfto_vld_i   ( sf_shfto_vld_i        ),
  .sf_shfto_done_i  ( sf_shfto_done_i       ),
   
  .sf_dout_data     ( sf_dout_data          ),
  .sf_dout_vld      ( sf_dout_vld           ),
  .sf_dout_done     ( sf_dout_done          ),
  
  .A_exp_out        ( A_exp_out             ),
  .B_exp_out        ( B_exp_out             ),
  .C_exp_out        ( C_exp_out             ),
  .D_exp_out        ( D_exp_out             ),
  .P_exp_in         ( P_exp_in              )
);


//--------------------------------------------------------------
//output shifter：shitero
//--------------------------------------------------------------  


(*keep_hierarchy="yes"*)
nvm_shifter#(
   .DW   (DW ),
   .NUM  (NUM)
)u_shift_1(
   .clk               (clk                  ),
   .rst               (reset                ),
   .shift_sel         (~sf_en               ),//=1--->in1
   .shift_in0_init_num(4'd14                ),
   .shift_in0_post_num(4'd15                ),
   .shift_in1_nvm_dir (nvm_odir             ),
   .shift_in1_nvm_num (nvm_onum[4-1:0]      ),
   
   .shift_in0_vld     (sf_shfto_vld_o       ),
   .shift_in0_done    (sf_shfto_done_o      ),
   .shift_in0_data    (sf_shfto_data_o      ),
   
   .shift_in1_vld     (1'd0                 ),
   .shift_in1_done    (1'd0                 ),
   .shift_in1_data    (512'd0               ),
   
   .shift_out0_data   (sf_shfto_data_i      ),
   .shift_out0_vld    (sf_shfto_vld_i       ),
   .shift_out0_done   (sf_shfto_done_i      ),
   
   .shift_out1_data   (                     ),
   .shift_out1_vld    (                     ),
   .shift_out1_done   (                     )
);


//--------------------------------------------------------------
//fifo 1：Store data for sf_exp or ln_sub
//--------------------------------------------------------------

(*keep_hierarchy="yes"*)
nvm_fifo_share#(
  .FIFO_DELAY       (1                      ),
  .FIFO_DEEP        (512                    ),
  .FIFO_WIDTH       (NUM*(DW+1)+1           )
)u_fifo_1(
  .clk              (clk                    ),
  .reset            (reset                  ),
  .sf_en            (sf_en                  ),
  .ln_en            (ln_en                  ),    
            
  .sf_in_done       (sf_exp_out_done        ),
  .sf_in_vld        (sf_exp_out_val         ),
  .sf_in_data       ({{NUM{1'b0}},
                     sf_exp_out_data   }    ),
 
  .ln_in_data       (ln_sub_out_data        ), 
  .ln_in_vld        (ln_sub_out_val         ),
  .ln_in_done       (ln_sub_out_done        ),
 
  .sf_in_ren        (sf_sum_fifo_ren        ),
  .ln_in_ren        (ln_sqrt_fifo_ren       ),
 
  .sf_out_done      (sf_exp_fifo_done       ),
  .sf_out_vld       (sf_exp_fifo_val        ),
  .sf_out_data      (sf_exp_fifo_data       ),
 
  .ln_out_data      (ln_sub_fifo_data       ), 
  .ln_out_vld       (ln_sub_fifo_val        ),
  .ln_out_done      (ln_sub_fifo_done       )
);


//--------------------------------------------------------------
//Once for each row of data Layer_Norm
//--------------------------------------------------------------
(*keep_hierarchy="no"*)
nvm_ln_input #(
  .DW   (16 ),
  .NUM  (32 )        
)u_ln_input(
  .clk              (clk                    ),
  .reset            (reset                  ),
  .ln_en            (ln_en                  ),
  .res_en           (res_en                 ),
  .res_result_done  (res_dout_done          ),
  .res_result_val   (res_dout_vld           ),
  .res_result_data  (res_dout_data          ),
  .ln_rdata_in      (ln_rdata_in            ),
  .ln_rdata_vld     (ln_rdata_vld           ),
  .ln_rdata_done    (ln_rdata_done          ),    
  .ln_input_data    (ln_input_data          ),
  .ln_input_val     (ln_input_val           ),
  .ln_input_done    (ln_input_done          )
);


(*keep_hierarchy="yes"*)nvm_layer_norm # (
  .DATA_WIDTH       ( DW                    ),
  .OUT_WIDTH        ( DW                    ),
  .NUM_ELEMS        ( NUM                   ),
  .MAX_PKG_LEN      ( PLEN                  ) 
)u_layer_norm (
  .clk              ( clk                   ),
  .rst              ( reset                 ),
  .enable           ( ln_en                 ),
  .nvm_rstep        ( nvm_rstep             ),
  
  .ln_mean_in_data  ( ln_input_data         ),//ln1:Q16_14,ln2:Q16_9
  .ln_mean_in_val   ( ln_input_val          ),                      
  .ln_mean_in_done  ( ln_input_done         ),  
                       
  .ln_mean_fifo_ren ( ln_mean_fifo_ren      ),                      
  .ln_sub_in_data   ( ln_sub_in_data        ),//ln1:Q16_14,ln2:Q16_9
  .ln_sub_in_val    ( ln_sub_in_val         ),                      
  .ln_sub_in_done   ( ln_sub_in_done        ),                      
  .ln_sub_out_data  ( ln_sub_out_data       ),//ln1:Q17_14,ln2:Q17_9
  .ln_sub_out_val   ( ln_sub_out_val        ),                      
  .ln_sub_out_done  ( ln_sub_out_done       ),       
  .ln_sqrt_fifo_ren ( ln_sqrt_fifo_ren      ),                
  .ln_sqrt_out_data ( ln_sqrt_out_data      ),//ln1:Q32_14,ln2:Q32_9
  .ln_sqrt_out_vld  ( ln_sqrt_out_vld       ),
  .ln_sqrt_out_done ( ln_sqrt_out_done      ),
  .ln_div_in_vld    ( ln_div_result_vld     ),
  .ln_div_in_data   ( ln_div_result_data    ),//Q24_15
  .ln_div_in_done   ( ln_div_result_done    ),
  .beta_wdata       ( beta_wdata            ),
  .beta_wvld        ( beta_wvld             ),
  .beta_wstart      ( beta_wstart           ),    
  .gamma_wdata      ( gamma_wdata           ),
  .gamma_wvld       ( gamma_wvld            ),
  .gamma_wstart     ( gamma_wstart          ),
  .nvm_bnum         ( nvm_bnum              ),
  .nvm_gnum         ( nvm_gnum              ),
  .nvm_xnum         ( nvm_xnum              ),
  .nvm_ynum         ( nvm_ynum              ),
  .sync_en          ( nvm_sync              ),
  .ln_sum_tx        ( nvm_sum_tx            ),
  .ln_sum_rx        ( nvm_sum_rx            ),
  .ln_dout_data     ( ln_dout_data          ),
  .ln_dout_vld      ( ln_dout_vld           ),
  .ln_dout_done     ( ln_dout_done          ),
  .A_mac_out        ( A_mac_out             ),
  .B_mac_out        ( B_mac_out             ),
  .C_mac_out        ( C_mac_out             ),
  .D_mac_out        ( D_mac_out             ),
  .P_mac_in         ( P_mac_in              ),
  .A_squ_out        ( A_squ_out             ),
  .B_squ_out        ( B_squ_out             ),
  .P_squ_in         ( P_squ_in              ),
  .ln_mean_dividend ( ln_mean_dividend      ),
  .ln_mean_divisor  ( ln_mean_divisor       ),
  .ln_mean_result   ( ln_mean_result        )
);



//--------------------------------------------------------------
//Shared multiplier exp and gelu DSP_P[31:0] Q32_22
//-------------------------------------------------------------- 

(*keep_hierarchy="no"*)
nvm_dsp_share#(
  .NUM(NUM)          
)u_dsp_share(
  .clk              ( clk                   ),
  .reset            ( reset                 ),         
  .act_en           ( act_en                ), 
  .sf_en            ( sf_en                 ), 
  .ln_en            ( ln_en                 ), 
  .A_squ_out        ( A_squ_out             ), 
  .B_squ_out        ( B_squ_out             ), 
  .P_squ_in         ( P_squ_in              ),
  .A_act_out        ( A_act_out             ), 
  .B_act_out        ( B_act_out             ), 
  .C_act_out        ( C_act_out             ), 
  .D_act_out        ( D_act_out             ), 
  .P_act_in         ( P_act_in              ),
  .A_exp_out        ( A_exp_out             ),
  .B_exp_out        ( B_exp_out             ), 
  .C_exp_out        ( C_exp_out             ), 
  .D_exp_out        ( D_exp_out             ), 
  .P_exp_in         ( P_exp_in              ), 
  .A_mac_out        ( A_mac_out             ),
  .B_mac_out        ( B_mac_out             ),
  .C_mac_out        ( C_mac_out             ),
  .D_mac_out        ( D_mac_out             ),
  .P_mac_in         ( P_mac_in              ),
  .A_dsp0_out       ( A_dsp0_out            ), 
  .B_dsp0_out       ( B_dsp0_out            ), 
  .C_dsp0_out       ( C_dsp0_out            ), 
  .D_dsp0_out       ( D_dsp0_out            ), 
  .P_dsp0_in        ( P_dsp0_in             ),
  .A_dsp1_out       ( A_dsp1_out            ), 
  .B_dsp1_out       ( B_dsp1_out            ), 
  .C_dsp1_out       ( C_dsp1_out            ), 
  .D_dsp1_out       ( D_dsp1_out            ), 
  .P_dsp1_in        ( P_dsp1_in             )
);
 
//-----------------------------------------------------------------
//
//-----------------------------------------------------------------
(*keep_hierarchy="no"*)
nvm_div_share#(
  .DW                     ( 16),
  .NUM                    ( 32),
  .DLY_DIV                ( 25)                        
)u_div_share(
  .clk                    ( clk                    ),
  .reset                  ( reset                  ),
  .sf_en                  ( sf_en                  ),
  .ln_en                  ( ln_en                  ),
  .sf_exp_fifo_val        ( sf_exp_fifo_val        ),
  .sf_exp_fifo_done       ( sf_exp_fifo_done       ),
  .sf_exp_fifo_data       ( sf_exp_fifo_data       ),
  .ln_sub_fifo_data       ( ln_sub_fifo_data       ),
  .ln_sub_fifo_val        ( ln_sub_fifo_val        ),
  .ln_sub_fifo_done       ( ln_sub_fifo_done       ),
  .sf_sum_out_vld         ( sf_sum_out_vld         ),
  .sf_sum_out_done        ( sf_sum_out_done        ),
  .sf_sum_out_data        ( sf_sum_out_data        ),
  .ln_sqrt_out_data       ( ln_sqrt_out_data       ),
  .ln_sqrt_out_vld        ( ln_sqrt_out_vld        ),
  .ln_sqrt_out_done       ( ln_sqrt_out_done       ),
  .sf_div_result_vld      ( sf_div_result_vld      ),
  .sf_div_result_done     ( sf_div_result_done     ),
  .sf_div_result_data     ( sf_div_result_data     ),
  .ln_div_result_data     ( ln_div_result_data     ),
  .ln_div_result_vld      ( ln_div_result_vld      ),
  .ln_div_result_done     ( ln_div_result_done     ),
  .s_axis_divisor_tvalid  ( s_axis_divisor_tvalid  ),
  .s_axis_divisor_tdata   ( s_axis_divisor_tdata   ),
  .s_axis_dividend_tdata  ( s_axis_dividend_tdata  ), 
  .s_axis_dividend_tvalid ( s_axis_dividend_tvalid ),
  .m_axis_dout_tvalid     ( m_axis_dout_tvalid     ),
  .m_axis_dout_tdata      ( m_axis_dout_tdata      )
);

 

//-----------------------------------------------------------------
//
//-----------------------------------------------------------------
(*keep_hierarchy="yes"*)
  nvm_back_addr
u_nvm_back_addr
(
  .clk                  ( clk                    ),
  .reset                ( reset                  ),             
  .nvm_back_en          ( nvm_back_en            ),
  .nvm_rnum             ( nvm_rnum               ),
  .nvm_rstep            ( nvm_rstep              ),
  .nvm_raddr            ( nvm_raddr              ),
  .nvm_raddr_vld        ( nvm_raddr_vld          ),
  .layer_cnt            ( layer_cnt              ),
  .back_row_wdone       ( back_row_wdone         ),
  .back_row_wvld        ( back_row_wvld          ),
  .back_wvld            ( back_wvld              ),
  .back_wdone           ( back_wdone             ),
  .back_waddr           ( back_waddr             ), 
  .back_raddr           ( back_raddr             ),
  .back_raddr_vld       ( back_raddr_vld         )
);
 
//--------------------------------------------------------------
//Output multiplexer according to enable
//--------------------------------------------------------------
(*keep_hierarchy="yes"*)
nvm_select_out#(
  .DW (16),
  .NUM(32)      
)u_select_out(
  .clk                  ( clk                    ),
  .reset                ( reset                  ), 
  .nvm_index_en         ( nvm_index_en           ),
  .nvm_back_en          ( nvm_back_en            ), 
  
  .tr_dout_data         ( tr_dout_data           ),//1                       
  .sf_dout_data         ( sf_dout_data           ),//2                         
  .ln_dout_data         ( ln_dout_data           ),//3                     
  .res_dout_data        ( res_dout_data          ),//4                  
  .act_dout_data        ( act_dout_data          ),//5                  
  .out_rdata_in         ( out_rdata_in           ),//6
  .tr_dout_vld          ( tr_dout_vld            ),
  .tr_dout_done         ( tr_dout_done           ),           
  .sf_dout_vld          ( sf_dout_vld            ),
  .sf_dout_done         ( sf_dout_done           ),        
  .ln_dout_vld          ( ln_dout_vld            ),
  .ln_dout_done         ( ln_dout_done           ),       
  .res_dout_vld         ( res_dout_vld           ),
  .res_dout_done        ( res_dout_done          ),              
  .act_dout_vld         ( act_dout_vld           ),
  .act_dout_done        ( act_dout_done          ),            
  .out_rdata_vld        ( out_rdata_vld          ),
  .out_rdata_done       ( out_rdata_done         ),
  
  .back_wdata           ( back_wdata             ),
  .back_row_wvld        ( back_row_wvld          ),
  .back_row_wdone       ( back_row_wdone         ),  
  .back_rdata_vld       ( back_rdata_vld         ),
  .back_rdata           ( back_rdata             ),
  .ddr_wdata            ( ddr_wdata              ),
  .ddr_wvld             ( ddr_wvld               )
);


`ifdef DEBUG_ENABLE

 reg                debug_nvm_total  =0           ;
 wire               debug_nvm_dsp                 ;
 wire               debug_nvm_div                 ;
 wire               debug_nvm_sync                ;
 wire               debug_nvm_back                ;

 always @(posedge clk)
 if(nvm_start)      debug_nvm_total<=1            ;
 else if(nvm_done)  debug_nvm_total<=0            ;
 
 assign debug_nvm_dsp=
  OPU_TOP.CORE_TOP1.u_nvm_top.u_layer_norm.ln_squ_result_val
 |OPU_TOP.CORE_TOP1.u_nvm_top.u_layer_norm.mac_out_vld
 |OPU_TOP.CORE_TOP1.u_nvm_top.u_act_function.act_vld
 |OPU_TOP.CORE_TOP1.u_nvm_top.u_soft_max.sf_exp_result_vld  ;

 assign debug_nvm_div=
  OPU_TOP.CORE_TOP1.u_nvm_top.u_layer_norm.mean0_result_val
 |OPU_TOP.CORE_TOP1.u_nvm_top.u_layer_norm.mean1_result_val
 |OPU_TOP.CORE_TOP1.u_nvm_top.u_layer_norm.ln_div_in_vld
 |OPU_TOP.CORE_TOP1.u_nvm_top.u_soft_max.sf_div_in_vld      ;

 assign debug_nvm_sync=
  OPU_TOP.CORE_TOP1.u_nvm_top.u_layer_norm.u_ln_vmean0.u_nvm_ln_vmean_sync.sync_util
 |OPU_TOP.CORE_TOP1.u_nvm_top.u_layer_norm.u_ln_vmean1.u_nvm_ln_vmean_sync.sync_util;

 assign debug_nvm_back=back_wvld|back_rdata_vld|back_raddr_vld;
  
`endif





endmodule