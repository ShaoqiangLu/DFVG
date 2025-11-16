`timescale 1ns / 1ps
// -----------------------------------------------------------------------------
// Copyright      : UCLA EDA LAB
// -----------------------------------------------------------------------------
// Engineer       : Chen Wu
// Design Name    : opu series
// Module Name    : fake_ddr4
// Target Devices : 325t, Alveo U200
// Tool Versions  : Vivado 2020.1, Modelsim 2019.4
// Description    : 
//    Fake DDR4 read/write, only used for simulation to speed up, not check
//    write last signal
//
// Revision       :
// Version        Date        Author        Descriptin
// 1.0            2021-10-30  Chen Wu       Initial version
// 2.0            2023-11-30  Shaoqiang     Simulation 97 layers,and
//                                          implementation on FPGA of U200.
// -----------------------------------------------------------------------------

`include "opu_parameter.vh"
module tb_fake_ddr4 #( 
parameter ddr_file = "/12_data/sim_com/dram_data_97.txt",
parameter ID_DW    =7
)
(
  input         [ID_DW  -1 : 0]     m_axi_awid                  ,
  input                             m_axi_awlock                ,
  input         [    4  -1 : 0]     m_axi_awcache               ,
  input         [    3  -1 : 0]     m_axi_awprot                ,
  input         [    4  -1 : 0]     m_axi_awqos                 ,
  input         [    64 -1 : 0]     m_axi_awaddr                ,
  input         [    8  -1 : 0]     m_axi_awlen                 ,
  input         [    3  -1 : 0]     m_axi_awsize                ,
  input         [    2  -1 : 0]     m_axi_awburst               ,
  input                             m_axi_awvalid               ,
  output  reg                       m_axi_awready               ,
  //w
  input         [    512-1 : 0]     m_axi_wdata                 ,
  input                             m_axi_wlast                 ,
  input                             m_axi_wvalid                ,
  output  reg                       m_axi_wready                ,
  input         [    64- 1 : 0]     m_axi_wstrb                 ,
  //b
  output  reg   [ID_DW  -1 : 0]     m_axi_bid                   ,
  output  reg   [    2  -1 : 0]     m_axi_bresp                 ,
  output  reg                       m_axi_bvalid                ,
  input                             m_axi_bready                ,
  //ar
  input         [ID_DW  -1 : 0]     m_axi_arid                  ,
  input                             m_axi_arlock                ,
  input         [    4  -1 : 0]     m_axi_arcache               ,
  input         [    3  -1 : 0]     m_axi_arprot                ,
  input         [    4  -1 : 0]     m_axi_arqos                 ,
  input         [    64 -1 : 0]     m_axi_araddr                ,
  input         [    8  -1 : 0]     m_axi_arlen                 ,
  input         [    3  -1 : 0]     m_axi_arsize                ,
  input         [    2  -1 : 0]     m_axi_arburst               ,
  input                             m_axi_arvalid               ,
  output  wire                      m_axi_arready               ,
  //r
  input                             m_axi_rready                ,
  output  wire  [    512-1 : 0]     m_axi_rdata                 ,
  output  wire                      m_axi_rvalid                ,
  output  wire                      m_axi_rlast                 ,
  output  wire  [ID_DW  -1 : 0]     m_axi_rid                   ,
  output  wire  [    2  -1 : 0]     m_axi_rresp                 ,
  input                             clk                         ,
  input                             reset                     
);

  // ---------------------------------------------------------------------------
  // A register for DDR4,For simulation purposes
  // --------------------------------------------------------------------------- 
  localparam        DEEP            =   6000000         ;//97 layer
  reg  [512-1:0]    DDR4_MEM            [0:DEEP]        ;
  reg  [512-1:0]    DDR4_MEM_r          [0:DEEP]        ;
  wire [512-1:0]    DDR4_MEM_row0   =   DDR4_MEM[0]     ;
  wire [512-1:0]    DDR4_MEM_row1   =   DDR4_MEM[1]     ;
  wire [512-1:0]    DDR4_MEM_row2   =   DDR4_MEM[2]     ;
  wire [512-1:0]    DDR4_MEM_row3   =   DDR4_MEM[3]     ;
  wire [512-1:0]    DDR4_MEM_row4   =   DDR4_MEM[4]     ;
  
