`timescale 1ns / 1ps
// -----------------------------------------------------------------------------
// Copyright      : UCLA EDA LAB
// -----------------------------------------------------------------------------
// Engineer       : Chen Wu
// Design Name    : opu series
// Module Name    : dly_cell
// Target Devices : 
// Tool Versions  : Vivado 2020.1, Modelsim 2019.4
// Description    : 
//    Delay unit.
// Revision       :
// Version        Date        Author        Descriptin
// 1.0            2020-05-27  Chen Wu       Initial version
// 2.0            2023-09-27  Shaoqiang     Implementation on FPGA of U200.
// -----------------------------------------------------------------------------


module dly_cell 
#(parameter DW=32,DLY=8)
(
  output        [DW-1 : 0]    dout      ,
  input         [DW-1 : 0]    din       ,

  input                       clk       ,
  input                       reset     
);

  
  
generate
  //----------------------------------------
  if(DLY==0)begin:DLY0
        assign dout = din;
  end else begin :DLY1
  //----------------------------------------
      (*dont_touch="true"*)reg[DW*DLY-1:0] MEMDLY=0;
  
      for(genvar i=0;i<DLY;i=i+1)
      begin
        if(i==0)always @(posedge clk)
        MEMDLY[i*DW+:DW]<=din;
        else    always @(posedge clk)
        MEMDLY[i*DW+:DW]<=MEMDLY[(i-1)*DW+:DW];
      end  
  
     assign dout = MEMDLY[(DLY-1)*DW+:DW];
  
  end

endgenerate


endmodule