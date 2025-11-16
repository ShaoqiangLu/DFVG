`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/19/2024 06:44:11 PM
// Design Name: 
// Module Name: divider_share
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
//--------------------------------------------------------------
//32 shared dividers, used by sf and ln
//-------------------------------------------------------------- 
//dout = dividend / divisor
//DIV_share :The integer    is [39:16]_Q24_0 ,
//           The fractional is [15:0 ]_Q16_15
//1) softmax the dout_tdata always is 0<= result <1,
//   According to the calculation formula of softmax,
//   So we just need to take the fractional, is [15:0].
//
//2) layernorm Both integers and residues are required.
//    
//div is 27 cycles

module nvm_div_share#(
    parameter     DW               = 16,
    parameter     NUM              = 32,
    parameter     DLY_DIV          = 20
)(
    input                          clk     ,
    input                          reset   ,
    input                          sf_en   ,
    input                          ln_en   ,
    
    input                          sf_exp_fifo_val    ,
    input                          sf_exp_fifo_done   ,
    input         [NUM*(DW+1)-1:0] sf_exp_fifo_data   ,
    input         [NUM*(DW+1)-1:0] ln_sub_fifo_data   ,
    input                          ln_sub_fifo_val    ,
    input                          ln_sub_fifo_done   ,
    
    input                          sf_sum_out_vld     ,
    input                          sf_sum_out_done    ,
    input         [NUM-1:0][24-1:0]sf_sum_out_data    ,
    input         [NUM-1:0][24-1:0]ln_sqrt_out_data   ,
    input                          ln_sqrt_out_vld    ,
    input                          ln_sqrt_out_done   ,
    
    output  wire                   sf_div_result_vld  ,
    output  wire                   sf_div_result_done ,
    output  reg  [NUM-1:0][24-1:0] sf_div_result_data=0,
    output  reg  [NUM-1:0][24-1:0] ln_div_result_data=0,
    output  wire                   ln_div_result_vld  ,
    output  wire                   ln_div_result_done ,
    
    output  reg  [NUM-1:0]         s_axis_divisor_tvalid  ={NUM{1'b1}},
    output  reg  [NUM-1:0][24-1:0] s_axis_divisor_tdata   ={NUM{1'b1}},
    output  reg  [NUM-1:0][24-1:0] s_axis_dividend_tdata  ={NUM{1'b1}}, 
    output  reg  [NUM-1:0]         s_axis_dividend_tvalid ={NUM{1'b1}},
    
    input   wire [NUM-1:0]         m_axis_dout_tvalid     ,
    input   wire [NUM*40-1:0]      m_axis_dout_tdata      
);

integer i=0,j=0;

(*max_fanout=32*)reg r0_sf_en=0;
(*max_fanout=32*)reg r0_ln_en=0;
(*max_fanout=32*)reg r1_sf_en=0;
(*max_fanout=32*)reg r1_ln_en=0;

always @(posedge clk)
begin
    r0_sf_en<=sf_en;
    r0_ln_en<=ln_en;
    r1_sf_en<=sf_en;
    r1_ln_en<=ln_en;
end



always @(posedge clk)
for(i=0;i<NUM;i=i+1)
if(r1_sf_en)     s_axis_divisor_tvalid[i]<=sf_sum_out_vld ;
else if(r1_ln_en)s_axis_divisor_tvalid[i]<=ln_sqrt_out_vld;
else             s_axis_divisor_tvalid[i]<=0              ;

//sf Q32_14--> Q24_14          
//ln1:Q32_14,ln2:Q32_9-->Q24_14
always @(posedge clk)
for(i=0;i<NUM;i=i+1) 
if(r1_sf_en)     s_axis_divisor_tdata[i]<=sf_sum_out_data [i];
else if(r1_ln_en)s_axis_divisor_tdata[i]<=ln_sqrt_out_data[i];
else             s_axis_divisor_tdata[i]<=0;

//----------------------------------------------------------------------
always @(posedge clk)
for(i=0;i<NUM;i=i+1)
if(r1_sf_en)     s_axis_dividend_tvalid[i]<=sf_exp_fifo_val;
else if(r1_ln_en)s_axis_dividend_tvalid[i]<=ln_sub_fifo_val;
else             s_axis_dividend_tvalid[i]<=0              ;

//sf Q32_14--> Q24_14          
//ln1:Q32_14,ln2:Q32_9-->Q24_14
always @(posedge clk)
for(i=0;i<NUM;i=i+1) 
if(r1_sf_en)     s_axis_dividend_tdata[i]<={{(24-DW-0){sf_exp_fifo_data[i*(DW+0)+(DW+0)-1]}},sf_exp_fifo_data[i*(DW+0)+:(DW+0)]};
else if(r1_ln_en)s_axis_dividend_tdata[i]<={{(24-DW-1){ln_sub_fifo_data[i*(DW+1)+(DW+1)-1]}},ln_sub_fifo_data[i*(DW+1)+:(DW+1)]};
else             s_axis_dividend_tdata[i]<=0;


//----------------------------------------------------------------------
//
//----------------------------------------------------------------------
//sf Fix need Low16bit_Q16_15,ln both need High24bit_[39:16],Low16bit_[15:0]
//so (Q24_0)<<<15 + Q16_15------>Q24_15
reg [NUM*24-1:0]    m_result_int=0;
reg [NUM*24-1:0]    m_result_poi=0;

always @ (posedge clk)
for(i=0;i<NUM;i=i+1) 
begin
    m_result_int[i*24+:24]<={   m_axis_dout_tdata[i*40+ 16+:9],15'd0};//integer, Q24_15
    m_result_poi[i*24+:24]<={{9{m_axis_dout_tdata[i*40+ 15]}},
                                m_axis_dout_tdata[i*40+:15]};//point  , Q24_15
end

always @ (posedge clk)
for(i=0;i<NUM;i=i+1) 
begin
    sf_div_result_data[i]<=m_result_int[i*24+:24]+m_result_poi[i*24+:24];//-------->Q24_15
    ln_div_result_data[i]<=m_result_int[i*24+:24]+m_result_poi[i*24+:24];//-------->Q24_15
end


//----------------------------------------------------------------------
//
//----------------------------------------------------------------------
                   
reg [DLY_DIV*4-1:0] dly_vd=0;
always @ (posedge clk)
for(i=0;i<DLY_DIV;i=i+1) 
if(i==0)dly_vd[i*4+:4]<={
     sf_sum_out_vld  &r1_sf_en,
     sf_sum_out_done &r1_sf_en,
     ln_sqrt_out_vld &r1_ln_en,
     ln_sqrt_out_done&r1_ln_en};
else dly_vd[i*4+:4]<=dly_vd[(i-1)*4+:4];

assign sf_div_result_vld =dly_vd[(DLY_DIV-1)*4+3];
assign sf_div_result_done=dly_vd[(DLY_DIV-1)*4+2];
assign ln_div_result_vld =dly_vd[(DLY_DIV-1)*4+1];
assign ln_div_result_done=dly_vd[(DLY_DIV-1)*4+0];




endmodule
