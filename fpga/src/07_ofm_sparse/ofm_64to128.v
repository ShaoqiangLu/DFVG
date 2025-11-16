`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/17/2024 02:26:57 PM
// Design Name: 
// Module Name: collect_256to512
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


module ofm_64to128#(
  parameter                     NUM    = 32*4 , 
  parameter                     IDW    = 37+1 ,
  parameter                     DWCNT  = 6  ,
  parameter                     SELPRE = 64 ,
  parameter                     SELCUR = 128,
  localparam                    NUMPRE = NUM/SELPRE,
  localparam                    NUMCUR = NUM/SELCUR         
)(
    input      [NUMPRE*SELPRE*IDW-1:0]data_in  ,
    output wire[NUMCUR*SELCUR*IDW-1:0]data_out ,
    input                       clk      ,       
    input                       reset   
);


  //-----------------------------------------------------------------------------------------------
  //64=8(local)*8(select)
  //-----------------------------------------------------------------------------------------------

  reg [NUM*IDW-1:0] sel_data  =0;
  reg [NUM*IDW-1:0] sel_data_r=0;
  wire[(DWCNT+1)*NUMCUR-1:0] sel_cnt;
  always @(posedge clk)
  begin
      sel_data_r<=data_in;
      sel_data<=sel_data_r;
  end

  
  (*keep_hierarchy="no"*)
  ofm_cnt_64to128
  #(
  .NUM   (NUM   ), 
  .IDW   (IDW   ),
  .DWCNT (DWCNT ),
  .SELPRE(SELPRE),
  .SELCUR(SELCUR)
  )u_cnt_64to128
  (
      .data_in (data_in)  ,
      .data_out(sel_cnt)  ,
      .clk     (clk)  
  );
  
  (*keep_hierarchy="no"*)
  ofm_mux_64to128
  #(
  .NUM   (NUM   ), 
  .IDW   (IDW   ),
  .DWCNT (DWCNT ),
  .SELPRE(SELPRE),
  .SELCUR(SELCUR)
  )u_mux_64to128
  (
      .data_in (sel_data),
      .sel_cnt (sel_cnt ),
      .data_out(data_out),
      .clk     (clk)  
  );



endmodule
