`timescale 1ns / 1ps

module ofm_shift_unit #(
  parameter  NUM     =              128                 ,
  parameter  IDW     =              37                  ,
  parameter  ODW     =              42   
        
)(
  input                             clk                 ,
  input                             reset               ,
  input      [5-1:0]                shift_num           ,
  input      [NUM-1:0][IDW-1:0]     shift_in            ,
  output reg [NUM-1:0][ODW-1:0]     shift_out=0
);


integer i=0,j=0;

(*dont_touch="true"*)reg[NUM*5-1:0] r0_shift_num    =0  ;
always @(posedge clk)   r0_shift_num<={NUM{shift_num}}  ;

  
generate 
for(genvar i=0;i<NUM;i=i+1 )
begin:s
//-----------------------------------------------------------------
        wire [IDW-1:0]r0_shift_in_wire                  ;
        reg  [ODW-1:0]r0_shift_in    =0                 ;
        assign r0_shift_in_wire=shift_in[i]             ;
        always @(posedge clk)
        if(ODW>IDW)
            r0_shift_in<={{(ODW-IDW){
            r0_shift_in_wire[IDW-1]}},
            r0_shift_in_wire};
        else
            r0_shift_in<= r0_shift_in_wire[ODW-1:0]     ;                

//-----------------------------------------------------------------
        reg [ODW-1:0]   r1_shift_in    =0               ;
        reg [ODW-1:0]   r1_result      =0               ;
        always @(posedge clk)
        begin
            r1_shift_in<=r0_shift_in;
            r1_result<=r0_shift_in<<<r0_shift_num[i*5+:5];
        end 
//-----------------------------------------------------------------
        always @(posedge clk)
        if(     r1_shift_in[ODW-1]==
                r1_result  [ODW-1])shift_out[i]<=r1_result             ;
        else if(r1_shift_in[ODW-1])shift_out[i]<={1'b1,{(ODW-1){1'b0}}};
        else                       shift_out[i]<={1'b0,{(ODW-1){1'b1}}};
//-------------------------------------------------------------------
end  
endgenerate



endmodule


