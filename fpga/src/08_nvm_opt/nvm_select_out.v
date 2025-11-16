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
`include "opu_parameter.vh"
module nvm_select_out #(
  parameter DW        =     16                          ,
  parameter NUM       =     32                                
) (
  input                     clk                         ,
  input                     reset                       , 
  input    [5-1:0]          nvm_index_en                ,
  input                     nvm_back_en                 , 
  input    [NUM-1:0][DW-1:0]tr_dout_data                ,//1                       
  input    [NUM-1:0][DW-1:0]sf_dout_data                ,//2                         
  input    [NUM-1:0][DW-1:0]ln_dout_data                ,//3                     
  input    [NUM-1:0][DW-1:0]res_dout_data               ,//4                  
  input    [NUM-1:0][DW-1:0]act_dout_data               ,//5                  
  input    [NUM-1:0][DW-1:0]out_rdata_in                ,//6
  input                     tr_dout_vld                 ,
  input                     tr_dout_done                ,           
  input                     sf_dout_vld                 ,
  input                     sf_dout_done                ,        
  input                     ln_dout_vld                 ,
  input                     ln_dout_done                ,       
  input                     res_dout_vld                ,
  input                     res_dout_done               ,              
  input                     act_dout_vld                ,
  input                     act_dout_done               ,            
  input                     out_rdata_vld               ,
  input                     out_rdata_done              ,
  
  output wire [NUM*DW-1:0]  back_wdata                  ,
  output reg                back_row_wvld  =0           ,
  output reg                back_row_wdone =0           ,  

  input                     back_rdata_vld              ,
  input       [NUM*DW-1:0]  back_rdata                  ,
  
  output reg  [NUM*DW-1:0]  ddr_wdata      =0           ,
  output reg                ddr_wvld       =0  

);

//--------------------------------------------------------------
//Output multiplexer according to enable
//--------------------------------------------------------------
integer          i=0,j=0                                ;
(*max_fanout=16*)reg[32*3-1:0]index_cnt0=0              ;
(*max_fanout=16*)reg[3-1:0]index_cnt1   =0              ;
always @(posedge clk)
    case(nvm_index_en)
    5'b00001:index_cnt0<={32{3'd1}}                     ;//tr_en
    5'b00010:index_cnt0<={32{3'd2}}                     ;//sf_en
    5'b00100,
    5'b01100:index_cnt0<={32{3'd3}}                     ;//ln_en
    5'b01000:index_cnt0<={32{3'd4}}                     ;//res_en
    5'b10000:index_cnt0<={32{3'd5}}                     ;//act_en
    default :index_cnt0<={32{3'd0}}                     ;
endcase

always @(posedge clk)
    case(nvm_index_en)
    5'b00001:index_cnt1<=3'd1                           ;//tr_en
    5'b00010:index_cnt1<=3'd2                           ;//sf_en
    5'b00100,
    5'b01100:index_cnt1<=3'd3                           ;//ln_en
    5'b01000:index_cnt1<=3'd4                           ;//res_en
    5'b10000:index_cnt1<=3'd5                           ;//act_en
    default :index_cnt1<=3'd0                           ;
endcase

(*max_fanout=16*)reg back_en=0                          ;
always @(posedge clk)back_en<=nvm_back_en               ;

//--------------------------------------------------------------
//
//--------------------------------------------------------------
(*dont_touch="true"*)reg[NUM*DW-1:0] out_wdata   =0     ;  
(*dont_touch="true"*)reg[NUM*DW-1:0] r_back_wdata=0     ;  
reg             out_wvld=0                              ;
reg             back_row_wvld_r=0                       ;

`ifndef SIM_CODE
assign back_wdata=r_back_wdata                          ;
`else
assign back_wdata=~back_row_wvld_r?0:r_back_wdata       ;
`endif



