`default_nettype none

module mult#(
    parameter
        ROW_WIDTH    = 9,
        DATA_WIDTH   = 16,
        MAC_WIDTH    = DATA_WIDTH*2
)(
    input  wire  signed  [DATA_WIDTH   - 1:0]   multiplicand, 
    input  wire  signed  [DATA_WIDTH - 1:0]     multiplier,
    output wire  signed  [MAC_WIDTH - 1:0]      op
);

    assign op = multiplicand * multiplier;

endmodule