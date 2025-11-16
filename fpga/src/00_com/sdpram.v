`timescale 1ns / 1ps
// -----------------------------------------------------------------------------
// Copyright      : UCLA EDA LAB
// -----------------------------------------------------------------------------
// Engineer       : Chen Wu
// Design Name    : opu series
// Module Name    : sdpram
// Target Devices : 325t, Alveo U200
// Tool Versions  : Vivado 2020.1, Modelsim 2019.4
// Description    : 
//    Generate Simple Dual Port RAM with Xilinx xpm_memory template.
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


module sdpram #(
  parameter         ADDR_WIDTH        =   12                                ,
  parameter         DATA_WIDTH        =   4096                              ,
  parameter         MEM_TYPE          =   "block"                           ,
  parameter         RD_DLY            =   2                                 ,

  localparam        MEM_SIZE          =   (1 << ADDR_WIDTH) * DATA_WIDTH     
  ) (
  
  input             [DATA_WIDTH-1 : 0]    dina                              ,
  input             [ADDR_WIDTH-1 : 0]    addra                             ,
  input                                   ena                               ,
  input                                   wea                               ,

  output    wire    [DATA_WIDTH-1 : 0]    doutb                             ,
  input             [ADDR_WIDTH-1 : 0]    addrb                             ,
  input                                   enb                               ,

  input                                   clk                               ,
  input                                   reset                             
  );

  xpm_memory_sdpram #(
    .ADDR_WIDTH_A                   ( ADDR_WIDTH                            ),
    .ADDR_WIDTH_B                   ( ADDR_WIDTH                            ),
    .AUTO_SLEEP_TIME                ( 0                                     ),
    .BYTE_WRITE_WIDTH_A             ( DATA_WIDTH                            ),
    .CASCADE_HEIGHT                 ( 0                                     ),
    .CLOCKING_MODE                  ( "common_clock"                        ),
    .ECC_MODE                       ( "no_ecc"                              ),
    .MEMORY_INIT_FILE               ( "none"                                ),
    .MEMORY_INIT_PARAM              ( "0"                                   ),
    .MEMORY_OPTIMIZATION            ( "true"                                ),
    .MEMORY_PRIMITIVE               ( MEM_TYPE                              ),
    .MEMORY_SIZE                    ( MEM_SIZE                              ),
    .MESSAGE_CONTROL                ( 0                                     ),
    .READ_DATA_WIDTH_B              ( DATA_WIDTH                            ),
    .READ_LATENCY_B                 ( RD_DLY                                ),
    .READ_RESET_VALUE_B             ( "0"                                   ),
    .RST_MODE_A                     ( "SYNC"                                ),
    .RST_MODE_B                     ( "SYNC"                                ),
    .SIM_ASSERT_CHK                 ( 0                                     ),
    .USE_EMBEDDED_CONSTRAINT        ( 0                                     ),
    .USE_MEM_INIT                   ( 1                                     ),
    .WAKEUP_TIME                    ( "disable_sleep"                       ),
    .WRITE_DATA_WIDTH_A             ( DATA_WIDTH                            ),
    .WRITE_MODE_B                   ( "read_first"                          ) 
  )
  xpm_memory_sdpram_inst (
    .dbiterrb                       (                                       ),
    .doutb                          ( doutb                                 ),  
    .sbiterrb                       (                                       ),
    .addra                          ( addra                                 ),  
    .addrb                          ( addrb                                 ),  
    .clka                           ( clk                                   ),   
    .clkb                           ( clk                                   ),   
    .dina                           ( dina                                  ),   
    .ena                            ( ena                                   ),    
    .enb                            ( enb                                   ),    
    .injectdbiterra                 ( 1'b0                                  ),
    .injectsbiterra                 ( 1'b0                                  ),
    .regceb                         ( 1'b1                                  ),
    .rstb                           ( reset                                 ),
    .sleep                          ( 1'b0                                  ),
    .wea                            ( wea                                   )
   );

endmodule