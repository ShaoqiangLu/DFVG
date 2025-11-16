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

module nvm_ln_input #(
  parameter  DW  = 16  ,
  parameter  NUM = 32          
) (
  input                    clk                  ,
  input                    reset                ,
  input                    ln_en                ,
  input                    res_en               ,
  input                    res_result_done      ,
  input                    res_result_val       ,
  input       [NUM*DW-1:0] res_result_data      ,
  input       [NUM*DW-1:0] ln_rdata_in          ,
  input                    ln_rdata_vld         ,
  input                    ln_rdata_done        ,    
  output  reg [NUM*DW-1:0] ln_input_data =0     ,
  output  reg              ln_input_val  =0     ,
  output  reg              ln_input_done =0    
);

//--------------------------------------------------------------
//
//--------------------------------------------------------------
(*max_fanout=16*)reg        r_ln_en =0          ;
(*max_fanout=16*)reg        r_res_en=0          ;
always @(posedge clk)
begin
    r_ln_en  <=ln_en                            ;
    r_res_en <=res_en                           ;
end



always @(posedge clk)
if(r_ln_en)
begin
if(r_res_en)begin
    ln_input_val <=res_result_val               ;
    ln_input_done<=res_result_done              ;
end else begin
    ln_input_val <=ln_rdata_vld                 ;
    ln_input_done<=ln_rdata_done                ;
end 
end else begin
    ln_input_val <=0                            ;
    ln_input_done<=0                            ;
end



always @(posedge clk)
if(r_res_en)ln_input_data <=res_result_data     ;
else        ln_input_data <=ln_rdata_in         ;





endmodule