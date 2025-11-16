`timescale 1ns / 1ps
// -----------------------------------------------------------------------------
// UCLA EDA LAB
// -----------------------------------------------------------------------------
// Engineer       : Chen Wu
// Design Name    : opu series
// Module Name    : arithmetic_unit
// Target Devices : 325t
// Tool Versions  : Vivado 2020.1, Modelsim 2019.4
// Description    : 
//    In general, it performs p = x * y, for more than one multipliers, 
//    y is shared;
//
//    Compact different number of low precision multiplications into one dsp.
//    one DSP48E1 is configured as (A+D)*B+C, assign different A,B,C,D to have:
//      one int16 multiplication
//      two int8 multiplicaiton
//      mixed precision, support both int8 and int4
//
//    Delay: 4 cycles
// Revision       :
// Version        Date        Author        Descriptin
// 1.0            2021-04-04  Chen Wu       Initial version
// 2.0            2023-09-11  Shaoqiang     Simulation 97 layers,and       
//                                          implementation on FPGA of U200.
// -----------------------------------------------------------------------------

`include "core_param.vh"

module dsp_wrap_old #(
  // PRECISION indicates the precision of multiplier and multiplcand
  // 3'b000 -- int8
  // 3'b001 -- int16
  // 3'b010 -- mixed precision
  // other  -- reserved
  parameter     PRECISION   =   3'b000                              ,//1

  // MUL_NUM indicates the number of multipliers in one DSP
  // with given precision
  // 2 -- int8
  // 1 -- int16
  // 2 -- mixed precision (at least)
  // 1 -- other reserved
  parameter     MUL_NUM     =   PRECISION == 3'b000 ? 2 :
                                PRECISION == 3'b001 ? 1 :
                                PRECISION == 3'b010 ? 2 :
                                                      1             ,//1
  
  // DW indicates the bit width of multipliers and multiplicands with
  // given precision
  // 8 -- int8
  // 16 -- int16
  // 8 -- mixed precision (at most)
  // 18 -- other reserved
  // Product doubles the bit with after multiplication
  parameter     DW          =   PRECISION == 3'b000 ? 8  :
                                PRECISION == 3'b001 ? 16 :
                                PRECISION == 3'b010 ? 8  :
                                                      18            //16
  ) (
  output  reg     [DW*MUL_NUM*2-1 : 0]      p         =0            ,//1 reg +4 DSP +1 output=6

  input           [DW*MUL_NUM  -1 : 0]      x                       ,
  input           [DW*MUL_NUM  -1 : 0]      y                       ,
  input                                     mode                    ,

  input                                     clk                     ,
  input                                     reset           
  );
  
  

  localparam                                HDW =DW/2               ;//8


  (*dont_touch="true"*)reg   [24 : 0]  dsp_a = 0                    ;
  (*dont_touch="true"*)reg   [17 : 0]  dsp_b = 0                    ;
  //reg               [47 : 0]         dsp_c = 0                    ;
  //reg               [24 : 0]         dsp_d = 0                    ;
  (*dont_touch="true"*)wire  [47 : 0]         dsp_p                 ;

//-----------------------------------------------------------------------
//******* Select implementation for different parameters. ***************
//-----------------------------------------------------------------------

