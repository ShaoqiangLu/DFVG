`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/17/2024 11:33:28 AM
// Design Name: 
// Module Name: collect_4to8
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


module ofm_4to8#(
  parameter                     NUM    = 32*4 , 
  parameter                     IDW    = 37+1 ,
  parameter                     DWCNT  = 2  ,
  parameter                     SELPRE = 4  ,
  parameter                     SELCUR = 8  ,
  localparam                    NUMPRE = NUM/SELPRE,//32
  localparam                    NUMCUR = NUM/SELCUR //16       
)(
    input                       clk        ,       
    input                       reset      ,
    input      [NUMPRE-1:0][SELPRE*IDW-1:0] data_in    ,
    output reg [NUMCUR-1:0][SELCUR*IDW-1:0] data_out=0   
);

  //-----------------------------------------------------------------------------------------------
  //
  //-----------------------------------------------------------------------------------------------
integer j=0;
  
generate for(genvar i=0;i<NUMCUR;i=i+1 )
begin:mux
 reg [SELPRE*IDW-1:0]data_high=0;
 reg [SELPRE*IDW-1:0]data_low =0;
 wire[SELPRE*IDW-1:0]data_sel;
 reg [(DWCNT+1)-1:0]index_cnt=0;
 always @(posedge clk)
 begin
     data_high<= data_in[2*i+1];
     data_low <= data_in[2*i+0];
 end
 //---------------------------
 assign data_sel=data_in[2*i];
 //---------------------------
 always @(posedge clk)
 begin
     index_cnt<=
     data_sel[3*IDW+:1]+
     data_sel[2*IDW+:1]+
     data_sel[1*IDW+:1]+
     data_sel[0*IDW+:1];           
 end       
     
 always @(posedge clk)
 if(index_cnt[0+DWCNT])
           data_out[i]<={           data_high,data_low[0+:4*IDW]};
 else (*full_case*)
 case(index_cnt[0+:DWCNT]) 
   2'd0   :data_out[i]<={{4{38'd0}},data_high                   };
   2'd1   :data_out[i]<={{3{38'd0}},data_high,data_low[0+:1*IDW]};
   2'd2   :data_out[i]<={{2{38'd0}},data_high,data_low[0+:2*IDW]}; 
   default:data_out[i]<={{1{38'd0}},data_high,data_low[0+:3*IDW]};  
 endcase

end
endgenerate


endmodule
