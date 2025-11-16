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
// 6.0            2024-05-30  Shaoqiang       Make small modules based on their functions.


module ofm_merge #(
  parameter                        NUM  =   32                  ,
  parameter                        PNUM =   4                   ,
  parameter                        DW   =   37                  ,
  localparam                       IDW  =   PNUM*NUM*DW         
)(
  input                            clk                          ,
  input                            reset                        ,
  input  [NUM*PNUM*DW-1:0]         data_in                      ,
  input  [NUM*PNUM-1:0]            data_in_vld                  ,
  input  [NUM-1:0]                 data_in_meg                  ,  


  output [NUM*PNUM*DW-1:0]         data_out                     ,
  output [NUM*PNUM   -1:0]         data_out_vld                 
                
);

  integer i=0,j=0;
  reg  [NUM*PNUM*DW-1:0]  r0_data_in     =0                     ;
  reg  [NUM*PNUM-1:0]     r0_data_in_vld =0                     ;
  reg  [NUM -1:0]         r0_data_in_meg =0                     ; 
  reg  [NUM*2-1:0]        r0_data_in_case=0                     ;

  wire [NUM*PNUM*DW-1:0]  r1_data_out                           ;
  wire [NUM*PNUM-1:0]     r1_data_out_vld                       ;
  wire [NUM -1:0]         r1_data_out_meg                       ; 

  wire [NUM*PNUM*DW-1:0]  r2_data_out                           ;
  wire [NUM*PNUM-1:0]     r2_data_out_vld                       ;

  reg  [NUM*PNUM*DW-1:0]  r3_data_in     =0                     ;
  reg  [NUM*PNUM-1:0]     r3_data_in_vld =0                     ;
  reg  [NUM*2-1:0]        r3_data_in_case=0                     ;


//------------------------------------------------------------------------
//
//------------------------------------------------------------------------
  always @(posedge clk)
  begin
      r0_data_in     <= data_in     ;
      r0_data_in_vld <= data_in_vld ;
      r0_data_in_meg <= data_in_meg ;
            
      for(i=0;i<NUM;i=i+1)
      r0_data_in_case[i*2+:2]<=
      data_in_vld[i*PNUM+3+:1]+
      data_in_vld[i*PNUM+2+:1]+
      data_in_vld[i*PNUM+1+:1]+
      data_in_vld[i*PNUM+0+:1];
  end
//------------------------------------------------------------------------
//
//------------------------------------------------------------------------
(*keep_hierarchy="yes"*)
ofm_merge_add
#(
  .NUM (32),
  .PNUM(4 ),
  .DW  (37)
)u_ofm_merge_add(
  .clk          (clk            ),
  .reset        (reset          ),
  
  .data_in      (r0_data_in     ),
  .data_in_vld  (r0_data_in_vld ),
  .data_in_meg  (r0_data_in_meg ),
  .data_in_case (r0_data_in_case),
  
  .data_out     (r1_data_out    ),
  .data_out_vld (r1_data_out_vld),
  .data_out_meg (r1_data_out_meg)
);

(*keep_hierarchy="yes"*)
ofm_merge_clear
#(
  .NUM (32),
  .PNUM(4 ),
  .DW  (37)
)u_ofm_merge_clear(
  .clk          (clk            ),
  .reset        (reset          ),
  
  .data_in      (r1_data_out    ),
  .data_in_vld  (r1_data_out_vld),
  .data_in_meg  (r1_data_out_meg),

  .data_out     (r2_data_out    ),
  .data_out_vld (r2_data_out_vld)
);



//------------------------------------------------------------------------
//
//------------------------------------------------------------------------
  always @(posedge clk)
  begin
      r3_data_in      <= r2_data_out    ;
      r3_data_in_vld  <= r2_data_out_vld;
     
      for(i=0;i<NUM;i=i+1)
      r3_data_in_case[i*2+:2]<=
      r2_data_out_vld[i*PNUM+3+:1]+
      r2_data_out_vld[i*PNUM+2+:1]+
      r2_data_out_vld[i*PNUM+1+:1]+
      r2_data_out_vld[i*PNUM+0+:1];
  end


(*keep_hierarchy="yes"*)
ofm_merge_order
#(
  .NUM (32),
  .PNUM(4 ),
  .DW  (37)
)u_ofm_merge_order(
  .clk          (clk            ),
  .reset        (reset          ),
  
  .data_in      (r3_data_in     ),
  .data_in_vld  (r3_data_in_vld ),
  .data_in_case (r3_data_in_case),
  
  .data_out     (data_out       ),
  .data_out_vld (data_out_vld   )
);




//--------------------------------------------------
/*
reg [DW-1:0]  test_r0_data_in    [NUM-1:0][PNUM-1:0];
reg [PNUM-1:0]test_r0_data_in_vld[NUM-1:0];
reg           test_r0_data_in_meg[NUM-1:0];

reg [DW-1:0]  test_r1_data_out    [NUM-1:0][PNUM-1:0];
reg [PNUM-1:0]test_r1_data_out_vld[NUM-1:0];
reg           test_r1_data_out_meg[NUM-1:0];

reg [DW-1:0]  test_r2_data_out    [NUM-1:0][PNUM-1:0];
reg [PNUM-1:0]test_r2_data_out_vld[NUM-1:0];

reg [DW-1:0]  test_data_out    [NUM-1:0][PNUM-1:0];
reg [PNUM-1:0]test_data_out_vld[NUM-1:0];


always @(*)
for(i=0;i<NUM ;i=i+1)
for(j=0;j<PNUM;j=j+1)
begin
    test_r0_data_in_meg[i]<=r0_data_in_meg[i];
    test_r0_data_in     [i][j]<=r0_data_in     [i*(PNUM*DW)+j*DW+:DW];
    test_r0_data_in_vld [i][j]<=r0_data_in_vld [i*(PNUM*1 )+j*1 +:1 ];
    
    test_r1_data_out_meg[i]<=r1_data_out_meg[i];
    test_r1_data_out    [i][j]<=r1_data_out    [i*(PNUM*DW)+j*DW+:DW];
    test_r1_data_out_vld[i][j]<=r1_data_out_vld[i*(PNUM*1 )+j*1 +:1 ];
    
    test_r2_data_out    [i][j]<=r2_data_out    [i*(PNUM*DW)+j*DW+:DW];
    test_r2_data_out_vld[i][j]<=r2_data_out_vld[i*(PNUM*1 )+j*1 +:1 ];
    
    test_data_out       [i][j]<=data_out       [i*(PNUM*DW)+j*DW+:DW];
    test_data_out_vld   [i][j]<=data_out_vld   [i*(PNUM*1 )+j*1 +:1 ];
end
*/






endmodule
