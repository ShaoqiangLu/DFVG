`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/12/07 12:07:45
// Design Name: 
// Module Name: Vexe
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

/* This is a vectorizing wrapper for exp_func. */
`include "opu_parameter.vh"
module nvm_sf_exp #(
    parameter       NUM_ELEMS                      =32, 
    parameter       DATA_WIDTH                     =16,
    parameter       DLY                            =8 
)(
    input                                          clk          ,
    input                                          rst          ,
    input                                          x_val        ,
    input                                          x_done       ,
    input     signed[NUM_ELEMS-1:0][(DATA_WIDTH+1)-1:0]x_data   ,//Q17_9
    output   reg    [NUM_ELEMS-1:0][ DATA_WIDTH   -1:0]y_data=0 ,//Q16_14
    output   wire                                  y_val        ,
    output   wire                                  y_done       ,
    output   reg    [NUM_ELEMS-1:0][17-1:0]        A_exp_out=0  ,//Q17_9
    output   reg    [NUM_ELEMS-1:0][15-1:0]        B_exp_out=0  ,//Q15_14
    output   reg    [NUM_ELEMS-1:0][32-1:0]        C_exp_out=0  ,//Q32_23
    output   reg    [NUM_ELEMS-1:0][17-1:0]        D_exp_out=0  ,//Q17_9
    input           [NUM_ELEMS-1:0][32-1:0]        P_exp_in      //Q32_23
);

