`default_nettype none

module meissa_column #(
    parameter
        ROW_WIDTH    = 8,
        COLUMN_WIDTH = 9,
        DATA_WIDTH   = 16,
        MAC_WIDTH    = DATA_WIDTH*2
)(
    input  wire                                  clk,
    input  wire                                  reset,
    input  wire [DATA_WIDTH*COLUMN_WIDTH-1:0]    datain,
    input  wire [DATA_WIDTH*COLUMN_WIDTH-1:0]    weight,
           
    output wire [MAC_WIDTH*COLUMN_WIDTH-1:0]     maccout
);

    genvar i;
    generate begin : COLUMN_PE
        for (i = 0; i < COLUMN_WIDTH; i = i + 1) begin : PE_CELL
            if (i == 0) begin 
                meissa_pe #(
                    .ROW_WIDTH        (ROW_WIDTH),
                    .DATA_WIDTH       (DATA_WIDTH),
                    .MAC_WIDTH        (MAC_WIDTH)  
                ) meissa_pe (
                    .clk              (clk),
                    .reset            (reset),
                    .datain           (datain[DATA_WIDTH-1:0]),
                    .weight           (weight[DATA_WIDTH-1:0]),
                    .maccout          (maccout[MAC_WIDTH-1:0])
                    );
            end
            else begin
                meissa_pe #(
                    .ROW_WIDTH        (ROW_WIDTH),
                    .DATA_WIDTH       (DATA_WIDTH),
                    .MAC_WIDTH        (MAC_WIDTH)
                ) meissa_pe (
                    .clk              (clk),
                    .reset            (reset),
                    .datain           (datain[DATA_WIDTH*(i+1)-1:DATA_WIDTH*i]),
                    .weight           (weight[DATA_WIDTH*(i+1)-1:DATA_WIDTH*i]),
                    .maccout          (maccout[MAC_WIDTH*(i+1)-1:MAC_WIDTH*i])
                );
            end
        end
    end
    endgenerate
    
endmodule