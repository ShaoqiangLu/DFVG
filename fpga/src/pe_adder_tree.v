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

module pe_adder_tree #(
  // Stages of the adder tree
  parameter         STAGE   = 6                     ,

  // data width of the input data
  parameter         DW      = 32                    ,

  // number of the input data
  parameter         NUM     = STAGE == 6 ? 64 :
                              STAGE == 5 ? 32 : 
                              STAGE == 4 ? 16 :
                              STAGE == 3 ?  8 : 4 
) (
  output  wire    [  DW    -1 : 0]    dout          ,
  input           [  DW*NUM-1 : 0]    din           ,
  input                               clk           ,
  input                               reset     
);


if ( STAGE == 6 ) begin
  adder_tree64 #(.DW(DW)) add64 (
    .dout           ( dout                          ),
    .din            ( din                           ),
    .clk            ( clk                           ),
    .reset          ( reset                         )
  );
end else if ( STAGE == 5 ) begin
  adder_tree32 #(.DW(DW)) add32 (
    .dout           ( dout                          ),
    .din            ( din                           ),
    .clk            ( clk                           ),
    .reset          ( reset                         )
  );
end else if ( STAGE == 4 ) begin
  adder_tree16 #(.DW(DW)) add16 (
    .dout           ( dout                          ),
    .din            ( din                           ),
    .clk            ( clk                           ),
    .reset          ( reset                         )
  );
end else if ( STAGE == 3 ) begin
  adder_tree8 #(.DW(DW)) add8 (
    .dout           ( dout                          ),
    .din            ( din                           ),
    .clk            ( clk                           ),
    .reset          ( reset                         )
  );
end else begin
  adder_tree4 #(.DW(DW)) add4 (
    .dout           ( dout                          ),
    .din            ( din                           ),
    .clk            ( clk                           ),
    .reset          ( reset                         )
  );
end


endmodule






 //----------------------------------------------------------------add64
