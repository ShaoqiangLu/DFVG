`timescale 1ns / 1ps
// -----------------------------------------------------------------------------
// Orgnization: UCLA EDA lab
// Design Name    : opu series
// Module Name    : output_ctrl_top
// Target Devices : k325t
// Tool Versions  : Vivado 2020.1, Modelsim 2019.4
// Description    : 
//    Add bias or temp results to finalize the calculation of one convolutional
//    layer.
// Revision       :
// Version        Date        Author          Description
// 1.0            2017-10-25  Chen Wu         Initial version
// 1.1            2020-02-04  Chen Wu         Modify code style
// 3.1            2021-02-01  Shan Shen       Change data width to 42 from 26
// 3.2            2021-04-07  Jinming Zhuang  Modify & specify the sequential 
//                                            relationship in internal signals
// 4.0            2021-04-26  Chen Wu         Add parameter & delete rearrange
// 4.1            2022-04--7  Chen Wu         Simplify for INT16 case, add pp
// 5.0            2022-09-14  Shaoqiang       Simulation 97 layers,and       
//                                            implementation on FPGA of U200.
// -----------------------------------------------------------------------------
`include "opu_parameter.vh"
module ofm_nvm_data #(
  parameter     NUM                 =   32                      ,
  parameter     PNUM                =   4                       ,
  parameter     DW_NVM              =   16                      ,
  parameter     DW_RAM              =   32                      ,
  parameter     RAM_DATA            =   1024                    ,
  parameter     DLY_RAM_R           =   6                       
)(
  input                             clk                         ,
  input                             reset                       ,
  input         [15-1:0]            nvm_raddr                   ,
  input                             nvm_raddr_vld               ,
  input                             nvm_raddr_done              ,
  output reg    [NUM-1:0][DW_NVM-1:0]nvm_rdata                  ,
  output wire                       nvm_rdata_vld               ,
  output wire                       nvm_rdata_done              ,
  input         [15-1:0]            back_raddr                  ,
  input                             back_raddr_vld              ,
  output reg    [NUM-1:0][DW_NVM-1:0]back_rdata                 ,
  output wire                       back_rdata_vld              ,
  output reg    [PNUM-1:0]          NVM_R_EN        =0          ,
  output reg    [PNUM-1:0][15-1:0]  NVM_R_ADDR      =0          ,
  input         [PNUM-1:0][RAM_DATA-1:0]NVM_R_DATA              , 
  input         [PNUM-1:0]          NVM_R_VLD                   ,
  //  
  output reg    [PNUM-1:0]          NVM_W_WEN       =0          ,
  output reg    [PNUM-1:0][15-1:0]  NVM_W_ADDR      =0          ,                      
  output reg    [NUM-1:0][DW_RAM-1:0]NVM_W_DATA     =0          ,  
  input         [NUM-1:0][DW_NVM-1:0]back_wdata                 ,
  input         [15-1:0]            back_waddr                  ,                      
  input                             back_wvld                   ,
  input                             back_wdone                  ,
  
  input                             nvm_res_en                  ,
  
  input        [NUM*DW_NVM-1:0]     res_load_data               ,
  input                             res_load_vld                ,
  input                             res_load_done               ,
  
  output reg   [NUM-1:0][DW_NVM-1:0]nvm_res_rdata      =0       ,
  output wire                       nvm_res_rdata_vld      
  
  
);
integer i=0;
//-----------------------------------------------------------------
//read
//-----------------------------------------------------------------
wire                    res_load_done0                          ;
reg     [15-1:0]        res_load_addr1           =0             ;//0,2,4,6
reg     [15-1:0]        res_load_addr2           =0             ;//0,1,0,1
reg     [15-1:0]        res_load_addr3           =0             ;//0,128,256,384
wire    [15-1:0]        res_load_addr                           ;
reg     [DW_NVM-1:0]    res_data_out      [NUM-1:0]             ;


