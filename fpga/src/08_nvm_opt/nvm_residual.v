`timescale 1ns / 1ps
// -----------------------------------------------------------------------------
// Copyright      : UCLA EDA LAB
// -----------------------------------------------------------------------------
// Engineer       : Chen Wu
// Design Name    : opu series
// Module Name    : res_top
// Target Devices : 325t, Alveo U200
// Tool Versions  : Vivado 2020.1, Modelsim 2019.4
// Description    : 
//    Residual top.
//    Delay: 2 cycles
//
// Revision       :
// Version        Date        Author        Descriptin
// 1.0            2022-04-08  Chen Wu       Initial version
// 2.0            2023-08-25  Shaoqiang     Implementation in U200
// -----------------------------------------------------------------------------


module nvm_residual # (
  parameter               NUM         =     32                      ,
  parameter               DW          =     16                      ,
  localparam              ADW         =     NUM * DW                
) (
  input                               clk                           ,
  input                               reset                         ,
  input                               res_en                        ,
  
  input                               res_din_vld                   ,
  input                               res_din_done                  , 
  input             [ADW-1 : 0]       res_din_data                  ,//Q16_14
  
  input             [ADW-1 : 0]       nvm_din_data                  ,//Q16_14
  input                               nvm_din_vld                   ,
  input                               nvm_din_done                  ,

  output  wire                        res_dout_vld                  ,
  output  wire                        res_dout_done                 ,
  output  reg       [NUM-1:0][DW-1:0] res_dout_data     =0            //Q16_14
            
);

  integer i=0,j=0;
  
  reg [3*ADW-1 : 0]           r_nvm_din_data =0                     ;//Q16_14
  reg [3-1:0]                 r_nvm_din_vld  =0                     ;
  reg [3-1:0]                 r_nvm_din_done =0                     ;
  always @(posedge clk)
  for(i=0;i<3;i=i+1)
  if(i==0)begin
    r_nvm_din_data[i*ADW+:ADW]<=nvm_din_data                        ;
    r_nvm_din_vld [i*1  +:1  ]<=nvm_din_vld                         ;
    r_nvm_din_done[i*1  +:1  ]<=nvm_din_done                        ;
  end else begin
    r_nvm_din_data[i*ADW+:ADW]<=r_nvm_din_data[(i-1)*ADW+:ADW]      ;
    r_nvm_din_vld [i*1  +:1  ]<=r_nvm_din_vld [(i-1)*1  +:1  ]      ;
    r_nvm_din_done[i*1  +:1  ]<=r_nvm_din_done[(i-1)*1  +:1  ]      ;
  
  end


  reg [ADW-1:0] A_res_din=0                                         ;//Q16_14
  reg [ADW-1:0] B_nvm_din=0                                         ;//Q16_14
  always @(posedge clk)
  begin
          A_res_din<=res_din_data                                   ;
          B_nvm_din<=r_nvm_din_data[(3-1)*ADW+:ADW]                 ;
  end
  localparam RDW = NUM * (DW+1)                                     ;
  localparam LB  = {1'b1,{(DW-1){1'b0}}}                            ;
  localparam UB  = {1'b0,{(DW-1){1'b1}}}                            ;

//------------------------------------------------------------------------
//
//------------------------------------------------------------------------
  wire [RDW-1:0]res_add_out                                         ;

  generate for(genvar i=0;i<NUM;i=i+1)//1 cycle
  begin: g
    (*keep_hierarchy="yes"*)ADD_RES ADD (
      .CLK   (clk                                                   ),// input  wire CLK
      .A     (A_res_din[DW*i+:DW]                                   ),// input  wire [15 : 0] A
      .B     (B_nvm_din[DW*i+:DW]                                   ),// input  wire [15 : 0] B
      .S     (res_add_out[(DW+1)*i+:(DW+1)]                         ) // output wire [15 : 0] S
    );

    always @(posedge clk)
         if (res_add_out [(DW+1)*i+(DW+1)-1] == 
             res_add_out [(DW+1)*i+(DW+1)-2])
             res_dout_data[i]<=
             res_add_out [(DW+1)*i+:DW     ]                        ;
    else if (res_add_out [(DW+1)*i+(DW+1)-1]) 
             res_dout_data[i]<=LB                                   ;
    else     res_dout_data[i]<=UB                                   ;
  end
  endgenerate

  //---------------------------------------------------------------------
  //
  //---------------------------------------------------------------------
  localparam          DLY_RES         =3                            ;
  reg [DLY_RES*2-1:0] dey_vd_reg      =0                            ;

  always @(posedge clk)
  for(i=0;i<DLY_RES;i=i+1)
  if(i==0)dey_vd_reg[i*2+:2]<=
         {res_en&res_din_vld &r_nvm_din_vld [2]                     ,
          res_en&res_din_done&r_nvm_din_done[2]}                    ;
  else    dey_vd_reg[i*2+:2]<=dey_vd_reg[(i-1)*2+:2]                ;

  assign  res_dout_vld  = dey_vd_reg[(DLY_RES-1)*2+1+:1]            ;
  assign  res_dout_done = dey_vd_reg[(DLY_RES-1)*2+0+:1]            ;




endmodule