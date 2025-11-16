`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/18/2024 09:40:22 AM
// Design Name: 
// Module Name: mux_64to128
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


module ofm_mux_64to128#(
  parameter                     NUM    = 16 , 
  parameter                     IDW    = 32 ,
  parameter                     DWCNT  = 6  ,
  parameter                     SELPRE = 64 ,
  parameter                     SELCUR = 128,
  localparam                    NUMPRE = NUM/SELPRE,
  localparam                    NUMCUR = NUM/SELCUR
)(
    input      [NUMPRE-1:0][SELPRE*IDW-1:0]data_in ,
    input      [NUMCUR-1:0][(DWCNT+1) -1:0]sel_cnt ,
    output reg [NUMCUR-1:0][SELCUR*IDW-1:0]data_out=0,
    input                              clk       
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
            data_out[i]<={             data_high, data_low[0+:64 *IDW]};
  else (*full_case*)
  case(index[0+:DWCNT])//down    //up
    6'd0   :data_out[i]<={{64{38'd0}}, data_high                      };
    6'd1   :data_out[i]<={{63{38'd0}}, data_high, data_low[0+:1  *IDW]};
    6'd2   :data_out[i]<={{62{38'd0}}, data_high, data_low[0+:2  *IDW]}; 
    6'd3   :data_out[i]<={{61{38'd0}}, data_high, data_low[0+:3  *IDW]};  
    6'd4   :data_out[i]<={{60{38'd0}}, data_high, data_low[0+:4  *IDW]};
    6'd5   :data_out[i]<={{59{38'd0}}, data_high, data_low[0+:5  *IDW]};
    6'd6   :data_out[i]<={{58{38'd0}}, data_high, data_low[0+:6  *IDW]}; 
    6'd7   :data_out[i]<={{57{38'd0}}, data_high, data_low[0+:7  *IDW]}; 
    6'd8   :data_out[i]<={{56{38'd0}}, data_high, data_low[0+:8  *IDW]}; 
    6'd9   :data_out[i]<={{55{38'd0}}, data_high, data_low[0+:9  *IDW]};
    6'd10  :data_out[i]<={{54{38'd0}}, data_high, data_low[0+:10 *IDW]}; 
    6'd11  :data_out[i]<={{53{38'd0}}, data_high, data_low[0+:11 *IDW]};  
    6'd12  :data_out[i]<={{52{38'd0}}, data_high, data_low[0+:12 *IDW]};
    6'd13  :data_out[i]<={{51{38'd0}}, data_high, data_low[0+:13 *IDW]};
    6'd14  :data_out[i]<={{50{38'd0}}, data_high, data_low[0+:14 *IDW]}; 
    6'd15  :data_out[i]<={{49{38'd0}}, data_high, data_low[0+:15 *IDW]}; 
    6'd16  :data_out[i]<={{48{38'd0}}, data_high, data_low[0+:16 *IDW]}; 
    6'd17  :data_out[i]<={{47{38'd0}}, data_high, data_low[0+:17 *IDW]};
    6'd18  :data_out[i]<={{46{38'd0}}, data_high, data_low[0+:18 *IDW]}; 
    6'd19  :data_out[i]<={{45{38'd0}}, data_high, data_low[0+:19 *IDW]};  
    6'd20  :data_out[i]<={{44{38'd0}}, data_high, data_low[0+:20 *IDW]};
    6'd21  :data_out[i]<={{43{38'd0}}, data_high, data_low[0+:21 *IDW]};
    6'd22  :data_out[i]<={{42{38'd0}}, data_high, data_low[0+:22 *IDW]}; 
    6'd23  :data_out[i]<={{41{38'd0}}, data_high, data_low[0+:23 *IDW]}; 
    6'd24  :data_out[i]<={{40{38'd0}}, data_high, data_low[0+:24 *IDW]}; 
    6'd25  :data_out[i]<={{39{38'd0}}, data_high, data_low[0+:25 *IDW]};
    6'd26  :data_out[i]<={{38{38'd0}}, data_high, data_low[0+:26 *IDW]}; 
    6'd27  :data_out[i]<={{37{38'd0}}, data_high, data_low[0+:27 *IDW]};  
    6'd28  :data_out[i]<={{36{38'd0}}, data_high, data_low[0+:28 *IDW]};
    6'd29  :data_out[i]<={{35{38'd0}}, data_high, data_low[0+:29 *IDW]};
    6'd30  :data_out[i]<={{34{38'd0}}, data_high, data_low[0+:30 *IDW]}; 
    6'd31  :data_out[i]<={{33{38'd0}}, data_high, data_low[0+:31 *IDW]}; 
    6'd32  :data_out[i]<={{32{38'd0}}, data_high, data_low[0+:32 *IDW]}; 
    6'd33  :data_out[i]<={{31{38'd0}}, data_high, data_low[0+:33 *IDW]};
    6'd34  :data_out[i]<={{30{38'd0}}, data_high, data_low[0+:34 *IDW]}; 
    6'd35  :data_out[i]<={{29{38'd0}}, data_high, data_low[0+:35 *IDW]};  
    6'd36  :data_out[i]<={{28{38'd0}}, data_high, data_low[0+:36 *IDW]};
    6'd37  :data_out[i]<={{27{38'd0}}, data_high, data_low[0+:37 *IDW]};
    6'd38  :data_out[i]<={{26{38'd0}}, data_high, data_low[0+:38 *IDW]}; 
    6'd39  :data_out[i]<={{25{38'd0}}, data_high, data_low[0+:39 *IDW]}; 
    6'd40  :data_out[i]<={{24{38'd0}}, data_high, data_low[0+:40 *IDW]}; 
    6'd41  :data_out[i]<={{23{38'd0}}, data_high, data_low[0+:41 *IDW]};
    6'd42  :data_out[i]<={{22{38'd0}}, data_high, data_low[0+:42 *IDW]}; 
    6'd43  :data_out[i]<={{21{38'd0}}, data_high, data_low[0+:43 *IDW]};  
    6'd44  :data_out[i]<={{20{38'd0}}, data_high, data_low[0+:44 *IDW]};
    6'd45  :data_out[i]<={{19{38'd0}}, data_high, data_low[0+:45 *IDW]};
    6'd46  :data_out[i]<={{18{38'd0}}, data_high, data_low[0+:46 *IDW]}; 
    6'd47  :data_out[i]<={{17{38'd0}}, data_high, data_low[0+:47 *IDW]}; 
    6'd48  :data_out[i]<={{16{38'd0}}, data_high, data_low[0+:48 *IDW]}; 
    6'd49  :data_out[i]<={{15{38'd0}}, data_high, data_low[0+:49 *IDW]};
    6'd50  :data_out[i]<={{14{38'd0}}, data_high, data_low[0+:50 *IDW]}; 
    6'd51  :data_out[i]<={{13{38'd0}}, data_high, data_low[0+:51 *IDW]};  
    6'd52  :data_out[i]<={{12{38'd0}}, data_high, data_low[0+:52 *IDW]};
    6'd53  :data_out[i]<={{11{38'd0}}, data_high, data_low[0+:53 *IDW]};
    6'd54  :data_out[i]<={{10{38'd0}}, data_high, data_low[0+:54 *IDW]}; 
    6'd55  :data_out[i]<={{ 9{38'd0}}, data_high, data_low[0+:55 *IDW]}; 
    6'd56  :data_out[i]<={{ 8{38'd0}}, data_high, data_low[0+:56 *IDW]}; 
    6'd57  :data_out[i]<={{ 7{38'd0}}, data_high, data_low[0+:57 *IDW]};
    6'd58  :data_out[i]<={{ 6{38'd0}}, data_high, data_low[0+:58 *IDW]}; 
    6'd59  :data_out[i]<={{ 5{38'd0}}, data_high, data_low[0+:59 *IDW]};  
    6'd60  :data_out[i]<={{ 4{38'd0}}, data_high, data_low[0+:60 *IDW]};
    6'd61  :data_out[i]<={{ 3{38'd0}}, data_high, data_low[0+:61 *IDW]};
    6'd62  :data_out[i]<={{ 2{38'd0}}, data_high, data_low[0+:62 *IDW]}; 
    default:data_out[i]<={{ 1{38'd0}}, data_high, data_low[0+:63 *IDW]}; 
  endcase

end
endgenerate








  
endmodule