always @(posedge clk)
for(i=0;i<32;i=i+1)
case(index_cnt0[i*3+:3])
  3'd1: begin
        r_back_wdata[i*DW+:DW]<=tr_dout_data[i]         ;
        out_wdata   [i*DW+:DW]<=tr_dout_data[i]         ;  
        end
  3'd2: begin
        r_back_wdata[i*DW+:DW]<=sf_dout_data[i]         ;
        out_wdata   [i*DW+:DW]<=sf_dout_data[i]         ;  
        end
  3'd3: begin
        r_back_wdata[i*DW+:DW]<=ln_dout_data[i]         ;
        out_wdata   [i*DW+:DW]<=ln_dout_data[i]         ;  
        end
  3'd4: begin
        r_back_wdata[i*DW+:DW]<=res_dout_data[i]        ;
        out_wdata   [i*DW+:DW]<=res_dout_data[i]        ;  
        end
  3'd5: begin
        r_back_wdata[i*DW+:DW]<=act_dout_data[i]        ;
        out_wdata   [i*DW+:DW]<=act_dout_data[i]        ;  
        end
default:begin
        r_back_wdata[i*DW+:DW]<=out_rdata_in[i]         ;
        out_wdata   [i*DW+:DW]<=out_rdata_in[i]         ;  
        end
endcase

//--------------------------------------------------------------
//
//--------------------------------------------------------------
always @(posedge clk)
case(index_cnt1)
  3'd1: begin
        out_wvld        <=~back_en&tr_dout_vld          ; 
        back_row_wvld_r <= back_en&tr_dout_vld          ;
        end
  3'd2: begin
        out_wvld        <=~back_en&sf_dout_vld          ; 
        back_row_wvld_r <= back_en&sf_dout_vld          ;
        end
  3'd3: begin
        out_wvld        <=~back_en&ln_dout_vld          ; 
        back_row_wvld_r <= back_en&ln_dout_vld          ; 
        end
  3'd4: begin
        out_wvld        <=~back_en&res_dout_vld         ; 
        back_row_wvld_r <= back_en&res_dout_vld         ;
        end
  3'd5: begin
        out_wvld        <=~back_en&act_dout_vld         ; 
        back_row_wvld_r <= back_en&act_dout_vld         ;
        end
default:begin
        out_wvld        <=~back_en&out_rdata_vld        ; 
        back_row_wvld_r <= back_en&out_rdata_vld        ;
        end
endcase

always @(*)
case(index_cnt1)
  3'd1: begin
        back_row_wvld   <= back_en&tr_dout_vld          ;
        back_row_wdone  <= back_en&tr_dout_done         ;
        end
  3'd2: begin
        back_row_wvld   <= back_en&sf_dout_vld          ;
        back_row_wdone  <= back_en&sf_dout_done         ; 
        end
  3'd3: begin
        back_row_wvld   <= back_en&ln_dout_vld          ;
        back_row_wdone  <= back_en&ln_dout_done         ;  
        end
  3'd4: begin 
        back_row_wvld   <= back_en&res_dout_vld         ;
        back_row_wdone  <= back_en&res_dout_done        ; 
        end
  3'd5: begin 
        back_row_wvld   <= back_en&act_dout_vld         ;
        back_row_wdone  <= back_en&act_dout_done        ; 
        end
default:begin
        back_row_wvld   <= back_en&out_rdata_vld        ;
        back_row_wdone  <= back_en&out_rdata_done       ; 
        end
endcase







//--------------------------------------------------------------
// Data output to ddr.
//--------------------------------------------------------------
   (*max_fanout=16*) reg ddr_sel=0                      ;
   always @(posedge clk) ddr_sel<=back_en               ;

`ifndef SIM_CODE
   always @(posedge clk) 
   if(ddr_sel)ddr_wdata<= back_rdata                    ;
   else       ddr_wdata<=  out_wdata                    ;
`else
   always @(posedge clk) 
   if(ddr_sel)ddr_wdata<=~back_rdata_vld?0:back_rdata   ;
   else       ddr_wdata<=~out_wvld?0:out_wdata          ;
`endif




   always @(posedge clk)
   if(ddr_sel)ddr_wvld <= back_rdata_vld                ;
   else       ddr_wvld <= out_wvld                      ;
   





endmodule