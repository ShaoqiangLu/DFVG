`default_nettype none

module parallel_meissa #(
    parameter 
        DATA_WIDTH   = 16,
        ROW_WIDTH    = 10,
        COLUMN_WIDTH = 9,
        MAC_WIDTH    = DATA_WIDTH + DATA_WIDTH
)(
    input wire                                            clk,
    input wire                                            reset,
    input wire                                            start,
    
    input wire [DATA_WIDTH*COLUMN_WIDTH - 1:0]            datain,
    input wire [DATA_WIDTH*ROW_WIDTH*COLUMN_WIDTH - 1:0]  weightin,
    
    output wire [MAC_WIDTH*ROW_WIDTH*COLUMN_WIDTH - 1:0]  maccout
);

    genvar i;
    generate begin : Column_generate
        for (i=0; i < ROW_WIDTH; i = i+1) begin :COLUMN_CELL
            if (i==0) begin
                meissa_column #(
                    .ROW_WIDTH     (ROW_WIDTH),
                    .COLUMN_WIDTH  (COLUMN_WIDTH),
                    .DATA_WIDTH    (DATA_WIDTH),
                    .MAC_WIDTH     (MAC_WIDTH)
                ) meissa_column (
                    .clk           (clk),
                    .reset         (reset),
                    .datain        (datain),
                    .weight        (weightin[DATA_WIDTH*COLUMN_WIDTH-1:0]),
                    .maccout       (maccout[MAC_WIDTH*COLUMN_WIDTH-1:0])
                );
            end 
            else begin
                meissa_column #(
                    .ROW_WIDTH     (ROW_WIDTH),
                    .COLUMN_WIDTH  (COLUMN_WIDTH),
                    .DATA_WIDTH    (DATA_WIDTH),
                    .MAC_WIDTH     (MAC_WIDTH)
                ) meissa_column (
                    .clk           (clk),
                    .reset         (reset),
                    .datain        (datain),
                    .weight        (weightin[DATA_WIDTH*COLUMN_WIDTH*(i+1)-1:DATA_WIDTH*COLUMN_WIDTH*i]),
                    .maccout       (maccout[MAC_WIDTH*COLUMN_WIDTH*(i+1)-1:MAC_WIDTH*COLUMN_WIDTH*i])
                );
            end
        end
    end
endgenerate


endmodule
