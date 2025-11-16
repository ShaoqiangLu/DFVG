`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/19/2024 06:44:11 PM
// Design Name: 
// Module Name: divider_share
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
module nvm_div_top#(
parameter           IDW                 = 24,
parameter           ODW                 = 40,
parameter           NUM                 = 32                        
)(
input  wire                             aclk                    ,
input  wire                             aresetn                 ,
input  wire        [NUM-1:0]            s_axis_divisor_tvalid   ,
input  wire signed [NUM-1:0][IDW-1:0]   s_axis_divisor_tdata    ,
                       
input  wire        [NUM-1:0]            s_axis_dividend_tvalid  ,
input  wire signed [NUM-1:0][IDW-1:0]   s_axis_dividend_tdata   ,
                       
output wire        [NUM-1:0]            m_axis_dout_tvalid      ,
output wire signed [NUM-1:0][ODW-1:0]   m_axis_dout_tdata       ,

input   wire       [2-1:0][40-1:0]      ln_mean_dividend        ,
input   wire       [2-1:0][16-1:0]      ln_mean_divisor         ,
output  wire       [2-1:0][48-1:0]      ln_mean_result              
);


//------------------------------------------------------------------------
// 16 cycle
//------------------------------------------------------------------------

generate for(genvar i=0;i<NUM;i=i+1)
begin:g0    
`ifndef SIM_DIV

        (*keep_hierarchy="yes" *)
        DIV_share DIVs (
            .aclk                  ( aclk                      ),
            .s_axis_divisor_tvalid ( s_axis_divisor_tvalid[i]  ),
            .s_axis_divisor_tdata  ( s_axis_divisor_tdata[i]   ),

            .s_axis_dividend_tvalid( s_axis_dividend_tvalid[i] ),
            .s_axis_dividend_tdata ( s_axis_dividend_tdata[i]  ),
            
            .m_axis_dout_tvalid    ( m_axis_dout_tvalid[i]     ),
            .m_axis_dout_tdata     ( m_axis_dout_tdata[i]      ) 
        );
/*
    //--------------------------------------------------------------------------------------------
    reg  signed [23:0] m_result_int_out[31:0];
    reg  signed [15:0] m_result_pot_out[31:0];
    reg  signed [39:0] m_result_out    [31:0];
    reg  signed [23:0] div_result_int_out[31:0];
    reg  signed [15:0] div_result_pot_out[31:0];
    reg  signed [39:0] div_result_out    [31:0];
    reg  test_int [31:0];
    reg  test_pot [31:0];
    reg  test_out [31:0];

    wire signed [39:0] div_dividend_shift ={s_axis_dividend_tdata[i*IDW+ IDW-1],
                                            s_axis_dividend_tdata[i*IDW+:IDW],15'd0} ;//fenzi
    wire signed [39:0] div_dividend       =$signed(s_axis_dividend_tdata[i*IDW+:IDW]);//fenzi
    wire signed [39:0] div_divisor        =$signed(s_axis_divisor_tdata [i*IDW+:IDW]);//fenmu
    wire signed [23:0] div_result_int_in  ;
    wire signed [15:0] div_result_pot_in  ;
    wire signed [39:0] div_result_in      ;

    assign div_result_int_in      = (div_divisor==0)?0:$signed(div_dividend      /div_divisor);
    
    assign div_result_pot_in[14:0]= (div_divisor==0)?0:$signed(div_dividend_shift/div_divisor);
    assign div_result_pot_in[15]  = (div_divisor==0)?0:(div_result_pot_in[14:0]==0)
                                                    ?0:div_dividend_shift[39]^div_divisor[39];
    
    assign div_result_in          = {div_result_int_in,div_result_pot_in};
    
    wire  signed [23:0] r_div_result_int_out;
    wire  signed [15:0] r_div_result_pot_out;
    wire  signed [39:0] r_div_result_out    ;
    localparam  DIV_DLY   =3;
    (*keep_hierarchy="yes"*)dly_cell #(
      .DW                      ( ODW*2                                  ),
      .DLY                     ( DIV_DLY-1                              )
     ) DIV_SIM(
      .dout                    ( {r_div_result_int_out,
                                  r_div_result_pot_out,
                                  r_div_result_out}),
      .din                     ( {div_result_int_in,
                                  div_result_pot_in,
                                  div_result_in}),
      .clk                     ( aclk                                   ),
      .reset                   ( 1'b0                                   )
     );

    always @(posedge aclk)
    begin
         
         div_result_int_out[i] <= r_div_result_int_out;
         div_result_pot_out[i] <= r_div_result_pot_out;
         div_result_out    [i] <= r_div_result_out    ;
         test_int[i] <=div_result_int_out[i]!=m_axis_dout_tdata[i*ODW+16+:24 ];
         test_pot[i] <=div_result_pot_out[i]!=m_axis_dout_tdata[i*ODW+0 +:16 ];
         test_out[i] <=div_result_out    [i]!=m_axis_dout_tdata[i*ODW+0 +:ODW];
    end


    always @(*)
    begin
         m_result_pot_out[i] <= m_axis_dout_tdata[i*ODW+0 +:16 ];
         m_result_int_out[i] <= m_axis_dout_tdata[i*ODW+16+:24 ];
         m_result_out    [i] <= m_axis_dout_tdata[i*ODW+0 +:ODW];
    end
*/


