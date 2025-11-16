`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/19/2024 10:20:03 PM
// Design Name: 
// Module Name: concat
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`include "opu_parameter.vh"


module ofm_concat_mux
#(
  parameter     DWCNT=4,
  parameter     RATIO=8,
  parameter     IDW  =38,
  parameter     CNUM=512         
) (
  input                                 clk                         ,
  input         [CNUM-1:0][DWCNT-1:0]   cnt0                        ,
  input         [CNUM-1:0][DWCNT-1:0]   cnt1                        ,
  input         [CNUM-1:0]              sel                         ,
  input         [128*IDW-1:0]           rdata                       ,
  output wire   [128*IDW-1:0]           shift_reg                   ,
  output wire                           shift_vld            
);

  localparam    DWSH                    =(256*IDW)/CNUM             ;
  integer       i                       =0                          ;
  reg           [256*IDW-1:0]           SHIFT_regist        =0      ;
  reg           [128*IDW-1:0]           SHIFT_rdata[4-1:0]          ;
  reg           [CNUM   -1:0]           SHIFT_sel           =0      ;
  reg           [DWCNT  -1:0]           SHIFT_cnt0[CNUM-1:0]        ;
  reg           [DWCNT  -1:0]           SHIFT_cnt1[CNUM-1:0]        ;


  assign shift_vld      =   SHIFT_sel   [CNUM-1]                    ;
  assign shift_reg      =   SHIFT_regist[128*IDW-1:0]               ;


  always @(posedge clk)
  begin
       SHIFT_rdata[0]   <=  rdata                                   ;
       SHIFT_rdata[1]   <=  SHIFT_rdata[0]                          ;
       SHIFT_rdata[2]   <=  SHIFT_rdata[1]                          ;
       SHIFT_rdata[3]   <=  SHIFT_rdata[1]                          ;
       //SHIFT_rdata[4]   <=  SHIFT_rdata[2]                          ;
  end
 
  always @(posedge clk)
  for(i=0;i<CNUM;i=i+1)
  begin
      SHIFT_sel [i]     <=  sel [i]                                 ;
      SHIFT_cnt0[i]     <=  cnt0[i]                                 ;
      SHIFT_cnt1[i]     <=  cnt0[i]                                 ;
  end

  wire [256*IDW-1:0] SHIFT0_wire0  ={{(RATIO*16){38'd0}},SHIFT_rdata[2]                                     };
  wire [256*IDW-1:0] SHIFT0_wire1  ={{(RATIO*15){38'd0}},SHIFT_rdata[2],SHIFT_regist[128*IDW+:(RATIO*1 )*IDW]};
  wire [256*IDW-1:0] SHIFT0_wire2  ={{(RATIO*14){38'd0}},SHIFT_rdata[2],SHIFT_regist[128*IDW+:(RATIO*2 )*IDW]};
  wire [256*IDW-1:0] SHIFT0_wire3  ={{(RATIO*13){38'd0}},SHIFT_rdata[2],SHIFT_regist[128*IDW+:(RATIO*3 )*IDW]};
  wire [256*IDW-1:0] SHIFT0_wire4  ={{(RATIO*12){38'd0}},SHIFT_rdata[2],SHIFT_regist[128*IDW+:(RATIO*4 )*IDW]};
  wire [256*IDW-1:0] SHIFT0_wire5  ={{(RATIO*11){38'd0}},SHIFT_rdata[2],SHIFT_regist[128*IDW+:(RATIO*5 )*IDW]};
  wire [256*IDW-1:0] SHIFT0_wire6  ={{(RATIO*10){38'd0}},SHIFT_rdata[2],SHIFT_regist[128*IDW+:(RATIO*6 )*IDW]};
  wire [256*IDW-1:0] SHIFT0_wire7  ={{(RATIO*9 ){38'd0}},SHIFT_rdata[2],SHIFT_regist[128*IDW+:(RATIO*7 )*IDW]};
  wire [256*IDW-1:0] SHIFT0_wire8  ={{(RATIO*8 ){38'd0}},SHIFT_rdata[2],SHIFT_regist[128*IDW+:(RATIO*8 )*IDW]};
  wire [256*IDW-1:0] SHIFT0_wire9  ={{(RATIO*7 ){38'd0}},SHIFT_rdata[2],SHIFT_regist[128*IDW+:(RATIO*9 )*IDW]};
  wire [256*IDW-1:0] SHIFT0_wire10 ={{(RATIO*6 ){38'd0}},SHIFT_rdata[2],SHIFT_regist[128*IDW+:(RATIO*10)*IDW]};
  wire [256*IDW-1:0] SHIFT0_wire11 ={{(RATIO*5 ){38'd0}},SHIFT_rdata[2],SHIFT_regist[128*IDW+:(RATIO*11)*IDW]};
  wire [256*IDW-1:0] SHIFT0_wire12 ={{(RATIO*4 ){38'd0}},SHIFT_rdata[2],SHIFT_regist[128*IDW+:(RATIO*12)*IDW]};
  wire [256*IDW-1:0] SHIFT0_wire13 ={{(RATIO*3 ){38'd0}},SHIFT_rdata[2],SHIFT_regist[128*IDW+:(RATIO*13)*IDW]};
  wire [256*IDW-1:0] SHIFT0_wire14 ={{(RATIO*2 ){38'd0}},SHIFT_rdata[2],SHIFT_regist[128*IDW+:(RATIO*14)*IDW]};
  wire [256*IDW-1:0] SHIFT0_wire15 ={{(RATIO*1 ){38'd0}},SHIFT_rdata[2],SHIFT_regist[128*IDW+:(RATIO*15)*IDW]};
  //
  wire [256*IDW-1:0] SHIFT1_wire0  ={{(RATIO*16){38'd0}},SHIFT_rdata[3]                                };
  wire [256*IDW-1:0] SHIFT1_wire1  ={{(RATIO*15){38'd0}},SHIFT_rdata[3],SHIFT_regist[0+:(RATIO*1 )*IDW]};
  wire [256*IDW-1:0] SHIFT1_wire2  ={{(RATIO*14){38'd0}},SHIFT_rdata[3],SHIFT_regist[0+:(RATIO*2 )*IDW]};
  wire [256*IDW-1:0] SHIFT1_wire3  ={{(RATIO*13){38'd0}},SHIFT_rdata[3],SHIFT_regist[0+:(RATIO*3 )*IDW]};
  wire [256*IDW-1:0] SHIFT1_wire4  ={{(RATIO*12){38'd0}},SHIFT_rdata[3],SHIFT_regist[0+:(RATIO*4 )*IDW]};
  wire [256*IDW-1:0] SHIFT1_wire5  ={{(RATIO*11){38'd0}},SHIFT_rdata[3],SHIFT_regist[0+:(RATIO*5 )*IDW]};
  wire [256*IDW-1:0] SHIFT1_wire6  ={{(RATIO*10){38'd0}},SHIFT_rdata[3],SHIFT_regist[0+:(RATIO*6 )*IDW]};
  wire [256*IDW-1:0] SHIFT1_wire7  ={{(RATIO*9 ){38'd0}},SHIFT_rdata[3],SHIFT_regist[0+:(RATIO*7 )*IDW]};
  wire [256*IDW-1:0] SHIFT1_wire8  ={{(RATIO*8 ){38'd0}},SHIFT_rdata[3],SHIFT_regist[0+:(RATIO*8 )*IDW]};
  wire [256*IDW-1:0] SHIFT1_wire9  ={{(RATIO*7 ){38'd0}},SHIFT_rdata[3],SHIFT_regist[0+:(RATIO*9 )*IDW]};
  wire [256*IDW-1:0] SHIFT1_wire10 ={{(RATIO*6 ){38'd0}},SHIFT_rdata[3],SHIFT_regist[0+:(RATIO*10)*IDW]};
  wire [256*IDW-1:0] SHIFT1_wire11 ={{(RATIO*5 ){38'd0}},SHIFT_rdata[3],SHIFT_regist[0+:(RATIO*11)*IDW]};
  wire [256*IDW-1:0] SHIFT1_wire12 ={{(RATIO*4 ){38'd0}},SHIFT_rdata[3],SHIFT_regist[0+:(RATIO*12)*IDW]};
  wire [256*IDW-1:0] SHIFT1_wire13 ={{(RATIO*3 ){38'd0}},SHIFT_rdata[3],SHIFT_regist[0+:(RATIO*13)*IDW]};
  wire [256*IDW-1:0] SHIFT1_wire14 ={{(RATIO*2 ){38'd0}},SHIFT_rdata[3],SHIFT_regist[0+:(RATIO*14)*IDW]};
  wire [256*IDW-1:0] SHIFT1_wire15 ={{(RATIO*1 ){38'd0}},SHIFT_rdata[3],SHIFT_regist[0+:(RATIO*15)*IDW]};



  always @(posedge clk)
  for(i=0;i<CNUM;i=i+1)
  if(SHIFT_sel[i])//---------------------------------------------------------------
    (*full_case*)
    case(SHIFT_cnt0[i])
    4'd0   : SHIFT_regist[i*DWSH+:DWSH] <=  SHIFT0_wire0 [i*DWSH+:DWSH] ;
    4'd1   : SHIFT_regist[i*DWSH+:DWSH] <=  SHIFT0_wire1 [i*DWSH+:DWSH] ;
    4'd2   : SHIFT_regist[i*DWSH+:DWSH] <=  SHIFT0_wire2 [i*DWSH+:DWSH] ;
    4'd3   : SHIFT_regist[i*DWSH+:DWSH] <=  SHIFT0_wire3 [i*DWSH+:DWSH] ;
    4'd4   : SHIFT_regist[i*DWSH+:DWSH] <=  SHIFT0_wire4 [i*DWSH+:DWSH] ;
    4'd5   : SHIFT_regist[i*DWSH+:DWSH] <=  SHIFT0_wire5 [i*DWSH+:DWSH] ;
    4'd6   : SHIFT_regist[i*DWSH+:DWSH] <=  SHIFT0_wire6 [i*DWSH+:DWSH] ;
    4'd7   : SHIFT_regist[i*DWSH+:DWSH] <=  SHIFT0_wire7 [i*DWSH+:DWSH] ;
    4'd8   : SHIFT_regist[i*DWSH+:DWSH] <=  SHIFT0_wire8 [i*DWSH+:DWSH] ;
    4'd9   : SHIFT_regist[i*DWSH+:DWSH] <=  SHIFT0_wire9 [i*DWSH+:DWSH] ;
    4'd10  : SHIFT_regist[i*DWSH+:DWSH] <=  SHIFT0_wire10[i*DWSH+:DWSH] ;
    4'd11  : SHIFT_regist[i*DWSH+:DWSH] <=  SHIFT0_wire11[i*DWSH+:DWSH] ;
    4'd12  : SHIFT_regist[i*DWSH+:DWSH] <=  SHIFT0_wire12[i*DWSH+:DWSH] ;
    4'd13  : SHIFT_regist[i*DWSH+:DWSH] <=  SHIFT0_wire13[i*DWSH+:DWSH] ;
    4'd14  : SHIFT_regist[i*DWSH+:DWSH] <=  SHIFT0_wire14[i*DWSH+:DWSH] ;
    default: SHIFT_regist[i*DWSH+:DWSH] <=  SHIFT0_wire15[i*DWSH+:DWSH] ;
    endcase
  else//------------------------------------------------------------------------
    (*full_case*)
    case(SHIFT_cnt1[i])
    4'd0   : SHIFT_regist[i*DWSH+:DWSH] <=  SHIFT1_wire0 [i*DWSH+:DWSH] ;
    4'd1   : SHIFT_regist[i*DWSH+:DWSH] <=  SHIFT1_wire1 [i*DWSH+:DWSH] ;
    4'd2   : SHIFT_regist[i*DWSH+:DWSH] <=  SHIFT1_wire2 [i*DWSH+:DWSH] ;
    4'd3   : SHIFT_regist[i*DWSH+:DWSH] <=  SHIFT1_wire3 [i*DWSH+:DWSH] ;
    4'd4   : SHIFT_regist[i*DWSH+:DWSH] <=  SHIFT1_wire4 [i*DWSH+:DWSH] ;
    4'd5   : SHIFT_regist[i*DWSH+:DWSH] <=  SHIFT1_wire5 [i*DWSH+:DWSH] ;
    4'd6   : SHIFT_regist[i*DWSH+:DWSH] <=  SHIFT1_wire6 [i*DWSH+:DWSH] ;
    4'd7   : SHIFT_regist[i*DWSH+:DWSH] <=  SHIFT1_wire7 [i*DWSH+:DWSH] ;
    4'd8   : SHIFT_regist[i*DWSH+:DWSH] <=  SHIFT1_wire8 [i*DWSH+:DWSH] ;
    4'd9   : SHIFT_regist[i*DWSH+:DWSH] <=  SHIFT1_wire9 [i*DWSH+:DWSH] ;
    4'd10  : SHIFT_regist[i*DWSH+:DWSH] <=  SHIFT1_wire10[i*DWSH+:DWSH] ;
    4'd11  : SHIFT_regist[i*DWSH+:DWSH] <=  SHIFT1_wire11[i*DWSH+:DWSH] ;
    4'd12  : SHIFT_regist[i*DWSH+:DWSH] <=  SHIFT1_wire12[i*DWSH+:DWSH] ;
    4'd13  : SHIFT_regist[i*DWSH+:DWSH] <=  SHIFT1_wire13[i*DWSH+:DWSH] ;
    4'd14  : SHIFT_regist[i*DWSH+:DWSH] <=  SHIFT1_wire14[i*DWSH+:DWSH] ;
    default: SHIFT_regist[i*DWSH+:DWSH] <=  SHIFT1_wire15[i*DWSH+:DWSH] ;
    endcase





endmodule
