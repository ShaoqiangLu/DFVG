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

module nvm_ln_vmean #(
    parameter           NUM_ELEMS                       = 32            ,
    parameter           DW_IN                           = 16            ,
    parameter           DW_multi                        = 40            ,
    parameter           DW_PKG                          = 16            ,
    parameter           DW_OUT                          = 16            ,
    parameter           DLY_Mean_DIV                    = 16            ,
    parameter           DLY_SYNC_2                      = 16            ,
    parameter           DLY_SYNC_4                      = 32             
)(
    input  wire                                         clk             ,
    input  wire                                         rst             ,
    input  wire                                         enable          ,
    input               [7 -1:0]                        nvm_rstep       ,
    input               [12-1:0]                        nvm_xnum        ,
    input  wire         [NUM_ELEMS*DW_IN-1:0]           data_in         ,
    input  wire                                         data_in_val     ,
    input  wire                                         data_in_done    ,
    
    output wire         [DW_OUT-1:0]                    mean_out        ,
    output wire                                         mean_out_val    ,
    output wire                                         mean_out_done   ,
    output wire                                         mean_out_val_pre,
    
    output wire         [DW_multi-1:0]                  ln_sum_tx       ,
    input  wire         [DW_multi-1:0]                  ln_sum_rx       ,

    output wire         [40-1:0]                        ln_mean_dividend,
    output wire         [16-1:0]                        ln_mean_divisor ,
    input  wire         [48-1:0]                        ln_mean_result  
);


    wire                [DW_multi-1:0]      sum_local                   ;
    wire                                    sum_local_val               ;
    wire                                    sum_local_done              ;
    wire                [DW_PKG-1:0]        pkg_local_acc               ;

    (*keep_hierarchy="yes"*)nvm_ln_vmean_sum #(
        .NUM_ELEMS          (NUM_ELEMS                                  ),
        .DW_IN              (DW_IN                                      ),
        .DW_multi           (DW_multi                                   ),
        .DW_PKG             (DW_PKG                                     )
    )u_nvm_ln_vmean_sum(
        .clk                (clk                                        ),
        .rst                (rst                                        ),
        .nvm_rstep          (nvm_rstep                                  ),
        .data_in_val        (data_in_val                                ),
        .data_in_done       (data_in_done                               ),
        .data_in            (data_in                                    ),
        .sum_out            (sum_local                                  ),
        .sum_out_val        (sum_local_val                              ),
        .sum_out_done       (sum_local_done                             ),
        .pkg_out_acc        (pkg_local_acc                              )
    );

    wire                    [DW_multi-1:0] sum_sync                     ;
    wire                                   sum_sync_val                 ;
    wire                                   sum_sync_done                ;
    wire                    [DW_PKG-1:0]   pkg_sync_acc                 ;

    (*keep_hierarchy="yes"*)nvm_ln_vmean_sync #(
        .DW_multi           (DW_multi                                   ),
        .DW_PKG             (DW_PKG                                     ),
        .DLY_SYNC_2         (DLY_SYNC_2                                 ),
        .DLY_SYNC_4         (DLY_SYNC_4                                 ) 
    )u_nvm_ln_vmean_sync(
        .clk                (clk                                        ),
        .rst                (rst                                        ),
        .sum_local          (sum_local                                  ),
        .sum_local_val      (sum_local_val                              ),
        .sum_local_done     (sum_local_done                             ),
        .pkg_local_acc      (pkg_local_acc                              ),
        .sum_sync           (sum_sync                                   ),
        .sum_sync_val       (sum_sync_val                               ),
        .sum_sync_done      (sum_sync_done                              ),
        .pkg_sync_acc       (pkg_sync_acc                               ),
        .ln_sum_tx          (ln_sum_tx                                  ),
        .ln_sum_rx          (ln_sum_rx                                  ) 
    );


    (*keep_hierarchy="yes"*)nvm_ln_vmean_div #(
        .DLY_Mean_DIV       (DLY_Mean_DIV                               ),
        .DW_multi           (DW_multi                                   ),
        .DW_PKG             (DW_PKG                                     ),
        .DW_OUT             (DW_OUT                                     )
    )u_nvm_ln_vmean_div(
        .clk                (clk                                        ),
        .rst                (rst                                        ),
        .nvm_xnum           (nvm_xnum                                   ),
        .sum_sync           (sum_sync                                   ),
        .sum_sync_val       (sum_sync_val                               ),
        .sum_sync_done      (sum_sync_done                              ),
        .pkg_sync_acc       (pkg_sync_acc                               ),
        .mean_out           (mean_out                                   ),
        .mean_out_val       (mean_out_val                               ),
        .mean_out_done      (mean_out_done                              ),
        .mean_out_val_pre   (mean_out_val_pre                           ),
        .ln_mean_dividend   (ln_mean_dividend                           ),
        .ln_mean_divisor    (ln_mean_divisor                            ),
        .ln_mean_result     (ln_mean_result                             ) 
    );





endmodule
