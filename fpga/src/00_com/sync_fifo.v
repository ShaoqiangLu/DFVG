`timescale 1ns / 1ps
// -----------------------------------------------------------------------------
// Copyright      : UCLA EDA LAB
// -----------------------------------------------------------------------------
// Engineer       : Chen Wu
// Design Name    : opu series
// Module Name    : sync_fifo
// Target Devices : 325t, Alveo U200
// Tool Versions  : Vivado 2020.1, Modelsim 2019.4
// Description    : 
//    Instantiate synchronize fifo using primitive
//    Parameters  :
//      MEM_TYPE     : memory type
//                      "auto" - Allow Vivado Synthesis to choose, default
//                      "block" - Block RAM FIFO
//                      "distributed" - Distributed RAM FIFO
//                      "ultra" - URAM FIFO  
//      RMODE        : read mode
//                      "std" - standard read mode
//                      "fwfl" - First-Word-Fall-Through read mode
//      FEATURES     : String, enables different features, default "0707"
//                      FEATURES[0]   - overflow
//                      FEATURES[1]   - prog_full
//                      FEATURES[2]   - wr_data_count
//                      FEATURES[3]   - almost_full
//                      FEATURES[4]   - wr_ack
//                      FEATURES[8]   - underflow
//                      FEATURES[9]   - prog_empty
//                      FEATURES[10]  - rd_data_count
//                      FEATURES[11]  - almost_empty
//                      FEATURES[12]  - data_valid
//      DEPTH        : write depth, 16 - 4194304. Default value = 2048
//                      NOTE: The maximum FIFO size (width x depth) is limited to 150-Megabits
//      PEMPTY_THRESH: threshold for prog_empty to be asserted, 3 - 4194304, default value = 10 
//      RLATENCY     : read latency
//                      0 - 100, default value = 1
//                      if RMODE = "fwft", only applicable value is 0
//      RWIDTH       : read data width, 1 - 4096, default value = 32
//      PFULL_THRESH : threshold for prog_full to be asserted, 3 - 4194301, default value = 10
//      WWIDTH       : write data width, 1 - 4096, default value = 32                  
//                      Note: Write and read width aspect ratio must be 1:1, 1:2, 1:4, 1:8, 8:1, 4:1 and 2:1 
// Revision       :
// Version        Date        Author        Descriptin
// 1.0            2022-03-30  Chen Wu       Initial version
// 2.0            2023-08-25  Shaoqiang     Implementation on FPGA of U200.      
// -----------------------------------------------------------------------------


module sync_fifo #(
  parameter         MEM_TYPE        =     "auto"              ,
  parameter         RLATENCY        =     1                   ,
  parameter         DEPTH           =     2048                ,
  parameter         PEMPTY_THRESH   =     10                  ,
  parameter         PFULL_THRESH    =     10                  ,
  parameter         RWIDTH          =     32                  ,
  parameter         RMODE           =     "std"               ,
  parameter         FEATURES        =     "0707"              ,
  parameter         WWIDTH          =     32                  
) (
  output  wire                      aempty                    ,
  output  wire                      pempty                    ,
  output  wire                      empty                     ,
  output  wire      [RWIDTH-1 : 0]  rdata                     ,
  input                             ren                       ,

  output  wire                      afull                     ,
  output  wire                      pfull                     ,
  output  wire                      full                      ,
  input             [WWIDTH-1 : 0]  wdata                     ,
  input                             wen                       ,

  input                             clk                       ,
  input                             reset                     
);

  xpm_fifo_sync #(
    .DOUT_RESET_VALUE               ( "0"                     ), 
    .ECC_MODE                       ( "no_ecc"                ), 
    .FIFO_MEMORY_TYPE               ( MEM_TYPE                ),
    .FIFO_READ_LATENCY              ( RLATENCY                ),
    .FIFO_WRITE_DEPTH               ( DEPTH                   ),
    .FULL_RESET_VALUE               ( 0                       ),
    .PROG_EMPTY_THRESH              ( PEMPTY_THRESH           ),
    .PROG_FULL_THRESH               ( PFULL_THRESH            ),
    .RD_DATA_COUNT_WIDTH            ( 1                       ),
    .READ_DATA_WIDTH                ( RWIDTH                  ),
    .READ_MODE                      ( RMODE                   ),
    .SIM_ASSERT_CHK                 ( 0                       ),
    .USE_ADV_FEATURES               ( FEATURES                ),
    .WAKEUP_TIME                    ( 0                       ),
    .WRITE_DATA_WIDTH               ( WWIDTH                  ),
    .WR_DATA_COUNT_WIDTH            ( 1                       ) 
  ) xpm_fifo_sync_inst (
    .almost_empty                   ( aempty                  ),
    .almost_full                    ( afull                   ),
    .data_valid                     (                         ),
    .dbiterr                        (                         ),
    .dout                           ( rdata                   ),
    .empty                          ( empty                   ),
    .full                           ( full                    ),
    .overflow                       (                         ),
    .prog_empty                     ( pempty                  ),
    .prog_full                      ( pfull                   ),
    .rd_data_count                  (                         ),
    .rd_rst_busy                    (                         ),
    .sbiterr                        (                         ),
    .underflow                      (                         ),
    .wr_ack                         (                         ),
    .wr_data_count                  (                         ),
    .wr_rst_busy                    (                         ),
    .din                            ( wdata                   ),
    .injectdbiterr                  ( 1'b0                    ),
    .injectsbiterr                  ( 1'b0                    ),
    .rd_en                          ( ren                     ),
    .rst                            ( reset                   ),
    .sleep                          ( 1'b0                    ),
    .wr_clk                         ( clk                     ),
    .wr_en                          ( wen                     )
  );

endmodule