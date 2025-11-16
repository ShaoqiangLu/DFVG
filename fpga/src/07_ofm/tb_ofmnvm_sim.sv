`timescale 1ns / 1ps
// -----------------------------------------------------------------------------
// Engineer       : Chen Wu
// Design Name    : opu series
// Module Name    : ofm_top_tb
// Target Devices : k325t 
// Tool Versions  : Vivado 2020.1, Modelsim 2019.4
// Description    : 
//    Testbench for ofm top.
//
// Revision       :
// Version        Date        Author        Description
// 1.0            2021-04-04  Jinming ZhuangInitial version
// 2.0            2022-04-07  Chen Wu       Update test cases
// 3.0            2022-07-18  Lu Shaoqiang  Added real data flow waveform
// 3.1            2023-08-25  Shaoqiang     Implementation in U200
// -----------------------------------------------------------------------------


module tb_ofmnvm_sim();
  localparam           DW         = 16                       ;
  localparam           NUM        = 32                       ;
  localparam           PLEN       = 24                       ;
  localparam           PDW        = 42                       ;
  localparam           BDW        = 32                       ;
  localparam           ODW        = 16                       ;

  reg                  sys_clk_p  = 0                        ;
  reg                  sys_clk_n  = 1                        ;
  reg                  sys_rst    = 1                        ;
  initial begin
      sys_clk_p   <=       1                                 ;
      sys_clk_n   <=       0                                 ;
    forever #(3.333/2)begin//T=3.333ns=3333ps,f=300Mhz
      sys_clk_p   <=       ~sys_clk_p                        ;
      sys_clk_n   <=       ~sys_clk_n                        ;
      end
  end
  initial begin
    sys_rst       <=        1                                ;
    repeat (100) @(posedge sys_clk_p)                        ;
    sys_rst       <=        0                                ;
    
    //#5000000; $stop();
  end

  ofmnvm_synth #(
    .DW             ( DW        ),//16
    .NUM            ( NUM       ),//32
    .PLEN           ( PLEN      ),//24
    .PDW            ( PDW       ),//42
    .BDW            ( BDW       ),//32
    .ODW            ( ODW       ) //16 
  ) u0_ofmnvm_synth (
    .sys_clk_p      ( sys_clk_p ),
    .sys_clk_n      ( sys_clk_n ),
    .sys_rst        ( sys_rst   )  
  );





endmodule
