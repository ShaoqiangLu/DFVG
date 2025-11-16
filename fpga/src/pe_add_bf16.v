`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/05/08 19:07:10
// Design Name: 
// Module Name: add_bf16
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

//--------------------------------------------------------
// 7 cycle ,LUT= ,FF=
//--------------------------------------------------------
module pe_add_bf16 # (
    parameter    IN_WIDTH  = 16,
    localparam   OUT_WIDTH = IN_WIDTH   
)
(
	input         clk,
	input [IN_WIDTH-1:0]  x1,
	input [IN_WIDTH-1:0]  x2,

	output reg [OUT_WIDTH-1:0]  y=0
);
//-------------------------------------------------------
//cycle 1
//-------------------------------------------------------

reg                                         x1_equaled_x2   =0  ;
reg                                         x1_greater_x2   =0  ;
reg                                         x1_smaller_x2   =0  ;
reg     [7:0]                               x1_sub_x2       =0  ;
reg     [7:0]                               x2_sub_x1       =0  ;
reg                                         x1_15           =0  ;
reg                                         x2_15           =0  ;
always @(posedge clk)
begin
    x1_equaled_x2   <=x1[14:7] == x2[14:7]                      ;
    x1_greater_x2   <=x1[14:7] >  x2[14:7]                      ;
    x1_smaller_x2   <=x1[14:7] <  x2[14:7]                      ;
    x1_sub_x2       <=x1[14:7] -  x2[14:7]                      ;
    x2_sub_x1       <=x2[14:7] -  x1[14:7]                      ;
    x1_15           <=x1[15]                                    ;
    x2_15           <=x2[15]                                    ;
end


reg         [IN_WIDTH-1:0]           r_x1=0;
reg         [IN_WIDTH-1:0]           r_x2=0;
reg                                  state_0=0;
reg  signed         [ 9:0]           expo_x1_0=0;
reg  signed         [ 9:0]           expo_x2_0=0;
reg                 [ 9:0]           mant_x1_0=0;
reg                 [ 9:0]           mant_x2_0=0;

always @(posedge clk) r_x1 <= x1;
always @(posedge clk) r_x2 <= x2;
always @(posedge clk) state_0   <= (x1[14:7] == 8'hff) | (x2[14:7] == 8'hff);
always @(posedge clk) expo_x1_0 <= (x1[14:7] == 8'h00) ? -127 : (x1[14:7] - 127);
always @(posedge clk) expo_x2_0 <= (x2[14:7] == 8'h00) ? -127 : (x2[14:7] - 127);
always @(posedge clk) mant_x1_0 <= (x1[14:7] == 8'h00) ? {1'b0, x1[6:0], 2'b0} : {2'b01, x1[6:0], 1'b0};
always @(posedge clk) mant_x2_0 <= (x2[14:7] == 8'h00) ? {1'b0, x2[6:0], 2'b0} : {2'b01, x2[6:0], 1'b0};


//-------------------------------------------------------
//cycle 2
//-------------------------------------------------------
reg         [ 9:0] mant_max_1=0;
reg signed  [ 9:0] expo_max_1=0;
reg                sign_max_1=0;

reg         [ 9:0] mant_min_1=0;
reg                sign_min_1=0;
reg                state_1=0;

always @(posedge clk)begin

    if (x1_equaled_x2)begin
		state_1 <= state_0;
		if (mant_x1_0 > mant_x2_0)begin
			mant_max_1 <= mant_x1_0;
			expo_max_1 <= expo_x1_0;
			sign_max_1 <= x1_15;

			mant_min_1 <= mant_x2_0;
			sign_min_1 <= x2_15;
		end
		else begin
			mant_max_1 <= mant_x2_0;
			expo_max_1 <= expo_x2_0;
			sign_max_1 <= x2_15;

			mant_min_1 <= mant_x1_0;
			sign_min_1 <= x1_15;
		end
	end
	else if (x1_greater_x2)begin
		state_1 <= state_0;

		mant_max_1 <= mant_x1_0;
		expo_max_1 <= expo_x1_0;
		sign_max_1 <= x1_15;

		mant_min_1 <= mant_x2_0 >> (x1_sub_x2);
		sign_min_1 <= x2_15;
	end
	else if(x1_smaller_x2)begin
		state_1 <= state_0;

		mant_max_1 <= mant_x2_0;
		expo_max_1 <= expo_x2_0;
		sign_max_1 <= x2_15;

		mant_min_1 <= mant_x1_0 >>(x2_sub_x1);
		sign_min_1 <= x1_15;
	end

end


//-------------------------------------------------------
//cycle 3
//-------------------------------------------------------
reg         [ 9:0] mant_2=0;
reg signed  [ 9:0] expo_2=0;
reg                sign_2=0;
reg                state_2=0;

always @(posedge clk)begin


	if (sign_max_1 == sign_min_1)begin
		mant_2  <= mant_max_1 + mant_min_1;
		expo_2  <= expo_max_1;
		sign_2  <= sign_max_1;
		state_2 <= state_1;
	end
	else begin
		mant_2  <= mant_max_1 - mant_min_1;
		expo_2  <= expo_max_1;
		sign_2  <= sign_max_1;
		state_2 <= state_1;
	end

end


//-------------------------------------------------------
//cycle 4
//-------------------------------------------------------
reg         [ 9:0] mant_3=0;
reg signed  [ 9:0] expo_3=0;
reg                sign_3=0;
reg                state_3=0;

always @(posedge clk)begin


	if (mant_2[9:5]!= 5'h0)begin
		mant_3 <= mant_2;
		expo_3 <= expo_2;
		sign_3 <= sign_2;
		state_3 <= state_2;
	end
	else if (mant_2[4:0]!= 5'h0)begin
		mant_3 <= mant_2 << 5;///13
		expo_3 <= expo_2 - 5;///13
		sign_3 <= sign_2;
		state_3 <= state_2;
	end
	else begin
		mant_3 <= 10'h0;
		expo_3 <= 0;
		sign_3 <= 0;
		state_3 <= state_2;
	end

end


//-------------------------------------------------------
//cycle 5
//-------------------------------------------------------
reg         [ 9:0] mant_4=0;
reg signed  [ 9:0] expo_4=0;
reg                sign_4=0;
reg                state_4=0;

always @(posedge clk)begin


	if (mant_3[9])begin
		mant_4  <= mant_3 >> 1;
		expo_4  <= expo_3 + 1;
		sign_4  <= sign_3;
		state_4 <= state_3;
	end
	else if (mant_3[8])begin
		mant_4  <= mant_3;
		expo_4  <= expo_3;
		sign_4  <= sign_3;
		state_4 <= state_3;
	end
	else if (mant_3[7])begin
		mant_4  <= mant_3 << 1;
		expo_4  <= expo_3 - 1;
		sign_4  <= sign_3;
		state_4 <= state_3;
	end
	else if (mant_3[6])begin
		mant_4  <= mant_3 << 2;
		expo_4  <= expo_3 - 2;
		sign_4  <= sign_3;
		state_4 <= state_3;
	end
	else if (mant_3[5])begin
		mant_4  <= mant_3 << 3;
		expo_4  <= expo_3 - 3;
		sign_4  <= sign_3;
		state_4 <= state_3;
	end
	else begin
		mant_4  <= mant_3;
		expo_4  <= -127;
		sign_4  <= sign_3;
		state_4 <= state_3;
	end

end


//-------------------------------------------------------
//cycle 6
//-------------------------------------------------------
reg         [ 9:0] mant_5=0;
reg signed  [ 9:0] expo_5=0;
reg                sign_5=0;

always @(posedge clk)begin

	if (state_4)begin
		expo_5 <= 8'b11111111;
		mant_5 <= 10'h0;
		sign_5 <= sign_4;
	end
	else if (expo_4 > 127)begin
		expo_5 <= 8'b11111111;
		mant_5 <= 10'h0;
		sign_5 <= sign_4;
	end
	else if (expo_4 < -126)begin
		expo_5 <= 9'h0;
		mant_5 <= mant_4 >> (-126 - expo_4);///?
		sign_5 <= sign_4;
	end
	else begin
		expo_5 <= expo_4 + 127;
		mant_5 <= mant_4;
		sign_5 <= sign_4;
	end
end


//-------------------------------------------------------
//cycle 7
//-------------------------------------------------------
always @(posedge clk)begin
    y[15]   <= sign_5;
    y[14:7] <= expo_5[7:0];
    y[6:0]  <= mant_5[7:1];
end




endmodule


