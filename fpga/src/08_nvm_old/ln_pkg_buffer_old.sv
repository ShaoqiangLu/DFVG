module ln_pkg_buffer_old # (
    parameter DATA_WIDTH  = 16,
    parameter NUM_ELEMS   = 8,
    parameter RAM_DEEP = 8
) (
    input  logic                                 clk,
    input  logic                                 rst,
    input  logic                [5:0]            nvm_rstep,
    output logic                                 pkg_in_rdy     ,
    input  logic [NUM_ELEMS-1:0][DATA_WIDTH-1:0] pkg_in_data    ,
    input  logic                                 pkg_in_val     ,
    input  logic                                 pkg_in_done    ,
    
    input  logic                                 pkg_out_rdy    ,
    output logic [NUM_ELEMS-1:0][DATA_WIDTH-1:0] pkg_out_data   ,
    output logic                                 pkg_out_val    ,
    output logic                                 pkg_out_done
);

    //-------------------------------------------------------------
    // Current read index threshold (current output pkg length)
    // Whether current rd_idx_hold is valid              
    // Indices for read and write 
    // Thresholds for read and write indices
    //-------------------------------------------------------------
    localparam CNT_WIDTH                   = $clog2(RAM_DEEP)    ;
    logic [NUM_ELEMS-1:0][DATA_WIDTH-1:0]  BUFFER_MEM[RAM_DEEP]  ;
    logic [CNT_WIDTH-1:0]                  wr_idx;
    logic [CNT_WIDTH-1:0]                  idx_hold; 
    logic [CNT_WIDTH-1:0]                  rd_idx;
    logic                                  rd_idx_val;  
    logic                                  rd_idx_done;

    //-------------------------------------------------------------
    // Assignments and Always Blocks
    // Only invalid if write loops around and catches up to read
    // If read idx == write idx, then we are waiting on more writes (not val)       
    // Except when rd_idx_val == 1, then write has caught up to read (val)
    //-------------------------------------------------------------


    //assign pkg_in_rdy  =(!rd_idx_val&& !pkg_in_val)||(!pkg_in_done&& pkg_in_val);
    assign pkg_in_rdy  = !pkg_in_val;


always @(posedge clk)
if (rst)begin
        for (int i=0;i<RAM_DEEP;i++)BUFFER_MEM[i]<=0;
        wr_idx                <= 0;
        rd_idx                <= 0;
        idx_hold              <= 0;
        rd_idx_val            <= 0;
        pkg_out_val           <= 0;
        pkg_out_data          <= 0;
        pkg_out_done          <= 0;
end
else begin

//-------------------------------------------------------------------
// Write transaction logic
// If package done, set rd threshold and reset wr_idx
// Increment write index
            if (pkg_in_val)
            begin
                if (pkg_in_done) 
                begin
                     wr_idx         <= 0;
                     idx_hold       <= wr_idx;
                     rd_idx_val     <= 1'b1;  
                end
                else wr_idx         <= wr_idx + 1;
                BUFFER_MEM[wr_idx]  <= pkg_in_data;
            end


//-----------------------------------------------------------------------
// Read transaction logic
// If package done, reset threshold val and reset rd_idx
// Note: may be overwritten by write transaction
// Increment read index
// (rd_idx != wr_idx) | rd_idx_threshold_val;
            if (pkg_out_rdy)
            begin
                if (rd_idx_done) 
                begin
                     rd_idx_val <= 0; 
                     rd_idx     <= 0;
                     idx_hold   <= 0;
                end
                else rd_idx <= rd_idx + 1;

                pkg_out_val  <= pkg_out_rdy         ;
                pkg_out_data <= BUFFER_MEM[rd_idx]  ;
                pkg_out_done <= rd_idx_done         ;
            end
            else begin
                if(pkg_in_done)rd_idx<=0;
                pkg_out_val  <= 0;
                pkg_out_data <= 0;
                pkg_out_done <= 0;
            end



end

assign rd_idx_done=(rd_idx == idx_hold) & rd_idx_val;




//    always @(posedge clk) 
//    begin
//        pkg_out_val  <= pkg_out_rdy       ;//(rd_idx != wr_idx) | rd_idx_threshold_val;
//        pkg_out_data <= BUFFER_MEM[rd_idx];
//        pkg_out_done <= (rd_idx == rd_idx_threshold) & rd_idx_threshold_val;
//    end



endmodule
