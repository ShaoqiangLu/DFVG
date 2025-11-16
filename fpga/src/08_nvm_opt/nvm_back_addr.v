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

module nvm_back_addr(
  input                     clk                                 ,
  input                     reset                               ,             
  input                     nvm_back_en                         ,
  input         [11-1:0]    nvm_rnum                            ,
  input         [ 7-1:0]    nvm_rstep                           ,
  input         [10-1:0]    layer_cnt                           ,
  input         [15-1:0]    nvm_raddr                           ,
  input                     nvm_raddr_vld                       ,
  input                     back_row_wdone                      ,
  input                     back_row_wvld                       ,
  output  reg               back_wvld       =0                  ,
  output  reg               back_wdone      =0                  ,
  output  reg   [15-1:0]    back_waddr      =0                  , 
  output  wire  [15-1:0]    back_raddr                          ,
  output  reg               back_raddr_vld  =0   
);
  
  integer   i=0,j=0;

  reg       [11-1:0]        back_wcnt=0                         ;
  always @(posedge clk)
  if(~nvm_back_en)          back_wcnt <=0                       ;
  else if(back_wdone)       back_wcnt <=0                       ;
  else if(back_row_wvld&back_row_wdone)
          back_wcnt <=      back_wcnt+1                         ; 

  //---------------------------------------------------------------
  //
  //---------------------------------------------------------------
  localparam            DLY_ADR     = 256                       ;  
  reg       [15-1:0]    dly_adr_reg [DLY_ADR:0]                 ;
  reg       [8 -1:0]    dly_adr_cnt = 0                         ;

  always @(posedge clk)for(i=0;i<=DLY_ADR;i=i+1)
  if(reset)     dly_adr_reg[i]<=0                               ;  
  else if(i==0) dly_adr_reg[i]<=nvm_raddr                       ;
  else          dly_adr_reg[i]<=dly_adr_reg[i-1]                ;

  always @(posedge clk)
  if(back_wdone)        dly_adr_cnt<=0                          ;
  else if(back_row_wvld)dly_adr_cnt<=dly_adr_cnt                ;
  else if(nvm_raddr_vld&nvm_back_en)
                        dly_adr_cnt<=dly_adr_cnt+1              ;

  always @(posedge clk)
  if(back_row_wvld)
  begin
    back_waddr<= dly_adr_reg[dly_adr_cnt-1]                     ;
    back_wdone<=(back_wcnt==nvm_rnum-1)&&back_row_wdone         ;
    back_wvld <=1    ;
  end else begin
    back_waddr<=0    ;
    back_wdone<=0    ;
    back_wvld <=0    ;
  end

  
  //-------------------------------------------------------------
  //
  //-------------------------------------------------------------
  localparam        DLY_DR    =5                                ;                 
  reg [DLY_DR-1:0]  dly_dreg  =0                                ;
  always @(posedge clk)
  for(i=0;i<DLY_DR;i=i+1)
  if(i==0)dly_dreg[i]<=back_wdone                               ;
  else    dly_dreg[i]<=dly_dreg[i-1]                            ;

  reg       back_rstart     =0                                  ;
  wire      back_rnum_rdone                                     ;
  wire      back_rstep_rdone                                    ;
  always @(posedge clk)back_rstart<=dly_dreg[DLY_DR-1]          ;


  reg [11-1:0] back_rnum_cnt =0                                 ;
  reg [7 -1:0] back_rstep_cnt=0                                 ;
  
  always @(posedge clk)
  if(~nvm_back_en)  
  begin
        back_rstep_cnt  <=0                                     ; 
        back_rnum_cnt   <=0                                     ;  
  end 
  else if(back_rstart)
  begin
        back_rstep_cnt  <=0                                     ; 
        back_rnum_cnt   <=0                                     ;
  end
  else if(back_rnum_rdone)
  begin
        back_rstep_cnt  <=0                                     ;
        back_rnum_cnt   <=0                                     ;
  end 
  else if(back_raddr_vld)
  begin
  //--------------------------------------------------------------
      if(back_rstep_rdone)
      begin
            back_rstep_cnt<=0                                   ;
            back_rnum_cnt <=back_rnum_cnt+1                     ;
      end 
      else begin 
            back_rstep_cnt<=back_rstep_cnt+1                    ; 
            back_rnum_cnt <=back_rnum_cnt                       ;
      end
  //--------------------------------------------------------------
  end else
  begin
         back_rstep_cnt<=0; 
         back_rnum_cnt <=0;
  end

  assign back_rstep_rdone=  back_rstep_cnt==nvm_rstep-1         ;
  assign back_rnum_rdone =  back_rstep_cnt==nvm_rstep-1&
                            back_rnum_cnt ==nvm_rnum -1         ;



  always @(posedge clk)
  if(~nvm_back_en)          back_raddr_vld<=0                   ;
  else if(back_rstart)      back_raddr_vld<=1                   ;
  else if(back_rnum_rdone)  back_raddr_vld<=0                   ;

  reg    [15-1:0]           back_raddr_seq        =0            ;

  always @(posedge clk)
  if(~nvm_back_en)          back_raddr_seq<=0                   ;
  else if(back_rstart)      back_raddr_seq<=0                   ;
  else if(back_rnum_rdone)  back_raddr_seq<=0                   ;
  else if(back_raddr_vld)   back_raddr_seq<=back_raddr_seq+1    ;
  else    back_raddr_seq<= 0                                    ;


  reg   [15-1:0]            back_raddr_skip1      =0            ;//0,2,3,4-->126
  wire                      back_raddr_skip1_done               ;
  reg   [15-1:0]            back_raddr_skip2      =0            ;//0,1,0,1
  wire                      back_raddr_skip2_done               ;
  reg   [15-1:0]            back_raddr_skip3      =0            ;//0,128,256
  wire  [15-1:0]            back_raddr_skip                     ;//0,128,256
  
  assign back_raddr_skip1_done=back_raddr_vld&
         back_raddr_skip1==(nvm_rnum+nvm_rnum-2)                ;
  
  always @(posedge clk)
  if(~nvm_back_en)          back_raddr_skip1<=0                 ;
  else if(back_raddr_vld)begin
       if(back_raddr_skip1_done)back_raddr_skip1<=0             ;
       else   back_raddr_skip1<=back_raddr_skip1+2              ;
  end  else   back_raddr_skip1<=0                               ;

  assign back_raddr_skip2_done=back_raddr_vld&
         back_raddr_skip1_done&back_raddr_skip2==1              ;

  always @(posedge clk)
  if(~nvm_back_en)          back_raddr_skip2<=0                 ;
  else if(back_raddr_vld)begin
  //-------------------------------------------------------------
  if(back_raddr_skip1_done)
  begin
       if(back_raddr_skip2_done)back_raddr_skip2<=0             ;
       else   back_raddr_skip2<=back_raddr_skip2+1              ;
  end 
  //-------------------------------------------------------------
  end  else   back_raddr_skip2<=0                               ;


  always @(posedge clk)
  if(~nvm_back_en)          back_raddr_skip3<=0                 ;
  else if(back_raddr_vld)begin
  //-------------------------------------------------------------
       if(back_raddr_skip2_done)
       back_raddr_skip3<=back_raddr_skip3+(nvm_rnum+nvm_rnum)   ;
  //-------------------------------------------------------------
  end else back_raddr_skip3<=0                                  ;

  assign back_raddr_skip=   back_raddr_skip1+
                            back_raddr_skip2+
                            back_raddr_skip3                    ;


  assign back_raddr=        layer_cnt==6||layer_cnt==8          ?
                            back_raddr_skip:
                            back_raddr_seq                      ;



endmodule