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
//`define DSP_PE_IP_FP32
//`define DSP_PE_IP_FP16
//`define DSP_PE_USER_FP32
`define DSP_PE_USER_BF16

module pe_array
#(
  parameter                         DW  =   16      ,
  parameter                         NUM =   32      ,
  parameter                         ODW =   32
)(
  input                             clk             ,
  input       [NUM-1:0][DW-1:0]     dina            ,
  input       [NUM-1:0][DW-1:0]     dinb0           ,
  input       [NUM-1:0][DW-1:0]     dinb1           ,
  output wire          [ODW-1:0]    dout0           ,
  output wire          [ODW-1:0]    dout1        
);

  //-------------------------------------------------
  //Instantiate adder tree 0.
  //-------------------------------------------------
  reg   [NUM*ODW-1:0]  dout_mul0    =0              ;
  
  wire  [16-1:0]       r_dout0                      ;
  wire  [NUM*16-1:0]   r_dout_mul0                  ;
  pe_adder_tree #(
    .STAGE          (5                              ),
    .DW             (ODW/2                          )
  )u_pe_adder_tree0(
    .dout           (r_dout0                        ),
    .din            (r_dout_mul0                    ),
    .clk            (clk                            ),
    .reset          (1'b0                           )
  );
  assign            dout0   ={r_dout0,16'd0}        ;


  //-------------------------------------------------
  //Instantiate adder tree 1.
  //-------------------------------------------------
  reg   [NUM*ODW-1:0]  dout_mul1    =0              ;
  wire  [16-1:0]       r_dout1                      ;
  wire  [NUM*16-1:0]   r_dout_mul1                  ;
  pe_adder_tree #(
    .STAGE          (5                              ),
    .DW             (ODW/2                          )
  )u_pe_adder_tree1(
    .dout           (r_dout1                        ),
    .din            (r_dout_mul1                    ),
    .clk            (clk                            ),
    .reset          (1'b0                           )
  );
  assign            dout1   ={r_dout1,16'd0}        ;


generate for(genvar i=0;i<NUM;i=i+1) 
begin: unit
    
    wire   [32-1:0]dout_mul0_wire                   ;
    assign dout_mul0_wire=dout_mul0[i*ODW+:ODW]     ;
    assign r_dout_mul0[i*16+:16]=dout_mul0_wire[32-1:16];

    wire   [32-1:0]dout_mul1_wire                   ;
    assign dout_mul1_wire=dout_mul1[i*ODW+:ODW]     ;
    assign r_dout_mul1[i*16+:16]=dout_mul1_wire[32-1:16];


    //-----------------------------------------------
    //Share an input data.
    //-----------------------------------------------
    reg    [DW-1:0] r_dina  =0                      ;
    always @(posedge clk)
    begin
        r_dina<=dina[i]                             ;   
    end
    
    //-----------------------------------------------
    //Two weights.
    //-----------------------------------------------
    reg    [DW-1:0]  r_dinb0  =0                    ;
    reg    [DW-1:0]  r_dinb1  =0                    ;
    always @(posedge clk)
    begin
           r_dinb0   <=dinb0[i]                     ;  
           r_dinb1   <=dinb1[i]                     ;
    end
    
    //-----------------------------------------------
    //Output two results
    //-----------------------------------------------
    wire   [ODW-1:0] r_dout_mul0                    ;
    wire   [ODW-1:0] r_dout_mul1                    ;
    
    always @(posedge clk)
    begin
        dout_mul0[i*ODW+:ODW]<=r_dout_mul0          ;
        dout_mul1[i*ODW+:ODW]<=r_dout_mul1          ;
    end

   //-----------------------------------------------
   //Instantiating the Multiplier Unit
   //-----------------------------------------------
`ifdef DSP_PE_IP_FP32

    //-----------------------------------------------
    //8 cycle,LUT=244,FF=400
    //-----------------------------------------------
    DSP_PE_FP32 u0_DSP_PE_FP32 (
      .aclk                 (clk                    ),// input  wire aclk
      .s_axis_a_tvalid      (1'b1                   ),// input  wire s_axis_a_tvalid
      .s_axis_a_tready      (                       ),// output wire s_axis_a_tready
      .s_axis_a_tdata       ({r_dinad,16'd0}        ),// input  wire [31 : 0] s_axis_a_tdata
      .s_axis_b_tvalid      (1'b1                   ),// input  wire s_axis_b_tvalid
      .s_axis_b_tready      (                       ),// output wire s_axis_b_tready
      .s_axis_b_tdata       ({r_dinb0,16'd0}        ),// input  wire [31 : 0] s_axis_b_tdata
      .m_axis_result_tvalid (                       ),// output wire m_axis_result_tvalid
      .m_axis_result_tdata  (r_dout_mul0            ) // output wire [31 : 0] m_axis_result_tdata
    );

    DSP_PE_FP32 u1_DSP_PE_FP32 (
      .aclk                 (clk                    ),// input  wire aclk
      .s_axis_a_tvalid      (1'b1                   ),// input  wire s_axis_a_tvalid
      .s_axis_a_tready      (                       ),// output wire s_axis_a_tready
      .s_axis_a_tdata       (r_dina                 ),// input  wire [31 : 0] s_axis_a_tdata
      .s_axis_b_tvalid      (1'b1                   ),// input  wire s_axis_b_tvalid
      .s_axis_b_tready      (                       ),// output wire s_axis_b_tready
      .s_axis_b_tdata       (r_dinb1                ),// input  wire [31 : 0] s_axis_b_tdata
      .m_axis_result_tvalid (                       ),// output wire m_axis_result_tvalid
      .m_axis_result_tdata  (r_dout_mul1            ) // output wire [31 : 0] m_axis_result_tdata
    );
 
`elsif DSP_PE_IP_FP16
    wire   [DW-1:0]        r_dout_mul0_wire         ;
    wire   [DW-1:0]        r_dout_mul1_wire         ;

    assign r_dout_mul0     ={r_dout_mul0_wire,16'd0};
    assign r_dout_mul1     ={r_dout_mul1_wire,16'd0};

    //-----------------------------------------------
    //7 cycle+1reg,LUT=71,FF=133
    //-----------------------------------------------
    reg    [DW-1:0]  r0_dina0  =0                   ;
    reg    [DW-1:0]  r0_dina1  =0                   ;
    reg    [DW-1:0]  r0_dinb0  =0                   ;
    reg    [DW-1:0]  r0_dinb1  =0                   ;
    always @(posedge clk)
    begin
            r0_dina0        <=r_dina                ;    
            r0_dina1        <=r_dina                ;    
            r0_dinb0        <=r_dinb0               ;    
            r0_dinb1        <=r_dinb1               ;    
    end

    DSP_PE_BF16 u0_DSP_PE_BF16 (
      .aclk                 (clk                    ),// input  wire aclk
      .s_axis_a_tvalid      (1'b1                   ),// input  wire s_axis_a_tvalid
      .s_axis_a_tready      (                       ),// output wire s_axis_a_tready
      .s_axis_a_tdata       (r0_dina0               ),// input  wire [15 : 0] s_axis_a_tdata
      .s_axis_b_tvalid      (1'b1                   ),// input  wire s_axis_b_tvalid
      .s_axis_b_tready      (                       ),// output wire s_axis_b_tready
      .s_axis_b_tdata       (r0_dinb0               ),// input  wire [15 : 0] s_axis_b_tdata
      .m_axis_result_tvalid (                       ),// output wire m_axis_result_tvalid
      .m_axis_result_tdata  (r_dout_mul0_wire       ) // output wire [15 : 0] m_axis_result_tdata
    );

    DSP_PE_BF16 u1_DSP_PE_BF16 (
      .aclk                 (clk                    ),// input  wire aclk
      .s_axis_a_tvalid      (1'b1                   ),// input  wire s_axis_a_tvalid
      .s_axis_a_tready      (                       ),// output wire s_axis_a_tready
      .s_axis_a_tdata       (r0_dina1               ),// input  wire [15 : 0] s_axis_a_tdata
      .s_axis_b_tvalid      (1'b1                   ),// input  wire s_axis_b_tvalid
      .s_axis_b_tready      (                       ),// output wire s_axis_b_tready
      .s_axis_b_tdata       (r0_dinb1               ),// input  wire [15 : 0] s_axis_b_tdata
      .m_axis_result_tvalid (                       ),// output wire m_axis_result_tvalid
      .m_axis_result_tdata  (r_dout_mul1_wire       ) // output wire [15 : 0] m_axis_result_tdata
    );
`elsif DSP_PE_USER_FP32
    //-----------------------------------------------
    // aglin=8cycle
    //-----------------------------------------------
    pe_dsp_pack_bf16 
    u_pe_unit
    (
      .clk                  (clk                    ),
      .reset                (1'b0                   ),
      .din_x                (r_dina                 ),
      .din_y1               (r_dinb0                ),
      .din_y2               (r_dinb1                ),
      .dout_xy1             (r_dout_mul0            ),
      .dout_xy2             (r_dout_mul1            )
    );
`elsif DSP_PE_USER_BF16
    //-----------------------------------------------
    // aglin=8cycle
    //-----------------------------------------------
    wire   [DW-1:0]        r_dout_mul0_wire         ;
    wire   [DW-1:0]        r_dout_mul1_wire         ;

    assign r_dout_mul0     ={r_dout_mul0_wire,16'd0};
    assign r_dout_mul1     ={r_dout_mul1_wire,16'd0};
    pe_dsp_pack_ibf16_obf16
    u_pe_dsp_pack_ibf16_obf16
    (
      .clk                 (clk                    ),
      .reset               (1'b0                   ),
      .din_x               (r_dina                 ),
      .din_y1              (r_dinb0                ),
      .din_y2              (r_dinb1                ),
      .dout_xy1            (r_dout_mul0_wire       ),
      .dout_xy2            (r_dout_mul1_wire       ) 
    );

`endif

end
endgenerate  
    




endmodule





