if(PRECISION==3'b000) begin//------------------------------------------000,int8
        reg  [47 : 0]  dsp_c_nd = 0            ;

        always @(posedge clk) begin
          dsp_a     <=  $signed(x[DW-1   -: DW])                    ;
          //dsp_d     <=  $signed(x[DW*2-1 -: DW]) << 16              ;
          dsp_b     <=  $signed(y)                                  ;
        end

        always @(posedge clk) begin
          dsp_c_nd  <=  ((x[DW-1]^y[DW-1])&(|x[DW-1-:DW])&(|y[DW-1-:DW]))?
                                          48'h0000_0001_0000 : 48'h0;
          //dsp_c     <=  dsp_c_nd                                    ;
        end
end else
if(PRECISION==3'b001) begin//------------------------------------------001,int16
        always @(posedge clk) begin
          dsp_a   <=  $signed(x)                                     ;
          dsp_b   <=  $signed(y)                                     ;
          //dsp_c   <=  0                                              ;
          //dsp_d   <=  0                                              ;
        end
end else 
if(PRECISION==3'b010) begin//------------------------------------------010,mixed
    wire   [ 6 : 0]      dsp_a_part0           ;
    wire   [ 6 : 0]      dsp_a_part1           ;
    wire   [ 6 : 0]      dsp_a_part2           ;
    reg    [ 2 : 0]      dsp_c_flag  = 0       ;
    reg    [47 : 0]      dsp_c_nd    = 0       ;

    assign dsp_a_part0  = $signed(x[HDW-2 -: HDW-1])                 ;
    assign dsp_a_part1  = {{(8-HDW){x[HDW*2-2]}}, x[HDW*2-2 -: HDW-1]}-{6'h0, x[HDW-2]}         ;
    assign dsp_a_part2  = {{(8-HDW){x[HDW*3-2]}}, x[HDW*3-2 -: HDW-1]}-{6'h0, dsp_a_part1[6]}   ;

    always @(posedge clk) begin
      dsp_c_flag[0] <= (x[HDW*1-2] ^ y[HDW-1]) & (|x[HDW*1-2 -: HDW-1]) & (|y[HDW-1 -: HDW])    ; 
      dsp_c_flag[1] <= (x[HDW*2-2] ^ y[HDW-1]) & (|x[HDW*2-2 -: HDW-1]) & (|y[HDW-1 -: HDW])    ;
      dsp_c_flag[2] <= (x[HDW*3-2] ^ y[HDW-1]) & (|x[HDW*3-2 -: HDW-1]) & (|y[HDW-1 -: HDW])    ;
    end

    always @(posedge clk) begin
      dsp_c_nd  <=  ((x[DW-1]^y[DW-1])&(|x[DW-1-:DW])&(|y[DW-1-:DW]))?
                                    48'h0000_0001_0000 : 48'h0        ;
    end

    always @(posedge clk) begin
      if ( mode )
        dsp_a <= $signed({dsp_a_part2, dsp_a_part1, dsp_a_part0})     ;
      else
        dsp_a <= $signed(x[DW-1-:DW])                                 ;
    end

    always @(posedge clk) begin
      if ( mode )
        dsp_b <= $signed(y[HDW-1-:HDW])                               ;
      else
        dsp_b <= $signed(y)                                           ;
    end

    /*
    always @(posedge clk) begin
      if ( mode )
        dsp_d <= $signed(x[HDW*4-2 -: HDW-1]) << 21                   ;
      else
        dsp_d <= $signed(x[ DW*2-1 -: DW   ]) << 16                   ;
    end
    */
    /*
    always @(posedge clk)
      if ( mode ) 
        case ( dsp_c_flag )
        3'h0  : dsp_c <=  {26'h0, 22'h00_0000}                         ;
        3'h1  : dsp_c <=  {26'h0, 22'h00_0080}                         ;
        3'h2  : dsp_c <=  {26'h0, 22'h00_4000}                         ;
        3'h3  : dsp_c <=  {26'h0, 22'h00_4080}                         ;
        3'h4  : dsp_c <=  {26'h0, 22'h20_0000}                         ;
        3'h5  : dsp_c <=  {26'h0, 22'h20_0080}                         ;
        3'h6  : dsp_c <=  {26'h0, 22'h20_4000}                         ;
        3'h7  : dsp_c <=  {26'h0, 22'h20_4080}                         ;
        endcase
      else
        dsp_c     <=  dsp_c_nd                                         ;
     */
end//-------------------------------------------------------------------end


  (*dont_touch="true"*) reg reset_dsp=1                     ;
  always @(posedge clk) reset_dsp <=reset                   ;

`ifdef SIM_DSP_PE
//---------------------------------------------------------------------
//Only used during simulation.
//--------------------------------------------------------------------
  (*dont_touch="true"*)wire [47 : 0] dsp_p_test_in          ;
  (*dont_touch="true"*)wire [47 : 0] dsp_p_test_out         ;
  assign   dsp_p_test_in= $signed(dsp_a)*$signed(dsp_b)     ;
  assign   dsp_p=dsp_p_test_out                             ;
  dly_cell #(
    .DW                   ( 48                              ),
    .DLY                  ( 4                               )
  ) DSP_SIM (
    .dout                 ( dsp_p_test_out                  ),
    .din                  ( dsp_p_test_in                   ),
    .clk                  ( clk                             ),
    .reset                ( reset_dsp                       )
  );
`else 
//-----------------------------------------------------------------------
//**************** Instantiating DSP Multiplier Unit ********************
//-----------------------------------------------------------------------
//Multiplying two fixed-point data, they results ixed-point is the add 
//of the two data fixed-point,and the bit width also is add two data
//eg Q_25_13 * eg Q_18_13 = eg Q_43_26---->eg Q_48_26
//the DSP48 is 4 cycle : (A+D)*B+C
  (*keep_hierarchy="yes" *)
  DSP_pe DSP (
    .SCLR   ( reset_dsp ),
    .CLK    ( clk       ),//
    .A      ( dsp_a     ),//[24 : 0],eg Q_25_13
    .B      ( dsp_b     ),//[17 : 0],eg Q_18_13
    .P      ( dsp_p     ) //[47 : 0],eg Q_48_26
  );     
`endif



//-----------------------------------------------------------------------
// output 1 clock
//-----------------------------------------------------------------------
if ( PRECISION == 3'b000 ) begin
    always @(posedge clk) p <= dsp_p[31:0]                              ;
end else 
if ( PRECISION == 3'b001 ) begin
    always @(posedge clk) p <= dsp_p[31:0]                              ;
end else 
if ( PRECISION == 3'b010 ) begin
    always @(posedge clk)
    if(mode)              p <={dsp_p[27], dsp_p[27:21],
                               dsp_p[20], dsp_p[20:14],
                               dsp_p[13], dsp_p[13: 7],
                               dsp_p[ 6], dsp_p[ 6: 0]}                 ; 
    else                  p<=  dsp_p[31:0]                              ;
  end 

endmodule