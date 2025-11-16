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
 //----------------------------------------------------------------------------
 //layer_cnt=1:tr_en,transpose[0,2,3,1]                                   
 //layer_cnt=2:      transpose[0,2,1,3]
 //layer_cnt=3:      transpose[0,2,1,3]      
 //layer_cnt=4:div_en,sf_en
 //layer_cnt=5:      transpose[0,2,1,3]  
 //layer_cnt=6:res_en,ln_en                         
 //layer_cnt=7:gelu                
 //layer_cnt=8:res_en,ln_en                                     
 //----------------------------------------------------------------------------
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

module nvm_load_addr
(
  input                     clk                                     ,
  input                     reset                                   ,
  input        [10-1: 0]    layer_cnt                               ,
  input                     nvm_back_en                             ,
  input                     nvm_start                               ,
  input        [7 -1: 0]    nvm_rstep                               ,
  input        [11-1: 0]    nvm_rnum                                ,
  output  wire [15-1: 0]    nvm_raddr                               ,
  output  reg               nvm_raddr_vld     =0                    ,
  output  wire              nvm_raddr_done                          ,
  input                     ddr_wvld                                ,
  output  reg               nvm_done          =0
);

  reg           [7 -1: 0]   nvm_rstep_cnt     =0                    ;
  reg           [11-1: 0]   nvm_rnum_cnt      =0                    ;
  wire                      nvm_rstep_done                          ;
  wire                      nvm_rnum_done                           ;
  reg           [2-1 : 0]   nvm_flag_done     =0                    ;
  
  //---------------------------------------------------------------
  always @(posedge clk)
  if(reset)                 nvm_rstep_cnt <= 0                      ;
  else if(nvm_start)        nvm_rstep_cnt <= 0                      ;
  else if(nvm_rstep_done)   nvm_rstep_cnt <= 0                      ;
  else if(nvm_raddr_vld)    nvm_rstep_cnt <= nvm_rstep_cnt+1        ;//form 0 to 23
  
  assign nvm_rstep_done=nvm_raddr_vld&(nvm_rstep_cnt==nvm_rstep-1)  ;
  
  //---------------------------------------------------------------
  always @(posedge clk)
  if(reset)                 nvm_rnum_cnt <= 0                       ;
  else if(nvm_start)        nvm_rnum_cnt <= 0                       ;
  else if(nvm_rnum_done)    nvm_rnum_cnt <= 0                       ;
  else if(nvm_rstep_done)   nvm_rnum_cnt <= nvm_rnum_cnt+1          ;//form 0 to 64
  
  assign nvm_rnum_done=nvm_rstep_done&(nvm_rnum_cnt==nvm_rnum-1)    ;
  //---------------------------------------------------------------
  always @(posedge clk)
  if (reset)                nvm_raddr_vld <= 0                      ;
  else if (nvm_rnum_done)   nvm_raddr_vld <= 0                      ;
  else if (nvm_start)       nvm_raddr_vld <= 1                      ;
  //---------------------------------------------------------------
  
  assign nvm_raddr_done =nvm_rstep_done                             ;

  always @(posedge clk) 
  begin
        nvm_flag_done[0]<= ddr_wvld;
        nvm_flag_done[1]<= nvm_flag_done[0]                         ;
        nvm_done        <=~nvm_flag_done[0]&nvm_flag_done[1]        ;
  end

  //-------------------------------------------------------------------------
  //
  //-------------------------------------------------------------------------
  //0,64,128---1472,1,65---->
  reg [15-1:0]               nvm_raddr_skip   =0                    ; 
  always @(posedge clk)
  if(nvm_start|nvm_rnum_done|nvm_done)nvm_raddr_skip<= 11'h0        ;
  else if(nvm_rstep_done)    nvm_raddr_skip<=nvm_rnum_cnt+ 1        ;//1,65,129
  else if(nvm_raddr_vld)     nvm_raddr_skip<=nvm_raddr_skip+nvm_rnum;//0,64,128,---1472
  else                       nvm_raddr_skip<=11'h0                  ;

  //-------------------------------------------------------------------------
  //
  //-------------------------------------------------------------------------
  //0,2,4,6--->126,1,3,5,7----_127,128
  //0             ,1              ,0
  //0                             ,128--->   

  wire                       nvm_raddr_seq1_done                    ;
  wire                       nvm_raddr_seq2_done                    ;
  reg    [15-1:0]            nvm_raddr_seq1      =0                 ;
  reg    [15-1:0]            nvm_raddr_seq2      =0                 ;
  reg    [15-1:0]            nvm_raddr_seq3      =0                 ;
  wire   [15-1:0]            nvm_raddr_seq                          ;

  assign nvm_raddr_seq1_done=nvm_raddr_vld&(nvm_raddr_seq1==nvm_rnum+nvm_rnum-2);
  assign nvm_raddr_seq2_done=nvm_raddr_seq1_done&&nvm_raddr_seq2==1 ;
  
  always @(posedge clk)
  if(~nvm_raddr_vld)           nvm_raddr_seq1<=0                    ;
  else begin
       if(nvm_raddr_seq1_done) nvm_raddr_seq1<=0                    ;
       else    nvm_raddr_seq1<=nvm_raddr_seq1+2                     ;
  end  

  always @(posedge clk)
  if(~nvm_raddr_vld)nvm_raddr_seq2<=0                               ;
  else begin
             if(nvm_raddr_seq1_done)
      begin  if(nvm_raddr_seq2_done)nvm_raddr_seq2<=0               ;
              else  nvm_raddr_seq2<=nvm_raddr_seq2+1                ;
      end
  end

  always @(posedge clk)
  if(~nvm_raddr_vld)         nvm_raddr_seq3<=0                      ;
  else begin
      if(nvm_raddr_seq2_done)nvm_raddr_seq3<=nvm_raddr_seq3+128     ;
  end 

  assign nvm_raddr_seq=nvm_raddr_seq1+nvm_raddr_seq2+nvm_raddr_seq3 ;

 
  //-------------------------------------------------------------------------
  //
  //-------------------------------------------------------------------------
  //0,1,2,3,4--->1535
  reg [15-1:0]               nvm_raddr_incr =0                      ; 
  always @(posedge clk)
  if(~nvm_raddr_vld)         nvm_raddr_incr<=0                      ;
  else      nvm_raddr_incr <=nvm_raddr_incr+1                       ;//0,1,2,3


  //-----------------------------------------------------------------
  //0,1,0,1, 0,1,0,1
  //0  ,128, 256,512
  //
  wire                         nvm_raddr_half1_done                 ; 
  wire                         nvm_raddr_half2_done                 ;
  reg [15-1:0]                 nvm_raddr_half1  =0                  ; 
  reg [15-1:0]                 nvm_raddr_half2  =0                  ;
  reg [15-1:0]                 nvm_raddr_half3  =0                  ;
  wire[15-1:0]                 nvm_raddr_half                       ;
  
  assign nvm_raddr_half1_done=nvm_raddr_vld&&nvm_raddr_half1==1     ;
  
  always @(posedge clk)
  if(~nvm_raddr_vld)           nvm_raddr_half1<=0                   ;
  else begin
       if(nvm_raddr_half1_done)nvm_raddr_half1<=0                   ;
       else                    nvm_raddr_half1<=nvm_raddr_half1+1   ;
  end                    
  
  assign nvm_raddr_half2_done=nvm_raddr_half1_done&&nvm_rstep_done  ;
  
  always @(posedge clk)
  if(~nvm_raddr_vld)           nvm_raddr_half2<=0                   ;
  else begin
    if(nvm_raddr_half1_done)
    begin
        if(nvm_raddr_half2_done)nvm_raddr_half2<=0                  ;
        else nvm_raddr_half2 <= nvm_raddr_half2+128                 ;
    end
  end
       
  always @(posedge clk)
  if(~nvm_raddr_vld)           nvm_raddr_half3<=0                   ; 
  else begin
    if(nvm_raddr_half2_done)   nvm_raddr_half3<=nvm_raddr_half3+2   ;
  end                      
  
  assign nvm_raddr_half=nvm_raddr_half1+nvm_raddr_half2+nvm_raddr_half3;
  
  //-----------------------------------------------------------------
  //0,2,--->126,1,2----->127,0,2,--->126,1,2----->127,
  //0          ,1           ,0          ,1
  //0                       ,128                     ,256
  //
  //0       126,2        127,128,    254,         255,256---        
  wire                       nvm_raddr_act1_done                    ; 
  wire                       nvm_raddr_act2_done                    ;  
  reg       [15-1:0]         nvm_raddr_act1  =0                     ; 
  reg       [15-1:0]         nvm_raddr_act2  =0                     ;
  reg       [15-1:0]         nvm_raddr_act3  =0                     ;
  wire      [15-1:0]         nvm_raddr_act                          ;


  assign nvm_raddr_act1_done=nvm_raddr_vld&
                             nvm_raddr_act1==(nvm_rnum+nvm_rnum-2)  ;
  always @(posedge clk)
  if(~nvm_raddr_vld)         nvm_raddr_act1<=    0                  ;
  else begin
    if(nvm_raddr_act1_done)  nvm_raddr_act1<=0                      ;
    else nvm_raddr_act1<=    nvm_raddr_act1+2                       ;
  end 

  assign nvm_raddr_act2_done=nvm_raddr_act1_done&&nvm_raddr_act2==1 ;
  always @(posedge clk)
  if(~nvm_raddr_vld) nvm_raddr_act2<=    0                          ;
  else begin
    if(nvm_raddr_act1_done)
    begin
            if(nvm_raddr_act2_done)  nvm_raddr_act2<=0              ;
            else     nvm_raddr_act2<=nvm_raddr_act2+1               ;
    end
  end

  always @(posedge clk)
  if(~nvm_raddr_vld)           nvm_raddr_act3<=0                    ;
  else begin 
        if(nvm_raddr_act2_done)nvm_raddr_act3<=nvm_raddr_act3+128   ;
  end                   

  assign nvm_raddr_act=nvm_raddr_act1+ nvm_raddr_act2+nvm_raddr_act3;


  //-------------------------------------------------------------------------
  //
  //-------------------------------------------------------------------------
  assign nvm_raddr =
  layer_cnt==1|layer_cnt==2|layer_cnt==3?nvm_raddr_seq              :
  layer_cnt==4                          ?nvm_raddr_skip             :
  layer_cnt==5                          ?nvm_raddr_incr             :
  layer_cnt==6|layer_cnt==8             ?nvm_raddr_half             :
  layer_cnt==7                          ?nvm_raddr_act              :
                                         nvm_raddr_incr             ;
  
  


endmodule