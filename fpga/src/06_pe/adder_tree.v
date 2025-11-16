`timescale 1ns / 1ps
// -----------------------------------------------------------------------------
// UCLA EDA LAB
// -----------------------------------------------------------------------------
// Engineer       : Chen Wu
// Design Name    : opu series
// Module Name    : adder_tree
// Target Devices : 325t
// Tool Versions  : Vivado 2020.1, Modelsim 2019.4
// Description    : 
//    Adder tree module:
//      adder_tree64 = adder_tree32 + adder_tree32  DW ==> DW+6
//      adder_tree32 = adder_tree16 + adder_tree16  DW ==> DW+5
//      adder_tree16 = adder_tree8  + adder_tree8   DW ==> DW+4
//      adder_tree8  = adder_tree4  + adder_tree4   DW ==> DW+3
//      adder_tree4  = adder_tree2  + adder_tree2   DW ==> DW+2
//      adder_tree2  = adder        + adder         DW ==> DW+1
//    Here we just skip adder_tree2 and replace it with two adders.
//
// Revision       :
// Version        Date        Author        Descriptin
// 1.0            2021-04-04  Chen Wu       Initial version
// 2.0            2023-08-25  Shaoqiang     Simulation 97 layers,and       
//                                          implementation on FPGA of U200.
// -----------------------------------------------------------------------------


module adder_tree #(
  // Stages of the adder tree
  parameter         STAGE   = 6                     ,

  // data width of the input data
  parameter         DW      = 16                    ,

  // number of the input data
  parameter         NUM     = STAGE == 6 ? 64 :
                              STAGE == 5 ? 32 : 
                              STAGE == 4 ? 16 :
                              STAGE == 3 ?  8 : 4 
  ) (
  output  wire    [DW+STAGE-1 : 0]    dout_s0       ,
  output  wire    [DW+STAGE-2 : 0]    dout_s1a      ,
  output  wire    [DW+STAGE-2 : 0]    dout_s1b      ,
  output  wire    [DW+STAGE-3 : 0]    dout_s2a      ,
  output  wire    [DW+STAGE-3 : 0]    dout_s2b      ,
  output  wire    [DW+STAGE-3 : 0]    dout_s2c      ,
  output  wire    [DW+STAGE-3 : 0]    dout_s2d      ,
  input           [  DW*NUM-1 : 0]    din           ,
  input                               clk           ,
  input                               reset     
  );

if ( STAGE == 6 ) begin
  adder_tree64 #(.DW(DW)) add64 (
    .dout_final     ( dout_s0                       ),
    .dout_s5a       ( dout_s1a                      ),
    .dout_s5b       ( dout_s1b                      ),
    .dout_s4a       ( dout_s2a                      ),
    .dout_s4b       ( dout_s2b                      ),
    .dout_s4c       ( dout_s2c                      ),
    .dout_s4d       ( dout_s2d                      ),
    .din            ( din                           ),
    .clk            ( clk                           ),
    .reset          ( reset                         )
  );
end else if ( STAGE == 5 ) begin
  adder_tree32 #(.DW(DW)) add32 (
    .dout_final     ( dout_s0                       ),
    .dout_s4a       ( dout_s1a                      ),
    .dout_s4b       ( dout_s1b                      ),
    .din            ( din                           ),
    .clk            ( clk                           ),
    .reset          ( reset                         )
  );
  assign dout_s2a   =   0                           ;
  assign dout_s2b   =   0                           ;
  assign dout_s2c   =   0                           ;
  assign dout_s2d   =   0                           ;
end else if ( STAGE == 4 ) begin
  adder_tree16 #(.DW(DW)) add16 (
    .dout           ( dout_s0                       ),
    .din            ( din                           ),
    .clk            ( clk                           ),
    .reset          ( reset                         )
  );
  assign dout_s1a   =   0                           ;
  assign dout_s1b   =   0                           ;
  assign dout_s2a   =   0                           ;
  assign dout_s2b   =   0                           ;
  assign dout_s2c   =   0                           ;
  assign dout_s2d   =   0                           ;
end else if ( STAGE == 3 ) begin
  adder_tree8 #(.DW(DW)) add8 (
    .dout           ( dout_s0                       ),
    .din            ( din                           ),
    .clk            ( clk                           ),
    .reset          ( reset                         )
  );
  assign dout_s1a   =   0                           ;
  assign dout_s1b   =   0                           ;
  assign dout_s2a   =   0                           ;
  assign dout_s2b   =   0                           ;
  assign dout_s2c   =   0                           ;
  assign dout_s2d   =   0                           ;
end else begin
  adder_tree4 #(.DW(DW)) add4 (
    .dout           ( dout_s0                       ),
    .din            ( din                           ),
    .clk            ( clk                           ),
    .reset          ( reset                         )
  );
  assign dout_s1a   =   0                           ;
  assign dout_s1b   =   0                           ;
  assign dout_s2a   =   0                           ;
  assign dout_s2b   =   0                           ;
  assign dout_s2c   =   0                           ;
  assign dout_s2d   =   0                           ;
end


//------------------------------------------------------------------------------
//for Debug,.OK
//------------------------------------------------------------------------------
/*
  reg   [31:0]din_my[31:0];
  reg   [36:0]dout_s0_my;
generate 
for ( genvar j=0; j<32 ; j=j+1 ) 
begin//32
        always @(*) din_my[j]<= din[j*32+:32];
end
endgenerate
always @(*) dout_s0_my<= 
        $signed(din_my[31])+$signed(din_my[30])+$signed(din_my[29])+$signed(din_my[28])+
        $signed(din_my[27])+$signed(din_my[26])+$signed(din_my[25])+$signed(din_my[24])+
        $signed(din_my[23])+$signed(din_my[22])+$signed(din_my[21])+$signed(din_my[20])+
        $signed(din_my[19])+$signed(din_my[18])+$signed(din_my[17])+$signed(din_my[16])+
        $signed(din_my[15])+$signed(din_my[14])+$signed(din_my[13])+$signed(din_my[12])+
        $signed(din_my[11])+$signed(din_my[10])+$signed(din_my[ 9])+$signed(din_my[ 8])+
        $signed(din_my[ 7])+$signed(din_my[ 6])+$signed(din_my[ 5])+$signed(din_my[ 4])+
        $signed(din_my[ 3])+$signed(din_my[ 2])+$signed(din_my[ 1])+$signed(din_my[ 0]) ;
*/



endmodule

 //----------------------------------------------------------------add64
module adder_tree64 #(parameter DW=16) (
  output  wire    [    DW+6-1 : 0]    dout_final    ,
  output  wire    [    DW+5-1 : 0]    dout_s5a      ,
  output  wire    [    DW+5-1 : 0]    dout_s5b      ,
  output  wire    [    DW+4-1 : 0]    dout_s4a      ,
  output  wire    [    DW+4-1 : 0]    dout_s4b      ,
  output  wire    [    DW+4-1 : 0]    dout_s4c      ,
  output  wire    [    DW+4-1 : 0]    dout_s4d      ,
  input           [   DW*64-1 : 0]    din           ,
  input                               clk           ,
  input                               reset   
  );

  adder_tree32 #(.DW(DW)) u0_add32 (
    .dout_final     ( dout_s5a                      ),
    .dout_s4a       ( dout_s4a                      ),
    .dout_s4b       ( dout_s4b                      ),
    .din            ( din[0 +: DW*32]               ),
    .clk            ( clk                           ),
    .reset          ( reset                         )
  );

  adder_tree32 #(.DW(DW)) u1_add32 (
    .dout_final     ( dout_s5b                      ),
    .dout_s4a       ( dout_s4c                      ),
    .dout_s4b       ( dout_s4d                      ),
    .din            ( din[DW*32 +: DW*32]           ),
    .clk            ( clk                           ),
    .reset          ( reset                         )
  );

  adder #(.DW(DW+5)) u0_adder (
    .s              ( dout_final                    ),
    .a              ( dout_s5a                      ),
    .b              ( dout_s5b                      ),
    .clk            ( clk                           ),
    .reset          ( reset                         )
  );
endmodule


 //----------------------------------------------------------------add32
module adder_tree32 #(parameter DW=16) (
  output  wire    [    DW+5-1 : 0]    dout_final    ,
  output  wire    [    DW+4-1 : 0]    dout_s4a      ,
  output  wire    [    DW+4-1 : 0]    dout_s4b      ,
  input           [   DW*32-1 : 0]    din           ,
  input                               clk           ,
  input                               reset         
  );

  adder_tree16 #(.DW(DW)) u0_add16 (
    .dout           ( dout_s4a                      ),
    .din            ( din[0 +: DW*16]               ),
    .clk            ( clk                           ),
    .reset          ( reset                         )
  );

  adder_tree16 #(.DW(DW)) u1_add16 (
    .dout           ( dout_s4b                      ),
    .din            ( din[DW*16 +: DW*16]           ),
    .clk            ( clk                           ),
    .reset          ( reset                         )
  );

  adder #(.DW(DW+4)) u0_adder (
    .s              ( dout_final                    ),
    .a              ( dout_s4a                      ),
    .b              ( dout_s4b                      ),
    .clk            ( clk                           ),
    .reset          ( reset                         )
  );
endmodule

 //----------------------------------------------------------------add16
module adder_tree16 #(parameter DW=16) (
  output  wire    [    DW+4-1 : 0]    dout          ,
  input           [   DW*16-1 : 0]    din           ,
  input                               clk           ,
  input                               reset         
  );

  wire  [ DW+3-1 : 0]    s0    ;
  wire  [ DW+3-1 : 0]    s1    ;

  adder_tree8 #(.DW(DW)) u0_add8 (
    .dout           ( s0                            ),
    .din            ( din[0 +: DW*8]                ),
    .clk            ( clk                           ),
    .reset          ( reset                         )
  );

  adder_tree8 #(.DW(DW)) u1_add8 (
    .dout           ( s1                            ),
    .din            ( din[DW*8 +: DW*8]             ),
    .clk            ( clk                           ),
    .reset          ( reset                         )
  );

  adder #(.DW(DW+3)) u0_adder (
    .s              ( dout                          ),
    
    .a              ( s0                            ),
    .b              ( s1                            ),

    .clk            ( clk                           ),
    .reset          ( reset                         )
  );
endmodule


 //----------------------------------------------------------------add8
module adder_tree8 #(parameter DW=16) (
  output  wire    [   DW+3-1 : 0]     dout          ,
  input           [   DW*8-1 : 0]     din           ,
  input                               clk           ,
  input                               reset         
  );

  wire [ DW+2-1 : 0]     s0   ;
  wire [ DW+2-1 : 0]     s1   ;

  adder_tree4 #(.DW(DW)) u0_add4 (
    .dout           ( s0                            ),
    .din            ( din[DW*4 +: DW*4]             ),
    .clk            ( clk                           ),
    .reset          ( reset                         )
  );

  adder_tree4 #(.DW(DW)) u1_add4 (
    .dout           ( s1                            ),
    .din            ( din[   0 +: DW*4]             ),
    .clk            ( clk                           ),
    .reset          ( reset                         )
  );
  
  adder #(.DW(DW+2)) u0_adder (
    .s              ( dout                          ),
    .a              ( $signed(s0)                   ),
    .b              ( $signed(s1)                   ),
    .clk            ( clk                           ),
    .reset          ( reset                         )
  );

endmodule

module adder_tree4 #(parameter DW=16) (
  output  wire    [   DW+2-1 : 0]     dout          ,
  input           [   DW*4-1 : 0]     din           ,
  input                               clk           ,
  input                               reset         
  );
  
  wire [ DW : 0]     s0        ;
  wire [ DW : 0]     s1        ;

  adder #(.DW(DW)) u0_add2 (
    .s            ( s0                              ),
    
    .a            ( din[DW*0 +: DW]                 ),
    .b            ( din[DW*1 +: DW]                 ),

    .clk          ( clk                             ),
    .reset        ( reset                           )
  );

  adder #(.DW(DW)) u1_add2 (
    .s            ( s1                              ),
    
    .a            ( din[DW*2 +: DW]                 ),
    .b            ( din[DW*3 +: DW]                 ),

    .clk          ( clk                             ),
    .reset        ( reset                           )
  );

  adder #(.DW(DW+1)) u0_adder (
    .s            ( dout                            ),
    
    .a            ( s0                              ),
    .b            ( s1                              ),

    .clk          ( clk                             ),
    .reset        ( reset                           )
  );

endmodule

