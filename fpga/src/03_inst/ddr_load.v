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
// ddr_rstep_num(internal loop)---->continuous cycles burst length
// ddr_rstep    (external loop)---->the number of burst lengths


`include "opu_parameter.vh"
module ddr_load (
  input                             clk                         ,
  input                             reset                       ,
  input   wire                      core_init_finish            ,   
  //ar
  output  reg                       m_axi_arlock  =0            ,
  output  reg   [    4  -1 : 0]     m_axi_arcache =0            ,
  output  reg   [    3  -1 : 0]     m_axi_arprot  =0            ,
  output  reg   [    4  -1 : 0]     m_axi_arqos   =0            ,
  output  reg   [    4  -1 : 0]     m_axi_arid    =0            ,
  output  reg   [    64 -1 : 0]     m_axi_araddr  =0            ,
  output  reg   [    8  -1 : 0]     m_axi_arlen   =0            ,
  output  reg   [    3  -1 : 0]     m_axi_arsize  =0            ,
  output  reg   [    2  -1 : 0]     m_axi_arburst =0            ,
  output  reg                       m_axi_arvalid =0            ,
  input                             m_axi_arready               ,
  //r
  output  reg                       m_axi_rready    =0          ,
  
  input                             m_axi_rvalid                ,
  input                             m_axi_rlast                 ,
  input         [    4  -1 : 0]     m_axi_rid                   ,
  input         [    2  -1 : 0]     m_axi_rresp                 ,
  //data
  output  reg                       ddr_load_vld_ifm     =0     , 
  output  reg                       ddr_load_vld_bm      =0     , 
  output  wire  [2-1:0]             ddr_load_vld_ker            ,
  output  reg                       ddr_load_vld_bias    =0     ,
  output  reg                       ddr_load_vld_res     =0     ,
  output  reg                       ddr_load_vld_ins     =0     ,
  output  reg                       ddr_load_vld_beta    =0     , 
  output  reg                       ddr_load_vld_gamma   =0     , 
  output  reg                       ddr_rdone            =0     ,
  //read
  input                             ddr_rstart                  ,
  input         [      4-1 : 0]     ddr_roffset_high            ,
  input         [     25-1 : 0]     ddr_roffset                 ,
  input         [     25-1 : 0]     ddr_rstride                 ,
  input         [     7 -1 : 0]     ddr_rstep_num               ,  
  input         [     15-1 : 0]     ddr_rstep                   ,
  input         [      4-1 : 0]     ddr_rid                     ,
  input         [     15-1 : 0]     ddr_bm_num                  ,
  input                             ddr_bm_en                   
);



  //-------------------------------------------------------------
  localparam        FIFO_0_DELAY       = 0                       ;
  localparam        FIFO_0_DEEP        = 32                      ;
  localparam        FIFO_0_WIDTH       = 80                      ;
  integer i=0;
  wire [FIFO_0_WIDTH-1:0] u0_fifo_wdata                          ;
  wire                    u0_fifo_wen                            ;
  wire                    u0_fifo_empty                          ;
  reg                     u0_fifo_ren     =0                     ;
  wire [FIFO_0_WIDTH-1:0] u0_fifo_rdata                          ;
  (*keep_hierarchy="yes"*)sync_fifo #(
    .MEM_TYPE              ( "distributed"                       ),
    .RMODE                 ( "fwft"                              ),
    .FEATURES              ( "0002"                              ),
    .RLATENCY              ( FIFO_0_DELAY                        ),            
    .DEPTH                 ( FIFO_0_DEEP                         ),    
    .PFULL_THRESH          ( FIFO_0_DEEP-10                      ),       
    .RWIDTH                ( FIFO_0_WIDTH                        ),
    .WWIDTH                ( FIFO_0_WIDTH                        ),
    .PEMPTY_THRESH         ( 10                                  )
  ) FIFO_load(
    .full                  (                                     ),
    .afull                 (                                     ),
    .pfull                 (                                     ),
    .wdata                 ( u0_fifo_wdata                       ),
    .wen                   ( u0_fifo_wen                         ),
    .aempty                (                                     ),
    .pempty                (                                     ),
    .empty                 ( u0_fifo_empty                       ),
    .rdata                 ( u0_fifo_rdata                       ),
    .ren                   ( u0_fifo_ren                         ),
    .clk                   ( clk                                 ),
    .reset                 ( reset                               )
  );

//------------------------------------------------------------------------------
//read address
//------------------------------------------------------------------------------
  reg  ddr_rstart_r =0 ;
  wire ddr_rstart_frist;
  always @(posedge clk) ddr_rstart_r<=ddr_rstart  ;
  assign ddr_rstart_frist=ddr_rstart&&(~ddr_rstart_r);

  assign u0_fifo_wen   =(~ddr_rstart_frist)&&ddr_rstart;
  assign u0_fifo_wdata =
  {
      ddr_rstart      ,//1
      ddr_roffset_high,//4
      ddr_roffset     ,//25
      ddr_rstride     ,//25
      ddr_rstep_num   ,//7
      ddr_rstep       ,//15
      ddr_rid[2:0]     //3
  };

  wire            unit_rdone            ;
  reg             next_rstart        =0 ;
  reg  [ 4-1 : 0] next_roffset_high  =0 ;
  reg  [25-1 : 0] next_roffset       =0 ;
  reg  [25-1 : 0] next_rstride       =0 ;
  reg  [ 7-1 : 0] next_rstep_num     =0 ;  
  reg  [15-1 : 0] next_rstep         =0 ;
  reg  [ 3-1 : 0] next_rid           =0 ;

  always @(posedge clk)
  if(ddr_rstart_frist)
  begin
        next_roffset_high  <=ddr_roffset_high          ; 
        next_roffset       <=ddr_roffset+ddr_rstride   ;
        next_rstride       <=ddr_rstride               ;
        next_rstep_num     <=ddr_rstep_num-1           ;
        next_rstep         <=ddr_rstep                 ;
        next_rid           <=ddr_rid                   ;
  end
  else if(u0_fifo_ren)
  begin
        next_roffset_high  <=u0_fifo_rdata[78:75]      ;//4  
        next_roffset       <=u0_fifo_rdata[74:50]+u0_fifo_rdata[49:25];//25
        next_rstride       <=u0_fifo_rdata[49:25]      ;//25
        next_rstep_num     <=u0_fifo_rdata[24:18]-1    ;//7 
        next_rstep         <=u0_fifo_rdata[17: 3]      ;//15
        next_rid           <=u0_fifo_rdata[2 : 0]      ;//3 
  end
  else if(next_rstart)
  begin
        next_roffset_high  <=next_roffset_high          ; 
        next_roffset       <=next_roffset+next_rstride  ;
        next_rstride       <=next_rstride               ;
        next_rstep_num     <=next_rstep_num-1           ;
        next_rstep         <=next_rstep                 ;
        next_rid           <=next_rid                   ;
  end


  always @(posedge clk) u0_fifo_ren <=unit_rdone&&(next_rstep_num==0)&&(~u0_fifo_empty);
  always @(posedge clk) next_rstart <=unit_rdone&&(next_rstep_num!=0);
  



  //---------------------------------------------------------------------------
  wire  [64-1:0] araddr_high;
  wire  [64-1:0] araddr_base;
  wire  [64-1:0] fifo_araddr_high;
  wire  [64-1:0] fifo_araddr_base;
  wire  [64-1:0] next_araddr_high;
  wire  [64-1:0] next_araddr_base;
  

  assign  araddr_base     ={32'd0,ddr_roffset         ,6'd0 };
  assign  fifo_araddr_base={32'd0,u0_fifo_rdata[74:50],6'd0 };
  assign  next_araddr_base={32'd0,next_roffset        ,6'd0 };
  
  
  
  always @(posedge clk)
  if(ddr_rstart_frist)
  begin
      m_axi_arlen   <=ddr_rstep-1;
      m_axi_arsize  <=6;
      m_axi_arburst <=1;
      m_axi_arvalid <=1;
      m_axi_arid    <=ddr_rid;
      m_axi_araddr  <=araddr_high+araddr_base;
  end
  else if(u0_fifo_ren)
  begin
      m_axi_arlen   <=u0_fifo_rdata[17:3]-1;
      m_axi_arsize  <=6;
      m_axi_arburst <=1;
      m_axi_arvalid <=1;
      m_axi_arid    <=u0_fifo_rdata[2:0];
      m_axi_araddr  <=fifo_araddr_high+fifo_araddr_base;
  end
  else if(next_rstart)
  begin
      m_axi_arlen   <=next_rstep-1;
      m_axi_arsize  <=6;
      m_axi_arburst <=1;
      m_axi_arvalid <=1;
      m_axi_arid    <=next_rid;
      m_axi_araddr  <=next_araddr_high+next_araddr_base;
  end
  else begin
      m_axi_arvalid <=0;
  end
  
  
  wire     rready_rvalid;
  assign   rready_rvalid = m_axi_rvalid&&m_axi_rready;
  assign   unit_rdone    = m_axi_rvalid&&m_axi_rlast ;
  always @(posedge clk)ddr_rdone<=
  unit_rdone&&(next_rstep_num==0);

  

//------------------------------------------------------------------------------
//read data
//------------------------------------------------------------------------------
  always @(posedge clk)m_axi_rready <=core_init_finish;
  
  reg [11-1:0] bmrcnt  =0;
  always @(posedge clk)
  if(ddr_bm_en)  bmrcnt<=ddr_bm_num;
  else if(rready_rvalid&(m_axi_rid==2))
  begin
    if(bmrcnt==0)bmrcnt<=0         ;
    else         bmrcnt<=bmrcnt-1  ;
  end

  (*dont_touch="true"*)reg [2-1:0] r_ddr_load_vld_ker=0;

  assign ddr_load_vld_ker =r_ddr_load_vld_ker   ;

  always @(posedge clk)
  begin
      ddr_load_vld_ifm   <=  rready_rvalid&(m_axi_rid==1);                   
      ddr_load_vld_bm    <=  rready_rvalid&(m_axi_rid==2)&&(bmrcnt>0);       
      r_ddr_load_vld_ker <=  {2 {rready_rvalid&(m_axi_rid==2)&&(bmrcnt==0)}}; 
      ddr_load_vld_bias  <=  rready_rvalid&(m_axi_rid==3);                   
      ddr_load_vld_res   <=  rready_rvalid&(m_axi_rid==4);                   
      ddr_load_vld_ins   <=  rready_rvalid&(m_axi_rid==5);                   
      ddr_load_vld_beta  <=  rready_rvalid&(m_axi_rid==6);                   
      ddr_load_vld_gamma <=  rready_rvalid&(m_axi_rid==7);                   
  end

  assign  araddr_high     ={28'd0,ddr_roffset_high    ,32'd0};
  assign  fifo_araddr_high={28'd0,u0_fifo_rdata[78:75],32'd0};
  assign  next_araddr_high={28'd0,next_roffset_high   ,32'd0};



endmodule
