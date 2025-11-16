`timescale 1ns / 1ps
// -----------------------------------------------------------------------------
// Orgnization: UCLA EDA lab
// Design Name    : opu series
// Module Name    : output_ctrl_top
// Target Devices : k325t
// Tool Versions  : Vivado 2020.1, Modelsim 2019.4
// Description    : 
//    Add bias or temp results to finalize the calculation of one convolutional
//    layer.
// Revision       :
// Version        Date        Author          Description
// 1.0            2017-10-25  Chen Wu         Initial version
// 1.1            2020-02-04  Chen Wu         Modify code style
// 3.1            2021-02-01  Shan Shen       Change data width to 42 from 26
// 3.2            2021-04-07  Jinming Zhuang  Modify & specify the sequential 
//                                            relationship in internal signals
// 4.0            2021-04-26  Chen Wu         Add parameter & delete rearrange
// 4.1            2022-04--7  Chen Wu         Simplify for INT16 case, add pp
// 5.0            2022-09-14  Shaoqiang       Simulation 97 layers,and       
//                                            implementation on FPGA of U200.
// -----------------------------------------------------------------------------
`include "opu_parameter.vh"
module ofm_collect #(
  parameter                        NUM  =   32                  ,
  parameter                        PNUM =   4                   ,
  parameter                        DW   =   37                  ,
  localparam                       IDW  =   DW+1                ,       
  localparam                       INUM =   NUM*PNUM            //128
)(
  input                            clk                          ,
  input                            reset                        ,
  input       [INUM-1:0]           data_in_vld                  ,
  input       [INUM-1:0][DW-1:0]   data_in                      ,
  output reg  [INUM*DW-1:0]        data_out     =0              ,
  output reg  [INUM   -1:0]        data_out_vld =0                           
);



  integer i=0,j=0;
  reg   [INUM*IDW-1:0]  WIRE4  =0  ;
  wire  [INUM*IDW-1:0]  WIRE8      ;
  wire  [INUM*IDW-1:0]  WIRE16     ;
  wire  [INUM*IDW-1:0]  WIRE32     ;
  wire  [INUM*IDW-1:0]  WIRE64     ;
  wire  [INUM*IDW-1:0]  WIRE128    ;


  always @(posedge clk)
  for(i=0;i<INUM;i=i+1)
  WIRE4[i*IDW+:IDW]<=
  {data_in[i],
   data_in_vld[i]};

  (*keep_hierarchy="yes"*)
  ofm_4to8#(
    .NUM            (INUM       ), 
    .IDW            (IDW        ),
    .DWCNT          (2          ),
    .SELPRE         (4          ),
    .SELCUR         (8          )
  )u_4to8(
    .data_in        (WIRE4      ),
    .data_out       (WIRE8      ),
    .clk            (clk        ),       
    .reset          (reset      )
  );

  (*keep_hierarchy="yes"*)
  ofm_8to16#(
    .NUM            (INUM       ), 
    .IDW            (IDW        ),
    .DWCNT          (3          ),
    .SELPRE         (8          ),
    .SELCUR         (16         )
  )u_8to16(
    .data_in        (WIRE8      ),
    .data_out       (WIRE16     ),
    .clk            (clk        ),       
    .reset          (reset      )
  );


  (*keep_hierarchy="yes"*)
  ofm_16to32#(
    .NUM            (INUM       ), 
    .IDW            (IDW        ),
    .DWCNT          (4          ),
    .SELPRE         (16         ),
    .SELCUR         (32         )
  )u_16to32(
    .data_in        (WIRE16     ),
    .data_out       (WIRE32     ),
    .clk            (clk        ),       
    .reset          (reset      )
  );

  (*keep_hierarchy="yes"*)
  ofm_32to64#(
    .NUM            (INUM       ), 
    .IDW            (IDW        ),
    .DWCNT          (5          ),
    .SELPRE         (32         ),
    .SELCUR         (64         )
  )u_32to64(
    .data_in        (WIRE32     ),
    .data_out       (WIRE64     ),
    .clk            (clk        ),       
    .reset          (reset      )
  );

  (*keep_hierarchy="yes"*)
  ofm_64to128#(
    .NUM            (INUM       ), 
    .IDW            (IDW        ),
    .DWCNT          (6          ),
    .SELPRE         (64         ),
    .SELCUR         (128        )
  )u_64to128(
    .data_in        (WIRE64     ),
    .data_out       (WIRE128    ),
    .clk            (clk        ),       
    .reset          (reset      )
  );


//--------------------------------------------------------
//
//--------------------------------------------------------
  always @(posedge clk)
  for(i=0;i<INUM;i=i+1)
  begin
    data_out_vld[i*1+:1]  <=WIRE128[i*IDW  +:1 ];
    data_out    [i*DW+:DW]<=WIRE128[i*IDW+1+:DW];
  end





`ifdef SIM_CODE
  //-------------------------------------------------
  //Only used for simulation debugging.
  //-------------------------------------------------
  reg [DW-1:0]   test_data_WIRE4  [128-1:0];
  reg [DW-1:0]   test_data_WIRE8  [128-1:0];
  reg [DW-1:0]   test_data_WIRE16 [128-1:0];
  reg [DW-1:0]   test_data_WIRE32 [128-1:0];
  reg [DW-1:0]   test_data_WIRE64 [128-1:0];
  reg [DW-1:0]   test_data_WIRE128[128-1:0];
  reg            test_vlid_WIRE128[128-1:0]; 
  
  always @(*)
   for(i=0;i<128;i=i+1)
  begin
      test_data_WIRE4  [i]<=WIRE4  [(i*IDW)+1+:DW]; 
      test_data_WIRE8  [i]<=WIRE8  [(i*IDW)+1+:DW]; 
      test_data_WIRE16 [i]<=WIRE16 [(i*IDW)+1+:DW]; 
      test_data_WIRE32 [i]<=WIRE32 [(i*IDW)+1+:DW]; 
      test_data_WIRE64 [i]<=WIRE64 [(i*IDW)+1+:DW]; 
      test_data_WIRE128[i]<=WIRE128[(i*IDW)+1+:DW]; 
      test_vlid_WIRE128[i]<=WIRE128[(i*IDW)+0+:1 ]; 
  end
`endif



endmodule

















