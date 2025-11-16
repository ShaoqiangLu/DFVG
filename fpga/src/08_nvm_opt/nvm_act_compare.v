`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/11/23 13:04:14
// Design Name: 
// Module Name: GELU_driver
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: Gaussian Error Linear Unit
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
/* This file is updated using systemverilog.
   GELU_dirvier convert the scalar GELU active function to a vectorized function.
   NUM_ELEMS defines the elements in the vector.
   The GELU_act gets 2 cycles to compute the results, and the driver use 1 cycles to pass the results, y, to y_vec
*/

module nvm_act_compare # (
    parameter       CUT     =   27                              ,
    parameter       DW      =   16                              ,
    parameter       NUM     =   32                              ,
    parameter       DW_X    =   17
)(
    input                                       clk             ,
    input                                       rst             ,
    input           [NUM-1:0][DW  -1:0]         x_din           ,
    input           [CUT-1:0][DW_X-1:0]         PARAMETER_X_Q17 ,
    output  reg     [NUM-1:0][5   -1:0]         index  =0       //3 cyclle
);
  integer i=0,j=0;


generate 
for(genvar i=0;i<NUM;i=i+1 )
begin:COMP
    //
    wire                     [DW  -1:0]xdin_wire =x_din[i]      ;
    (*dont_touch="true"*)reg [DW_X-1:0]comp_xdin =0             ;
    always @ (posedge clk)comp_xdin<={xdin_wire[DW-1],xdin_wire};
    //
    (*dont_touch="true"*)reg [DW_X-1:0]comp_pram[CUT-1:0]       ;
    always @ (posedge clk)
    for(j=0;j<CUT;j=j+1)comp_pram[j]<=PARAMETER_X_Q17[j]        ;
    //
    reg                      [CUT-1:0] comp_out  =0             ;
    always @ (posedge clk)for(j=1;j<CUT;j=j+1)
    comp_out[j]<=$signed(comp_xdin)>=$signed(comp_pram[j])      ;
    //
    always @ (posedge clk)index[i]<=
    comp_out[ 0]+ comp_out[ 1]+ comp_out[ 2]+ comp_out[ 3]+
    comp_out[ 4]+ comp_out[ 5]+ comp_out[ 6]+ comp_out[ 7]+
    comp_out[ 8]+ comp_out[ 9]+ comp_out[10]+ comp_out[11]+
    comp_out[12]+ comp_out[13]+ comp_out[14]+ comp_out[15]+
    comp_out[16]+ comp_out[17]+ comp_out[18]+ comp_out[19]+
    comp_out[20]+ comp_out[21]+ comp_out[22]+ comp_out[23]+
    comp_out[24]+ comp_out[25]+ comp_out[26];//0~26
end
endgenerate

/*
  (*dont_touch="true"*)reg [(DW+1)-1:0]x_din0[NUM-1:0];
  (*dont_touch="true"*)reg [(DW+1)-1:0]x_din1[NUM-1:0];
  (*dont_touch="true"*)reg [(DW+1)-1:0]x_din2[NUM-1:0];
  (*dont_touch="true"*)reg [(DW+1)-1:0]x_din3[NUM-1:0];
  
  always @ (posedge clk)
  for(i=0;i<NUM;i=i+1)
  begin
      x_din0[i]<={x_din[i*DW+DW-1],x_din[i*DW+:DW]};
      x_din1[i]<={x_din[i*DW+DW-1],x_din[i*DW+:DW]};
      x_din2[i]<={x_din[i*DW+DW-1],x_din[i*DW+:DW]};
      x_din3[i]<={x_din[i*DW+DW-1],x_din[i*DW+:DW]};
  end
  //----------------------------------------------------
  //
  //----------------------------------------------------

  wire [CUT*(DW+1)-1:0]BUFFER_copy0={
                       {6{x_din0[0]}},
                       {6{x_din1[0]}},
                       {7{x_din2[0]}},
                       {7{x_din3[0]}}};
                       
  wire [CUT*(DW+1)-1:0]BUFFER_copy1={
                       {6{x_din0[1]}},
                       {6{x_din1[1]}},
                       {7{x_din2[1]}},
                       {7{x_din3[1]}}};
                       
  wire [CUT*(DW+1)-1:0]BUFFER_copy2={
                       {6{x_din0[2]}},
                       {6{x_din1[2]}},
                       {7{x_din2[2]}},
                       {7{x_din3[2]}}};
                       
  wire [CUT*(DW+1)-1:0]BUFFER_copy3={
                       {6{x_din0[3]}},
                       {6{x_din1[3]}},
                       {7{x_din2[3]}},
                       {7{x_din3[3]}}};
                       
  wire [CUT*(DW+1)-1:0]BUFFER_copy4={
                       {6{x_din0[4]}},
                       {6{x_din1[4]}},
                       {7{x_din2[4]}},
                       {7{x_din3[4]}}};
                       
  wire [CUT*(DW+1)-1:0]BUFFER_copy5={
                       {6{x_din0[5]}},
                       {6{x_din1[5]}},
                       {7{x_din2[5]}},
                       {7{x_din3[5]}}};
                       
  wire [CUT*(DW+1)-1:0]BUFFER_copy6={
                       {6{x_din0[6]}},
                       {6{x_din1[6]}},
                       {7{x_din2[6]}},
                       {7{x_din3[6]}}};
                       
  wire [CUT*(DW+1)-1:0]BUFFER_copy7={
                       {6{x_din0[7]}},
                       {6{x_din1[7]}},
                       {7{x_din2[7]}},
                       {7{x_din3[7]}}};
                       
  wire [CUT*(DW+1)-1:0]BUFFER_copy8={
                       {6{x_din0[8]}},
                       {6{x_din1[8]}},
                       {7{x_din2[8]}},
                       {7{x_din3[8]}}};
                       
  wire [CUT*(DW+1)-1:0]BUFFER_copy9={
                       {6{x_din0[9]}},
                       {6{x_din1[9]}},
                       {7{x_din2[9]}},
                       {7{x_din3[9]}}};
                       
  wire [CUT*(DW+1)-1:0]BUFFER_copy10={
                       {6{x_din0[10]}},
                       {6{x_din1[10]}},
                       {7{x_din2[10]}},
                       {7{x_din3[10]}}};
                       
  wire [CUT*(DW+1)-1:0]BUFFER_copy11={
                       {6{x_din0[11]}},
                       {6{x_din1[11]}},
                       {7{x_din2[11]}},
                       {7{x_din3[11]}}};
                       
  wire [CUT*(DW+1)-1:0]BUFFER_copy12={
                       {6{x_din0[12]}},
                       {6{x_din1[12]}},
                       {7{x_din2[12]}},
                       {7{x_din3[12]}}};
                       
  wire [CUT*(DW+1)-1:0]BUFFER_copy13={
                       {6{x_din0[13]}},
                       {6{x_din1[13]}},
                       {7{x_din2[13]}},
                       {7{x_din3[13]}}};
                       
  wire [CUT*(DW+1)-1:0]BUFFER_copy14={
                       {6{x_din0[14]}},
                       {6{x_din1[14]}},
                       {7{x_din2[14]}},
                       {7{x_din3[14]}}};
                       
  wire [CUT*(DW+1)-1:0]BUFFER_copy15={
                       {6{x_din0[15]}},
                       {6{x_din1[15]}},
                       {7{x_din2[15]}},
                       {7{x_din3[15]}}};
                       
  wire [CUT*(DW+1)-1:0]BUFFER_copy16={
                       {6{x_din0[16]}},
                       {6{x_din1[16]}},
                       {7{x_din2[16]}},
                       {7{x_din3[16]}}};
                       
  wire [CUT*(DW+1)-1:0]BUFFER_copy17={
                       {6{x_din0[17]}},
                       {6{x_din1[17]}},
                       {7{x_din2[17]}},
                       {7{x_din3[17]}}};
                       
  wire [CUT*(DW+1)-1:0]BUFFER_copy18={
                       {6{x_din0[18]}},
                       {6{x_din1[18]}},
                       {7{x_din2[18]}},
                       {7{x_din3[18]}}};
                       
  wire [CUT*(DW+1)-1:0]BUFFER_copy19={
                       {6{x_din0[19]}},
                       {6{x_din1[19]}},
                       {7{x_din2[19]}},
                       {7{x_din3[19]}}};
                       
  wire [CUT*(DW+1)-1:0]BUFFER_copy20={
                       {6{x_din0[20]}},
                       {6{x_din1[20]}},
                       {7{x_din2[20]}},
                       {7{x_din3[20]}}};
                       
  wire [CUT*(DW+1)-1:0]BUFFER_copy21={
                       {6{x_din0[21]}},
                       {6{x_din1[21]}},
                       {7{x_din2[21]}},
                       {7{x_din3[21]}}};
                       
  wire [CUT*(DW+1)-1:0]BUFFER_copy22={
                       {6{x_din0[22]}},
                       {6{x_din1[22]}},
                       {7{x_din2[22]}},
                       {7{x_din3[22]}}};
                       
  wire [CUT*(DW+1)-1:0]BUFFER_copy23={
                       {6{x_din0[23]}},
                       {6{x_din1[23]}},
                       {7{x_din2[23]}},
                       {7{x_din3[23]}}};
                       
  wire [CUT*(DW+1)-1:0]BUFFER_copy24={
                       {6{x_din0[24]}},
                       {6{x_din1[24]}},
                       {7{x_din2[24]}},
                       {7{x_din3[24]}}};
                       
  wire [CUT*(DW+1)-1:0]BUFFER_copy25={
                       {6{x_din0[25]}},
                       {6{x_din1[25]}},
                       {7{x_din2[25]}},
                       {7{x_din3[25]}}};
                       
  wire [CUT*(DW+1)-1:0]BUFFER_copy26={
                       {6{x_din0[26]}},
                       {6{x_din1[26]}},
                       {7{x_din2[26]}},
                       {7{x_din3[26]}}};
                       
  wire [CUT*(DW+1)-1:0]BUFFER_copy27={
                       {6{x_din0[27]}},
                       {6{x_din1[27]}},
                       {7{x_din2[27]}},
                       {7{x_din3[27]}}};
                       
  wire [CUT*(DW+1)-1:0]BUFFER_copy28={
                       {6{x_din0[28]}},
                       {6{x_din1[28]}},
                       {7{x_din2[28]}},
                       {7{x_din3[28]}}};
                       
  wire [CUT*(DW+1)-1:0]BUFFER_copy29={
                       {6{x_din0[29]}},
                       {6{x_din1[29]}},
                       {7{x_din2[29]}},
                       {7{x_din3[29]}}};
                       
  wire [CUT*(DW+1)-1:0]BUFFER_copy30={
                       {6{x_din0[30]}},
                       {6{x_din1[30]}},
                       {7{x_din2[30]}},
                       {7{x_din3[30]}}};
                       
  wire [CUT*(DW+1)-1:0]BUFFER_copy31={
                       {6{x_din0[31]}},
                       {6{x_din1[31]}},
                       {7{x_din2[31]}},
                       {7{x_din3[31]}}};
//--------------------------------------------------------------
//
//--------------------------------------------------------------
  (*dont_touch="true"*)reg [CUT*(DW+1)-1:0] r0_BUFFERX_Q17=0;
  (*dont_touch="true"*)reg [CUT*(DW+1)-1:0] r1_BUFFERX_Q17=0;
  (*dont_touch="true"*)reg [CUT*(DW+1)-1:0] r2_BUFFERX_Q17=0;
  (*dont_touch="true"*)reg [CUT*(DW+1)-1:0] r3_BUFFERX_Q17=0;
  always @ (posedge clk)
  begin
        r0_BUFFERX_Q17<=BUFFERX_Q17;
        r1_BUFFERX_Q17<=BUFFERX_Q17;
        r2_BUFFERX_Q17<=BUFFERX_Q17;
        r3_BUFFERX_Q17<=BUFFERX_Q17;
  end


  wire [CUT*(DW+1)-1:0]BUFFER_cut0 =r0_BUFFERX_Q17;
  wire [CUT*(DW+1)-1:0]BUFFER_cut1 =r0_BUFFERX_Q17;
  wire [CUT*(DW+1)-1:0]BUFFER_cut2 =r0_BUFFERX_Q17;
  wire [CUT*(DW+1)-1:0]BUFFER_cut3 =r0_BUFFERX_Q17;
  wire [CUT*(DW+1)-1:0]BUFFER_cut4 =r0_BUFFERX_Q17;
  wire [CUT*(DW+1)-1:0]BUFFER_cut5 =r0_BUFFERX_Q17;
  wire [CUT*(DW+1)-1:0]BUFFER_cut6 =r0_BUFFERX_Q17;
  wire [CUT*(DW+1)-1:0]BUFFER_cut7 =r0_BUFFERX_Q17;
  
  wire [CUT*(DW+1)-1:0]BUFFER_cut8 =r1_BUFFERX_Q17;
  wire [CUT*(DW+1)-1:0]BUFFER_cut9 =r1_BUFFERX_Q17;
  wire [CUT*(DW+1)-1:0]BUFFER_cut10=r1_BUFFERX_Q17;
  wire [CUT*(DW+1)-1:0]BUFFER_cut11=r1_BUFFERX_Q17;
  wire [CUT*(DW+1)-1:0]BUFFER_cut12=r1_BUFFERX_Q17;
  wire [CUT*(DW+1)-1:0]BUFFER_cut13=r1_BUFFERX_Q17;
  wire [CUT*(DW+1)-1:0]BUFFER_cut14=r1_BUFFERX_Q17;
  wire [CUT*(DW+1)-1:0]BUFFER_cut15=r1_BUFFERX_Q17;

  wire [CUT*(DW+1)-1:0]BUFFER_cut16=r2_BUFFERX_Q17;
  wire [CUT*(DW+1)-1:0]BUFFER_cut17=r2_BUFFERX_Q17;
  wire [CUT*(DW+1)-1:0]BUFFER_cut18=r2_BUFFERX_Q17;
  wire [CUT*(DW+1)-1:0]BUFFER_cut19=r2_BUFFERX_Q17;
  wire [CUT*(DW+1)-1:0]BUFFER_cut20=r2_BUFFERX_Q17;
  wire [CUT*(DW+1)-1:0]BUFFER_cut21=r2_BUFFERX_Q17;
  wire [CUT*(DW+1)-1:0]BUFFER_cut22=r2_BUFFERX_Q17;
  wire [CUT*(DW+1)-1:0]BUFFER_cut23=r2_BUFFERX_Q17;

  wire [CUT*(DW+1)-1:0]BUFFER_cut24=r3_BUFFERX_Q17;
  wire [CUT*(DW+1)-1:0]BUFFER_cut25=r3_BUFFERX_Q17;
  wire [CUT*(DW+1)-1:0]BUFFER_cut26=r3_BUFFERX_Q17;
  wire [CUT*(DW+1)-1:0]BUFFER_cut27=r3_BUFFERX_Q17;
  wire [CUT*(DW+1)-1:0]BUFFER_cut28=r3_BUFFERX_Q17;
  wire [CUT*(DW+1)-1:0]BUFFER_cut29=r3_BUFFERX_Q17;
  wire [CUT*(DW+1)-1:0]BUFFER_cut30=r3_BUFFERX_Q17;
  wire [CUT*(DW+1)-1:0]BUFFER_cut31=r3_BUFFERX_Q17;

//---------------------------------------------------------
//
//---------------------------------------------------------
  reg [CUT-1:0]compare[NUM-1:0];

  always @ (posedge clk)
  for(j=0;j<CUT;j=j+1)
  begin
       compare[0 ][j]<=$signed(BUFFER_copy0 [j*(DW+1)+:(DW+1)])<$signed(BUFFER_cut0 [j*(DW+1)+:(DW+1)]);
       compare[1 ][j]<=$signed(BUFFER_copy1 [j*(DW+1)+:(DW+1)])<$signed(BUFFER_cut1 [j*(DW+1)+:(DW+1)]);
       compare[2 ][j]<=$signed(BUFFER_copy2 [j*(DW+1)+:(DW+1)])<$signed(BUFFER_cut2 [j*(DW+1)+:(DW+1)]);
       compare[3 ][j]<=$signed(BUFFER_copy3 [j*(DW+1)+:(DW+1)])<$signed(BUFFER_cut3 [j*(DW+1)+:(DW+1)]);
       compare[4 ][j]<=$signed(BUFFER_copy4 [j*(DW+1)+:(DW+1)])<$signed(BUFFER_cut4 [j*(DW+1)+:(DW+1)]);
       compare[5 ][j]<=$signed(BUFFER_copy5 [j*(DW+1)+:(DW+1)])<$signed(BUFFER_cut5 [j*(DW+1)+:(DW+1)]);
       compare[6 ][j]<=$signed(BUFFER_copy6 [j*(DW+1)+:(DW+1)])<$signed(BUFFER_cut6 [j*(DW+1)+:(DW+1)]);
       compare[7 ][j]<=$signed(BUFFER_copy7 [j*(DW+1)+:(DW+1)])<$signed(BUFFER_cut7 [j*(DW+1)+:(DW+1)]);
       compare[8 ][j]<=$signed(BUFFER_copy8 [j*(DW+1)+:(DW+1)])<$signed(BUFFER_cut8 [j*(DW+1)+:(DW+1)]);
       compare[9 ][j]<=$signed(BUFFER_copy9 [j*(DW+1)+:(DW+1)])<$signed(BUFFER_cut9 [j*(DW+1)+:(DW+1)]);
       compare[10][j]<=$signed(BUFFER_copy10[j*(DW+1)+:(DW+1)])<$signed(BUFFER_cut10[j*(DW+1)+:(DW+1)]);
       compare[11][j]<=$signed(BUFFER_copy11[j*(DW+1)+:(DW+1)])<$signed(BUFFER_cut11[j*(DW+1)+:(DW+1)]);
       compare[12][j]<=$signed(BUFFER_copy12[j*(DW+1)+:(DW+1)])<$signed(BUFFER_cut12[j*(DW+1)+:(DW+1)]);
       compare[13][j]<=$signed(BUFFER_copy13[j*(DW+1)+:(DW+1)])<$signed(BUFFER_cut13[j*(DW+1)+:(DW+1)]);
       compare[14][j]<=$signed(BUFFER_copy14[j*(DW+1)+:(DW+1)])<$signed(BUFFER_cut14[j*(DW+1)+:(DW+1)]);
       compare[15][j]<=$signed(BUFFER_copy15[j*(DW+1)+:(DW+1)])<$signed(BUFFER_cut15[j*(DW+1)+:(DW+1)]);
       compare[16][j]<=$signed(BUFFER_copy16[j*(DW+1)+:(DW+1)])<$signed(BUFFER_cut16[j*(DW+1)+:(DW+1)]);
       compare[17][j]<=$signed(BUFFER_copy17[j*(DW+1)+:(DW+1)])<$signed(BUFFER_cut17[j*(DW+1)+:(DW+1)]);
       compare[18][j]<=$signed(BUFFER_copy18[j*(DW+1)+:(DW+1)])<$signed(BUFFER_cut18[j*(DW+1)+:(DW+1)]);
       compare[19][j]<=$signed(BUFFER_copy19[j*(DW+1)+:(DW+1)])<$signed(BUFFER_cut19[j*(DW+1)+:(DW+1)]);
       compare[20][j]<=$signed(BUFFER_copy20[j*(DW+1)+:(DW+1)])<$signed(BUFFER_cut20[j*(DW+1)+:(DW+1)]);
       compare[21][j]<=$signed(BUFFER_copy21[j*(DW+1)+:(DW+1)])<$signed(BUFFER_cut21[j*(DW+1)+:(DW+1)]);
       compare[22][j]<=$signed(BUFFER_copy22[j*(DW+1)+:(DW+1)])<$signed(BUFFER_cut22[j*(DW+1)+:(DW+1)]);
       compare[23][j]<=$signed(BUFFER_copy23[j*(DW+1)+:(DW+1)])<$signed(BUFFER_cut23[j*(DW+1)+:(DW+1)]);
       compare[24][j]<=$signed(BUFFER_copy24[j*(DW+1)+:(DW+1)])<$signed(BUFFER_cut24[j*(DW+1)+:(DW+1)]);
       compare[25][j]<=$signed(BUFFER_copy25[j*(DW+1)+:(DW+1)])<$signed(BUFFER_cut25[j*(DW+1)+:(DW+1)]);
       compare[26][j]<=$signed(BUFFER_copy26[j*(DW+1)+:(DW+1)])<$signed(BUFFER_cut26[j*(DW+1)+:(DW+1)]);
       compare[27][j]<=$signed(BUFFER_copy27[j*(DW+1)+:(DW+1)])<$signed(BUFFER_cut27[j*(DW+1)+:(DW+1)]);
       compare[28][j]<=$signed(BUFFER_copy28[j*(DW+1)+:(DW+1)])<$signed(BUFFER_cut28[j*(DW+1)+:(DW+1)]);
       compare[29][j]<=$signed(BUFFER_copy29[j*(DW+1)+:(DW+1)])<$signed(BUFFER_cut29[j*(DW+1)+:(DW+1)]);
       compare[30][j]<=$signed(BUFFER_copy30[j*(DW+1)+:(DW+1)])<$signed(BUFFER_cut30[j*(DW+1)+:(DW+1)]);
       compare[31][j]<=$signed(BUFFER_copy31[j*(DW+1)+:(DW+1)])<$signed(BUFFER_cut31[j*(DW+1)+:(DW+1)]);
  end

 //---------------------------------------------------------------------------------
 //
 //---------------------------------------------------------------------------------
 
  always @ (posedge clk)
  for(i=0;i<NUM;i=i+1)
  begin
      index  [i]<=
      compare[i][25]+
      compare[i][24]+
      compare[i][23]+
      compare[i][22]+
      compare[i][21]+
      compare[i][20]+
      compare[i][19]+
      compare[i][18]+
      compare[i][17]+
      compare[i][16]+
      compare[i][15]+
      compare[i][14]+
      compare[i][13]+
      compare[i][12]+
      compare[i][11]+
      compare[i][ 9]+
      compare[i][ 8]+
      compare[i][ 7]+
      compare[i][ 6]+
      compare[i][ 5]+
      compare[i][ 4]+
      compare[i][ 3]+
      compare[i][ 2]+
      compare[i][ 1]+
      compare[i][ 0];
  end
*/




endmodule
