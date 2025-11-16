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

module inst_state (

  output  reg              ddr_rstart       = 0         ,
  output  reg   [ 3  : 0]  ddr_rid          = 0         ,
  output  reg   [ 3  : 0]  ddr_roffset_high = 0         ,
  output  reg   [ 24 : 0]  ddr_roffset      = 0         ,
  output  reg   [ 24 : 0]  ddr_rstride      = 0         ,
  output  reg   [ 6  : 0]  ddr_rstep_num    = 0         ,
  output  reg   [ 14 : 0]  ddr_rstep        = 0         ,
  output  reg   [ 14 : 0]  ddr_bm_num       = 0         ,
  output  reg              ddr_bm_en        = 0         ,
  //
  output  reg              ddr_wstart       = 0         ,
  output  reg   [ 3  : 0]  ddr_woffset_high = 0         ,
  output  reg   [ 24 : 0]  ddr_woffset      = 0         ,
  output  reg   [ 24 : 0]  ddr_wstride      = 0         ,  
  output  reg   [  6 : 0]  ddr_wstep_num    = 0         ,  
  output  reg   [ 14 : 0]  ddr_wstep        = 0         ,
  //
  input         [ 3  : 0]  ddr_high_addr_ini_ddr_fm     ,
  input         [ 24 : 0]  ddr_rfm_offset               ,
  input         [ 9  : 0]  ddr_fm_in_xsize              ,
  input         [  9 : 0]  ddr_fm_in_ysize              ,  
  input         [ 14 : 0]  ddr_rfm_num                  ,  
  input         [ 3  : 0]  ddr_high_addr_ini_ddr_ker    ,
  input         [ 24 : 0]  ddr_rker_offset              ,
  input         [ 14 : 0]  ddr_rker_num                 ,
  input                    ddr_sparse_mask_enable       ,
  input         [ 14 : 0]  ddr_sparse_mask_rnum         ,
  input         [ 3  : 0]  ddr_high_addr_ini_ddr_bias   ,
  input         [ 24 : 0]  ddr_rbias_offset             ,
  input         [ 14 : 0]  ddr_rbias_num                ,
  input         [ 24 : 0]  ddr_rres_offset              ,
  input         [ 6  : 0]  ddr_rblk_ysize               ,            
  input         [ 6  : 0]  ddr_rblk_xsize               ,
  input         [ 3  : 0]  ddr_high_addr_ini_ddr_ins    ,
  input         [ 24 : 0]  ddr_rins_offset              ,
  input         [ 3  : 0]  ddr_high_addr_ini_ddr_param  ,
  input         [ 24 : 0]  ddr_rparam_offset            ,
  input         [ 14 : 0]  ddr_rparam_num               ,
  input         [ 6  : 0]  ddr_rtype                    ,
  input         [ 5  : 0]  dec_ddr_rtype                ,
  input                    dec_ddr_rstart               ,
  //
  input         [ 3  : 0]  ddr_high_addr_ini_fm_output  ,
  input         [ 24 : 0]  ddr_wfm_offset               ,
  input         [ 9  : 0]  ddr_fm_out_xsize             ,      
  input         [ 6  : 0]  ddr_wblk_ysize               ,      
  input         [ 6  : 0]  ddr_wblk_xsize               ,
  input                    dec_ddr_wstart               ,


  input         [ 3  : 0]  core_offset_high             ,
  input         [ 24 : 0]  core_offset                  ,
  input                    core_start                   ,

  input                    inst_ready                   ,
  input                    ddr_rdone                    ,
  input                    ofm_rdone_final              ,//for res
  output   wire            state_rdone                  ,
  
  input                    clk                          ,
  input                    reset                   
);

//-----------------------------------------------------------------------
//Control logic for ddr reading
//-----------------------------------------------------------------------
(*max_fanout=16*)reg [4-1:0]    STATE      =   0        ;
localparam      R0_IDLE         =   0                   ;
localparam      R1_IFM          =   1                   ;
localparam      R2_KER          =   2                   ;
localparam      R3_BIAS         =   3                   ;
localparam      R4_RES          =   4                   ;
localparam      R5_INST         =   5                   ;
localparam      R6_BETA         =   6                   ;
localparam      R7_GAMMA        =   7                   ;

wire    dec_ddr_rstart_ctrl                             ;

assign  dec_ddr_rstart_ctrl=(dec_ddr_rtype[3])?//|ddr_rtype[3]
        ofm_rdone_final:dec_ddr_rstart                  ;

