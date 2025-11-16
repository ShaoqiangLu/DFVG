`timescale 1ns / 1ps
// -----------------------------------------------------------------------------
// Copyright      : UCLA EDA LAB
// -----------------------------------------------------------------------------
// Engineer       : Chen Wu
// Design Name    : opu series
// Module Name    : ddr_rw_unit
// Target Devices : 325t, Alveo U200
// Tool Versions  : Vivado 2020.1, Modelsim 2019.4
// Description    : 
//    Read DDR in burst mode for one round
//    Write DDR in burst mode for one round
//
// Revision       :
// Version        Date        Author        Descriptin
// 1.0            2020-05-30  Chen Wu       Initial version
// 2.0            2020-09-21  Chen Wu       Modify to control on hardware
// 3.0            2021-02-02  Chen Wu       Modify to have small modules
// 3.1            2021-05-06  Chen Wu       Modify for GCN
// 3.2            2021-11-02  Chen Wu       Delete ID
// 3.3            2022-03-30  Chen Wu       Add write, change module name
// 4.0            2023-08-25  Shaoqiang     Simulation 97 layers,and      
//                                          implementation on FPGA of U200.
// -----------------------------------------------------------------------------


module ddr_store (
  input                            clk                          ,
  input                            reset                        ,
  input   wire                     core_init_finish             ,   
  //aw
  output  reg   [   4  -1: 0]      m_axi_awid           =0      ,
  output  reg                      m_axi_awlock         =0      ,
  output  reg   [   4  -1: 0]      m_axi_awcache        =0      ,
  output  reg   [   3  -1: 0]      m_axi_awprot         =0      ,
  output  reg   [   4  -1: 0]      m_axi_awqos          =0      ,
  output  reg   [   64 -1: 0]      m_axi_awaddr         =0      ,
  output  reg   [   8  -1: 0]      m_axi_awlen          =0      ,
  output  reg   [   3  -1: 0]      m_axi_awsize         =0      ,
  output  reg   [   2  -1: 0]      m_axi_awburst        =0      ,
  output  reg                      m_axi_awvalid        =0      ,
  input                            m_axi_awready                , 
  //w
  output        [   512-1: 0]      m_axi_wdata                  ,
  output        reg                m_axi_wlast  =0              ,
  output                           m_axi_wvalid                 ,
  input                            m_axi_wready                 ,
  output        [   64- 1: 0]      m_axi_wstrb                  ,
  input         [   4  -1: 0]      m_axi_bid                    ,
  input         [   2  -1: 0]      m_axi_bresp                  ,
  input                            m_axi_bvalid                 ,
  output  reg                      m_axi_bready       =0        ,

  output  reg                      ddr_wdone          =0        ,
  input         [     25-1 : 0]    ddr_woffset                  ,
  input         [      4-1 : 0]    ddr_woffset_high             ,
  input         [     15-1 : 0]    ddr_wstep                    ,
  input         [      7-1 : 0]    ddr_wstep_num                ,
  input         [     25-1 : 0]    ddr_wstride                  ,
  
  input                            ddr_wstart                   ,
  input         [    512-1 : 0]    ddr_store_data               ,
  input                            ddr_store_vld               
  );

 //------------------------------------------------------------------
 //
 //------------------------------------------------------------------
  localparam        FIFO_0_DELAY       = 0                      ;
  localparam        FIFO_0_DEEP        = 2048                   ;
  localparam        FIFO_0_WIDTH       = 512                    ;
  wire                      fifo_w_o_empty                      ;
  wire[FIFO_0_WIDTH-1:0]    fifo_w_o_rdata                      ;
  wire                      fifo_w_o_ren                        ;

  (*keep_hierarchy="yes"*)sync_fifo #(
    .MEM_TYPE              ( "block"                            ),
    .RMODE                 ( "fwft"                             ),
    .FEATURES              ( "0002"                             ),
    .RLATENCY              ( FIFO_0_DELAY                       ),            
    .DEPTH                 ( FIFO_0_DEEP                        ),    
    .PFULL_THRESH          ( FIFO_0_DEEP-10                     ),       
    .RWIDTH                ( FIFO_0_WIDTH                       ),
    .WWIDTH                ( FIFO_0_WIDTH                       ),
    .PEMPTY_THRESH         ( 10                                 )
  ) FIFO_store(
    .aempty                (                                    ),
    .pempty                (                                    ),
    .empty                 ( fifo_w_o_empty                     ),
    .rdata                 ( fifo_w_o_rdata                     ),
    .ren                   ( fifo_w_o_ren                       ),  
    .afull                 (                                    ),
    .pfull                 (                                    ),
    .full                  (                                    ),
    .wdata                 ( ddr_store_data                     ),
    .wen                   ( ddr_store_vld                      ),
    .clk                   ( clk                                ),
    .reset                 ( reset                              )
  );


  //---------------------------------------------------------------------------
  // ddr write
  //---------------------------------------------------------------------------
  reg [2 -1 : 0] r_ddr_wstart         =0;
  reg            next_ddr_wstart      =0;
  reg [25-1 : 0] next_ddr_woffset     =0;
  reg [ 4-1 : 0] next_ddr_woffset_high=0;
  reg [15-1 : 0] next_ddr_wstep       =0;
  reg [ 7-1 : 0] next_ddr_wstep_num   =0;
  reg [25-1 : 0] next_ddr_wstride     =0;
  reg [16-1 : 0] ddr_wack_cnt         =0;
  reg            ddr_wack_ctrl        =0;
  reg            ddr_wack_wdone       =0;

  always @(posedge clk)
  r_ddr_wstart<={2{ddr_wstart}};

  always @(posedge clk)
  if(r_ddr_wstart[0])  
  begin
       next_ddr_woffset       <= ddr_woffset+ddr_wstride;
       next_ddr_woffset_high  <= ddr_woffset_high;
       next_ddr_wstep         <= ddr_wstep       ;
       next_ddr_wstep_num     <= ddr_wstep_num-1 ;
       next_ddr_wstride       <= ddr_wstride     ;
  end
  else if(next_ddr_wstart)  
  begin
       next_ddr_woffset       <= next_ddr_woffset+next_ddr_wstride;
       next_ddr_woffset_high  <= next_ddr_woffset_high;
       next_ddr_wstep         <= next_ddr_wstep       ;
       next_ddr_wstep_num     <= next_ddr_wstep_num-1 ;
       next_ddr_wstride       <= next_ddr_wstride     ;
  end 
  else if(ddr_wdone)
  begin
       next_ddr_woffset       <= 0;
       next_ddr_woffset_high  <= 0;
       next_ddr_wstep         <= 0;
       next_ddr_wstep_num     <= 0;
       next_ddr_wstride       <= 0;
  end
  
  
  
  //-----------------------------------------------------------------
  wire  [63:0] next_awaddr_high  ={28'd0,next_ddr_woffset_high,32'd0};
  wire  [63:0] next_awaddr_base  ={26'd0,next_ddr_woffset      ,6'd0};
  wire  [63:0] awaddr_high  ={28'd0,ddr_woffset_high,32'd0};
  wire  [63:0] awaddr_base  ={26'd0,ddr_woffset      ,6'd0};

  always @(posedge clk)
  if(r_ddr_wstart[1])
  begin
    m_axi_awaddr   <=awaddr_high +awaddr_base ;
    m_axi_awlen    <=ddr_wstep-1; 
    m_axi_awsize   <=6 ;
    m_axi_awburst  <=1 ;
    m_axi_awvalid  <=1 ;
  end else if(next_ddr_wstart)
  begin
    m_axi_awaddr   <=next_awaddr_high+next_awaddr_base;
    m_axi_awlen    <=next_ddr_wstep-1; 
    m_axi_awsize   <=6 ;
    m_axi_awburst  <=1 ;
    m_axi_awvalid  <=1 ;
  end else begin
    m_axi_awaddr   <=0 ;
    m_axi_awlen    <=0 ; 
    m_axi_awsize   <=0 ;
    m_axi_awburst  <=0 ;
    m_axi_awvalid  <=0 ;
  end
  
  //--------------------------------------------------------------------------
  //Write Counter
  //--------------------------------------------------------------------------
  
  
  always @(posedge clk)
  if(m_axi_awvalid)                   ddr_wack_cnt<=m_axi_awlen+1 ;
  else if(ddr_wack_cnt==0)            ddr_wack_cnt<=ddr_wack_cnt  ;
  else if(m_axi_wvalid&&m_axi_wready) ddr_wack_cnt<=ddr_wack_cnt-1;
  
  always @(posedge clk)
  if(m_axi_awvalid)                   ddr_wack_ctrl<=1;
  else if(ddr_wack_cnt==1)            ddr_wack_ctrl<=0;
  
  
  
  assign m_axi_wvalid =m_axi_wready&&fifo_w_o_ren;
  assign m_axi_wdata  =fifo_w_o_rdata;
  always @(posedge clk)m_axi_wlast<=(ddr_wack_cnt==2);
  assign m_axi_wstrb  ={64{1'b1}};
  
  always @(posedge clk)m_axi_bready<= core_init_finish;
  always @(posedge clk)ddr_wack_wdone<=m_axi_bvalid&m_axi_bready;
  
  
  always @(posedge clk)
  if(next_ddr_wstep_num==0) 
       ddr_wdone<=ddr_wack_wdone;
  else next_ddr_wstart<=ddr_wack_wdone;
  
  assign fifo_w_o_ren=m_axi_wready&&(~fifo_w_o_empty)&&ddr_wack_ctrl;


endmodule
