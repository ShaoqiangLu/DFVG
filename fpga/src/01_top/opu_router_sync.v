`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/26/2024 05:20:44 AM
// Design Name: 
// Module Name: router
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
module opu_router_sync#
(
parameter     enable    =1,
parameter     sync_type =1,
parameter     operation =1,
parameter     direction =1,
parameter     odrer     =1,
parameter     delay     =1,
parameter     data_size =1
)(
input                   clk           ,
input                   rst           ,
input       [127:0]     left_rx1      ,
input       [127:0]     left_rx2      ,
output reg  [127:0]     right_tx1  =0 ,
output reg  [127:0]     right_tx2  =0 ,
input       [127:0]     local_rx      ,
output reg  [127:0]     local_tx   =0     
);

reg  [127:0] sum_result =0;
reg  [127:0] r_left_rx2 =0;


always @(posedge clk)
begin
    sum_result[63 :0 ]<= local_rx[63 :0 ]+left_rx1[63 :0 ];
    sum_result[127:64]<= local_rx[127:64]+left_rx1[127:64];
    right_tx1  <= sum_result;
    
    r_left_rx2 <=left_rx2;
    right_tx2  <= r_left_rx2;
    local_tx   <= r_left_rx2;
end


wire sync_crtl= local_rx[0];




























endmodule