always @ (posedge clk)
if (reset) STATE    <=  R0_IDLE                         ;
else case (STATE)
R0_IDLE:  
begin
  if (dec_ddr_rstart_ctrl)begin
       if(dec_ddr_rtype[1])STATE <= R2_KER              ;
  else if(dec_ddr_rtype[0])STATE <= R1_IFM              ;
  else if(dec_ddr_rtype[2])STATE <= R3_BIAS             ;             
  else if(dec_ddr_rtype[3])STATE <= R4_RES              ;
  else if(dec_ddr_rtype[4])STATE <= R5_INST             ;              
  else if(dec_ddr_rtype[5])STATE <= R6_BETA             ;
  else if(dec_ddr_rtype[5])STATE <= R7_GAMMA            ;                      
  end else                 STATE <= R0_IDLE             ;
end//---------------------------------------------------------
R2_KER:
begin
           if(ddr_rtype[0])STATE <= R1_IFM              ;
      else if(ddr_rtype[2])STATE <= R3_BIAS             ;             
      else if(ddr_rtype[3])STATE <= R4_RES              ;
      else if(ddr_rtype[4])STATE <= R5_INST             ;              
      else if(ddr_rtype[5])STATE <= R6_BETA             ;
      else if(ddr_rtype[6])STATE <= R7_GAMMA            ;                      
      else                 STATE <= R0_IDLE             ;
end//---------------------------------------------------------
R1_IFM:
begin
           if(ddr_rtype[2])STATE <= R3_BIAS             ;             
      else if(ddr_rtype[3])STATE <= R4_RES              ;
      else if(ddr_rtype[4])STATE <= R5_INST             ;              
      else if(ddr_rtype[5])STATE <= R6_BETA             ;
      else if(ddr_rtype[6])STATE <= R7_GAMMA            ;                      
      else                 STATE <= R0_IDLE             ; 
end//---------------------------------------------------------
R3_BIAS:
begin
           if(ddr_rtype[3])STATE <= R4_RES              ;
      else if(ddr_rtype[4])STATE <= R5_INST             ;              
      else if(ddr_rtype[5])STATE <= R6_BETA             ;
      else if(ddr_rtype[6])STATE <= R7_GAMMA            ;                      
      else                 STATE <= R0_IDLE             ;
end//---------------------------------------------------------                            
R4_RES:
begin
           if(ddr_rtype[4])STATE <= R5_INST             ;              
      else if(ddr_rtype[5])STATE <= R6_BETA             ;
      else if(ddr_rtype[6])STATE <= R7_GAMMA            ;                      
      else                 STATE <= R0_IDLE             ; 
end//---------------------------------------------------------
R5_INST:
begin
           if(ddr_rtype[5])STATE <= R6_BETA             ;
      else if(ddr_rtype[6])STATE <= R7_GAMMA            ;                      
      else                 STATE <= R0_IDLE             ; 
end//---------------------------------------------------------         
R6_BETA:
begin
      if(ddr_rtype[6])     STATE <= R7_GAMMA            ;                      
      else                 STATE <= R0_IDLE             ;
end//---------------------------------------------------------
R7_GAMMA:
begin
                           STATE <= R0_IDLE             ;
end//---------------------------------------------------------
default:
begin                           
                           STATE <= R0_IDLE             ;
end//---------------------------------------------------------
endcase


