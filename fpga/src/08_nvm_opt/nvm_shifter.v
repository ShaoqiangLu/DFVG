// -----------------------------------------------------------------------------
// Copyright      : UCLA EDA LAB
// -----------------------------------------------------------------------------
// Engineer       : Chen Wu
// Design Name    : opu series
// Module Name    : nvm_top
// Target Devices : 325t, Alveo U200
// Tool Versions  : Vivado 2020.1, Modelsim 2019.4
// Description    : 
// Revision       :
// Version        Date        Author        Descriptin
// 2.0            2023-08-25  Shaoqiang     Implementation in U200
// -----------------------------------------------------------------------------
// >>> arithmetic right,high: positive is add 0, negative is add 1
// <<< arithmetic left, low add 0,note May benefit          
// Simulations are all complement codes
// <<  logic left,  low add 0
// >>  logic right, high add 0
// <<< arithmetic left, low add 0
// >>> arithmetic right,high: positive is add 0, negative is add 1  
// soft-max is Fixed precision: Q16_9
                                                       


`include "opu_parameter.vh"
module nvm_shifter #(
    parameter DW    = 16,
    parameter NUM   = 32
    
)(
    input                           clk                         ,
	input                           rst                         ,
	input                           shift_sel                   ,//=1--->in1

	input       [4-1:0]             shift_in0_init_num          ,
	input       [4-1:0]             shift_in0_post_num          ,
	input                           shift_in1_nvm_dir           ,
    input       [4-1:0]             shift_in1_nvm_num           ,

    input                           shift_in0_vld               ,
    input                           shift_in0_done              ,
    input       [NUM*DW-1:0]        shift_in0_data              ,

    input                           shift_in1_vld               ,
    input                           shift_in1_done              ,
    input       [NUM*DW-1:0]        shift_in1_data              ,

    output wire [NUM*DW-1:0]        shift_out0_data             ,
    output wire                     shift_out0_vld              ,
    output wire                     shift_out0_done             ,

    output wire [NUM*DW-1:0]        shift_out1_data             ,
    output wire                     shift_out1_vld              ,
    output wire                     shift_out1_done             
);
integer i=0,j=0;

(*dont_touch="true"*)reg            shift_sel_in    =0          ;
(*dont_touch="true"*)reg [NUM-1:0]  shift_sel_out   =0          ;
(*dont_touch="true"*)reg [4-1:0]    shift_num_left  =0          ;
(*dont_touch="true"*)reg [4-1:0]    shift_num_right =0          ;
(*dont_touch="true"*)reg [NUM-1:0]  shift_dir       =0          ;
reg       [4-1:0]                   shift_in0_init_num_r   =0   ;
reg       [4-1:0]                   shift_in0_post_num_r   =0   ;


always @(posedge clk)
begin
    shift_sel_in        <= shift_sel                            ;
    shift_sel_out       <={NUM{shift_sel}}                      ; 
    shift_in0_init_num_r<=shift_in0_init_num                    ;
    shift_in0_post_num_r<=shift_in0_post_num                    ;
end

always @(posedge clk)
if(shift_sel_in)
begin
     shift_num_left  <= shift_in1_nvm_num                       ;
     shift_num_right <= shift_in1_nvm_num                       ; 
     shift_dir       <= {NUM{shift_in1_nvm_dir}}                ;
end else begin
//--------------------------------------------------------------
                        if(shift_in0_post_num_r>shift_in0_init_num_r) 
     begin shift_num_left<=shift_in0_post_num_r-shift_in0_init_num_r;shift_dir<={NUM{1'b1}};end//<<<
else                    if(shift_in0_post_num_r<shift_in0_init_num_r) 
     begin shift_num_left<=shift_in0_init_num_r-shift_in0_post_num_r;shift_dir<={NUM{1'b0}};end//>>>
else begin shift_num_left<=0                                        ;shift_dir<={NUM{1'b0}};end
//--------------------------------------------------------------

//--------------------------------------------------------------
                         if(shift_in0_post_num_r>shift_in0_init_num_r) 
     begin shift_num_right<=shift_in0_post_num_r-shift_in0_init_num_r;shift_dir<={NUM{1'b1}};end//<<<
else                     if(shift_in0_post_num_r<shift_in0_init_num_r) 
     begin shift_num_right<=shift_in0_init_num_r-shift_in0_post_num_r;shift_dir<={NUM{1'b0}};end//>>>
else begin shift_num_right<=0                                        ;shift_dir<={NUM{1'b0}};end
//--------------------------------------------------------------

end




//---------------------------------------------------------------
//
//---------------------------------------------------------------
    reg   [NUM-1:0]     shift_spill    =0                       ;
    reg   [NUM-1:0]     shift_nega     =0                       ;
    reg   [NUM*DW-1:0]  shift_result   =0                       ;

generate for ( genvar i=0; i<NUM; i=i+1 )
begin:s
    //-------------------------------------------------------------
    reg signed [DW-1:0]  r0_data    =0                          ;
    always @(posedge clk)
    if(shift_sel_out[i]) r0_data<=shift_in1_data[i*DW+:DW]      ;
    else                 r0_data<=shift_in0_data[i*DW+:DW]      ;
    //-------------------------------------------------------------
    reg     [DW-1:0]    r1_data     =0                          ;
    reg     [DW-1:0]    r1_shift    =0                          ;

    
    always @(posedge clk) shift_nega[i]<= r0_data[DW-1]         ;        
    
    always @(posedge clk)
    if(shift_dir[i])
    begin
       r1_shift <=$signed(r0_data)<<< shift_num_left            ;//
     case(shift_num_left)
     4'd1   :shift_spill[i]<=|(r0_data[DW-2-:1 ]^{1 {r0_data[DW-1]}});
     4'd2   :shift_spill[i]<=|(r0_data[DW-2-:2 ]^{2 {r0_data[DW-1]}});
     4'd3   :shift_spill[i]<=|(r0_data[DW-2-:3 ]^{3 {r0_data[DW-1]}});
     4'd4   :shift_spill[i]<=|(r0_data[DW-2-:4 ]^{4 {r0_data[DW-1]}});
     4'd5   :shift_spill[i]<=|(r0_data[DW-2-:5 ]^{5 {r0_data[DW-1]}});
     4'd6   :shift_spill[i]<=|(r0_data[DW-2-:6 ]^{6 {r0_data[DW-1]}});
     4'd7   :shift_spill[i]<=|(r0_data[DW-2-:7 ]^{7 {r0_data[DW-1]}});
     4'd8   :shift_spill[i]<=|(r0_data[DW-2-:8 ]^{8 {r0_data[DW-1]}});
     4'd9   :shift_spill[i]<=|(r0_data[DW-2-:9 ]^{9 {r0_data[DW-1]}});
     4'd10  :shift_spill[i]<=|(r0_data[DW-2-:10]^{10{r0_data[DW-1]}});
     4'd11  :shift_spill[i]<=|(r0_data[DW-2-:11]^{11{r0_data[DW-1]}});
     4'd12  :shift_spill[i]<=|(r0_data[DW-2-:12]^{12{r0_data[DW-1]}});
     4'd13  :shift_spill[i]<=|(r0_data[DW-2-:13]^{13{r0_data[DW-1]}});
     4'd14  :shift_spill[i]<=|(r0_data[DW-2-:14]^{14{r0_data[DW-1]}});
     4'd15  :shift_spill[i]<=|(r0_data[DW-2-:15]^{15{r0_data[DW-1]}});
     default:shift_spill[i]<=0;
     endcase
    end
    else begin
        r1_shift<=$signed(r0_data)>>>shift_num_right            ;   
        shift_spill[i]<=0;
    end

    //--------------------------------------------------------------
    always @(posedge clk) 
    if(shift_spill[i])begin
     if(shift_nega[i])shift_result[i*DW+:DW]<={1'b1,{(DW-1){1'b0}}};
        else          shift_result[i*DW+:DW]<={1'b0,{(DW-1){1'b1}}};
    end else          shift_result[i*DW+:DW]<=r1_shift             ;
    
end
endgenerate

`ifndef SIM_CODE
    assign  shift_out0_data = shift_result                      ;
    assign  shift_out1_data = shift_result                      ;
`else
    assign  shift_out0_data =~shift_sel_out[0]?shift_result:0   ;
    assign  shift_out1_data = shift_sel_out[0]?shift_result:0   ;
`endif




//---------------------------------------------------------------
//
//---------------------------------------------------------------
    localparam          DLY_SH          =3                      ;
    reg [DLY_SH*4-1:0]  dly_vd_reg      =0                      ;

    always @(posedge clk)
    for(i=0;i<DLY_SH;i=i+1)
    if(i==0)dly_vd_reg[i*4+:4]<={shift_in0_vld ,shift_in0_done  ,
                                 shift_in1_vld ,shift_in1_done} ;
    else    dly_vd_reg[i*4+:4]<=dly_vd_reg[(i-1)*4+:4]          ;


    assign  shift_out0_vld =dly_vd_reg[(DLY_SH-1)*4+3+:1]       ;
    assign  shift_out0_done=dly_vd_reg[(DLY_SH-1)*4+2+:1]       ;
    assign  shift_out1_vld =dly_vd_reg[(DLY_SH-1)*4+1+:1]       ;
    assign  shift_out1_done=dly_vd_reg[(DLY_SH-1)*4+0+:1]       ;




endmodule