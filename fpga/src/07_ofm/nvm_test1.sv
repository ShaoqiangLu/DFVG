`timescale 1ns / 1ps
// -----------------------------------------------------------------------------
// Copyright      : UCLA EDA LAB
// -----------------------------------------------------------------------------
// Engineer       : Chen Wu
// Design Name    : opu series
// Module Name    : tb_nvm_top
// Target Devices : 325t, Alveo U200
// Tool Versions  : Vivado 2020.1, Modelsim 2019.4
// Description    : 
//    Testbench for the nvm top module.
//
// Revision       :
// Version        Date        Author        Descriptin
// 1.0            2022-04-07  Chen Wu       Initial version
// 2.0            2023-08-25  Shaoqiang     Implementation in U200
// -----------------------------------------------------------------------------


module nvm_test1 #(
  parameter             DW        =     16                        ,
  parameter             NUM       =     32                        ,
  parameter             PLEN      =     24                        ,
  localparam            ADW       =     NUM*DW                    
  ) (
  input   wire                        layer_start                 ,
  input   wire   [   9  : 0]          layer_cnt                   ,
  
  
  output  reg    [   10 : 0]          nvm_rnum                    ,
  output  reg    [    6 : 0]          nvm_rstep                   ,  
  output  reg                         nvm_idir                    ,
  output  reg    [    5 : 0]          nvm_inum                    ,
  output  reg                         nvm_odir                    ,
  output  reg    [    5 : 0]          nvm_onum                    ,
  output  reg    [   11 : 0]          nvm_xnum                    ,
  output  reg    [   11 : 0]          nvm_ynum                    ,
  output  reg    [   11 : 0]          nvm_bnum                    ,
  output  reg    [   11 : 0]          nvm_gnum                    ,   
  output  reg                         tr_en                       ,
  output  reg                         res_en                      ,  
  output  reg                         ln_en                       ,   
  output  reg    [    3 : 0]          act_type                    ,
  output  reg                         act_en                      ,
  output  reg                         div_en                      ,
  output  reg                         sf_en                       , 
  output  reg    [NUM-1 :0 ][8-1:0]   pos=0                       ,     


  input   wire                        ofm_done                    ,
  output  reg                         nvm_rstart                  ,   
  
  input   wire   [   10 : 0]          nvm_raddr                   ,
  input   wire                        nvm_raddr_vld               ,
  
  output  wire                        res_rvld                    ,
  output  wire   [ADW-1 : 0]          res_rdata                   ,  

  output  reg    [ADW-1 : 0]          beta_wdata    =0            ,
  output  reg                         beta_wvld     =0            ,
  output  reg                         beta_wstart   =0            ,
  output  reg    [ADW-1 : 0]          gamma_wdata   =0            ,
  output  reg                         gamma_wvld    =0            ,
  output  reg                         gamma_wstart  =0            ,

  input                               clk                         ,
  input                               reset                       
  );
 //---------------------------------------------------------------

  wire           test_start                                      ;
  dly_cell #(
    .DLY                ( 20                                     ),
    .DW                 ( 1                                      )
  ) dly_st (
    .dout               ( test_start                             ),
    .din                ( ofm_done                               ),
    .clk                ( clk                                    ),
    .reset              ( reset                                  )
  );

  always @ (posedge clk)
  if(reset)
    nvm_rstart <= 0                                              ;
  else
    nvm_rstart <= test_start                                     ;


 //---------------------------------------------------------------
 //enable:res_en,act_en,sf_en,ln_en,tr_en
 //num:rnum,rstep,idir,inum,odir,onum,xnum,ynum,bnum,gnum

  always @ (posedge clk)
  if(reset)begin
    nvm_rnum        <=0                                         ;
    nvm_rstep       <=0                                         ;
    nvm_idir        <=0                                         ;
    nvm_inum        <=0                                         ;
    nvm_odir        <=0                                         ;
    nvm_onum        <=0                                         ;
    nvm_xnum        <=0                                         ;
    nvm_ynum        <=0                                         ;
    nvm_bnum        <=0                                         ;
    nvm_gnum        <=0                                         ;
    tr_en           <=0                                         ;
    res_en          <=0                                         ;      
    ln_en           <=0                                         ;
    act_en          <=0                                         ;
    act_type        <=0                                         ;
    div_en          <=0                                         ;
    sf_en           <=0                                         ;
    pos             <=0                                         ;

  end else 
  if(test_start)begin 
  
  case ( layer_cnt )
  10'd1:begin//-------------------------------------------------1,transpose
      nvm_rnum      <=64                                        ;//64,out-side large cycle
      nvm_rstep     <=24                                        ;//24,in-side  small cycle
      nvm_idir      <=0                                         ;
      nvm_inum      <=0                                         ;
      nvm_odir      <=0                                         ;
      nvm_onum      <=0                                         ;
      nvm_xnum      <=13                                        ;
      nvm_ynum      <=13                                        ;
      nvm_bnum      <=0                                         ;
      nvm_gnum      <=0                                         ;
      tr_en         <=1                                         ;
      res_en        <=0                                         ;
      ln_en         <=0                                         ;      
      act_en        <=0                                         ;
      act_type      <=0                                         ;
      div_en        <=0                                         ;
      sf_en         <=0                                         ;
      pos           <=0                                         ;

  end

  10'd2:begin//-------------------------------------------------2
      nvm_rnum      <=64                                        ;
      nvm_rstep     <=24                                        ;
      nvm_idir      <=0                                         ;
      nvm_inum      <=0                                         ;
      nvm_odir      <=0                                         ;
      nvm_onum      <=0                                         ;
      nvm_xnum      <=12                                        ;
      nvm_ynum      <=12                                        ;
      nvm_bnum      <=0                                         ;
      nvm_gnum      <=0                                         ;
      tr_en         <=0                                         ;
      res_en        <=0                                         ;
      ln_en         <=0                                         ;      
      act_en        <=0                                         ;
      act_type      <=0                                         ;
      div_en        <=0                                         ;
      sf_en         <=0                                         ;
      pos           <=0                                         ;
      
  end

  10'd3:begin//-------------------------------------------------3
      nvm_rnum      <=64                                        ;
      nvm_rstep     <=24                                        ;
      nvm_idir      <=0                                         ;
      nvm_inum      <=0                                         ;
      nvm_odir      <=0                                         ;
      nvm_onum      <=0                                         ;
      nvm_xnum      <=12                                        ;
      nvm_ynum      <=12                                        ;
      nvm_bnum      <=0                                         ;
      nvm_gnum      <=0                                         ;
      tr_en         <=0                                         ;
      res_en        <=0                                         ;
      ln_en         <=0                                         ;      
      act_en        <=0                                         ;
      act_type      <=0                                         ;
      div_en        <=0                                         ;
      sf_en         <=0                                         ;
      pos           <=0                                         ;
      
  end

  10'd4 ,10'd5 ,10'd6 ,10'd7 ,10'd8 ,10'd9,
  10'd10,10'd11,10'd12,10'd13,10'd14,10'd15
  :begin//------------------------------------------------------4,divide,softmax
      nvm_rnum      <=64                                        ;
      nvm_rstep     <=2                                         ;
      nvm_idir      <=0                                         ;
      nvm_inum      <=1                                         ;
      nvm_odir      <=0                                         ;
      nvm_onum      <=1                                         ;
      //nvm_xnum      <=8                                         ;
      nvm_xnum      <=7                                         ;
      nvm_ynum      <=15                                        ;
      nvm_bnum      <=0                                         ;
      nvm_gnum      <=0                                         ;
      tr_en         <=0                                         ;
      res_en        <=0                                         ;
      ln_en         <=0                                         ;      
      act_en        <=0                                         ;
      act_type      <=0                                         ;
      div_en        <=1                                         ;
      sf_en         <=1                                         ;
      pos           <=0                                         ;
  end

  10'd16,10'd17,10'd18,10'd19,10'd20,10'd21,
  10'd22,10'd23,10'd24,10'd25,10'd26,10'd27
  :begin//------------------------------------------------------5
      nvm_rnum      <=64                                        ;
      nvm_rstep     <=2                                         ;
      nvm_idir      <=0                                         ;
      nvm_inum      <=1                                         ;
      nvm_odir      <=0                                         ;
      nvm_onum      <=1                                         ;
      nvm_xnum      <=14                                        ;
      nvm_ynum      <=14                                        ;
      nvm_bnum      <=0                                         ;
      nvm_gnum      <=0                                         ;
      tr_en         <=0                                         ;
      res_en        <=0                                         ;
      ln_en         <=0                                         ;      
      act_en        <=0                                         ;
      act_type      <=0                                         ;
      div_en        <=0                                         ;
      sf_en         <=0                                         ;
      pos           <=0                                         ;
  end

  10'd28:begin//-------------------------------------------------6,residual_add,layer_norm
      nvm_rnum      <=64                                        ;
      nvm_rstep     <=24                                        ;
      nvm_idir      <=0                                         ;
      nvm_inum      <=1                                         ;
      nvm_odir      <=0                                         ;
      nvm_onum      <=1                                         ;
      nvm_xnum      <=14                                        ;
      nvm_ynum      <=9                                         ;
      nvm_bnum      <=12                                        ;
      nvm_gnum      <=13                                        ;
      tr_en         <=0                                         ;
      res_en        <=1                                         ;
      ln_en         <=1                                         ;      
      act_en        <=0                                         ;
      act_type      <=0                                         ;
      div_en        <=0                                         ;
      sf_en         <=0                                         ;
      pos           <=0                                         ;
  end

  10'd29,10'd30,10'd31,10'd32
  :begin//-------------------------------------------------------7,actFun
      nvm_rnum      <=64                                        ;
      nvm_rstep     <=24                                        ;
      nvm_idir      <=0                                         ;
      nvm_inum      <=0                                         ;
      nvm_odir      <=0                                         ;
      nvm_onum      <=0                                         ;
      nvm_xnum      <=11                                        ;
      nvm_ynum      <=11                                        ;
      nvm_bnum      <=0                                         ;
      nvm_gnum      <=0                                         ;
      tr_en         <=0                                         ;
      res_en        <=0                                         ;
      ln_en         <=0                                         ;      
      act_en        <=1                                         ;
      act_type      <=5                                         ;
      div_en        <=0                                         ;
      sf_en         <=0                                         ;
      pos           <=0                                         ;
  end

  10'd33:begin//------------------------------------------------8,residual_add,layer_norm
      nvm_rnum      <=64                                        ;
      nvm_rstep     <=24                                        ;
      nvm_idir      <=0                                         ;
      nvm_inum      <=0                                         ;
      nvm_odir      <=0                                         ;
      nvm_onum      <=0                                         ;
      nvm_xnum      <=9                                         ;
      nvm_ynum      <=11                                        ;
      nvm_bnum      <=14                                        ;
      nvm_gnum      <=15                                        ;
      tr_en         <=0                                         ;
      res_en        <=1                                         ;
      ln_en         <=1                                         ;      
      act_en        <=0                                         ;
      act_type      <=0                                         ;
      div_en        <=0                                         ;
      sf_en         <=0                                         ;
      pos           <=0                                         ;
  end

  default:begin//not
      nvm_rnum      <=0                                         ;
      nvm_rstep     <=0                                         ;
      nvm_idir      <=0                                         ;
      nvm_inum      <=0                                         ;
      nvm_odir      <=0                                         ;
      nvm_onum      <=0                                         ;
      nvm_xnum      <=0                                         ;
      nvm_ynum      <=0                                         ;
      nvm_bnum      <=0                                         ;
      nvm_gnum      <=0                                         ;
      tr_en         <=0                                         ;
      res_en        <=0                                         ;
      ln_en         <=0                                         ;      
      act_en        <=0                                         ;
      act_type      <=0                                         ;
      div_en        <=0                                         ;
      sf_en         <=0                                         ;
      pos           <=0                                         ;
  end
      endcase
  end
 

  //res[0],res[6]
  //---------------------------------------------------------------------------------------------------------
  integer   ci ,cj ;
  reg  [ 15:0]  res_MEM0_r[0:1536*32  ]  ;
  reg  [511:0]  res_MEM0[0:1535  ]  ;
  reg  [511:0]  res_MEM6[0:454183]  ;
  initial 
  begin
     $readmemh("/home/lsq/Desktop/opu/rtl/src/12_data/sim6/rtl6/rtl6_0_dram_data_saved.txt", res_MEM0_r);//"X0":txt[1     ,1536  ]->mem[0     ,1535  ] 
     $readmemh("/home/lsq/Desktop/opu/rtl/src/12_data/sim8/sim8_0_dram_data_saved.txt", res_MEM6);//"x6":txt[452649,454184]->mem[452648,454183]
     
    for( ci=0 ; ci<444825; ci=ci+1)
    for( cj=31; cj>=0    ; cj=cj-1)
        res_MEM0[ci][cj*16+:16]=res_MEM0_r[32*ci+31-cj]             ;
  end
  
  
    reg    [ADW-1 : 0]          res_rdata_mem_r     =0          ;
    reg    [ADW-1 : 0]          res_rdata_mem       =0          ;  
    
    assign res_rdata =res_rvld?res_rdata_mem:0                  ;


  always @(posedge clk)
  if ( reset ) 
      res_rdata_mem_r              <=  0                        ;
  else
  if ( res_en && nvm_raddr_vld )
    begin
     if(layer_cnt==28)
        res_rdata_mem_r            <= res_MEM0[nvm_raddr+0]     ;
     else
     if(layer_cnt==33)             
        res_rdata_mem_r            <= res_MEM6[nvm_raddr+452648];    
    end
  else
    res_rdata_mem_r                <=  0                        ;

  always @(posedge clk)
  if ( reset ) 
      res_rdata_mem                <=  0                        ;
  else
      res_rdata_mem                <=  res_rdata_mem_r          ;

   dly_cell#(
    .DW                   ( 1                                   ),
    .DLY                  ( 2                                   )
  ) dly_rev(
    .dout                 ( res_rvld                            ),
    .din                  ( nvm_raddr_vld                       ),
    .clk                  ( clk                                 ),
    .reset                ( reset                               )
  );
 

   reg          [10:0] bg_cnt                                   ; 
 
   always @ (posedge clk)
  if(reset)
    bg_cnt <= 0                                                 ;
  else
  if(nvm_rstart&&(layer_cnt==28 || layer_cnt==33))
    bg_cnt <= 100                                               ;
  else
  if( bg_cnt==0)
    bg_cnt <= bg_cnt                                            ;
  else
    bg_cnt <= bg_cnt-1                                          ;
 
 
   always @ (bg_cnt)
   begin
        if(bg_cnt==100)  beta_wstart  <=1                       ;
        else             beta_wstart  <=0                       ;
        if(bg_cnt<=99 && bg_cnt>99-nvm_rstep)
                         beta_wvld    <=1                       ;
        else             beta_wvld    <=0                       ;

        if(bg_cnt==71)   gamma_wstart <=1                       ;
        else             gamma_wstart <=0                       ;
        if(bg_cnt<=70 && bg_cnt>70-nvm_rstep)
                         gamma_wvld   <=1                       ;
        else             gamma_wvld   <=0                       ;

   end
 

  reg  [ 15:0]  bg_MEM6_r[0:444825*32-1]                        ;
  reg  [511:0]  bg_MEM6[0:444824-1]                             ;
  reg  [511:0]  bg_MEM8[0:444872-1]                             ;
  
  initial 
  begin
     $readmemh("/home/lsq/Desktop/opu/rtl/src/12_data/sim6/rtl6/rtl6_0_dram_data_saved.txt", bg_MEM6_r);//"X0":txt[444777,444825]->mem[444776,444824]
     $readmemh("/home/lsq/Desktop/opu/rtl/src/12_data/sim8/sim8_0_dram_data_saved.txt", bg_MEM8);//"x6":txt[444825,444873]->mem[444824,444872]
     
    for( ci=0 ; ci<444825; ci=ci+1)
    for( cj=31; cj>=0    ; cj=cj-1)
        bg_MEM6[ci][cj*16+:16]=bg_MEM6_r[32*ci+31-cj]             ;
     
  end
  
  
  always @(bg_cnt)
  begin
        if(bg_cnt<=99 && bg_cnt>99-nvm_rstep)
           begin
            if(layer_cnt==28)
               beta_wdata      <=bg_MEM6[0 +(99-bg_cnt)+444776]     ;
            else
            if(layer_cnt==33)             
               beta_wdata      <=bg_MEM8[0 +(99-bg_cnt)+444824]     ;    
           end
     
        else   beta_wdata          <=0                              ;
  
        if(bg_cnt<=70 && bg_cnt>70-nvm_rstep)
           begin
            if(layer_cnt==28)
               gamma_wdata     <=bg_MEM6[24+(70-bg_cnt)+444776]     ;
            else
            if(layer_cnt==33)             
               gamma_wdata     <=bg_MEM8[24+(70-bg_cnt)+444824]     ;   
           end
        
        else   gamma_wdata         <=0                              ;
  end

 
 
 
 
 
 
 
 
 
 

endmodule