always @(posedge clk)
if(nvm_raddr_vld)
begin
    NVM_R_EN  [0]<= nvm_raddr[1:0]==0                           ;
    NVM_R_ADDR[0]<= nvm_raddr[1:0]==0?nvm_raddr[14:2]:0         ;
    
    NVM_R_EN  [1]<= nvm_raddr[1:0]==1                           ;
    NVM_R_ADDR[1]<= nvm_raddr[1:0]==1?nvm_raddr[14:2]:0         ;
    
    NVM_R_EN  [2]<= nvm_raddr[1:0]==2                           ;
    NVM_R_ADDR[2]<= nvm_raddr[1:0]==2?nvm_raddr[14:2]:0         ;
    
    NVM_R_EN  [3]<= nvm_raddr[1:0]==3                           ;
    NVM_R_ADDR[3]<= nvm_raddr[1:0]==3?nvm_raddr[14:2]:0         ;
end
else if(back_raddr_vld)
begin
    NVM_R_EN  [0]<= back_raddr[1:0]==0                          ;
    NVM_R_ADDR[0]<= back_raddr[1:0]==0?back_raddr[14:2]:0       ;
    
    NVM_R_EN  [1]<= back_raddr[1:0]==1                          ;
    NVM_R_ADDR[1]<= back_raddr[1:0]==1?back_raddr[14:2]:0       ;
    
    NVM_R_EN  [2]<= back_raddr[1:0]==2                          ;
    NVM_R_ADDR[2]<= back_raddr[1:0]==2?back_raddr[14:2]:0       ;
    
    NVM_R_EN  [3]<= back_raddr[1:0]==3                          ;
    NVM_R_ADDR[3]<= back_raddr[1:0]==3?back_raddr[14:2]:0       ;
end
else if(res_load_vld)
begin
    NVM_R_EN  [0]<= res_load_addr[1:0]==0                       ;
    NVM_R_ADDR[0]<= res_load_addr[1:0]==0?res_load_addr[14:2]:0 ;
    
    NVM_R_EN  [1]<= res_load_addr[1:0]==1                       ;
    NVM_R_ADDR[1]<= res_load_addr[1:0]==1?res_load_addr[14:2]:0 ;
    
    NVM_R_EN  [2]<= res_load_addr[1:0]==2                       ;
    NVM_R_ADDR[2]<= res_load_addr[1:0]==2?res_load_addr[14:2]:0 ;
    
    NVM_R_EN  [3]<= res_load_addr[1:0]==3                       ;
    NVM_R_ADDR[3]<= res_load_addr[1:0]==3?res_load_addr[14:2]:0 ;
end
else begin
    NVM_R_EN  [0]<= 0                                           ;
    NVM_R_ADDR[0]<= 0                                           ;
    NVM_R_EN  [1]<= 0                                           ;
    NVM_R_ADDR[1]<= 0                                           ;
    NVM_R_EN  [2]<= 0                                           ;
    NVM_R_ADDR[2]<= 0                                           ;
    NVM_R_EN  [3]<= 0                                           ;
    NVM_R_ADDR[3]<= 0                                           ;
end


(*dont_touch="true"*)reg [2-1:0]        NVM_R_DATA_CNT=0        ;
(*dont_touch="true"*)reg [RAM_DATA-1:0] NVM_R_DATA_MUX=0        ; 


localparam   DW_DLY   = (15+1)+(15+1)+(15+1+1)                  ;//49
reg [DLY_RAM_R*DW_DLY-1:0] dly_rn_reg        =0                 ;

always @(posedge clk)
begin
//    for(i=0;i<NUM;i=i+1)
    (*full_case*)
    case(NVM_R_DATA_CNT)
    2'd0   :NVM_R_DATA_MUX  <=  NVM_R_DATA[0]                   ;
    2'd1   :NVM_R_DATA_MUX  <=  NVM_R_DATA[1]                   ;
    2'd2   :NVM_R_DATA_MUX  <=  NVM_R_DATA[2]                   ;
    default:NVM_R_DATA_MUX  <=  NVM_R_DATA[3]                   ;
    endcase
