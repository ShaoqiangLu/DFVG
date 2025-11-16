`timescale 1ns / 1ps
// -----------------------------------------------------------------------------
// Copyright      : UCLA EDA LAB
// -----------------------------------------------------------------------------
// Engineer       : Chen Wu
// Design Name    : opu series
// Module Name    : nvm_top
// Target Devices : 325t, Alveo U200
// Tool Versions  : Vivado 2020.1, Modelsim 2019.4
// Description    : 
//    Post processes including: residual, GeLU, Softmax, LayerNormalization,
//    Transpose. Each feature can be enabled or not.
//    Attention   : In this design, DW * NUM must be 512 (DDR Datawidth)
//----------------------------------------------------------------------------


module nvm_dsp_share #(
parameter NUM =  32          
) (
  input        clk    ,
  input        reset  ,         
 
  input        act_en , 
  input        sf_en  , 
  input        ln_en  , 

  input        [NUM-1:0][17-1:0]A_squ_out      , 
  input        [NUM-1:0][17-1:0]B_squ_out      , 
  output  reg  [NUM-1:0][34-1:0]P_squ_in =0    ,

  input        [NUM*17-1:0]     A_act_out      , 
  input        [NUM*15-1:0]     B_act_out      , 
  input        [NUM*32-1:0]     C_act_out      , 
  input        [NUM*17-1:0]     D_act_out      , 
  output  reg  [NUM-1:0][32-1:0]P_act_in =0    ,
 
  input        [NUM*17-1:0]     A_exp_out      ,
  input        [NUM*15-1:0]     B_exp_out      , 
  input        [NUM*32-1:0]     C_exp_out      , 
  input        [NUM*17-1:0]     D_exp_out      , 
  output  reg  [NUM-1:0][32-1:0]P_exp_in =0    , 
 
  input        [NUM*24-1:0]     A_mac_out      ,
  input        [NUM*16-1:0]     B_mac_out      ,
  input        [NUM*40-1:0]     C_mac_out      ,
  input        [NUM*24-1:0]     D_mac_out      ,
  output  reg  [NUM-1:0][40-1:0]P_mac_in =0    ,

  output  reg  [NUM-1:0][24-1:0]A_dsp0_out =0  , 
  output  reg  [NUM-1:0][16-1:0]B_dsp0_out =0  , 
  output  reg  [NUM-1:0][40-1:0]C_dsp0_out =0  , 
  output  reg  [NUM-1:0][24-1:0]D_dsp0_out =0  , 
  input   wire [NUM*40-1:0]     P_dsp0_in      ,
  
  output  reg  [NUM-1:0][17-1:0]A_dsp1_out =0  , 
  output  reg  [NUM-1:0][17-1:0]B_dsp1_out =0  , 
  output  reg  [NUM-1:0][34-1:0]C_dsp1_out =0  , 
  output  reg  [NUM-1:0][17-1:0]D_dsp1_out =0  , 
  input   wire [NUM-1:0][34-1:0]P_dsp1_in      

);
        
//--------------------------------------------------------------
//Shared multiplier exp and gelu DSP_P[31:0] Q32_22
//-------------------------------------------------------------- 
integer i=0,j=0;
(*max_fanout=32*)reg [2-1:0]r_enable =0; 
(*max_fanout=32*)reg [2-1:0]  enable0=0;
(*max_fanout=32*)reg [2-1:0]  enable1=0;
(*max_fanout=32*)reg [2-1:0]  enable2=0;
(*max_fanout=32*)reg [2-1:0]  enable3=0;
always @(posedge clk)
     if(~ln_en&~sf_en& act_en)r_enable<=1;
else if(~ln_en& sf_en&~act_en)r_enable<=2;
else if( ln_en&~sf_en&~act_en)r_enable<=3;
else                          r_enable<=0;

always @(posedge clk)
begin
    enable0 <=r_enable;
    enable1 <=r_enable;
    enable2 <=r_enable;
    enable3 <=r_enable;
end





always @(posedge clk)
for(i=0;i<NUM;i=i+1)
case(enable0) 
   2'd1   :A_dsp0_out[i]<={{(24-17){A_act_out[i*17+17-1]}},A_act_out[i*17+:17]};
   2'd2   :A_dsp0_out[i]<={{(24-17){A_exp_out[i*17+17-1]}},A_exp_out[i*17+:17]};
   2'd3   :A_dsp0_out[i]<={                                A_mac_out[i*24+:24]};//---------------------
   default:A_dsp0_out[i]<=0;  
endcase

always @(posedge clk)
for(i=0;i<NUM;i=i+1)
case(enable1) 
   2'd1   :B_dsp0_out[i]<={{(16-15){B_act_out[i*15+15-1]}},B_act_out[i*15+:15]};
   2'd2   :B_dsp0_out[i]<={{(16-15){B_exp_out[i*15+15-1]}},B_exp_out[i*15+:15]};
   2'd3   :B_dsp0_out[i]<={                                B_mac_out[i*16+:16]};
   default:B_dsp0_out[i]<=0;  
endcase

always @(posedge clk)
for(i=0;i<NUM;i=i+1)
case(enable2) 
   2'd1   :C_dsp0_out[i]<={{(40-32){C_act_out[i*32+32-1]}},C_act_out[i*32+:32]};
   2'd2   :C_dsp0_out[i]<={{(40-32){C_exp_out[i*32+32-1]}},C_exp_out[i*32+:32]};
   2'd3   :C_dsp0_out[i]<={                                C_mac_out[i*40+:40]};
   default:C_dsp0_out[i]<=0;  
endcase

always @(posedge clk)
for(i=0;i<NUM;i=i+1)
case(enable3) 
   2'd1   :D_dsp0_out[i]<={{(24-17){D_act_out[i*17+17-1]}},D_act_out[i*17+:17]};
   2'd2   :D_dsp0_out[i]<={{(24-17){D_exp_out[i*17+17-1]}},D_exp_out[i*17+:17]};
   2'd3   :D_dsp0_out[i]<={                                D_mac_out[i*24+:24]};//-------------------
   default:D_dsp0_out[i]<=0;  
endcase

always @(posedge clk)
for(i=0;i<NUM;i=i+1)
begin
    P_act_in[i]<={P_dsp0_in[i*40+40-1],P_dsp0_in[i*40+:31]};
    P_exp_in[i]<={P_dsp0_in[i*40+40-1],P_dsp0_in[i*40+:31]};
    P_mac_in[i]<={P_dsp0_in[i*40+:40]};
end

//----------------------------------------------------------------------------------
//
//----------------------------------------------------------------------------------

always @(posedge clk)
for(i=0;i<NUM;i=i+1)
begin
    A_dsp1_out[i]<=A_squ_out[i];
    B_dsp1_out[i]<=B_squ_out[i];
    C_dsp1_out[i]<=0;
    D_dsp1_out[i]<=0;
    P_squ_in  [i]<=P_dsp1_in[i];
end




endmodule