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
//    Generate True Dual Port RAM with Xilinx xpm_memory template.
//    Use common_clk, Synchronize rst
//    Parameters:
//    ADDR_WIDTH  : width of address
//    DATA_WIDTH  : width of data
//    MEM_TYPE    : "auto", "block", "ultra"
//    RD_DLY      : read latency, >= 2, default (2)
//
// Revision       :
// Version        Date        Author        Descriptin
// 1.0            2021-10-15  Chen Wu       Initial version
// 2.0            2023-08-25  Shaoqiang     Implementation on FPGA of U200.   
// ---------------------------------------------------------------------------


module tdpram # (
  parameter         ADDR_WIDTH        =   12                                ,
  parameter         DATA_WIDTH        =   4096                              ,
  parameter         MEM_TYPE          =   "block"                           ,
  parameter         RD_DLY            =   2                                 ,

  localparam        MEM_SIZE          =   (1 << ADDR_WIDTH) * DATA_WIDTH     
  ) (
  
  output    wire    [DATA_WIDTH-1 : 0]    douta                             ,
  input             [DATA_WIDTH-1 : 0]    dina                              ,
  input             [ADDR_WIDTH-1 : 0]    addra                             ,
  input                                   ena                               ,
  input                                   wea                               ,

  output    wire    [DATA_WIDTH-1 : 0]    doutb                             ,
  input             [DATA_WIDTH-1 : 0]    dinb                              ,
  input             [ADDR_WIDTH-1 : 0]    addrb                             ,
  input                                   enb                               ,
  input                                   web                               ,

  input                                   clk                               ,
  input                                   reset                             
  );

  xpm_memory_tdpram #(
    .ADDR_WIDTH_A                   ( ADDR_WIDTH                            ),  // DECIMAL
    .ADDR_WIDTH_B                   ( ADDR_WIDTH                            ),  // DECIMAL
    .AUTO_SLEEP_TIME                ( 0                                     ),  // DECIMAL
    .BYTE_WRITE_WIDTH_A             ( DATA_WIDTH                            ),  // DECIMAL
    .BYTE_WRITE_WIDTH_B             ( DATA_WIDTH                            ),  // DECIMAL
    .CASCADE_HEIGHT                 ( 0                                     ),  // DECIMAL, let Vivado choose
    .CLOCKING_MODE                  ( "common_clock"                        ),  // String, "common_clock" or "independent_clock"
    .ECC_MODE                       ( "no_ecc"                              ),  // String
    .MEMORY_INIT_FILE               ( "none"                                ),  // String
    .MEMORY_INIT_PARAM              ( "0"                                   ),  // String
    .MEMORY_OPTIMIZATION            ( "true"                                ),  // String
    .MEMORY_PRIMITIVE               ( MEM_TYPE                              ),  // String, "auto", "distributed", "block", "ultra"
    .MEMORY_SIZE                    ( MEM_SIZE                              ),  // DECIMAL
    .MESSAGE_CONTROL                ( 0                                     ),  // DECIMAL
    .READ_DATA_WIDTH_A              ( DATA_WIDTH                            ),  // DECIMAL
    .READ_DATA_WIDTH_B              ( DATA_WIDTH                            ),  // DECIMAL
    .READ_LATENCY_A                 ( RD_DLY                                ),  // DECIMAL
    .READ_LATENCY_B                 ( RD_DLY                                ),  // DECIMAL
    .READ_RESET_VALUE_A             ( "0"                                   ),  // String
    .READ_RESET_VALUE_B             ( "0"                                   ),  // String
    .RST_MODE_A                     ( "SYNC"                                ),  // String, "SYNC", "ASYNC"
    .RST_MODE_B                     ( "SYNC"                                ),  // String, "SYNC", "ASYNC"
    .SIM_ASSERT_CHK                 ( 0                                     ),  // DECIMAL; 0=disable simulation messages, 
                                                                                //          1=enable simulation messages
    .USE_EMBEDDED_CONSTRAINT        ( 0                                     ),  // DECIMAL
    .USE_MEM_INIT                   ( 1                                     ),  // DECIMAL
    .WAKEUP_TIME                    ( "disable_sleep"                       ),  // String
    .WRITE_DATA_WIDTH_A             ( DATA_WIDTH                            ),  // DECIMAL
    .WRITE_DATA_WIDTH_B             ( DATA_WIDTH                            ),  // DECIMAL
    .WRITE_MODE_A                   ( "read_first"                          ),  // String
    .WRITE_MODE_B                   ( "read_first"                          )   // String
  )
  u0_xpm_memory_tdpram (
    .dbiterra                       (                                       ),
    .dbiterrb                       (                                       ),

    .douta                          ( douta                                 ),
    .doutb                          ( doutb                                 ),

    .sbiterra                       (                                       ),
    .sbiterrb                       (                                       ),

    .addra                          ( addra                                 ),
    .addrb                          ( addrb                                 ),

    .clka                           ( clk                                   ),
    .clkb                           ( clk                                   ),

    .dina                           ( dina                                  ),
    .dinb                           ( dinb                                  ),

    .ena                            ( ena                                   ),
    .enb                            ( enb                                   ),

    .injectdbiterra                 ( 1'b0                                  ), 
    .injectdbiterrb                 ( 1'b0                                  ), 

    .injectsbiterra                 ( 1'b0                                  ), 
    .injectsbiterrb                 ( 1'b0                                  ), 

    .regcea                         ( 1'b1                                  ), 
    .regceb                         ( 1'b1                                  ), 

    .rsta                           ( reset                                 ),
    .rstb                           ( reset                                 ),

    .sleep                          ( 1'b0                                  ),

    .wea                            ( wea                                   ),
    .web                            ( web                                   ) 
  );

endmodule