`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/18/2024 09:39:17 AM
// Design Name: 
// Module Name: mux_32to64
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


module ofm_mux_32to64#(
  parameter                     NUM    = 128 , 
  parameter                     IDW    = 38 ,
  parameter                     DWCNT  = 5  ,
  parameter                     SELPRE = 32 ,
  parameter                     SELCUR = 64 ,
  localparam                    NUMPRE = NUM/SELPRE,
  localparam                    NUMCUR = NUM/SELCUR
)(
    input                              clk         ,
    input      [NUMPRE-1:0][SELPRE*IDW-1:0]data_in ,
    input      [NUMCUR-1:0][(DWCNT+1) -1:0]sel_cnt ,
    output reg [NUMCUR-1:0][SELCUR*IDW-1:0]data_out=0

);

integer j=0;
generate for(genvar i=0;i<NUMCUR;i=i+1 )
begin:mux
  reg [(DWCNT+1)-1:0]index=0;
  reg [SELPRE*IDW-1:0]data_low =0;
  reg [SELPRE*IDW-1:0]data_high=0;  
  always @(posedge clk)
  begin
      index<=sel_cnt[i]; 
      data_low <= data_in[2*i+0];
      data_high<= data_in[2*i+1];
  end

   

  always @(posedge clk)
  if(index[0+DWCNT])
            data_out[i]<={             data_high, data_low[0+:32 *IDW]};
  else (*full_case*)
  case(index[0+:DWCNT])//down  //up
    5'd0   :data_out[i]<={{32{38'd0}}, data_high                      };
    5'd1   :data_out[i]<={{31{38'd0}}, data_high, data_low[0+:1  *IDW]};
    5'd2   :data_out[i]<={{30{38'd0}}, data_high, data_low[0+:2  *IDW]}; 
    5'd3   :data_out[i]<={{29{38'd0}}, data_high, data_low[0+:3  *IDW]};  
    5'd4   :data_out[i]<={{28{38'd0}}, data_high, data_low[0+:4  *IDW]};
    5'd5   :data_out[i]<={{27{38'd0}}, data_high, data_low[0+:5  *IDW]};
    5'd6   :data_out[i]<={{26{38'd0}}, data_high, data_low[0+:6  *IDW]}; 
    5'd7   :data_out[i]<={{25{38'd0}}, data_high, data_low[0+:7  *IDW]}; 
    5'd8   :data_out[i]<={{24{38'd0}}, data_high, data_low[0+:8  *IDW]}; 
    5'd9   :data_out[i]<={{23{38'd0}}, data_high, data_low[0+:9  *IDW]};
    5'd10  :data_out[i]<={{22{38'd0}}, data_high, data_low[0+:10 *IDW]}; 
    5'd11  :data_out[i]<={{21{38'd0}}, data_high, data_low[0+:11 *IDW]};  
    5'd12  :data_out[i]<={{20{38'd0}}, data_high, data_low[0+:12 *IDW]};
    5'd13  :data_out[i]<={{19{38'd0}}, data_high, data_low[0+:13 *IDW]};
    5'd14  :data_out[i]<={{18{38'd0}}, data_high, data_low[0+:14 *IDW]}; 
    5'd15  :data_out[i]<={{17{38'd0}}, data_high, data_low[0+:15 *IDW]}; 
    5'd16  :data_out[i]<={{16{38'd0}}, data_high, data_low[0+:16 *IDW]}; 
    5'd17  :data_out[i]<={{15{38'd0}}, data_high, data_low[0+:17 *IDW]};
    5'd18  :data_out[i]<={{14{38'd0}}, data_high, data_low[0+:18 *IDW]}; 
    5'd19  :data_out[i]<={{13{38'd0}}, data_high, data_low[0+:19 *IDW]};  
    5'd20  :data_out[i]<={{12{38'd0}}, data_high, data_low[0+:20 *IDW]};
    5'd21  :data_out[i]<={{11{38'd0}}, data_high, data_low[0+:21 *IDW]};
    5'd22  :data_out[i]<={{10{38'd0}}, data_high, data_low[0+:22 *IDW]}; 
    5'd23  :data_out[i]<={{ 9{38'd0}}, data_high, data_low[0+:23 *IDW]}; 
    5'd24  :data_out[i]<={{ 8{38'd0}}, data_high, data_low[0+:24 *IDW]}; 
    5'd25  :data_out[i]<={{ 7{38'd0}}, data_high, data_low[0+:25 *IDW]};
    5'd26  :data_out[i]<={{ 6{38'd0}}, data_high, data_low[0+:26 *IDW]}; 
    5'd27  :data_out[i]<={{ 5{38'd0}}, data_high, data_low[0+:27 *IDW]};  
    5'd28  :data_out[i]<={{ 4{38'd0}}, data_high, data_low[0+:28 *IDW]};
    5'd29  :data_out[i]<={{ 3{38'd0}}, data_high, data_low[0+:29 *IDW]};
    5'd30  :data_out[i]<={{ 2{38'd0}}, data_high, data_low[0+:30 *IDW]}; 
    default:data_out[i]<={{ 1{38'd0}}, data_high, data_low[0+:31 *IDW]}; 
  endcase                

end
endgenerate

endmodule