`timescale 1ns / 1ps
// -----------------------------------------------------------------------------
// Copyright      : UCLA EDA LAB
// -----------------------------------------------------------------------------
// Engineer       : Chen Wu
// Design Name    : opu series
// Module Name    : ifm_top
// Target Devices : 325t, Alveo U200
// Tool Versions  : Vivado 2020.1, Modelsim 2019.4
// Description    : 
//    This module is the mean function for layer_normalization. 
//    The NUM_ELEMS is the number of input elements.
//    It first compute the mean and the variance.
//    The variance is adding with a epsilon(a small count), then square root.
//    Then, substract the mean , variance division, for each elements.
//    
//    The root is implemented by LUT.
//    Next optimizing direction is using division, root IP, using pipline.
//
// Revision       :
// Version        Date        Author        Descriptin
// 1.0            2021-03-31  Yiheng Jian   Initial version
// 1.1            2022-04-04  Chen Wu       Add beta, gamma, shift
// 2.0            2022-05-08  Chen Wu       Delete BG to reduce resource
// -----------------------------------------------------------------------------
// Input element data width                                                                  
// Output element data width                                                                 
// Number of input elements in a single cycle                                                
// Maximum number of NUM_ELEMS-sized packages
// (e.g. max vector size is NUM_ELEMS*MAX_PKG_LEN)





module layer_norm_old # (
  parameter DATA_WIDTH  = 16, 
  parameter OUT_WIDTH   = 16, 
  parameter NUM_ELEMS   = 8 , 
  parameter MAX_PKG_LEN = 8   
  ) (
  input                                             clk           ,
  input                                             rst           ,
  input                                             enable        ,
  input         [   5  : 0]                         nvm_rstep     ,
  input         [   11 : 0]                         xnum          ,
  input         [   11 : 0]                         ynum          ,
  input         [   11 : 0]                         bnum          ,
  input         [   11 : 0]                         gnum          ,
  output logic                                      ln_fifo_ready ,
  input         [NUM_ELEMS-1:0][DATA_WIDTH-1:0]     ln_din        ,
  input                                             ln_din_vld    ,
  input                                             ln_din_done   ,
  output logic  [NUM_ELEMS-1:0][OUT_WIDTH-1: 0]     ln_dout       ,
  output logic                                      ln_dout_vld   ,
  output logic                                      ln_dout_done  ,
  input                                             gamma_wstart  , 
  input                                             gamma_wvld    ,
  input         [  511 : 0]                         gamma_wdata   ,
  input                                             beta_wstart   ,
  input                                             beta_wvld     ,
  input         [  511 : 0]                         beta_wdata    ,
  output wire         [127:0]                       sum_tx        ,
  input  wire         [127:0]                       sum_rx    

  );

  localparam CNT_WIDTH = $clog2(MAX_PKG_LEN);
  //---------------------------------------------------------------
  // Input Stage
  //---------------------------------------------------------------
    logic [NUM_ELEMS-1:0][DATA_WIDTH-1:0] buffer1_out_data  ;
    logic                                 buffer1_out_val   ;
    logic                                 buffer1_out_done  ;
    logic                                 buffer1_out_rdy   ;
    ln_pkg_buffer_old # (
        .DATA_WIDTH     (DATA_WIDTH                 ),
        .NUM_ELEMS      (NUM_ELEMS                  ),
        .RAM_DEEP       (64                         )
    ) U_BUFFER1(
        .clk            (clk                        ),
        .rst            (rst                        ),
        .nvm_rstep      (nvm_rstep                  ),
        .pkg_in_rdy     (ln_fifo_ready              ),//o
        .pkg_in_data    (~enable?0: ln_din          ),
        .pkg_in_val     (~enable?0: ln_din_vld      ),
        .pkg_in_done    (~enable?0: ln_din_done     ),
        .pkg_out_rdy    (~enable?0: buffer1_out_rdy ),//i
        .pkg_out_data   (buffer1_out_data           ),
        .pkg_out_val    (buffer1_out_val            ),
        .pkg_out_done   (buffer1_out_done           )
        
    );

    //---------------------------------------------------------------
    // Mean Stage
    // Must be 1 since this aligns with input buffer
    // Each pkg is just one element for mean        
    //---------------------------------------------------------------
    logic [DATA_WIDTH-1:0] mean1_result_data    ;
    logic                  mean1_result_vld     ;
    logic                  mean1_result_done    ;
    logic                  mean1_result_frist   ;

    localparam  DIV_MEAN_DLY=16;
    ln_mean_old # (
        .DATA_WIDTH       (DATA_WIDTH           ),
        .NUM_ELEMS        (NUM_ELEMS            ),
        .DIV_MEAN_DLY     (DIV_MEAN_DLY         )
    ) U_MEAN1(
        .clk              (clk                  ),
        .rst              (rst                  ),
        .nvm_rstep        (nvm_rstep            ),
        .mean_in_data     (~enable?0:ln_din     ),
        .mean_in_vld      (~enable?0:ln_din_vld ),
        .mean_in_done     (~enable?0:ln_din_done),
        .mean_out_data    (mean1_result_data    ),
        .mean_out_vld     (mean1_result_vld     ),
        .mean_out_done    (mean1_result_done    ),
        .mean_out_frist   (mean1_result_frist   ),
        .sum_tx           (sum_tx[63:0]         ),
        .sum_rx           (~enable?0:sum_rx[63:0])
    );

    
    //---------------------------------------------------------------
    // Mean delay Signals
    //---------------------------------------------------------------
    generate
    logic [DATA_WIDTH-1:0] r_mean1_result_data  =0  ;
    logic                  r_mean1_result_vld   =0  ;
    logic                  r_mean1_result_done  =0  ;
    logic                  r_mean1_result_frist =0  ;
    logic [DATA_WIDTH-1:0] sub_in_data  =0          ;
    logic                  sub_in_vld   =0          ;
    logic                  sub_in_done  =0          ;
    logic                  sub_in_frist =0          ;

    always @(posedge clk)
    begin
        r_mean1_result_data  <=   mean1_result_data ;
        r_mean1_result_vld   <=   mean1_result_vld  ;
        r_mean1_result_done  <=   mean1_result_done ;
        r_mean1_result_frist <=   mean1_result_frist;
        sub_in_data     <= r_mean1_result_data      ;
        sub_in_vld      <= r_mean1_result_vld       ;
        sub_in_done     <= r_mean1_result_done      ;
        sub_in_frist    <= r_mean1_result_frist     ;
    end
    endgenerate


    //---------------------------------------------------------------
    // Input-mean Stage
    // Subtraction inputs (accumulate X and mean values)
    // Sign extend input and mean, then subtract them
    // Both should go high at the same transaction
    // Subtraction (X-mean)
    //---------------------------------------------------------------
    logic [NUM_ELEMS-1:0][DATA_WIDTH:0]    sub_result_data   ;
    logic                                  sub_result_val    ;
    logic                                  sub_result_done   ;
    
    always_ff @(posedge clk) buffer1_out_rdy=mean1_result_vld;
    
    generate for (genvar i=0; i<NUM_ELEMS; i++)
    begin
    logic [DATA_WIDTH:0]    r_sub_result_data ;
    
    always @(posedge clk)begin
        r_sub_result_data   <= $signed(buffer1_out_data[i])  - $signed(sub_in_data) ;
        sub_result_data[i]  <= r_sub_result_data;
    end
    end

    reg r_sub_result_val  =0;
    reg r_sub_result_done =0;
    always @(posedge clk)begin
       r_sub_result_val  <= buffer1_out_val  & sub_in_vld;
       r_sub_result_done <= buffer1_out_done & sub_in_done;     
         sub_result_val  <= r_sub_result_val ;
         sub_result_done <= r_sub_result_done;
    end
    endgenerate
    



    //----------------------------------------------------------------
    // Subtraction outputs
    //----------------------------------------------------------------
    logic                                  buffer2_out_rdy  ;
    logic [NUM_ELEMS-1:0][DATA_WIDTH:0]    buffer2_out_data ;
    logic                                  buffer2_out_val  ;
    logic                                  buffer2_out_done ;


    ln_pkg_buffer_old # (
        .DATA_WIDTH  (DATA_WIDTH+1                  ),
        .NUM_ELEMS   (NUM_ELEMS                     ),
        .RAM_DEEP    (64                            )
    ) U_BUFFER2(
        .clk         (clk                           ),
        .rst         (rst                           ),
        .nvm_rstep   (nvm_rstep                     ),
        .pkg_in_rdy  (),
        .pkg_in_data (~enable?0:sub_result_data     ),
        .pkg_in_val  (~enable?0:sub_result_val      ),
        .pkg_in_done (~enable?0:sub_result_done     ),
        .pkg_out_rdy (~enable?0:buffer2_out_rdy     ),
        .pkg_out_data(buffer2_out_data              ),
        .pkg_out_val (buffer2_out_val               ),
        .pkg_out_done(buffer2_out_done              )
    );



    //---------------------------------------------------------------
    // Sum((X-mean)^2) Stage
    // Pipeline (X-mean) ->  (input to multiplier)
    // (DATA_WIDTH+1)*2 bits for product (X-mean)**2
    // Calculate product
    //---------------------------------------------------------------
    logic [NUM_ELEMS-1:0][2*(DATA_WIDTH+1)-1:0] prod_result_data ;
    logic                                       prod_result_vld  ;
    logic                                       prod_result_done ;
  
    localparam  PROD_DLY =6;
    generate 
    for (genvar i=0; i<NUM_ELEMS; i++)
    begin:dsp_s
        wire [2*(DATA_WIDTH+1)-1:0]dsp_sim_in;
        assign dsp_sim_in=$signed(sub_result_data[i])
                         *$signed(sub_result_data[i]);
        dly_cell #(
          .DLY          (PROD_DLY                         ),
          .DW           (2*(DATA_WIDTH+1)                 )
        ) U_DSP_sim(
          .dout         (prod_result_data[i]              ),
          .din          (dsp_sim_in                       ),
          .clk          (clk                              ),
          .reset        (rst                              )
        );
        end
        
        dly_cell #(
          .DLY          (PROD_DLY                         ),
          .DW           (2                                )
        ) U_dsvd(
          .dout         ({prod_result_vld,prod_result_done}),
          .din          ({sub_result_val ,sub_result_done }),
          .clk          (clk                              ),
          .reset        (rst                              )
        );
    
    endgenerate

    //------------------------------------------------------
    // Calculate mean of products (e.g. variance)
    //------------------------------------------------------
    logic [2*(DATA_WIDTH+1)-1:0] mean2_result_data      ;
    logic                        mean2_result_vld       ;
    logic                        mean2_result_done      ;
    logic                        mean2_result_frist     ;

    ln_mean_old # (
        .DATA_WIDTH     (2*(DATA_WIDTH+1)               ),
        .NUM_ELEMS      (NUM_ELEMS                      ),
        .DIV_MEAN_DLY   (DIV_MEAN_DLY                   )
    ) U_MEAN2(
        .clk            (clk                            ),
        .rst            (rst                            ),
        .nvm_rstep      (nvm_rstep                      ),
        .mean_in_data   (~enable?0:prod_result_data     ),
        .mean_in_vld    (~enable?0:prod_result_vld      ),
        .mean_in_done   (~enable?0:prod_result_done     ),
        .mean_out_data  (mean2_result_data              ),
        .mean_out_vld   (mean2_result_vld               ),
        .mean_out_done  (mean2_result_done              ),
        .mean_out_frist (mean2_result_frist             ),
        .sum_tx         (sum_tx[127:64]                 ),
        .sum_rx         (~enable?0:sum_rx[127:64]       )
    );



    //---------------------------------------------------------------
    // change from here to use cordic
    // sqrt(var) Stage
    //---------------------------------------------------------------    
    logic          [47:0]       sqrt_in_data            ;
    logic          [31:0]       sqrt_result_data        ;
    logic                       sqrt_result_vld         ;
    logic                       sqrt_result_done        ;
    assign  sqrt_in_data = $signed(mean2_result_data)   ;

    ln_sqrt U_SQRT (
      .aclk                     (clk                    ),
      .s_axis_cartesian_tvalid  (1'b1                   ),
      .s_axis_cartesian_tdata   (sqrt_in_data           ),
      .m_axis_dout_tvalid       (                       ),
      .m_axis_dout_tdata        (sqrt_result_data       ) 
    );

    localparam SQRT_DLY = 13;
    dly_cell #(
      .DLY          (SQRT_DLY                             ),
      .DW           (2                                    )
    ) U_sqvd(
      .dout         ({sqrt_result_vld  ,sqrt_result_done }),
      .din          ({mean2_result_vld ,mean2_result_done}),
      .clk          (clk                                  ),
      .reset        (rst                                  )
    );



    //---------------------------------------------------------------
    // (x-mean)/sqrt(var) Stage
    //---------------------------------------------------------------
    localparam DIV_DLY = 16;
    logic [23:0]                divisor_data     = 0     ;
    logic                       divisor_vld      = 0     ;
    logic                       divisor_done     = 0     ;
    logic [NUM_ELEMS-1:0][23:0] dividend_data    = 0     ;
    logic                       dividend_vld     = 0     ;
    logic                       dividend_done    = 0     ;
    logic [NUM_ELEMS-1:0][39:0] div_result_data          ;
    logic                       div_result_vld           ;
    logic                       div_result_done          ;    


generate
    assign buffer2_out_rdy     =    sqrt_result_vld      ;
    logic          [31:0]       r1_sqrt_result_data   =0 ;
    logic                       r1_sqrt_result_vld    =0 ;
    logic                       r1_sqrt_result_done   =0 ;
    always @(posedge clk) begin
        r1_sqrt_result_data  <=     sqrt_result_data     ;
        r1_sqrt_result_vld   <=     sqrt_result_vld      ;
        r1_sqrt_result_done  <=     sqrt_result_done     ;
    end


    always @(posedge clk) begin
        divisor_data  <= $signed(r1_sqrt_result_data);
        divisor_vld   <=         r1_sqrt_result_vld ;
        divisor_done  <=         r1_sqrt_result_done;
        dividend_vld  <= buffer2_out_val ;
        dividend_done <= buffer2_out_done;
    end
   
    for ( genvar i = 0; i < NUM_ELEMS; i = i + 1 ) begin:gdi1
        always @(posedge clk)
        dividend_data[i] <= $signed(buffer2_out_data[i]);
    end

    for ( genvar i = 0; i < NUM_ELEMS; i = i + 1 ) begin:gdiv
      ln_div U_DIV (
        .aclk                         ( clk                   ),
        .s_axis_divisor_tvalid        ( 1'b1                  ),
        .s_axis_divisor_tdata         ( divisor_data          ),
        .s_axis_dividend_tvalid       ( 1'b1                  ),
        .s_axis_dividend_tdata        ( dividend_data[i]      ),
        .m_axis_dout_tvalid           (                       ),
        .m_axis_dout_tdata            ( div_result_data[i]    ) 
      );
    end

    logic                       r_div_result_vld              ;
    logic                       r_div_result_done             ;  

    assign r_div_result_vld  = divisor_vld  && dividend_vld   ;
    assign r_div_result_done = divisor_done && dividend_done  ;

    dly_cell #(
      .DLY                (DIV_DLY                            ),
      .DW                 (2                                  )
    ) U_divd (
      .dout               ({div_result_vld  ,div_result_done  }),
      .din                ({r_div_result_vld,r_div_result_done}),
      .clk                (clk                                 ),
      .reset              (rst                                 )
    );

endgenerate


  //------------------------------------------------------------------------
  // LayerNorm
  // Initial gamma and beta
  //------------------------------------------------------------------------
  reg           [  511 : 0]           MEM_gamma[31:0]             ;
  reg           [  511 : 0]           MEM_beta [31:0]             ;
  reg           [    4 : 0]           ln_wcnt = 0                 ;
  reg           [    4 : 0]           ln_rcnt = 0                 ;

  always @(posedge clk)
  if (gamma_wstart|| beta_wstart)
      ln_wcnt             <=    5'h0                              ;
  else if (gamma_wvld) begin
      ln_wcnt             <=    ln_wcnt + 1                       ;
      MEM_gamma[ln_wcnt]  <=    gamma_wdata                       ;
  end
  else if (beta_wvld) begin
      ln_wcnt             <=    ln_wcnt + 1                       ;
      MEM_beta[ln_wcnt]   <=    beta_wdata                        ;
  end

  reg           [  511 : 0]            mac_in_gamma =0            ;
  reg           [  511 : 0]            mac_in_beta  =0            ;
  always @(posedge clk)
  if(div_result_done)
        ln_rcnt<=0;
  else if(div_result_vld)
  begin
        ln_rcnt<=ln_rcnt+1;
        mac_in_gamma<=MEM_gamma[ln_rcnt];
        mac_in_beta <=MEM_beta [ln_rcnt];
  end


  localparam MAC_A_DW = 25;
  localparam MAC_B_DW = 16;
  localparam MAC_C_DW = 41;
  localparam MAC_D_DW = 25;
  localparam MAC_P_DW = 42;


  reg   [NUM_ELEMS-1:0][MAC_B_DW-1:0]        r1_mac_in_gamma =0            ;
  reg   [NUM_ELEMS-1:0][MAC_C_DW-1:0]        r1_mac_in_beta  =0            ;
  reg   [NUM_ELEMS-1:0][MAC_A_DW-1:0]        mac_in_data     =0            ;
  reg   [NUM_ELEMS-1:0][MAC_A_DW-1:0]        r1_mac_in_data  =0            ;
  
  logic [NUM_ELEMS-1:0][MAC_P_DW-1:0]        mac_result_data               ;
  logic                                      mac_result_vld                ;
  logic                                      mac_result_done               ;
  logic [NUM_ELEMS-1:0][MAC_P_DW-1:0]        mac_result_data_shift         ;
  logic                                      mac_result_vld_shift          ;
  logic                                      mac_result_done_shift         ;

  logic  [NUM_ELEMS-1:0][OUT_WIDTH-1: 0]     mac_out_data  ;
  logic                                      mac_out_vld   ;
  logic                                      mac_out_done  ;
  
  

  generate
  for ( genvar i = 0; i < NUM_ELEMS; i = i + 1 ) begin: gmac
  always @(posedge clk)begin
          r1_mac_in_gamma[i] <= $signed(mac_in_gamma[i*16+:16]);
          r1_mac_in_beta [i] <= $signed(mac_in_gamma[i*16+:16]<<<bnum);
          mac_in_data    [i] <= $signed(div_result_data[i]);
          r1_mac_in_data [i] <= mac_in_data[i]; 
  end
  
  //---------------------------------------------------------------
  // gamma * (x-mean)/sqrt(var) + beta Stage
  //---------------------------------------------------------------

    ln_mac U_MAC (
        .CLK    ( clk                                                     ),
        .SCLR   ( rst                                                     ),
        .A      ( r1_mac_in_data[i]                                       ),
        .B      ( r1_mac_in_gamma[i]                                      ),
        .C      ( r1_mac_in_beta[i]                                       ),
        .D      ( 25'd0                                                   ),
        .P      ( mac_result_data[i]                                      ) 
      );

    always @(posedge clk)begin
        mac_result_data_shift[i]<=mac_result_data[i] >> ynum ;
        mac_out_data[i]         <=mac_result_data_shift[i][OUT_WIDTH-1:0] ;
    end
  
  end
  endgenerate

    //---------------------------------------------------------------
    //DSP out 
    //---------------------------------------------------------------
   localparam MAC_DLY = 6;
    dly_cell #(
      .DLY                ( MAC_DLY                                       ),
      .DW                 ( 2                                             )
    ) U_mac_vd (
      .dout               ( {mac_result_vld,mac_result_done}              ),
      .din                ( {div_result_vld,div_result_done}              ),

      .clk                ( clk                                           ),
      .reset              ( rst                                           )
    );
    always @(posedge clk)begin
        mac_result_vld_shift    <=mac_result_vld ;
        mac_result_done_shift   <=mac_result_done;
        mac_out_vld             <= mac_result_vld_shift  ;
        mac_out_done            <= mac_result_done_shift ;
    end



    //---------------------------------------------------------------
    //output selection
    //---------------------------------------------------------------
    always @(posedge clk)
    if(enable)
    begin
        ln_dout      <= mac_out_data;
        ln_dout_vld  <= mac_out_vld ;
        ln_dout_done <= mac_out_done;
    end
    else begin
        ln_dout      <= ln_din      ;
        ln_dout_vld  <= ln_din_vld  ;
        ln_dout_done <= ln_din_done ;
    end








endmodule
