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

module bias_top_sparse # (
  parameter                             NUM = 32                    ,
  parameter                             DW  = 16                    ,
  parameter                             PNUM= 4                     ,
  parameter                             BDW = 32                    ,
  parameter                             CYCLE_NUM = 4                 
) (
  input                                 clk                         ,
  input                                 reset                       ,
  input                                 bias_wstart                 ,
  input           [NUM*DW-1 : 0]        bias_wdata                  ,
  input                                 bias_wvld                   ,
  input                                 bias_pp                     ,
  output  wire    [BDW*NUM*PNUM-1:0]    bias_rdata                    
);

  wire    [CYCLE_NUM-1:0]               bias_wen0                   ;
  wire    [CYCLE_NUM-1:0]               bias_wen1                   ;
  wire    [CYCLE_NUM*(NUM*DW)-1:0]      bias_wdata0                 ;
  wire    [CYCLE_NUM*(NUM*DW)-1:0]      bias_wdata1                 ; 
  wire    [CYCLE_NUM*(NUM*DW)-1:0]      bias_rdata0                 ; 
  wire    [CYCLE_NUM*(NUM*DW)-1:0]      bias_rdata1                 ;


(*keep_hierarchy="yes"*)bias_write #(
  .NUM              (NUM                ),
  .DW               (DW                 ),
  .CYCLE_NUM        (CYCLE_NUM          )
)u_bias_write(
  .clk              (clk                ),
  .reset            (reset              ),
  .bias_wstart      (bias_wstart        ),
  .bias_wdata       (bias_wdata         ),
  .bias_wvld        (bias_wvld          ),
  .bias_pp          (bias_pp            ),
  .bias_wen0        (bias_wen0          ),
  .bias_wen1        (bias_wen1          ),
  .bias_wdata0      (bias_wdata0        ),
  .bias_wdata1      (bias_wdata1        )
);




(*keep_hierarchy="yes"*)bias_buffer # (
  .NUM              (NUM                ),
  .DW               (DW                 ),
  .CYCLE_NUM        (CYCLE_NUM          )
)u_bias_buffer(
  .clk              (clk                ),
  .reset            (reset              ),
  .bias_wen0        (bias_wen0          ),
  .bias_wdata0      (bias_wdata0        ),
  .bias_wen1        (bias_wen1          ),
  .bias_wdata1      (bias_wdata1        ), 
  .bias_rdata0      (bias_rdata0        ), 
  .bias_rdata1      (bias_rdata1        )
);



(*keep_hierarchy="yes"*)bias_read # (
  .NUM              (32                 ),
  .PNUM             (4                  ),
  .BDW              (32                 ),
  .CYCLE_NUM        (4                  )
)u_bias_read(
  .clk              (clk                ),
  .reset            (reset              ),
  .bias_pp          (bias_pp            ),
  .bias_rdata0      (bias_rdata0        ),
  .bias_rdata1      (bias_rdata1        ),
  .bias_rdata       (bias_rdata         )    
);















endmodule
