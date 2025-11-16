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


module tdpram_uram
#(
  parameter         ADDR_WIDTH        =   23                                ,
  parameter         DATA_WIDTH        =   72                                ,
  parameter         MEM_TYPE          =   "ultra"                           ,
  parameter         RD_DLY            =   2                                 ,
  localparam        MEM_SIZE          =   (1 << ADDR_WIDTH) * DATA_WIDTH     
)(
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


//-----------------------------------------------------------------------------------------------
// URAM288_BASE: 288K-bit High-Density Base Memory Building Block
//               Virtex UltraScale+
// Xilinx HDL Language Template, version 2020.1

URAM288_BASE
#(
    .AUTO_SLEEP_LATENCY             (8                                      ),// Latency requirement to enter sleep mode
    .AVG_CONS_INACTIVE_CYCLES       (10                                     ),// Average consecutive inactive cycles when is SLEEP mode for power estimation
    .BWE_MODE_A                     ("PARITY_INTERLEAVED"                   ),// Port A Byte write control
    .BWE_MODE_B                     ("PARITY_INTERLEAVED"                   ),// Port B Byte write control
    .EN_AUTO_SLEEP_MODE             ("FALSE"                                ),// Enable to automatically enter sleep mode
    .EN_ECC_RD_A                    ("FALSE"                                ),// Port A ECC encoder
    .EN_ECC_RD_B                    ("FALSE"                                ),// Port B ECC encoder
    .EN_ECC_WR_A                    ("FALSE"                                ),// Port A ECC decoder
    .EN_ECC_WR_B                    ("FALSE"                                ),// Port B ECC decoder
    .IREG_PRE_A                     ("FALSE"                                ),// Optional Port A input pipeline registers
    .IREG_PRE_B                     ("FALSE"                                ),// Optional Port B input pipeline registers
    .IS_CLK_INVERTED                (1'b0                                   ),// Optional inverter for CLK
    .IS_EN_A_INVERTED               (1'b0                                   ),// Optional inverter for Port A enable
    .IS_EN_B_INVERTED               (1'b0                                   ),// Optional inverter for Port B enable
    .IS_RDB_WR_A_INVERTED           (1'b0                                   ),// Optional inverter for Port A read/write select
    .IS_RDB_WR_B_INVERTED           (1'b0                                   ),// Optional inverter for Port B read/write select
    .IS_RST_A_INVERTED              (1'b0                                   ),// Optional inverter for Port A reset
    .IS_RST_B_INVERTED              (1'b0                                   ),// Optional inverter for Port B reset
    .OREG_A                         ("FALSE"                                ),// Optional Port A output pipeline registers
    .OREG_B                         ("FALSE"                                ),// Optional Port B output pipeline registers
    .OREG_ECC_A                     ("FALSE"                                ),// Port A ECC decoder output
    .OREG_ECC_B                     ("FALSE"                                ),// Port B output ECC decoder
    .RST_MODE_A                     ("SYNC"                                 ),// Port A reset mode
    .RST_MODE_B                     ("SYNC"                                 ),// Port B reset mode
    .USE_EXT_CE_A                   ("FALSE"                                ),// Enable Port A external CE inputs for output registers
    .USE_EXT_CE_B                   ("FALSE"                                ) // Enable Port B external CE inputs for output registers
)
URAM288_BASE_inst 
(
    .DBITERR_A                      (                                       ),// 1-bit  output: Port A double-bit error flag status
    .DBITERR_B                      (                                       ),// 1-bit  output: Port B double-bit error flag status
    .SBITERR_A                      (                                       ),// 1-bit  output: Port A single-bit error flag status
    .SBITERR_B                      (                                       ),// 1-bit  output: Port B single-bit error flag status
    .INJECT_DBITERR_A               (1'b0                                   ),// 1-bit  input : Port A double-bit error injection
    .INJECT_DBITERR_B               (1'b0                                   ),// 1-bit  input : Port B double-bit error injection
    .INJECT_SBITERR_A               (1'b0                                   ),// 1-bit  input : Port A single-bit error injection
    .INJECT_SBITERR_B               (1'b0                                   ),// 1-bit  input : Port B single-bit error injection
    .BWE_A                          (9'b111111111                           ),// 9-bit  input : Port A Byte-write enable
    .BWE_B                          (9'b111111111                           ),// 9-bit  input : Port B Byte-write enable
    .OREG_CE_A                      (1'b0                                   ),// 1-bit  input : Port A output register clock enable
    .OREG_CE_B                      (1'b0                                   ),// 1-bit  input : Port B output register clock enable
    .OREG_ECC_CE_A                  (1'b0                                   ),// 1-bit  input : Port A ECC decoder output register clock enable
    .OREG_ECC_CE_B                  (1'b0                                   ),// 1-bit  input : Port B ECC decoder output register clock enable
    .SLEEP                          (1'b0                                   ),// 1-bit  input : Dynamic power gating control
    .EN_A                           (ena                                    ),// 1-bit  input : Port A enable
    .EN_B                           (enb                                    ),// 1-bit  input : Port B enable 
    //
    .DOUT_A                         (douta                                  ),// 72-bit output: Port A read data output
    .DOUT_B                         (doutb                                  ),// 72-bit output: Port B read data output
    .ADDR_A                         (addra                                  ),// 23-bit input : Port A address
    .ADDR_B                         (addrb                                  ),// 23-bit input : Port B address
    .DIN_A                          (dina                                   ),// 72-bit input : Port A write data input
    .DIN_B                          (dinb                                   ),// 72-bit input : Port B write data input
    .RDB_WR_A                       (wea                                    ),// 1-bit  input : Port A read/write select
    .RDB_WR_B                       (web                                    ),// 1-bit  input : Port B read/write select
    .RST_A                          (reset                                  ),// 1-bit  input : Port A asynchronous or synchronous reset for output registers
    .RST_B                          (reset                                  ),// 1-bit  input : Port B asynchronous or synchronous reset for output registers
    .CLK                            (clk                                    ) // 1-bit  input : Clock source
);








			
endmodule