`ifdef INST_DATA_TXT
  initial
  begin
          $readmemb ({ddr_file,".txt"}, DDR4_MEM_r      ); 
          for(int i=0;i<=DEEP;i=i+1)
          begin
              DDR4_MEM[i][16*0 +:16]=DDR4_MEM_r[i][16*31+:16];
              DDR4_MEM[i][16*1 +:16]=DDR4_MEM_r[i][16*30+:16];
              DDR4_MEM[i][16*2 +:16]=DDR4_MEM_r[i][16*29+:16];
              DDR4_MEM[i][16*3 +:16]=DDR4_MEM_r[i][16*28+:16];
              DDR4_MEM[i][16*4 +:16]=DDR4_MEM_r[i][16*27+:16];
              DDR4_MEM[i][16*5 +:16]=DDR4_MEM_r[i][16*26+:16];
              DDR4_MEM[i][16*6 +:16]=DDR4_MEM_r[i][16*25+:16];
              DDR4_MEM[i][16*7 +:16]=DDR4_MEM_r[i][16*24+:16]; 
              DDR4_MEM[i][16*8 +:16]=DDR4_MEM_r[i][16*23+:16];
              DDR4_MEM[i][16*9 +:16]=DDR4_MEM_r[i][16*22+:16];
              DDR4_MEM[i][16*10+:16]=DDR4_MEM_r[i][16*21+:16];
              DDR4_MEM[i][16*11+:16]=DDR4_MEM_r[i][16*20+:16];
              DDR4_MEM[i][16*12+:16]=DDR4_MEM_r[i][16*19+:16];
              DDR4_MEM[i][16*13+:16]=DDR4_MEM_r[i][16*18+:16];
              DDR4_MEM[i][16*14+:16]=DDR4_MEM_r[i][16*17+:16];
              DDR4_MEM[i][16*15+:16]=DDR4_MEM_r[i][16*16+:16]; 
              DDR4_MEM[i][16*16+:16]=DDR4_MEM_r[i][16*15+:16];
              DDR4_MEM[i][16*17+:16]=DDR4_MEM_r[i][16*14+:16];
              DDR4_MEM[i][16*18+:16]=DDR4_MEM_r[i][16*13+:16];
              DDR4_MEM[i][16*19+:16]=DDR4_MEM_r[i][16*12+:16];
              DDR4_MEM[i][16*20+:16]=DDR4_MEM_r[i][16*11+:16];
              DDR4_MEM[i][16*21+:16]=DDR4_MEM_r[i][16*10+:16];
              DDR4_MEM[i][16*22+:16]=DDR4_MEM_r[i][16*9 +:16];
              DDR4_MEM[i][16*23+:16]=DDR4_MEM_r[i][16*8 +:16]; 
              DDR4_MEM[i][16*24+:16]=DDR4_MEM_r[i][16*7 +:16];
              DDR4_MEM[i][16*25+:16]=DDR4_MEM_r[i][16*6 +:16];
              DDR4_MEM[i][16*26+:16]=DDR4_MEM_r[i][16*5 +:16];
              DDR4_MEM[i][16*27+:16]=DDR4_MEM_r[i][16*4 +:16];
              DDR4_MEM[i][16*28+:16]=DDR4_MEM_r[i][16*3 +:16];
              DDR4_MEM[i][16*29+:16]=DDR4_MEM_r[i][16*2 +:16];
              DDR4_MEM[i][16*30+:16]=DDR4_MEM_r[i][16*1 +:16];
              DDR4_MEM[i][16*31+:16]=DDR4_MEM_r[i][16*0 +:16]; 
          end       
  end
`else
  integer file;
  initial
  begin
    file =$fopen    ({ddr_file,".bin"},"r"              );
          $fread    (DDR4_MEM_r,file                    );
          $fclose   (file                               );  
          for(int i=0;i<=DEEP;i=i+1)
          begin
              DDR4_MEM[i][16*0 +:16]=DDR4_MEM_r[i][16*31+:16];
              DDR4_MEM[i][16*1 +:16]=DDR4_MEM_r[i][16*30+:16];
              DDR4_MEM[i][16*2 +:16]=DDR4_MEM_r[i][16*29+:16];
              DDR4_MEM[i][16*3 +:16]=DDR4_MEM_r[i][16*28+:16];
              DDR4_MEM[i][16*4 +:16]=DDR4_MEM_r[i][16*27+:16];
              DDR4_MEM[i][16*5 +:16]=DDR4_MEM_r[i][16*26+:16];
              DDR4_MEM[i][16*6 +:16]=DDR4_MEM_r[i][16*25+:16];
              DDR4_MEM[i][16*7 +:16]=DDR4_MEM_r[i][16*24+:16]; 
              DDR4_MEM[i][16*8 +:16]=DDR4_MEM_r[i][16*23+:16];
              DDR4_MEM[i][16*9 +:16]=DDR4_MEM_r[i][16*22+:16];
              DDR4_MEM[i][16*10+:16]=DDR4_MEM_r[i][16*21+:16];
              DDR4_MEM[i][16*11+:16]=DDR4_MEM_r[i][16*20+:16];
              DDR4_MEM[i][16*12+:16]=DDR4_MEM_r[i][16*19+:16];
              DDR4_MEM[i][16*13+:16]=DDR4_MEM_r[i][16*18+:16];
              DDR4_MEM[i][16*14+:16]=DDR4_MEM_r[i][16*17+:16];
              DDR4_MEM[i][16*15+:16]=DDR4_MEM_r[i][16*16+:16]; 
              DDR4_MEM[i][16*16+:16]=DDR4_MEM_r[i][16*15+:16];
              DDR4_MEM[i][16*17+:16]=DDR4_MEM_r[i][16*14+:16];
              DDR4_MEM[i][16*18+:16]=DDR4_MEM_r[i][16*13+:16];
              DDR4_MEM[i][16*19+:16]=DDR4_MEM_r[i][16*12+:16];
              DDR4_MEM[i][16*20+:16]=DDR4_MEM_r[i][16*11+:16];
              DDR4_MEM[i][16*21+:16]=DDR4_MEM_r[i][16*10+:16];
              DDR4_MEM[i][16*22+:16]=DDR4_MEM_r[i][16*9 +:16];
              DDR4_MEM[i][16*23+:16]=DDR4_MEM_r[i][16*8 +:16]; 
              DDR4_MEM[i][16*24+:16]=DDR4_MEM_r[i][16*7 +:16];
              DDR4_MEM[i][16*25+:16]=DDR4_MEM_r[i][16*6 +:16];
              DDR4_MEM[i][16*26+:16]=DDR4_MEM_r[i][16*5 +:16];
              DDR4_MEM[i][16*27+:16]=DDR4_MEM_r[i][16*4 +:16];
              DDR4_MEM[i][16*28+:16]=DDR4_MEM_r[i][16*3 +:16];
              DDR4_MEM[i][16*29+:16]=DDR4_MEM_r[i][16*2 +:16];
              DDR4_MEM[i][16*30+:16]=DDR4_MEM_r[i][16*1 +:16];
              DDR4_MEM[i][16*31+:16]=DDR4_MEM_r[i][16*0 +:16]; 
          end  
  end
