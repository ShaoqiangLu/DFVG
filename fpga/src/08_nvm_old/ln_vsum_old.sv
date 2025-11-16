// This module recursively generates an adder tree with full-precision bit growth
// Note: we assume here that the number of elements is a power of 2

module ln_vsum_old # (
    parameter  IN_WIDTH  = 16,
    parameter  NUM_ELEMS = 2,
    localparam OUT_WIDTH = IN_WIDTH + $clog2(NUM_ELEMS)
) ( input                                      clk     ,
    input  logic [NUM_ELEMS-1:0][IN_WIDTH-1:0] data_in ,
    output logic [OUT_WIDTH-1:0]               data_out
);
    logic [OUT_WIDTH-2:0] sum_left;  // 1 bit narrower that sum
    logic [OUT_WIDTH-2:0] sum_right;
    
    generate

        if (NUM_ELEMS == 2) // Recursive base case (2-element addition)
        begin
            assign sum_left  = data_in[0];
            assign sum_right = data_in[1];
        end
        else // Generate two sub-adder trees
        begin
            // Left half adder tree
            ln_vsum_old #(
                .IN_WIDTH (IN_WIDTH),
                .NUM_ELEMS(NUM_ELEMS/2)
            ) va0 (
                .clk        (clk),
                .data_in    (data_in[NUM_ELEMS-1:NUM_ELEMS/2]),
                .data_out   (sum_left)
            );

            // Right half adder tree
            ln_vsum_old #(
                .IN_WIDTH (IN_WIDTH),
                .NUM_ELEMS(NUM_ELEMS/2)
            ) va1 (
                .clk        (clk),
                .data_in    (data_in[NUM_ELEMS/2-1:0]),
                .data_out   (sum_right)
            );
        end

    endgenerate
    
    

    generate 
        if (NUM_ELEMS ==32 || NUM_ELEMS ==8|| NUM_ELEMS ==2) begin:gen_Pipe
        wire  [OUT_WIDTH-1:0] sum_pi;
        reg   [OUT_WIDTH-1:0] sum_po=0;
        assign sum_pi= {sum_left[OUT_WIDTH-2], sum_left} + {sum_right[OUT_WIDTH-2], sum_right}; // add with 1-bit sign extension
        
            always @(posedge clk)sum_po <= sum_pi;
            assign data_out=sum_po;
            
        end else begin:gen_noPipe
            assign data_out= {sum_left[OUT_WIDTH-2], sum_left} + {sum_right[OUT_WIDTH-2], sum_right}; // add with 1-bit sign extension
        end
    endgenerate
     
 





endmodule
