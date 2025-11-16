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
//---------------------------------------------------
//(A+D)*B+C
//---------------------------------------------------
`include "opu_parameter.vh"
module nvm_dsp_top #(
  parameter  NUM = 32 
) (
  input      clk      ,     
              
  input      signed [NUM-1:0][24-1:0] A_dsp0 , 
  input      signed [NUM-1:0][16-1:0] B_dsp0 , 
  input      signed [NUM-1:0][40-1:0] C_dsp0 , 
  input      signed [NUM-1:0][24-1:0] D_dsp0 , 
  output     signed [NUM-1:0][40-1:0] P_dsp0 ,

  input      signed [NUM-1:0][17-1:0] A_dsp1 , 
  input      signed [NUM-1:0][17-1:0] B_dsp1 , 
  input      signed [NUM-1:0][34-1:0] C_dsp1 , 
  input      signed [NUM-1:0][17-1:0] D_dsp1 , 
  output     signed [NUM-1:0][34-1:0] P_dsp1 
);
  


reg signed [40-1:0] dsp_test0[NUM-1:0];
generate 
for(genvar i=0; i<NUM; i=i+1) 
begin:g0
`ifndef SIM_DSP_PE
(*keep_hierarchy="yes"*)
DSP_share DSPs(
  .CLK ( clk       ),
  .A   ( A_dsp0[i] ),
  .B   ( B_dsp0[i] ),
  .C   ( C_dsp0[i] ),
  .D   ( D_dsp0[i] ),
  .P   ( P_dsp0[i] ) 
);
`else

reg signed [40-1:0] dly_test0[3-1:0];
always @(posedge clk)
begin
    dsp_test0[i]<=($signed(A_dsp0[i])+$signed(D_dsp0[i]))
                  *$signed(B_dsp0[i])+$signed(C_dsp0[i]);
    dly_test0[0]<=dsp_test0[i];
    dly_test0[1]<=dly_test0[0];
    dly_test0[2]<=dly_test0[1];
end
assign P_dsp0[i] =dly_test0[2];
`endif



end
endgenerate


reg signed [34-1:0] dsp_test1[NUM-1:0];
generate
for(genvar i=0;i<NUM;i=i+1)
begin:g1
`ifndef SIM_DSP_PE
(*keep_hierarchy="yes"*)DSP_square SQUs (
  .CLK  ( clk       ),
  .A    ( A_dsp1[i] ),
  .B    ( B_dsp1[i] ),
  .P    ( P_dsp1[i] ) 
);
`else
reg signed [34-1:0] dly_test1[3-1:0];
always @(posedge clk)
begin
    dsp_test1[i]<=$signed(A_dsp1[i])*$signed(B_dsp1[i]);
    dly_test1[0]<=dsp_test1[i];
    dly_test1[1]<=dly_test1[0];
    dly_test1[2]<=dly_test1[1];
end
assign P_dsp1[i] =dly_test1[2];
`endif

end
endgenerate



endmodule