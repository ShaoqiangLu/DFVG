`timescale 1ns/1ps

// -----------------------------------------------------------------------------
// UCLA EDA LAB
// -----------------------------------------------------------------------------
// Engineer       : Chen Wu
// Design Name    : opu series
// Module Name    : pe_top
// Description    : 
//    an array of macc units, using adder tree to sum up the results.
//    Different columns performs in parallel.
//    Delay       : 3 + CAS - 1 + $clog2(NUM)
// 
// Parameters     :
//    CAS         : Depth for cascade.
//    NUM         : Number of macc units.
//    COL         : Number of macc_col.
//    DW          : Data width for inputs.
//    RATIO       : Ratio between fast clock and slow clock, only 2 now.
//    !Attention  : Do not set too large CAS for timing closure.
//
// Revision       :
// Version        Date        Author        Descriptin
// 1.0            2024-01-09  Chen Wu       Initial version
// 2.0            2024-05-25  Shaoqiang     Organize and reduce registers. 
//                                          For the synthetic layout.
// -----------------------------------------------------------------------------

`include "opu_parameter.vh"
module pe_top
#(
  parameter                         DW      =   16                          ,
  parameter                         NUM     =   32                          ,
  parameter                         ODW     =   32                          
)(
  input                             clk                                     ,
  input                             reset                                   ,
  input     [NUM-1:0][NUM*DW-1:0]   dina                                    ,//ifm
  input                             dina_vld                                ,
  input                             dina_done                               ,

  input                             dinb_vld                                ,
  input                             dinb_done                               ,
  input     [NUM-1:0][NUM*DW-1:0]   dinb                                    ,//ker

  output reg  [NUM-1:0][ODW-1:0]    dout       =0                           ,
  output wire                       dout_vld                                ,
  output wire                       dout_done                               
);


//----------------------------------------------------------------------------
//To delay the valid signal.
//----------------------------------------------------------------------------
     
  localparam                        PE_DLY  =`PE_DLY                        ;
  integer                           i=0,j   = 0;
  reg                               [PE_DLY*2-1:0]  dly_dv   =0             ;
  always @(posedge clk)
  for(i=0;i<PE_DLY;i=i+1)
  if(i==0)dly_dv[i*2+:2]            <={dina_vld,dina_done}                  ;
  else    dly_dv[i*2+:2]            <=dly_dv[(i-1)*2+:2]                    ;
  assign  dout_vld                   =dly_dv[(PE_DLY-1)*2+1+:1]             ;
  assign  dout_done                  =dly_dv[(PE_DLY-1)*2+0+:1]             ;




`ifdef OPU_SYNTH_IMPLE_simple_pe

  wire [NUM*ODW-1:0] simple_dout;
  pe_simple_top
  #(
    .DW           (16           ),
    .NUM          (32           )
  )u_pe_simple_top(
    .clk          (clk          ),
    .dina         (dina[0]      ),
    .dinb         (dinb         ),
    .dinb_vld     (dinb_vld     ),
    .dout         (simple_dout  )
  );
  always @(posedge clk)
     dout         <=simple_dout ;
`else


//----------------------------------------------------------------------------
// Instantiate PE array
//----------------------------------------------------------------------------
  generate for (genvar i=0; i<NUM/2; i=i+1) 
  begin: array
  
    //-----------------------------------------------------------------------
    // Input data repeatedly.
    //-----------------------------------------------------------------------
    reg  [NUM*DW-1:0]               r_dina=0                                ;
    always @(posedge clk)
    begin
         r_dina                     <=dina[i]                               ;
    end
    //-----------------------------------------------------------------------
    // The fold weight becomes 2.
    //-----------------------------------------------------------------------
    reg  [NUM*DW-1:0]               r0_dinb=0                               ;
    reg  [NUM*DW-1:0]               r1_dinb=0                               ;
    
    
    always @(posedge clk)
    begin
         r0_dinb                    <=dinb[0 +i]                            ;
         r1_dinb                    <=dinb[16+i]                            ; 
    end
    
    //-----------------------------------------------------------------------
    // The output is reordered.
    //-----------------------------------------------------------------------
    wire [ODW-1:0]                  r0_dout                                 ;
    wire [ODW-1:0]                  r1_dout                                 ;
    always @(posedge clk)           dout[0 +i]<=r0_dout                     ;
    always @(posedge clk)           dout[16+i]<=r1_dout                     ;
  
    `ifndef SIM_PE
    pe_array#(
      .DW                           (DW                                     ),
      .NUM                          (NUM                                    ),
      .ODW                          (ODW                                    )
    )
    u_array(
      .clk                          (clk                                    ),
      .dina                         (r_dina                                 ),
      .dinb0                        (r0_dinb                                ),
      .dinb1                        (r1_dinb                                ),  
      .dout0                        (r0_dout                                ),
      .dout1                        (r1_dout                                )
    );
   `else
    assign r0_dout=0;
    assign r1_dout=0;
   `endif
  end
  endgenerate
`endif

//------------------------------------------------------------------------------
//Test data, in order to facilitate the observation of the waveform
//------------------------------------------------------------------------------
`ifdef SIM_CODE
  wire [NUM*DW-1:0]                 test_dina_wire=dina[0]                  ;
  wire [NUM*NUM*DW-1:0]             test_dinb_wire=dinb                     ;
  reg  [DW-1:0]                     test_dina[NUM-1:0]                      ;
  reg  [DW-1:0]                     test_dinb[NUM-1:0][NUM-1:0]             ;
  reg  [ODW-1:0]                    test_dout[NUM-1:0]                      ;
  always @(*)
  begin
      for(i=0;i<NUM;i=i+1)
      test_dina[i]                  <=test_dina_wire[i*DW+:DW]              ;
  end

  always @(*)
  begin
      for(i=0;i<NUM;i=i+1)
      for(j=0;j<NUM;j=j+1)
      test_dinb[i][j]               <=test_dinb_wire[i*(DW*NUM)+j*DW+:DW]   ;
  end

  always @(*)
  begin
      for(i=0;i<NUM;i=i+1)
      test_dout[i]                  <=dout[i]                               ;
  end
`endif



endmodule
