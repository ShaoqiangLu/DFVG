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
module ofm_adder#(
  parameter     NUM                 =   128                 ,
  parameter     DW_ADD              =   42                  ,
  parameter     DW_RAM              =   32                  ,
  parameter     DLY_INST_ADD        =   3                    
)(
  input                             clk                     ,
  input                             reset                   ,

  input                             ofm_bias_sel            ,
  input                             ofm_tmp_sel             ,
  
  input                             ofm_ina_vld             ,
  input  [NUM-1:0][DW_ADD-1:0]      ofm_ina                 ,

  
  input  [NUM-1:0][DW_ADD-1:0]      bias_inb                ,
  input                             bias_inb_vld            ,

  input                             temp_inb_vld            ,
  input  [NUM-1:0][DW_RAM-1:0]      temp_inb                ,

  output wire [NUM-1:0][DW_ADD-1:0] adder_result            ,
  output reg                        adder_result_vld =0      
);
 
integer i=0,j=0;


reg     [DLY_INST_ADD*2-1:0]        dly_btsel     =0        ;
(*dont_touch="true"*)reg [NUM-1:0]  r_ofm_bias_sel=0        ;
(*dont_touch="true"*)reg [NUM-1:0]  r_ofm_tmp_sel =0        ;


always @(posedge clk)
for(i=0;i<DLY_INST_ADD;i=i+1)
if(i==0)dly_btsel[i*2+:2]<={ofm_bias_sel,ofm_tmp_sel}       ;
else    dly_btsel[i*2+:2]<= dly_btsel[(i-1)*2+:2]           ;

always @(posedge clk)
begin
r_ofm_bias_sel<={NUM{dly_btsel[(DLY_INST_ADD-1)*2+1]}}      ;
r_ofm_tmp_sel <={NUM{dly_btsel[(DLY_INST_ADD-1)*2+0]}}      ;
end



reg         [DW_ADD*NUM-1:0]     adder_ina  =0              ;
reg         [DW_ADD*NUM-1:0]     adder_inb  =0              ;

wire        [NUM-1:0]            adder_out_pos_max          ;
wire        [NUM-1:0]            adder_out_neg_min          ;

wire        [NUM*(DW_ADD+1)-1:0] adder_out                  ;



always @(posedge clk)
for(i=0;i<NUM;i=i+1)
begin
    adder_ina[i*DW_ADD+:DW_ADD]<=ofm_ina[i]                 ;
    //
    if(r_ofm_bias_sel[i])
         adder_inb[i*DW_ADD+:DW_ADD]<=bias_inb[i]           ;
    else if(r_ofm_tmp_sel[i]) 
         adder_inb[i*DW_ADD+:DW_ADD]<=
         {temp_inb[i],{(DW_ADD-DW_RAM){1'b0}}}              ;
    else adder_inb[i*DW_ADD+:DW_ADD]<=0                     ;
    
end

//------------------------------------------------------------
// 2cycle 
//------------------------------------------------------------


generate 
for (genvar i=0;i<NUM;i=i+1) 
  begin:add   
  (*keep_hierarchy="yes"*)
  ADD_ofm1 ADD1 (
    .CLK    (clk                                            ), 
    .A      (adder_ina   [i*DW_ADD+:DW_ADD]                 ), 
    .B      (adder_inb   [i*DW_ADD+:DW_ADD]                 ), 
    .S      (adder_out   [i*(DW_ADD+1)+:(DW_ADD+1)]         )  
  );   

  assign adder_out_pos_max[i]
        =adder_out[i*(DW_ADD+1)+(DW_ADD+1)-1]==0
       &&adder_out[i*(DW_ADD+1)+(DW_ADD+1)-2]==1;
  
  assign adder_out_neg_min[i]
        =adder_out[i*(DW_ADD+1)+(DW_ADD+1)-1]==1
       &&adder_out[i*(DW_ADD+1)+(DW_ADD+1)-2]==0;
  

  assign adder_result[i]=
         adder_out_pos_max[i]?{1'b0,{41{1'b1}}}:
         adder_out_neg_min[i]?{1'b1,{41{1'b0}}}:
        {adder_out[i*(DW_ADD+1)+(DW_ADD+1)-1],
         adder_out[i*(DW_ADD+1)+:DW_ADD-1]
        };  
end
endgenerate


reg         r0_adder_result_vld         =0                  ; 
reg         r1_adder_result_vld         =0                  ;       

always @(posedge clk)
begin

    if(r_ofm_tmp_sel[0])
            r0_adder_result_vld<=ofm_ina_vld&bias_inb_vld   ;
    else if(r_ofm_tmp_sel[0])
            r0_adder_result_vld<=ofm_ina_vld&temp_inb_vld   ;
    else    r0_adder_result_vld<=ofm_ina_vld                ;


    r1_adder_result_vld     <=r0_adder_result_vld           ;
    adder_result_vld        <=r1_adder_result_vld           ;
end


`ifdef SIM_CODE
     reg [DW_ADD-1:0] test_adder_ina    [NUM-1:0]           ;
     reg [DW_ADD-1:0] test_adder_inb    [NUM-1:0]           ;
     
     always @(*)for(i=0;i<NUM;i=i+1)
     begin
         test_adder_ina[i]<=adder_ina[i*DW_ADD+:DW_ADD]     ;
         test_adder_inb[i]<=adder_inb[i*DW_ADD+:DW_ADD]     ;
     end

`endif



endmodule
