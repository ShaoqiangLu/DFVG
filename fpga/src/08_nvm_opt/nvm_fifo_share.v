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
`include "opu_parameter.vh"


module nvm_fifo_share#(
  parameter      FIFO_DELAY         = 1                 ,
  parameter      FIFO_DEEP          = 512               ,
  parameter      FIFO_WIDTH         = 32*16+1   
  ) (
  input                             clk                 ,
  input                             reset               ,
  input                             sf_en               ,
  input                             ln_en               ,              
  input                             sf_in_done          ,
  input                             sf_in_vld           ,
  input      [(FIFO_WIDTH-1)-1:0]   sf_in_data          ,
  input      [(FIFO_WIDTH-1)-1:0]   ln_in_data          , 
  input                             ln_in_vld           ,
  input                             ln_in_done          ,
  input                             sf_in_ren           ,
  input                             ln_in_ren           ,
  output reg                        sf_out_done  =0     ,
  output reg                        sf_out_vld   =0     ,
  output reg [(FIFO_WIDTH-1)-1:0]   sf_out_data  =0     ,
  output reg [(FIFO_WIDTH-1)-1:0]   ln_out_data  =0     , 
  output reg                        ln_out_vld   =0     ,
  output reg                        ln_out_done  =0  
  
);

  //--------------------------------------------------------------
  //fifo 0：Store data for sf_max or ln_mean
  //--------------------------------------------------------------

  (*max_fanout=16*)reg      fifo_wen  =0                ;
  reg [FIFO_WIDTH-1:0]      fifo_wdata=0                ;
  wire[FIFO_WIDTH-1:0]      fifo_rdata                  ;
  wire                      fifo_ren                    ;
  reg                       fifo_rvld =0                ;
  (*max_fanout=16*)reg      r_sf_en   =0                ;
  (*max_fanout=16*)reg      r_ln_en   =0                ;
  
  always @(posedge clk)
  begin
      r_sf_en   <=  sf_en                               ;
      r_ln_en   <=  ln_en                               ;
  end
  
  
  
  always @(posedge clk)
  if(r_sf_en)       fifo_wen <=sf_in_vld                ;
  else if(r_ln_en)  fifo_wen <=ln_in_vld                ;
  else              fifo_wen <=0                        ;

  always @(posedge clk)
  if(r_sf_en)       fifo_wdata <={sf_in_done,sf_in_data};
  else if(r_ln_en)  fifo_wdata <={ln_in_done,ln_in_data};
  
  //--------------------------------------------------------------
  //
  //--------------------------------------------------------------
  (*keep_hierarchy="yes"*)sync_fifo #(
    .MEM_TYPE              ( "block"                    ),
    .RMODE                 ( "std"                      ),
    .FEATURES              ( "0002"                     ),
    .RLATENCY              ( FIFO_DELAY                 ),            
    .DEPTH                 ( FIFO_DEEP                  ),    
    .PFULL_THRESH          ( FIFO_DEEP-10               ),       
    .RWIDTH                ( FIFO_WIDTH                 ),
    .WWIDTH                ( FIFO_WIDTH                 ),
    .PEMPTY_THRESH         ( 10                         )
  )u_FIFO(
    .full                  (                            ),
    .afull                 (                            ),
    .pfull                 (                            ),
    .wdata                 ( fifo_wdata                 ),
    .wen                   ( fifo_wen                   ),
    .aempty                (                            ),
    .pempty                (                            ),
    .empty                 (                            ),
    .rdata                 ( fifo_rdata                 ),
    .ren                   ( fifo_ren                   ),
    .clk                   ( clk                        ),
    .reset                 ( 1'b0                       )
  );

  assign fifo_ren        = r_sf_en?sf_in_ren:           
                           r_ln_en?ln_in_ren:0          ;   
  always @(posedge clk) fifo_rvld<=fifo_ren             ;                
  //--------------------------------------------------------------
  //
  //--------------------------------------------------------------   
  
  
  `ifndef SIM_CODE                  
  always @(posedge clk)
  begin
        sf_out_vld <=fifo_rvld&r_sf_en                  ;
        sf_out_done<=fifo_rdata[ FIFO_WIDTH-1]&fifo_rvld&r_sf_en;
        sf_out_data<=fifo_rdata[(FIFO_WIDTH-1)-1:0]     ;
  end
  
  always @(posedge clk)
  begin
        ln_out_vld <=fifo_rvld&r_ln_en                  ;
        ln_out_done<=fifo_rdata[ FIFO_WIDTH-1]&fifo_rvld&r_ln_en;
        ln_out_data<=fifo_rdata[(FIFO_WIDTH-1)-1:0]     ;
  end

  `else
  always @(posedge clk)
  begin
        sf_out_vld <=fifo_rvld&r_sf_en                  ;
        sf_out_done<=fifo_rdata[ FIFO_WIDTH-1]&fifo_rvld&r_sf_en;
        sf_out_data<=~fifo_rvld&r_sf_en?0:fifo_rdata[(FIFO_WIDTH-1)-1:0];
  end
  
  always @(posedge clk)
  begin
        ln_out_vld <=fifo_rvld&r_ln_en                  ;
        ln_out_done<=fifo_rdata[ FIFO_WIDTH-1]&fifo_rvld&r_ln_en;
        ln_out_data<=~fifo_rvld&r_ln_en?0:fifo_rdata[(FIFO_WIDTH-1)-1:0];
  end
  
  `endif
  

  
  

endmodule