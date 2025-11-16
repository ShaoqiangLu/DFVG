`timescale 1ns / 1ps
// -----------------------------------------------------------------------------
// UCLA EDA LAB
// -----------------------------------------------------------------------------
// Engineer       : Chen Wu
// Design Name    : opu series
// Module Name    : inst_dec
// Target Devices : 325t
// Tool Versions  : Vivado 2020.1, Modelsim 2019.4
// Description    : 
//    Decode instructions
//
// Revision       :
// Version        Date        Author        Descriptin
// 1.0            2021-04-15  Chen Wu       Initial version
// 2.0            2023-09-11  Shaoqiang     Simulation 97 layers,and       
//                                          implementation on FPGA of U200.
// 3.0            2024-05-21  Shaoqiang     Organize the code.
// -----------------------------------------------------------------------------


module inst_decoder
(
  output  reg                       dec_dw_flag                 =0  ,//0 
  output  reg     [  6 : 0]         dec_ifm_w                   =0  ,
  output  reg     [  6 : 0]         dec_ifm_h                   =0  ,
  output  reg     [  9 : 0]         dec_fm_in_ysize             =0  ,//1
  output  reg     [  9 : 0]         dec_fm_in_xsize             =0  ,
  output  reg     [ 10 : 0]         dec_cout                    =0  ,//2
  output  reg     [ 10 : 0]         dec_cin                     =0  ,
  output  reg     [ 24 : 0]         dec_ddr_rfm_offset          =0  ,//3
  output  reg     [ 24 : 0]         dec_ddr_rker_offset         =0  ,//4
  output  reg     [ 24 : 0]         dec_ddr_rbias_offset        =0  ,//5
  output  reg     [ 24 : 0]         dec_ddr_rres_offset         =0  ,//6
  output  reg     [ 14 : 0]         dec_ddr_rfm_num             =0  ,//7
  output  reg     [ 14 : 0]         dec_ddr_rker_num            =0  ,//8
  output  reg     [ 14 : 0]         dec_ddr_rbias_num           =0  ,//9
  output  reg     [ 14:  0]         dec_ddr_wfm_num             =0  ,//10
  output  reg                       dec_ddr_rsingle             =0  ,//11
  output  reg     [  5 : 0]         dec_ker_on_board            =0  ,
  output  reg     [  2 : 0]         dec_ddr_rstart_trig         =0  ,
  output  reg     [  8 : 0]         dec_ddr_rstart_dma_num      =0  ,
  output  reg     [  5 : 0]         dec_ddr_rtype               =0  ,
  output  reg     [  2 : 0]         dec_ifm_rstart_trig         =0  ,//12
  output  reg     [  6 : 0]         dec_ifm_wmax                =0  ,
  output  reg     [  3 : 0]         dec_ifm_wmin                =0  ,  
  output  reg     [  6 : 0]         dec_ifm_hmax                =0  ,
  output  reg     [  3 : 0]         dec_ifm_hmin                =0  ,
  output  reg     [  3 : 0]         dec_ker_ysize               =0  ,//13
  output  reg     [  3 : 0]         dec_ker_xsize               =0  , 
  output  reg     [  2 : 0]         dec_ifm_ws                  =0  ,  
  output  reg     [  2 : 0]         dec_ifm_hs                  =0  ,
  output  reg     [  4 : 0]         dec_ker_repeat              =0  ,  
  output  reg     [  2 : 0]         dec_layer_type              =0  ,//14  
  output  reg     [  5 : 0]         dec_ifm_rkeep               =0  , 
  output  reg     [  2 : 0]         dec_pe_output_num           =0  ,
  output  reg     [  1 : 0]         dec_ifm_rsel                =0  ,//15   
  output  reg     [  4 : 0]         dec_ker_repeat_last         =0  , 
  output  reg     [  3 : 0]         dec_dma_shift               =0  ,
  output  reg                       dec_dma_shift_dir           =0  ,  
  output  reg     [  5 : 0]         dec_ker_eaddr               =0  ,
  output  reg     [  5 : 0]         dec_ker_saddr               =0  ,  
  output  reg     [  6 : 0]         dec_ofm_concat_num          =0  ,//16
  output  reg                       dec_output_final_blk        =0  ,
  output  reg                       dec_final_output            =0  ,  
  output  reg                       dec_ofm_tmp_sel             =0  ,
  output  reg                       dec_bias_sel                =0  ,
  output  reg     [  9 : 0]         dec_bias_snum               =0  ,
  output  reg     [  2 : 0]         dec_ofm_rstart_trig         =0  ,  
  output  reg     [  4 : 0]         dec_ofm_snum                =0  ,//17
  output  reg     [  9 : 0]         dec_fm_out_ysize            =0  ,
  output  reg     [  9 : 0]         dec_fm_out_xsize            =0  ,
  output  reg                       dec_ddr_wsel                =0  ,//18  
  output  reg     [  2 : 0]         dec_padding_size            =0  ,
  output  reg     [  3 : 0]         dec_act_type                =0  ,
  output  reg     [  2 : 0]         dec_pool_ys                 =0  ,
  output  reg     [  2 : 0]         dec_pool_xs                 =0  ,
  output  reg     [  1 : 0]         dec_pool_type               =0  ,
  output  reg     [  3 : 0]         dec_pool_ysize              =0  ,
  output  reg     [  3 : 0]         dec_pool_xsize              =0  ,
  output  reg                       dec_pool_decrapated         =0  ,
  output  reg                       dec_ddr_save_need_sync      =0  ,//19
  output  reg                       dec_ddr_wdes                =0  ,
  output  reg     [  2 : 0]         dec_ddr_wstart_trig         =0  ,
  output  reg     [  6 : 0]         dec_pool_blk_ysize          =0  ,
  output  reg     [  6 : 0]         dec_pool_blk_xsize          =0  ,
  output  reg                       dec_res_en                  =0  ,
  output  reg                       dec_ups_en                  =0  , 
  output  reg                       dec_act_en                  =0  ,  
  output  reg                       dec_pool_en                 =0  ,   
  output  reg                       dec_pad_en                  =0  ,  
  output  reg     [ 24 : 0]         dec_ddr_wfm_offset          =0  ,//20  
  output  reg     [ 24 : 0]         dec_ddr_rins_offset         =0  ,//21  
  output  reg                       dec_network_done            =0  ,//22
  output  reg     [  7 : 0]         dec_output_blk_ysize        =0  ,//23
  output  reg     [  7 : 0]         dec_output_blk_xsize        =0  ,
  output  reg     [ 63 : 0]         dec_ddr_wmask               =0  ,//24,25,26
  output  reg     [  2 : 0]         dec_pool_padding_l          =0  ,//27
  output  reg     [  2 : 0]         dec_pool_padding_r          =0  ,
  output  reg     [  2 : 0]         dec_pool_padding_u          =0  ,
  output  reg     [  2 : 0]         dec_pool_padding_d          =0  ,
  output  reg     [  6 : 0]         dec_ddr_rblk_ysize          =0  ,//28
  output  reg     [  6 : 0]         dec_ddr_rblk_xsize          =0  ,
  output  reg     [  7 : 0]         dec_avg_pool_param          =0  ,//29
  output  reg     [  6 : 0]         dec_ddr_wblk_ysize          =0  ,
  output  reg     [  6 : 0]         dec_ddr_wblk_xsize          =0  ,
  output  reg                       dec_default_flag            =0  ,//30  
  output  reg     [  6 : 0]         dec_out_ymax                =0  ,
  output  reg     [  3 : 0]         dec_out_ymin                =0  ,
  output  reg     [  6 : 0]         dec_out_xmax                =0  ,
  output  reg     [  3 : 0]         dec_out_xmin                =0  ,
  output  reg     [  6 : 0]         dec_out_ys                  =0  ,//31
  output  reg     [  6 : 0]         dec_out_xs                  =0  , 
  output  reg     [  2 : 0]         dec_se_stage                =0  ,//32
  output  reg     [  2 : 0]         dec_se_fc_in_num            =0  ,
  output  reg     [  7 : 0]         dec_se_fc_out_num           =0  , 
  output  reg     [ 24 : 0]         dec_ddr_rparam_offset       =0  ,//33
  output  reg     [ 14 : 0]         dec_ddr_rparam_num          =0  ,//34
  output  reg     [ 14 : 0]         dec_ofm_rbase               =0  ,//35
  output  reg     [ 14 : 0]         dec_ofm_wbase               =0  ,
  output  reg     [  1 : 0]         dec_param_bank_id           =0  ,//36
  output  reg                       dec_add_zero                =0  ,           
  output  reg     [  3 : 0]         dec_ddr_wpos                =0  ,//37        
  output  reg     [ 11 : 0]         dec_nvm_xnum                =0  ,//38
  output  reg     [ 11 : 0]         dec_nvm_ynum                =0  ,
  output  reg     [ 11 : 0]         dec_nvm_gnum                =0  ,//39
  output  reg     [ 11 : 0]         dec_nvm_bnum                =0  ,
  output  reg                       dec_nvm_idir                =0  ,//40
  output  reg     [  5 : 0]         dec_nvm_inum                =0  ,
  output  reg                       dec_nvm_odir                =0  ,
  output  reg     [  5 : 0]         dec_nvm_onum                =0  , 
  output  reg     [  3 : 0]         dec_high_addr_ini_ddr_param =0  ,//41
  output  reg     [  3 : 0]         dec_high_addr_ini_ddr_ins   =0  ,
  output  reg     [  3 : 0]         dec_high_addr_ini_fm_output =0  ,
  output  reg     [  3 : 0]         dec_high_addr_ini_ddr_bias  =0  ,
  output  reg     [  3 : 0]         dec_high_addr_ini_ddr_fm    =0  ,
  output  reg     [  3 : 0]         dec_high_addr_ini_ddr_ker   =0  ,
  output  reg     [14  : 0]         dec_ddr_sparse_mask_rnum    =0  ,//42
  output  reg                       dec_ddr_sparse_mask_enable  =0  ,

  input           [ 31 : 0]         inst_round                      ,
  input           [ 31 : 0]         inst_rdata                      ,
  input           [ 63 : 0]         inst_rvld                       ,

  input                             clk                             ,
  input                             reset                   
);


//-----------------------------------------------------------
//*******decode instructions, from opcode 0 to end **********
//-----------------------------------------------------------
  always @(posedge clk)
  if ( inst_rvld[0] &(inst_rdata[5:0] == 0) ) 
  begin
      dec_dw_flag               <=  inst_rdata[20]                  ;
      dec_ifm_w                 <=  inst_rdata[19:13]               ;
      dec_ifm_h                 <=  inst_rdata[12:6]                ;
  end


  always @(posedge clk)
  if ( inst_rvld[1] &(inst_rdata[5:0] == 1) ) 
  begin
      dec_fm_in_ysize           <=  inst_rdata[25:16]               ;
      dec_fm_in_xsize           <=  inst_rdata[15:6]                ;
  end


  always @(posedge clk)
  if ( inst_rvld[2] &(inst_rdata[5:0] == 2) ) 
  begin
      dec_cout                  <=  inst_rdata[27:17]               ;
      dec_cin                   <=  inst_rdata[16:6]                ;
  end


  always @(posedge clk) 
  if ( inst_rvld[3] &(inst_rdata[5:0] == 3) )
  begin
      dec_ddr_rfm_offset        <=  inst_rdata[30:6]                ;
  end

  always @(posedge clk) 
  if ( inst_rvld[4] &(inst_rdata[5:0] == 4) )
  begin
      dec_ddr_rker_offset       <=  inst_rdata[30:6]                ;
  end
  
  always @(posedge clk) 
  if ( inst_rvld[5] &(inst_rdata[5:0] == 5) )
  begin
      dec_ddr_rbias_offset      <=  inst_rdata[30:6]                ;
  end

  always @(posedge clk) 
  if ( inst_rvld[6] &(inst_rdata[5:0] == 6) )
  begin
      dec_ddr_rres_offset       <=  inst_rdata[30:6]                ;
  end


  always @(posedge clk) 
  if ( inst_rvld[7] &(inst_rdata[5:0] == 7) )
  begin
      dec_ddr_rfm_num           <=  inst_rdata[20:6]                ;
  end
  
  always @(posedge clk) 
  if ( inst_rvld[8] &(inst_rdata[5:0] == 8) )
  begin
      dec_ddr_rker_num          <=  inst_rdata[20:6]                ;
  end

  always @(posedge clk) 
  if ( inst_rvld[9] &(inst_rdata[5:0] == 9) )
  begin
      dec_ddr_rbias_num         <=  inst_rdata[20:6]                ;
  end

  always @(posedge clk) 
  if ( inst_rvld[10] &(inst_rdata[5:0] == 10) )
  begin
      dec_ddr_wfm_num           <=  inst_rdata[20:6]                ;
  end

  always @(posedge clk)
  if (inst_rvld[11] & (inst_rdata[5:0] == 11) ) 
  begin
      dec_ddr_rsingle           <=  inst_rdata[30]                  ;
      dec_ker_on_board          <=  inst_rdata[29:24]               ;
      dec_ddr_rstart_trig       <=  inst_rdata[23:21]               ;
      dec_ddr_rstart_dma_num    <=  inst_rdata[20:12]               ;
      dec_ddr_rtype             <=  inst_rdata[11:6]                ;
  end
 

  always @(posedge clk)
  if (inst_rvld[12] & (inst_rdata[5:0] == 12) ) 
  begin
      dec_ifm_rstart_trig       <=  inst_rdata[30:28]               ;
      dec_ifm_wmax              <=  inst_rdata[27:21]               ;
      dec_ifm_wmin              <=  inst_rdata[20:17]               ;
      dec_ifm_hmax              <=  inst_rdata[16:10]               ;
      dec_ifm_hmin              <=  inst_rdata[9:6]                 ;
  end
  

  always @(posedge clk) 
  if (inst_rvld[13] & (inst_rdata[5:0] == 13) ) 
  begin
      dec_ker_ysize             <=  inst_rdata[24:21]               ;
      dec_ker_xsize             <=  inst_rdata[20:17]               ;
      dec_ifm_ws                <=  inst_rdata[16:14]               ;
      dec_ifm_hs                <=  inst_rdata[13:11]               ;
      dec_ker_repeat            <=  inst_rdata[10:6]                ;
  end

  always @(posedge clk)
  if (inst_rvld[14] & (inst_rdata[5:0] == 14) ) 
  begin
      dec_layer_type            <=  inst_rdata[17:15]               ;
    //dec_ifm_rkeep             <=  inst_rdata[14:9]- 6'd1          ;
      dec_ifm_rkeep             <=  6'd0                            ;
      dec_pe_output_num         <=  inst_rdata[8:6]                 ;
    //dec_pe_output_num         <=  inst_rdata[8:6]+1               ;
  end


  always @(posedge clk)
  if (inst_rvld[15] & (inst_rdata[5:0] == 15) ) 
  begin
      dec_ifm_rsel              <=  inst_rdata[29:28]               ;
      dec_ker_repeat_last       <=  inst_rdata[27:23]               ;
      dec_dma_shift             <=  inst_rdata[22:19]               ;
      dec_dma_shift_dir         <=  inst_rdata[18]                  ;
      dec_ker_eaddr             <=  inst_rdata[17:12]               ;
      dec_ker_saddr             <=  inst_rdata[11:6]                ;
  end

  always @(posedge clk)
  if (inst_rvld[16] & (inst_rdata[5:0] == 16) ) 
  begin
      dec_ofm_concat_num        <=  inst_rdata[30:24]               ;
      dec_output_final_blk      <=  inst_rdata[23]                  ;
      dec_final_output          <=  inst_rdata[22]                  ;
      dec_ofm_tmp_sel           <=  inst_rdata[21]                  ;
      dec_bias_sel              <=  inst_rdata[20]                  ;
      dec_bias_snum             <=  inst_rdata[19:10]               ;
      dec_ofm_rstart_trig       <=  inst_rdata[9:6]                 ;
  end

  always @(posedge clk)
  if ( inst_rvld[17] & (inst_rdata[5:0] == 17) ) 
  begin
      dec_ofm_snum              <=  inst_rdata[30:26]               ;
      dec_fm_out_ysize          <=  inst_rdata[25:16]               ;
      dec_fm_out_xsize          <=  inst_rdata[15:6]                ;
  end

  always @(posedge clk)
  if ( inst_rvld[18] &(inst_rdata[5:0] == 18) ) 
  begin
      dec_ddr_wsel              <=  inst_rdata[30]                  ;
      dec_padding_size          <=  inst_rdata[29:27]               ;
      dec_act_type              <=  inst_rdata[26:23]               ;
      dec_pool_ys               <=  inst_rdata[22:20]               ;
      dec_pool_xs               <=  inst_rdata[19:17]               ;
      dec_pool_type             <=  inst_rdata[16:15]               ;
      dec_pool_ysize            <=  inst_rdata[14:11]               ;
      dec_pool_xsize            <=  inst_rdata[10:7]                ;
      dec_pool_decrapated       <=  inst_rdata[6]                   ;
  end

  always @(posedge clk)
  if ( inst_rvld[19] &(inst_rdata[5:0] == 19) ) 
  begin
      dec_ddr_save_need_sync    <=  inst_rdata[29]                  ;
      dec_ddr_wdes              <=  inst_rdata[28]                  ;
      dec_ddr_wstart_trig       <=  inst_rdata[27:25]               ;
      dec_pool_blk_ysize        <=  inst_rdata[24:18]               ;
      dec_pool_blk_xsize        <=  inst_rdata[17:11]               ;
      dec_res_en                <=  inst_rdata[10]                  ;
      dec_ups_en                <=  inst_rdata[9]                   ;
      dec_act_en                <=  inst_rdata[8]                   ;
      dec_pool_en               <=  inst_rdata[7]                   ;
      dec_pad_en                <=  inst_rdata[6]                   ;
  end

  always @(posedge clk)
  if ( inst_rvld[20] & (inst_rdata[5:0] == 20) )
  begin
      dec_ddr_wfm_offset        <=  inst_rdata[30:6]                ;
  end

  always @(posedge clk) 
  if ( inst_rvld[21] &(inst_rdata[5:0] == 21) )
  begin
      dec_ddr_rins_offset       <=  inst_rdata[30:6]                ;
  end

  always @(posedge clk) 
  if ( inst_rvld[22] & (inst_rdata[5:0] == 22) )
  begin
      dec_network_done          <=  inst_rdata[6]                   ;
  end

  always @(posedge clk)
  if (inst_rvld[23] & (inst_rdata[5:0] == 23) ) 
  begin
      dec_output_blk_ysize      <=  inst_rdata[19:13]               ;
      dec_output_blk_xsize      <=  inst_rdata[12:6]                ;
  end

  always @(posedge clk)
  if ( inst_rvld[24] & (inst_rdata[5:0] == 24) )
  begin
      dec_ddr_wmask[63:50]      <=  inst_rdata[30:17]               ;
  end

  always @(posedge clk)
  if ( inst_rvld[25] & (inst_rdata[5:0] == 25) )
  begin
      dec_ddr_wmask[49:25]      <=  inst_rdata[30:6]                ;
  end

  always @(posedge clk)
  if ( inst_rvld[26] & (inst_rdata[5:0] == 26) )
  begin
      dec_ddr_wmask[24:0]       <=  inst_rdata[30:6]                ;
  end

  always @(posedge clk)
  if (inst_rvld[27] & (inst_rdata[5:0] == 27) ) 
  begin
      dec_pool_padding_l        <=  inst_rdata[17:15]               ;
      dec_pool_padding_r        <=  inst_rdata[14:12]               ;
      dec_pool_padding_u        <=  inst_rdata[11:9]                ;
      dec_pool_padding_d        <=  inst_rdata[8:6]                 ;
  end

  always @(posedge clk)
  if (inst_rvld[28] & (inst_rdata[5:0] == 28) ) 
  begin
      dec_ddr_rblk_ysize        <=  inst_rdata[19:13]               ;
      dec_ddr_rblk_xsize        <=  inst_rdata[12:6]                ;
  end

  always @(posedge clk)
  if (inst_rvld[29] & (inst_rdata[5:0] == 29) ) 
  begin
      dec_avg_pool_param        <=  inst_rdata[27:20]               ;
      dec_ddr_wblk_ysize        <=  inst_rdata[19:13]               ;
      dec_ddr_wblk_xsize        <=  inst_rdata[12:6]                ;
  end

  always @(posedge clk)
  if (inst_rvld[30] & (inst_rdata[5:0] == 30) ) 
  begin
      dec_default_flag          <=  inst_rdata[28]                  ;
      dec_out_ymax              <=  inst_rdata[27:21]               ;
      dec_out_ymin              <=  inst_rdata[20:17]               ;
      dec_out_xmax              <=  inst_rdata[16:10]               ;
      dec_out_xmin              <=  inst_rdata[9:6]                 ;
  end

  always @(posedge clk)
  if (inst_rvld[31] & (inst_rdata[5:0] == 31) ) 
  begin
      dec_out_ys                <=  inst_rdata[19:13]               ;
      dec_out_xs                <=  inst_rdata[12:6]                ;
  end

  always @(posedge clk)
  if (inst_rvld[32] & (inst_rdata[5:0] == 32) ) 
  begin
      dec_se_stage              <=  inst_rdata[19:17]               ;
      dec_se_fc_in_num          <=  inst_rdata[16:14]               ;
      dec_se_fc_out_num         <=  inst_rdata[13:6]                ;
  end

  always @(posedge clk) 
  if ( inst_rvld[33] &(inst_rdata[5:0] == 33) )
  begin
      dec_ddr_rparam_offset     <=  inst_rdata[30:6]                ;
  end

  always @(posedge clk) 
  if ( inst_rvld[34] &(inst_rdata[5:0] == 34) )
  begin
      dec_ddr_rparam_num        <=  inst_rdata[20:6]                ;
  end
  

  always @(posedge clk)
  if (inst_rvld[35] & (inst_rdata[5:0] == 35) ) 
  begin
      dec_ofm_rbase             <=  inst_rdata[20:6]                ;
      dec_ofm_wbase             <=  inst_rdata[20:6]                ;
  end
  
  always @(posedge clk)
  if (inst_rvld[36] & (inst_rdata[5:0] == 36) ) 
  begin
      dec_param_bank_id         <=  inst_rdata[8:7]                 ;
      dec_add_zero              <=  inst_rdata[6]                   ;
  end

  always @(posedge clk)
  if (inst_rvld[37] & (inst_rdata[5:0] == 37) ) 
  begin
      dec_ddr_wpos              <=  inst_rdata[9:6]                 ;
  end

  always @(posedge clk)
  if (inst_rvld[38] & (inst_rdata[5:0] == 38) ) 
  begin
      dec_nvm_xnum              <=  inst_rdata[29:18]               ;
      dec_nvm_ynum              <=  inst_rdata[17:6]                ;
  end

  always @(posedge clk)
  if (inst_rvld[39] & (inst_rdata[5:0] == 39) ) 
  begin
      dec_nvm_gnum              <=  inst_rdata[29:18]               ;
      dec_nvm_bnum              <=  inst_rdata[17:6]                ;
  end

  always @(posedge clk)
  if (inst_rvld[40] & (inst_rdata[5:0] == 40) ) 
  begin
      dec_nvm_idir              <=  inst_rdata[6]                   ;
      dec_nvm_inum              <=  inst_rdata[11:7]                ;
      dec_nvm_odir              <=  inst_rdata[12]                  ;
      dec_nvm_onum              <=  inst_rdata[17:13]               ;
  end

  always @(posedge clk)
  if ( inst_rvld[41] &(inst_rdata[5:0] == 41) ) 
  begin
      dec_high_addr_ini_ddr_param<= inst_rdata[29:26]               ;
      dec_high_addr_ini_ddr_ins  <= inst_rdata[25:22]               ;
      dec_high_addr_ini_fm_output<= inst_rdata[21:18]               ;
      dec_high_addr_ini_ddr_bias <= inst_rdata[17:14]               ;
      dec_high_addr_ini_ddr_fm   <= inst_rdata[9 : 6]               ;
      dec_high_addr_ini_ddr_ker  <= inst_rdata[13:10]               ;
  end

  always @(posedge clk)
  if ( inst_rvld[42] &(inst_rdata[5:0] == 42) ) 
  begin
      dec_ddr_sparse_mask_rnum  <=  inst_rdata[21:7]                ;
      dec_ddr_sparse_mask_enable<=  inst_rdata[6:6]                 ;
  end



endmodule
