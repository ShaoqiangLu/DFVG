`default_nettype none

module adder_tree_array #(
    parameter 
        ROW_WIDTH     = 10,   
        COLUMN_WIDTH  = 9,
        DATA_WIDTH    = 16,  
        MAC_WIDTH     = DATA_WIDTH*2,    
        OUT_WIDTH     = MAC_WIDTH + 4
)(
    input  wire                                         clk,
    input  wire                                         reset,
    input  wire [ROW_WIDTH*COLUMN_WIDTH*MAC_WIDTH-1:0]  maccout,  
    output wire [ROW_WIDTH*OUT_WIDTH-1:0]               result        
);

    wire [OUT_WIDTH-1:0] column_sum [0:ROW_WIDTH-1];

    genvar i;
    generate
        for (i = 0; i < ROW_WIDTH; i = i + 1) begin : gen_columns
            // column-major\B7\CE \B5\E9\BE\EE\BF\D4\C0\B8\B9Ƿ\CE, i\B9\F8° column\C0\BA \B1׳\C9 \BD\BD\B6\F3\C0̽\BA\B7\CE \C0߶\F3\BC\AD adder_tree\BF\A1 \B3\D6\C0\B8\B8\E9 \B5\CA
            adder_tree #(
                .MAC_WIDTH      (MAC_WIDTH),
                .COLUMN_WIDTH   (COLUMN_WIDTH),   // \C7\D1 column \BE\C8\C0\C7 \BF\F8\BC\D2 \B0\B3\BC\F6
                .OUT_WIDTH      (OUT_WIDTH)
            ) adder_tree_inst (
                .clk            (clk),
                .reset          (reset),
                .data_in        (maccout[MAC_WIDTH*COLUMN_WIDTH*(i+1)-1 -: MAC_WIDTH*COLUMN_WIDTH]),
                .sum_out        (column_sum[i])
            );

            // \B0\E1\B0\FA \B9\AD\B1\E2
            assign result[OUT_WIDTH*(i+1)-1 : OUT_WIDTH*i] = column_sum[i];
        end
    endgenerate

endmodule