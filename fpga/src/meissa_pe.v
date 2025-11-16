`default_nettype none

module meissa_pe#(
    parameter
        ROW_WIDTH    = 9,
        DATA_WIDTH   = 16,
        MAC_WIDTH    = DATA_WIDTH*2
)(
    input wire                      clk,
    input wire                      reset,
    input wire [DATA_WIDTH-1:0]     datain,
    input wire [DATA_WIDTH-1:0]     weight,
    
    output reg [MAC_WIDTH-1:0]      maccout
);

    wire [MAC_WIDTH-1:0]result_mult;
    
    mult #(
        .ROW_WIDTH        (ROW_WIDTH),
        .DATA_WIDTH       (DATA_WIDTH),
        .MAC_WIDTH        (MAC_WIDTH)  
    ) mult (
        .multiplicand     (datain),
        .multiplier       (weight), 
        .op               (result_mult)
    );
    
    always@(posedge clk or negedge reset)begin
        if(!reset)begin
            maccout <= 0;
        end
        else begin
            maccout <= result_mult;
        end
    end
    
endmodule