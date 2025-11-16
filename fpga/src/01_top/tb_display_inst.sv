`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/13/2023 09:56:44 AM
// Design Name: 
// Module Name: point
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: You can check the size of the fixed point number. 
//              And I will help you save the data.
//              Note that this is a circuit that cannot be integrated. 
//              Just for your convenience in debugging
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 1.0            2023-09-11  Shaoqiang     Functional simulation testing,
//                                         implementation on FPGA of U200.
//////////////////////////////////////////////////////////////////////////////////

module tb_display_inst#(
    parameter     FILE0  =  "/home/lsq/Desktop/opu/rtl/src/12_data/",
    parameter     FILE1  =  "_debug_inst_dec.txt",
    parameter     IDW    =  32      
)(
    input                   clk     ,
    input                   reset   ,
    input                   wvld    ,
    input       [IDW-1:0]   wdata   
);

  //-----------------------------------------------------------
  //Record the translation results of instructions
  //-----------------------------------------------------------

  integer file;
  initial file = $fopen({FILE0,FILE1},"w");
  reg [16-1:0] cnt=0;
  
  always @(posedge clk)
  if(wvld)
  begin
             cnt<=cnt+1;
  case(wdata[5:0])
     0:begin $display(  "%d[0][20:20]dw_flag(%d) [6:12]ifm_h(%d) [13:19]ifm_w(%d)",cnt,wdata[20],   wdata[12:6],wdata[19:13]);
             $fwrite(file,"[0][20:20]dw_flag(%d) [6:12]ifm_h(%d) [13:19]ifm_w(%d)\n",  wdata[20],   wdata[12:6],wdata[19:13]);end
     1:begin $display(  "%d[1][16:25]fm_in_xsize(%d) [6:15]fm_in_ysize(%d)",cnt,       wdata[25:16],wdata[15:6]);
             $fwrite(file,"[1][16:25]fm_in_xsize(%d) [6:15]fm_in_ysize(%d)\n",         wdata[25:16],wdata[15:6]);end
     2:begin $display(  "%d[2][17:27]cout(%d) [6:16]cin(%d)",cnt,                      wdata[27:17],$signed(wdata[16:6])+$signed(-1));
             $fwrite(file,"[2][17:27]cout(%d) [6:16]cin(%d)\n",                        wdata[27:17],$signed(wdata[16:6])+$signed(-1));end
     3:begin $display(  "%d[3][6:30]ddr_rfm_offset(%d)",cnt,  wdata[30:6]);
             $fwrite(file,"[3][6:30]ddr_rfm_offset(%d)\n",    wdata[30:6]);end
     4:begin $display(  "%d[4][6:30]ddr_rker_offset(%d)",cnt, wdata[30:6]);
             $fwrite(file,"[4][6:30]ddr_rker_offset(%d)\n",   wdata[30:6]);end
     5:begin $display(  "%d[5][6:30]ddr_rbias_offset(%d)",cnt,wdata[30:6]);
             $fwrite(file,"[5][6:30]ddr_rbias_offset(%d)\n",  wdata[30:6]);end
     6:begin $display(  "%d[6][6:30]ddr_rres_offset(%d)",cnt, wdata[30:6]);
             $fwrite(file,"[6][6:30]ddr_rres_offset(%d)\n",   wdata[30:6]);end
     7:begin $display(  "%d[7][6:20]ddr_rfm_num(%d)",cnt,     wdata[20:6]);
             $fwrite(file,"[7][6:20]ddr_rfm_num(%d)\n",       wdata[20:6]);end
     8:begin $display(  "%d[8][6:20]ddr_rker_num(%d)",cnt,    wdata[20:6]);
             $fwrite(file,"[8][6:20]ddr_rker_num(%d)\n",      wdata[20:6]);end
     9:begin $display(  "%d[9][6:20]ddr_rbias_num(%d)",cnt,   wdata[20:6]);
             $fwrite(file,"[9][6:20]ddr_rbias_num(%d)\n",     wdata[20:6]);end
    10:begin $display(  "%d[10][6:20]ddr_wfm_num(%d)",cnt,    wdata[20:6]);
             $fwrite(file,"[10][6:20]ddr_wfm_num(%d)\n",      wdata[20:6]);end
    11:begin $display(  "%d[11][30:30]ddr_rsingle(%d) [24:29]ker_on_board(%d) [21:23]ddr_rstart_trig(%d) [6:11]ddr_rtype(%d) [12:20]ddr_rstart_dma_num(%d)",cnt,wdata[30],$signed(wdata[29:24])+$signed(-1),wdata[23:21],wdata[11:6],wdata[20:12]);//
             $fwrite(file,"[11][30:30]ddr_rsingle(%d) [24:29]ker_on_board(%d) [21:23]ddr_rstart_trig(%d) [6:11]ddr_rtype(%d) [12:20]ddr_rstart_dma_num(%d)\n",  wdata[30],$signed(wdata[29:24])+$signed(-1),wdata[23:21],wdata[11:6],wdata[20:12]);end
    12:begin $display(  "%d[12][28:30]ifm_rstart_trig(%d) [21:27]ifm_wmax(%d) [17:20]ifm_wmin(%d) [6:9]ifm_hmin(%d) [10:16]ifm_hmax(%d)",cnt,                   wdata[30:28],     wdata[27:21],             wdata[20:17],wdata[9 :6],wdata[16:10]);
             $fwrite(file,"[12][28:30]ifm_rstart_trig(%d) [21:27]ifm_wmax(%d) [17:20]ifm_wmin(%d) [6:9]ifm_hmin(%d) [10:16]ifm_hmax(%d)\n",                     wdata[30:28],     wdata[27:21],             wdata[20:17],wdata[9 :6],wdata[16:10]);end
    13:begin $display(  "%d[13][21:24]ker_ysize(%d) [17:20]ker_xsize(%d) [14:16]ifm_ws(%d) [6:10]ifm_hs(%d) [11:13]ker_repeat(%d)",cnt,                         wdata[24:21],     wdata[20:17],             wdata[16:14],    $signed(wdata[10:6])+$signed(-1),wdata[13:11]);
             $fwrite(file,"[13][21:24]ker_ysize(%d) [17:20]ker_xsize(%d) [14:16]ifm_ws(%d) [6:10]ifm_hs(%d) [11:13]ker_repeat(%d)\n",                           wdata[24:21],     wdata[20:17],             wdata[16:14],    $signed(wdata[10:6])+$signed(-1),wdata[13:11]);end
    14:begin $display(  "%d[14][15:17]layer_type(%d) [6:8]pe_output_num(%d) [9:14]ifm_rkeep(%d)",cnt,                                                           wdata[17:15],     wdata[8 :6 ],             wdata[14:9]);
             $fwrite(file,"[14][15:17]layer_type(%d) [6:8]pe_output_num(%d) [9:14]ifm_rkeep(%d)\n",                                                             wdata[17:15],     wdata[8 :6 ],             wdata[14:9]);end
    15:begin $display(  "%d[15][28:29]ifm_rsel(%d) [23:27]ker_repeat_last(%d) [19:22]dma_shift(%d) [18:18]dma_shift_dir(%d) [6:11]ker_saddr(%d) [12:17]ker_eaddr(%d)",cnt,        wdata[29:28],     $signed(wdata[27:23])+$signed(-1),$signed(wdata[22:19])+$signed(-1),$signed(wdata[18:18])+$signed(-1),wdata[11:6],wdata[17:12]);
             $fwrite(file,"[15][28:29]ifm_rsel(%d) [23:27]ker_repeat_last(%d) [19:22]dma_shift(%d) [18:18]dma_shift_dir(%d) [6:11]ker_saddr(%d) [12:17]ker_eaddr(%d)\n",          wdata[29:28],     $signed(wdata[27:23])+$signed(-1),$signed(wdata[22:19])+$signed(-1),$signed(wdata[18:18])+$signed(-1),wdata[11:6],wdata[17:12]);end
    16:begin $display(  "%d[16][24:30]ofm_concat_num(%d) [10:19]bias_snum(%d) [6:9]ofm_start_trig(%d) [20:20]bias_sel(%d) [21:21]ofm_tmp_sel(%d) [22:22]final_output(%d) [23:23]output_final_blk(%d)",cnt,  wdata[30:24],wdata[19:10],        wdata[9:6],   wdata[20],wdata[21],wdata[22],    $signed(    wdata[23:23])+$signed(-1));
             $fwrite(file,"[16][24:30]ofm_concat_num(%d) [10:19]bias_snum(%d) [6:9]ofm_start_trig(%d) [20:20]bias_sel(%d) [21:21]ofm_tmp_sel(%d) [22:22]final_output(%d) [23:23]output_final_blk(%d)\n",    wdata[30:24],wdata[19:10],        wdata[9:6],   wdata[20],wdata[21],wdata[22],    $signed(    wdata[23:23])+$signed(-1));end
    17:begin $display(  "%d[17][26:30]ofm_snum(%d) [6:15]fm_out_xsize(%d) [16:25]fm_out_ysize(%d)",cnt,                                                                                                     wdata[30:26],wdata[15: 6],        wdata[25:16]);                       
             $fwrite(file,"[17][26:30]ofm_snum(%d) [6:15]fm_out_xsize(%d) [16:25]fm_out_ysize(%d)\n",                                                                                                       wdata[30:26],wdata[15: 6],        wdata[25:16]);end                                  
    18:begin $display(  "%d[18][30:30]ddr_wsel(%d) [27:29]padding_size(%d) [23:26]act_type(%d) [7:10]pool_xsize(%d) [6:6]pool_decrapated(%d) [11:14]pool_ysize(%d) [15:16]pool_type(%d) [17:19]pool_xs(%d) [20:22]pool_ys(%d)",cnt,   $signed(wdata[30:30])+$signed(-1),$signed(wdata[29:27])+$signed(-1),wdata[26:23],wdata[10:7],$signed(wdata[6:6])+$signed(-1),   wdata[14:11],wdata[16:15],wdata[19:17],wdata[22:20]); 
             $fwrite(file,"[18][30:30]ddr_wsel(%d) [27:29]padding_size(%d) [23:26]act_type(%d) [7:10]pool_xsize(%d) [6:6]pool_decrapated(%d) [11:14]pool_ysize(%d) [15:16]pool_type(%d) [17:19]pool_xs(%d) [20:22]pool_ys(%d)\n",     $signed(wdata[30:30])+$signed(-1),$signed(wdata[29:27])+$signed(-1),wdata[26:23],wdata[10:7],$signed(wdata[6:6])+$signed(-1),   wdata[14:11],wdata[16:15],wdata[19:17],wdata[22:20]);end 
    19:begin $display(  "%d[19][25:27]ddr_wstart_trig(%d) [28:28]ddr_wdes(%d) [18:24]pool_blk_ysize(%d) [7:7]pool_en(%d) [6:6]pad_en(%d) [8:8]act_en(%d) [9:9]ups_en(%d) [10:10]res_en(%d) [11:17]pool_blk_xsize(%d)",cnt,                    wdata[27:25],wdata[28],   $signed(wdata[24:18])+$signed(-1),wdata[7],    wdata[6],wdata[8],  wdata[9],wdata[10],$signed(wdata[17:11])+$signed(-1));    
             $fwrite(file,"[19][25:27]ddr_wstart_trig(%d) [28:28]ddr_wdes(%d) [18:24]pool_blk_ysize(%d) [7:7]pool_en(%d) [6:6]pad_en(%d) [8:8]act_en(%d) [9:9]ups_en(%d) [10:10]res_en(%d) [11:17]pool_blk_xsize(%d)\n",                      wdata[27:25],wdata[28],   $signed(wdata[24:18])+$signed(-1),wdata[7],    wdata[6],wdata[8],  wdata[9],wdata[10],$signed(wdata[17:11])+$signed(-1));end   
    20:begin $display(  "%d[20][6:30]ddr_wfm_offset(%d)",cnt,   wdata[30:6]);
             $fwrite(file,"[20][6:30]ddr_wfm_offset(%d)\n",     wdata[30:6]);end
    21:begin $display(  "%d[21][6:30]ddr_rins_offset(%d)",cnt,  wdata[30:6]); 
             $fwrite(file,"[21][6:30]ddr_rins_offset(%d)\n",    wdata[30:6]);end 
    22:begin $display(  "%d[22][6:6]network_done(%d)",cnt,      wdata[6]); 
             $fwrite(file,"[22][6:6]network_done(%d)\n",        wdata[6]);end                                                                          
    23:begin $display(  "%d[23][13:19]output_blk_ysize(%d) [6:12]output_blk_xsize(%d)",cnt, wdata[19:13],wdata[12:6]); 
             $fwrite(file,"[23][13:19]output_blk_ysize(%d) [6:12]output_blk_xsize(%d)\n",   wdata[19:13],wdata[12:6]);end 
    24:begin $display(  "%d[24][17:30]ddr_wmask[63:50](%d)",cnt,wdata[30:17]);            
             $fwrite(file,"[24][17:30]ddr_wmask[63:50](%d)\n",  wdata[30:17]);end        
    25:begin $display(  "%d[25][6:30]ddr_wmask[49:25](%d)",cnt, wdata[30:6]);             
             $fwrite(file,"[25][6:30]ddr_wmask[49:25](%d)\n",   wdata[30:6]);end     
    26:begin $display(  "%d[26][6:30]ddr_wmask[24:0](%d)",cnt,  wdata[30:6]);         
             $fwrite(file,"[26][6:30]ddr_wmask[24:0](%d)\n",    wdata[30:6]);end                                     
    27:begin $display(  "%d[27][15:17]pool_padding_l(%d) [12:14]pool_padding_r(%d) [9:11]pool_padding_u(%d) [6:8]pool_padding_d(%d)",cnt,    wdata[17:15],wdata[14:12],wdata[11:9],wdata[8:6]);
             $fwrite(file,"[27][15:17]pool_padding_l(%d) [12:14]pool_padding_r(%d) [9:11]pool_padding_u(%d) [6:8]pool_padding_d(%d)\n",      wdata[17:15],wdata[14:12],wdata[11:9],wdata[8:6]);end
    28:begin $display(  "%d[28][13:19]ddr_rblk_xsize(%d) [6:12]ddr_rblk_ysize(%d)",cnt,                                                      wdata[19:13],wdata[12:6]);                         
             $fwrite(file,"[28][13:19]ddr_rblk_xsize(%d) [6:12]ddr_rblk_ysize(%d)\n",                                                        wdata[19:13],wdata[12:6]);end        
    29:begin $display(  "%d[29][20:27]avg_pool_param(%d) [6:12]ddr_wblk_xsize(%d) [13:19]ddr_wblk_ysize(%d)",cnt,                    $signed(wdata[27:20])+$signed(-1),wdata[12: 6],wdata[19:13]);       
             $fwrite(file,"[29][20:27]avg_pool_param(%d) [6:12]ddr_wblk_xsize(%d) [13:19]ddr_wblk_ysize(%d)\n",                      $signed(wdata[27:20])+$signed(-1),wdata[12: 6],wdata[19:13]);end          
    30:begin $display(  "%d[30][28:28]default_flag(%d) [21:27]out_ymax(%d) [17:20]out_ymin(%d) [10:16]out_xmax(%d) [6:9]out_xmin(%d)",cnt,   wdata[28],   wdata[27:21],wdata[20:17],wdata[16:10],wdata[9:6]);    
             $fwrite(file,"[30][28:28]default_flag(%d) [21:27]out_ymax(%d) [17:20]out_ymin(%d) [10:16]out_xmax(%d) [6:9]out_xmin(%d)\n",     wdata[28],   wdata[27:21],wdata[20:17],wdata[16:10],wdata[9:6]);end          
    31:begin $display(  "%d[31][13:19]out_ys(%d) [6:12]out_xs(%d)",cnt,                                          wdata[19:13],wdata[12:6]);                                  
             $fwrite(file,"[31][13:19]out_ys(%d) [6:12]out_xs(%d)\n",                                            wdata[19:13],wdata[12:6]);end                
    32:begin $display(  "%d[32][17:19]se_stage(%d) [14:16]se_fc_in_num(%d) [6:13]se_fc_out_num(%d)",cnt,         wdata[19:17],wdata[16:14],wdata[13:6]);
             $fwrite(file,"[32][17:19]se_stage(%d) [14:16]se_fc_in_num(%d) [6:13]se_fc_out_num(%d)\n",           wdata[19:17],wdata[16:14],wdata[13:6]);end
    33:begin $display(  "%d[33][6:30]ddr_rparam_offset(%d)",cnt,              wdata[30:6]);
             $fwrite(file,"[33][6:30]ddr_rparam_offset(%d)\n",                wdata[30:6]);end
    34:begin $display(  "%d[34][6:20]ddr_rparam_num(%d)",cnt,                 wdata[20:6]);
             $fwrite(file,"[34][6:20]ddr_rparam_num(%d)\n",                   wdata[20:6]);end
    35:begin $display(  "%d[35][6:20]ofm_rbase(%d) [6:20]ofm_wbase(%d)",cnt,  wdata[20:6],wdata[20:6]);      
             $fwrite(file,"[35][6:20]ofm_rbase(%d) [6:20]ofm_wbase(%d)\n",    wdata[20:6],wdata[20:6]);end            
    36:begin $display(  "%d[36][7:8]param_bank_id(%d) [6:6]add_zero(%d)",cnt, wdata[8 :7],wdata[6]);      
             $fwrite(file,"[36][7:8]param_bank_id(%d) [6:6]add_zero(%d)\n",   wdata[8 :7],wdata[6]);end        
    37:begin $display(  "%d[37][6:9]ddr_wpos(%d)",cnt,                        wdata[9 :6]);              
             $fwrite(file,"[37][6:9]ddr_wpos(%d)\n",                          wdata[9 :6]);end               
    38:begin $display(  "%d[38][18:29]nvm_xnum(%d) [6:17]nvm_ynum(%d)",cnt,   wdata[29:18],wdata[17:6]);       
             $fwrite(file,"[38][18:29]nvm_xnum(%d) [6:17]nvm_ynum(%d)\n",     wdata[29:18],wdata[17:6]);end            
    39:begin $display(  "%d[39][18:29]nvm_gnum(%d) [6:17]nvm_bnum(%d)",cnt,   wdata[29:18],wdata[17:6]);   
             $fwrite(file,"[39][18:29]nvm_gnum(%d) [6:17]nvm_bnum(%d)\n",     wdata[29:18],wdata[17:6]);end                 
    40:begin $display(  "%d[40][13:17]nvm_onum(%d) [12:12]nvm_odir(%d) [6:6]nvm_idir(%d) [7:11]nvm_inum(%d)",cnt,wdata[17:13],wdata[12],wdata[6],wdata[11:7]);
             $fwrite(file,"[40][13:17]nvm_onum(%d) [12:12]nvm_odir(%d) [6:6]nvm_idir(%d) [7:11]nvm_inum(%d)\n",  wdata[17:13],wdata[12],wdata[6],wdata[11:7]);end
    41:begin $display(  "%d[41][26:29]high_addr_ini_ddr_param(%d) [22:25]high_addr_ini_ddr_ins(%d) [18:21]high_addr_ini_fm_output(%d) [14:17]high_addr_ini_ddr_bias(%d) [6:9]high_addr_ini_ddr_fm(%d)[10:13]high_addr_ini_ddr_ker(%d)",cnt,wdata[29:26],wdata[25:22],wdata[21:18],wdata[17:14],wdata[9:6],wdata[13:10]);
             $fwrite(file,"[41][26:29]high_addr_ini_ddr_param(%d) [22:25]high_addr_ini_ddr_ins(%d) [18:21]high_addr_ini_fm_output(%d) [14:17]high_addr_ini_ddr_bias(%d) [6:9]high_addr_ini_ddr_fm(%d)[10:13]high_addr_ini_ddr_ker(%d)\n",  wdata[29:26],wdata[25:22],wdata[21:18],wdata[17:14],wdata[9:6],wdata[13:10]);end
    42:begin $display(  "%d[42][7:21]ddr_sparse_mask_read_num(%d) [6:6]sparse_model(%d)",cnt, wdata[21:7],wdata[6:6]);       
             $fwrite(file,"[42][7:21]ddr_sparse_mask_read_num(%d) [6:6]sparse_model(%d)\n",   wdata[21:7],wdata[6:6]);end   
  endcase
  end
  
  always @(negedge wvld)
  begin          $display(" ");
      if (~reset)$fwrite(file,"\n");
  end
  //-----------------------------------------------------------
  //For debugging, match each line of "rtl_ins_dec.txt"
  //-----------------------------------------------------------
  
  reg           wvld_r=0    ;
  reg [16-1:0]  txt_cnt =1  ;
  wire[6-1:0]   txt_opcode  ;
  
  always @(posedge clk)
  begin
    wvld_r<=wvld            ;
    if(wvld|wvld_r) txt_cnt<=txt_cnt+1;
  end
  
  assign txt_opcode=wvld?wdata[6-1:0]:0;
  

endmodule