////-------------------------------------------------------------------------------------------------------------------------------------------------
//http://binary-converter.bchrt.com/
//
//x is Q17_9  : setpx= 0.001953  x_min= -128.998047   x_max= 127.998047
//y is Q16_14 : setpy= 0.000061  y_min=   -2.999939   y_max=   1.999939
//
//[-oo       ,-9.69727)  x<x0[0]  [ -oo ,x0[0])  range_idx=0  #         -oo               0.00000000           0.0000000000   y=0                         
//[-9.69727  ,-6.00000)  x<x0[1]  [x0[0],x0[1])  range_idx=1  #  x0[0]= -9.69727   k0[0]= 0.00061035    y0[0]= 0.0000619888   y=(x-x0[0])*k0[0]+y0[0]     
//[-6.00000  ,-4.00000)  x<x0[2]  [x0[1],x0[2])  range_idx=2  #  x0[1]= -6.00000   k0[1]= 0.00787353    y0[1]= 0.0024789571   y=(x-x0[1])*k0[1]+y0[1]     
//[-4.00000  ,-3.00000)  x<x0[3]  [x0[2],x0[3])  range_idx=3  #  x0[2]= -4.00000   k0[2]= 0.03143310    y0[2]= 0.0183159112   y=(x-x0[2])*k0[2]+y0[2]     
//[-3.00000  ,-2.40039)  x<x0[4]  [x0[3],x0[4])  range_idx=4  #  x0[3]= -3.00000   k0[3]= 0.06817627    y0[3]= 0.0497869253   y=(x-x0[3])*k0[3]+y0[3]     
//[-2.40039  ,-2.00000)  x<x0[5]  [x0[4],x0[5])  range_idx=5  #  x0[4]= -2.40039   k0[4]= 0.11151123    y0[4]= 0.0907179117   y=(x-x0[4])*k0[4]+y0[4]     
//[-2.00000  ,-1.60156)  x<x0[6]  [x0[5],x0[6])  range_idx=6  #  x0[5]= -2.00000   k0[5]= 0.16638184    y0[5]= 0.1353349686   y=(x-x0[5])*k0[5]+y0[5]     
//[-1.60156  ,-1.20117)  x<x0[7]  [x0[6],x0[7])  range_idx=7  #  x0[6]= -1.60156   k0[6]= 0.24822998    y0[6]= 0.2018969059   y=(x-x0[6])*k0[6]+y0[6]     
//[-1.20117  ,-0.80078)  x<x0[8]  [x0[7],x0[8])  range_idx=8  #  x0[7]= -1.20117   k0[7]= 0.37030029    y0[7]= 0.3011939526   y=(x-x0[7])*k0[7]+y0[7]     
//[-0.80078  ,-0.40039)  x<x0[9]  [x0[8],x0[9])  range_idx=9  #  x0[8]= -0.80078   k0[8]= 0.55242920    y0[8]= 0.4493288994   y=(x-x0[8])*k0[8]+y0[8]     
//[-0.40039  , 0.00000)  x<0      [x0[9],  0  )  range_idx=10 #  x0[9]= -0.40039   k0[9]= 0.82415771    y0[9]= 0.6703199148   y=(x-x0[9])*k0[9]+y0[9]     
//
//y= k0*(x-x0)+y0
//P= B *(A +D)+C
//----------------------------------------------------------------------------------------------------------------------------------------------------
  
  
  //Q17_9
  localparam PRAM_X0_0=17'b1_1110110_010011011;//-9.69727
  localparam PRAM_X0_1=17'b1_1111010_000000000;//-6.00000
  localparam PRAM_X0_2=17'b1_1111100_000000000;//-4.00000
  localparam PRAM_X0_3=17'b1_1111101_000000000;//-3.00000
  localparam PRAM_X0_4=17'b1_1111101_100110100;//-2.40039
  localparam PRAM_X0_5=17'b1_1111110_000000000;//-2.00000
  localparam PRAM_X0_6=17'b1_1111110_011001101;//-1.60156
  localparam PRAM_X0_7=17'b1_1111110_110011010;//-1.20117
  localparam PRAM_X0_8=17'b1_1111111_001100111;//-0.80078
  localparam PRAM_X0_9=17'b1_1111111_100110100;//-0.40039
  
  //Q15_14
  localparam PRAM_K0_0=15'b0_00000000001001;//0.00061035
  localparam PRAM_K0_1=15'b0_00000010000000;//0.00787353
  localparam PRAM_K0_2=15'b0_00001000000010;//0.03143310
  localparam PRAM_K0_3=15'b0_00010001011101;//0.06817627
  localparam PRAM_K0_4=15'b0_00011100100010;//0.11151123
  localparam PRAM_K0_5=15'b0_00101010100110;//0.16638184
  localparam PRAM_K0_6=15'b0_00111111100010;//0.24822998
  localparam PRAM_K0_7=15'b0_01011110110010;//0.37030029
  localparam PRAM_K0_8=15'b0_10001101011011;//0.55242920
  localparam PRAM_K0_9=15'b0_11010010111110;//0.82415771
  
  //Q32_23
  localparam PRAM_Y0_0=32'b0_00000000_00000000000001000000111;//0.0000619888
  localparam PRAM_Y0_1=32'b0_00000000_00000000101000100111010;//0.0024789571
  localparam PRAM_Y0_2=32'b0_00000000_00000100101100000101100;//0.0183159112
  localparam PRAM_Y0_3=32'b0_00000000_00001100101111101101010;//0.0497869253
  localparam PRAM_Y0_4=32'b0_00000000_00010111001110010100100;//0.0907179117
  localparam PRAM_Y0_5=32'b0_00000000_00100010101001010101000;//0.1353349686
  localparam PRAM_Y0_6=32'b0_00000000_00110011101011111000010;//0.2018969059
  localparam PRAM_Y0_7=32'b0_00000000_01001101000110110000110;//0.3011939526
  localparam PRAM_Y0_8=32'b0_00000000_01110011000001110011100;//0.4493288994
  localparam PRAM_Y0_9=32'b0_00000000_10101011100110100001010;//0.6703199148


integer i=0,j=0;

