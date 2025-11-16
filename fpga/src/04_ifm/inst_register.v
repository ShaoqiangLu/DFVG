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
// -----------------------------------------------------------------------------

`include "opu_parameter.vh"

module inst_register 
(
  input           [  3 : 0]         dec_high_addr_ini_ddr_fm    ,//41
  input           [ 24 : 0]         dec_ddr_rfm_offset          ,//3
  input           [  9 : 0]         dec_fm_in_xsize             ,//1 
  input           [  9 : 0]         dec_fm_in_ysize             ,//1  
  input           [ 14 : 0]         dec_ddr_rfm_num             ,//7  
  input           [  3 : 0]         dec_high_addr_ini_ddr_ker   ,//41 
  input           [ 24 : 0]         dec_ddr_rker_offset         ,//4  
  input           [ 14 : 0]         dec_ddr_rker_num            ,//8  
  input                             dec_ddr_sparse_mask_enable  ,//42 
  input           [14  : 0]         dec_ddr_sparse_mask_rnum    ,//42
  input           [  3 : 0]         dec_high_addr_ini_ddr_bias  ,//41
  input           [ 24 : 0]         dec_ddr_rbias_offset        ,//5  
  input           [ 14 : 0]         dec_ddr_rbias_num           ,//9  
  input           [ 24 : 0]         dec_ddr_rres_offset         ,//6 
  input           [  6 : 0]         dec_ddr_rblk_ysize          ,//28
  input           [  6 : 0]         dec_ddr_rblk_xsize          ,//28 
  input           [  3 : 0]         dec_high_addr_ini_ddr_ins   ,//41     
  input           [ 24 : 0]         dec_ddr_rins_offset         ,//21 
  input           [  3 : 0]         dec_high_addr_ini_ddr_param ,//41  
  input           [ 24 : 0]         dec_ddr_rparam_offset       ,//33 
  input           [ 14 : 0]         dec_ddr_rparam_num          ,//34 
  input           [  5 : 0]         dec_ddr_rtype               ,//11
  input           [  1 : 0]         dec_param_bank_id           ,//36 
  input           [  3 : 0]         dec_high_addr_ini_fm_output ,//41  
  input           [ 24 : 0]         dec_ddr_wfm_offset          ,//20
  input           [  9 : 0]         dec_fm_out_xsize            ,//17 
  input           [  6 : 0]         dec_ddr_wblk_ysize          ,//29  
  input           [  6 : 0]         dec_ddr_wblk_xsize          ,//29  
   //
  output    reg   [  3 : 0]         ddr_high_addr_ini_ddr_fm=0  ,  
  output    reg   [ 24 : 0]         ddr_rfm_offset    =0        ,
  output    reg   [  9 : 0]         ddr_fm_in_xsize   =0        , 
  output    reg   [  9 : 0]         ddr_fm_in_ysize   =0        , 
  output    reg   [ 14 : 0]         ddr_rfm_num       =0        ,  
  output    reg   [  3 : 0]         ddr_high_addr_ini_ddr_ker=0 , 
  output    reg   [ 24 : 0]         ddr_rker_offset   =0        ,
  output    reg   [ 14 : 0]         ddr_rker_num      =0        ,
  output    reg                     ddr_sparse_mask_enable=0    ,  
  output    reg   [ 14 : 0]         ddr_sparse_mask_rnum  =0    ,
  output    reg   [  3 : 0]         ddr_high_addr_ini_ddr_bias=0, 
  output    reg   [ 24 : 0]         ddr_rbias_offset  =0        ,
  output    reg   [ 14 : 0]         ddr_rbias_num     =0        ,
  output    reg   [ 24 : 0]         ddr_rres_offset   =0        , 
  output    reg   [  6 : 0]         ddr_rblk_ysize    =0        ,
  output    reg   [  6 : 0]         ddr_rblk_xsize    =0        ,  
  output    reg   [  3 : 0]         ddr_high_addr_ini_ddr_ins=0 ,   
  output    reg   [ 24 : 0]         ddr_rins_offset   =0        ,
  output    reg   [  3 : 0]         ddr_high_addr_ini_ddr_param=0,
  output    reg   [ 24 : 0]         ddr_rparam_offset =0        ,
  output    reg   [ 14 : 0]         ddr_rparam_num    =0        ,
  output    reg   [  6 : 0]         ddr_rtype         =0        , 
  output    reg   [  3 : 0]         ddr_high_addr_ini_fm_output=0, 
  output    reg   [ 24 : 0]         ddr_wfm_offset    =0        ,
  output    reg   [  9 : 0]         ddr_fm_out_xsize  =0        , 
  output    reg   [  6 : 0]         ddr_wblk_ysize    =0        ,    
  output    reg   [  6 : 0]         ddr_wblk_xsize    =0        ,  
  //--------------------------------------------------------------
  input           [  6 : 0]         dec_ifm_hmax                ,//12    
  input           [  3 : 0]         dec_ifm_hmin                ,//12    
  input           [  2 : 0]         dec_ifm_hs                  ,//13    
  input           [  6 : 0]         dec_ifm_h                   ,//0    
  input           [  6 : 0]         dec_ifm_wmax                ,//12    
  input           [  3 : 0]         dec_ifm_wmin                ,//12   
  input           [  2 : 0]         dec_ifm_ws                  ,//13    
  input           [  6 : 0]         dec_ifm_w                   ,//0    
  input           [  5 : 0]         dec_ifm_rkeep               ,//14    
  input           [  1 : 0]         dec_ifm_rsel                ,//15
  input           [  5 : 0]         dec_ker_eaddr               ,//15    
  input           [  5 : 0]         dec_ker_saddr               ,//15
  input           [  2 : 0]         dec_pe_output_num           ,//14    
  output    reg                     ifm_rstart        =0        ,
  output    reg   [  6 : 0]         ifm_hmax          =0        ,
  output    reg   [  3 : 0]         ifm_hmin          =0        ,
  output    reg   [  2 : 0]         ifm_hs            =0        ,
  output    reg   [  6 : 0]         ifm_h             =0        ,
  output    reg   [  6 : 0]         ifm_wmax          =0        ,
  output    reg   [  3 : 0]         ifm_wmin          =0        ,
  output    reg   [  2 : 0]         ifm_ws            =0        ,
  output    reg   [  6 : 0]         ifm_w             =0        ,
  output    reg   [  5 : 0]         ifm_rkeep         =0        ,
  output    reg   [  1 : 0]         ifm_rsel          =0        ,
  output    reg                     ifm_pp            =0        ,
  output    reg   [  5 : 0]         ker_eaddr         =0        ,
  output    reg   [  5 : 0]         ker_saddr         =0        ,
  output    reg                     ker_pp            =0        ,
  output    reg   [  2 : 0]         pe_output_num     =0        ,
  //--------------------------------------------------------------
  input                             dec_bias_sel                ,//16 
  input           [  9 : 0]         dec_bias_snum               ,//16 
  input           [  6 : 0]         dec_ofm_concat_num          ,//16
  input                             dec_ofm_tmp_sel             ,//16  
  input                             dec_final_output            ,//16  
  input           [  4 : 0]         dec_ofm_snum                ,//17
  input           [ 14 : 0]         dec_ofm_rbase               ,//35
  input           [ 14 : 0]         dec_ofm_wbase               ,//15  
  output    reg                     bias_pp          =0         , 
  output    reg   [  2 : 0]         ofm_din_enc      =0         ,
  output    reg                     ofm_bias_sel     =0         ,
  output    reg   [  9 : 0]         ofm_bias_snum    =0         ,
  output    reg                     ofm_rstart       =0         ,  
  output    reg   [  6 : 0]         ofm_concat_num   =0         ,
  output    reg                     ofm_tmp_sel      =0         ,
  output    reg                     ofm_output_sel   =0         ,
  output    reg   [  4 : 0]         ofm_din_snum     =0         ,
  output    reg   [ 14 : 0]         ofm_rbase        =0         ,
  output    reg   [ 14 : 0]         ofm_wbase        =0         ,
  output    reg                     ofm_pp           =0         ,
  //-------------------------------------------------------------
  input                             dec_res_en                  ,//19 
  input                             dec_act_en                  ,//19    
  input           [  3 : 0]         dec_act_type                ,//18    
  input           [  3 : 0]         dec_ddr_wpos                ,//37  
  input                             dec_ddr_save_need_sync      ,//19
  input           [ 10 : 0]         dec_cout                    ,//2                          
  input           [ 11 : 0]         dec_nvm_xnum                ,//38
  input           [ 11 : 0]         dec_nvm_ynum                ,//38 
  input           [ 11 : 0]         dec_nvm_bnum                ,//39      
  input           [ 11 : 0]         dec_nvm_gnum                ,//39
  input                             dec_nvm_idir                ,//40
  input           [  5 : 0]         dec_nvm_inum                ,//40    
  input                             dec_nvm_odir                ,//40    
  input           [  5 : 0]         dec_nvm_onum                ,//40    
  output    reg                     nvm_rstart       =0         ,  
  output    reg                     nvm_res_en       =0         ,
  output    reg                     nvm_act_en       =0         ,
  output    reg   [  3 : 0]         nvm_act_type     =0         ,
  output    reg                     nvm_sf_en        =0         ,
  output    reg                     nvm_ln_en        =0         ,
  output    reg                     nvm_tr_en        =0         ,
  output    reg                     nvm_router       =0         ,
  output    reg   [ 10 : 0]         nvm_rnum         =0         ,
  output    reg   [  6 : 0]         nvm_rstep        =0         ,
  output    reg   [ 11 : 0]         nvm_xnum         =0         ,
  output    reg   [ 11 : 0]         nvm_ynum         =0         ,
  output    reg   [ 11 : 0]         nvm_bnum         =0         ,
  output    reg   [ 11 : 0]         nvm_gnum         =0         ,
  output    reg                     nvm_idir         =0         ,
  output    reg   [  5 : 0]         nvm_inum         =0         ,
  output    reg                     nvm_odir         =0         ,
  output    reg   [  5 : 0]         nvm_onum         =0         ,
  input           [8-1:0]           dec_ddr_rstart_r            ,
  input                             dec_ddr_rstart              ,
  input                             dec_ifm_rstart              ,
  input                             dec_ofm_rstart              ,
  input                             dec_ddr_wstart              ,
  input                             dec_nvm_rstart              ,
  
  input                             nvm_rdone                   ,
  input                             core_start                  ,
  input                             state_rdone                 ,
  input                             clk                         ,
  input                             reset                   
);

  //-------------------------------------------------------------------------
  //For the DDR-R module
  //-------------------------------------------------------------------------
  always @(posedge clk) begin
    if ( dec_ddr_rstart ) begin
      ddr_high_addr_ini_ddr_fm      <=  dec_high_addr_ini_ddr_fm                ;
      ddr_fm_in_xsize               <=  dec_fm_in_xsize                         ;
      ddr_fm_in_ysize               <=  dec_fm_in_ysize                         ;
      ddr_high_addr_ini_ddr_ker     <=  dec_high_addr_ini_ddr_ker               ;
      ddr_sparse_mask_enable        <=  dec_ddr_sparse_mask_enable              ;
      ddr_high_addr_ini_ddr_bias    <=  dec_high_addr_ini_ddr_bias              ;
      ddr_rblk_ysize                <=  dec_ddr_rblk_ysize                      ;
      ddr_rblk_xsize                <=  dec_ddr_rblk_xsize                      ;
      ddr_high_addr_ini_ddr_ins     <=  dec_high_addr_ini_ddr_ins               ;
      ddr_high_addr_ini_ddr_param   <=  dec_high_addr_ini_ddr_param             ;
      ddr_rtype[4:0]                <=  dec_ddr_rtype[4:0]                      ;
      ddr_rtype[5]                  <=  dec_ddr_rtype[5]&&dec_param_bank_id==0  ;
      ddr_rtype[6]                  <=  dec_ddr_rtype[5]&&dec_param_bank_id==1  ;
    end
  end
  always @(posedge clk) begin
  if(dec_ddr_rstart_r[0])ddr_rfm_offset          <=  dec_ddr_rfm_offset         ;//24bit
  if(dec_ddr_rstart_r[1])ddr_rker_offset         <=  dec_ddr_rker_offset        ;//24bit
  if(dec_ddr_rstart_r[2])ddr_rfm_num             <=  dec_ddr_rfm_num            ;//14bit
  if(dec_ddr_rstart_r[2])ddr_rker_num            <=  dec_ddr_rker_num           ;//14bit
  if(dec_ddr_rstart_r[3])ddr_rbias_offset        <=  dec_ddr_rbias_offset       ;//24bit
  if(dec_ddr_rstart_r[4])ddr_sparse_mask_rnum    <=  dec_ddr_sparse_mask_rnum   ;//14bit
  if(dec_ddr_rstart_r[4])ddr_rbias_num           <=  dec_ddr_rbias_num          ;//14bit
  if(dec_ddr_rstart_r[5])ddr_rres_offset         <=  dec_ddr_rres_offset        ;//24bit
  if(dec_ddr_rstart_r[6])ddr_rins_offset         <=  dec_ddr_rins_offset        ;//24bit
  if(dec_ddr_rstart_r[7])ddr_rparam_offset       <=  dec_ddr_rparam_offset      ;//24bit
  if(dec_ddr_rstart_r[7])ddr_rparam_num          <=  dec_ddr_rparam_num         ;//14bit
 end






  //-------------------------------------------------------------------------
  //For the DDR-W module
  //-------------------------------------------------------------------------
  always @(posedge clk)
  if (dec_ddr_wstart)
  begin
      ddr_high_addr_ini_fm_output<=dec_high_addr_ini_fm_output;
      ddr_wfm_offset          <=  dec_ddr_wfm_offset          ;
      ddr_fm_out_xsize        <=  dec_fm_out_xsize            ;      
      ddr_wblk_ysize          <=  dec_ddr_wblk_ysize          ;
      ddr_wblk_xsize          <=  dec_ddr_wblk_xsize          ;
  end 

  //-------------------------------------------------------------------------
  //For the IFM module, For the KER module
  //-------------------------------------------------------------------------
  reg       dec_ifm_pp  =0                                    ;
  reg       dec_ker_pp  =0                                    ;
  always @(posedge clk) begin
    if ( dec_ifm_rstart ) begin
      ifm_hmax                <=  dec_ifm_hmax                ;
      ifm_hmin                <=  dec_ifm_hmin                ;
      ifm_hs                  <=  dec_ifm_hs                  ;
      ifm_h                   <=  dec_ifm_h                   ;
      ifm_wmax                <=  dec_ifm_wmax                ;
      ifm_wmin                <=  dec_ifm_wmin                ;
      ifm_ws                  <=  dec_ifm_ws                  ;
      ifm_w                   <=  dec_ifm_w                   ;
      ifm_rkeep               <=  dec_ifm_rkeep               ;
      ifm_rsel                <=  dec_ifm_rsel                ;
      ker_eaddr               <=  dec_ker_eaddr               ;
      ker_saddr               <=  dec_ker_saddr               ;
      pe_output_num           <=  dec_pe_output_num           ;
    end
  end
  
  always @(posedge clk) 
  ifm_rstart                 <=  dec_ifm_rstart               ;
  


  always @(posedge clk)
  if(core_start)             dec_ifm_pp<= 0                   ;
  else if(dec_ddr_rstart&&
          dec_ddr_rtype[0])  dec_ifm_pp<= ~dec_ifm_pp         ;
          
  always @(posedge clk)
  if(dec_ifm_rstart)         ifm_pp<= dec_ifm_pp              ;



  always @(posedge clk)
  if(core_start)             dec_ker_pp<= 0                   ;
  else if(dec_ddr_rstart&&
          dec_ddr_rtype[1])  dec_ker_pp<=~dec_ker_pp          ;

  always @(posedge clk)
  if(dec_ifm_rstart)         ker_pp<= dec_ker_pp              ;





  //-------------------------------------------------------------------------
  //For the OFM module
  //-------------------------------------------------------------------------

  localparam              INST_OFM_DLY       =`INST_OFM_DLY     ;
  localparam              INST_NVM_DLY       =`INST_NVM_DLY     ;

  reg                     dec_bias_pp =0                        ;
  reg                     dec_ofm_pp  =0                        ;
  always @(posedge clk)
  begin
      if(dec_ofm_rstart)  dec_bias_pp<=~dec_bias_pp             ;
      if(dec_ofm_rstart)  dec_ofm_pp <=~dec_ofm_pp              ;
  end



  reg                     r_bias_pp          =0                 ; 
  reg                     r_ofm_bias_sel     =0                 ;
  reg   [  9 : 0]         r_ofm_bias_snum    =0                 ;
  reg                     r_ofm_rstart       =0                 ;  
  reg   [  6 : 0]         r_ofm_concat_num   =0                 ;
  reg                     r_ofm_tmp_sel      =0                 ;
  reg                     r_ofm_output_sel   =0                 ;
  reg   [  4 : 0]         r_ofm_snum         =0                 ;
  reg   [ 14 : 0]         r_ofm_rbase        =0                 ;
  reg   [ 14 : 0]         r_ofm_wbase        =0                 ;
  reg                     r_ofm_pp           =0                 ;
  reg   [ 10 : 0]         ofm_dly_cnt        =0                 ;

  
  always @(posedge clk)
  if (dec_ofm_rstart) begin
      r_ofm_bias_sel            <=  dec_bias_sel                ;
      r_ofm_bias_snum           <=  dec_bias_snum               ;
      r_ofm_concat_num          <=  dec_ofm_concat_num          ;
      r_ofm_tmp_sel             <=  dec_ofm_tmp_sel             ;
      r_ofm_output_sel          <=  dec_final_output            ; 
      r_ofm_snum                <=  dec_ofm_snum                ;
      if(dec_ofm_tmp_sel) r_ofm_rbase<=dec_ofm_rbase            ;
      r_ofm_wbase               <=  dec_ofm_wbase               ;
  end


  always @(posedge clk)  
  if(dec_ofm_rstart)      ofm_dly_cnt<=INST_OFM_DLY             ;
  else begin
        if(ofm_dly_cnt==0)ofm_dly_cnt<=0;
        else              ofm_dly_cnt<=ofm_dly_cnt-1            ;
  end
  
  always @(posedge clk) ofm_rstart <=  (ofm_dly_cnt==1)         ;
  
  always @(posedge clk)
  if(ofm_dly_cnt==1)begin
      ofm_din_enc               <=  pe_output_num               ;
      ofm_bias_sel              <=  r_ofm_bias_sel              ;
      ofm_bias_snum             <=  r_ofm_bias_snum             ;
      ofm_concat_num            <=  r_ofm_concat_num            ;
      ofm_tmp_sel               <=  r_ofm_tmp_sel               ;
      ofm_output_sel            <=  r_ofm_output_sel            ; 
      ofm_din_snum              <=  r_ofm_snum                  ;
      ofm_rbase                 <=  r_ofm_rbase                 ;
      ofm_wbase                 <=  r_ofm_wbase                 ;
      bias_pp                   <=  dec_bias_pp&&r_ofm_bias_sel ;
      ofm_pp                    <=  dec_ofm_pp                  ;
  end


  //-------------------------------------------------------------------------
  //For the NVM module
  //-------------------------------------------------------------------------
  (*max_fanout=16*)reg    r_nvm_rstart       =0                ;  
  reg                     r_nvm_res_en       =0                ;
  reg                     r_nvm_act_en       =0                ;
  reg   [  3 : 0]         r_nvm_act_type     =0                ;
  reg                     r_nvm_sf_en        =0                ;
  reg                     r_nvm_ln_en        =0                ;
  reg                     r_nvm_tr_en        =0                ;
  reg                     r_nvm_router       =0                ;
  reg   [ 10 : 0]         r_nvm_rnum         =0                ;
  reg   [  6 : 0]         r_nvm_rstep        =0                ;
  reg   [ 11 : 0]         r_nvm_xnum         =0                ;
  reg   [ 11 : 0]         r_nvm_ynum         =0                ;
  reg   [ 11 : 0]         r_nvm_bnum         =0                ;
  reg   [ 11 : 0]         r_nvm_gnum         =0                ;
  reg                     r_nvm_idir         =0                ;
  reg   [  5 : 0]         r_nvm_inum         =0                ;
  reg                     r_nvm_odir         =0                ;
  reg   [  5 : 0]         r_nvm_onum         =0                ;
  reg   [ 10 : 0]         nvm_dly_cnt        =0                ;


  always @(posedge clk)
  if ( dec_nvm_rstart )
  begin
      r_nvm_res_en          <=  dec_res_en                     ;
      r_nvm_act_en          <=  dec_act_en                     ; 
      r_nvm_act_type        <=  dec_act_type                   ;      
      r_nvm_sf_en           <=  dec_ddr_wpos ==8               ;
      r_nvm_ln_en           <=  dec_ddr_wpos ==7               ;
      r_nvm_tr_en           <=  dec_ddr_wpos ==4               ;
      r_nvm_router          <=  dec_ddr_save_need_sync         ;
      r_nvm_rnum            <=  dec_cout                       ;
      r_nvm_rstep           <=  dec_ddr_wblk_ysize             ;      
      r_nvm_xnum            <=  dec_nvm_xnum                   ;
      r_nvm_ynum            <=  dec_nvm_ynum                   ;
      r_nvm_bnum            <=  dec_nvm_bnum                   ;
      r_nvm_gnum            <=  dec_nvm_gnum                   ;      
      r_nvm_idir            <=  dec_nvm_idir                   ;
      r_nvm_inum            <=  dec_nvm_inum                   ;
      r_nvm_odir            <=  dec_nvm_odir                   ;
      r_nvm_onum            <=  dec_nvm_onum                   ;
  end  

  always @(posedge clk)  
  if(dec_nvm_rstart)      nvm_dly_cnt<=INST_NVM_DLY            ;
  else begin
        if(!nvm_dly_cnt)  nvm_dly_cnt<=0;
        else              nvm_dly_cnt<=nvm_dly_cnt-1           ;
  end
  
  always @(posedge clk)   nvm_rstart <=(nvm_dly_cnt==1)        ;
  always @(posedge clk) r_nvm_rstart <=(nvm_dly_cnt==5)        ;
  
  always @(posedge clk)
  if ( r_nvm_rstart )
  begin
        nvm_res_en          <=  r_nvm_res_en                   ;
        nvm_act_en          <=  r_nvm_act_en                   ; 
        nvm_act_type        <=  r_nvm_act_type                 ;      
        nvm_sf_en           <=  r_nvm_sf_en                    ;
        nvm_ln_en           <=  r_nvm_ln_en                    ;
        nvm_tr_en           <=  r_nvm_tr_en                    ;
        nvm_router          <=  r_nvm_router                   ;
        nvm_rnum            <=  r_nvm_rnum                     ;
        nvm_rstep           <=  r_nvm_rstep                    ;      
        nvm_xnum            <=  r_nvm_xnum                     ;
        nvm_ynum            <=  r_nvm_ynum                     ;
        nvm_bnum            <=  r_nvm_bnum                     ;
        nvm_gnum            <=  r_nvm_gnum                     ;      
        nvm_idir            <=  r_nvm_idir                     ;
        nvm_inum            <=  r_nvm_inum                     ;
        nvm_odir            <=  r_nvm_odir                     ;
        nvm_onum            <=  r_nvm_onum                     ;
  end  
  else if(nvm_rdone)
  begin
        nvm_res_en          <=  0                              ;
        nvm_act_en          <=  0                              ; 
        nvm_act_type        <=  0                              ;      
        nvm_sf_en           <=  0                              ;
        nvm_ln_en           <=  0                              ;
        nvm_tr_en           <=  0                              ;
        nvm_router          <=  0                              ;
        nvm_rnum            <=  0                              ;
        nvm_rstep           <=  0                              ;      
        nvm_xnum            <=  0                              ;
        nvm_ynum            <=  0                              ;
        nvm_bnum            <=  0                              ;
        nvm_gnum            <=  0                              ;      
        nvm_idir            <=  0                              ;
        nvm_inum            <=  0                              ;
        nvm_odir            <=  0                              ;
        nvm_onum            <=  0                              ;
  end
  
  
  




endmodule

