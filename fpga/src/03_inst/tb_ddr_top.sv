`timescale 1ns / 1ps
// -----------------------------------------------------------------------------
// Copyright      : UCLA EDA LAB
// -----------------------------------------------------------------------------
// Engineer       : Chen Wu
// Design Name    : opu series
// Module Name    : tb_ddr_top
// Target Devices : 325t, Alveo U200
// Tool Versions  : Vivado 2020.1, Modelsim 2019.4
// Description    : 
//    Testbench for ddr top
//
// Revision       :
// Version        Date        Author        Descriptin
// 1.0            2022-03-30  Chen Wu       Initial version
// -----------------------------------------------------------------------------


module tb_ddr_top();


  wire          [      63 : 0]      m_axi_awaddr              ;
  wire          [       7 : 0]      m_axi_awlen               ;
  wire                              m_axi_awvalid             ;
  wire                              m_axi_awready             ;

  wire          [     511 : 0]      m_axi_wdata               ;
  wire                              m_axi_wlast               ;
  wire                              m_axi_wvalid              ;
  wire                              m_axi_wready              ;

  wire          [      63 : 0]      m_axi_araddr              ;
  wire          [       7 : 0]      m_axi_arlen               ;
  wire                              m_axi_arvalid             ;
  wire                              m_axi_arready             ;

  wire                              m_axi_rready              ;
  wire          [     511 : 0]      m_axi_rdata               ;
  wire                              m_axi_rvalid              ;
  wire                              m_axi_rlast               ;

  wire                              ddr_rdone                 ;
  wire          [     511 : 0]      ddr_rdata                 ;
  wire                              ddr_rvld                  ;
  wire                              ddr_wdone                 ;
  wire                              ddr_wrdy                  ;

  reg           [      25 : 0]      ddr_roffset = 0           ;
  reg           [      15 : 0]      ddr_rstep = 0             ;
  reg           [       3 : 0]      ddr_rstep_num = 0         ;
  reg           [      25 : 0]      ddr_rstride = 0           ;
  reg                               ddr_rstart = 0            ;

  reg           [      25 : 0]      ddr_woffset = 0           ;
  reg           [      15 : 0]      ddr_wstep = 0             ;
  reg           [       3 : 0]      ddr_wstep_num = 0         ;
  reg           [      25 : 0]      ddr_wstride = 0           ;
  reg                               ddr_wstart = 0            ;
  reg           [     511 : 0]      ddr_wdata = 0             ;
  reg                               ddr_wvld = 0              ;

  reg                               clk                       ;
  reg                               reset = 1                 ;

  localparam          CYCLE         = 4                       ;
  localparam          ddr_file      = "E:/workspace/00_github/01_ucla/bert_opu_verification/test_chen/ddr.txt";

  initial begin
    clk           =       1'b1                      ;
    forever #(CYCLE / 2)
      clk         =       ~clk                      ;
  end

  task read_ddr                                     ;
    repeat (20) @(posedge clk)                      ;
    reset         <=    1'b0                        ;
    repeat (20) @(posedge clk)                      ;

    @(posedge clk)                                  ;
    ddr_roffset   <=    0                           ;
    ddr_rstep     <=    320                         ;
    ddr_rstep_num <=    2                           ;
    ddr_rstride   <=    640                         ;
    ddr_rstart    <=    1'b1                        ;

    @(posedge clk)                                  ;
    ddr_rstart    <=    1'b0                        ;

    repeat (20) @(posedge clk)                      ;
  endtask

  task write_ddr                                    ;
    automatic int i, j                              ;
    bit     [511 : 0]   data_q[$]                   ;
    bit     [511 : 0]   data_tmp                    ;

    for ( i = 0; i < 320*2; i++ ) begin
      for ( j = 0; j < 32; j++ ) begin
        data_tmp[16*j +: 16]  = $random() % 65536   ;
      end
      data_q.push_back(data_tmp)                    ;
    end

    repeat (20) @(posedge clk)                      ;
    reset         <=    1'b0                        ;
    repeat (20) @(posedge clk)                      ;

    @(posedge clk)                                  ;
    ddr_woffset   <=    0                           ;
    ddr_wstep     <=    320                         ;
    ddr_wstep_num <=    2                           ;
    ddr_wstride   <=    640                         ;
    ddr_wstart    <=    1'b1                        ;

    @(posedge clk)                                  ;
    ddr_wstart    <=    1'b0                        ;

    forever @(posedge clk) begin
      if ( data_q.size() == 0 ) begin
        ddr_wdata <=    512'h0                      ;
        ddr_wvld  <=    1'b0                        ;
        break                                       ;
      end else if ( ddr_wrdy ) begin
        ddr_wdata <=    data_q.pop_front()          ;
        ddr_wvld  <=    1'b1                        ;
      end
    end

    repeat (20) @(posedge clk)                      ;
  endtask

  initial begin
    read_ddr()                                      ;
    wait(ddr_rdone)                                 ;
    $display("Read DDR done.\n")                    ;

    write_ddr()                                     ;
    wait(ddr_wdone)                                 ;
    $display("Write DDR done.\n")                   ;
  end

  ddr_top u0_ddr_top (
    .m_axi_awaddr                 ( m_axi_awaddr              ),
    .m_axi_awlen                  ( m_axi_awlen               ),
    .m_axi_awvalid                ( m_axi_awvalid             ),
    .m_axi_awready                ( m_axi_awready             ),

    .m_axi_wdata                  ( m_axi_wdata               ),
    .m_axi_wlast                  ( m_axi_wlast               ),
    .m_axi_wvalid                 ( m_axi_wvalid              ),
    .m_axi_wready                 ( m_axi_wready              ),

    .m_axi_araddr                 ( m_axi_araddr              ),
    .m_axi_arlen                  ( m_axi_arlen               ),
    .m_axi_arvalid                ( m_axi_arvalid             ),
    .m_axi_arready                ( m_axi_arready             ),

    .m_axi_rready                 ( m_axi_rready              ),
    .m_axi_rdata                  ( m_axi_rdata               ),
    .m_axi_rvalid                 ( m_axi_rvalid              ),
    .m_axi_rlast                  ( m_axi_rlast               ),

    .ddr_rdone                    ( ddr_rdone                 ),
    .ddr_rdata                    ( ddr_rdata                 ),
    .ddr_rvld                     ( ddr_rvld                  ),
    .ddr_roffset                  ( ddr_roffset               ),
    .ddr_rstep                    ( ddr_rstep                 ),
    .ddr_rstep_num                ( ddr_rstep_num             ),
    .ddr_rstride                  ( ddr_rstride               ),
    .ddr_rstart                   ( ddr_rstart                ),

    .ddr_wdone                    ( ddr_wdone                 ),
    .ddr_wrdy                     ( ddr_wrdy                  ),
    .ddr_woffset                  ( ddr_woffset               ),
    .ddr_wstep                    ( ddr_wstep                 ),
    .ddr_wstep_num                ( ddr_wstep_num             ),
    .ddr_wstride                  ( ddr_wstride               ),
    .ddr_wstart                   ( ddr_wstart                ),
    .ddr_wdata                    ( ddr_wdata                 ),
    .ddr_wvld                     ( ddr_wvld                  ),

    .clk                          ( clk                       ),
    .reset                        ( reset                     )
  );

  fake_ddr4 #(
    .filename                     ( ddr_file                  )
  ) u0_fake_ddr4 (
    .m_axi_arready                ( m_axi_arready             ),
    .m_axi_araddr                 ( m_axi_araddr              ),
    .m_axi_arlen                  ( m_axi_arlen               ),
    .m_axi_arvalid                ( m_axi_arvalid             ),

    .m_axi_rlast                  ( m_axi_rlast               ),
    .m_axi_rready                 ( m_axi_rready              ),
    .m_axi_rdata                  ( m_axi_rdata               ),
    .m_axi_rvalid                 ( m_axi_rvalid              ),

    .m_axi_awready                ( m_axi_awready             ),
    .m_axi_awaddr                 ( m_axi_awaddr              ),
    .m_axi_awlen                  ( m_axi_awlen               ),
    .m_axi_awvalid                ( m_axi_awvalid             ),

    .m_axi_wready                 ( m_axi_wready              ),
    .m_axi_wdata                  ( m_axi_wdata               ),
    .m_axi_wvalid                 ( m_axi_wvalid              ),
    .m_axi_wlast                  ( m_axi_wlast               ),

    .clk                          ( clk                       ),
    .reset                        ( reset                     )
  );

endmodule