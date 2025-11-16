`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/11/23 13:04:14
// Design Name: 
// Module Name: GELU_driver
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: Gaussian Error Linear Unit
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
/* This file is updated using systemverilog.
   GELU_dirvier convert the scalar GELU active function to a vectorized function.
   NUM_ELEMS defines the elements in the vector.
   The GELU_act gets 2 cycles to compute the results, and the driver use 1 cycles to pass the results, y, to y_vec
*/

module nvm_act_function # (
    parameter DW  = 16,
    parameter NUM = 32
)(
    input                          clk         ,
    input                          rst         ,
    input                          enable      ,
    input         [4-1:0]          act_type    ,
    input         [4-1:0]          nvm_xnum    ,
    input         [4-1:0]          nvm_ynum    ,
    input                          x_vld       ,//i
    input                          x_done      ,
    input         [NUM-1:0][DW-1:0]x_data      ,//i
    output wire   [NUM*DW-1:0]     y_data      ,
    output wire                    y_vld       ,
    output wire                    y_done      ,
    output wire   [NUM*17-1:0]     A_act_out   , 
    output wire   [NUM*15-1:0]     B_act_out   , 
    output wire   [NUM*32-1:0]     C_act_out   , 
    output wire   [NUM*17-1:0]     D_act_out   , 
    input         [NUM*32-1:0]     P_act_in     //i
);
 localparam CUT  =27;
 localparam DLY  =16;
 integer i=0,j=0;

//------------------------------------------------
//
//------------------------------------------------
wire [CUT*15-1:0]   PARAMETER_K_Q15 ;
wire [CUT*17-1:0]   PARAMETER_X_Q17 ;
wire [CUT*32-1:0]   PARAMETER_Y_Q32 ;
(*keep_hierarchy="yes"*)
nvm_act_precision#(
    .CUT            (CUT            ),
    .DW             (DW             ),
    .NUM            (NUM)
)u_act_precision    (
    .clk            (clk            ),
    .rst            (rst            ),
    .x_num          (nvm_xnum       ),
    .PARAMETER_K_Q15(PARAMETER_K_Q15),//o,3cycle
    .PARAMETER_X_Q17(PARAMETER_X_Q17),//o
    .PARAMETER_Y_Q32(PARAMETER_Y_Q32) //o 
);
//------------------------------------------------
//
//------------------------------------------------
wire [NUM*5-1:0]    index           ;
(*keep_hierarchy="yes"*)
nvm_act_compare # (
     .CUT           (CUT            ),
     .DW            (DW             ),
     .NUM           (NUM            )
)u_act_compare (    
    .clk            (clk            ),
    .rst            (rst            ),
    .x_din          (x_data         ),
    .PARAMETER_X_Q17(PARAMETER_X_Q17),
    .index          (index          )//3 cycle 
);
//------------------------------------------------
//
//------------------------------------------------
wire [NUM*15-1:0]   K_sel           ;
wire [NUM*17-1:0]   X_sel           ;
wire [NUM*32-1:0]   Y_sel           ;
(*keep_hierarchy="yes"*)
nvm_act_selector # (
    .CUT            (CUT            ),
    .DW             (DW             ),
    .NUM            (NUM            )
)u_act_selector(    
    .clk            (clk            ),
    .rst            (rst            ),  
    .PARAMETER_K_Q15(PARAMETER_K_Q15),
    .PARAMETER_X_Q17(PARAMETER_X_Q17),
    .PARAMETER_Y_Q32(PARAMETER_Y_Q32),
    .index          (index          ),
    .K_sel          (K_sel          ),//2 cycle
    .X_sel          (X_sel          ),
    .Y_sel          (Y_sel          )
);
//------------------------------------------------
//
//------------------------------------------------
wire                act_vld         ;

(*keep_hierarchy="yes"*)
nvm_act_approximation # (
    .DW             (DW             ),
    .NUM            (NUM            )
)u_act_approximation(
    .clk            (clk            ),
    .rst            (rst            ),
    .act_vld        (act_vld        ),
    .x_num          (nvm_xnum       ),
    .y_num          (nvm_ynum       ),
    .K_sel          (K_sel          ),
    .X_sel          (X_sel          ),
    .Y_sel          (Y_sel          ),
    .x_data         (x_data         ),//2 cycle
    .y_data         (y_data         ),
    .A_act_out      (A_act_out      ),//1 cycle 
    .B_act_out      (B_act_out      ), 
    .C_act_out      (C_act_out      ), 
    .D_act_out      (D_act_out      ), 
    .P_act_in       (P_act_in       ) //8 cycle???? 
);




//---------------------------------------------------
//
//---------------------------------------------------
  reg  [2*DLY-1:0] dly_vd =0                ;
  always @(posedge clk)for(i=0;i<DLY;i=i+1)
  if(i==0)dly_vd[i*2+:2]<={x_vld,x_done}    ;
  else    dly_vd[i*2+:2]<=dly_vd[(i-1)*2+:2];
  assign  y_vld  =dly_vd[(DLY-1)*2+1]       ;
  assign  y_done =dly_vd[(DLY-1)*2+0]       ;
  assign  act_vld=dly_vd[(4)*2+1]           ;
  
endmodule