//------------------------------------------------------------
// loading data form off-memory
//------------------------------------------------------------

  always @(core_start or STATE)//posedge clk
  if ( core_start )
  begin
      ddr_rstart      <=1                               ;
      ddr_rid         <=R5_INST                         ;
      ddr_roffset_high<=core_offset_high                ;
      ddr_roffset     <=core_offset                     ;
      ddr_rstride     <=64                              ;
      ddr_rstep_num   <=1                               ;            
      ddr_rstep       <=64                              ;
      ddr_bm_en       <=0                               ;
      ddr_bm_num      <=0                               ;  
  end
  else 
  case (STATE)
  R1_IFM: begin//-------------------------------1
      ddr_rstart      <=1                               ;
      ddr_rid         <=R1_IFM                          ;
      ddr_roffset_high<=ddr_high_addr_ini_ddr_fm        ;
      ddr_roffset     <=ddr_rfm_offset                  ;
      ddr_rstride     <=ddr_fm_in_xsize                 ;
      ddr_rstep_num   <=ddr_fm_in_ysize                 ;            
      ddr_rstep       <=ddr_rfm_num                     ;
      ddr_bm_en       <=0                               ;
      ddr_bm_num      <=0                               ;
  end 
  R2_KER: begin//-------------------------------2
      ddr_rstart      <=1                               ;
      ddr_rid         <=R2_KER                          ;
      ddr_roffset_high<=ddr_high_addr_ini_ddr_ker       ;
      ddr_roffset     <=ddr_rker_offset                 ;
      ddr_rstride     <=ddr_rker_num                    ;
      ddr_rstep_num   <=1                               ;            
      ddr_rstep       <=ddr_rker_num                    ;
      ddr_bm_en       <=ddr_sparse_mask_rnum>0          ;//ddr_sparse_mask_enable  ;
      ddr_bm_num      <=ddr_sparse_mask_rnum            ;
  end  
  R3_BIAS: begin//------------------------------3
      ddr_rstart      <=1                               ;
      ddr_rid         <=R3_BIAS                         ;
      ddr_roffset_high<=ddr_high_addr_ini_ddr_bias      ;
      ddr_roffset     <=ddr_rbias_offset                ;
      ddr_rstride     <=ddr_rbias_num                   ;
      ddr_rstep_num   <=1                               ;            
      ddr_rstep       <=ddr_rbias_num                   ;
      ddr_bm_en       <=0                               ;
      ddr_bm_num      <=0                               ;
  end  
  R4_RES: begin//-------------------------------4
      ddr_rstart      <=1                               ;
      ddr_rid         <=R4_RES                          ;
      ddr_roffset_high<=ddr_high_addr_ini_ddr_fm        ;
      ddr_roffset     <=ddr_rres_offset                 ;
      ddr_rstride     <=ddr_fm_in_xsize                 ;
      ddr_rstep_num   <=ddr_rblk_ysize                  ;           
      ddr_rstep       <=ddr_rblk_xsize                  ;
      ddr_bm_en       <=0                               ;
      ddr_bm_num      <=0                               ;
  end  
  R5_INST: begin//------------------------------5
      ddr_rstart      <=1                               ;
      ddr_rid         <=R5_INST                         ;
      ddr_roffset_high<=ddr_high_addr_ini_ddr_ins       ;
      ddr_roffset     <=ddr_rins_offset                 ;
      ddr_rstride     <=64                              ;
      ddr_rstep_num   <=1                               ;            
      ddr_rstep       <=64                              ;
      ddr_bm_en       <=0                               ;
      ddr_bm_num      <=0                               ;
  end  
  R6_BETA: begin//------------------------------6
      ddr_rstart      <=1                               ;
      ddr_rid         <=R6_BETA                         ;
      ddr_roffset_high<=ddr_high_addr_ini_ddr_param     ;
      ddr_roffset     <=ddr_rparam_offset               ;
      ddr_rstride     <=ddr_rparam_num                  ;
      ddr_rstep_num   <=1                               ;            
      ddr_rstep       <=ddr_rparam_num                  ;
      ddr_bm_en       <=0                               ;
      ddr_bm_num      <=0                               ;
  end  
  R7_GAMMA: begin//-----------------------------7
      ddr_rstart      <=1                               ;
      ddr_rid         <=R7_GAMMA                        ;
      ddr_roffset_high<=ddr_high_addr_ini_ddr_param     ;
      ddr_roffset     <=ddr_rparam_offset               ;
      ddr_rstride     <=ddr_rparam_num                  ;
      ddr_rstep_num   <=1                               ;            
      ddr_rstep       <=ddr_rparam_num                  ;
      ddr_bm_en       <=0                               ;
      ddr_bm_num      <=0                               ;
  end  
  default: begin//------------------------------0
      ddr_rstart      <=0                               ;
      ddr_rid         <=0                               ;
      ddr_roffset_high<=0                               ;
      ddr_roffset     <=0                               ;
      ddr_rstride     <=0                               ;
      ddr_rstep_num   <=0                               ;            
      ddr_rstep       <=0                               ;
      ddr_bm_en       <=0                               ;
      ddr_bm_num      <=0                               ;   
  end
  endcase

  reg       [4:0]     state_cnt=0                       ;
  always @(posedge clk)
  if(ddr_rstart)      state_cnt<=state_cnt+1            ;
  else if(ddr_rdone)  state_cnt<=state_cnt-1            ;
  
  assign state_rdone=(state_cnt==1)&&ddr_rdone&&inst_ready;



  //---------------------------------------------------------
  //
  //---------------------------------------------------------
  always @(posedge clk)
     ddr_wstart       <= dec_ddr_wstart                 ;

  always @(posedge clk)
  if(ddr_wstart)
  begin
      ddr_woffset_high<=ddr_high_addr_ini_fm_output     ;
      ddr_woffset     <=ddr_wfm_offset                  ;
      ddr_wstride     <={15'd0,ddr_fm_out_xsize}        ;      
      ddr_wstep_num   <=       ddr_wblk_ysize           ;      
      ddr_wstep       <={8'd0 ,ddr_wblk_xsize}          ;
  end
  









endmodule

