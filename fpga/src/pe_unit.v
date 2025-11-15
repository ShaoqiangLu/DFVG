`timescale 1ns/1ps

// -----------------------------------------------------------------------------
// UCLA EDA LAB
// -----------------------------------------------------------------------------
// Engineer       : Chen Wu
// Design Name    : opu series
// Module Name    : pe_top
// Description    : 
//    an array of macc units, using adder tree to sum up the results.
//    Different columns performs in parallel.
//    Delay       : 3 + CAS - 1 + $clog2(NUM)
// 
// Parameters     :
//    CAS         : Depth for cascade.
//    NUM         : Number of macc units.
//    COL         : Number of macc_col.
//    DW          : Data width for inputs.
//    RATIO       : Ratio between fast clock and slow clock, only 2 now.
//    !Attention  : Do not set too large CAS for timing closure.
//
// Revision       :
// Version        Date        Author        Descriptin
// 1.0            2024-01-09  Chen Wu       Initial version
// 2.0            2024-05-25  Shaoqiang     Organize and reduce registers. 
//                                          For the synthetic layout.
// -----------------------------------------------------------------------------

`include "opu_parameter.vh"

module pe_unit
#(
  parameter                         DW      =   16                          ,
  parameter                         NUM     =   32                          ,
  parameter                         ODW     =   32                          
)(
  input                             clk                                     ,
  input       [DW-1:0]              dina                                    ,
  input       [DW-1:0]              dinb                                    ,
  output wire [ODW-1:0]             dout                                    
);

//---------------------------------------------------------------------------
//
//---------------------------------------------------------------------------
(*dont_touch="true"*)reg [31:0]     dina_fp32   =0                          ;
(*dont_touch="true"*)reg [31:0]     dinb_fp32   =0                          ;
always @(posedge clk)
begin
    dina_fp32                       <={dina,16'b0}                          ;
    dinb_fp32                       <={dinb,16'b0}                          ;
end

integer i=0;


`ifdef SIM_PE
  localparam                         DLY_PE  =9+1                           ;
  reg                               [DLY_PE*ODW-1:0]  dly_dv   =0           ;
  wire [32-1:0]dout_in               =dina*dinb;
  always @(posedge clk)
  for(i=0;i<DLY_PE;i=i+1)
  if(i==0)dly_dv[i*ODW+:ODW]        <=dout_in;
  else    dly_dv[i*ODW+:ODW]        <=dly_dv[(i-1)*ODW+:ODW]                ;
  assign  dout                       =dly_dv[(DLY_PE-1)*ODW+:ODW]           ;
`else
//--------------------------------------------------------------------------
// IP is 9cycle
//--------------------------------------------------------------------------
DSP_FP32 u_dsp_fp32
 (
  .aclk                             (clk                                    ),// input  wire aclk
  .s_axis_a_tvalid                  (1'b1                                   ),// input  wire s_axis_a_tvalid
  .s_axis_a_tready                  (                                       ),// output wire s_axis_a_tready
  .s_axis_a_tdata                   (dina_fp32                              ),// input  wire [31 : 0] s_axis_a_tdata
  .s_axis_b_tvalid                  (1'b1                                   ),// input  wire s_axis_b_tvalid
  .s_axis_b_tready                  (                                       ),// output wire s_axis_b_tready
  .s_axis_b_tdata                   (dinb_fp32                              ),// input  wire [31 : 0] s_axis_b_tdata
  .m_axis_result_tvalid             (                                       ),// output wire m_axis_result_tvalid
  .m_axis_result_tdata              (dout                                   ) // output wire [31 : 0] m_axis_result_tdata
);
`endif  

endmodule




