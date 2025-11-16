`timescale 1ns / 1ps
// -----------------------------------------------------------------------------
// Copyright      : UCLA EDA LAB
// -----------------------------------------------------------------------------
// Engineer       : Chen Wu
// Design Name    : opu series
// Module Name    : tdpram
// Target Devices : 325t, Alveo U200
// Tool Versions  : Vivado 2020.1, Modelsim 2019.4
// Description    : 
//    Generate Single Port RAM with Xilinx xpm_memory template.
//    Use common_clk, Synchronize rst
//    Parameters:
//    ADDR_WIDTH  : width of address
//    DATA_WIDTH  : width of data
//    MEM_TYPE    : "block", "ultra", "distributed", "auto"
//    RD_DLY      : read latency, >= 2, default (2)
//
// Revision       :
// Version        Date        Author        Descriptin
// 1.0            2021-10-15  Chen Wu       Initial version
// ---------------------------------------------------------------------------


module spram # (
  parameter         ADDR_WIDTH        =   12                                ,
  parameter         DATA_WIDTH        =   4096                              ,
  parameter         MEM_TYPE          =   "distributed"                     ,
  parameter         RD_DLY            =   2                                 ,

  localparam        MEM_SIZE          =   (1 << ADDR_WIDTH) * DATA_WIDTH     
  ) (
  output    wire    [DATA_WIDTH-1 : 0]    douta                             ,
  input             [DATA_WIDTH-1 : 0]    dina                              ,
  input             [ADDR_WIDTH-1 : 0]    addra                             ,
  input                                   ena                               ,
  input                                   wea                               ,

  input                                   clk                               ,
  input                                   reset                             
  );


  xpm_memory_spram #(
    .ADDR_WIDTH_A                 ( ADDR_WIDTH                              ),
    .AUTO_SLEEP_TIME              ( 0                                       ),
    .BYTE_WRITE_WIDTH_A           ( DATA_WIDTH                              ),
    .CASCADE_HEIGHT               ( 0                                       ),
    .ECC_MODE                     ( "no_ecc"                                ),
    .MEMORY_INIT_FILE             ( "none"                                  ),
    .MEMORY_INIT_PARAM            ( "0"                                     ),
    .MEMORY_OPTIMIZATION          ( "true"                                  ),
    .MEMORY_PRIMITIVE             ( MEM_TYPE                                ),
    .MEMORY_SIZE                  ( MEM_SIZE                                ),
    .MESSAGE_CONTROL              ( 0                                       ),
    .READ_DATA_WIDTH_A            ( DATA_WIDTH                              ),
    .READ_LATENCY_A               ( RD_DLY                                  ),
    .READ_RESET_VALUE_A           ( "0"                                     ),
    .RST_MODE_A                   ( "SYNC"                                  ),
    .SIM_ASSERT_CHK               ( 0                                       ),
    .USE_MEM_INIT                 ( 1                                       ),
    .WAKEUP_TIME                  ( "disable_sleep"                         ),
    .WRITE_DATA_WIDTH_A           ( DATA_WIDTH                              ),
    .WRITE_MODE_A                 ( "read_first"                            ) 
  ) xpm_memory_spram_inst (
    .dbiterra                     (                                         ),
    .douta                        ( douta                                   ),
    .sbiterra                     (                                         ),
    .addra                        ( addra                                   ),
    .clka                         ( clk                                     ),
    .dina                         ( dina                                    ),
    .ena                          ( ena                                     ),
    .injectdbiterra               ( 1'b0                                    ),
    .injectsbiterra               ( 1'b0                                    ),
    .regcea                       ( 1'b1                                    ),
    .rsta                         ( reset                                   ),
    .sleep                        ( 1'b0                                    ),
    .wea                          ( wea                                     ) 
  );














endmodule