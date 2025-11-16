
// -----------------------------------------------------------------------------
// Copyright      : UCLA EDA LAB
// -----------------------------------------------------------------------------
// Engineer       : Chen Wu
// Design Name    : opu series
// Module Name    : tb_topu
// Target Devices : 325t, Alveo U200
// Tool Versions  : Vivado 2020.1, Modelsim 2019.4
// Description    : 
//    Testbench for the top module.
//
// Revision       :
// Version        Date        Author        Descriptin
// 1.0            2022-04-07  Chen Wu       Initial version
// 2.0            2023-09-07  Shaoqiang     run all 97 layers
// -----------------------------------------------------------------------------

//`define ModelSim
//`define ModelSim_imple

`timescale 1ps/1ps
module tb_core_top();

  //--------------------------------------------------------------------
  // Attention: Need to be changed according your environemtn
  //--------------------------------------------------------------------
  wire                                clk                             ;
  reg                                 reset                           ;
  reg                                 sys_clk_p                       ;
  reg                                 sys_clk_n                       ;
  reg                                 c1_data_init_finish    =0       ;
  reg         [  25  -1 : 0]          core_offset      =0             ;
  reg                                 core_start       =0             ;
  wire        [  10  -1 : 0]          layer_cnt                       ;
  //aw
  wire      [    2  -1 : 0]           m_axi_awid                      ;
  wire                                m_axi_awlock                    ;
  wire      [    4  -1 : 0]           m_axi_awcache                   ;
  wire      [    3  -1 : 0]           m_axi_awprot                    ;
  wire      [    4  -1 : 0]           m_axi_awqos                     ;
  wire      [    64 -1 : 0]           m_axi_awaddr                    ;
  wire      [    8  -1 : 0]           m_axi_awlen                     ;
  wire      [    3  -1 : 0]           m_axi_awsize                    ;
  wire      [    2  -1 : 0]           m_axi_awburst                   ;
  wire                                m_axi_awvalid                   ;
  wire                                m_axi_awready                   ;
  //w
  wire      [    512-1 : 0]           m_axi_wdata                     ;
  wire                                m_axi_wlast                     ;
  wire                                m_axi_wvalid                    ;
  wire                                m_axi_wready                    ;
  wire      [    64- 1 : 0]           m_axi_wstrb                     ;
  //b
  wire      [    2  -1 : 0]           m_axi_bid                       ;
  wire      [    2  -1 : 0]           m_axi_bresp                     ;
  wire                                m_axi_bvalid                    ;
  wire                                m_axi_bready                    ;
  //ar
  wire      [    2  -1 : 0]           m_axi_arid                      ;
  wire                                m_axi_arlock                    ;
  wire      [    4  -1 : 0]           m_axi_arcache                   ;
  wire      [    3  -1 : 0]           m_axi_arprot                    ;
  wire      [    4  -1 : 0]           m_axi_arqos                     ;
  wire      [    64 -1 : 0]           m_axi_araddr                    ;
  wire      [    8  -1 : 0]           m_axi_arlen                     ;
  wire      [    3  -1 : 0]           m_axi_arsize                    ;
  wire      [    2  -1 : 0]           m_axi_arburst                   ;
  wire                                m_axi_arvalid                   ;
  wire                                m_axi_arready                   ;
  //r
  wire                                m_axi_rready                    ;
  wire      [    512-1 : 0]           m_axi_rdata                     ;
  wire                                m_axi_rvalid                    ;
  wire                                m_axi_rlast                     ;
  wire      [    2  -1 : 0]           m_axi_rid                       ;
  wire      [    2  -1 : 0]           m_axi_rresp                     ;


  `include "sim_debug.vh"
  
  


  //-------------------------------------------------------------------
  // clock and reset
  //-------------------------------------------------------------------

  initial begin
      sys_clk_p         =       1'b1                                  ;
    forever #(CYCLE / 2)
      sys_clk_p         =       ~sys_clk_p                            ;
  end
  initial begin
      sys_clk_n         =       1'b0                                  ;
    forever #(CYCLE / 2)
      sys_clk_n         =       ~sys_clk_n                            ;
  end
  assign clk=sys_clk_p;
  initial begin
    reset         <=      1'b1                                        ;
    c1_data_init_finish<=0                                            ;
    repeat (100) @(posedge clk)                                       ;
    reset         <=      1'b0                                        ;
    repeat (2000) @(posedge clk)                                      ;
    c1_data_init_finish<=1                                            ;
    task_run_inst()                                                   ;
  end
  //-------------------------------------------------------------------
  // run with instructions
  //-------------------------------------------------------------------
  task task_run_inst                                                  ;
    core_offset                               <=  0                   ;
    core_start                                <=  0                   ;
    repeat (100) @(posedge clk)                                       ;
    core_offset                               <=  INS_BASE            ;
    core_start                                <=  1                   ;
    @(posedge clk)                                                    ;
    core_offset                               <=  0                   ;
    core_start                                <=  0                   ;
  endtask
  //-------------------------------------------------------------------
  // Instantiation OPU module
  //-------------------------------------------------------------------
  core_top #(
    .PRECISION                  ( 3'b001                              ),
    .MUL_NUM                    ( 512                                 ),
    .DIN_NUM                    ( 32                                  ),
    .DOUT_NUM                   ( 32                                  ),
    .PE_NUM                     ( 1                                   ) 
  ) u0_core_top (
    .clk                        ( clk                                 ),
    .reset                      ( reset                               ),
    .c1_data_init_finish        ( c1_data_init_finish                 ),
    //aw---------------------------------------------------------------
    .m_axi_awid                 ( m_axi_awid                          ),
    .m_axi_awlock               ( m_axi_awlock                        ),
    .m_axi_awcache              ( m_axi_awcache                       ),
    .m_axi_awprot               ( m_axi_awprot                        ),
    .m_axi_awqos                ( m_axi_awqos                         ),
    .m_axi_awaddr               ( m_axi_awaddr                        ),
    .m_axi_awlen                ( m_axi_awlen                         ),
    .m_axi_awsize               ( m_axi_awsize                        ),
    .m_axi_awburst              ( m_axi_awburst                       ),
    .m_axi_awvalid              ( m_axi_awvalid                       ),
    .m_axi_awready              ( m_axi_awready&&c1_data_init_finish  ),
    //w----------------------------------------------------------------
    .m_axi_wdata                ( m_axi_wdata                         ),
    .m_axi_wlast                ( m_axi_wlast                         ),
    .m_axi_wvalid               ( m_axi_wvalid                        ),
    .m_axi_wready               ( m_axi_wready&&c1_data_init_finish   ),
    .m_axi_wstrb                ( m_axi_wstrb                         ),
    //b----------------------------------------------------------------
    .m_axi_bid                  ( m_axi_bid                           ),
    .m_axi_bresp                ( m_axi_bresp                         ),
    .m_axi_bvalid               ( m_axi_bvalid                        ),
    .m_axi_bready               ( m_axi_bready                        ),
    //ar---------------------------------------------------------------
    .m_axi_arid                 ( m_axi_arid                          ),
    .m_axi_arlock               ( m_axi_arlock                        ),
    .m_axi_arcache              ( m_axi_arcache                       ),
    .m_axi_arprot               ( m_axi_arprot                        ),
    .m_axi_arqos                ( m_axi_arqos                         ),
    .m_axi_araddr               ( m_axi_araddr                        ),
    .m_axi_arlen                ( m_axi_arlen                         ),
    .m_axi_arsize               ( m_axi_arsize                        ),
    .m_axi_arburst              ( m_axi_arburst                       ),
    .m_axi_arvalid              ( m_axi_arvalid                       ),
    .m_axi_arready              ( m_axi_arready&&c1_data_init_finish  ),
    //r----------------------------------------------------------------
    .m_axi_rready               ( m_axi_rready                        ),
    .m_axi_rdata                ( m_axi_rdata                         ),
    .m_axi_rvalid               ( m_axi_rvalid                        ),
    .m_axi_rlast                ( m_axi_rlast                         ),
    .m_axi_rid                  ( m_axi_rid                           ),
    .m_axi_rresp                ( m_axi_rresp                         ), 
    .core_offset                ( core_offset                         ),
    .core_start                 ( core_start                          ),
    .layer_cnt_o                ( layer_cnt                           )
  );

  tb_fake_ddr4 #(
    .ddr_file                   ( ddr_file                            )
  ) u_tb_fake_ddr4 (
    //aw---------------------------------------------------------------
    .m_axi_awid                 ( m_axi_awid                          ),
    .m_axi_awlock               ( m_axi_awlock                        ),
    .m_axi_awcache              ( m_axi_awcache                       ),
    .m_axi_awprot               ( m_axi_awprot                        ),
    .m_axi_awqos                ( m_axi_awqos                         ),
    .m_axi_awaddr               ( m_axi_awaddr                        ),
    .m_axi_awlen                ( m_axi_awlen                         ),
    .m_axi_awsize               ( m_axi_awsize                        ),
    .m_axi_awburst              ( m_axi_awburst                       ),
    .m_axi_awvalid              ( m_axi_awvalid                       ),
    .m_axi_awready              ( m_axi_awready                       ),
    //w----------------------------------------------------------------
    .m_axi_wdata                ( m_axi_wdata                         ),
    .m_axi_wlast                ( m_axi_wlast                         ),
    .m_axi_wvalid               ( m_axi_wvalid                        ),
    .m_axi_wready               ( m_axi_wready                        ),
    .m_axi_wstrb                ( m_axi_wstrb                         ),
    //b----------------------------------------------------------------
    .m_axi_bid                  ( m_axi_bid                           ),
    .m_axi_bresp                ( m_axi_bresp                         ),
    .m_axi_bvalid               ( m_axi_bvalid                        ),
    .m_axi_bready               ( m_axi_bready                        ),
    //ar---------------------------------------------------------------
    .m_axi_arid                 ( m_axi_arid                          ),
    .m_axi_arlock               ( m_axi_arlock                        ),
    .m_axi_arcache              ( m_axi_arcache                       ),
    .m_axi_arprot               ( m_axi_arprot                        ),
    .m_axi_arqos                ( m_axi_arqos                         ),
    .m_axi_araddr               ( m_axi_araddr                        ),
    .m_axi_arlen                ( m_axi_arlen                         ),
    .m_axi_arsize               ( m_axi_arsize                        ),
    .m_axi_arburst              ( m_axi_arburst                       ),
    .m_axi_arvalid              ( m_axi_arvalid                       ),
    .m_axi_arready              ( m_axi_arready                       ),
    //r----------------------------------------------------------------
    .m_axi_rready               ( m_axi_rready                        ),
    .m_axi_rdata                ( m_axi_rdata                         ),
    .m_axi_rvalid               ( m_axi_rvalid                        ),
    .m_axi_rlast                ( m_axi_rlast                         ),
    .m_axi_rid                  ( m_axi_rid                           ),
    .m_axi_rresp                ( m_axi_rresp                         ),
    
    .layer_cnt                  ( layer_cnt                           ),
    .clk                        ( clk                                 ),
    .reset                      ( reset                               )
  );


  
  //-------------------------------------------------------------------
  //Simulation
  //-------------------------------------------------------------------









endmodule