module adder_tree64 #(parameter DW=32) (
  output  wire    [    DW-1 : 0]      dout          ,
  input           [ DW*64-1 : 0]      din           ,
  input                               clk           ,
  input                               reset   
  );
  wire  [ DW-1 : 0]    s0    ;
  wire  [ DW-1 : 0]    s1    ;
  
  adder_tree32 #(.DW(DW)) u0_add32 (
    .dout           ( s0                            ),
    .din            ( din[DW*32*0+: DW*32]          ),
    .clk            ( clk                           ),
    .reset          ( reset                         )
  );

  adder_tree32 #(.DW(DW)) u1_add32 (
    .dout           ( s1                            ),
    .din            ( din[DW*32*1+: DW*32]          ),
    .clk            ( clk                           ),
    .reset          ( reset                         )
  );
  
  //--------------------------------------------------
  //U64
  //--------------------------------------------------
  `ifdef ADD_TREE_IP_FP32
  ADD_PE_FP32 
  u_ADD_PE_FP32 (
    .aclk                 (clk                      ),// input wire aclk
    .s_axis_a_tvalid      (1'b1                     ),// input wire s_axis_a_tvalid
    .s_axis_a_tready      (                         ),// output wire s_axis_a_tready
    .s_axis_a_tdata       (s0                       ),// input wire [31 : 0] s_axis_a_tdata
    .s_axis_b_tvalid      (1'b1                     ),// input wire s_axis_b_tvalid
    .s_axis_b_tready      (                         ),// output wire s_axis_b_tready
    .s_axis_b_tdata       (s1                       ),// input wire [31 : 0] s_axis_b_tdata
    .m_axis_result_tvalid (                         ),// output wire m_axis_result_tvalid
    .m_axis_result_tdata  (dout                     ) // output wire [31 : 0] m_axis_result_tdata
  );
 `elsif ADD_TREE_IP_BF16
  ADD_PE_BF16 
  u_ADD_PE_BF16 (
    .aclk                 (clk                      ),// input  wire aclk
    .s_axis_a_tvalid      (1'b1                     ),// input  wire s_axis_a_tvalid
    .s_axis_a_tready      (                         ),// output wire s_axis_a_tready
    .s_axis_a_tdata       (s0                       ),// input  wire [15 : 0] s_axis_a_tdata
    .s_axis_b_tvalid      (1'b1                     ),// input  wire s_axis_b_tvalid
    .s_axis_b_tready      (                         ),// output wire s_axis_b_tready
    .s_axis_b_tdata       (s1                       ),// input  wire [15 : 0] s_axis_b_tdata
    .m_axis_result_tvalid (                         ),// output wire m_axis_result_tvalid
    .m_axis_result_tdata  (dout                     ) // output wire [15 : 0] m_axis_result_tdata
  );
 `elsif ADD_TREE_USER_FP32
  pe_add_fp32
  u_pe_add_fp32(
    .clk                  (clk                      ),
    .x1                   (s0                       ),
    .x2                   (s1                       ),
    .y                    (dout                     )
  );
 `elsif ADD_TREE_USER_BF16
  pe_add_bf16
  u_pe_add_bf16(
    .clk                  (clk                      ),
    .x1                   (s0                       ),
    .x2                   (s1                       ),
    .y                    (dout                     )
  );
  `endif

  
  
endmodule


 //----------------------------------------------------------------add32
module adder_tree32 #(parameter DW=32) (
  output  wire    [    DW-1 : 0]      dout          ,
  input           [  DW*32-1: 0]      din           ,
  input                               clk           ,
  input                               reset         
  );


  wire  [ DW-1 : 0]    s0    ;
  wire  [ DW-1 : 0]    s1    ;


  adder_tree16 #(.DW(DW)) u0_add16 (
    .dout           ( s0                            ),
    .din            ( din[DW*16*0 +: DW*16]         ),
    .clk            ( clk                           ),
    .reset          ( reset                         )
  );

  adder_tree16 #(.DW(DW)) u1_add16 (
    .dout           ( s1                            ),
    .din            ( din[DW*16*1 +: DW*16]         ),
    .clk            ( clk                           ),
    .reset          ( reset                         )
  );

  //--------------------------------------------------
  //U32
  //--------------------------------------------------
  `ifdef ADD_TREE_IP_FP32
  ADD_PE_FP32 
  u_ADD_PE_FP32 (
    .aclk                 (clk                      ),// input wire aclk
    .s_axis_a_tvalid      (1'b1                     ),// input wire s_axis_a_tvalid
    .s_axis_a_tready      (                         ),// output wire s_axis_a_tready
    .s_axis_a_tdata       (s0                       ),// input wire [31 : 0] s_axis_a_tdata
    .s_axis_b_tvalid      (1'b1                     ),// input wire s_axis_b_tvalid
    .s_axis_b_tready      (                         ),// output wire s_axis_b_tready
    .s_axis_b_tdata       (s1                       ),// input wire [31 : 0] s_axis_b_tdata
    .m_axis_result_tvalid (                         ),// output wire m_axis_result_tvalid
    .m_axis_result_tdata  (dout                     ) // output wire [31 : 0] m_axis_result_tdata
  );
 `elsif ADD_TREE_IP_BF16
  ADD_PE_BF16 
  u_ADD_PE_BF16 (
    .aclk                 (clk                      ),// input  wire aclk
    .s_axis_a_tvalid      (1'b1                     ),// input  wire s_axis_a_tvalid
    .s_axis_a_tready      (                         ),// output wire s_axis_a_tready
    .s_axis_a_tdata       (s0                       ),// input  wire [15 : 0] s_axis_a_tdata
    .s_axis_b_tvalid      (1'b1                     ),// input  wire s_axis_b_tvalid
    .s_axis_b_tready      (                         ),// output wire s_axis_b_tready
    .s_axis_b_tdata       (s1                       ),// input  wire [15 : 0] s_axis_b_tdata
    .m_axis_result_tvalid (                         ),// output wire m_axis_result_tvalid
    .m_axis_result_tdata  (dout                     ) // output wire [15 : 0] m_axis_result_tdata
  );
 `elsif ADD_TREE_USER_FP32
  pe_add_fp32
  u_pe_add_fp32(
    .clk                  (clk                      ),
    .x1                   (s0                       ),
    .x2                   (s1                       ),
    .y                    (dout                     )
  );
 `elsif ADD_TREE_USER_BF16
  pe_add_bf16
  u_pe_add_bf16(
    .clk                  (clk                      ),
    .x1                   (s0                       ),
    .x2                   (s1                       ),
    .y                    (dout                     )
  );
  `endif
  
  
  
endmodule

 //----------------------------------------------------------------add16
module adder_tree16 #(parameter DW=32) (
  output  wire    [   DW-1 : 0]       dout          ,
  input           [   DW*16-1 : 0]    din           ,
  input                               clk           ,
  input                               reset         
  );

  wire  [ DW-1 : 0]    s0    ;
  wire  [ DW-1 : 0]    s1    ;

  adder_tree8 #(.DW(DW)) u0_add8 (
    .dout           ( s0                            ),
    .din            ( din[DW*8*0+: DW*8]            ),
    .clk            ( clk                           ),
    .reset          ( reset                         )
  );

  adder_tree8 #(.DW(DW)) u1_add8 (
    .dout           ( s1                            ),
    .din            ( din[DW*8*1+: DW*8]            ),
    .clk            ( clk                           ),
    .reset          ( reset                         )
  );

  //--------------------------------------------------
  //U16
  //--------------------------------------------------
  `ifdef ADD_TREE_IP_FP32
  ADD_PE_FP32 
  u_ADD_PE_FP32 (
    .aclk                 (clk                      ),// input wire aclk
    .s_axis_a_tvalid      (1'b1                     ),// input wire s_axis_a_tvalid
    .s_axis_a_tready      (                         ),// output wire s_axis_a_tready
    .s_axis_a_tdata       (s0                       ),// input wire [31 : 0] s_axis_a_tdata
    .s_axis_b_tvalid      (1'b1                     ),// input wire s_axis_b_tvalid
    .s_axis_b_tready      (                         ),// output wire s_axis_b_tready
    .s_axis_b_tdata       (s1                       ),// input wire [31 : 0] s_axis_b_tdata
    .m_axis_result_tvalid (                         ),// output wire m_axis_result_tvalid
    .m_axis_result_tdata  (dout                     ) // output wire [31 : 0] m_axis_result_tdata
  );
 `elsif ADD_TREE_IP_BF16
  ADD_PE_BF16 
  u_ADD_PE_BF16 (
    .aclk                 (clk                      ),// input  wire aclk
    .s_axis_a_tvalid      (1'b1                     ),// input  wire s_axis_a_tvalid
    .s_axis_a_tready      (                         ),// output wire s_axis_a_tready
    .s_axis_a_tdata       (s0                       ),// input  wire [15 : 0] s_axis_a_tdata
    .s_axis_b_tvalid      (1'b1                     ),// input  wire s_axis_b_tvalid
    .s_axis_b_tready      (                         ),// output wire s_axis_b_tready
    .s_axis_b_tdata       (s1                       ),// input  wire [15 : 0] s_axis_b_tdata
    .m_axis_result_tvalid (                         ),// output wire m_axis_result_tvalid
    .m_axis_result_tdata  (dout                     ) // output wire [15 : 0] m_axis_result_tdata
  );
 `elsif ADD_TREE_USER_FP32
  pe_add_fp32
  u_pe_add_fp32(
    .clk                  (clk                      ),
    .x1                   (s0                       ),
    .x2                   (s1                       ),
    .y                    (dout                     )
  );
 `elsif ADD_TREE_USER_BF16
  pe_add_bf16
  u_pe_add_bf16(
    .clk                  (clk                      ),
    .x1                   (s0                       ),
    .x2                   (s1                       ),
    .y                    (dout                     )
  );
  `endif


endmodule


 //----------------------------------------------------------------add8
module adder_tree8 #(parameter DW=32) (
  output  wire    [   DW  -1 : 0]     dout          ,
  input           [   DW*8-1 : 0]     din           ,
  input                               clk           ,
  input                               reset         
  );

  wire [ DW-1 : 0]     s0   ;
  wire [ DW-1 : 0]     s1   ;

  adder_tree4 #(.DW(DW)) u0_add4 (
    .dout           ( s0                            ),
    .din            ( din[DW*4*0 +: DW*4]           ),
    .clk            ( clk                           ),
    .reset          ( reset                         )
  );

  adder_tree4 #(.DW(DW)) u1_add4 (
    .dout           ( s1                            ),
    .din            ( din[DW*4*1 +: DW*4]           ),
    .clk            ( clk                           ),
    .reset          ( reset                         )
  );
  
  //--------------------------------------------------
  //U8
  //--------------------------------------------------
  `ifdef ADD_TREE_IP_FP32
  ADD_PE_FP32 
  u_ADD_PE_FP32 (
    .aclk                 (clk                      ),// input wire aclk
    .s_axis_a_tvalid      (1'b1                     ),// input wire s_axis_a_tvalid
    .s_axis_a_tready      (                         ),// output wire s_axis_a_tready
    .s_axis_a_tdata       (s0                       ),// input wire [31 : 0] s_axis_a_tdata
    .s_axis_b_tvalid      (1'b1                     ),// input wire s_axis_b_tvalid
    .s_axis_b_tready      (                         ),// output wire s_axis_b_tready
    .s_axis_b_tdata       (s1                       ),// input wire [31 : 0] s_axis_b_tdata
    .m_axis_result_tvalid (                         ),// output wire m_axis_result_tvalid
    .m_axis_result_tdata  (dout                     ) // output wire [31 : 0] m_axis_result_tdata
  );
 `elsif ADD_TREE_IP_BF16
  ADD_PE_BF16 
  u_ADD_PE_BF16 (
    .aclk                 (clk                      ),// input  wire aclk
    .s_axis_a_tvalid      (1'b1                     ),// input  wire s_axis_a_tvalid
    .s_axis_a_tready      (                         ),// output wire s_axis_a_tready
    .s_axis_a_tdata       (s0                       ),// input  wire [15 : 0] s_axis_a_tdata
    .s_axis_b_tvalid      (1'b1                     ),// input  wire s_axis_b_tvalid
    .s_axis_b_tready      (                         ),// output wire s_axis_b_tready
    .s_axis_b_tdata       (s1                       ),// input  wire [15 : 0] s_axis_b_tdata
    .m_axis_result_tvalid (                         ),// output wire m_axis_result_tvalid
    .m_axis_result_tdata  (dout                     ) // output wire [15 : 0] m_axis_result_tdata
  );
 `elsif ADD_TREE_USER_FP32
  pe_add_fp32
  u_pe_add_fp32(
    .clk                  (clk                      ),
    .x1                   (s0                       ),
    .x2                   (s1                       ),
    .y                    (dout                     )
  );
 `elsif ADD_TREE_USER_BF16
  pe_add_bf16
  u_pe_add_bf16(
    .clk                  (clk                      ),
    .x1                   (s0                       ),
    .x2                   (s1                       ),
    .y                    (dout                     )
  );
  `endif


endmodule



module adder_tree4 #(parameter DW=32) (
  output  wire    [   DW  -1 : 0]     dout          ,
  input           [   DW*4-1 : 0]     din           ,
  input                               clk           ,
  input                               reset         
  );
  
  wire [ DW-1: 0]           s0                      ;
  wire [ DW-1: 0]           s1                      ;

  //--------------------------------------------------
  //U4_0
  //--------------------------------------------------
  `ifdef ADD_TREE_IP_FP32
  ADD_PE_FP32 
  u0_ADD_PE_FP32 (
    .aclk                 (clk                      ),// input wire aclk
    .s_axis_a_tvalid      (1'b1                     ),// input wire s_axis_a_tvalid
    .s_axis_a_tready      (                         ),// output wire s_axis_a_tready
    .s_axis_a_tdata       (din[DW*0 +: DW]          ),// input wire [31 : 0] s_axis_a_tdata
    .s_axis_b_tvalid      (1'b1                     ),// input wire s_axis_b_tvalid
    .s_axis_b_tready      (                         ),// output wire s_axis_b_tready
    .s_axis_b_tdata       (din[DW*1 +: DW]          ),// input wire [31 : 0] s_axis_b_tdata
    .m_axis_result_tvalid (                         ),// output wire m_axis_result_tvalid
    .m_axis_result_tdata  (s0                       ) // output wire [31 : 0] m_axis_result_tdata
  );
 `elsif ADD_TREE_IP_BF16
  ADD_PE_BF16 
  u0_ADD_PE_BF16 (
    .aclk                 (clk                      ),// input  wire aclk
    .s_axis_a_tvalid      (1'b1                     ),// input  wire s_axis_a_tvalid
    .s_axis_a_tready      (                         ),// output wire s_axis_a_tready
    .s_axis_a_tdata       (din[DW*0 +: DW]          ),// input  wire [15 : 0] s_axis_a_tdata
    .s_axis_b_tvalid      (1'b1                     ),// input  wire s_axis_b_tvalid
    .s_axis_b_tready      (                         ),// output wire s_axis_b_tready
    .s_axis_b_tdata       (din[DW*1 +: DW]          ),// input  wire [15 : 0] s_axis_b_tdata
    .m_axis_result_tvalid (                         ),// output wire m_axis_result_tvalid
    .m_axis_result_tdata  (s0                       ) // output wire [15 : 0] m_axis_result_tdata
  );
 `elsif ADD_TREE_USER_FP32
  pe_add_fp32
  u0_pe_add_fp32(
    .clk                  (clk                      ),
    .x1                   (din[DW*0 +: DW]          ),
    .x2                   (din[DW*1 +: DW]          ),
    .y                    (s0                       )
  );
 `elsif ADD_TREE_USER_BF16
  pe_add_bf16
  u0_pe_add_bf16(
    .clk                  (clk                      ),
    .x1                   (din[DW*0 +: DW]          ),
    .x2                   (din[DW*1 +: DW]          ),
    .y                    (s0                       )
  );
  `endif

  //--------------------------------------------------
  //U4_1
  //--------------------------------------------------
  `ifdef ADD_TREE_IP_FP32
  ADD_PE_FP32 
  u1_ADD_PE_FP32 (
    .aclk                 (clk                      ),// input wire aclk
    .s_axis_a_tvalid      (1'b1                     ),// input wire s_axis_a_tvalid
    .s_axis_a_tready      (                         ),// output wire s_axis_a_tready
    .s_axis_a_tdata       (din[DW*2 +: DW]          ),// input wire [31 : 0] s_axis_a_tdata
    .s_axis_b_tvalid      (1'b1                     ),// input wire s_axis_b_tvalid
    .s_axis_b_tready      (                         ),// output wire s_axis_b_tready
    .s_axis_b_tdata       (din[DW*3 +: DW]          ),// input wire [31 : 0] s_axis_b_tdata
    .m_axis_result_tvalid (                         ),// output wire m_axis_result_tvalid
    .m_axis_result_tdata  (s1                       ) // output wire [31 : 0] m_axis_result_tdata
  );
 `elsif ADD_TREE_IP_BF16
  ADD_PE_BF16 
  u1_ADD_PE_BF16 (
    .aclk                 (clk                      ),// input  wire aclk
    .s_axis_a_tvalid      (1'b1                     ),// input  wire s_axis_a_tvalid
    .s_axis_a_tready      (                         ),// output wire s_axis_a_tready
    .s_axis_a_tdata       (din[DW*2 +: DW]          ),// input  wire [15 : 0] s_axis_a_tdata
    .s_axis_b_tvalid      (1'b1                     ),// input  wire s_axis_b_tvalid
    .s_axis_b_tready      (                         ),// output wire s_axis_b_tready
    .s_axis_b_tdata       (din[DW*3 +: DW]          ),// input  wire [15 : 0] s_axis_b_tdata
    .m_axis_result_tvalid (                         ),// output wire m_axis_result_tvalid
    .m_axis_result_tdata  (s1                       ) // output wire [15 : 0] m_axis_result_tdata
  );
 `elsif ADD_TREE_USER_FP32
  pe_add_fp32
  u1_pe_add_fp32(
    .clk                  (clk                      ),
    .x1                   (din[DW*2 +: DW]          ),
    .x2                   (din[DW*3 +: DW]          ),
    .y                    (s1                       )
  );
 `elsif ADD_TREE_USER_BF16
  pe_add_bf16
  u1_pe_add_bf16(
    .clk                  (clk                      ),
    .x1                   (din[DW*2 +: DW]          ),
    .x2                   (din[DW*3 +: DW]          ),
    .y                    (s1                       )
  );
  `endif

  
  
  //--------------------------------------------------
  //U4_2 
  //--------------------------------------------------
  `ifdef ADD_TREE_IP_FP32
  ADD_PE_FP32 
  u2_ADD_PE_FP32 (
    .aclk                 (clk                      ),// input wire aclk
    .s_axis_a_tvalid      (1'b1                     ),// input wire s_axis_a_tvalid
    .s_axis_a_tready      (                         ),// output wire s_axis_a_tready
    .s_axis_a_tdata       (s0                       ),// input wire [31 : 0] s_axis_a_tdata
    .s_axis_b_tvalid      (1'b1                     ),// input wire s_axis_b_tvalid
    .s_axis_b_tready      (                         ),// output wire s_axis_b_tready
    .s_axis_b_tdata       (s1                       ),// input wire [31 : 0] s_axis_b_tdata
    .m_axis_result_tvalid (                         ),// output wire m_axis_result_tvalid
    .m_axis_result_tdata  (dout                     ) // output wire [31 : 0] m_axis_result_tdata
  );
 `elsif ADD_TREE_IP_BF16
  ADD_PE_BF16 
  u2_ADD_PE_BF16 (
    .aclk                 (clk                      ),// input  wire aclk
    .s_axis_a_tvalid      (1'b1                     ),// input  wire s_axis_a_tvalid
    .s_axis_a_tready      (                         ),// output wire s_axis_a_tready
    .s_axis_a_tdata       (s0                       ),// input  wire [15 : 0] s_axis_a_tdata
    .s_axis_b_tvalid      (1'b1                     ),// input  wire s_axis_b_tvalid
    .s_axis_b_tready      (                         ),// output wire s_axis_b_tready
    .s_axis_b_tdata       (s1                       ),// input  wire [15 : 0] s_axis_b_tdata
    .m_axis_result_tvalid (                         ),// output wire m_axis_result_tvalid
    .m_axis_result_tdata  (dout                     ) // output wire [15 : 0] m_axis_result_tdata
  );
 `elsif ADD_TREE_USER_FP32
  pe_add_fp32
  u2_pe_add_fp32(
    .clk                  (clk                      ),
    .x1                   (s0                       ),
    .x2                   (s1                       ),
    .y                    (dout                     )
  );
 `elsif ADD_TREE_USER_BF16
 //6cycle
  pe_add_bf16
  u2_pe_add_bf16(
    .clk                  (clk                      ),
    .x1                   (s0                       ),
    .x2                   (s1                       ),
    .y                    (dout                     )
  );
  `endif



endmodule


