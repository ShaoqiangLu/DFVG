`timescale 1ns / 1ps
// -----------------------------------------------------------------------------
// Copyright      : UCLA EDA LAB
// -----------------------------------------------------------------------------
// Engineer       : Chen Wu
// Design Name    : opu series
// Module Name    : ifm_top
// Target Devices : 325t, Alveo U200
// Tool Versions  : Vivado 2020.1, Modelsim 2019.4
// Description    : 
//    Write data (from ddr) to bias buffer in ping-pong mode
//    Read data from input bias buffer in ping-pong mode
//
// Revision       :
// Version        Date        Author        Descriptin
// 1.0            2022-03-31  Chen Wu       Initial version
// 2.0            2023-08-25  Shaoqiang     Simulation 97 layers,and       
//                                          implementation on FPGA of U200.
// -----------------------------------------------------------------------------
// ------------------------------------------------------------------
// pp = 0: write ram0, read ram1; 
// pp = 1: write ram1, read ram0
// ------------------------------------------------------------------

module bias_buffer # (
  parameter     NUM                             = 32            ,
  parameter     DW                              = 16            ,
  parameter     CYCLE_NUM                       = 4   
) (
  input                                         clk             ,
  input                                         reset           ,
  input         [CYCLE_NUM-1:0]                 bias_wen0       ,
  input         [CYCLE_NUM-1:0][(NUM*DW)-1:0]   bias_wdata0     ,
  input         [CYCLE_NUM-1:0]                 bias_wen1       ,
  input         [CYCLE_NUM-1:0][(NUM*DW)-1:0]   bias_wdata1     , 
  output wire   [CYCLE_NUM-1:0][(NUM*DW)-1:0]   bias_rdata0     , 
  output wire   [CYCLE_NUM-1:0][(NUM*DW)-1:0]   bias_rdata1     
);


  localparam              RAM_CYCLE=   2                        ;
  localparam              RAM_IDATA=   NUM*DW                   ;
  localparam              RAM_ADDR =   1                        ;

generate for (genvar i=0; i<CYCLE_NUM; i=i+1)
begin:M0
    (*keep_hierarchy="yes"*)
    spram # (
      .ADDR_WIDTH               ( RAM_ADDR                      ),
      .DATA_WIDTH               ( RAM_IDATA                     ),
      .RD_DLY                   ( RAM_CYCLE                     ),       
      .MEM_TYPE                 ( "distributed"                 )
    ) RAM0 (
      .wea                      ( bias_wen0[i]                  ),    
      .addra                    ( 1'b0                          ),
      .dina                     ( bias_wdata0[i]                ),           
      .douta                    ( bias_rdata0[i]                ),
      .ena                      ( 1'b1                          ),
      .clk                      ( clk                           ),
      .reset                    ( 1'b0                          )             
    );
end
endgenerate

generate for ( genvar i=0; i<CYCLE_NUM; i=i+1 )
begin:M1
    (*keep_hierarchy="yes"*)
    spram # (
      .ADDR_WIDTH               ( RAM_ADDR                      ),
      .DATA_WIDTH               ( RAM_IDATA                     ),
      .RD_DLY                   ( RAM_CYCLE                     ),       
      .MEM_TYPE                 ( "distributed"                 )
    ) RAM1 (
      .wea                      ( bias_wen1[i]                  ),    
      .addra                    ( 1'b0                          ),
      .dina                     ( bias_wdata1[i]                ),           
      .douta                    ( bias_rdata1[i]                ),
      .ena                      ( 1'b1                          ),
      .clk                      ( clk                           ),
      .reset                    ( 1'b0                          )             
    );
end
endgenerate




endmodule