`else
    wire [IDW-1:0]  s_axis_dividend_tdata_r=s_axis_dividend_tdata[i];
    wire signed [39:0] div_dividend_shift ={s_axis_dividend_tdata_r[IDW-1],
                                            s_axis_dividend_tdata_r,15'd0} ;//fenzi
    wire signed [39:0] div_dividend=$signed(s_axis_dividend_tdata[i]);//fenzi
    wire signed [39:0] div_divisor =$signed(s_axis_divisor_tdata [i]);//fenmu
    wire signed [23:0] div_result_int_in  ;
    wire signed [15:0] div_result_pot_in  ;
    wire signed [39:0] div_result_in      ;

    assign div_result_int_in      = (div_divisor==0)?0:$signed(div_dividend      /div_divisor);
    assign div_result_pot_in[14:0]= (div_divisor==0)?0:$signed(div_dividend_shift/div_divisor);
    assign div_result_pot_in[15]  = (div_divisor==0)?0:(div_result_pot_in[14:0]==0)
                                                    ?0:div_dividend_shift[39]^div_divisor[39];
    assign div_result_in          = {div_result_int_in,div_result_pot_in};
    
    wire signed [15:0] div_result_pot_out   ;
    wire signed [23:0] div_result_int_out   ;
    wire signed [39:0] div_result_out       ;

    localparam  DIV_DLY   =20;
    (*keep_hierarchy="yes"*)dly_cell #(
      .DW                      ( ODW*2              ),
      .DLY                     ( DIV_DLY            )
     ) DIV_SIM(
      .dout                    ( {div_result_pot_out,
                                  div_result_int_out,
                                  div_result_out}),
      .din                     ( {div_result_pot_in,
                                  div_result_int_in,
                                  div_result_in}),
      .clk                     ( aclk               ),
      .reset                   ( 1'b0               )
     );


       assign m_axis_dout_tvalid[i]    =1;  
       assign m_axis_dout_tdata[i]     =div_result_out;  

`endif


end
endgenerate

//---------------------------------------------------------------------
//
//---------------------------------------------------------------------



generate for(genvar i=0;i<2;i=i+1)
begin:g1
  (*keep_hierarchy="yes" *)
  DIV_mean u0_div (
      .aclk                   ( aclk                ),
      .s_axis_divisor_tvalid  ( 1'b1                ),
      .s_axis_divisor_tdata   ( ln_mean_divisor[i]  ),
      .s_axis_dividend_tvalid ( 1'b1                ),
      .s_axis_dividend_tdata  ( ln_mean_dividend[i] ),
      .m_axis_dout_tvalid     (                     ),
      .m_axis_dout_tdata      ( ln_mean_result[i]   )
    );





end
endgenerate














endmodule
