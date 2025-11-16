`timescale 1ns / 1ps
// -----------------------------------------------------------------------------
// UCLA EDA LAB
// -----------------------------------------------------------------------------
// Engineer       : Chen Wu
// Design Name    : opu series
// Module Name    : inst_top
// Target Devices : 325t
// Tool Versions  : Vivado 2020.1, Modelsim 2019.4
// Description    : 
//    Write instructions from DDR to inst ram
//    Fetch instructions from inst ram
//    Decode instructions
//
// Revision       :
// Version        Date        Author        Descriptin
// 1.0            2021-04-12  Chen Wu       Initial version
// 2.0            2023-09-11  Shaoqiang     Simulation 97 layers,and       
//                                          implementation on FPGA of U200.
// -----------------------------------------------------------------------------

module inst_buffer (
  input                             core_start                          ,
  input                             inst_wstart                         ,
  input                             inst_wvld                           ,    
  input           [512-1: 0]        inst_wdata                          ,
  output  reg                       inst_ready       =0                 ,
  input                             inst_rstart                         ,
  output  reg                       inst_rvld        =0                 ,    
  output  wire    [32-1 : 0]        inst_rdata                          , 
  output  wire    [32-1 : 0]        inst_round                          , 
   
  input                             clk                                 ,
  input                             reset                               
);

   wire                             ins_ram_wen                         ;
   wire[ 31 : 0]                    ins_ram_wdata                       ;
   reg [  9 : 0]                    ins_ram_waddr   = 0                 ;
   reg                              ins_ram_wdone   = 0                 ;
   reg                              ins_ram_wpp     = 0                 ;
   
   (*max_fanout=8*)reg              inst_rvld_r     = 0                 ; 
   (*max_fanout=8*)reg              ins_ram_rpp     = 0                 ; 
   reg [  9 : 0]                    ins_ram_raddr   = 0                 ; 
   wire                             ins_ram_raddr_done                  ;
   wire                             ins_rctrl                           ;
   wire                             inst_round_rstart                   ;
   reg [ 31 : 0]                    inst_round_r    =0                  ; 
   wire[ 31 : 0]                    ins_ram0_doutb                      ;
   wire[ 31 : 0]                    ins_ram1_doutb                      ;
   

  //---------------------------------------------------------------------
  //DDR4 ----> RAM
  //---------------------------------------------------------------------
  (*keep_hierarchy="yes"*)inst_fifo FIFO_w512r32 (
    .din_rstart           ( inst_wstart                                 ),
    .din_vld              ( inst_wvld                                   ),
    .din                  ( inst_wdata                                  ),
    .dout_vld             ( ins_ram_wen                                 ),
    .dout                 ( ins_ram_wdata                               ),
    .clk                  ( clk                                         ),
    .reset                ( reset                                       )
  );
  //---------------------------------------------------------------------
  //buffer instructions from ddr, convert data width
  //never full, controlled by compiler
  //write  to ram0/ram1
  //---------------------------------------------------------------------
  always @(posedge clk) ins_ram_wdone <=(ins_ram_waddr==1022)           ;
  
  always @(posedge clk)
  if (ins_ram_wdone)    ins_ram_waddr <=  10'h0                         ;
  else if (ins_ram_wen) ins_ram_waddr <=  ins_ram_waddr + 1             ;//0~1023
  
  always @(posedge clk)
  if(core_start)        ins_ram_wpp   <=  1'b0                          ;
  else if(ins_ram_wdone)ins_ram_wpp   <=  ~ins_ram_wpp                  ;

  //---------------------------------------------------------------------
  //Read inst trigger conditions
  //---------------------------------------------------------------------
  always @(posedge clk)
  if (core_start)           inst_ready  <=  1'b0                        ;
  else if ( ins_ram_wdone ) inst_ready  <=  1'b1                        ;
  
  assign ins_rctrl=inst_rdata[31]|(inst_ready?inst_rstart:ins_ram_wdone);

  //----------------------------------------------------------------------
  // addr=0, and wvld_ctrl=1,only be converted
  //----------------------------------------------------------------------
  assign ins_ram_raddr_done=inst_ready&&(ins_ram_raddr==0)&&ins_rctrl   ;
  
  always @(posedge clk)
  if ( core_start )                      ins_ram_rpp <=  1'b0           ;
  else if(ins_ram_raddr_done)ins_ram_rpp <=  ~ins_ram_rpp               ;


  //---------------------------------------------------------------------
  //Read address generation
  //---------------------------------------------------------------------
  always @(posedge clk)
  if(core_start)                         ins_ram_raddr<=0               ;
  else if(ins_rctrl)                     ins_ram_raddr<=ins_ram_raddr+1 ;
  
  //---------------------------------------------------------------------
  //read data
  //---------------------------------------------------------------------
  always @(posedge clk)
  if (core_start)                        inst_rvld <=  1'h0             ;
  else                                   inst_rvld <=  ins_rctrl        ;

  always @(posedge clk)
  if (core_start)                        inst_rvld_r<= 1'h0             ;
  else                                   inst_rvld_r<= ins_rctrl        ;

  assign inst_rdata=inst_rvld_r?(ins_ram_rpp?ins_ram1_doutb:ins_ram0_doutb):0; 

  assign inst_round_rstart               =~inst_rvld&ins_rctrl          ;
  always @(posedge clk)
  if (core_start)                        inst_round_r<=0                ;
  else if(inst_round_rstart)             inst_round_r<=inst_round_r+1   ;
  
  assign inst_round=inst_rvld_r?inst_round_r:0                          ;

  //--------------------------------------------------------------------
  // write instructions to ins ram in ping-pong manner
  // wpp = 0: write ram0; wpp = 1: write ram1
  // rpp = 0: read  ram0; rpp = 1:  read ram1
  // write on a port and read on b port
  //--------------------------------------------------------------------              
  localparam        INST_RAM_CYCLE     =  1; 
  (*keep_hierarchy="yes"*)tdpram # (
    .ADDR_WIDTH                 ( 10                                ),
    .DATA_WIDTH                 ( 32                                ),
    .MEM_TYPE                   ( "block"                           ),
    .RD_DLY                     ( INST_RAM_CYCLE                    )
  ) RAM0 (
    .douta                      (                                   ),
    .dina                       ( ins_ram_wdata                     ),    
    .addra                      ( ins_ram_waddr                     ),     
    .wea                        ( ins_ram_wen&(~ins_ram_wpp)        ),
    .dinb                       ( 32'h0                             ),    
    .ena                        ( 1'b1                              ),
    .enb                        ( 1'b1                              ),
    .web                        ( 1'b0                              ),
    .doutb                      ( ins_ram0_doutb                    ),
    .addrb                      ( ins_ram_raddr                     ),
    .clk                        ( clk                               ),
    .reset                      ( reset                             )
  );

  (*keep_hierarchy="yes"*)tdpram # (
    .ADDR_WIDTH                 ( 10                                ),
    .DATA_WIDTH                 ( 32                                ),
    .MEM_TYPE                   ( "block"                           ),
    .RD_DLY                     ( INST_RAM_CYCLE                    )
  ) RAM1 (
    .douta                      (                                   ),
    .dina                       ( ins_ram_wdata                     ),    
    .addra                      ( ins_ram_waddr                     ),     
    .wea                        ( ins_ram_wen&( ins_ram_wpp)        ),
    .dinb                       ( 32'h0                             ),    
    .ena                        ( 1'b1                              ),
    .enb                        ( 1'b1                              ),
    .web                        ( 1'b0                              ),
    .doutb                      ( ins_ram1_doutb                    ),
    .addrb                      ( ins_ram_raddr                     ),
    .clk                        ( clk                               ),
    .reset                      ( reset                             )
  );




endmodule

