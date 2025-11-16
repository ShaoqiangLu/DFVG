`default_nettype none

module adder_tree #(
    parameter  
        COLUMN_WIDTH = 9,                              // \C7\E0\B7\C4 ũ\B1\E2 (9x9)
        DATA_WIDTH   = 16,                           // \C0Է\C2 \B5\A5\C0\CC\C5\CD \BA\F1Ʈ \C6\F8
        MAC_WIDTH    = DATA_WIDTH*2,                 // \C0Է\C2 \B5\A5\C0\CC\C5\CD \BA\F1Ʈ \C6\F8   
        OUT_WIDTH    = MAC_WIDTH + 4                   // \C3\E2\B7\C2 \B5\A5\C0\CC\C5\CD \BA\F1Ʈ \C6\F8
)(
    input  wire                                  clk,
    input  wire                                  reset,
    input  wire [COLUMN_WIDTH*MAC_WIDTH-1:0]     data_in,  
    output reg  [OUT_WIDTH-1:0]                  sum_out          
);

    // --------------------------
    // \B7\B9\BA\A7 1: 2\B0\B3\BE\BF \B4\F5\C7ϱ\E2
    // --------------------------
    wire signed [33:0] level1 [0:3];  // 32+1\BA\F1Ʈ \BF\A9\C0\AF
    assign level1[0] = $signed(data_in[31:0])   + $signed(data_in[63:32]);
    assign level1[1] = $signed(data_in[95:64])  + $signed(data_in[127:96]);
    assign level1[2] = $signed(data_in[159:128])+ $signed(data_in[191:160]);
    assign level1[3] = $signed(data_in[223:192])+ $signed(data_in[255:224]);
    wire signed [31:0] leftover = $signed(data_in[287:256]); // \B8\B6\C1\F6\B8\B7 \C7ϳ\AA

    // --------------------------
    // \B7\B9\BA\A7 2: \C6\C4\C0\CC\C7\C1\B6\F3\C0̴\D7
    // --------------------------
    wire signed [34:0] level2 [0:1];
    assign level2[0] = level1[0] + level1[1];
    assign level2[1] = level1[2] + level1[3];

    // --------------------------
    // \B7\B9\BA\A7 3: \C3\D6\C1\BE \C7\D5
    // --------------------------
    always @(posedge clk or negedge reset) begin
        if(!reset)
            sum_out <= 0;
        else
            sum_out <= level2[0] + level2[1] + leftover;
    end

endmodule