generate for (genvar i=0; i<NUM_ELEMS; i=i+1)
begin:g
//------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------
  reg signed[DATA_WIDTH+1-1:0]r0_data_in     =0;
  reg                         r0_data_in_vld =0;
  (*dont_touch="true"*)reg[3 -1:0]compare_vld=0;
  (*dont_touch="true"*)reg[11-1:0]compare0   =0;
  (*dont_touch="true"*)reg[11-1:0]compare1   =0;
  always @(posedge clk)
  begin
      r0_data_in    <=x_data[i] ;
      r0_data_in_vld<=x_val     ;
      compare_vld   <={3{r0_data_in_vld}};
      compare0[0 ]<=$signed(r0_data_in)< $signed(PRAM_X0_0);
      compare0[1 ]<=$signed(r0_data_in)< $signed(PRAM_X0_1);
      compare0[2 ]<=$signed(r0_data_in)< $signed(PRAM_X0_2);
      compare0[3 ]<=$signed(r0_data_in)< $signed(PRAM_X0_3);
      compare0[4 ]<=$signed(r0_data_in)< $signed(PRAM_X0_4);
      compare0[5 ]<=$signed(r0_data_in)< $signed(PRAM_X0_5);
      compare0[6 ]<=$signed(r0_data_in)< $signed(PRAM_X0_6);
      compare0[7 ]<=$signed(r0_data_in)< $signed(PRAM_X0_7);
      compare0[8 ]<=$signed(r0_data_in)< $signed(PRAM_X0_8);
      compare0[9 ]<=$signed(r0_data_in)< $signed(PRAM_X0_9);
      compare0[10]<=$signed(r0_data_in)<=$signed(0        );

      compare1[0 ]<=$signed(r0_data_in)< $signed(PRAM_X0_0);
      compare1[1 ]<=$signed(r0_data_in)< $signed(PRAM_X0_1);
      compare1[2 ]<=$signed(r0_data_in)< $signed(PRAM_X0_2);
      compare1[3 ]<=$signed(r0_data_in)< $signed(PRAM_X0_3);
      compare1[4 ]<=$signed(r0_data_in)< $signed(PRAM_X0_4);
      compare1[5 ]<=$signed(r0_data_in)< $signed(PRAM_X0_5);
      compare1[6 ]<=$signed(r0_data_in)< $signed(PRAM_X0_6);
      compare1[7 ]<=$signed(r0_data_in)< $signed(PRAM_X0_7);
      compare1[8 ]<=$signed(r0_data_in)< $signed(PRAM_X0_8);
      compare1[9 ]<=$signed(r0_data_in)< $signed(PRAM_X0_9);
      compare1[10]<=$signed(r0_data_in)<=$signed(0        );
  end
