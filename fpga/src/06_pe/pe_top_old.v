`timescale 1ns / 1ps
// -----------------------------------------------------------------------------
// UCLA EDA LAB
// -----------------------------------------------------------------------------
// Engineer       : Chen Wu
// Design Name    : opu series
// Module Name    : pe_array_top
// Target Devices : 325t
// Tool Versions  : Vivado 2020.1, Modelsim 2019.4
// Description    : 
//    Top module for PE Array, all the PE performs in the same way.
//    Constraints: control signals "mode", "output_num", "trunc_pos" should
//    last till the output finishes
//
// Revision       :
// Version        Date        Author        Descriptin
// 1.0            2021-04-04  Chen Wu       Initial version
// 2.0            2023-08-25  Shaoqiang     Simulation 97 layers,and       
//                                          implementation on FPGA of U200.
// -----------------------------------------------------------------------------


module pe_top_old #(
  // 3'b000 -- int8
  // 3'b001 -- int16
  // 3'b010 -- mixed precision
  // other  -- reserved
  parameter     PRECISION   =   3'b001                                        ,

  // MUL_NUM defines the total number of multipliers in the mul_array
  // for mixed precision, it defines the total number of INT8 multipliers
  parameter     MUL_NUM     =   512                                           ,

  // DIN_NUM defines the number of input to be added at most 
  parameter     DIN_NUM     =   32                                            ,

  // DOUT_NUM defines the number of output at most
  parameter     DOUT_NUM    =   32                                            ,

  // PE_NUM defines the number of PEs
  parameter     PE_NUM      =   1                                             ,

  // XDW defines the data width for input x array
  localparam    XDW         =   PRECISION == 3'b000 ?  8 * MUL_NUM :
                                PRECISION == 3'b001 ? 16 * MUL_NUM :
                                PRECISION == 3'b010 ?  8 * MUL_NUM :
                                                      18 * MUL_NUM            ,

  // YDW defines the data width for input y array
  localparam    YDW         =   PRECISION == 3'b000 ?  4 * MUL_NUM :
                                PRECISION == 3'b001 ? 16 * MUL_NUM :
                                PRECISION == 3'b010 ?  4 * MUL_NUM :
                                                      18 * MUL_NUM            ,

  // PDW defines the data width for product
  localparam    PDW         =   PRECISION == 3'b000 ? 16 :
                                PRECISION == 3'b001 ? 32 :
                                PRECISION == 3'b010 ? 16 : 16                 ,

  // ADD_STAGE defines the number of adder tree stages
  localparam    ADD_STAGE   =   $clog2(DIN_NUM)                               ,

  // TREENUM defines the number of adder trees
  localparam    TREE_NUM    =   PRECISION == 3'b010 ? 2*MUL_NUM / DIN_NUM :
                                                        MUL_NUM / DIN_NUM     ,

  // ADD_DW defines the data width of inputs of adder tree
  // For mixed precision, MUL_NUM indicates the number of INT8 multipliers
  localparam    ADD_DW      =   PRECISION == 3'b010 ? 9 : PDW                 ,
  
  // ADD_ODW defines the data width of outputs of adder tree
  localparam    ADD_ODW     =   PRECISION == 3'b010 ? ADD_DW*2+ADD_STAGE-3 :
                                                      ADD_DW+ADD_STAGE        ,

  // ODW defines the data width of outputs
  localparam    ODW         =   PRECISION == 3'b000 ? 26 : 
                                PRECISION == 3'b001 ? 42 : 
                                PRECISION == 3'b010 ? 16 : ADD_ODW            

  ) (
  output  wire    [ODW*DOUT_NUM*PE_NUM-1 : 0]   dout                          ,
  output  wire                                  dout_vld                      ,
  output  wire                                  done                          ,

  input           [         XDW*PE_NUM-1 : 0]   din_x                         ,
  input           [         YDW*PE_NUM-1 : 0]   din_y                         ,
  input                                         din_vld                       ,
  input                                         din_done                      ,
  input                                         mode                          ,
  input           [                    2 : 0]   output_num                    ,
  input           [                    2 : 0]   trunc_pos                     ,

  input                                         clk                           ,
  input                                         reset                                
  );

  reg                      dout_vld_s0      =0           ;
  reg                      dout_vld_s1      =0           ;
  wire                     dout_vld_s2                   ;
  reg                      done_s0          =0           ;
  reg                      done_s1          =0           ;
  wire                     done_s2                       ;

  generate for ( genvar i=0; i < PE_NUM; i=i+1 ) begin: PE512
    (*keep_hierarchy="yes" *)
    pe_unit_old #(
      .PRECISION              ( PRECISION                                     ),//1
      .MUL_NUM                ( MUL_NUM                                       ),//512
      .DIN_NUM                ( DIN_NUM                                       ),//32
      .DOUT_NUM               ( DOUT_NUM                                      ) //32
    ) PE (
      .dout                   ( dout[ODW*DOUT_NUM*i +: ODW*DOUT_NUM]          ),//42*32=1344
      .din_x                  ( din_x[XDW*i +: XDW]                           ),//8192
      .din_y                  ( din_y[YDW*i +: YDW]                           ),//8192
      .mode                   ( mode                                          ),
      .output_num             ( output_num                                    ),
      .trunc_pos              ( trunc_pos                                     ),

      .clk                    ( clk                                           ),
      .reset                  ( reset                                         )
      );
  end
  endgenerate

  // Generate dout_vld & done only by delay.
  // All the PEs perform in the same way.
  // 5 cycles for mul_array
  // 1 cycle to feed into adder tree
  // ADD_STAGE cycles for adder tree 
  //(also controlled by output num if select inter stage outputs) 
  // 1 cycle to get results from adder tree
  // 1 cycle for truncate
  (*keep_hierarchy="yes" *)
  dly_cell #(
    .DW           ( 1                       ), 
    .DLY          ( 5+1+ADD_STAGE-2+1+1+1+1 )
  ) dly_outvd (
    .dout         ( dout_vld_s2             ),
    .din          ( din_vld                 ),

    .clk          ( clk                     ),
    .reset        ( reset                   )
  );
 
  (*keep_hierarchy="yes" *)
  dly_cell #(
    .DW           ( 1                       ), 
    .DLY          ( 5+1+ADD_STAGE-2+1+1+1+1 )
  ) dly_done (
    .dout         ( done_s2                 ),

    .din          ( din_done                ),

    .clk          ( clk                     ),
    .reset        ( reset                   )
  );

  always @(posedge clk) begin
    if ( reset ) begin
      dout_vld_s1   <=  1'b0                ;
      dout_vld_s0   <=  1'b0                ;
      done_s1       <=  1'b0                ;
      done_s0       <=  1'b0                ;
    end else begin
      dout_vld_s1   <=  dout_vld_s2         ;
      dout_vld_s0   <=  dout_vld_s1         ;
      done_s1       <=  done_s2             ;
      done_s0       <=  done_s1             ;
    end
  end

if ( PRECISION == 3'b010 ) begin
  assign dout_vld = output_num == 3'b101 ? dout_vld_s0 : 1'b0   ;
  assign done     = output_num == 3'b101 ? done_s0     : 1'b0   ;
end else begin
  assign dout_vld = output_num == 3'b011 ? dout_vld_s0 :
                    output_num == 3'b100 ? dout_vld_s1 :
                    output_num == 3'b101 ? dout_vld_s2 : 1'b0   ;
  assign done     = output_num == 3'b011 ? done_s0     :
                    output_num == 3'b100 ? done_s1     :
                    output_num == 3'b101 ? done_s2     : 1'b0   ;
end





//----------------------------------------------------------------------------
reg [8192-1:0]din_x1=0;
reg [8192-1:0]din_y1=0;

always @(posedge clk)
begin
din_x1 <= din_x;
din_y1 <= din_y;
end





reg [15:0]test_pe_ia[511:0];
reg [15:0]test_pe_ib[511:0];
reg [36:0]test_pe_ou[15 :0];

integer ii;

always @(*)
begin
for(ii=0;ii<512;ii=ii+1) test_pe_ia[ii]=din_x1[16*ii+:16];
for(ii=0;ii<512;ii=ii+1) test_pe_ib[ii]=din_y1[16*ii+:16];
for(ii=0;ii<16 ;ii=ii+1) test_pe_ou[ii]=dout[42*ii+:42];

end


endmodule 