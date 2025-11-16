`timescale 1ns / 1ps
// -----------------------------------------------------------------------------
// UCLA EDA LAB
// -----------------------------------------------------------------------------
// Engineer       : Chen Wu
// Design Name    : opu series
// Module Name    : inst_top
// Target Devices : 325t
// Tool Versions  : Vivado 2020.1, Modelsim 2019.4
// Description    : 
//    Write instructions from DDR to inst ram
//    Fetch instructions from inst ram
//    Decode instructions
//
// Revision       :
// Version        Date        Author        Descriptin
// 1.0            2021-04-12  Chen Wu       Initial version
// 2.0            2023-09-11  Shaoqiang     Simulation 97 layers,and       
//                                          implementation on FPGA of U200.
// 3.0            2024-05-21  Shaoqiang     Organize the code. 
//                                          Divide functions into small modules.
// -----------------------------------------------------------------------------
`include "opu_parameter.vh"
module inst_top 
(
  input                             inst_wstart             ,
  input                             inst_wvld               ,    
  input           [511 : 0]         inst_wdata              ,
  //---------------------------------------------------------
  output  wire                      ddr_rstart              ,
  output  wire    [ 3  : 0]         ddr_rid                 ,
  output  wire    [ 3  : 0]         ddr_roffset_high        ,
  output  wire    [ 24 : 0]         ddr_roffset             ,
  output  wire    [ 24 : 0]         ddr_rstride             ,
  output  wire    [ 6  : 0]         ddr_rstep_num           ,
  output  wire    [ 14 : 0]         ddr_rstep               ,
  output  wire    [14  : 0]         ddr_bm_num              ,
  output  wire                      ddr_bm_en               ,
  output  wire                      ddr_wstart              ,
  output  wire    [ 3  : 0]         ddr_woffset_high        ,
  output  wire    [ 24 : 0]         ddr_woffset             ,
  output  wire    [ 24 : 0]         ddr_wstride             ,  
  output  wire    [  6 : 0]         ddr_wstep_num           ,  
  output  wire    [ 14 : 0]         ddr_wstep               ,
  //---------------------------------------------------------     
  output  wire                      ifm_rstart              ,
  output  wire    [  6 : 0]         ifm_hmax                ,
  output  wire    [  3 : 0]         ifm_hmin                ,
  output  wire    [  2 : 0]         ifm_hs                  ,
  output  wire    [  6 : 0]         ifm_h                   ,
  output  wire    [  6 : 0]         ifm_wmax                ,
  output  wire    [  3 : 0]         ifm_wmin                ,
  output  wire    [  2 : 0]         ifm_ws                  ,
  output  wire    [  6 : 0]         ifm_w                   ,
  output  wire    [  5 : 0]         ifm_rkeep               ,
  output  wire    [  1 : 0]         ifm_rsel                ,
  output  wire                      ifm_pp                  ,
  output  wire    [  5 : 0]         ker_eaddr               ,
  output  wire    [  5 : 0]         ker_saddr               ,
  output  wire                      ker_pp                  ,
  output  wire    [  2 : 0]         pe_output_num           ,
  //---------------------------------------------------------
  output  wire                      bias_pp                 ,  
  output  wire    [  2 : 0]         ofm_din_enc             ,
  output  wire                      ofm_bias_sel            ,
  output  wire    [  9 : 0]         ofm_bias_snum           ,  
  output  wire    [  6 : 0]         ofm_concat_num          ,  
  output  wire                      ofm_tmp_sel             ,
  output  wire                      ofm_output_sel          ,
  output  wire    [  4 : 0]         ofm_din_snum            ,
  output  wire    [ 14 : 0]         ofm_rbase               ,
  output  wire    [ 14 : 0]         ofm_wbase               ,
  output  wire                      ofm_pp                  ,  
  output  wire                      ofm_rstart              ,  
  //--------------------------------------------------------
  output  wire                      nvm_rstart              ,  
  output  wire                      nvm_res_en              ,
  output  wire                      nvm_act_en              ,
  output  wire    [  3 : 0]         nvm_act_type            ,
  output  wire                      nvm_sf_en               ,
  output  wire                      nvm_ln_en               ,
  output  wire                      nvm_tr_en               ,
  output  wire    [ 10 : 0]         nvm_rnum                ,
  output  wire    [  6 : 0]         nvm_rstep               ,
  output  wire    [ 11 : 0]         nvm_xnum                ,
  output  wire    [ 11 : 0]         nvm_ynum                ,
  output  wire    [ 11 : 0]         nvm_bnum                ,
  output  wire    [ 11 : 0]         nvm_gnum                ,
  output  wire                      nvm_idir                ,
  output  wire    [  5 : 0]         nvm_inum                ,
  output  wire                      nvm_odir                ,
  output  wire    [  5 : 0]         nvm_onum                ,
  output  wire                      nvm_router              ,
  //---------------------------------------------------------
  input                             ddr_rdone               ,  
  input                             ifm_rdone_inst          , 
  input                             ofm_rdone               ,
  input                             ofm_rdone_final         ,
  input                             nvm_rdone               ,   
  input   wire                      ddr_wdone               ,
  output  reg     [  31: 0 ]        opcode_cnt  =0          ,  
  output  wire                      layer_final             ,  
  output  wire                      layer_start             ,
  output  reg                       layer_start_init=0      ,
  input   wire                      layer_start_sync        ,
  input           [ 3  : 0]         core_offset_high        ,
  input           [ 24 : 0]         core_offset             ,
  input                             core_start              ,
  input                             clk                     ,
  input                             reset                   
);
  wire                       inst_ready                      ;
  wire                       inst_rstart                     ;
  wire                       inst_rvld                       ;
  wire     [ 31 : 0]         inst_rdata                      ;
  wire     [ 31 : 0]         inst_round                      ;
  //------------------------------------------------------------------
  //The signal of the decoder. Note: Naming of rules.
  //------------------------------------------------------------------
  wire                       dec_dw_flag                     ;//0 
  wire     [  6 : 0]         dec_ifm_w                       ;//0
  wire     [  6 : 0]         dec_ifm_h                       ;//0
  wire     [  9 : 0]         dec_fm_in_ysize                 ;//1
  wire     [  9 : 0]         dec_fm_in_xsize                 ;//1
  wire     [ 10 : 0]         dec_cout                        ;//2
  wire     [ 10 : 0]         dec_cin                         ;//2
  wire     [ 24 : 0]         dec_ddr_rfm_offset              ;//3
  wire     [ 24 : 0]         dec_ddr_rker_offset             ;//4
  wire     [ 24 : 0]         dec_ddr_rbias_offset            ;//5
  wire     [ 24 : 0]         dec_ddr_rres_offset             ;//6
  wire     [ 14 : 0]         dec_ddr_rfm_num                 ;//7
  wire     [ 14 : 0]         dec_ddr_rker_num                ;//8
  wire     [ 14 : 0]         dec_ddr_rbias_num               ;//9
  wire     [ 14:  0]         dec_ddr_wfm_num                 ;//10
  wire                       dec_ddr_rsingle                 ;//11
  wire     [  5 : 0]         dec_ker_on_board                ;//11
  wire     [  2 : 0]         dec_ddr_rstart_trig             ;//11
  wire     [  8 : 0]         dec_ddr_rstart_dma_num          ;//11
  wire     [  5 : 0]         dec_ddr_rtype                   ;//11
  wire     [  2 : 0]         dec_ifm_rstart_trig             ;//12
  wire     [  6 : 0]         dec_ifm_wmax                    ;//12
  wire     [  3 : 0]         dec_ifm_wmin                    ;//12  
  wire     [  6 : 0]         dec_ifm_hmax                    ;//12
  wire     [  3 : 0]         dec_ifm_hmin                    ;//12
  wire     [  3 : 0]         dec_ker_ysize                   ;//13
  wire     [  3 : 0]         dec_ker_xsize                   ;//13 
  wire     [  2 : 0]         dec_ifm_ws                      ;//13  
  wire     [  2 : 0]         dec_ifm_hs                      ;//13
  wire     [  4 : 0]         dec_ker_repeat                  ;//13  
  wire     [  2 : 0]         dec_layer_type                  ;//14  
  wire     [  5 : 0]         dec_ifm_rkeep                   ;//14 
  wire     [  2 : 0]         dec_pe_output_num               ;//14
  wire     [  1 : 0]         dec_ifm_rsel                    ;//15   
  wire     [  4 : 0]         dec_ker_repeat_last             ;//15 
  wire     [  3 : 0]         dec_dma_shift                   ;//15
  wire                       dec_dma_shift_dir               ;//15  
  wire     [  5 : 0]         dec_ker_eaddr                   ;//15
  wire     [  5 : 0]         dec_ker_saddr                   ;//15  
  wire     [  6 : 0]         dec_ofm_concat_num              ;//16
  wire                       dec_output_final_blk            ;//16
  wire                       dec_final_output                ;//16  
  wire                       dec_ofm_tmp_sel                 ;//16
  wire                       dec_bias_sel                    ;//16
  wire     [  9 : 0]         dec_bias_snum                   ;//16
  wire     [  2 : 0]         dec_ofm_rstart_trig             ;//16  
  wire     [  4 : 0]         dec_ofm_snum                    ;//17
  wire     [  9 : 0]         dec_fm_out_ysize                ;//17
  wire     [  9 : 0]         dec_fm_out_xsize                ;//17
  wire                       dec_ddr_wsel                    ;//18  
  wire     [  2 : 0]         dec_padding_size                ;//18
  wire     [  3 : 0]         dec_act_type                    ;//18
  wire     [  2 : 0]         dec_pool_ys                     ;//18
  wire     [  2 : 0]         dec_pool_xs                     ;//18
  wire     [  1 : 0]         dec_pool_type                   ;//18
  wire     [  3 : 0]         dec_pool_ysize                  ;//18
  wire     [  3 : 0]         dec_pool_xsize                  ;//18
  wire                       dec_pool_decrapated             ;//18
  wire                       dec_ddr_save_need_sync          ;//19
  wire                       dec_ddr_wdes                    ;//19
  wire     [  2 : 0]         dec_ddr_wstart_trig             ;//19
  wire     [  6 : 0]         dec_pool_blk_ysize              ;//19
  wire     [  6 : 0]         dec_pool_blk_xsize              ;//19
  wire                       dec_res_en                      ;//19
  wire                       dec_ups_en                      ;//19 
  wire                       dec_act_en                      ;//19  
  wire                       dec_pool_en                     ;//19   
  wire                       dec_pad_en                      ;//19  
  wire     [ 24 : 0]         dec_ddr_wfm_offset              ;//20  
  wire     [ 24 : 0]         dec_ddr_rins_offset             ;//21  
  wire                       dec_network_done                ;//22
  wire     [  7 : 0]         dec_output_blk_ysize            ;//23
  wire     [  7 : 0]         dec_output_blk_xsize            ;//23
  wire     [ 63 : 0]         dec_ddr_wmask                   ;//24,25,26
  wire     [  2 : 0]         dec_pool_padding_l              ;//27
  wire     [  2 : 0]         dec_pool_padding_r              ;//27
  wire     [  2 : 0]         dec_pool_padding_u              ;//27
  wire     [  2 : 0]         dec_pool_padding_d              ;//27
  wire     [  6 : 0]         dec_ddr_rblk_ysize              ;//28
  wire     [  6 : 0]         dec_ddr_rblk_xsize              ;//28
  wire     [  7 : 0]         dec_avg_pool_param              ;//29
  wire     [  6 : 0]         dec_ddr_wblk_ysize              ;//29
  wire     [  6 : 0]         dec_ddr_wblk_xsize              ;//29
  wire                       dec_default_flag                ;//30  
  wire     [  6 : 0]         dec_out_ymax                    ;//30
  wire     [  3 : 0]         dec_out_ymin                    ;//30
  wire     [  6 : 0]         dec_out_xmax                    ;//30
  wire     [  3 : 0]         dec_out_xmin                    ;//30
  wire     [  6 : 0]         dec_out_ys                      ;//31
  wire     [  6 : 0]         dec_out_xs                      ;//31 
  wire     [  2 : 0]         dec_se_stage                    ;//32
  wire     [  2 : 0]         dec_se_fc_in_num                ;//32
  wire     [  7 : 0]         dec_se_fc_out_num               ;//32 
  wire     [ 24 : 0]         dec_ddr_rparam_offset           ;//33
  wire     [ 14 : 0]         dec_ddr_rparam_num              ;//34
  wire     [ 14 : 0]         dec_ofm_rbase                   ;//35
  wire     [ 14 : 0]         dec_ofm_wbase                   ;//35
  wire     [  1 : 0]         dec_param_bank_id               ;//36
  wire                       dec_add_zero                    ;//36           
  wire     [  3 : 0]         dec_ddr_wpos                    ;//37        
  wire     [ 11 : 0]         dec_nvm_xnum                    ;//38
  wire     [ 11 : 0]         dec_nvm_ynum                    ;//38
  wire     [ 11 : 0]         dec_nvm_gnum                    ;//39
  wire     [ 11 : 0]         dec_nvm_bnum                    ;//39
  wire                       dec_nvm_idir                    ;//40
  wire     [  5 : 0]         dec_nvm_inum                    ;//40
  wire                       dec_nvm_odir                    ;//40
  wire     [  5 : 0]         dec_nvm_onum                    ;//40 
  wire     [  3 : 0]         dec_high_addr_ini_ddr_param     ;//41
  wire     [  3 : 0]         dec_high_addr_ini_ddr_ins       ;//41
  wire     [  3 : 0]         dec_high_addr_ini_fm_output     ;//41
  wire     [  3 : 0]         dec_high_addr_ini_ddr_bias      ;//41
  wire     [  3 : 0]         dec_high_addr_ini_ddr_fm        ;//41
  wire     [  3 : 0]         dec_high_addr_ini_ddr_ker       ;//41
  wire     [ 14 : 0]         dec_ddr_sparse_mask_rnum        ;//42
  wire                       dec_ddr_sparse_mask_enable      ;//42
  //----------------------------------------------------------
  wire     [  3 : 0]         ddr_high_addr_ini_ddr_fm        ;//41
  wire     [ 24 : 0]         ddr_rfm_offset                  ;//3
  wire     [  9 : 0]         ddr_fm_in_xsize                 ;//1 
  wire     [  9 : 0]         ddr_fm_in_ysize                 ;//1  
  wire     [ 14 : 0]         ddr_rfm_num                     ;//7  
  wire     [  3 : 0]         ddr_high_addr_ini_ddr_ker       ;//41 
  wire     [ 24 : 0]         ddr_rker_offset                 ;//4  
  wire     [ 14 : 0]         ddr_rker_num                    ;//8  
  wire                       ddr_sparse_mask_enable          ;//42 
  wire     [14  : 0]         ddr_sparse_mask_rnum            ;//42
  wire     [  3 : 0]         ddr_high_addr_ini_ddr_bias      ;//41
  wire     [ 24 : 0]         ddr_rbias_offset                ;//5  
  wire     [ 14 : 0]         ddr_rbias_num                   ;//9  
  wire     [ 24 : 0]         ddr_rres_offset                 ;//6 
  wire     [  6 : 0]         ddr_rblk_ysize                  ;//28
  wire     [  6 : 0]         ddr_rblk_xsize                  ;//28 
  wire     [  3 : 0]         ddr_high_addr_ini_ddr_ins       ;//41     
  wire     [ 24 : 0]         ddr_rins_offset                 ;//21 
  wire     [  3 : 0]         ddr_high_addr_ini_ddr_param     ;//41  
  wire     [ 24 : 0]         ddr_rparam_offset               ;//33 
  wire     [ 14 : 0]         ddr_rparam_num                  ;//34 
  wire     [  6 : 0]         ddr_rtype                       ;//11
  wire     [ 3  : 0]         ddr_high_addr_ini_fm_output     ;//41
  wire     [ 24 : 0]         ddr_wfm_offset                  ;//20
  wire     [ 9  : 0]         ddr_fm_out_xsize                ;//17      
  wire     [ 6  : 0]         ddr_wblk_ysize                  ;//29      
  wire     [ 6  : 0]         ddr_wblk_xsize                  ;//29
  reg                        layer_init = 0                  ;
  wire                       layer_trig                      ;  
  wire                       state_rdone                     ;
  wire     [8-1:0]           dec_ddr_rstart_r                ;
  wire                       dec_ddr_rstart                  ;
  wire                       dec_ifm_rstart                  ;
  wire                       dec_ofm_rstart                  ;
  wire                       dec_ddr_wstart                  ;
  wire                       dec_nvm_rstart                  ;


  //------------------------------------------------------------------------
  //Once the first instruction fetch is completed, 
  //immediately pull up one cycle
  //Use the signal that completes the ddr every time it 
  //is written as the starting signal for the next layer
  //------------------------------------------------------------------------
  always @(posedge clk)
  if ( layer_start )        layer_init     <=  1'b0          ;
  else if ( core_start )    layer_init     <=  1'b1          ;
    
  always @(posedge clk)
  layer_start_init <=(layer_init&inst_rvld&~inst_rdata[31])|layer_trig;          
  assign  layer_start  = layer_start_sync                    ;

  assign inst_rstart=dec_ddr_rstart|dec_ifm_rstart|dec_ddr_wstart;

   (*keep_hierarchy="yes"*)inst_buffer 
   u0_inst_buffer
   (
   .core_start                  (core_start                 ),
   .inst_wstart                 (inst_wstart                ),
   .inst_wvld                   (inst_wvld                  ),    
   .inst_wdata                  (inst_wdata                 ),
   .inst_ready                  (inst_ready                 ),
   .inst_rstart                 (inst_rstart                ),
   .inst_rvld                   (inst_rvld                  ),    
   .inst_rdata                  (inst_rdata                 ), 
   .inst_round                  (inst_round                 ), 
   .clk                         (clk                        ),
   .reset                       (reset                      )
   );

  //------------------------------------------------------------------
  //
  //------------------------------------------------------------------
   (*keep_hierarchy="yes"*)inst_trigger 
   u0_inst_trigger
   (
   .inst_round                  (inst_round                 ),
   .dec_ddr_rstart_trig         (dec_ddr_rstart_trig        ),
   .dec_ifm_rstart_trig         (dec_ifm_rstart_trig        ),
   .dec_ofm_rstart_trig         (dec_ofm_rstart_trig        ),    
   .dec_ddr_wstart_trig         (dec_ddr_wstart_trig        ),
   .dec_ddr_rstart_r            (dec_ddr_rstart_r           ),//o
   .dec_ddr_rstart              (dec_ddr_rstart             ),
   .dec_ifm_rstart              (dec_ifm_rstart             ),    
   .dec_ofm_rstart              (dec_ofm_rstart             ),  
   .dec_ddr_wstart              (dec_ddr_wstart             ),
   .dec_nvm_rstart              (dec_nvm_rstart             ),
   .ddr_rtype                   (ddr_rtype                  ),
   .layer_start                 (layer_start                ),
   .state_rdone                 (state_rdone                ),
   .ifm_rdone_inst              (ifm_rdone_inst             ),
   .ofm_rdone                   (ofm_rdone                  ),
   .ofm_rdone_final             (ofm_rdone_final            ),
   .ddr_wdone                   (ddr_wdone                  ),
   .nvm_rdone                   (nvm_rdone                  ),
   .layer_trig                  (layer_trig                 ),
   .layer_final                 (layer_final                ),
   .clk                         (clk                        ),
   .reset                       (reset                      )
   );

  //------------------------------------------------------------------
  //
  //------------------------------------------------------------------
  (*keep_hierarchy="yes"*)inst_state 
  u0_inst_state(
   .ddr_rstart                  (ddr_rstart                 ),
   .ddr_rid                     (ddr_rid                    ),
   .ddr_roffset_high            (ddr_roffset_high           ),
   .ddr_roffset                 (ddr_roffset                ),
   .ddr_rstride                 (ddr_rstride                ),
   .ddr_rstep_num               (ddr_rstep_num              ),
   .ddr_rstep                   (ddr_rstep                  ),
   .ddr_bm_num                  (ddr_bm_num                 ),
   .ddr_bm_en                   (ddr_bm_en                  ),
   //
   .ddr_wstart                  (ddr_wstart                 ),
   .ddr_woffset_high            (ddr_woffset_high           ),
   .ddr_woffset                 (ddr_woffset                ),
   .ddr_wstride                 (ddr_wstride                ),  
   .ddr_wstep_num               (ddr_wstep_num              ),  
   .ddr_wstep                   (ddr_wstep                  ),
   //
   .ddr_high_addr_ini_ddr_fm    (ddr_high_addr_ini_ddr_fm   ),
   .ddr_rfm_offset              (ddr_rfm_offset             ),
   .ddr_fm_in_xsize             (ddr_fm_in_xsize            ),
   .ddr_fm_in_ysize             (ddr_fm_in_ysize            ),
   .ddr_rfm_num                 (ddr_rfm_num                ),
   .ddr_high_addr_ini_ddr_ker   (ddr_high_addr_ini_ddr_ker  ),
   .ddr_rker_offset             (ddr_rker_offset            ),
   .ddr_rker_num                (ddr_rker_num               ),
   .ddr_sparse_mask_enable      (ddr_sparse_mask_enable     ),
   .ddr_sparse_mask_rnum        (ddr_sparse_mask_rnum       ),
   .ddr_high_addr_ini_ddr_bias  (ddr_high_addr_ini_ddr_bias ),
   .ddr_rbias_offset            (ddr_rbias_offset           ),
   .ddr_rbias_num               (ddr_rbias_num              ),
   .ddr_rres_offset             (ddr_rres_offset            ),
   .ddr_rblk_ysize              (ddr_rblk_ysize             ),
   .ddr_rblk_xsize              (ddr_rblk_xsize             ),
   .ddr_high_addr_ini_ddr_ins   (ddr_high_addr_ini_ddr_ins  ),
   .ddr_rins_offset             (ddr_rins_offset            ),
   .ddr_high_addr_ini_ddr_param (ddr_high_addr_ini_ddr_param),
   .ddr_rparam_offset           (ddr_rparam_offset          ),
   .ddr_rparam_num              (ddr_rparam_num             ),
   .ddr_rtype                   (ddr_rtype                  ),
   .dec_ddr_rtype               (dec_ddr_rtype              ),
   .dec_ddr_rstart              (dec_ddr_rstart             ),
   //
   .ddr_high_addr_ini_fm_output (ddr_high_addr_ini_fm_output),
   .ddr_wfm_offset              (ddr_wfm_offset             ),
   .ddr_fm_out_xsize            (ddr_fm_out_xsize           ),
   .ddr_wblk_ysize              (ddr_wblk_ysize             ),
   .ddr_wblk_xsize              (ddr_wblk_xsize             ),
   .dec_ddr_wstart              (dec_ddr_wstart             ),
   //
   .core_offset_high            (core_offset_high           ),
   .core_offset                 (core_offset                ),
   .core_start                  (core_start                 ),
   .inst_ready                  (inst_ready                 ),
   .ofm_rdone_final             (ofm_rdone_final            ),
   .ddr_rdone                   (ddr_rdone                  ),
   .state_rdone                 (state_rdone                ),
   .clk                         (clk                        ),
   .reset                       (reset                      )
);

  //------------------------------------------------------------------
  //
  //------------------------------------------------------------------
   (*keep_hierarchy="yes"*)inst_register 
   u0_inst_register(
   .dec_high_addr_ini_ddr_fm    (dec_high_addr_ini_ddr_fm   ),//41 
   .dec_ddr_rfm_offset          (dec_ddr_rfm_offset         ),//3  
   .dec_fm_in_xsize             (dec_fm_in_xsize            ),//1
   .dec_fm_in_ysize             (dec_fm_in_ysize            ),//1  
   .dec_ddr_rfm_num             (dec_ddr_rfm_num            ),//7 
   .dec_high_addr_ini_ddr_ker   (dec_high_addr_ini_ddr_ker  ),//41
   .dec_ddr_rker_offset         (dec_ddr_rker_offset        ),//4  
   .dec_ddr_rker_num            (dec_ddr_rker_num           ),//8 
   .dec_ddr_sparse_mask_enable  (dec_ddr_sparse_mask_enable ),//42  
   .dec_ddr_sparse_mask_rnum    (dec_ddr_sparse_mask_rnum   ),//42
   .dec_high_addr_ini_ddr_bias  (dec_high_addr_ini_ddr_bias ),//41  
   .dec_ddr_rbias_offset        (dec_ddr_rbias_offset       ),//5  
   .dec_ddr_rbias_num           (dec_ddr_rbias_num          ),//9 
   .dec_ddr_rres_offset         (dec_ddr_rres_offset        ),//6  
   .dec_ddr_rblk_ysize          (dec_ddr_rblk_ysize         ),//28 
   .dec_ddr_rblk_xsize          (dec_ddr_rblk_xsize         ),//28    
   .dec_high_addr_ini_ddr_ins   (dec_high_addr_ini_ddr_ins  ),//41  
   .dec_ddr_rins_offset         (dec_ddr_rins_offset        ),//21   
   .dec_high_addr_ini_ddr_param (dec_high_addr_ini_ddr_param),//41   
   .dec_ddr_rparam_offset       (dec_ddr_rparam_offset      ),//33    
   .dec_ddr_rparam_num          (dec_ddr_rparam_num         ),//34 
   .dec_ddr_rtype               (dec_ddr_rtype              ),//11
   .dec_param_bank_id           (dec_param_bank_id          ),//36 
   .dec_high_addr_ini_fm_output (dec_high_addr_ini_fm_output),//41   
   .dec_ddr_wfm_offset          (dec_ddr_wfm_offset         ),//20
   .dec_fm_out_xsize            (dec_fm_out_xsize           ),//17  
   .dec_ddr_wblk_ysize          (dec_ddr_wblk_ysize         ),//29    
   .dec_ddr_wblk_xsize          (dec_ddr_wblk_xsize         ),//29   
   .ddr_high_addr_ini_ddr_fm    (ddr_high_addr_ini_ddr_fm   ),
   .ddr_rfm_offset              (ddr_rfm_offset             ),
   .ddr_fm_in_xsize             (ddr_fm_in_xsize            ),
   .ddr_fm_in_ysize             (ddr_fm_in_ysize            ),
   .ddr_rfm_num                 (ddr_rfm_num                ),
   .ddr_high_addr_ini_ddr_ker   (ddr_high_addr_ini_ddr_ker  ),
   .ddr_rker_offset             (ddr_rker_offset            ),
   .ddr_rker_num                (ddr_rker_num               ),
   .ddr_sparse_mask_enable      (ddr_sparse_mask_enable     ),
   .ddr_sparse_mask_rnum        (ddr_sparse_mask_rnum       ),
   .ddr_high_addr_ini_ddr_bias  (ddr_high_addr_ini_ddr_bias ),
   .ddr_rbias_offset            (ddr_rbias_offset           ),
   .ddr_rbias_num               (ddr_rbias_num              ),
   .ddr_rres_offset             (ddr_rres_offset            ),
   .ddr_rblk_ysize              (ddr_rblk_ysize             ),
   .ddr_rblk_xsize              (ddr_rblk_xsize             ),
   .ddr_high_addr_ini_ddr_ins   (ddr_high_addr_ini_ddr_ins  ),
   .ddr_rins_offset             (ddr_rins_offset            ),
   .ddr_high_addr_ini_ddr_param (ddr_high_addr_ini_ddr_param),
   .ddr_rparam_offset           (ddr_rparam_offset          ),
   .ddr_rparam_num              (ddr_rparam_num             ),
   .ddr_rtype                   (ddr_rtype                  ),
   .ddr_high_addr_ini_fm_output (ddr_high_addr_ini_fm_output),
   .ddr_wfm_offset              (ddr_wfm_offset             ),
   .ddr_fm_out_xsize            (ddr_fm_out_xsize           ),
   .ddr_wblk_ysize              (ddr_wblk_ysize             ),
   .ddr_wblk_xsize              (ddr_wblk_xsize             ),
   //---------------------------------------------------------
   .dec_ifm_hmax                (dec_ifm_hmax               ),  
   .dec_ifm_hmin                (dec_ifm_hmin               ),    
   .dec_ifm_hs                  (dec_ifm_hs                 ),    
   .dec_ifm_h                   (dec_ifm_h                  ),    
   .dec_ifm_wmax                (dec_ifm_wmax               ),    
   .dec_ifm_wmin                (dec_ifm_wmin               ),    
   .dec_ifm_ws                  (dec_ifm_ws                 ),    
   .dec_ifm_w                   (dec_ifm_w                  ),    
   .dec_ifm_rkeep               (dec_ifm_rkeep              ),    
   .dec_ifm_rsel                (dec_ifm_rsel               ),//15
   .dec_ker_eaddr               (dec_ker_eaddr              ),    
   .dec_ker_saddr               (dec_ker_saddr              ), 
   .dec_pe_output_num           (dec_pe_output_num          ),   
   .ifm_rstart                  (ifm_rstart                 ),
   .ifm_hmax                    (ifm_hmax                   ),
   .ifm_hmin                    (ifm_hmin                   ),
   .ifm_hs                      (ifm_hs                     ),
   .ifm_h                       (ifm_h                      ),
   .ifm_wmax                    (ifm_wmax                   ),
   .ifm_wmin                    (ifm_wmin                   ),
   .ifm_ws                      (ifm_ws                     ),
   .ifm_w                       (ifm_w                      ),
   .ifm_rkeep                   (ifm_rkeep                  ),
   .ifm_rsel                    (ifm_rsel                   ),
   .ifm_pp                      (ifm_pp                     ),
   .ker_eaddr                   (ker_eaddr                  ),
   .ker_saddr                   (ker_saddr                  ),
   .ker_pp                      (ker_pp                     ),
   .pe_output_num               (pe_output_num              ),   
   //--------------------------------------------------------
   .dec_bias_sel                (dec_bias_sel               ),   
   .dec_bias_snum               (dec_bias_snum              ),  
   .dec_ofm_concat_num          (dec_ofm_concat_num         ),//16
   .dec_ofm_tmp_sel             (dec_ofm_tmp_sel            ),    
   .dec_final_output            (dec_final_output           ), 
   .dec_ofm_snum                (dec_ofm_snum               ),//17
   .dec_ofm_rbase               (dec_ofm_rbase              ),//35
   .dec_ofm_wbase               (dec_ofm_wbase              ),
   .bias_pp                     (bias_pp                    ),
   .ofm_din_enc                 (ofm_din_enc                ),
   .ofm_bias_sel                (ofm_bias_sel               ),
   .ofm_bias_snum               (ofm_bias_snum              ),
   .ofm_rstart                  (ofm_rstart                 ), 
   .ofm_concat_num              (ofm_concat_num             ),
   .ofm_tmp_sel                 (ofm_tmp_sel                ),
   .ofm_output_sel              (ofm_output_sel             ),
   .ofm_din_snum                (ofm_din_snum               ),
   .ofm_rbase                   (ofm_rbase                  ),
   .ofm_wbase                   (ofm_wbase                  ),
   .ofm_pp                      (ofm_pp                     ),
   //---------------------------------------------------------
   .dec_res_en                  (dec_res_en                 ),    
   .dec_act_en                  (dec_act_en                 ),    
   .dec_act_type                (dec_act_type               ),  
   .dec_ddr_wpos                (dec_ddr_wpos               ),
   .dec_ddr_save_need_sync      (dec_ddr_save_need_sync     ),//19
   .dec_cout                    (dec_cout                   ),//2                                       
   .dec_nvm_xnum                (dec_nvm_xnum               ),//38
   .dec_nvm_ynum                (dec_nvm_ynum               ),
   .dec_nvm_bnum                (dec_nvm_bnum               ),         
   .dec_nvm_gnum                (dec_nvm_gnum               ),//39
   .dec_nvm_idir                (dec_nvm_idir               ),//40
   .dec_nvm_inum                (dec_nvm_inum               ),    
   .dec_nvm_odir                (dec_nvm_odir               ),    
   .dec_nvm_onum                (dec_nvm_onum               ), 
   .nvm_rstart                  (nvm_rstart                 ),  
   .nvm_res_en                  (nvm_res_en                 ),
   .nvm_act_en                  (nvm_act_en                 ),
   .nvm_act_type                (nvm_act_type               ),
   .nvm_sf_en                   (nvm_sf_en                  ),
   .nvm_ln_en                   (nvm_ln_en                  ),
   .nvm_tr_en                   (nvm_tr_en                  ),
   .nvm_router                  (nvm_router                 ),
   .nvm_rnum                    (nvm_rnum                   ),
   .nvm_rstep                   (nvm_rstep                  ),
   .nvm_xnum                    (nvm_xnum                   ),
   .nvm_ynum                    (nvm_ynum                   ),
   .nvm_bnum                    (nvm_bnum                   ),
   .nvm_gnum                    (nvm_gnum                   ),
   .nvm_idir                    (nvm_idir                   ),
   .nvm_inum                    (nvm_inum                   ),
   .nvm_odir                    (nvm_odir                   ),
   .nvm_onum                    (nvm_onum                   ),
   //--------------------------------------------------------
   .dec_ddr_rstart_r            (dec_ddr_rstart_r           ),//i
   .dec_ddr_rstart              (dec_ddr_rstart             ),//i
   .dec_ifm_rstart              (dec_ifm_rstart             ),//i
   .dec_ofm_rstart              (dec_ofm_rstart             ),//i
   .dec_ddr_wstart              (dec_ddr_wstart             ),//i
   .dec_nvm_rstart              (dec_nvm_rstart             ),//i
   //--------------------------------------------------------    
   .core_start                  (core_start                 ),
   .state_rdone                 (state_rdone                ),
   .nvm_rdone                   (nvm_rdone                  ),
   .clk                         (clk                        ),
   .reset                       (reset                      )
);


