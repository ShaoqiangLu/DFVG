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
//    Write data (from ddr) to kernel buffer in ping-pong mode
//    Read data from input kernel buffer in ping-pong mode
//
// Revision       :
// Version        Date        Author        Descriptin
// 1.0            2022-03-31  Chen Wu       Initial version
// 2.0            2023-08-25  Shaoqiang     Simulation 97 layers,and       
//                                          implementation on FPGA of U200.
// 3.0            2024-05-30  Shaoqiang     For sparsity
// -----------------------------------------------------------------------------
//    ifm             ker              ofm
//[0][1][2][3] *  [0][0][0][0]  = [ ][ ][ ][ ]
//[0][1][2][3]    [1][1][1][1]    [ ][ ][ ][ ]
//[0][1][2][3]    [2][2][2][2]    [ ][ ][ ][ ]   
//[0][1][2][3]    [3][3][3][3]    [ ][ ][ ][ ]
//[0][1][2][3]                    [ ][ ][ ][ ]
//[0][1][2][3]                    [ ][ ][ ][ ]
//[0][1][2][3]                    [ ][ ][ ][ ]
//[0][1][2][3]                    [ ][ ][ ][ ]
//
//        cycle0   cycle1    cycle2    cycle3                     cycle0   cycle1    cycle2    cycle3   cycle4    cycle5    cycle6
//highbit [3]      [3]       [3]       [3]                |------------------------------------->[0]      [1]       [2]       [3]   
//        [2]      [2]       [2]       [2]                | |------------------------->[0]       [1]      [2]       [3]             
//        [1]      [1]       [1]       [1]                | | |------------->[0]       [1]       [2]      [3]                       
//low-bit [0]      [0]       [0]       [0]                | | | |-->[0]      [1]       [2]       [3]                                
//         |        |         |         |        biffer   | | | | 
//         |        |         |         ---->[3][2][1][0]-| | | | 
//         |        |         -------------->[3][2][1][0]---| | | 
//         |        ------------------------>[3][2][1][0]-----| | 
//         --------------------------------->[3][2][1][0]-------|  
//                                           high     low



module ker_top_sparse # (
  parameter                             DW     = 16                 ,
  parameter                             NUM    = 32                       
) (
  input                                 clk                         ,
  input                                 reset                       ,
  input                                 ker_wstart                  ,
  input         [NUM*DW*2-1:0]          ker_wdata                   ,
  input         [2-1:0]                 ker_wvld                    ,
  input                                 ker_pp                      ,
  input                                 ker_rstart                  ,
  input         [7-1:0]                 ker_hold                    ,
  
  output  wire  [NUM-1:0]               ker_addr_vld                ,
  output  wire  [NUM*5 -1:0]            ker_addr_cnt                ,
  output  wire  [NUM-1:0]               ker_addr_rpp                ,

  output  wire  [NUM*DW-1:0]            ker_rdata                   ,
  output  wire                          ker_rdata_vld               ,    
  output  wire                          ker_rdata_start             
  
                
);

  localparam                            KER_RAM_DEEP  =32           ;
  localparam                            KER_RAM_CYCLE =2            ;
  localparam                            KER_RAM_ADDR  =5            ;
  integer i=0,j=0;
  wire [KER_RAM_DEEP*(NUM*DW)-1:0]      RAM_wdata0                  ;
  wire [KER_RAM_DEEP*(NUM*DW)-1:0]      RAM_wdata1                  ;
  wire [KER_RAM_DEEP* NUM-1:0]          RAM_wen0                    ;
  wire [KER_RAM_DEEP* NUM-1:0]          RAM_wen1                    ;   

  wire [NUM*KER_RAM_ADDR -1:0]          RAM_addr_cnt0               ;
  wire [NUM*KER_RAM_ADDR -1:0]          RAM_addr_cnt1               ;
  wire [NUM*DW-1:0]                     RAM_rdata0                  ;
  wire [NUM*DW-1:0]                     RAM_rdata1                  ;


(*keep_hierarchy="yes"*)ker_write #(
  .DW               (DW                 ),
  .NUM              (NUM                ),
  .KER_RAM_DEEP     (KER_RAM_DEEP       )            
)u_ker_write(
  .clk              (clk                ),
  .reset            (reset              ),
  .ker_wstart       (ker_wstart         ),
  .ker_wdata        (ker_wdata          ),
  .ker_wvld         (ker_wvld           ),
  .ker_pp           (ker_pp             ),
  
  .RAM_wdata0       (RAM_wdata0         ),
  .RAM_wdata1       (RAM_wdata1         ),
  .RAM_wen0         (RAM_wen0           ),
  .RAM_wen1         (RAM_wen1           )
);


(*keep_hierarchy="yes"*)ker_buffer # (
  .DW (DW ),
  .NUM(NUM)  
)u_ker_buffer(
  .clk              (clk                ),
  .reset            (reset              ),
  .RAM_wen0         (RAM_wen0           ),
  .RAM_wen1         (RAM_wen1           ),
  .RAM_wdata0       (RAM_wdata0         ),
  .RAM_wdata1       (RAM_wdata1         ),
  .RAM_rdata0       (RAM_rdata0         ),
  .RAM_rdata1       (RAM_rdata1         ),
  .RAM_addr_vld     (ker_addr_vld       ),//for sim
  .RAM_addr_cnt0    (RAM_addr_cnt0      ),
  .RAM_addr_cnt1    (RAM_addr_cnt1      )        
);

(*keep_hierarchy="yes"*)ker_read # (
  .DW               (DW                 ),
  .NUM              (NUM                ),
  .KER_RAM_ADDR     (KER_RAM_ADDR       ),
  .KER_RAM_DEEP     (KER_RAM_DEEP       )
)u_ker_read(
  .clk              (clk                ),
  .reset            (reset              ),
  .ker_pp           (ker_pp             ),
  .ker_rstart       (ker_rstart         ),
  .ker_hold         (ker_hold           ),
  
  .ker_addr_vld     (ker_addr_vld       ),
  .ker_addr_rpp     (ker_addr_rpp       ),
  .ker_addr_cnt     (ker_addr_cnt       ),
  
  .RAM_addr_cnt0    (RAM_addr_cnt0      ),
  .RAM_addr_cnt1    (RAM_addr_cnt1      ),
  .RAM_rdata0       (RAM_rdata0         ),
  .RAM_rdata1       (RAM_rdata1         ),
  
  .ker_rdata        (ker_rdata          ),
  .ker_rdata_vld    (ker_rdata_vld      ),    
  .ker_rdata_start  (ker_rdata_start    )
           
);


endmodule
