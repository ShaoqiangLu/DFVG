`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/13/2023 09:56:44 AM
// Design Name: 
// Module Name: point
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: You can check the size of the fixed point number. 
//              And I will help you save the data.
//              Note that this is a circuit that cannot be integrated. 
//              Just for your convenience in debugging
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 1.0            2023-09-11  Shaoqiang     Functional simulation testing,
//                                         implementation on FPGA of U200.
//////////////////////////////////////////////////////////////////////////////////


module tb_display_data#(
    parameter     FILE0  =  "/home/lsq/Desktop/opu/rtl/src/12_data/",
    parameter     FILE1  =  "fix_name.txt",
    parameter     LAYER  =  1       ,
    parameter     NUM    =  32      ,
    parameter     IDW    =  16      ,
    parameter     ODW    =  16      ,
    parameter     HEX    =  1       ,
    parameter     MSB    =  1        //left is high
     
)(
    input                   clk     ,
    input   [10-1:0]        layer   , 
    input                   wvld    ,
    input   [NUM*IDW-1:0]   wdata        
);

integer i=0,file;

initial begin
         if(LAYER==1 )file = $fopen({FILE0,"1", FILE1},"w");
    else if(LAYER==2 )file = $fopen({FILE0,"2", FILE1},"w");
    else if(LAYER==3 )file = $fopen({FILE0,"3", FILE1},"w");
    else if(LAYER==4 )file = $fopen({FILE0,"4", FILE1},"w");
    else if(LAYER==5 )file = $fopen({FILE0,"5", FILE1},"w");
    else if(LAYER==6 )file = $fopen({FILE0,"6", FILE1},"w");
    else if(LAYER==7 )file = $fopen({FILE0,"7", FILE1},"w");
    else if(LAYER==8 )file = $fopen({FILE0,"8", FILE1},"w");
    else if(LAYER==9 )file = $fopen({FILE0,"9", FILE1},"w");
    else if(LAYER==10)file = $fopen({FILE0,"10",FILE1},"w");
    else if(LAYER==11)file = $fopen({FILE0,"11",FILE1},"w");
    else if(LAYER==12)file = $fopen({FILE0,"12",FILE1},"w");
    else if(LAYER==13)file = $fopen({FILE0,"13",FILE1},"w");
    else if(LAYER==14)file = $fopen({FILE0,"14",FILE1},"w");
    else if(LAYER==15)file = $fopen({FILE0,"15",FILE1},"w");
    else if(LAYER==16)file = $fopen({FILE0,"16",FILE1},"w");
    else if(LAYER==17)file = $fopen({FILE0,"17",FILE1},"w");
    else if(LAYER==18)file = $fopen({FILE0,"18",FILE1},"w");
    else if(LAYER==19)file = $fopen({FILE0,"19",FILE1},"w");
    else if(LAYER==20)file = $fopen({FILE0,"20",FILE1},"w");
    else if(LAYER==21)file = $fopen({FILE0,"21",FILE1},"w");
    else if(LAYER==22)file = $fopen({FILE0,"22",FILE1},"w");
    else if(LAYER==23)file = $fopen({FILE0,"23",FILE1},"w");
    else if(LAYER==24)file = $fopen({FILE0,"24",FILE1},"w");
    else if(LAYER==25)file = $fopen({FILE0,"25",FILE1},"w");
    else if(LAYER==26)file = $fopen({FILE0,"26",FILE1},"w");
    else if(LAYER==27)file = $fopen({FILE0,"27",FILE1},"w");
    else if(LAYER==28)file = $fopen({FILE0,"28",FILE1},"w");
    else if(LAYER==29)file = $fopen({FILE0,"29",FILE1},"w");
    else if(LAYER==30)file = $fopen({FILE0,"30",FILE1},"w");
    else if(LAYER==31)file = $fopen({FILE0,"31",FILE1},"w");
    else if(LAYER==32)file = $fopen({FILE0,"32",FILE1},"w");
    else if(LAYER==33)file = $fopen({FILE0,"33",FILE1},"w");
    else if(LAYER==34)file = $fopen({FILE0,"34",FILE1},"w");
    else if(LAYER==35)file = $fopen({FILE0,"35",FILE1},"w");
    else if(LAYER==36)file = $fopen({FILE0,"36",FILE1},"w");
    else if(LAYER==37)file = $fopen({FILE0,"37",FILE1},"w");
    else if(LAYER==38)file = $fopen({FILE0,"38",FILE1},"w");
    else if(LAYER==39)file = $fopen({FILE0,"39",FILE1},"w");
    else if(LAYER==40)file = $fopen({FILE0,"40",FILE1},"w");
    else if(LAYER==41)file = $fopen({FILE0,"41",FILE1},"w");
    else if(LAYER==42)file = $fopen({FILE0,"42",FILE1},"w");
    else if(LAYER==43)file = $fopen({FILE0,"43",FILE1},"w");
    else if(LAYER==44)file = $fopen({FILE0,"44",FILE1},"w");
    else if(LAYER==45)file = $fopen({FILE0,"45",FILE1},"w");
    else if(LAYER==46)file = $fopen({FILE0,"46",FILE1},"w");
    else if(LAYER==47)file = $fopen({FILE0,"47",FILE1},"w");
    else if(LAYER==48)file = $fopen({FILE0,"48",FILE1},"w");
    else if(LAYER==49)file = $fopen({FILE0,"49",FILE1},"w");
    else if(LAYER==50)file = $fopen({FILE0,"50",FILE1},"w");
    else if(LAYER==51)file = $fopen({FILE0,"51",FILE1},"w");
    else if(LAYER==52)file = $fopen({FILE0,"52",FILE1},"w");
    else if(LAYER==53)file = $fopen({FILE0,"53",FILE1},"w");
    else if(LAYER==54)file = $fopen({FILE0,"54",FILE1},"w");
    else if(LAYER==55)file = $fopen({FILE0,"55",FILE1},"w");
    else if(LAYER==56)file = $fopen({FILE0,"56",FILE1},"w");
    else if(LAYER==57)file = $fopen({FILE0,"57",FILE1},"w");
    else if(LAYER==58)file = $fopen({FILE0,"58",FILE1},"w");
    else if(LAYER==59)file = $fopen({FILE0,"59",FILE1},"w");
    else if(LAYER==60)file = $fopen({FILE0,"60",FILE1},"w");
    else if(LAYER==61)file = $fopen({FILE0,"61",FILE1},"w");
    else if(LAYER==62)file = $fopen({FILE0,"62",FILE1},"w");
    else if(LAYER==63)file = $fopen({FILE0,"63",FILE1},"w");
    else if(LAYER==64)file = $fopen({FILE0,"64",FILE1},"w");
    else if(LAYER==65)file = $fopen({FILE0,"65",FILE1},"w");
    else if(LAYER==66)file = $fopen({FILE0,"66",FILE1},"w");
    else if(LAYER==67)file = $fopen({FILE0,"67",FILE1},"w");
    else if(LAYER==68)file = $fopen({FILE0,"68",FILE1},"w");
    else if(LAYER==69)file = $fopen({FILE0,"69",FILE1},"w");
    else if(LAYER==70)file = $fopen({FILE0,"70",FILE1},"w");
    else if(LAYER==71)file = $fopen({FILE0,"71",FILE1},"w");
    else if(LAYER==72)file = $fopen({FILE0,"72",FILE1},"w");
    else if(LAYER==73)file = $fopen({FILE0,"73",FILE1},"w");
    else if(LAYER==74)file = $fopen({FILE0,"74",FILE1},"w");
    else if(LAYER==75)file = $fopen({FILE0,"75",FILE1},"w");
    else if(LAYER==76)file = $fopen({FILE0,"76",FILE1},"w");
    else if(LAYER==77)file = $fopen({FILE0,"77",FILE1},"w");
    else if(LAYER==78)file = $fopen({FILE0,"78",FILE1},"w");
    else if(LAYER==79)file = $fopen({FILE0,"79",FILE1},"w");
    else if(LAYER==80)file = $fopen({FILE0,"80",FILE1},"w");
    else if(LAYER==81)file = $fopen({FILE0,"81",FILE1},"w");
    else if(LAYER==82)file = $fopen({FILE0,"82",FILE1},"w");
    else if(LAYER==83)file = $fopen({FILE0,"83",FILE1},"w");
    else if(LAYER==84)file = $fopen({FILE0,"84",FILE1},"w");
    else if(LAYER==85)file = $fopen({FILE0,"85",FILE1},"w");
    else if(LAYER==86)file = $fopen({FILE0,"86",FILE1},"w");
    else if(LAYER==87)file = $fopen({FILE0,"87",FILE1},"w");
    else if(LAYER==88)file = $fopen({FILE0,"88",FILE1},"w");
    else if(LAYER==89)file = $fopen({FILE0,"89",FILE1},"w");
    else if(LAYER==90)file = $fopen({FILE0,"90",FILE1},"w");
    else if(LAYER==91)file = $fopen({FILE0,"91",FILE1},"w");
    else if(LAYER==92)file = $fopen({FILE0,"92",FILE1},"w");
    else if(LAYER==93)file = $fopen({FILE0,"93",FILE1},"w");
    else if(LAYER==94)file = $fopen({FILE0,"94",FILE1},"w");
    else if(LAYER==95)file = $fopen({FILE0,"95",FILE1},"w");
    else if(LAYER==96)file = $fopen({FILE0,"96",FILE1},"w");
    else if(LAYER==97)file = $fopen({FILE0,"97",FILE1},"w");
    else if(LAYER==98)file = $fopen({FILE0,"98",FILE1},"w");
end

reg [NUM*ODW-1:0]wdata_out=0; 


always @(*)
for(i=0;i<NUM;i=i+1)
begin
if(IDW==ODW)    wdata_out[i*ODW+:ODW]=wdata[i*IDW+:IDW];
else if(IDW<ODW)wdata_out[i*ODW+:ODW]=
    {{(ODW-IDW){wdata[i*IDW+IDW-1]}},
                wdata[i*IDW+:IDW]};
else if(IDW>ODW)wdata_out[i*ODW+:ODW]=
                wdata[i*IDW+:ODW];//IDW-1-
end



always @(posedge clk)
if(layer==LAYER&&wvld)
if(MSB==1)//-----------------------------------------------------
begin
for(i=NUM-1;i>=0;i=i-1)
if(HEX==1)begin
    if(i==0)    $fwrite(file,"%h\n",wdata_out[i*ODW+:ODW]);
    else        $fwrite(file,"%h " ,wdata_out[i*ODW+:ODW]);
end
else begin
    if(i==0)    $fwrite(file,"%d\n",wdata_out[i*ODW+:ODW]);
    else        $fwrite(file,"%d " ,wdata_out[i*ODW+:ODW]);
end
end 
else //----------------------------------------------------------
begin
for(i=0;i<NUM;i=i+1)
if(HEX==1)begin
    if(i==NUM-1)$fwrite(file,"%h\n",wdata_out[i*ODW+:ODW]);
    else        $fwrite(file,"%h " ,wdata_out[i*ODW+:ODW]);
end
else begin
    if(i==NUM-1)$fwrite(file,"%d\n",wdata_out[i*ODW+:ODW]);
    else        $fwrite(file,"%d " ,wdata_out[i*ODW+:ODW]);
end
end 





endmodule
