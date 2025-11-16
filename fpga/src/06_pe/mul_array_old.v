`timescale 1ns / 1ps
// -----------------------------------------------------------------------------
// UCLA EDA LAB
// -----------------------------------------------------------------------------
// Engineer       : Chen Wu
// Design Name    : opu series
// Module Name    : mul_array
// Target Devices : 325t
// Tool Versions  : Vivado 2020.1, Modelsim 2019.4
// Description    : 
//    In general, it has a multiply array to perform p = x * y.
//
//    Delay: 5 cycles
// Revision       :
// Version        Date        Author        Descriptin
// 1.0            2021-04-04  Chen Wu       Initial version
// 2.0            2023-09-11  Shaoqiang     Simulation 97 layers,and       
//                                          implementation on FPGA of U200.
// -----------------------------------------------------------------------------

module mul_array_old #(
  // PRECISION indicates the precision of multiplier and multiplcand
  // 3'b000 -- int8
  // 3'b001 -- int16
  // 3'b010 -- mixed precision
  // other  -- reserved
  parameter     PRECISION   =   3'b000                                ,

  // MUL_NUM defines the total number of multipliers in the mul_array
  // for mixed precision, it defines the total number of INT8 multipliers
  parameter     MUL_NUM     =   1024                                  ,

  // XDW defines the data width for input x array
  parameter     XDW         =   PRECISION == 3'b000 ?  8 * MUL_NUM :
                                PRECISION == 3'b001 ? 16 * MUL_NUM :
                                PRECISION == 3'b010 ?  8 * MUL_NUM :
                                                      18 * MUL_NUM    ,

  // YDW defines the data width for input y array
  parameter     YDW         =   PRECISION == 3'b000 ?  4 * MUL_NUM :
                                PRECISION == 3'b001 ? 16 * MUL_NUM :
                                PRECISION == 3'b010 ?  4 * MUL_NUM :
                                                      18 * MUL_NUM    ,

  // PDW defines the data width for output p array
  parameter     PDW         =   PRECISION == 3'b000 ? 16 * MUL_NUM :
                                PRECISION == 3'b001 ? 32 * MUL_NUM :
                                PRECISION == 3'b010 ? 16 * MUL_NUM :
                                                      36 * MUL_NUM     
  
  ) (
  output  reg     [PDW-1 : 0]               array_p = 0               ,
  input           [XDW-1 : 0]               array_x                   ,
  input           [YDW-1 : 0]               array_y                   ,
  input                                     mode                      ,
  input                                     clk                       ,
  input           [32-1  : 0]               reset                     
  );
  
  localparam    DSP_NUM     =   PRECISION == 3'b000 ?  MUL_NUM / 2    :
                                PRECISION == 3'b001 ?  MUL_NUM / 1    :
                                PRECISION == 3'b010 ?  MUL_NUM / 2    :
                                                       MUL_NUM        ;
                                                                    
  localparam    XDW_S       =   XDW / DSP_NUM ;
  localparam    YDW_S       =   YDW / DSP_NUM ; 
  localparam    PDW_S       =   PDW / DSP_NUM ;
  wire          [PDW-1 : 0]     arith_p       ;
 
//-----------------------------------------------------------------------
//************** Instantiating multi wrap ,base is dsp ******************
//-----------------------------------------------------------------------
// for 5 cycles
// eg Q_16_13 * eg Q_16_13 ---->eg Q_32_26
  (*dont_touch="true"*) reg [DSP_NUM-1:0]reset_r={DSP_NUM{1'b1}}      ;
  always @(posedge clk) reset_r<={16{reset}}                          ;
  
  generate for ( genvar i=0; i <DSP_NUM; i=i+1 ) begin: DSP
  (*dont_touch="true"*) reg       reset_r1=1                          ;
  always @(posedge clk) reset_r1<=reset_r[i]                          ;
    (*keep_hierarchy="yes" *)
    dsp_wrap_old #( .PRECISION ( PRECISION                                )
    ) dsp_wrap (
      .p              ( arith_p[PDW_S*i +: PDW_S]                     ),//bit width 32*i+32-->32
      .x              ( array_x[XDW_S*i +: XDW_S]                     ),//bit width 16*i+16-->16
      .y              ( array_y[YDW_S*i +: YDW_S]                     ),//bit width 16*i+16-->16
      .mode           ( mode                                          ),
      .clk            ( clk                                           ),
      .reset          ( reset_r1                                      )
    );
  end
  endgenerate

//-----------------------------------------------------------------------
//********* Select output data for different parameters. ***************
//-----------------------------------------------------------------------
generate for ( genvar i=0; i <MUL_NUM; i=i+1 ) begin: OUT
if ( PRECISION == 3'b000 ) begin//-------------------------------------------------------------int8
      always @(posedge clk)
            array_p[PDW_S/2*((i%2)*DSP_NUM+(i/2)%DSP_NUM)+:PDW_S/2] <=
            arith_p[PDW_S/2*i +:PDW_S/2]                               ;
      
end else 
if ( PRECISION == 3'b001 ) begin//-------------------------------------------------------------int16
      always @(posedge clk)
            array_p[PDW_S*i +:PDW_S]<= arith_p[PDW_S*i+:PDW_S]         ;//bit width 32*i+32-->32
      
end else 
if ( PRECISION == 3'b010 ) begin//-------------------------------------------------------------mixed
      always @(posedge clk) begin
            if ( ~mode )
                array_p[PDW_S/2*((i%2)*DSP_NUM+(i/2)%DSP_NUM)+:PDW_S/2] <=
                arith_p[PDW_S/2*i+:PDW_S/2]                             ;
            else
                array_p[PDW_S/4*(((i%2)==0)*(i/2)+((i%2)==1)*(i/2+DSP_NUM*2))+:PDW_S/4]<=
                arith_p[PDW_S/2*i+:PDW_S/4]                             ;
                
                
                array_p[PDW_S/4*(((i%2)==0)*(i/2+DSP_NUM)+((i%2)==1)*(i/2+DSP_NUM*3))+:PDW_S/4]<= 
                arith_p[PDW_S/2*i+PDW_S/4+:PDW_S/4]                     ;
      end
end else//------------------------------------------------------------------------------------reserved
begin
      always @(posedge clk)
        array_p[PDW_S*i +: PDW_S]<=arith_p[PDW_S*i+:PDW_S]               ;
end
end//OUT
endgenerate

endmodule