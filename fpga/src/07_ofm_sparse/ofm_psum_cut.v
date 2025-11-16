`timescale 1ns / 1ps
// -----------------------------------------------------------------------------
// Orgnization: UCLA EDA lab
// Design Name    : opu series
// Module Name    : output_ctrl_top
// Target Devices : k325t
// Tool Versions  : Vivado 2020.1, Modelsim 2019.4
// Description    : 
//    Add bias or temp results to finalize the calculation of one convolutional
//    layer.
// Revision       :
// Version        Date        Author          Description
// 1.0            2017-10-25  Chen Wu         Initial version
// 1.1            2020-02-04  Chen Wu         Modify code style
// 3.1            2021-02-01  Shan Shen       Change data width to 42 from 26
// 3.2            2021-04-07  Jinming Zhuang  Modify & specify the sequential 
//                                            relationship in internal signals
// 4.0            2021-04-26  Chen Wu         Add parameter & delete rearrange
// 4.1            2022-04--7  Chen Wu         Simplify for INT16 case, add pp
// 5.0            2022-09-14  Shaoqiang       Simulation 97 layers,and       
//                                            implementation on FPGA of U200.
// -----------------------------------------------------------------------------

`include "opu_parameter.vh"

module ofm_psum_cut#(
  parameter                         NUM         =   128     ,
  parameter                         PNUM        =   4       ,
  parameter                         DW_ADD      =   42      , 
  parameter                         DW_RAM      =   32      ,
  parameter                         DW_NVM      =   16      ,
  parameter                         DLY_INST_CUT=   9
)(
  input                             clk                     ,
  input                             reset                   ,
  input                             ofm_output_sel          ,
  input                             ofm_rstart              ,
  input      [15-1:0]               ofm_wbase               ,
  input                             data_in_vld             ,
  input      [NUM*DW_ADD-1:0]       data_in                 ,
  output reg [NUM -1:0][DW_RAM-1:0] ofm_wdata      =0       ,
  output reg [PNUM-1:0][15-1:0]     ofm_waddr      =0       ,
  output reg [PNUM-1:0]             ofm_wdata_vld  =0        
);

integer i=0,j=0;


//---------------------------------------------------------------------
// Q42_43--->Q32_33
//---------------------------------------------------------------------

reg                 [NUM*DW_RAM-1:0]    psum_data       =0      ;//32 
reg                                     psum_data_vld   =0      ;//32 

reg                 [NUM-1:0]           psum_data_pos   =0      ;
reg                 [NUM-1:0]           psum_data_neg   =0      ;

reg                 [NUM-1:0]           psum_data_ctrl  =0      ;

always @(posedge clk)
for(i=0;i<NUM;i=i+1)
begin
    psum_data[i*DW_RAM+:DW_RAM]<=data_in[i*DW_ADD+(DW_ADD-1)-:DW_RAM];
    psum_data_vld              <=data_in_vld                    ;
    psum_data_ctrl[i]<=data_in[i*DW_ADD+DW_NVM+(DW_ADD-DW_RAM)-1]
    &&(16'h7fff)!=data_in[i*DW_ADD+DW_NVM+(DW_ADD-DW_RAM)+:DW_NVM]
    ;
end


//-------------------------------------------------------------------------
//
//-------------------------------------------------------------------------
(*dont_touch="true"*)reg [NUM-1:0]  r_ofm_output_sel    =0      ;
wire [15-1:0]                       r_ofm_wbase                 ;
wire                                r_ofm_rstart                ; 

reg [NUM*DW_RAM-1:0]                psum_cut_data       =0      ;
reg                                 psum_cut_data_vld   =0      ;
reg                                 psum_cut_data_end   =0      ;
always @(posedge clk)
for(i=0;i<NUM;i=i+1)
if(r_ofm_output_sel[i])
begin 

if(psum_data_ctrl[i])begin
     psum_cut_data[i*DW_RAM+1*DW_NVM+:DW_NVM]<={DW_NVM{1'b0}}   ;
     psum_cut_data[i*DW_RAM+0*DW_NVM+:DW_NVM]<=
     psum_data[i*DW_RAM+DW_NVM+:DW_NVM]+1'b1                    ; 
end 
else begin
     psum_cut_data[i*DW_RAM+1*DW_NVM+:DW_NVM]<={DW_NVM{1'b0}}   ;
     psum_cut_data[i*DW_RAM+0*DW_NVM+:DW_NVM]<=
     psum_data[i*DW_RAM+DW_NVM+:DW_NVM]                         ; 
end
end
else psum_cut_data[i*DW_RAM+:DW_RAM]<=psum_data[i*DW_RAM+:DW_RAM];


always @(posedge clk)
begin
    psum_cut_data_end    <=psum_data_vld&&r_ofm_output_sel[0]   ;
    psum_cut_data_vld    <=psum_data_vld                        ;
end



//--------------------------------------------------------------------------
//
//--------------------------------------------------------------------------

always @(posedge clk)
begin
    ofm_wdata_vld        <={4{psum_cut_data_vld}}               ;
    
    for(i=0;i<NUM;i=i+1)
    ofm_wdata[i]         <=psum_cut_data[i*DW_RAM+:DW_RAM]      ;
end


//--------------------------------------------------------------------------
//
//--------------------------------------------------------------------------

  reg [DLY_INST_CUT*17-1:0] dly_sb_reg =0                       ;
  always @(posedge clk)
  for(i=0;i<DLY_INST_CUT;i=i+1)
  if(i==0)dly_sb_reg[i*17+:17]<=
          {ofm_output_sel,ofm_wbase,ofm_rstart}                 ;
  else    dly_sb_reg[i*17+:17]<=dly_sb_reg[(i-1)*17+:17]        ;
  

  always @(posedge clk)
  r_ofm_output_sel<={NUM{dly_sb_reg[(DLY_INST_CUT-2)*17+1+15+:1]}};


  
  assign r_ofm_wbase =dly_sb_reg[(DLY_INST_CUT-1)*17+1+:15]     ;
  assign r_ofm_rstart=dly_sb_reg[(DLY_INST_CUT-1)*17+0+:1 ]     ;
  
  always @(posedge clk)
  for(i=0;i<4;i=i+1)
  begin
      if(r_ofm_rstart)      ofm_waddr[i]<=r_ofm_wbase           ;
      else if(ofm_wdata_vld)ofm_waddr[i]<=ofm_waddr[i]+PNUM     ;
  end



`ifdef SIM_CODE
    reg [DW_ADD-1:0]        test_data_in        [NUM-1:0]       ;
    reg [DW_RAM-1:0]        test_psum_data      [NUM-1:0]       ;
    reg [DW_RAM-1:0]        test_psum_cut_data  [NUM-1:0]       ;
    
    reg [DW_ADD-1:0]        test_psum_cnt       =0              ;
    
    always @(*)for(i=0;i<NUM;i=i+1)
    begin
       test_data_in      [i]<=data_in      [i*DW_ADD+:DW_ADD]   ;
       test_psum_data    [i]<=psum_data    [i*DW_RAM+:DW_RAM]   ; 
       test_psum_cut_data[i]<=psum_cut_data[i*DW_RAM+:DW_RAM]   ; 
    end
    
    always @(posedge clk)  
    if(psum_cut_data_vld)   test_psum_cnt<=test_psum_cnt+1      ;
    
    
`endif



endmodule