end
always @(posedge clk)
for(i=0;i<NUM;i=i+1)
begin
`ifndef SIM_CODE
    nvm_rdata    [i]<= NVM_R_DATA_MUX[i*DW_RAM       +:DW_NVM]  ;
    back_rdata   [i]<= NVM_R_DATA_MUX[i*DW_RAM       +:DW_NVM]  ;
    res_data_out [i]<= NVM_R_DATA_MUX[i*DW_RAM       +:DW_NVM]  ;
    nvm_res_rdata[i]<= NVM_R_DATA_MUX[i*DW_RAM+DW_NVM+:DW_NVM]  ;
`else
    nvm_rdata    [i]<=~dly_rn_reg[(DLY_RAM_R-2)*DW_DLY+1 +:1]?0: NVM_R_DATA_MUX[i*DW_RAM       +:DW_NVM];
    back_rdata   [i]<=~dly_rn_reg[(DLY_RAM_R-2)*DW_DLY+17+:1]?0: NVM_R_DATA_MUX[i*DW_RAM       +:DW_NVM];
    res_data_out [i]<=~dly_rn_reg[(DLY_RAM_R-2)*DW_DLY+33+:1]?0: NVM_R_DATA_MUX[i*DW_RAM       +:DW_NVM];
    nvm_res_rdata[i]<=~dly_rn_reg[(DLY_RAM_R-2)*DW_DLY+1 +:1]?0: NVM_R_DATA_MUX[i*DW_RAM+DW_NVM+:DW_NVM];
