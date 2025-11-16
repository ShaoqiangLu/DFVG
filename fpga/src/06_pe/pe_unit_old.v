`timescale 1ns / 1ps
// -----------------------------------------------------------------------------
// UCLA EDA LAB
// -----------------------------------------------------------------------------
// Engineer       : Chen Wu
// Design Name    : opu series
// Module Name    : pe
// Target Devices : 325t
// Tool Versions  : Vivado 2020.1, Modelsim 2019.4
// Description    : 
//    Processing inner product
//    Requirement: mode, output_num, trunc_pos should last till the last data 
//    get out from the trunc module.
//
// Revision       :
// Version        Date        Author        Descriptin
// 1.0            2021-04-04  Chen Wu       Initial version
// 1.1            2022-04-07  Chen Wu       Simplify INT16 case
// 2.0            2023-08-25  Shaoqiang     Simulation 97 layers,and       
//                                          implementation on FPGA of U200.
// -----------------------------------------------------------------------------


module pe_unit_old#(
  // PRECISION indicates the precision of multiplier and multiplcand
  // 3'b000 -- int8
  // 3'b001 -- int16
  // 3'b010 -- mixed precision
  // other  -- reserved
  parameter     PRECISION   =   3'b001                                        ,//1

  // MUL_NUM defines the total number of multipliers in the mul_array
  // for mixed precision, it defines the total number of INT8 multipliers
  parameter     MUL_NUM     =   512                                           ,//512

  // DIN_NUM defines the number of input to be added at most 
  parameter     DIN_NUM     =   32                                            ,//32

  // DOUT_NUM defines the number of output at most
  parameter     DOUT_NUM    =   32                                            ,//32

  // XDW defines the data width for input x array
  localparam    XDW         =   PRECISION == 3'b000 ?  8 * MUL_NUM :
                                PRECISION == 3'b001 ? 16 * MUL_NUM :
                                PRECISION == 3'b010 ?  8 * MUL_NUM :
                                                      18 * MUL_NUM            ,//8192

  // YDW defines the data width for input y array
  localparam    YDW         =   PRECISION == 3'b000 ?  4 * MUL_NUM :
                                PRECISION == 3'b001 ? 16 * MUL_NUM :
                                PRECISION == 3'b010 ?  4 * MUL_NUM :
                                                      18 * MUL_NUM            ,//8192

  // PDW defines the data width for product
  localparam    PDW         =   PRECISION == 3'b000 ? 16 :
                                PRECISION == 3'b001 ? 32 :
                                PRECISION == 3'b010 ? 16 : 16                 ,//32

  // ADD_STAGE defines the number of adder tree stages
  localparam    ADD_STAGE   =   $clog2(DIN_NUM)                               ,//5

  // TREENUM defines the number of adder trees
  localparam    TREE_NUM    =   PRECISION == 3'b010 ? 2*MUL_NUM / DIN_NUM :
                                                        MUL_NUM / DIN_NUM     ,//16

  // ADD_DW defines the data width of inputs of each adder in the adder tree
  localparam    ADD_DW      =   PRECISION == 3'b010 ? 9 : PDW                 ,//32
  
  // ADD_ODW defines the data width of outputs of adder tree
  localparam    ADD_ODW     =   PRECISION == 3'b010 ? ADD_DW*2+ADD_STAGE-3 :
                                                      ADD_DW+ADD_STAGE        ,//37

  // ODW defines the data width of outputs
  localparam    ODW         =   PRECISION == 3'b000 ? 26 : 
                                PRECISION == 3'b001 ? 42 : // ADD_ODW :
                                PRECISION == 3'b010 ? 16 : ADD_ODW            //42
  ) (
  output  wire    [           ODW*DOUT_NUM-1 : 0]   dout                      ,
  input           [                    XDW-1 : 0]   din_x                     ,
  input           [                    YDW-1 : 0]   din_y                     ,
  input                                             mode                      ,
  input           [                        2 : 0]   output_num                ,
  input           [                        2 : 0]   trunc_pos                 ,
  input                                             clk                       ,
  input                                             reset                      
  );

  localparam    DW_S0       =   ADD_DW + ADD_STAGE                            ;//37
  localparam    DW_S1       =   DW_S0 - 1                                     ;//36
  localparam    DW_S2       =   DW_S0 - 2                                     ;//35
  localparam    ALL_ADD_DW  =   PRECISION == 3'b010 ? ADD_DW*2*MUL_NUM :
                                                      ADD_DW*MUL_NUM          ;//16384
  
  wire  [PDW*MUL_NUM-1      : 0]   mul_p                 ;
  reg   [ALL_ADD_DW-1       : 0]   add_din  = 0          ;
  reg   [ADD_ODW*DOUT_NUM-1 : 0]   add_dout = 0          ; 
  reg   [ADD_ODW*DOUT_NUM-1 : 0]   tmp_dout = 0          ;
  wire  [DW_S0*TREE_NUM-1   : 0]   add_dout_s0           ;
  wire  [DW_S1*TREE_NUM-1   : 0]   add_dout_s1a          ;
  wire  [DW_S1*TREE_NUM-1   : 0]   add_dout_s1b          ;
  wire  [DW_S2*TREE_NUM-1   : 0]   add_dout_s2a          ;
  wire  [DW_S2*TREE_NUM-1   : 0]   add_dout_s2b          ;
  wire  [DW_S2*TREE_NUM-1   : 0]   add_dout_s2c          ;
  wire  [DW_S2*TREE_NUM-1   : 0]   add_dout_s2d          ;



//-----------------------------------------------------------------------------
//*********** Instantiating multi array, Contains 512 DSPs resources***********
//-----------------------------------------------------------------------------
//1reg+4DSP=5 cycles,x(ifm),y(ker)
  (*dont_touch="true"*) reg reset_ar_r =1'b1            ;
  always @(posedge clk)     reset_ar_r <=reset          ;
  (*dont_touch="true"*) reg [32-1:0]reset_ar={32{1'b1}} ;
  always @(posedge clk) reset_ar <={32{reset_ar_r}}     ;
  (*keep_hierarchy="yes" *)
  mul_array_old #(
    .PRECISION      ( PRECISION             ),//1
    .MUL_NUM        ( MUL_NUM               )//512
  ) ARRAY (
    .array_p        ( mul_p                 ),//512*32=16384
    .array_x        ( din_x                 ),//512*16=8192
    .array_y        ( din_y                 ),//512*16=8192
    .mode           ( mode                  ),//0
    .clk            ( clk                   ),
    .reset          ( reset_ar              )
  );
  
genvar i, j;
generate for ( i = 0; i < TREE_NUM ; i = i + 1 ) begin: ADDi//16
         for ( j = 0; j < DIN_NUM/4; j = j + 1 ) begin: ADDj//32/4=8
            if ( PRECISION == 3'b010 )
            begin
                  always @(posedge clk)
                  if ( ~mode ) begin
                       add_din[(i*DIN_NUM+j)*ADD_DW +: ADD_DW]<= 
                       $unsigned(mul_p[(i*DIN_NUM/2+2*j)*PDW +: PDW/2])         ;
                       add_din[(i*DIN_NUM+DIN_NUM/4+j)*ADD_DW +: ADD_DW]<= 
                       $unsigned(mul_p[(i*DIN_NUM/2+2*j+1)*PDW +: PDW/2])       ;
                       add_din[(i*DIN_NUM+DIN_NUM/4*2+j)*ADD_DW +: ADD_DW]<= 
                       $signed(mul_p[(i*DIN_NUM/2+2*j)*PDW+PDW/2 +: PDW/2])     ;
                       add_din[(i*DIN_NUM+DIN_NUM/4*3+j)*ADD_DW +: ADD_DW]<= 
                       $signed(mul_p[(i*DIN_NUM/2+2*j+1)*PDW+PDW/2 +: PDW/2])   ;
                   end 
                   else begin
                       add_din[(i*DIN_NUM+j)*ADD_DW +: ADD_DW]<= 
                       $signed(mul_p[(i*DIN_NUM+4*j)*PDW/2 +: PDW/2])           ;
                       add_din[(i*DIN_NUM+DIN_NUM/4+j)*ADD_DW +: ADD_DW]<= 
                       $signed(mul_p[(i*DIN_NUM+4*j+1)*PDW/2 +: PDW/2])         ;
                       add_din[(i*DIN_NUM+DIN_NUM/4*2+j)*ADD_DW +: ADD_DW]<= 
                       $signed(mul_p[(i*DIN_NUM+4*j+2)*PDW/2 +: PDW/2])         ;
                       add_din[(i*DIN_NUM+DIN_NUM/4*3+j)*ADD_DW +: ADD_DW]<= 
                       $signed(mul_p[(i*DIN_NUM+4*j+3)*PDW/2 +: PDW/2])         ;
                   end
            
            end 
            else 
                    always @(posedge clk) begin
                       add_din[(i*DIN_NUM+j*4+0)*ADD_DW +: ADD_DW]<=  mul_p[(i*DIN_NUM+j*4+0)*PDW +: PDW];
                            //  (i*32+j*4+0)*32+:32                            (i*32+j*4+0)*32+:32
                       add_din[(i*DIN_NUM+j*4+1)*ADD_DW +: ADD_DW]<=  mul_p[(i*DIN_NUM+j*4+1)*PDW +: PDW];
                       add_din[(i*DIN_NUM+j*4+2)*ADD_DW +: ADD_DW]<=  mul_p[(i*DIN_NUM+j*4+2)*PDW +: PDW];
                       add_din[(i*DIN_NUM+j*4+3)*ADD_DW +: ADD_DW]<=  mul_p[(i*DIN_NUM+j*4+3)*PDW +: PDW];
                    end
                
        end//ADDj
    end//ADDi
endgenerate

//-----------------------------------------------------------------------------
//************************** Instantiating adder tree**************************
//-----------------------------------------------------------------------------
//DSP output is : 16384=512*32bit------>32(add),16 num ,32bit
//so one ADD is ADD32
  (*dont_touch="true"*) reg reset_add_r =1'b1                                ;
  always @(posedge clk)     reset_add_r <=reset                              ;
  (*dont_touch="true"*) reg [TREE_NUM-1:0]reset_add={TREE_NUM{1'b1}}         ;
  always @(posedge clk) reset_add<={TREE_NUM{reset_add_r}}                   ;
  generate for ( i=0; i <TREE_NUM; i=i+1 ) begin: ADD
    (*keep_hierarchy="yes" *)
    adder_tree #(
      .STAGE            ( ADD_STAGE                                          ),//5
      .DW               ( ADD_DW                                             )//32
    ) Tree (
      .dout_s0          ( add_dout_s0 [DW_S0*i +: DW_S0]                     ),//yes,37
      .dout_s1a         ( add_dout_s1a[DW_S1*i +: DW_S1]                     ),
      .dout_s1b         ( add_dout_s1b[DW_S1*i +: DW_S1]                     ),
      .dout_s2a         ( add_dout_s2a[DW_S2*i +: DW_S2]                     ),//no
      .dout_s2b         ( add_dout_s2b[DW_S2*i +: DW_S2]                     ),//no
      .dout_s2c         ( add_dout_s2c[DW_S2*i +: DW_S2]                     ),//no
      .dout_s2d         ( add_dout_s2d[DW_S2*i +: DW_S2]                     ),//no
      .din              ( add_din[ADD_DW*DIN_NUM*i +: ADD_DW*DIN_NUM]        ),//eath is 32num*32bit
      .clk              ( clk                                                ),
      .reset            ( reset_add[i]                                       )
    );
  end
  endgenerate

//------------------------------------------------------------------------------
//for Debug,******OK******
//------------------------------------------------------------------------------
/*
  reg   [31:0]add_din_my[15:0][31:0];
  reg   [36:0]add_dout_s0_r[15:0];
  reg   [36:0]add_dout_s0_my[15:0];
  reg   [36:0]add_dout_s0_my1[15:0];
  reg   [36:0]add_dout_s0_my2[15:0];
  reg   [36:0]add_dout_s0_my3[15:0];
  reg   [36:0]add_dout_s0_my4[15:0];
  reg   [36:0]add_dout_s0_my5[15:0];
  
generate 
for ( i=0; i<16 ; i=i+1 ) 
begin//16
    for ( j=0; j<32 ; j=j+1 ) 
    begin//32*32bit=1024bit
        always @(*) add_din_my[i][j]<= add_din[i*1024+j*32+:32];
    end
end
endgenerate
  
generate 
for ( i=0; i<16 ; i=i+1 ) 
begin//16
    always @(*) add_dout_s0_r[i] <= add_dout_s0[i*37 +: 37];
    always @(*) add_dout_s0_my[i]<=
         $signed(add_din_my[i][31])+$signed(add_din_my[i][30])+$signed(add_din_my[i][29])+$signed(add_din_my[i][28])+
         $signed(add_din_my[i][27])+$signed(add_din_my[i][26])+$signed(add_din_my[i][25])+$signed(add_din_my[i][24])+
         $signed(add_din_my[i][23])+$signed(add_din_my[i][22])+$signed(add_din_my[i][21])+$signed(add_din_my[i][20])+
         $signed(add_din_my[i][19])+$signed(add_din_my[i][18])+$signed(add_din_my[i][17])+$signed(add_din_my[i][16])+
         $signed(add_din_my[i][15])+$signed(add_din_my[i][14])+$signed(add_din_my[i][13])+$signed(add_din_my[i][12])+
         $signed(add_din_my[i][11])+$signed(add_din_my[i][10])+$signed(add_din_my[i][ 9])+$signed(add_din_my[i][ 8])+
         $signed(add_din_my[i][ 7])+$signed(add_din_my[i][ 6])+$signed(add_din_my[i][ 5])+$signed(add_din_my[i][ 4])+
         $signed(add_din_my[i][ 3])+$signed(add_din_my[i][ 2])+$signed(add_din_my[i][ 1])+$signed(add_din_my[i][ 0]) ;
end
endgenerate

generate 
for ( i=0; i<16 ; i=i+1 ) 
begin//16
     always @(posedge clk) begin
        add_dout_s0_my5[i]<=add_dout_s0_my4[i];
        add_dout_s0_my4[i]<=add_dout_s0_my3[i];
        add_dout_s0_my3[i]<=add_dout_s0_my2[i];
        add_dout_s0_my2[i]<=add_dout_s0_my1[i];
        add_dout_s0_my1[i]<=add_dout_s0_my[i];
     end
end
endgenerate
*/


//-----------------------------------------------------------------------------
//*********** choose output from adder tree according to output num************
//-----------------------------------------------------------------------------

generate for ( i = 0; i < DOUT_NUM; i = i + 1 ) begin: OUT
if ( PRECISION == 3'b010 )
begin
     always @(posedge clk) 
     tmp_dout[ADD_ODW*i +: ADD_ODW] <= $signed({add_dout_s1b[DW_S1*i+:DW_S1-1] + 
                                                add_dout_s1a[DW_S1*i+8+:DW_S1-9],
                                                add_dout_s1a[DW_S1*i+:8]})                  ;
     always @(posedge clk)
     begin
        if ( (~mode) & (output_num == 3'b101) ) 
            add_dout[ADD_ODW*i +: ADD_ODW]    <=  tmp_dout[ADD_ODW*i +: ADD_ODW]             ;
        else 
        if ( output_num == 3'b101 ) 
            add_dout[ADD_ODW*i +: ADD_ODW]    <=  $signed(add_dout_s0[DW_S0*i +: DW_S0])     ;
        
     end
    
end 
else
begin
      always @(posedge clk)
        if( output_num == 3'b011 )//---------------------------------------------------------yes
        begin
          if ( i < 16 )
            add_dout[ADD_ODW*i +: ADD_ODW]  <=  $signed(add_dout_s0[ADD_ODW*i +: ADD_ODW])  ;//37
          else
            add_dout[ADD_ODW*i +: ADD_ODW]  <=  0                                           ;
           
        end 
        else 
        if ( output_num == 3'b100 ) begin
               if ( i < 16 )
            add_dout[ADD_ODW*i +: ADD_ODW]  <=  $signed(add_dout_s1a[DW_S1*i +: DW_S1])     ;
          else if ( (i >= 16) & (i < 32) )
            add_dout[ADD_ODW*i +: ADD_ODW]  <=  $signed(add_dout_s1b[DW_S1*(i-16) +: DW_S1]);
          else
            add_dout[ADD_ODW*i +: ADD_ODW]  <=  0                                           ;
        end 
        else 
        if ( output_num == 3'b101 ) begin
               if ( i < 16 )
            add_dout[ADD_ODW*i +: ADD_ODW]  <=  $signed(add_dout_s2a[DW_S2*i +: DW_S2])     ;
          else if ( (i >= 16) & (i < 32) )
            add_dout[ADD_ODW*i +: ADD_ODW]  <=  $signed(add_dout_s2b[DW_S2*(i-16) +: DW_S2]);
          else if ( (i >= 32) & (i < 48) )
            add_dout[ADD_ODW*i +: ADD_ODW]  <=  $signed(add_dout_s2c[DW_S2*(i-32) +: DW_S2]);
          else
            add_dout[ADD_ODW*i +: ADD_ODW]  <=  $signed(add_dout_s2d[DW_S2*(i-48) +: DW_S2]);
        end
        
end
end
endgenerate


//-----------------------------------------------------------------------------
//*************** For INT8/INT16, decide if we need trunc here*****************
//-----------------------------------------------------------------------------
generate for ( i = 0; i < DOUT_NUM; i = i + 1 ) begin: TRUNC
if ( PRECISION == 3'b010 ) begin
        (*keep_hierarchy="yes" *)
        trunc_old #(
          .IDW              ( ADD_ODW                                           ),
          .ODWH             ( ODW                                               ),
          .ODWL             ( ODW/2                                             ),
          .NUM              ( TREE_NUM                                          )
        ) Trunc (
          .dout             ( dout                                              ),
          .din              ( add_dout                                          ),
          .trunc_pos        ( trunc_pos                                         ),
          .mode             ( mode                                              ),
          .clk              ( clk                                               ),
          .reset            ( reset                                             )
        );
end else 
begin
        (*dont_touch="true"*)reg  [ODW-1 : 0]    dout_tmp = 0                    ;
        always @(posedge clk) dout_tmp<= $signed(add_dout[i*ADD_ODW +:ADD_ODW])  ;
        assign dout[i*ODW+:ODW]  = dout_tmp                                      ;//42
end
end
endgenerate

endmodule
