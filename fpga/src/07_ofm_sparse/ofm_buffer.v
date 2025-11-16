

`timescale 1ns / 1ps
`include "opu_parameter.vh"



module ofm_buffer #(
  parameter    NUM                      = 32                ,
  parameter    PNUM                     = 4                 ,
  parameter    DW_RAM                   = 32                ,
  parameter    DW_NVM                   = 16                ,
  parameter    RAM_CYCLE                = 2                 ,
  parameter    RAM_ADDR                 = 15                ,
  parameter    RAM_DATA                 = 1024 
)(
  input                                 clk                 ,
  input                                 reset               ,

  input       [PNUM-1:0]                ofm_wvld            ,
  input       [PNUM-1:0][RAM_ADDR-1:0]  ofm_waddr           ,
  input       [PNUM-1:0][RAM_DATA-1:0]  ofm_wdata           ,
  input       [PNUM-1:0][RAM_ADDR-1:0]  ofm_raddr           ,
  input       [PNUM-1:0]                ofm_raddr_vld       ,
  
  input       [PNUM-1:0]                NVM_R_EN            ,   
  input       [PNUM-1:0][RAM_ADDR-1:0]  NVM_R_ADDR          ,
  input       [PNUM-1:0]                NVM_W_WEN           ,
  input       [PNUM-1:0][RAM_ADDR-1:0]  NVM_W_ADDR          ,
  input       [PNUM-1:0][RAM_DATA-1:0]  NVM_W_DATA          ,
  output wire [PNUM-1:0][RAM_DATA-1:0]  ram_doutb           , 
  output reg  [PNUM-1:0]                ram_rvld_ofm   =0   , 
  output reg  [PNUM-1:0]                ram_rvld_nvm   =0     
);

integer i=0,j=0;

//--------------------------------------------------------------------
// write
//--------------------------------------------------------------------
reg     [PNUM-1:0]          RAM_W_WEN        =0             ; 
reg     [11-1:0]            RAM_W_ADDR[PNUM-1:0]            ; 
reg     [RAM_DATA-1:0]      RAM_W_DATA[PNUM-1:0]            ; 

always @(posedge clk)
for(i=0;i<PNUM;i=i+1)
begin
  RAM_W_WEN [i]<=NVM_W_WEN[i]?NVM_W_WEN [i]:ofm_wvld[i]     ;
  RAM_W_ADDR[i]<=NVM_W_WEN[i]?NVM_W_ADDR[i]:ofm_waddr[i]>>2 ;
end


//--------------------------------------------------------------------
// read
//--------------------------------------------------------------------
reg     [11-1:0]            RAM_R_ADDR[PNUM-1:0]            ; 
wire    [PNUM*RAM_DATA-1:0] RAM_R_DATA                      ; 
always @(posedge clk)
for(i=0;i<PNUM;i=i+1)
begin
    if(NVM_R_EN[i])
         RAM_R_ADDR[i] <=  NVM_R_ADDR[i]                    ;
    else RAM_R_ADDR[i] <=  ofm_raddr [i]>>2                 ;
end


reg     [RAM_CYCLE*8-1:0]  dly_vd      =0                   ;
always @(posedge clk)
for(i=0;i<RAM_CYCLE;i=i+1)
if(i==0)dly_vd[i*8+:8] <= {ofm_raddr_vld,NVM_R_EN}          ;
else    dly_vd[i*8+:8] <=  dly_vd[(i-1)*8+:8]               ;

always @(posedge clk)
begin
    ram_rvld_ofm       <=  dly_vd[(RAM_CYCLE-1)*8+4+:4]     ;
    ram_rvld_nvm       <=  dly_vd[(RAM_CYCLE-1)*8+0+:4]     ;
end

//--------------------------------------------------------------
//
//--------------------------------------------------------------

generate 
for(genvar i=0;i<PNUM;i=i+1 )
begin:RAM

wire [RAM_DATA-1:0] RAM_W_DATA_nvm  = NVM_W_DATA[i]         ;
wire [RAM_DATA-1:0] RAM_W_DATA_ofm  = ofm_wdata[i]          ;

/*
always @(posedge clk)
for(j=0;j<NUM;j=j+1)
begin
    if(NVM_W_WEN[i*NUM+j])
    RAM_W_DATA [i][j*DW_RAM+:DW_RAM]<=
    RAM_W_DATA_nvm[j*DW_RAM+:DW_RAM]                        ;

    else
  
    RAM_W_DATA [i][j*DW_RAM+:DW_RAM]<=
    RAM_W_DATA_ofm[j*DW_RAM+:DW_RAM]                        ;   
end
*/

always @(posedge clk)
begin
    if(NVM_W_WEN[i]) RAM_W_DATA [i]<=RAM_W_DATA_nvm         ;
    else             RAM_W_DATA [i]<=RAM_W_DATA_ofm         ;   
end




(*keep_hierarchy="yes"*)tdpram # (
    .ADDR_WIDTH     ( 11                                    ),//11,RAM_ADDR-PNUM
    .DATA_WIDTH     ( RAM_DATA                              ),
    .RD_DLY         ( RAM_CYCLE                             ),
    .MEM_TYPE       ( "block"                               )
)u0_uram_buffer     (
    .douta          (                                       ),
    .wea            ( RAM_W_WEN [i]                         ),
    .addra          ( RAM_W_ADDR[i]                         ),         
    .dina           ( RAM_W_DATA[i]                         ),
    .dinb           ( 1024'h0                               ),    
    .ena            ( 1'b1                                  ),
    .enb            ( 1'b1                                  ),
    .web            ( 1'b0                                  ),
    .addrb          ( RAM_R_ADDR[i]                         ),
    .doutb          ( RAM_R_DATA[i*RAM_DATA+:RAM_DATA]      ),
    .clk            ( clk                                   ),
    .reset          ( 1'b0                                  )
);



`ifndef SIM_CODE
    assign ram_doutb[i]=RAM_R_DATA[i*RAM_DATA+:RAM_DATA]    ;
`else
    assign ram_doutb[i]=~(ram_rvld_ofm[i]||ram_rvld_nvm[i])?0:
                        RAM_R_DATA[i*RAM_DATA+:RAM_DATA]    ;
`endif


end
endgenerate


endmodule