`endif






//  reg           [    512-1 : 0]     DDR4_MEM_r[0:DEEP]          ;
//  reg           [    512-1 : 0]     DDR4_MEM  [0:DEEP]          ;
  

//  initial 
//  begin
////    $readmemh(ddr_file, DDR4_MEM_r)                           ;  
//     

/*

*/
    
//  end

  
  wire                              fifo0_i_full                ;
  wire                              fifo0_i_push                ;    
  wire          [      71  : 0]     fifo0_i_data                ;    
  wire                              fifo0_o_empty               ;
  wire                              fifo0_o_pop                 ;  
  wire          [      71  : 0]     fifo0_o_data                ;
  reg                               rrunning                    ;
  wire                              gen_raddr_done              ;
  reg           [       31 : 0]     rbase_addr      = 0         ;
  reg           [        8 : 0]     rlen            = 0         ;
  reg           [       31 : 0]     raddr_incr      = 0         ;
  wire          [       32 : 0]     fifo1_i_data                ;
  reg                               fifo1_i_push                ; 
  wire                              fifo1_i_full                ;
  wire                              fifo1_o_empty               ; 
  wire                              fifo1_o_pop                 ;   
  wire          [       32 : 0]     fifo1_o_data                ;
  wire          [       511: 0]     r_m_axi_rdata               ; 
  reg           [      15  : 0]     rcnt_in=0                   ;
  reg           [      511 : 0]     MEM_rdata[64:1]             ;
  reg           [       15 : 0]     rcnt_out=0                  ;
  reg                               rcnt_out_vld=0              ;
  wire                              r_m_axi_rvalid              ;
  wire                              r_m_axi_rlast               ;  
  //------------------------------------------------------------
  wire                              fifo2_i_full                ;
  wire                              fifo2_i_push                ;   
  wire          [       71 : 0]     fifo2_i_data                ;    
  wire                              fifo2_o_empty               ;
  wire                              fifo2_o_pop                 ;  
  wire          [       71 : 0]     fifo2_o_data                ; 
  reg                               wrunning                    ;
  wire                              gen_waddr_done              ;
  reg           [       31 : 0]     wbase_addr      = 0         ;
  reg           [        8 : 0]     wlen = 0                    ;
  reg           [       31 : 0]     waddr_incr      = 0         ;
  wire          [       32 : 0]     fifo3_i_data                ;  
  reg                               fifo3_i_push                ;   
  wire                              fifo3_i_full                ;
  reg                               w_start_flay    = 0         ;
  reg           [        9 : 0]     w_cnt_wready    = 0         ;
  reg           [        9 : 0]     w_mem_wctrl     = 0         ;
  wire          [      512 : 0]     fifo4_i_data                ;   
  wire                              fifo4_i_push                ; 
  wire                              fifo4_i_full                ;
  wire                              fifo4_o_empty               ;
  wire                              fifo4_o_pop                 ;  
  wire          [      512 : 0]     fifo4_o_data                ;
  wire          [       32 : 0]     fifo3_o_data                ;
  wire                              fifo3_o_pop                 ;   
  wire                              fifo3_o_empty               ;
 


  //--------------------------------------------------------------------
  always @(posedge clk)
  if(m_axi_arvalid&m_axi_arready)rcnt_in<= m_axi_arlen+1         ;
  else if(rcnt_in==0)           rcnt_in<= rcnt_in               ;
  else if(r_m_axi_rvalid)       rcnt_in<= rcnt_in-1             ;//64-->1
  
  always @(rcnt_in,r_m_axi_rvalid,r_m_axi_rdata) 
  if(r_m_axi_rvalid) MEM_rdata[rcnt_in]<=r_m_axi_rdata          ;
  
  task task_63 ;
    repeat(1 )@(posedge clk)begin rcnt_out<=m_axi_arlen+1; rcnt_out_vld=1;  end//64
    repeat(13)@(posedge clk)begin rcnt_out<=rcnt_out-1   ; rcnt_out_vld=1;  end//63-51
    repeat(7 )@(posedge clk)begin rcnt_out<=rcnt_out     ; rcnt_out_vld=0;  end 
    repeat(7 )@(posedge clk)begin rcnt_out<=rcnt_out-1   ; rcnt_out_vld=1;  end//50-44
    repeat(6 )@(posedge clk)begin rcnt_out<=rcnt_out     ; rcnt_out_vld=0;  end
    repeat(12)@(posedge clk)begin rcnt_out<=rcnt_out-1   ; rcnt_out_vld=1;  end //43-32
    repeat(8 )@(posedge clk)begin rcnt_out<=rcnt_out     ; rcnt_out_vld=0;  end
    repeat(2 )@(posedge clk)begin rcnt_out<=rcnt_out-1   ; rcnt_out_vld=1;  end//31-30
    repeat(4 )@(posedge clk)begin rcnt_out<=rcnt_out     ; rcnt_out_vld=0;  end
    repeat(9 )@(posedge clk)begin rcnt_out<=rcnt_out-1   ; rcnt_out_vld=1;  end//29-21
    repeat(7 )@(posedge clk)begin rcnt_out<=rcnt_out     ; rcnt_out_vld=0;  end
    repeat(2 )@(posedge clk)begin rcnt_out<=rcnt_out-1   ; rcnt_out_vld=1;  end//20-19
    repeat(9 )@(posedge clk)begin rcnt_out<=rcnt_out     ; rcnt_out_vld=0;  end
    repeat(5 )@(posedge clk)begin rcnt_out<=rcnt_out-1   ; rcnt_out_vld=1;  end//18-14
    repeat(6 )@(posedge clk)begin rcnt_out<=rcnt_out     ; rcnt_out_vld=0;  end
    repeat(8 )@(posedge clk)begin rcnt_out<=rcnt_out-1   ; rcnt_out_vld=1;  end//13-6
    repeat(8 )@(posedge clk)begin rcnt_out<=rcnt_out     ; rcnt_out_vld=0;  end
    repeat(2 )@(posedge clk)begin rcnt_out<=rcnt_out-1   ; rcnt_out_vld=1;  end//5-4
    repeat(6 )@(posedge clk)begin rcnt_out<=rcnt_out     ; rcnt_out_vld=0;  end
    repeat(2 )@(posedge clk)begin rcnt_out<=rcnt_out-1   ; rcnt_out_vld=1;  end//3-1
    repeat(10)@(posedge clk)begin rcnt_out<=rcnt_out     ; rcnt_out_vld=0;  end
    repeat(1 )@(posedge clk)begin rcnt_out<=rcnt_out-1   ; rcnt_out_vld=1;  end//1
    repeat(1 )@(posedge clk)begin rcnt_out<=rcnt_out-1   ; rcnt_out_vld=0;  end//0
  endtask

  task task_31 ;
    repeat(1 )@(posedge clk)begin rcnt_out<=m_axi_arlen+1; rcnt_out_vld=1;  end//32
    repeat(13)@(posedge clk)begin rcnt_out<=rcnt_out-1   ; rcnt_out_vld=1;  end//31-19
    repeat(9 )@(posedge clk)begin rcnt_out<=rcnt_out     ; rcnt_out_vld=0;  end 
    repeat(7 )@(posedge clk)begin rcnt_out<=rcnt_out-1   ; rcnt_out_vld=1;  end//18-12
    repeat(10)@(posedge clk)begin rcnt_out<=rcnt_out     ; rcnt_out_vld=0;  end
    repeat(4 )@(posedge clk)begin rcnt_out<=rcnt_out-1   ; rcnt_out_vld=1;  end//11-8
    repeat(9 )@(posedge clk)begin rcnt_out<=rcnt_out     ; rcnt_out_vld=0;  end
    repeat(2 )@(posedge clk)begin rcnt_out<=rcnt_out-1   ; rcnt_out_vld=1;  end//7-6
    repeat(9 )@(posedge clk)begin rcnt_out<=rcnt_out     ; rcnt_out_vld=0;  end
    repeat(2 )@(posedge clk)begin rcnt_out<=rcnt_out-1   ; rcnt_out_vld=1;  end//5-4
    repeat(4 )@(posedge clk)begin rcnt_out<=rcnt_out     ; rcnt_out_vld=0;  end
    repeat(2 )@(posedge clk)begin rcnt_out<=rcnt_out-1   ; rcnt_out_vld=1;  end//3-2
    repeat(9 )@(posedge clk)begin rcnt_out<=rcnt_out     ; rcnt_out_vld=0;  end
    repeat(1 )@(posedge clk)begin rcnt_out<=rcnt_out-1   ; rcnt_out_vld=1;  end//1
    repeat(1 )@(posedge clk)begin rcnt_out<=rcnt_out-1   ; rcnt_out_vld=0;  end//0
  endtask

  task task_1 ;
    repeat(1 )@(posedge clk)begin rcnt_out<=m_axi_arlen+1; rcnt_out_vld=1;  end//2
    repeat(3 )@(posedge clk)begin rcnt_out<=rcnt_out     ; rcnt_out_vld=0;  end 
    repeat(1 )@(posedge clk)begin rcnt_out<=rcnt_out-1   ; rcnt_out_vld=1;  end//1
    repeat(1 )@(posedge clk)begin rcnt_out<=rcnt_out-1   ; rcnt_out_vld=0;  end//0
  endtask

  task task_23 ;
    repeat(1 )@(posedge clk)begin rcnt_out<=m_axi_arlen+1; rcnt_out_vld=1;  end//24
    repeat(9 )@(posedge clk)begin rcnt_out<=rcnt_out-1   ; rcnt_out_vld=1;  end//23-15
    repeat(9 )@(posedge clk)begin rcnt_out<=rcnt_out     ; rcnt_out_vld=0;  end 
    repeat(3 )@(posedge clk)begin rcnt_out<=rcnt_out-1   ; rcnt_out_vld=1;  end//14-12
    repeat(12)@(posedge clk)begin rcnt_out<=rcnt_out     ; rcnt_out_vld=0;  end
    repeat(4 )@(posedge clk)begin rcnt_out<=rcnt_out-1   ; rcnt_out_vld=1;  end//11-8
    repeat(9 )@(posedge clk)begin rcnt_out<=rcnt_out     ; rcnt_out_vld=0;  end
    repeat(2 )@(posedge clk)begin rcnt_out<=rcnt_out-1   ; rcnt_out_vld=1;  end//7-6
    repeat(8 )@(posedge clk)begin rcnt_out<=rcnt_out     ; rcnt_out_vld=0;  end
    repeat(2 )@(posedge clk)begin rcnt_out<=rcnt_out-1   ; rcnt_out_vld=1;  end//5-4
    repeat(13)@(posedge clk)begin rcnt_out<=rcnt_out     ; rcnt_out_vld=0;  end
    repeat(2 )@(posedge clk)begin rcnt_out<=rcnt_out-1   ; rcnt_out_vld=1;  end//3-2
    repeat(6 )@(posedge clk)begin rcnt_out<=rcnt_out     ; rcnt_out_vld=0;  end
    repeat(1 )@(posedge clk)begin rcnt_out<=rcnt_out-1   ; rcnt_out_vld=1;  end//1
    repeat(1 )@(posedge clk)begin rcnt_out<=rcnt_out-1   ; rcnt_out_vld=0;  end//0
  endtask

  /*
  //--------------------------------------------------------------
  always @(*) if(r_m_axi_rlast)
  begin  
         if(m_axi_arlen==63) task_63                            ;
    else if(m_axi_arlen==31) task_31                            ;
    else if(m_axi_arlen==1 ) task_1                             ;
    else if(m_axi_arlen==23) task_23                            ;
  end
  //--------------------------------------------------------------
  */
  localparam   DDR_delay =   1                  ;//20
  reg [10:0] raddr_delay =0;
  always @(posedge clk)
  if(m_axi_arvalid) raddr_delay<=DDR_delay;
  else if(raddr_delay==0)raddr_delay<=0;
  else raddr_delay<=raddr_delay-1;

  reg [7:0] m_axi_arlen_r =0;
  always @(posedge clk)
  if(m_axi_arvalid) m_axi_arlen_r <=m_axi_arlen;

  always @(posedge clk)
  if(raddr_delay==1)rcnt_out=m_axi_arlen_r+1;
  else if(rcnt_out==0)rcnt_out<=0;
  else if(r_m_axi_rvalid)rcnt_out<=rcnt_out-1;
  
  always @(rcnt_out,r_m_axi_rvalid) 
  if(rcnt_out>=1 && rcnt_out<=64 && r_m_axi_rvalid)
  rcnt_out_vld=1;
  else rcnt_out_vld=0;
  
  
  reg [ID_DW-1:0]r_m_axi_arid=0;
  always @(posedge clk) if(m_axi_arvalid&m_axi_arready)r_m_axi_arid<=m_axi_arid;
  
  
  assign   m_axi_rvalid=rcnt_out_vld                            ;
  assign   m_axi_rdata =rcnt_out_vld?MEM_rdata[rcnt_out]:0      ;
  assign   m_axi_rlast =rcnt_out_vld?(rcnt_out==1)      :0      ;
  assign   m_axi_rid   =rcnt_out_vld?r_m_axi_arid:0             ;
  assign   m_axi_rresp =0                                       ;


  //---------------------------------------------------------------------------
  // Read
  //---------------------------------------------------------------------------
  // addr, len -> st_fifo -> addr -> addr_fifo
  // address generation
  // store accepted address & length to fifo

  
  reg read_runing=0;
  always @(posedge clk)
  if(m_axi_rlast)       read_runing<=0;
  else if(m_axi_arvalid)read_runing<=1;

  assign m_axi_arready =~read_runing;


  assign fifo0_i_push  =m_axi_arready && m_axi_arvalid          ;
  assign fifo0_i_data  =fifo0_i_push?{m_axi_arlen,m_axi_araddr}:0;
  //--------------------------------------------------------------
  // generate address according to base address and length
  //--------------------------------------------------------------
/*
  localparam        FIFO_0_DELAY       = 0                      ;
  localparam        FIFO_0_DEEP        = 1024                   ;
  localparam        FIFO_0_WIDTH       = 72                     ;
  sync_fifo #(
    .MEM_TYPE         ( "auto"                                  ),
    .RLATENCY         ( FIFO_0_DELAY                            ),
    .DEPTH            ( FIFO_0_DEEP                             ),
    .PEMPTY_THRESH    ( 10                                      ),
    .PFULL_THRESH     ( FIFO_0_DEEP-10                          ),
    .RWIDTH           ( FIFO_0_WIDTH                            ),
    .WWIDTH           ( FIFO_0_WIDTH                            ),
    .RMODE            ( "fwft"                                  ),
    .FEATURES         ( "0000"                                  )
  ) FIFO0_r_addr (
    .aempty           (                                         ),
    .pempty           (                                         ),
    .empty            ( fifo0_o_empty                           ),
    .rdata            ( fifo0_o_data                            ),
    .ren              ( fifo0_o_pop                             ),
    .afull            (                                         ),
    .pfull            (                                         ),
    .full             ( fifo0_i_full                            ),//0
    .wdata            ( fifo0_i_data                            ),
    .wen              ( fifo0_i_push                            ),
    .clk              ( clk                                     ),
    .reset            ( reset                                   )
  );
  assign fifo0_o_pop=(~fifo0_o_empty)&rrunning&(~fifo1_i_full)  ;
*/
  assign fifo0_i_full =0;//-------
  assign fifo0_o_empty=0;
  
  
  assign fifo0_o_data  =fifo0_i_data;
  assign fifo0_o_pop   =fifo0_i_push   ;
  
  
  always @(posedge clk)
  if (reset)              rrunning <= 1'b1                      ;
  else if (fifo0_o_pop)   rrunning <= 1'b0                      ;
  else if (gen_raddr_done)rrunning <= 1'b1                      ;
  
  always @(posedge clk)
  if (fifo0_o_pop) begin
      rbase_addr    <=    (~fifo0_o_pop)?0:fifo0_o_data[37:6]   ;
      rlen          <=    (~fifo0_o_pop)?0:fifo0_o_data[71:64]+1;
  end
  
  always @(posedge clk)
  if (fifo0_o_pop)             raddr_incr<=32'h0                ;
  else if (raddr_incr+1<rlen)  raddr_incr<=raddr_incr + 1       ;
  assign gen_raddr_done   = raddr_incr+1==rlen                  ;


  always @(posedge clk)
  if(reset)                 fifo1_i_push<=1'b0                  ;
  else if (fifo0_o_pop)     fifo1_i_push<=1'b1                  ;
  else if (gen_raddr_done)  fifo1_i_push<=1'b0                  ;
  
  assign fifo1_i_data = fifo1_i_push?{gen_raddr_done, 
                        rbase_addr+raddr_incr}:0                ;

  //-------------------------------------------------------------
  // data generation, read from fifo to get address, then get data
  //-------------------------------------------------------------
`ifdef BYPASS_AXI
  reg                       r_fifo1_o_pop                       ;   
  reg          [32 : 0]     r_fifo1_o_data                      ;
  always @(posedge clk)
  begin
  r_fifo1_o_pop  <= fifo1_i_push       ;
  r_fifo1_o_data <= fifo1_i_data       ;
  end
  assign  fifo1_o_pop  = r_fifo1_o_pop ;
  assign  fifo1_o_data = r_fifo1_o_data;
  
  assign  fifo1_o_empty=0;
  assign  fifo1_i_full =0;
