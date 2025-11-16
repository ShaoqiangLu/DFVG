// Whether data is transferred (on which we accumulate)
// Delete BG for reducing resource
module ln_mean_old #(
    parameter DATA_WIDTH  = 16,
    parameter NUM_ELEMS   = 32,
    parameter DIV_MEAN_DLY= 16
)(
    input  logic                                  clk           ,
    input  logic                                  rst           ,
    input  logic                                  nvm_rstep     ,
    input  logic [NUM_ELEMS-1:0][DATA_WIDTH-1:0]  mean_in_data  ,
    input  logic                                  mean_in_vld   , 
    input  logic                                  mean_in_done  ,
    output logic [DATA_WIDTH-1:0]                 mean_out_data ,
    output logic                                  mean_out_vld  ,
    output logic                                  mean_out_done ,
    output logic                                  mean_out_frist,
    output wire         [63:0]                    sum_tx          ,
    input  wire         [63:0]                    sum_rx    
);

    //-------------------------------------------------------------------
    // bit width for a single cycle's data sum
    // Current sum for elements (not accumulated for full package)
    //-------------------------------------------------------------------
    localparam SUM_WIDTH = DATA_WIDTH+$clog2(NUM_ELEMS);  
    logic [SUM_WIDTH-1:0]  sum_current_data            ; 
    logic                  sum_current_vld             ;
    logic                  sum_current_vld_r           ;
    logic                  sum_current_done            ;
    logic                  sum_current_frist           ;

    ln_vsum_old # (
        .IN_WIDTH   (DATA_WIDTH                       ),
        .NUM_ELEMS  (NUM_ELEMS                        )
    ) U_SUM_old(
        .clk        (clk                              ),
        .data_in    (mean_in_data                     ),
        .data_out   (sum_current_data                 )
    );

    dly_cell #(
      .DLY          (3                                ),
      .DW           (2                                )
    ) U_dly_svd(
      .dout         ({sum_current_vld,sum_current_done}),
      .din          ({mean_in_vld,mean_in_done }      ),
      .clk          (clk                              ),
      .reset        (rst                              )
    );

    always_ff @(posedge clk)sum_current_vld_r<= sum_current_vld   ;
    assign sum_current_frist=sum_current_vld&&(~sum_current_vld_r);


    //-------------------------------------------------------------
    // Accumulator with bit growth           
    // Counter for current sum package length
    // make sure data width is enough for not overflow
    // Combinational sum of accumulator + sum
    // Next state of sum_pkg_len  
    // Input transaction (accumulate sum)
    // Reset accumulator and pkg len, and set mean
    // Accumulate (and increment sum_pkg_len for mean)          
    //-------------------------------------------------------------
    localparam DW_multi =64;
    logic [DW_multi-1:0]        sum_result_data     ; 
    logic                       sum_result_vld      ;
    logic                       sum_result_done     ;
    logic                       sum_result_frist    ;
    logic [15:0]                sum_pkg_len         ; 

    always_ff @(posedge clk)
    if(rst)begin
            sum_result_data     <= 0;
            sum_pkg_len         <= 0;
    end else
    if(sum_current_vld) 
    begin
            if (sum_current_frist) 
            begin
                sum_result_data <= sum_current_data;
                sum_pkg_len     <= NUM_ELEMS       ;
            end 
            else 
            begin
                sum_result_data <= $signed(sum_result_data) + $signed(sum_current_data);
                sum_pkg_len     <= sum_pkg_len + NUM_ELEMS;
            end
    end

  (*keep_hierarchy="yes"*)dly_cnt #(
    .DW                  ( 3                                        ),
    .Deep                ( 64                                       )
  ) cnt_sum_multi_vd(
      .dout              ({sum_result_vld ,
                           sum_result_done ,
                           sum_result_frist}),
      .din               ({sum_current_vld,
                           sum_current_done,
                           sum_current_frist}),
    .cnt                 ( nvm_rstep                                ),
    .clk                 ( clk                                      ),
    .reset               ( 1'b0                                     )
  );


    logic [DW_multi-1:0]mean_dividend                     ;
    logic [15 : 0]      mean_divisor                      ;
    logic [79 : 0]      mean_result                       ;

  reg sync_util =0;
`include "core_param.vh"
`ifdef DEBUG_CORE1//--------------------------------------------------
    //------------------------------------------------------------------------------------
    // Add acc + sign extended sum combinationally (for next state logic)
    // Mean calculation from sum - we add BG bits since we divide by BG-bit package length
    // Use IP to include more cases
    // Divisor 12 bits, at most 4095, unsigned
    //------------------------------------------------------------------------------------
    assign                  sum_tx=0    ;
    always_ff @(posedge clk)sync_util<=0;
    assign    mean_dividend = $signed  (sum_result_data);
    assign    mean_divisor  = $unsigned(sum_pkg_len)    ;
    dly_cell #(
      .DLY          (DIV_MEAN_DLY+1                   ),
      .DW           (3                                )
    ) U_dly_divd(
      .dout({mean_out_vld  ,mean_out_done  ,mean_out_frist   }),
      .din ({sum_result_vld,sum_result_done,sum_result_frist }),
      .clk          (clk                               ),
      .reset        (1'b0                              )
    );

`elsif DEBUG_CORE2//--------------------------------------------------
`ifdef ROUTER
  localparam  SYNC_Mean_DLY =10;
  assign      sum_tx=sum_result_data                                 ;
  wire   [16-1:0]   sum_pkg_len_sync                                 ;
  (*keep_hierarchy="yes"*)dly_cell #(
     .DLY                 (  SYNC_Mean_DLY                           ),
     .DW                  (  16                                      )
  ) dly_mean_len(
     .dout                ( sum_pkg_len_sync                         ),
     .din                 ( sum_pkg_len+sum_pkg_len                  ),
     .clk                 ( clk                                      ),
     .reset               ( 1'b0                                     )
  );

  always @(posedge clk)   mean_dividend <=sum_rx                     ;
  always @(posedge clk)   mean_divisor  <=sum_pkg_len_sync           ;
  (*keep_hierarchy="yes"*)dly_cell #(
     .DLY                 (  DIV_MEAN_DLY+1+SYNC_Mean_DLY            ),
     .DW                  (  3                                       )
  ) U_dly_divd(
      .dout       ({mean_out_vld  ,mean_out_done  ,mean_out_frist   }),
      .din        ({sum_result_vld,sum_result_done,sum_result_frist }),
     .clk                 ( clk                                      ),
     .reset               ( 1'b0                                     )
  );

  wire sync_end_done      ;
  (*keep_hierarchy="yes"*)dly_cell #(
     .DLY                 (  SYNC_Mean_DLY                           ),
     .DW                  (  1                                       )
  ) dly_sync_ct(
     .dout                ( sync_end_done                            ),
     .din                 ( sum_result_done                          ),
     .clk                 ( clk                                      ),
     .reset               ( 1'b0                                     )
  );
  always @(posedge clk) 
  if(sum_result_done)     sync_util<=1;
  else if(sync_end_done)  sync_util<=0;
`else
    assign                  sum_tx=0    ;
    always_ff @(posedge clk)sync_util<=0;
    assign    mean_dividend = $signed  (sum_result_data);
    assign    mean_divisor  = $unsigned(sum_pkg_len)    ;
    dly_cell #(
      .DLY          (DIV_MEAN_DLY+1                   ),
      .DW           (3                                )
    ) U_dly_divd(
      .dout({mean_out_vld  ,mean_out_done  ,mean_out_frist   }),
      .din ({sum_result_vld,sum_result_done,sum_result_frist }),
      .clk          (clk                               ),
      .reset        (1'b0                              )
    );

`endif


`elsif DEBUG_CORE4//--------------------------------------------------
`ifdef ROUTER
  localparam  SYNC_Mean_DLY =16;
  assign      sum_tx=sum_result_data                                 ;
  wire   [16-1:0]   sum_pkg_len_sync                                 ;
  (*keep_hierarchy="yes"*)dly_cell #(
     .DLY                 (  SYNC_Mean_DLY                           ),
     .DW                  (  16                                      )
  ) dly_mean_len(
     .dout                ( sum_pkg_len_sync                         ),
     .din           ( sum_pkg_len+sum_pkg_len+sum_pkg_len+sum_pkg_len),
     .clk                 ( clk                                      ),
     .reset               ( 1'b0                                     )
  );

  always @(posedge clk)   mean_dividend <=sum_rx                     ;
  always @(posedge clk)   mean_divisor  <=sum_pkg_len_sync           ;
  (*keep_hierarchy="yes"*)dly_cell #(
     .DLY                 (  DIV_MEAN_DLY+1+SYNC_Mean_DLY            ),
     .DW                  (  3                                       )
  ) U_dly_divd(
      .dout      ({mean_out_vld  ,mean_out_done  ,mean_out_frist   }),
      .din       ({sum_result_vld,sum_result_done,sum_result_frist }),
     .clk                 ( clk                                      ),
     .reset               ( 1'b0                                     )
  );

  wire sync_end_done      ;
  (*keep_hierarchy="yes"*)dly_cell #(
     .DLY                 (  SYNC_Mean_DLY                           ),
     .DW                  (  1                                       )
  ) dly_sync_ct(
     .dout                ( sync_end_done                            ),
     .din                 ( sum_result_done                          ),
     .clk                 ( clk                                      ),
     .reset               ( 1'b0                                     )
  );
  always @(posedge clk) 
  if(sum_result_done)     sync_util<=1;
  else if(sync_end_done)  sync_util<=0;
  
`else
    assign                  sum_tx=0    ;
    always_ff @(posedge clk)sync_util<=0;
    assign    mean_dividend = $signed  (sum_result_data);
    assign    mean_divisor  = $unsigned(sum_pkg_len)    ;
    dly_cell #(
      .DLY          (DIV_MEAN_DLY+1                   ),
      .DW           (3                                )
    ) U_dly_divd(
      .dout({mean_out_vld  ,mean_out_done  ,mean_out_frist   }),
      .din ({sum_result_vld,sum_result_done,sum_result_frist }),
      .clk          (clk                               ),
      .reset        (1'b0                              )
    );

`endif
`endif


    ln_div_mean U_DIV (
      .aclk                   ( clk                     ),
      .s_axis_divisor_tready  (                         ),
      .s_axis_divisor_tvalid  ( 1'b1                    ),
      .s_axis_divisor_tdata   ( mean_divisor            ),
      .s_axis_dividend_tready (                         ),
      .s_axis_dividend_tvalid ( 1'b1                    ),
      .s_axis_dividend_tdata  ( mean_dividend           ),
      .m_axis_dout_tvalid     (                         ),
      .m_axis_dout_tdata      ( mean_result             ) 
    );
    logic [DATA_WIDTH-1:0]               r_mean_out_data ;
    always_ff @(posedge clk)r_mean_out_data<=mean_result[16+:DATA_WIDTH];
    assign mean_out_data = mean_out_vld?r_mean_out_data:0;













   
endmodule