`endif
end

//--------------------------------------------------------------------------

always @(posedge clk)
for(i=0;i<DLY_RAM_R;i=i+1)
if(i==0)dly_rn_reg[i*DW_DLY+:DW_DLY]<=
{       res_load_addr   ,//34+:15
        res_load_vld    ,//33+:1
        back_raddr      ,//18+:15
        back_raddr_vld  ,//17+:1
        nvm_raddr       ,//2 +:15
        nvm_raddr_vld   ,//1 +:1
        nvm_raddr_done   //0 +:1
};else  dly_rn_reg[i*DW_DLY+:DW_DLY]<=dly_rn_reg[(i-1)*DW_DLY+:DW_DLY];

assign  back_rdata_vld   =dly_rn_reg[(DLY_RAM_R-1)*DW_DLY+17+:1];
assign  nvm_rdata_vld    =dly_rn_reg[(DLY_RAM_R-1)*DW_DLY+1 +:1];
assign  nvm_rdata_done   =dly_rn_reg[(DLY_RAM_R-1)*DW_DLY+0 +:1];
assign  nvm_res_rdata_vld=dly_rn_reg[(DLY_RAM_R-1)*DW_DLY+1 +:1]&nvm_res_en;


always @(posedge clk)
begin
                 if(dly_rn_reg[(DLY_RAM_R-4)*DW_DLY+1 +:1])
    NVM_R_DATA_CNT<=dly_rn_reg[(DLY_RAM_R-4)*DW_DLY+2 +:15]     ;
    
            else if(dly_rn_reg[(DLY_RAM_R-4)*DW_DLY+17+:1])           
    NVM_R_DATA_CNT<=dly_rn_reg[(DLY_RAM_R-4)*DW_DLY+18+:15]     ;  

            else if(dly_rn_reg[(DLY_RAM_R-4)*DW_DLY+33+:1])           
    NVM_R_DATA_CNT<=dly_rn_reg[(DLY_RAM_R-4)*DW_DLY+34+:15]     ;          
end


//-----------------------------------------------------------------
//write
//-----------------------------------------------------------------
wire    [15-1:0]              res_waddr                         ;
wire                          res_wvld                          ;
wire    [NUM*DW_NVM-1:0]      res_wdata                         ;


always @(posedge clk)
if(back_wvld)
begin
    NVM_W_WEN [0]<=back_waddr[1:0]==0                           ;
    NVM_W_ADDR[0]<=back_waddr[1:0]==0?back_waddr[14:2]:0        ;
    
    NVM_W_WEN [1]<=back_waddr[1:0]==1                           ;
    NVM_W_ADDR[1]<=back_waddr[1:0]==1?back_waddr[14:2]:0        ;
    
    NVM_W_WEN [2]<=back_waddr[1:0]==2                           ;
    NVM_W_ADDR[2]<=back_waddr[1:0]==2?back_waddr[14:2]:0        ;
    
    NVM_W_WEN [3]<=back_waddr[1:0]==3                           ;
    NVM_W_ADDR[3]<=back_waddr[1:0]==3?back_waddr[14:2]:0        ;

    for(i=0;i<NUM;i=i+1)NVM_W_DATA[i]<={{DW_NVM{1'b0}},back_wdata[i]};
end
else if(res_wvld)
begin
    NVM_W_WEN [0]<=res_waddr[1:0]==0                            ;
    NVM_W_ADDR[0]<=res_waddr[1:0]==0?res_waddr[14:2]:0          ;
    
    NVM_W_WEN [1]<=res_waddr[1:0]==1                            ;
    NVM_W_ADDR[1]<=res_waddr[1:0]==1?res_waddr[14:2]:0          ;
    
    NVM_W_WEN [2]<=res_waddr[1:0]==2                            ;
    NVM_W_ADDR[2]<=res_waddr[1:0]==2?res_waddr[14:2]:0          ;
    
    NVM_W_WEN [3]<=res_waddr[1:0]==3                            ;
    NVM_W_ADDR[3]<=res_waddr[1:0]==3?res_waddr[14:2]:0          ;

    for(i=0;i<NUM;i=i+1)
    NVM_W_DATA[i]<={res_wdata[i*DW_NVM+:DW_NVM],res_data_out[i]};
end
else begin
    NVM_W_WEN [0]<=0                                            ;
    NVM_W_ADDR[0]<=0                                            ;
    NVM_W_WEN [1]<=0                                            ;
    NVM_W_ADDR[1]<=0                                            ;
    NVM_W_WEN [2]<=0                                            ;
    NVM_W_ADDR[2]<=0                                            ;
    NVM_W_WEN [3]<=0                                            ;
    NVM_W_ADDR[3]<=0                                            ;
    for(i=0;i<NUM;i=i+1)NVM_W_DATA[i]<=0                        ;
end

//-----------------------------------------------------------------
//residual
//-----------------------------------------------------------------
//read 
always @(posedge clk) 
if(back_wdone)          res_load_addr1<=0                       ;
else if(res_load_done|| res_load_done0) res_load_addr1<=0       ;
else if(res_load_vld)   res_load_addr1<=res_load_addr1+2        ;
else                    res_load_addr1<=0                       ;

assign res_load_done0=  res_load_addr1==126&res_load_vld        ;


//
always @(posedge clk)
if(back_wdone)          res_load_addr2<=0                       ;
else if(res_load_done|| res_load_done0)
begin
if(res_load_addr2==1)   res_load_addr2<=0                       ;
else                    res_load_addr2<=res_load_addr2+1        ;
end    
//
always @(posedge clk)
if(back_wdone)          res_load_addr3<=0                       ;
else if((res_load_done||res_load_done0)&&res_load_addr2==1)
        res_load_addr3<=res_load_addr3+128                      ;
//
assign  res_load_addr=  res_load_vld? (res_load_addr1+
                        res_load_addr2+res_load_addr3):0        ;

//write---------------------------------------------------------

localparam     DLYRESCNT   = 6                                  ;
localparam     DLYRESDW    = 512+15+1                           ;

reg [DLYRESCNT*DLYRESDW-1:0] dly_res_reg    =0                  ;

always @(posedge clk)
for(i=0;i<DLYRESCNT;i=i+1)
if(i==0)dly_res_reg[i*DLYRESDW+:DLYRESDW]<=
{       res_load_data   ,//16+:512
        res_load_addr   ,//1 +:15
        res_load_vld     //0 +:1
};else  dly_res_reg[ i*   DLYRESDW+:DLYRESDW]<=
        dly_res_reg[(i-1)*DLYRESDW+:DLYRESDW];

assign  res_wdata = dly_res_reg[(DLYRESCNT-1)*DLYRESDW+16+:512] ;
assign  res_waddr = dly_res_reg[(DLYRESCNT-1)*DLYRESDW+1 +:15 ] ;
assign  res_wvld  = dly_res_reg[(DLYRESCNT-1)*DLYRESDW+0 +:1  ] ;







endmodule
