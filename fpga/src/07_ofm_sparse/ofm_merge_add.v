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
// 6.0            2024-05-30  Shaoqiang       Make small modules based on their functions.


module ofm_merge_add #(
  parameter                        NUM  =   32                  ,
  parameter                        PNUM =   4                   ,
  parameter                        DW   =   37                  ,
  localparam                       IDW  =   PNUM*NUM*DW         
)(
  input                            clk                          ,
  input                            reset                        ,
  input      [NUM*PNUM*DW-1:0]     data_in                      ,
  input      [NUM*PNUM-1:0]        data_in_vld                  ,
  input      [NUM-1:0]             data_in_meg                  ,  
  input      [NUM*2-1:0]           data_in_case                 ,
  
  output reg [NUM*PNUM*DW-1:0]     data_out     =0              ,  
  output reg [NUM*PNUM-1:0]        data_out_vld =0              ,
  output reg [NUM-1:0]             data_out_meg =0              
);

integer i=0,j=0;
//------------------------------------------------------------------------
//meg=1    
//          [3]           [3]           [3]           [3]<-|   
//          [2]           [2]           [2]<-|        [2]  | 
//          [1]           [1]<-|        [1]  |        [1]  |
//          [0]<-|        [0]  |        [0]  |        [0]  |
//meg=1          |             |             |             |
//          [3]  |        [3]  |     |->[3]  |        [3]  |
//          [2]  |     |->[2]  |     |  [2]  |        [2]  |
//       |->[1]  |     |  [1]  |     |  [1]  |        [1]  |
//       |  [0]->|     |  [0]->|     |  [0]->|        [0]->|
//       |             |             |  
//meg=0  |  [3]        |  [3]        |  [3]           [3]   
//       |  [2]        |  [2]        |  [2]           [2]   
//       |  [1]        |  [1]        |  [1]           [1]   
//       |<-[0]        |<-[0]        |<-[0]           [0]   
//------------------------------------------------------------------------

always @(posedge clk)
begin
    data_out_vld <=data_in_vld ;
    data_out_meg <=data_in_meg ;
end


always @(posedge clk)
begin
    data_out[0*(PNUM*DW)+3*DW+:DW]<=data_in[0*(PNUM*DW)+3*DW+:DW];             
    data_out[0*(PNUM*DW)+2*DW+:DW]<=data_in[0*(PNUM*DW)+2*DW+:DW];   
    data_out[0*(PNUM*DW)+1*DW+:DW]<=data_in[0*(PNUM*DW)+1*DW+:DW];   
    data_out[0*(PNUM*DW)+0*DW+:DW]<=data_in[0*(PNUM*DW)+0*DW+:DW];
end

always @(posedge clk)
for(i=1;i<NUM;i=i+1)//
if(data_in_meg[i])
begin
(* full_case *)
case(data_in_case[i*2+:2])
2'd1:begin
    data_out[i*(PNUM*DW)+3*DW+:DW]<=data_in[i*(PNUM*DW)+3*DW+:DW];
    data_out[i*(PNUM*DW)+2*DW+:DW]<=data_in[i*(PNUM*DW)+2*DW+:DW];
    data_out[i*(PNUM*DW)+1*DW+:DW]<=data_in[i*(PNUM*DW)+1*DW+:DW];
    data_out[i*(PNUM*DW)+0*DW+:DW]<=data_in[i*(PNUM*DW)+0*DW+:DW]+data_in[(i-1)*(PNUM*DW)+0*DW+:DW];
end
2'd2:begin
    data_out[i*(PNUM*DW)+3*DW+:DW]<=data_in[i*(PNUM*DW)+3*DW+:DW];
    data_out[i*(PNUM*DW)+2*DW+:DW]<=data_in[i*(PNUM*DW)+2*DW+:DW];
    data_out[i*(PNUM*DW)+1*DW+:DW]<=data_in[i*(PNUM*DW)+1*DW+:DW]+data_in[(i-1)*(PNUM*DW)+0*DW+:DW];
    data_out[i*(PNUM*DW)+0*DW+:DW]<=data_in[i*(PNUM*DW)+0*DW+:DW];
end
2'd3:begin
    data_out[i*(PNUM*DW)+3*DW+:DW]<=data_in[i*(PNUM*DW)+3*DW+:DW];
    data_out[i*(PNUM*DW)+2*DW+:DW]<=data_in[i*(PNUM*DW)+2*DW+:DW]+data_in[(i-1)*(PNUM*DW)+0*DW+:DW];
    data_out[i*(PNUM*DW)+1*DW+:DW]<=data_in[i*(PNUM*DW)+1*DW+:DW];
    data_out[i*(PNUM*DW)+0*DW+:DW]<=data_in[i*(PNUM*DW)+0*DW+:DW];
end
default:begin 
    data_out[i*(PNUM*DW)+3*DW+:DW]<=data_in[i*(PNUM*DW)+3*DW+:DW]+data_in[(i-1)*(PNUM*DW)+0*DW+:DW];
    data_out[i*(PNUM*DW)+2*DW+:DW]<=data_in[i*(PNUM*DW)+2*DW+:DW];
    data_out[i*(PNUM*DW)+1*DW+:DW]<=data_in[i*(PNUM*DW)+1*DW+:DW];
    data_out[i*(PNUM*DW)+0*DW+:DW]<=data_in[i*(PNUM*DW)+0*DW+:DW];
end
endcase
end else begin
    data_out[i*(PNUM*DW)+3*DW+:DW]<=data_in[i*(PNUM*DW)+3*DW+:DW];
    data_out[i*(PNUM*DW)+2*DW+:DW]<=data_in[i*(PNUM*DW)+2*DW+:DW];
    data_out[i*(PNUM*DW)+1*DW+:DW]<=data_in[i*(PNUM*DW)+1*DW+:DW];
    data_out[i*(PNUM*DW)+0*DW+:DW]<=data_in[i*(PNUM*DW)+0*DW+:DW];
end

endmodule