//-----------------------------------------------------------
//Instantiate decoder module
//-----------------------------------------------------------
  (*keep_hierarchy="yes"*)inst_decoder
  u0_inst_decoder(
  .dec_dw_flag                 (dec_dw_flag                 ),//0 
  .dec_ifm_w                   (dec_ifm_w                   ),
  .dec_ifm_h                   (dec_ifm_h                   ),
  .dec_fm_in_ysize             (dec_fm_in_ysize             ),//1
  .dec_fm_in_xsize             (dec_fm_in_xsize             ),
  .dec_cout                    (dec_cout                    ),//2
  .dec_cin                     (dec_cin                     ),
  .dec_ddr_rfm_offset          (dec_ddr_rfm_offset          ),//3
  .dec_ddr_rker_offset         (dec_ddr_rker_offset         ),//4
  .dec_ddr_rbias_offset        (dec_ddr_rbias_offset        ),//5
  .dec_ddr_rres_offset         (dec_ddr_rres_offset         ),//6
  .dec_ddr_rfm_num             (dec_ddr_rfm_num             ),//7
  .dec_ddr_rker_num            (dec_ddr_rker_num            ),//8
  .dec_ddr_rbias_num           (dec_ddr_rbias_num           ),//9
  .dec_ddr_wfm_num             (dec_ddr_wfm_num             ),//10
  .dec_ddr_rsingle             (dec_ddr_rsingle             ),//11
  .dec_ker_on_board            (dec_ker_on_board            ),
  .dec_ddr_rstart_trig         (dec_ddr_rstart_trig         ),
  .dec_ddr_rstart_dma_num      (dec_ddr_rstart_dma_num      ),
  .dec_ddr_rtype               (dec_ddr_rtype               ),
  .dec_ifm_rstart_trig         (dec_ifm_rstart_trig         ),//12
  .dec_ifm_wmax                (dec_ifm_wmax                ),
  .dec_ifm_wmin                (dec_ifm_wmin                ),  
  .dec_ifm_hmax                (dec_ifm_hmax                ),
  .dec_ifm_hmin                (dec_ifm_hmin                ),
  .dec_ker_ysize               (dec_ker_ysize               ),//13
  .dec_ker_xsize               (dec_ker_xsize               ), 
  .dec_ifm_ws                  (dec_ifm_ws                  ),  
  .dec_ifm_hs                  (dec_ifm_hs                  ),
  .dec_ker_repeat              (dec_ker_repeat              ),  
  .dec_layer_type              (dec_layer_type              ),//14  
  .dec_ifm_rkeep               (dec_ifm_rkeep               ), 
  .dec_pe_output_num           (dec_pe_output_num           ),
  .dec_ifm_rsel                (dec_ifm_rsel                ),//15   
  .dec_ker_repeat_last         (dec_ker_repeat_last         ), 
  .dec_dma_shift               (dec_dma_shift               ),
  .dec_dma_shift_dir           (dec_dma_shift_dir           ),  
  .dec_ker_eaddr               (dec_ker_eaddr               ),
  .dec_ker_saddr               (dec_ker_saddr               ),  
  .dec_ofm_concat_num          (dec_ofm_concat_num          ),//16
  .dec_output_final_blk        (dec_output_final_blk        ),
  .dec_final_output            (dec_final_output            ),  
  .dec_ofm_tmp_sel             (dec_ofm_tmp_sel             ),
  .dec_bias_sel                (dec_bias_sel                ),
  .dec_bias_snum               (dec_bias_snum               ),
  .dec_ofm_rstart_trig         (dec_ofm_rstart_trig         ),  
  .dec_ofm_snum                (dec_ofm_snum                ),//17
  .dec_fm_out_ysize            (dec_fm_out_ysize            ),
  .dec_fm_out_xsize            (dec_fm_out_xsize            ),
  .dec_ddr_wsel                (dec_ddr_wsel                ),//18  
  .dec_padding_size            (dec_padding_size            ),
  .dec_act_type                (dec_act_type                ),
  .dec_pool_ys                 (dec_pool_ys                 ),
  .dec_pool_xs                 (dec_pool_xs                 ),
  .dec_pool_type               (dec_pool_type               ),
  .dec_pool_ysize              (dec_pool_ysize              ),
  .dec_pool_xsize              (dec_pool_xsize              ),
  .dec_pool_decrapated         (dec_pool_decrapated         ),
  .dec_ddr_save_need_sync      (dec_ddr_save_need_sync      ),//19
  .dec_ddr_wdes                (dec_ddr_wdes                ),
  .dec_ddr_wstart_trig         (dec_ddr_wstart_trig         ),
  .dec_pool_blk_ysize          (dec_pool_blk_ysize          ),
  .dec_pool_blk_xsize          (dec_pool_blk_xsize          ),
  .dec_res_en                  (dec_res_en                  ),
  .dec_ups_en                  (dec_ups_en                  ), 
  .dec_act_en                  (dec_act_en                  ),  
  .dec_pool_en                 (dec_pool_en                 ),   
  .dec_pad_en                  (dec_pad_en                  ),  
  .dec_ddr_wfm_offset          (dec_ddr_wfm_offset          ),//20  
  .dec_ddr_rins_offset         (dec_ddr_rins_offset         ),//21  
  .dec_network_done            (dec_network_done            ),//22
  .dec_output_blk_ysize        (dec_output_blk_ysize        ),//23
  .dec_output_blk_xsize        (dec_output_blk_xsize        ),
  .dec_ddr_wmask               (dec_ddr_wmask               ),//24,25,26
  .dec_pool_padding_l          (dec_pool_padding_l          ),//27
  .dec_pool_padding_r          (dec_pool_padding_r          ),
  .dec_pool_padding_u          (dec_pool_padding_u          ),
  .dec_pool_padding_d          (dec_pool_padding_d          ),
  .dec_ddr_rblk_ysize          (dec_ddr_rblk_ysize          ),//28
  .dec_ddr_rblk_xsize          (dec_ddr_rblk_xsize          ),
  .dec_avg_pool_param          (dec_avg_pool_param          ),//29
  .dec_ddr_wblk_ysize          (dec_ddr_wblk_ysize          ),
  .dec_ddr_wblk_xsize          (dec_ddr_wblk_xsize          ),
  .dec_default_flag            (dec_default_flag            ),//30  
  .dec_out_ymax                (dec_out_ymax                ),
  .dec_out_ymin                (dec_out_ymin                ),
  .dec_out_xmax                (dec_out_xmax                ),
  .dec_out_xmin                (dec_out_xmin                ),
  .dec_out_ys                  (dec_out_ys                  ),//31
  .dec_out_xs                  (dec_out_xs                  ), 
  .dec_se_stage                (dec_se_stage                ),//32
  .dec_se_fc_in_num            (dec_se_fc_in_num            ),
  .dec_se_fc_out_num           (dec_se_fc_out_num           ), 
  .dec_ddr_rparam_offset       (dec_ddr_rparam_offset       ),//33
  .dec_ddr_rparam_num          (dec_ddr_rparam_num          ),//34
  .dec_ofm_rbase               (dec_ofm_rbase               ),//35
  .dec_ofm_wbase               (dec_ofm_wbase               ),
  .dec_param_bank_id           (dec_param_bank_id           ),//36
  .dec_add_zero                (dec_add_zero                ),           
  .dec_ddr_wpos                (dec_ddr_wpos                ),//37        
  .dec_nvm_xnum                (dec_nvm_xnum                ),//38
  .dec_nvm_ynum                (dec_nvm_ynum                ),
  .dec_nvm_gnum                (dec_nvm_gnum                ),//39
  .dec_nvm_bnum                (dec_nvm_bnum                ),
  .dec_nvm_idir                (dec_nvm_idir                ),//40
  .dec_nvm_inum                (dec_nvm_inum                ),
  .dec_nvm_odir                (dec_nvm_odir                ),
  .dec_nvm_onum                (dec_nvm_onum                ), 
  .dec_high_addr_ini_ddr_param (dec_high_addr_ini_ddr_param ),//41
  .dec_high_addr_ini_ddr_ins   (dec_high_addr_ini_ddr_ins   ),
  .dec_high_addr_ini_fm_output (dec_high_addr_ini_fm_output ),
  .dec_high_addr_ini_ddr_bias  (dec_high_addr_ini_ddr_bias  ),
  .dec_high_addr_ini_ddr_fm    (dec_high_addr_ini_ddr_fm    ),
  .dec_high_addr_ini_ddr_ker   (dec_high_addr_ini_ddr_ker   ),
  .dec_ddr_sparse_mask_rnum    (dec_ddr_sparse_mask_rnum    ),//42
  .dec_ddr_sparse_mask_enable  (dec_ddr_sparse_mask_enable  ),
  .inst_round                  (inst_round                  ),
  .inst_rdata                  (inst_rdata                  ),
  .inst_rvld                   ({64{inst_rvld}}             ),
  .clk                         (clk                         ),
  .reset                       (reset                       )
);











endmodule