`else
  assign  fifo1_o_pop     = (~fifo1_o_empty) && m_axi_rready    ;
  localparam        FIFO_1_DELAY       = 0                      ;
  localparam        FIFO_1_DEEP        = 2048                   ;
  localparam        FIFO_1_WIDTH       = 33                     ;
  sync_fifo #(
    .MEM_TYPE         ( "auto"                                  ),
    .RLATENCY         ( FIFO_1_DELAY                            ),
    .DEPTH            ( FIFO_1_DEEP                             ),
    .PEMPTY_THRESH    ( 10                                      ),
    .PFULL_THRESH     ( FIFO_1_DEEP-10                          ),
    .RWIDTH           ( FIFO_1_WIDTH                            ),
    .WWIDTH           ( FIFO_1_WIDTH                            ),
    .RMODE            ( "fwft"                                  ),
    .FEATURES         ( "0000"                                  )
  ) FIFO1_r_incr (
    .aempty           (                                         ),
    .pempty           (                                         ),
    .empty            ( fifo1_o_empty                           ),
    .rdata            ( fifo1_o_data                            ),
    .ren              ( fifo1_o_pop                             ),
    .afull            (                                         ),
    .pfull            (                                         ),
    .full             ( fifo1_i_full                            ),
    .wdata            ( fifo1_i_data                            ),
    .wen              ( fifo1_i_push                            ),
    .clk              ( clk                                     ),
    .reset            ( reset                                   )
  );

`endif





  
  
  
  assign  r_m_axi_rdata   = DDR4_MEM[(~fifo1_o_pop)?0:fifo1_o_data[31:0]]        ;
  assign  r_m_axi_rvalid  = fifo1_o_pop                         ;
  assign  r_m_axi_rlast   = (~fifo1_o_pop)?0:fifo1_o_data[32]                    ;


 //--------------------------------------------------------------------------
 // write
 //-------------------------------------------------------------------------
 // addr, len -> st_fifo -> addr -> addr_fifo
 // data -> data_fifo 
 // read at the same time when addr_fifo and data_fifo are not empty
  always @(posedge clk)   m_axi_awready<=~fifo2_i_full          ;
  
  assign  fifo2_i_push  = m_axi_awready && m_axi_awvalid        ;
  assign  fifo2_i_data  = fifo2_i_push?{m_axi_awlen, m_axi_awaddr}:0;
  

  //-------------------------------------------------------------
  // generate address according to base address and length
  //-------------------------------------------------------------
  

  assign fifo2_i_full =0;
  assign fifo2_o_data =fifo2_i_data;
  assign fifo2_o_pop  =fifo2_i_push;
  /*
  localparam        FIFO_2_DELAY       = 0                      ;
  localparam        FIFO_2_DEEP        = 1024                   ;
  localparam        FIFO_2_WIDTH       = 72                     ;
  sync_fifo #(
    .MEM_TYPE         ( "auto"                                  ),
    .RLATENCY         ( FIFO_2_DELAY                            ),
    .DEPTH            ( FIFO_2_DEEP                             ),
    .PEMPTY_THRESH    ( 10                                      ),
    .PFULL_THRESH     ( FIFO_2_DEEP-10                          ),
    .RWIDTH           ( FIFO_2_WIDTH                            ),
    .WWIDTH           ( FIFO_2_WIDTH                            ),
    .RMODE            ( "fwft"                                  ),
    .FEATURES         ( "0000"                                  )
  ) FIFO2_w_addr (
    .aempty           (                                         ),
    .pempty           (                                         ),
    .empty            ( fifo2_o_empty                           ),
    .rdata            ( fifo2_o_data                            ),
    .ren              ( fifo2_o_pop                             ),
    .afull            (                                         ),
    .pfull            (                                         ),
    .full             ( fifo2_i_full                            ),
    .wdata            ( fifo2_i_data                            ),
    .wen              ( fifo2_i_push                            ),
    .clk              ( clk                                     ),
    .reset            ( reset                                   )
  );
  //assign fifo2_o_pop=(~fifo2_o_empty)&wrunning&(~fifo3_i_full)  ;
  */
  assign fifo2_o_empty=0;
  assign fifo2_i_full =0;
  
  always @(posedge clk)
  if(reset)                 wrunning <=     1                   ;
  else if (fifo2_o_pop)     wrunning <=     0                   ;
  else if (gen_waddr_done)  wrunning <=     1                   ;
  
  always @(posedge clk)
  if(fifo2_o_pop)begin
      wbase_addr    <=    (~fifo2_o_pop)?0:fifo2_o_data[37:6]   ;
      wlen          <=    (~fifo2_o_pop)?0:fifo2_o_data[71:64]+1;
  end
  
  always @(posedge clk)
  if (fifo2_o_pop)         waddr_incr  <= 32'h0                 ;
  else if(waddr_incr+1<wlen)waddr_incr <= waddr_incr+1          ;
  assign gen_waddr_done   = waddr_incr + 1 == wlen              ;
  
  
  always @(posedge clk)
  if ( reset )              fifo3_i_push<=    1'b0              ;
  else if ( fifo2_o_pop )   fifo3_i_push<=    1'b1              ;
  else if ( gen_waddr_done )fifo3_i_push<=    1'b0              ;
  
  assign fifo3_i_data = fifo3_i_push?{gen_waddr_done            , 
                        wbase_addr + waddr_incr}:0              ;
  
  //-------------------------------------------------------------
  // Generate address self increment, which will be used later
  //-------------------------------------------------------------
  localparam        FIFO_3_DELAY       = 0                      ;
  localparam        FIFO_3_DEEP        = 2048                   ;
  localparam        FIFO_3_WIDTH       = 33                     ;
  sync_fifo #(
    .MEM_TYPE         ( "auto"                                  ),
    .RLATENCY         ( FIFO_3_DELAY                            ),
    .DEPTH            ( FIFO_3_DEEP                             ),
    .PEMPTY_THRESH    ( 10                                      ),
    .PFULL_THRESH     ( FIFO_3_DEEP-10                          ),
    .RWIDTH           ( FIFO_3_WIDTH                            ),
    .WWIDTH           ( FIFO_3_WIDTH                            ),
    .RMODE            ( "fwft"                                  ),
    .FEATURES         ( "0000"                                  )
  ) FIFO3_w_incr (
    .aempty           (                                         ),
    .pempty           (                                         ),
    .empty            ( fifo3_o_empty                           ),
    .rdata            ( fifo3_o_data                            ),
    .ren              ( fifo3_o_pop                             ),
    .afull            (                                         ),
    .pfull            (                                         ),
    .full             ( fifo3_i_full                            ),
    .wdata            ( fifo3_i_data                            ),
    .wen              ( fifo3_i_push                            ),
    .clk              ( clk                                     ),
    .reset            ( reset                                   )
  );

  reg [8-1:0]       m_axi_awlen_r1  =0                        ;
  always @(posedge m_axi_awvalid)m_axi_awlen_r1<=m_axi_awlen+1;



  always @(posedge clk)
  if(reset)                           w_start_flay<=0           ;
  //else if(m_axi_wlast)
  else if(m_axi_awlen_r1==1)          w_start_flay<=m_axi_wlast&&m_axi_wvalid;
  else if(m_axi_wlast&&m_axi_wvalid)  w_start_flay<=0           ;
  else if(m_axi_wvalid)               w_start_flay<=1           ;

  
  reg [5:0] w_cnt_wready_new=0;
  always @(posedge clk)
  if(w_start_flay)                    w_cnt_wready_new<=2;
  else if(w_cnt_wready_new==0)        w_cnt_wready_new<=0;
  else              w_cnt_wready_new<=w_cnt_wready_new-1 ;
  



  always @(posedge clk)
  if(reset)                         w_cnt_wready<=0                     ;
  else if(m_axi_wlast&&m_axi_wvalid)
  begin
      if(m_axi_awlen==0)                w_cnt_wready<=1 ;
      else if(w_cnt_wready==1)          w_cnt_wready<=0 ;
      else                              w_cnt_wready<=0                     ;
  end
  else if(m_axi_awvalid)            w_cnt_wready<=(m_axi_awlen+1)*2     ;
  else if(w_cnt_wready==0)          w_cnt_wready<=w_cnt_wready          ;
  else if(w_start_flay)             w_cnt_wready<=w_cnt_wready-1        ;

  reg [8-1:0]       m_axi_awlen_r  =0                           ;
  always @(posedge m_axi_awvalid)m_axi_awlen_r<=(m_axi_awlen+1)*2;


