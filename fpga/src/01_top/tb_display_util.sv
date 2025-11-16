`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/13/2023 09:56:44 AM
// Design Name: 
// Module Name: point
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: You can check the size of the fixed point number. 
//              And I will help you save the data.
//              Note that this is a circuit that cannot be integrated. 
//              Just for your convenience in debugging
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 1.0            2023-09-11  Shaoqiang     Functional simulation testing,
//                                         implementation on FPGA of U200.
//////////////////////////////////////////////////////////////////////////////////
//       d_layer_each,(0.00000333*d_layer_each),
//       d_pe_dsp    ,(d_pe_dsp  /d_layer_each),
//       d_nvm_dsp   ,(d_nvm_dsp /d_layer_each),
//       (d_pe_dsp+d_nvm_dsp),((d_pe_dsp+d_nvm_dsp)/d_layer_each),
//       d_nvm_sync  ,(d_nvm_sync/d_layer_each),
//       d_nvm_util_cnt,(0.00000333*d_nvm_util_cnt),
//       d_axi_cnt,     (0.00000333*d_axi_cnt),
//       (d_latency_cnt *0.00000333)



module tb_display_util#(
    parameter     FILE0  =  "/home/lsq/Desktop/opu/rtl/src/12_data/",
    parameter     FILE1  =  "_debug_inst_dec.txt"
)(
    input                   clk                 ,
    input                   core_layer_start    ,
    input                   core_layer_done     ,
    input   [9 :0]          core_layer_cnt      ,
    input   [31:0]          core_latency_cnt    ,
    input                   axi_util_load       ,
    input                   axi_util_store      ,
    input   [1024-1:0]      pe_act_val          ,
 
    input                   d_nvm_total         ,
    input                   d_nvm_dsp           ,
    input                   d_nvm_div           ,
    input                   d_nvm_sync          ,
    input                   d_nvm_back
);

localparam MS =3.3*0.000001;
localparam PCT=100;

//---------------------------------------------------------------
//
//---------------------------------------------------------------
integer file,i=0,j=0;
initial file  = $fopen({FILE0,FILE1},"w");


//---------------------------------------------------------------
//
//---------------------------------------------------------------

wire[10-1:0]    layer      =core_layer_cnt      ;
wire[32-1:0]    latency    =core_latency_cnt    ;
real            layer_each =0                   ;
real            axi_load   =0                   ;
real            axi_store  =0                   ;

real            dsp_all    =0                   ;

real            pe_array   =0                   ;
reg [32*6-1:0]  pe_act1    =0                   ;
reg [16  -1:0]  pe_act2    =0                   ;
real            pe_act     =0                   ;

real            nvm_total  =0                   ;
real            nvm_dsp    =0                   ;
real            nvm_div    =0                   ;
real            nvm_sync   =0                   ;
real            nvm_back   =0                   ;



always @(posedge clk)
if(core_layer_start)    layer_each<=0           ;
else                    layer_each<=layer_each+1;


always @(posedge clk)
if(core_layer_start)
begin
    axi_load    <=0;
    axi_store   <=0;
end
else begin
    if(axi_util_load)  axi_load <=axi_load+1   ;
    if(axi_util_store) axi_store<=axi_store+1  ;
end

always @(posedge clk)
if(core_layer_start)    
begin
    pe_array    <=0                             ;
    pe_act      <=0                             ;
end
else if(|pe_act_val)    
begin
    pe_array    <=pe_array+1                    ;
    pe_act      <=pe_act+pe_act2                ;
end


always @(posedge clk)
if(core_layer_start)
begin
    nvm_total   <=0 ;
    nvm_dsp     <=0 ;
    nvm_div     <=0 ;
    nvm_sync    <=0 ;
    nvm_back    <=0 ;
end 
else begin
    if(d_nvm_total)nvm_total<=nvm_total +1      ;
    if(d_nvm_dsp  )nvm_dsp  <=nvm_dsp   +1      ;
    if(d_nvm_div  )nvm_div  <=nvm_div   +1      ;
    if(d_nvm_sync )nvm_sync <=nvm_sync  +1      ;
    if(d_nvm_back )nvm_back <=nvm_back  +1      ;
end

always @(*)dsp_all=pe_array+nvm_dsp;


always @(posedge clk)
if(core_layer_done)
$fwrite(file, "layer=%0.0f,  latency=%0.4fms,  each=%0.0f/%0.4fms,  load=%0.0f/%0.4fms(%0.0f%%),  store=%0.0f/%0.4fms(%0.0f%%),  dsp_all=%0.0f/%0.4fms(%0.0f%%),  pe_array=%0.0f/%0.4fms(%0.0f%%)[act=%0.0f/(%0.0f%%)],  nvm_total=%0.0f/%0.4fms(%0.0f%%)[dsp=%0.0f/%0.0f%%,div=%0.0f/%0.0f%%,sync=%0.0f/%0.0f%%,back=%0.0f/%0.0f%%]\n",
layer           ,
latency*MS      ,
layer_each      ,layer_each*MS  ,
axi_load        ,axi_load  *MS  ,(axi_load /layer_each)*PCT   ,
axi_store       ,axi_store *MS  ,(axi_store/layer_each)*PCT   ,
dsp_all         ,dsp_all   *MS  ,(dsp_all  /layer_each)*PCT   ,
pe_array        ,pe_array  *MS  ,(pe_array /layer_each)*PCT   ,(pe_act/pe_array)*PCT,(pe_act  /(pe_array*1024))*PCT,
nvm_total       ,nvm_total *MS  ,(nvm_total/layer_each)*PCT   , nvm_dsp             ,(nvm_dsp /nvm_total      )*PCT,
                                                                nvm_div             ,(nvm_div /nvm_total      )*PCT,
                                                                nvm_sync            ,(nvm_sync/nvm_total      )*PCT,
                                                                nvm_back            ,(nvm_back/nvm_total      )*PCT
); 



always @(pe_act_val)
begin
for(i=0;i<32;i=i+1)
pe_act1[i*6+:6]=
    pe_act_val[32*i+31]+pe_act_val[32*i+30]+pe_act_val[32*i+29]+pe_act_val[32*i+28]+
    pe_act_val[32*i+27]+pe_act_val[32*i+26]+pe_act_val[32*i+25]+pe_act_val[32*i+24]+
    pe_act_val[32*i+23]+pe_act_val[32*i+22]+pe_act_val[32*i+21]+pe_act_val[32*i+20]+
    pe_act_val[32*i+19]+pe_act_val[32*i+18]+pe_act_val[32*i+17]+pe_act_val[32*i+16]+
    pe_act_val[32*i+15]+pe_act_val[32*i+14]+pe_act_val[32*i+13]+pe_act_val[32*i+12]+
    pe_act_val[32*i+11]+pe_act_val[32*i+10]+pe_act_val[32*i+9 ]+pe_act_val[32*i+8 ]+
    pe_act_val[32*i+7 ]+pe_act_val[32*i+6 ]+pe_act_val[32*i+5 ]+pe_act_val[32*i+4 ]+
    pe_act_val[32*i+3 ]+pe_act_val[32*i+2 ]+pe_act_val[32*i+1 ]+pe_act_val[32*i+0 ];
end

always @(pe_act1)
begin
pe_act2=
    pe_act1[6*31+:6]+pe_act1[6*30+:6]+pe_act1[6*29+:6]+pe_act1[6*28+:6]+
    pe_act1[6*27+:6]+pe_act1[6*26+:6]+pe_act1[6*25+:6]+pe_act1[6*24+:6]+
    pe_act1[6*23+:6]+pe_act1[6*22+:6]+pe_act1[6*21+:6]+pe_act1[6*20+:6]+
    pe_act1[6*19+:6]+pe_act1[6*18+:6]+pe_act1[6*17+:6]+pe_act1[6*16+:6]+
    pe_act1[6*15+:6]+pe_act1[6*14+:6]+pe_act1[6*13+:6]+pe_act1[6*12+:6]+
    pe_act1[6*11+:6]+pe_act1[6*10+:6]+pe_act1[6*9 +:6]+pe_act1[6*8 +:6]+
    pe_act1[6*7 +:6]+pe_act1[6*6 +:6]+pe_act1[6*5 +:6]+pe_act1[6*4 +:6]+
    pe_act1[6*3 +:6]+pe_act1[6*2 +:6]+pe_act1[6*1 +:6]+pe_act1[6*0 +:6];
end









endmodule
