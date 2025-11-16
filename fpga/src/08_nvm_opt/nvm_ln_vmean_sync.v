`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/11/24 16:57:15
// Design Name: 
// Module Name: comparator
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`include "opu_parameter.vh"
 
module nvm_ln_vmean_sync #(
    parameter           DW_multi            = 40                ,
    parameter           DW_PKG              = 16                ,
    parameter           DLY_SYNC_2          = 16                ,
    parameter           DLY_SYNC_4          = 32                 
)(
    input                                   clk                 ,
    input                                   rst                 ,
    input               [DW_multi-1:0]      sum_local           ,
    input                                   sum_local_val       ,
    input                                   sum_local_done      ,
    input               [DW_PKG-1:0]        pkg_local_acc       ,
    output  reg         [DW_multi-1:0]      sum_sync      =0    ,
    output  reg                             sum_sync_val  =0    ,
    output  reg                             sum_sync_done =0    ,
    output  reg         [DW_PKG-1:0]        pkg_sync_acc  =0    ,
    output  reg         [DW_multi-1:0]      ln_sum_tx     =0    ,
    input   wire        [DW_multi-1:0]      ln_sum_rx       
);




//------------------------------------------------------------------------
//
//------------------------------------------------------------------------
    localparam DWdly = 1+1+DW_PKG                               ;
    integer i=0,j=0                                             ;
    reg                 sync_util  =0                           ;
    wire                sync_start                              ;
    wire                sync_end                                ;




`ifdef ROUTER_SYNC2
    always @(posedge clk) ln_sum_tx<=sum_local                  ;
    reg [DWdly*(DLY_SYNC_2-1)-1:0] DLY_BUFFER  =0               ;
    always @(posedge clk)
    for(i=0;i<(DLY_SYNC_2-1);i=i+1)
    if(i==0)DLY_BUFFER[i*DWdly+:DWdly]
         <={sum_local_val,sum_local_done,pkg_local_acc}         ;    
    else    DLY_BUFFER[ i   *DWdly+:DWdly]<=
            DLY_BUFFER[(i-1)*DWdly+:DWdly]                      ;

    always @(posedge clk)
    begin
        sum_sync        <=   ln_sum_rx  ;
        sum_sync_val    <=   DLY_BUFFER[(DLY_SYNC_2-2)*DWdly+0+ DW_PKG+1+:1 ];
        sum_sync_done   <=   DLY_BUFFER[(DLY_SYNC_2-2)*DWdly+0+ DW_PKG+0+:1 ];
        pkg_sync_acc    <=   DLY_BUFFER[(DLY_SYNC_2-2)*DWdly+0+:DW_PKG]
                           + DLY_BUFFER[(DLY_SYNC_2-2)*DWdly+0+:DW_PKG];
    end

    //
    assign sync_start=~DLY_BUFFER[(1)*DWdly+0+DW_PKG+1+:1]&sum_local_val;
    assign sync_end  =~DLY_BUFFER[(DLY_SYNC_2-2)*DWdly+0+DW_PKG+1+:1]&sum_sync_val ;
    always @(posedge clk)     
    if(sync_start)          sync_util<=1                        ;
    else if(sync_end)       sync_util<=0                        ;
`elsif ROUTER_SYNC4
    always @(posedge clk) ln_sum_tx<=sum_local                  ;
    reg [DWdly*(DLY_SYNC_4-1)-1:0]  DLY_BUFFER  =0              ;
    always @(posedge clk)
    for(i=0;i<(DLY_SYNC_4-1);i=i+1)
    if(i==0)DLY_BUFFER[i*DWdly+:DWdly]
         <={sum_local_val,sum_local_done,pkg_local_acc}         ;
    else    DLY_BUFFER[ i   *DWdly+:DWdly]<=
            DLY_BUFFER[(i-1)*DWdly+:DWdly]                      ;

    always @(posedge clk)
    begin
        sum_sync        <=   ln_sum_rx                          ;
        sum_sync_val    <=   DLY_BUFFER[(DLY_SYNC_4-2)*DWdly+0+ DW_PKG+1+:1 ];
        sum_sync_done   <=   DLY_BUFFER[(DLY_SYNC_4-2)*DWdly+0+ DW_PKG  +:1 ];
        pkg_sync_acc    <=   DLY_BUFFER[(DLY_SYNC_4-2)*DWdly+0+:DW_PKG]
                           + DLY_BUFFER[(DLY_SYNC_4-2)*DWdly+0+:DW_PKG]
                           + DLY_BUFFER[(DLY_SYNC_4-2)*DWdly+0+:DW_PKG]
                           + DLY_BUFFER[(DLY_SYNC_4-2)*DWdly+0+:DW_PKG];
    end
    
    //
    assign sync_start=~DLY_BUFFER[(1)*DWdly+0+DW_PKG+1+:1]&sum_local_val;
    assign sync_end  =~DLY_BUFFER[(DLY_SYNC_4-2)*DWdly+0+DW_PKG+1+:1]&sum_sync_val ;
    always @(posedge clk)     
    if(sync_start)           sync_util<=1                       ;
    else if(sync_end)        sync_util<=0                       ;

`else
    assign  sync_start  =0;
    assign  sync_end    =0;
    
    
    always @(posedge clk)
    begin
        sum_sync        <=   sum_local                          ;
        sum_sync_val    <=   sum_local_val                      ;
        sum_sync_done   <=   sum_local_done                     ;
        pkg_sync_acc    <=   pkg_local_acc                      ;
    end

`endif


endmodule