//------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------
  (*dont_touch="true"*)reg  [4-1:0]  idx1=0 ;
  (*dont_touch="true"*)reg  [4-1:0]  idx2=0 ;
  (*dont_touch="true"*)reg  [4-1:0]  idx3=0 ;
  always @(posedge clk)
         if(compare_vld[0]) begin
         if(compare0[0 ]) begin idx1<=0 ;end//[  -oo ,x0[0] ) //[-oo       ,-9.69727)
    else if(compare0[1 ]) begin idx1<=1 ;end//[ x0[0],x0[1] ) //[-9.69727  ,-6.00000)
    else if(compare0[2 ]) begin idx1<=2 ;end//[ x0[1],x0[2] ) //[-6.00000  ,-4.00000)
    else if(compare0[3 ]) begin idx1<=3 ;end//[ x0[2],x0[3] ) //[-4.00000  ,-3.00000)
    else if(compare0[4 ]) begin idx1<=4 ;end//[ x0[3],x0[4] ) //[-3.00000  ,-2.40039)
    else if(compare0[5 ]) begin idx1<=5 ;end//[ x0[4],x0[5] ) //[-2.40039  ,-2.00000)
    else if(compare0[6 ]) begin idx1<=6 ;end//[ x0[5],x0[6] ) //[-2.00000  ,-1.60156) 
    else if(compare0[7 ]) begin idx1<=7 ;end//[ x0[6],x0[7] ) //[-1.60156  ,-1.20117)
    else if(compare0[8 ]) begin idx1<=8 ;end//[ x0[7],x0[8] ) //[-1.20117  ,-0.80078)
    else if(compare0[9 ]) begin idx1<=9 ;end//[ x0[8],x0[9] ) //[-0.80078  ,-0.40039)
    else if(compare0[10]) begin idx1<=10;end//[ x0[9],  0   ) //[-0.40039  , 0.00000)                    
  end else                begin idx1<=0 ;end

  always @(posedge clk)
         if(compare_vld[1]) begin
         if(compare0[0 ]) begin idx2<=0 ;end//[  -oo ,x0[0] ) //[-oo       ,-9.69727)
    else if(compare0[1 ]) begin idx2<=1 ;end//[ x0[0],x0[1] ) //[-9.69727  ,-6.00000)
    else if(compare0[2 ]) begin idx2<=2 ;end//[ x0[1],x0[2] ) //[-6.00000  ,-4.00000)
    else if(compare0[3 ]) begin idx2<=3 ;end//[ x0[2],x0[3] ) //[-4.00000  ,-3.00000)
    else if(compare0[4 ]) begin idx2<=4 ;end//[ x0[3],x0[4] ) //[-3.00000  ,-2.40039)
    else if(compare1[5 ]) begin idx2<=5 ;end//[ x0[4],x0[5] ) //[-2.40039  ,-2.00000)
    else if(compare1[6 ]) begin idx2<=6 ;end//[ x0[5],x0[6] ) //[-2.00000  ,-1.60156) 
    else if(compare1[7 ]) begin idx2<=7 ;end//[ x0[6],x0[7] ) //[-1.60156  ,-1.20117)
    else if(compare1[8 ]) begin idx2<=8 ;end//[ x0[7],x0[8] ) //[-1.20117  ,-0.80078)
    else if(compare1[9 ]) begin idx2<=9 ;end//[ x0[8],x0[9] ) //[-0.80078  ,-0.40039)
    else if(compare1[10]) begin idx2<=10;end//[ x0[9],  0   ) //[-0.40039  , 0.00000)                    
  end else                begin idx2<=0 ;end

  always @(posedge clk)
         if(compare_vld[2]) begin
         if(compare1[0 ]) begin idx3<=0 ;end//[  -oo ,x0[0] ) //[-oo       ,-9.69727)
    else if(compare1[1 ]) begin idx3<=1 ;end//[ x0[0],x0[1] ) //[-9.69727  ,-6.00000)
    else if(compare1[2 ]) begin idx3<=2 ;end//[ x0[1],x0[2] ) //[-6.00000  ,-4.00000)
    else if(compare1[3 ]) begin idx3<=3 ;end//[ x0[2],x0[3] ) //[-4.00000  ,-3.00000)
    else if(compare1[4 ]) begin idx3<=4 ;end//[ x0[3],x0[4] ) //[-3.00000  ,-2.40039)
    else if(compare1[5 ]) begin idx3<=5 ;end//[ x0[4],x0[5] ) //[-2.40039  ,-2.00000)
    else if(compare1[6 ]) begin idx3<=6 ;end//[ x0[5],x0[6] ) //[-2.00000  ,-1.60156) 
    else if(compare1[7 ]) begin idx3<=7 ;end//[ x0[6],x0[7] ) //[-1.60156  ,-1.20117)
    else if(compare1[8 ]) begin idx3<=8 ;end//[ x0[7],x0[8] ) //[-1.20117  ,-0.80078)
    else if(compare1[9 ]) begin idx3<=9 ;end//[ x0[8],x0[9] ) //[-0.80078  ,-0.40039)
    else if(compare1[10]) begin idx3<=10;end//[ x0[9],  0   ) //[-0.40039  , 0.00000)                    
  end else                begin idx3<=0 ;end