/*
  always @(posedge clk)
  if(reset)             m_axi_wready<=0                         ;
  else if(m_axi_awvalid)m_axi_wready<=1                         ;
  else begin
  m_axi_wready<=
                  (w_cnt_wready<=128 && w_cnt_wready>=115       )//14
                ||(w_cnt_wready<=102 && w_cnt_wready>=93        )//10
                ||(w_cnt_wready<=90  && w_cnt_wready>=84        )//7
                ||(w_cnt_wready<=80  && w_cnt_wready>=72        )//9
                ||(w_cnt_wready<=70  && w_cnt_wready>=67        )//4
                ||(w_cnt_wready<=64  && w_cnt_wready>=60        )//5
                ||(w_cnt_wready<=57  && w_cnt_wready>=54        )//4
                ||(w_cnt_wready<=51  && w_cnt_wready>=50        )//2
                ||(w_cnt_wready<=48  && w_cnt_wready>=44        )//5
                ||(w_cnt_wready<=41  && w_cnt_wready>=40        )//2
                ||(w_cnt_wready<=37  && w_cnt_wready>=36        )//2
                ||(w_cnt_wready<=35  && w_cnt_wready>0          )//0
  ;end
*/
  always @(posedge clk)
  if(reset)             m_axi_wready<=0                         ;
  else if(m_axi_awvalid)m_axi_wready<=1                         ;
  else begin
       if(m_axi_awlen_r==128)m_axi_wready<=  (w_cnt_wready<=128 && w_cnt_wready>=65);
  else if(m_axi_awlen_r==8  )m_axi_wready<=  (w_cnt_wready<=8   && w_cnt_wready>=4);
  else if(m_axi_awlen_r==2  )m_axi_wready<=  (w_cnt_wready<=2   && w_cnt_wready>=2);
  else                       m_axi_wready<=  (w_cnt_wready<=64  && w_cnt_wready>=33);


 
  end







  assign fifo4_i_push=m_axi_wready&m_axi_wvalid&&(~fifo4_i_full);
  assign fifo4_i_data=fifo4_i_push?{m_axi_wlast&&m_axi_wvalid, m_axi_wdata}:0 ;

  //-------------------------------------------------------------
  //Receive data cache and write it back to MEM
  //-------------------------------------------------------------
  localparam        FIFO_4_DELAY       = 0                      ;
  localparam        FIFO_4_DEEP        = 1024                   ;
  localparam        FIFO_4_WIDTH       = 513                    ;
  sync_fifo #(
    .MEM_TYPE         ( "auto"                                  ),
    .RLATENCY         ( FIFO_4_DELAY                            ),
    .DEPTH            ( FIFO_4_DEEP                             ),
    .PEMPTY_THRESH    ( 10                                      ),
    .PFULL_THRESH     ( FIFO_4_DEEP-10                          ),
    .RWIDTH           ( FIFO_4_WIDTH                            ),
    .WWIDTH           ( FIFO_4_WIDTH                            ),
    .RMODE            ( "fwft"                                  ),
    .FEATURES         ( "0000"                                  )
  ) FIFO4_w_data (
    .aempty           (                                         ),
    .pempty           (                                         ),
    .empty            ( fifo4_o_empty                           ),
    .rdata            ( fifo4_o_data                            ),
    .ren              ( fifo4_o_pop                             ),
    .afull            (                                         ),
    .pfull            (                                         ),
    .full             ( fifo4_i_full                            ),
    .wdata            ( fifo4_i_data                            ),
    .wen              ( fifo4_i_push                            ),
    .clk              ( clk                                     ),
    .reset            ( reset                                   )
  );


  always @(posedge clk)
  if(wlen==32)begin
      if(w_cnt_wready==(64-1))  w_mem_wctrl<=wlen                   ;
      else if(w_mem_wctrl==0)   w_mem_wctrl<=0                      ;
      else                      w_mem_wctrl<=w_mem_wctrl-1          ;
  end 
  
  else if(wlen==4)begin
      if(w_cnt_wready==(8-1))   w_mem_wctrl<=wlen                   ;
      else if(w_mem_wctrl==0)   w_mem_wctrl<=0                      ;
      else                      w_mem_wctrl<=w_mem_wctrl-1          ;
  end 

  else if(wlen==1)begin
            w_mem_wctrl<=w_cnt_wready_new==1;
  end 




  else begin
      if(w_cnt_wready==(128-1)) w_mem_wctrl<=wlen                   ;
      else if(w_mem_wctrl==0)   w_mem_wctrl<=0                      ;
      else                      w_mem_wctrl<=w_mem_wctrl-1          ;


  end
  

  assign  fifo4_o_pop=(w_mem_wctrl!==0)&&(~fifo4_o_empty)       ;
  assign  fifo3_o_pop=(w_mem_wctrl!==0)&&(~fifo3_o_empty)       ;

  always @(posedge clk)
  if(fifo4_o_pop)
  DDR4_MEM[(~fifo3_o_pop)?0:fifo3_o_data[31:0]]<=(~fifo4_o_pop)?0:fifo4_o_data[511:0]             ;
  
  //-------------------------------------------------------------
  reg [ID_DW-1:0] r_m_axi_awid=0;
  always @(posedge clk)
  if(m_axi_awvalid)r_m_axi_awid<=m_axi_awid;
  
  
  always @(posedge clk)
  if(reset) begin
    m_axi_bid       <=0;
    m_axi_bresp     <=0;
    m_axi_bvalid    <=0;
  end
  else 
  if(m_axi_bready) begin
    m_axi_bid       <=r_m_axi_awid;
    m_axi_bresp     <=0;
    m_axi_bvalid    <=(~fifo4_o_pop)?0:fifo4_o_data[512];
  end





endmodule