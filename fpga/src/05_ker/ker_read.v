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
//    Write data (from ddr) to kernel buffer in ping-pong mode
//    Read data from input kernel buffer in ping-pong mode
//
// Revision       :
// Version        Date        Author        Descriptin
// 1.0            2022-03-31  Chen Wu       Initial version
// 2.0            2023-08-25  Shaoqiang     Simulation 97 layers,and       
//                                          implementation on FPGA of U200.
// 3.0            2024-05-30  Shaoqiang     For sparsity
// -----------------------------------------------------------------------------

module ker_read # (
  parameter                                 DW     = 16                 ,
  parameter                                 NUM    = 32                 ,
  parameter                                 KER_RAM_ADDR  = 5           ,
  parameter                                 KER_RAM_DEEP  = 32  
) (
  input                                     clk                         ,
  input                                     reset                       ,
  
  input                                     ker_pp                      ,
  input                                     ker_rstart                  ,
  input       [7-  1:0]                     ker_hold                    ,
  
  
  output  reg [NUM-1:0]                     ker_addr_vld   =0           ,
  output  reg [NUM-1:0]                     ker_addr_rpp   =0           ,
  output  reg [NUM-1:0][KER_RAM_ADDR -1:0]  ker_addr_cnt   =0           ,
  
  output  reg [NUM-1:0][KER_RAM_ADDR -1:0]  RAM_addr_cnt0  =0           ,
  output  reg [NUM-1:0][KER_RAM_ADDR -1:0]  RAM_addr_cnt1  =0           ,
  input   wire[NUM-1:0][DW-1:0]             RAM_rdata0                  ,
  input   wire[NUM-1:0][DW-1:0]             RAM_rdata1                  ,

  output  reg [NUM-1:0][DW-1:0]             ker_rdata      =0           ,
  output  wire                              ker_rdata_vld               ,    
  output  wire                              ker_rdata_start             
           
);


  integer i=0,j=0;

 //---------------------------------------------------------------------------------------
 //Read data
 //---------------------------------------------------------------------------------------   
 wire                               ker_addr_done                       ;
 wire                               ker_addr_ctrl                       ;  

 (*dont_touch="true",max_fanout=32*)
 reg [NUM-1:0]                      RAM_rpp              =0             ;
 
 assign ker_addr_done= ker_addr_vld[0]&&ker_addr_cnt[0]==(KER_RAM_DEEP-1);
 assign ker_addr_ctrl= ker_addr_vld[0];
 always @(posedge clk)
 for(i=0;i<(KER_RAM_DEEP);i=i+1) 
 if(i==0)
 begin//-------------------------------------------------------
       if(ker_rstart)begin
               ker_addr_vld[i]       <=1                                ;
               ker_addr_cnt[i]       <=0                                ;
               ker_addr_rpp[i]       <=ker_pp                           ;
       end     
       else if(ker_addr_done)begin
               ker_addr_vld[i]       <=0                                ;
               ker_addr_cnt[i]       <=ker_addr_cnt[i]                  ;
               ker_addr_rpp[i]       <=ker_addr_rpp[i]                  ;
       end
       else begin
               ker_addr_vld[i]       <=ker_addr_vld[i]                  ;
               if(ker_addr_ctrl)
               ker_addr_cnt[i]       <=ker_addr_cnt[i]+1                ;
               ker_addr_rpp[i]       <=ker_addr_rpp[i]                  ;
       end
       
 end else begin//--------------------------------------------------------
               ker_addr_vld[i]       <=ker_addr_vld[i-1]                ;
               ker_addr_cnt[i]       <=ker_addr_cnt[i-1]                ;
               ker_addr_rpp[i]       <=ker_addr_rpp[i-1]                ;
 end


//-----------------------------------------------------------------------
//
//-----------------------------------------------------------------------

 always @(posedge clk)
 for(i=0;i<NUM;i=i+1) 
 if (i==0)begin
       if(ker_rstart)
               RAM_addr_cnt0[i]<=0                                      ;   
       else if(ker_addr_done)
               RAM_addr_cnt0[i]<=RAM_addr_cnt0[i]                       ;
       else    if(ker_addr_ctrl)
               RAM_addr_cnt0[i]<=RAM_addr_cnt0[i]+1                     ;
 end else      RAM_addr_cnt0[i]<=RAM_addr_cnt0[i-1]                     ;
 
 always @(posedge clk)
 for(i=0;i<NUM;i=i+1) 
 if (i==0)begin
       if(ker_rstart)
               RAM_addr_cnt1[i]<=0                                      ;   
       else if(ker_addr_done)
               RAM_addr_cnt1[i]<=RAM_addr_cnt1[i]                       ;
       else    if(ker_addr_ctrl)
               RAM_addr_cnt1[i]<=RAM_addr_cnt1[i]+1                     ;
 end else      RAM_addr_cnt1[i]<=RAM_addr_cnt1[i-1]                     ;
 
 //-----------------------------------------------------------------------
 
 always @(posedge clk) for(i=0;i<NUM; i=i+1)
 begin    RAM_rpp[i]  <=ker_addr_rpp[i]                                 ;
       if(RAM_rpp[i])   ker_rdata[i] <= RAM_rdata0[i]                   ;
     else               ker_rdata[i] <= RAM_rdata1[i]                   ;
 end 

//------------------------------------------------------------------------
 localparam        DLY_R        =       3                               ;        
 reg [DLY_R*1-1:0] dly_vd_reg   =       0                               ;
 always @(posedge clk)
 for(i=0;i<DLY_R;i=i+1)if(i==0)
         dly_vd_reg[i*1+:1]     <=ker_rstart                            ;
 else    dly_vd_reg[i*1+:1]     <=dly_vd_reg[(i-1)*1+:1]                ;

 assign  ifm_rdata_done         = dly_vd_reg[(DLY_R-1)*1+0+:1]          ;

 wire                           ker_addr_hold_start                     ; 
 wire                           ker_addr_hold_done                      ;
 reg        [6-1:0]             ker_addr_hold_cnt    =0                 ;
 reg                            ker_addr_hold_vld    =0                 ;

assign ker_addr_hold_start=dly_vd_reg[(DLY_R-1)*1+0+:1]                 ;
assign ker_addr_hold_done=ker_addr_hold_vld&&ker_addr_hold_cnt==ker_hold;

always @(posedge clk)
if(dly_vd_reg[(DLY_R-2)*1+0+:1])
begin
    ker_addr_hold_cnt       <=0                                         ;
    ker_addr_hold_vld       <=1                                         ;
end 
else if(ker_addr_hold_done)
begin
    ker_addr_hold_cnt       <=ker_addr_hold_cnt                         ;
    ker_addr_hold_vld       <=0                                         ;
end
else begin
    if(ker_addr_hold_vld)
    ker_addr_hold_cnt       <=ker_addr_hold_cnt+1                       ;
    ker_addr_hold_vld       <=ker_addr_hold_vld                         ;
end

assign  ker_rdata_vld       =ker_addr_hold_vld                          ;
assign  ker_rdata_start     =ker_addr_hold_start                        ;
 
 
 




endmodule