//------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------
  reg signed [DATA_WIDTH+1-1:0]sel_X0 =0;
  reg signed [DATA_WIDTH-2  :0]sel_K0 =0;
  reg signed [DATA_WIDTH*2-1:0]sel_Y0 =0;

  always @(posedge clk)
  case(idx1)
  4'd0   :sel_X0 <= 0;
  4'd1   :sel_X0 <= $signed(PRAM_X0_0)  ;
  4'd2   :sel_X0 <= $signed(PRAM_X0_1)  ;              
  4'd3   :sel_X0 <= $signed(PRAM_X0_2)  ;
  4'd4   :sel_X0 <= $signed(PRAM_X0_3)  ; 
  4'd5   :sel_X0 <= $signed(PRAM_X0_4)  ;
  4'd6   :sel_X0 <= $signed(PRAM_X0_5)  ;
  4'd7   :sel_X0 <= $signed(PRAM_X0_6)  ;
  4'd8   :sel_X0 <= $signed(PRAM_X0_7)  ;
  4'd9   :sel_X0 <= $signed(PRAM_X0_8)  ;
  4'd10  :sel_X0 <= $signed(PRAM_X0_9)  ;
  default:sel_X0 <= 0;
  endcase

  always @(posedge clk)
  case(idx2)
  4'd0   :sel_K0 <= 0;
  4'd1   :sel_K0 <= $signed(PRAM_K0_0)  ;
  4'd2   :sel_K0 <= $signed(PRAM_K0_1)  ;              
  4'd3   :sel_K0 <= $signed(PRAM_K0_2)  ;
  4'd4   :sel_K0 <= $signed(PRAM_K0_3)  ; 
  4'd5   :sel_K0 <= $signed(PRAM_K0_4)  ;
  4'd6   :sel_K0 <= $signed(PRAM_K0_5)  ;
  4'd7   :sel_K0 <= $signed(PRAM_K0_6)  ;
  4'd8   :sel_K0 <= $signed(PRAM_K0_7)  ;
  4'd9   :sel_K0 <= $signed(PRAM_K0_8)  ;
  4'd10  :sel_K0 <= $signed(PRAM_K0_9)  ;
  default:sel_K0 <= 0;
  endcase

  always @(posedge clk)
  case(idx3)
  4'd0   :sel_Y0 <= 0;
  4'd1   :sel_Y0 <= $signed(PRAM_Y0_0)  ;
  4'd2   :sel_Y0 <= $signed(PRAM_Y0_1)  ;              
  4'd3   :sel_Y0 <= $signed(PRAM_Y0_2)  ;
  4'd4   :sel_Y0 <= $signed(PRAM_Y0_3)  ; 
  4'd5   :sel_Y0 <= $signed(PRAM_Y0_4)  ;
  4'd6   :sel_Y0 <= $signed(PRAM_Y0_5)  ;
  4'd7   :sel_Y0 <= $signed(PRAM_Y0_6)  ;
  4'd8   :sel_Y0 <= $signed(PRAM_Y0_7)  ;
  4'd9   :sel_Y0 <= $signed(PRAM_Y0_8)  ;
  4'd10  :sel_Y0 <= $signed(PRAM_Y0_9)  ;
  default:sel_Y0 <= 0;
  endcase

  
  reg  [(DATA_WIDTH+1)-1:0] r1_data_in=0;
  reg  [(DATA_WIDTH+1)-1:0] r2_data_in=0;
  reg  [(DATA_WIDTH+1)-1:0] r3_data_in=0;
  always @(posedge clk)
  begin
      r1_data_in    <=  r0_data_in      ;
      r2_data_in    <=  r1_data_in      ;
      r3_data_in    <=  r2_data_in      ;
  end

//------------------------------------------------------------------------------------
// multiplicative calculation
//------------------------------------------------------------------------------------



`ifndef SIM_CODE
  always @(posedge clk)
  begin  
      A_exp_out[i]  <=  r3_data_in;
      B_exp_out[i]  <=  sel_K0    ;
      C_exp_out[i]  <=  sel_Y0    ;
      D_exp_out[i]  <= -sel_X0    ;
  end   
`else
  reg [2-1:0] vld_ctrl=0;
  always @(posedge clk)
  begin  
      vld_ctrl [0]  <=  compare_vld[0];
      vld_ctrl [1]  <=  vld_ctrl[0]   ;
      A_exp_out[i]  <= ~vld_ctrl[1]?0: r3_data_in;
      B_exp_out[i]  <= ~vld_ctrl[1]?0: sel_K0    ;
      C_exp_out[i]  <= ~vld_ctrl[1]?0: sel_Y0    ;
      D_exp_out[i]  <= ~vld_ctrl[1]?0:-sel_X0    ;
  end 
`endif
//-------------------------------------------------------------------------------------
//y_vec[i*DATA_WIDTH+:DATA_WIDTH]<={P_exp_in_r[31],P_exp_in_r[22],P_exp_in_r[21:8]};//Q32_22--->//Fix Q16_14
//-------------------------------------------------------------------------------------
  //Q32_23--->//Fix Q16_14 share mac
  reg [32-1:0] P_exp_in_r =0;
  always @(posedge clk)
  begin
       P_exp_in_r<=P_exp_in[i];
      y_data[i]<= 
      {P_exp_in_r[31],
       P_exp_in_r[23+:1 ],
       P_exp_in_r[22-:14]
      }; 
  end                                  
end
endgenerate


//--------------------------------------------------------------------------------
//
//--------------------------------------------------------------------------------

reg [2*DLY-1:0] DLY_vd=0;

always @(posedge clk)
for(i=0;i<DLY;i=i+1)
if(i==0)DLY_vd[i*2+:2]<={x_val,x_done};
else    DLY_vd[i*2+:2]<=DLY_vd[(i-1)*2+:2];


assign y_val =DLY_vd[(DLY-1)*2+1];
assign y_done=DLY_vd[(DLY-1)*2+0];


endmodule
