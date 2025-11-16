`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/05/08 19:07:10
// Design Name: 
// Module Name: add_fp32
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


module pe_add_fp32 # (
    parameter    IN_WIDTH  = 32,
    localparam   OUT_WIDTH = IN_WIDTH   
)
(
	input         clk,
	input [IN_WIDTH-1:0]  x1,
	input [IN_WIDTH-1:0]  x2,

	output [OUT_WIDTH-1:0]  y
);
/********0********/


reg         [IN_WIDTH-1:0]           r_x1=0;
reg         [IN_WIDTH-1:0]           r_x2=0;
reg                                  state_0=0;
reg  signed         [ 9:0]           expo_x1_0=0;
reg  signed         [ 9:0]           expo_x2_0=0;
reg                 [25:0]           mant_x1_0=0;
reg                 [25:0]           mant_x2_0=0;


always @(posedge clk) r_x1 <= x1;
always @(posedge clk) r_x2 <= x2;
always @(posedge clk) state_0 <= (x1[30:23] == 8'hff) | (x2[30:23] == 8'hff);
always @(posedge clk) expo_x1_0 <= (x1[30:23] == 8'h00) ? -127 : (x1[30:23] - 127);
always @(posedge clk) expo_x2_0 <= (x2[30:23] == 8'h00) ? -127 : (x2[30:23] - 127);
always @(posedge clk) mant_x1_0 <= (x1[30:23] == 8'h00) ? {1'b0, x1[22:0], 2'b0} : {2'b01, x1[22:0], 1'b0};
always @(posedge clk) mant_x2_0 <= (x2[30:23] == 8'h00) ? {1'b0, x2[22:0], 2'b0} : {2'b01, x2[22:0], 1'b0};

/********1********/
reg         [25:0] mant_max_1=0;
reg signed  [ 9:0] expo_max_1=0;
reg                sign_max_1=0;

reg         [25:0] mant_min_1=0;
reg                sign_min_1=0;
reg                state_1=0;

always @(posedge clk)begin

	if (r_x1[30:23] == r_x2[30:23])begin
		state_1 <= state_0;
		if (mant_x1_0 > mant_x2_0)begin
			mant_max_1 <= mant_x1_0;
			expo_max_1 <= expo_x1_0;
			sign_max_1 <= r_x1[31];

			mant_min_1 <= mant_x2_0;
			sign_min_1 <= r_x2[31];
		end
		else begin
			mant_max_1 <= mant_x2_0;
			expo_max_1 <= expo_x2_0;
			sign_max_1 <= r_x2[31];

			mant_min_1 <= mant_x1_0;
			sign_min_1 <= r_x1[31];
		end
	end
	else if (r_x1[30:23] > r_x2[30:23])begin
		state_1 <= state_0;

		mant_max_1 <= mant_x1_0;
		expo_max_1 <= expo_x1_0;
		sign_max_1 <= r_x1[31];

		mant_min_1 <= mant_x2_0 >> (r_x1[30:23]-r_x2[30:23]);
		sign_min_1 <= r_x2[31];
	end
	else begin
		state_1 <= state_0;

		mant_max_1 <= mant_x2_0;
		expo_max_1 <= expo_x2_0;
		sign_max_1 <= r_x2[31];

		mant_min_1 <= mant_x1_0 >>(r_x2[30:23]-r_x1[30:23]);
		sign_min_1 <= r_x1[31];
	end

end


/********2********/
reg         [25:0] mant_2=0;
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


/********3********/
reg         [25:0] mant_3=0;
reg signed  [ 9:0] expo_3=0;
reg                sign_3=0;
reg                state_3=0;

always @(posedge clk)begin


	if (mant_2[25:13]!= 13'h0)begin
		mant_3 <= mant_2;
		expo_3 <= expo_2;
		sign_3 <= sign_2;
		state_3 <= state_2;
	end
	else if (mant_2[12:0]!= 13'h0)begin
		mant_3 <= mant_2 << 13;
		expo_3 <= expo_2 - 13;
		sign_3 <= sign_2;
		state_3 <= state_2;
	end
	else begin
		mant_3 <= 26'h0;
		expo_3 <= 0;
		sign_3 <= 0;
		state_3 <= state_2;
	end

end


/********4********/
reg         [25:0] mant_4=0;
reg signed  [ 9:0] expo_4=0;
reg                sign_4=0;
reg                state_4=0;

always @(posedge clk)begin


	if (mant_3[25])begin
		mant_4  <= mant_3 >> 1;
		expo_4  <= expo_3 + 1;
		sign_4  <= sign_3;
		state_4 <= state_3;
	end
	else if (mant_3[24])begin
		mant_4  <= mant_3;
		expo_4  <= expo_3;
		sign_4  <= sign_3;
		state_4 <= state_3;
	end
	else if (mant_3[23])begin
		mant_4  <= mant_3 << 1;
		expo_4  <= expo_3 - 1;
		sign_4  <= sign_3;
		state_4 <= state_3;
	end
	else if (mant_3[22])begin
		mant_4  <= mant_3 << 2;
		expo_4  <= expo_3 - 2;
		sign_4  <= sign_3;
		state_4 <= state_3;
	end
	else if (mant_3[21])begin
		mant_4  <= mant_3 << 3;
		expo_4  <= expo_3 - 3;
		sign_4  <= sign_3;
		state_4 <= state_3;
	end
	else if (mant_3[20])begin
		mant_4  <= mant_3 << 4;
		expo_4  <= expo_3 - 4;
		sign_4  <= sign_3;
		state_4 <= state_3;
	end
	else if (mant_3[19])begin
		mant_4  <= mant_3 << 5;
		expo_4  <= expo_3 - 5;
		sign_4  <= sign_3;
		state_4 <= state_3;
	end
	else if (mant_3[18])begin
		mant_4  <= mant_3 << 6;
		expo_4  <= expo_3 - 6;
		sign_4  <= sign_3;
		state_4 <= state_3;
	end
	else if (mant_3[17])begin
		mant_4  <= mant_3 << 7;
		expo_4  <= expo_3 - 7;
		sign_4  <= sign_3;
		state_4 <= state_3;
	end
	else if (mant_3[16])begin
		mant_4  <= mant_3 << 8;
		expo_4  <= expo_3 - 8;
		sign_4  <= sign_3;
		state_4 <= state_3;
	end
	else if (mant_3[15])begin
		mant_4  <= mant_3 << 9;
		expo_4  <= expo_3 - 9;
		sign_4  <= sign_3;
		state_4 <= state_3;
	end
	else if (mant_3[14])begin
		mant_4  <= mant_3 << 10;
		expo_4  <= expo_3 - 10;
		sign_4  <= sign_3;
		state_4 <= state_3;
	end
	else if (mant_3[13])begin
		mant_4  <= mant_3 << 11;
		expo_4  <= expo_3 - 11;
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


/********5********/
reg         [25:0] mant_5=0;
reg signed  [ 9:0] expo_5=0;
reg                sign_5=0;
assign y[31] = sign_5;
assign y[30:23] = expo_5[7:0];
assign y[22:0] = mant_5[23:1];

always @(posedge clk)begin
 
	if (state_4)begin
		expo_5 <= 8'b11111111;
		mant_5 <= 26'h0;
		sign_5 <= sign_4;
	end
	else if (expo_4 > 127)begin
		expo_5 <= 8'b11111111;
		mant_5 <= 26'h0;
		sign_5 <= sign_4;
	end
	else if (expo_4 < -126)begin
		expo_5 <= 9'h0;
		mant_5 <= mant_4 >> (-126 - expo_4);
		sign_5 <= sign_4;
	end
	else begin
		expo_5 <= expo_4 + 127;
		mant_5 <= mant_4;
		sign_5 <= sign_4;
	end
end

endmodule


