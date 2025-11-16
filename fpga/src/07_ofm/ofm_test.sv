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
//    Testbench for the ofm top module.
//
// Revision       :
// Version        Date        Author        Descriptin
// 1.0            2022-04-07  Chen Wu       Initial version
// 2.0            2023-08-25  Shaoqiang     Implementation in U200
// -----------------------------------------------------------------------------



module ofm_test #(
  // NUM indicates the number of the input data for each cycle
  // Currently only supports 32, 64
  parameter                     NUM   =   32                    ,
  // IDW indicates the data width of each input data
  parameter                     IDW   =   42                    ,
  // ADW indicates the data width of each intermediate data
  parameter                     ADW   =   32                    ,
  // ODW indicates the data width of each output data
  parameter                     ODW   =   16                    ,
  localparam                    AIDW  =   NUM*IDW               ,
  localparam                    AADW  =   NUM*ADW               ,
  localparam                    AODW  =   NUM*ODW               
  ) (
  
  input                         layer_start                     ,
  input          [     9 : 0]   layer_cnt                       ,

  output  reg    [    10 : 0]   ofm_woffset                     ,  
  output  reg    [    10 : 0]   ofm_roffset                     ,
  output  reg    [    10 : 0]   ofm_wbase                       ,
  output  reg    [    10 : 0]   ofm_rbase                       ,
  output  reg    [     2 : 0]   ofm_din_enc                     ,
  output  reg    [     4 : 0]   ofm_snum                        ,
  output  reg    [     6 : 0]   concat_num                      ,
  output  reg    [     9 : 0]   bias_snum                       ,
  output  reg                   bias_sel                        ,
  output  reg                   tmp_sel                         ,
  output  reg                   output_sel                      ,
  output  reg                   nvm_osel                        ,  

  output  reg                   ofm_pp                          ,  
  output  wire                  ofm_start                       ,
  input   wire                  ofm_done                        ,    
  
  output  reg    [AIDW-1 : 0]   ofm_din                         ,
  output  reg                   ofm_din_vld                     ,
  output  reg                   ofm_din_done                    ,
  output  reg    [AADW-1 : 0]   bias_data                       ,
  output  reg                   bias_rvld                       ,

  input                         clk                             ,
  input                         reset                           

  );

  reg   [9:0]                   num_ker                         ;//24
  reg   [9:0]                   num_ifm                         ;//24
  reg   [9:0]                   num_step                        ;//64

  always @ (posedge clk)
  if(reset)begin   
    ofm_woffset         <=          1                           ;//no
    ofm_roffset         <=          1                           ;//no
    ofm_din_enc         <=          0                           ;
    concat_num          <=          0                           ;
    ofm_snum            <=          0                           ;
    bias_snum           <=          0                           ;
    nvm_osel            <=          0                           ;
    num_ker             <=          0                           ;
    num_ifm             <=          0                           ;
    num_step            <=          0                           ;
  end else 
  if(layer_start)begin 
  
  case ( layer_cnt )
  10'd1:begin//-------------------------------------------------1,transpose
    ofm_din_enc         <=          3                           ;//no
    concat_num          <=          32                          ;//no
    ofm_snum            <=          11                          ;
    bias_snum           <=          8                           ;
    nvm_osel            <=          0                           ;
    num_ker             <=          24                          ;
    num_ifm             <=          24                          ;
    num_step            <=          64                          ;
  end
  10'd2:begin//-------------------------------------------------2
    ofm_din_enc         <=          3                           ;
    concat_num          <=          32                          ;
    ofm_snum            <=          12                          ;
    bias_snum           <=          7                           ;
    nvm_osel            <=          1                           ;
    num_ker             <=          24                          ;
    num_ifm             <=          24                          ;
    num_step            <=          64                          ;
  end
  10'd3:begin//-------------------------------------------------3
    ofm_din_enc         <=          3                           ;
    concat_num          <=          32                          ;
    ofm_snum            <=          12                          ;
    bias_snum           <=          8                           ;
    nvm_osel            <=          1                           ; 
    num_ker             <=          24                          ;
    num_ifm             <=          24                          ;
    num_step            <=          64                          ;
  end
  10'd4 ,10'd5 ,10'd6 ,10'd7 ,10'd8 ,10'd9,
  10'd10,10'd11,10'd12,10'd13,10'd14,10'd15
  :begin//------------------------------------------------------4,divide,softmax
    ofm_din_enc         <=          3                           ;
    concat_num          <=          32                          ;
    ofm_snum            <=          10                          ;
    bias_snum           <=          5                           ;
    nvm_osel            <=          1                           ;
    num_ker             <=          2                           ;
    num_ifm             <=          2                           ;
    num_step            <=          64                          ;
  end
  10'd16,10'd17,10'd18,10'd19,10'd20,10'd21,
  10'd22,10'd23,10'd24,10'd25,10'd26,10'd27
  :begin//------------------------------------------------------5
    ofm_din_enc         <=          3                           ;
    concat_num          <=          32                          ;
    ofm_snum            <=          12                          ;
    bias_snum           <=          0                           ;//no
    nvm_osel            <=          1                           ;
    num_ker             <=          2                           ;
    num_ifm             <=          2                           ;
    num_step            <=          64                          ;
  end
  10'd28:begin//-------------------------------------------------6,residual_add,layer_norm
    ofm_din_enc         <=          3                           ;
    concat_num          <=          32                          ;
    ofm_snum            <=          11                          ;
    bias_snum           <=          9                           ;
    nvm_osel            <=          1                           ;
    num_ker             <=          24                          ;
    num_ifm             <=          24                          ;
    num_step            <=          64                          ;
  end
  10'd29,10'd30,10'd31,10'd32
  :begin//-------------------------------------------------------7,actFun
    ofm_din_enc         <=          3                           ;
    concat_num          <=          32                          ;
    ofm_snum            <=          12                          ;
    bias_snum           <=          6                           ;
    nvm_osel            <=          1                           ;
    num_ker             <=          24                          ;
    num_ifm             <=          24                          ;
    num_step            <=          64                          ;
  end
  10'd33:begin//------------------------------------------------8,residual_add,layer_norm
    ofm_din_enc         <=          3                           ;
    concat_num          <=          32                          ;
    ofm_snum            <=          10                          ;
    bias_snum           <=          4                           ;
    nvm_osel            <=          1                           ;
    num_ker             <=          24                          ;
    num_ifm             <=          24                          ;
    num_step            <=          64                          ;
  end
      endcase 
  end


  //-----------------------------------------------------------------
  reg        test_start                                             ;
  always @ (posedge clk)
  if(reset)  
    test_start          <=          0                               ;
  else 
    test_start          <=          layer_start                     ;


  //-----------------------------------------------------------------
   reg     [ 9:0 ]              cnt_gap                             ;
   reg     [ 9:0 ]              cnt_ker                             ;
   reg     [ 9:0 ]              cnt_ifm                             ;
   always @(posedge clk) 
   if( reset ) begin
       cnt_gap           <=  0                                      ;
       cnt_ker           <=  0                                      ;  
       cnt_ifm           <=  0                                      ;  
   end
   else
   if(test_start) begin
       cnt_gap           <=  num_step*2+24                          ;//199
       cnt_ker           <=  num_ker-1                              ;  
       cnt_ifm           <=  num_ifm-1                              ;  
   end
   else
   if ( cnt_ifm==0 &&  cnt_ker==0 && cnt_gap==0)
   begin
       cnt_gap           <=  cnt_gap                                ;  
       cnt_ker           <=  cnt_ker                                ;  
       cnt_ifm           <=  cnt_ifm                                ; 
   end
   else
   if ( cnt_gap==0 )
   begin
       cnt_gap           <=  num_step*2+24                          ;  
       if(cnt_ker==0) begin
            cnt_ker           <=  num_ker-1                         ;  
            cnt_ifm           <=  cnt_ifm-1                         ;        
       end
       else
       cnt_ker           <=  cnt_ker-1                              ; 
   end
   else
       cnt_gap           <=  cnt_gap -1                             ;  
   
   
   //----------------------------------------------------------------
  reg                           layer_flay                          ;
   always @(posedge clk) 
   if( reset )
       layer_flay           <=  0                                   ; 
   else
   if(test_start )
       layer_flay           <=  1                                   ; 
   else
   if(cnt_ifm==0 && cnt_ker==0 && cnt_gap==0 )
       layer_flay           <=  0                                   ; 

   assign ofm_start      = layer_flay?(cnt_gap ==num_step*2+24):0   ;


  //-----------------------------------------------------------------
  //sel
   always @(posedge clk) 
   if( reset )begin
       bias_sel          <=  0                                     ;
       tmp_sel           <=  0                                     ;
       output_sel        <=  0                                     ;
   end
   else
   if(test_start)
   begin
       bias_sel          <=  1                                     ;
       tmp_sel           <=  0                                     ;
       output_sel        <=  0                                     ;
   end
   else begin
   if((cnt_ifm==num_ifm-1)&& cnt_ker==0 && cnt_gap==0 )
       begin
       bias_sel          <=  ~bias_sel                             ;  
       tmp_sel           <=  ~tmp_sel                              ;  
       end
   if(cnt_ifm==1 && cnt_ker==0 && cnt_gap==0 )
       output_sel        <=  1                                     ;   
   end
   

   //----------------------------------------------------------------
   //base ram
   always @(posedge clk) 
   if( reset ) begin
       ofm_wbase           <=  0                                    ; 
   end
   else
   if(test_start) begin
       ofm_wbase           <=  0                                    ;
   end
   else
   if ( cnt_gap==0)
   begin
       if(cnt_ker==0)
       ofm_wbase           <=  0                                    ; 
       else
       ofm_wbase           <=  ofm_wbase+ num_step                  ; 
   end
 
   always @(posedge clk) 
   if( reset ) begin
       ofm_rbase           <=  0                                    ; 
   end
   else
   if(test_start) begin
       ofm_rbase           <=  0                                    ;
   end
   else
   if ( cnt_ifm==num_ker-1)
       ofm_rbase           <=  0                                    ;
   else
   if ( cnt_gap==0)
   begin
       if(cnt_ker==0)
       ofm_rbase           <=  0                                    ; 
       else
       ofm_rbase           <=  ofm_rbase+ num_step                  ; 
   end



  //-----------------------------------------------------------------
  //data cnt
  wire                          data_start                          ;
  reg     [ 9 :0 ]              data_cnt                            ;
  reg                           data_vld                            ;
  wire                          data_done                           ;
  dly_cell #(
    .DLY                        ( 14                               ),
    .DW                         ( 1                                )
  ) dly_st (
    .dout                       ( data_start                       ),
    .din                        ( ofm_start                        ),
    .clk                        ( clk                              ),
    .reset                      ( reset                            ) 
  );
   always @(posedge clk) 
   if( reset ) begin
       data_cnt          <=  0                                     ;
       data_vld          <=  0                                     ;   
   end
   else
   if(data_start) begin
       data_cnt          <=  num_step*2-1                          ;
       data_vld          <=  1                                     ;
   end
   else
   if( data_cnt ==0) begin
       data_cnt          <=  data_cnt                              ;
       data_vld          <=  0                                     ;
   end
   else
       data_cnt          <=  data_cnt -1                           ;

  assign data_done = data_vld? (data_cnt==0):0                     ;  


   //---------------------------------------------------------------
  //in data
  always @(*) 
  if(data_vld)begin
    ofm_din      =    {(AIDW/15){15'({$random}%(2**15))+data_cnt}}  ;
    ofm_din_vld  =    1                                             ;
    ofm_din_done =    data_done                                     ;
  end
  else
  begin
    ofm_din      =    0;
    ofm_din_vld  =    0;
    ofm_din_done =    0;
  end 

  always @(data_vld or bias_sel or layer_cnt) 
  if(layer_cnt>=16 && layer_cnt<=27)
  begin
    bias_data    =    0;
    bias_rvld    =    0;
  end 
  else
  if(data_vld &bias_sel)begin
    bias_data    =    {(AADW/15){15'({$random}%(2**15))}}           ;
    bias_rvld    =    1                                             ;
  end
  else
  begin
    bias_data    =    0;
    bias_rvld    =    0;
  end 

  //-----------------------------------------------------------------
  wire              ofm_done_r                                      ;
  //ofm_pp
   always @(posedge clk) 
   begin
   if( reset )
       ofm_pp              <=  0                                    ;
   else
     if ( ofm_done_r  )
       ofm_pp              <=  ~ofm_pp                              ;
   end

  dly_cell #(
    .DLY                        ( 13                               ),
    .DW                         ( 1                                )
  ) dly_p (
    .dout                       ( ofm_done_r                       ),
    .din                        ( ofm_done                         ),
    .clk                        ( clk                              ),
    .reset                      ( reset                            ) 
  );




endmodule
