`timescale 1ns / 1ps
// -----------------------------------------------------------------------------
// Copyright      : UCLA EDA LAB
// -----------------------------------------------------------------------------
// Engineer       : Chen Wu
// Design Name    : opu series
// Module Name    : tb_ker_top
// Target Devices : 325t, Alveo U200
// Tool Versions  : Vivado 2020.1, Modelsim 2019.4
// Description    : 
//    Testbench for ker top
//
// Revision       :
// Version        Date        Author        Descriptin
// 1.0            2022-04-06  Chen Wu       Initial version
// -----------------------------------------------------------------------------


module tb_ker_top();

  wire        [8191 : 0]            ker_rdata                     ;
  reg         [   5 : 0]            ker_saddr = 0                 ;
  reg         [   5 : 0]            ker_eaddr = 0                 ;
  reg                               ker_rstart = 0                ;

  reg         [ 511 : 0]            ker_wdata = 0                 ;
  reg                               ker_wvld = 0                  ;
  reg                               ker_wstart = 0                ;
  reg                               ker_pp = 0                    ;

  reg                               clk                           ;
  reg                               reset = 1                     ;

  localparam                        CYCLE = 4                     ;
  localparam                        NUM = 64*16                   ;

  initial begin
    clk           =   1'b1                                        ;
    forever #(CYCLE / 2)
      clk         =   ~clk                                        ;
  end

  task wr_ker (input pp)                                          ;
    automatic integer       i, j                                  ;
    bit       [ 511 : 0]    ker_q[$]                              ;
    bit       [ 511 : 0]    ker_tmp                               ;

    for ( i = 0; i < NUM; i = i + 1 ) begin
      for ( j = 0; j < 32; j = j + 1 ) begin
        ker_tmp[j*16 +: 16] = $random() % 65536                   ;
      end
      ker_q.push_back(ker_tmp)                                    ;
    end

    @(posedge clk)                                                ;
    ker_wstart        <=    1'b1                                  ;
    ker_pp            <=    pp                                    ;

    @(posedge clk)                                                ;
    ker_wstart        <=    1'b0                                  ;

    forever @(posedge clk) begin
      if ( ker_q.size() == 0 ) begin
        ker_wdata     <=    512'h0                                ;
        ker_wvld      <=    1'b0                                  ;
        break                                                     ;
      end else begin
        ker_wdata     <=    ker_q.pop_front()                     ;
        ker_wvld      <=    1'b1                                  ;
      end
    end

    repeat (20) @(posedge clk)                                    ;
  endtask

  task rd_ker                                                     ;
    @(posedge clk)                                                ;
    ker_saddr         <=    0                                     ;
    ker_eaddr         <=    1                                     ;
    ker_rstart        <=    1'b1                                  ;

    @(posedge clk)                                                ;
    ker_rstart        <=    1'b0                                  ;
  endtask

  initial begin
    repeat (20) @(posedge clk)                                    ;
    reset             <=    1'b0                                  ;
    repeat (20) @(posedge clk)                                    ;

    wr_ker(1'b0)                                                  ;

    fork
      begin
        rd_ker()                                                  ;
      end

      begin
        wr_ker(1'b1)                                              ;
      end
    join

  end

  ker_top u0_ker_top (
    .ker_rdata                      ( ker_rdata                   ),
    .ker_saddr                      ( ker_saddr                   ),
    .ker_eaddr                      ( ker_eaddr                   ),
    .ker_rstart                     ( ker_rstart                  ),

    .ker_wdata                      ( ker_wdata                   ),
    .ker_wvld                       ( ker_wvld                    ),
    .ker_wstart                     ( ker_wstart                  ),
    .ker_pp                         ( ker_pp                      ),

    .clk                            ( clk                         ),
    .reset                          ( reset                       )
  );

endmodule