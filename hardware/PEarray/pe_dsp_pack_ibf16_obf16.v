`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/17/2025 07:35:33 PM
// Design Name: 
// Module Name: pe_dsp_pack_bf16
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
// FF=105,FF-216


module pe_dsp_pack_ibf16_obf16(
    input                   clk                 ,
    input                   reset               ,
    input       [16-1:0]    din_x               ,
    input       [16-1:0]    din_y1              ,
    input       [16-1:0]    din_y2              ,
    
    output      [16-1:0]    dout_xy1            ,///
    output      [16-1:0]    dout_xy2             ///
);
    
    wire        [16-1:0]   din_b                ;
    wire        [16-1:0]   din_c                ;   
    wire        [16-1:0]   din_d                ;
    
    wire        [8-1:0]    exp_b                ;
    wire        [8-1:0]    exp_c                ;
    wire        [8-1:0]    exp_d                ;
    
    wire        [8-1:0]    mts_b                ;
    wire        [8-1:0]    mts_c                ;
    wire        [8-1:0]    mts_d                ;
    
    wire                   sign_bc              ;
    wire                   sign_bd              ;
    wire                   r_sign_bc            ;
    wire                   r_sign_bd            ;
    
    wire        [9-1:0]    sum_exp_bc           ;
    wire        [9-1:0]    sum_exp_bd           ;
    reg         [9-1:0]    r_sum_exp_bc    =0   ;
    reg         [9-1:0]    r_sum_exp_bd    =0   ;
    
    reg         [27-1:0]   dsp_mul_a=0          ;
    reg         [18-1:0]   dsp_mul_b=0          ; 

    wire        [48-1:0]   dsp_prod             ;
    
    wire        [16-1:0]   dout_bc              ;
    wire        [16-1:0]   dout_bd              ;
    
    
    //just normalization
    
    assign      din_b = din_x[15: 0]            ;
    assign      din_c = din_y1[15: 0]           ;                  
    assign      din_d = din_y2[15: 0]           ;
    
    assign      exp_b = din_b[14:7]             ;
    assign      exp_c = din_c[14:7]             ;
    assign      exp_d = din_d[14:7]             ;
    
    assign      mts_b = {1'b1,din_b[6:0]}       ;
    assign      mts_c = {1'b1,din_c[6:0]}       ;
    assign      mts_d = {1'b1,din_d[6:0]}       ;
    
    assign      r_sign_bc = din_b[15] ^ din_c[15];
    assign      r_sign_bd = din_b[15] ^ din_d[15];
    


//if exp =0 , result = 0 
    always @(posedge clk)
    begin
        r_sum_exp_bc <= ((exp_b==8'd0) || (exp_c==8'd0)) ? 9'd0 :  (exp_b + exp_c - 7'd127) ;
        r_sum_exp_bd <= ((exp_b==8'd0) || (exp_d==8'd0)) ? 9'd0 :  (exp_b + exp_d - 7'd127) ;
    end
    
    
    
    dly_cell#(
        .DW     ( 2*9                           ),
        .DLY    ( 4 + 0                         )//4+1
    ) u0_dly_exp(
        .dout   ( {sum_exp_bc,
                   sum_exp_bd                   }),
        .din    ( {r_sum_exp_bc,
                   r_sum_exp_bd                 }),
        .clk    ( clk                           ),
        .reset  ( reset                         )
    );
    
    dly_cell#(
        .DW     ( 1*2                           ),
        .DLY    ( 4 + 1 + 1                     )
    )u1_dly_sign(
        .dout   ( {sign_bc, 
                   sign_bd                      }),
        .din    ( {r_sign_bc,
                   r_sign_bd                    }),
        .clk    ( clk                           ),
        .reset  ( reset                         )
     );

    
    
    always @(posedge clk)
    begin
        dsp_mul_a <= {3'h0, mts_c, 8'h0, mts_d};
        dsp_mul_b <= {10'h0, mts_b};
    end    
    

    
    reg [26 : 0] DSP_A=0 ;
    reg [17 : 0] DSP_B=0 ;
    reg [47 : 0] DSP_C=0 ;
    reg [26 : 0] DSP_D=0 ;
    wire [47 : 0] DSP_P ;
    
    always @(*) begin
        DSP_A =dsp_mul_a;
        DSP_B =dsp_mul_b;
        DSP_C ={48{1'b0}};
        DSP_D ={27{1'b0}};
    end
    
    DSP_PE_INT u_dsp_int (
      .CLK  ( clk       ),  // input wire CLK
      .A    ( DSP_A     ),      // input wire [26 : 0] A
      .B    ( DSP_B     ),      // input wire [17 : 0] B
      .C    ( DSP_C     ),      // input wire [47 : 0] C
      .D    ( DSP_D     ),      // input wire [26 : 0] D
      .P    ( DSP_P     )      // output wire [47 : 0] P
    );
    
    assign dsp_prod=DSP_P;
    

    
    pe_dsp_combine_obf16 u_combine_obf16(
        .clk        (clk                        ),
        .dsp_prod   (dsp_prod                   ),
        .sign_bc    (sign_bc                    ),
        .sign_bd    (sign_bd                    ),
        .sum_exp_bc (sum_exp_bc                 ),
        .sum_exp_bd (sum_exp_bd                 ),
        .dout_bc    (dout_bc                    ),
        .dout_bd    (dout_bd                    )
    );
    
    assign dout_xy1 = dout_bc;
    assign dout_xy2 = dout_bd;
    
//------------------------------------------------------
//5 cycle adder for fp32
//------------------------------------------------------   
//    add_fp32 u0_add_fp32 (
//        .clk        ( clk                       ),
//        .x1         ( r_pcin_xy1                ),
//        .x2         ( dout_bc                   ),
//        .y          ( psum_xy1                  )
//    );
    
//    add_fp32 u1_add_fp32 (
//        .clk        ( clk                       ),
//        .x1         ( r_pcin_xy2                ),
//        .x2         ( dout_bd                   ),
//        .y          ( psum_xy2                  )
//    );




endmodule