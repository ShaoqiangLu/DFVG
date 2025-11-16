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

module tb_display_float#(
    parameter     FILE0  =  "/home/lsq/Desktop/opu/rtl/src/12_data/",
    parameter     FILE1  =  "fix_name.txt",
    parameter     LAYER  =  1       ,
    parameter     NUM    =  32      ,
    parameter     IDW    =  16      
)(
    input                   clk     ,
    input   [10-1:0]        layer   , 
    input                   wvld    ,
    input   [NUM*IDW-1:0]   wdata   ,   
    output  real   wdata_out[NUM-1:0]
);

//----------------------------------------------------------
//
//----------------------------------------------------------
localparam POINT=
    LAYER==1?   (13):
    LAYER==2?   (12):
    LAYER==3?   (12):
    LAYER==4?   (14):
    LAYER==5?   (14):
    LAYER==6?   (9 ):
    LAYER==7?   (11):
    LAYER==8?   (11):
    LAYER==9?   (13):
    LAYER==10?  (12):
    LAYER==11?  (12):
    LAYER==12?  (14):
    LAYER==13?  (13):
    LAYER==14?  (9 ):
    LAYER==15?  (11):
    LAYER==16?  (11):
    LAYER==17?  (13):
    LAYER==18?  (12):
    LAYER==19?  (11):
    LAYER==20?  (14):
    LAYER==21?  (13):
    LAYER==22?  (7 ):
    LAYER==23?  (9 ):
    LAYER==24?  (11):
    LAYER==25?  (13):
    LAYER==26?  (12):
    LAYER==27?  (12):
    LAYER==28?  (14):
    LAYER==29?  (13):
    LAYER==30?  (8 ):
    LAYER==31?  (12):
    LAYER==32?  (11):
    LAYER==33?  (12):
    LAYER==34?  (12):
    LAYER==35?  (12):
    LAYER==36?  (14):
    LAYER==37?  (13):
    LAYER==38?  (8 ):
    LAYER==39?  (11):
    LAYER==40?  (11):
    LAYER==41?  (12):
    LAYER==42?  (12):
    LAYER==43?  (12):
    LAYER==44?  (14):
    LAYER==45?  (13):
    LAYER==46?  (8 ):
    LAYER==47?  (11):
    LAYER==48?  (11): 
    LAYER==49?  (12):     
    LAYER==50?  (12):     
    LAYER==51?  (11):     
    LAYER==52?  (14):     
    LAYER==53?  (13):     
    LAYER==54?  (8 ):     
    LAYER==55?  (12):     
    LAYER==56?  (11):     
    LAYER==57?  (13):     
    LAYER==58?  (12):     
    LAYER==59?  (11):     
    LAYER==60?  (14):     
    LAYER==61?  (13):     
    LAYER==62?  (8 ):     
    LAYER==63?  (12):     
    LAYER==64?  (11):     
    LAYER==65?  (12):
    LAYER==66?  (12):
    LAYER==67?  (12):
    LAYER==68?  (14):
    LAYER==69?  (13):
    LAYER==70?  (8 ):
    LAYER==71?  (12):
    LAYER==72?  (11):
    LAYER==73?  (13):
    LAYER==74?  (12):
    LAYER==75?  (12):
    LAYER==76?  (14):
    LAYER==77?  (13):
    LAYER==78?  (6 ):
    LAYER==79?  (9 ):
    LAYER==80?  (11):
    LAYER==81?  (12):
    LAYER==82?  (12):
    LAYER==83?  (12):
    LAYER==84?  (14):
    LAYER==85?  (13):
    LAYER==86?  (5 ):
    LAYER==87?  (8 ):
    LAYER==88?  (11):
    LAYER==89?  (12):
    LAYER==90?  (12):
    LAYER==91?  (12):
    LAYER==92?  (14):
    LAYER==93?  (13):
    LAYER==94?  (10):
    LAYER==95?  (12):
    LAYER==96?  (11):
    LAYER==97?  (15):0; 
 
//----------------------------------------------------------
//
//----------------------------------------------------------
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

//----------------------------------------------------------
//
//----------------------------------------------------------
    reg [IDW-2:0]data[NUM-1:0]  ; 
    real         sign[NUM-1:0]  ;   
    real unfold[NUM-1:0]        ;

    always @(wdata)
    for(i=0;i<NUM;i=i+1)
    begin
        sign[i]=wdata[i*IDW+ IDW-1+:1]?-1:1;
        data[i]=wdata[i*IDW+ IDW-1+:1]?
        wdata[i*IDW+:IDW-1]:~wdata[i*IDW+:IDW-1]+1'b1;
    end
 
always @(*)for(i=0;i<NUM;i=i+1)
case(POINT) 
4'd0  :unfold[i]<=sign[i]*(
      +data[i][14]*2*2*2*2*2*2*2*2*2*2*2*2*2*2
      +data[i][13]*2*2*2*2*2*2*2*2*2*2*2*2*2
      +data[i][12]*2*2*2*2*2*2*2*2*2*2*2*2
      +data[i][11]*2*2*2*2*2*2*2*2*2*2*2
      +data[i][10]*2*2*2*2*2*2*2*2*2*2
      +data[i][9] *2*2*2*2*2*2*2*2*2
      +data[i][8] *2*2*2*2*2*2*2*2
      +data[i][7] *2*2*2*2*2*2*2
      +data[i][6] *2*2*2*2*2*2
      +data[i][5] *2*2*2*2*2
      +data[i][4] *2*2*2*2
      +data[i][3] *2*2*2
      +data[i][2] *2*2
      +data[i][1] *2
      +data[i][0] *1
      );
4'd1  :unfold[i]<=sign[i]*(
      +data[i][14]*2*2*2*2*2*2*2*2*2*2*2*2*2
      +data[i][13]*2*2*2*2*2*2*2*2*2*2*2*2  
      +data[i][12]*2*2*2*2*2*2*2*2*2*2*2    
      +data[i][11]*2*2*2*2*2*2*2*2*2*2      
      +data[i][10]*2*2*2*2*2*2*2*2*2        
      +data[i][9] *2*2*2*2*2*2*2*2          
      +data[i][8] *2*2*2*2*2*2*2            
      +data[i][7] *2*2*2*2*2*2              
      +data[i][6] *2*2*2*2*2                
      +data[i][5] *2*2*2*2                  
      +data[i][4] *2*2*2                    
      +data[i][3] *2*2                      
      +data[i][2] *2                        
      +data[i][1] *1                        
      +data[i][0] *0.5
      );
4'd2  :unfold[i]<=sign[i]*(
      +data[i][14]*2*2*2*2*2*2*2*2*2*2*2*2
      +data[i][13]*2*2*2*2*2*2*2*2*2*2*2    
      +data[i][12]*2*2*2*2*2*2*2*2*2*2      
      +data[i][11]*2*2*2*2*2*2*2*2*2        
      +data[i][10]*2*2*2*2*2*2*2*2          
      +data[i][9] *2*2*2*2*2*2*2            
      +data[i][8] *2*2*2*2*2*2              
      +data[i][7] *2*2*2*2*2                
      +data[i][6] *2*2*2*2                  
      +data[i][5] *2*2*2                    
      +data[i][4] *2*2                      
      +data[i][3] *2                        
      +data[i][2] *1                        
      +data[i][1] *0.5                      
      +data[i][0] *0.5*0.5
      );
4'd3  :unfold[i]<=sign[i]*(
      +data[i][14]*2*2*2*2*2*2*2*2*2*2*2
      +data[i][13]*2*2*2*2*2*2*2*2*2*2  
      +data[i][12]*2*2*2*2*2*2*2*2*2    
      +data[i][11]*2*2*2*2*2*2*2*2      
      +data[i][10]*2*2*2*2*2*2*2        
      +data[i][9] *2*2*2*2*2*2          
      +data[i][8] *2*2*2*2*2            
      +data[i][7] *2*2*2*2              
      +data[i][6] *2*2*2                
      +data[i][5] *2*2                  
      +data[i][4] *2                    
      +data[i][3] *1                    
      +data[i][2] *0.5                  
      +data[i][1] *0.5*0.5              
      +data[i][0] *0.5*0.5*0.5
      );
4'd4  :unfold[i]<=sign[i]*(
      +data[i][14]*2*2*2*2*2*2*2*2*2*2
      +data[i][13]*2*2*2*2*2*2*2*2*2  
      +data[i][12]*2*2*2*2*2*2*2*2    
      +data[i][11]*2*2*2*2*2*2*2      
      +data[i][10]*2*2*2*2*2*2        
      +data[i][9] *2*2*2*2*2          
      +data[i][8] *2*2*2*2            
      +data[i][7] *2*2*2              
      +data[i][6] *2*2                
      +data[i][5] *2                  
      +data[i][4] *1                  
      +data[i][3] *0.5                
      +data[i][2] *0.5*0.5            
      +data[i][1] *0.5*0.5*0.5        
      +data[i][0] *0.5*0.5*0.5*0.5
      );
4'd5  :unfold[i]<=sign[i]*(
      +data[i][14]*2*2*2*2*2*2*2*2*2
      +data[i][13]*2*2*2*2*2*2*2*2  
      +data[i][12]*2*2*2*2*2*2*2    
      +data[i][11]*2*2*2*2*2*2      
      +data[i][10]*2*2*2*2*2        
      +data[i][9] *2*2*2*2          
      +data[i][8] *2*2*2            
      +data[i][7] *2*2              
      +data[i][6] *2                
      +data[i][5] *1                
      +data[i][4] *0.5              
      +data[i][3] *0.5*0.5          
      +data[i][2] *0.5*0.5*0.5      
      +data[i][1] *0.5*0.5*0.5*0.5  
      +data[i][0] *0.5*0.5*0.5*0.5*0.5
      );
4'd6  :unfold[i]<=sign[i]*(
      +data[i][14]*2*2*2*2*2*2*2*2    
      +data[i][13]*2*2*2*2*2*2*2      
      +data[i][12]*2*2*2*2*2*2        
      +data[i][11]*2*2*2*2*2          
      +data[i][10]*2*2*2*2            
      +data[i][9] *2*2*2              
      +data[i][8] *2*2                
      +data[i][7] *2                  
      +data[i][6] *1                  
      +data[i][5] *0.5                
      +data[i][4] *0.5*0.5            
      +data[i][3] *0.5*0.5*0.5        
      +data[i][2] *0.5*0.5*0.5*0.5    
      +data[i][1] *0.5*0.5*0.5*0.5*0.5
      +data[i][0] *0.5*0.5*0.5*0.5*0.5*0.5
      );
4'd7  :unfold[i]<=sign[i]*(
      +data[i][14]*2*2*2*2*2*2*2          
      +data[i][13]*2*2*2*2*2*2            
      +data[i][12]*2*2*2*2*2              
      +data[i][11]*2*2*2*2                
      +data[i][10]*2*2*2                  
      +data[i][9] *2*2                    
      +data[i][8] *2                      
      +data[i][7] *1                      
      +data[i][6] *0.5                    
      +data[i][5] *0.5*0.5                
      +data[i][4] *0.5*0.5*0.5            
      +data[i][3] *0.5*0.5*0.5*0.5        
      +data[i][2] *0.5*0.5*0.5*0.5*0.5    
      +data[i][1] *0.5*0.5*0.5*0.5*0.5*0.5
      +data[i][0] *0.5*0.5*0.5*0.5*0.5*0.5*0.5
      );
4'd8  :unfold[i]<=sign[i]*(
      +data[i][14]*2*2*2*2*2*2                
      +data[i][13]*2*2*2*2*2                  
      +data[i][12]*2*2*2*2                    
      +data[i][11]*2*2*2                      
      +data[i][10]*2*2                        
      +data[i][9] *2                          
      +data[i][8] *1                          
      +data[i][7] *0.5                        
      +data[i][6] *0.5*0.5                    
      +data[i][5] *0.5*0.5*0.5                
      +data[i][4] *0.5*0.5*0.5*0.5            
      +data[i][3] *0.5*0.5*0.5*0.5*0.5        
      +data[i][2] *0.5*0.5*0.5*0.5*0.5*0.5    
      +data[i][1] *0.5*0.5*0.5*0.5*0.5*0.5*0.5
      +data[i][0] *0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5
      );
4'd9  :unfold[i]<=sign[i]*(
      +data[i][14]*2*2*2*2*2                      
      +data[i][13]*2*2*2*2                        
      +data[i][12]*2*2*2                          
      +data[i][11]*2*2                            
      +data[i][10]*2                              
      +data[i][9] *1                              
      +data[i][8] *0.5                            
      +data[i][7] *0.5*0.5                        
      +data[i][6] *0.5*0.5*0.5                    
      +data[i][5] *0.5*0.5*0.5*0.5                
      +data[i][4] *0.5*0.5*0.5*0.5*0.5            
      +data[i][3] *0.5*0.5*0.5*0.5*0.5*0.5        
      +data[i][2] *0.5*0.5*0.5*0.5*0.5*0.5*0.5    
      +data[i][1] *0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5
      +data[i][0] *0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5
      );
4'd10 :unfold[i]<=sign[i]*(
      +data[i][14]*2*2*2*2                            
      +data[i][13]*2*2*2                              
      +data[i][12]*2*2                                
      +data[i][11]*2                                  
      +data[i][10]*1                                  
      +data[i][9] *0.5                                
      +data[i][8] *0.5*0.5                            
      +data[i][7] *0.5*0.5*0.5                        
      +data[i][6] *0.5*0.5*0.5*0.5                    
      +data[i][5] *0.5*0.5*0.5*0.5*0.5                
      +data[i][4] *0.5*0.5*0.5*0.5*0.5*0.5            
      +data[i][3] *0.5*0.5*0.5*0.5*0.5*0.5*0.5        
      +data[i][2] *0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5    
      +data[i][1] *0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5
      +data[i][0] *0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5
      );
4'd11 :unfold[i]<=sign[i]*(
      +data[i][14]*2*2*2                                  
      +data[i][13]*2*2                                    
      +data[i][12]*2                                      
      +data[i][11]*1                                      
      +data[i][10]*0.5                                    
      +data[i][9] *0.5*0.5                                
      +data[i][8] *0.5*0.5*0.5                            
      +data[i][7] *0.5*0.5*0.5*0.5                        
      +data[i][6] *0.5*0.5*0.5*0.5*0.5                    
      +data[i][5] *0.5*0.5*0.5*0.5*0.5*0.5                
      +data[i][4] *0.5*0.5*0.5*0.5*0.5*0.5*0.5            
      +data[i][3] *0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5        
      +data[i][2] *0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5    
      +data[i][1] *0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5
      +data[i][0] *0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5
      );
4'd12 :unfold[i]<=sign[i]*(
      +data[i][14]*2*2                                        
      +data[i][13]*2                                          
      +data[i][12]*1                                          
      +data[i][11]*0.5                                        
      +data[i][10]*0.5*0.5                                    
      +data[i][9] *0.5*0.5*0.5                                
      +data[i][8] *0.5*0.5*0.5*0.5                            
      +data[i][7] *0.5*0.5*0.5*0.5*0.5                        
      +data[i][6] *0.5*0.5*0.5*0.5*0.5*0.5                    
      +data[i][5] *0.5*0.5*0.5*0.5*0.5*0.5*0.5                
      +data[i][4] *0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5            
      +data[i][3] *0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5        
      +data[i][2] *0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5    
      +data[i][1] *0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5
      +data[i][0] *0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5
      );
4'd13 :unfold[i]<=sign[i]*(
      +data[i][14]*2                                              
      +data[i][13]*1                                              
      +data[i][12]*0.5                                            
      +data[i][11]*0.5*0.5                                        
      +data[i][10]*0.5*0.5*0.5                                    
      +data[i][9] *0.5*0.5*0.5*0.5                                
      +data[i][8] *0.5*0.5*0.5*0.5*0.5                            
      +data[i][7] *0.5*0.5*0.5*0.5*0.5*0.5                        
      +data[i][6] *0.5*0.5*0.5*0.5*0.5*0.5*0.5                    
      +data[i][5] *0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5                
      +data[i][4] *0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5            
      +data[i][3] *0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5        
      +data[i][2] *0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5    
      +data[i][1] *0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5
      +data[i][0] *0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5
      );
4'd14 :unfold[i]<=sign[i]*(
      +data[i][14]*1                                                  
      +data[i][13]*0.5                                                
      +data[i][12]*0.5*0.5                                            
      +data[i][11]*0.5*0.5*0.5                                        
      +data[i][10]*0.5*0.5*0.5*0.5                                    
      +data[i][9] *0.5*0.5*0.5*0.5*0.5                                
      +data[i][8] *0.5*0.5*0.5*0.5*0.5*0.5                            
      +data[i][7] *0.5*0.5*0.5*0.5*0.5*0.5*0.5                        
      +data[i][6] *0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5                    
      +data[i][5] *0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5                
      +data[i][4] *0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5            
      +data[i][3] *0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5        
      +data[i][2] *0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5    
      +data[i][1] *0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5
      +data[i][0] *0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5
      );
4'd15 :unfold[i]<=sign[i]*(
      +data[i][14]*0.5                                                                                                      
      +data[i][13]*0.5*0.5                                                
      +data[i][12]*0.5*0.5*0.5                                            
      +data[i][11]*0.5*0.5*0.5*0.5                                        
      +data[i][10]*0.5*0.5*0.5*0.5*0.5                                    
      +data[i][9] *0.5*0.5*0.5*0.5*0.5*0.5                                
      +data[i][8] *0.5*0.5*0.5*0.5*0.5*0.5*0.5                            
      +data[i][7] *0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5                        
      +data[i][6] *0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5                    
      +data[i][5] *0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5                
      +data[i][4] *0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5            
      +data[i][3] *0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5        
      +data[i][2] *0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5    
      +data[i][1] *0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5
      +data[i][0] *0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5*0.5
      );
default:unfold[i]<=sign[i]*(
      +data[i][14]*2*2*2*2*2*2*2*2*2*2*2*2*2*2
      +data[i][13]*2*2*2*2*2*2*2*2*2*2*2*2*2
      +data[i][12]*2*2*2*2*2*2*2*2*2*2*2*2
      +data[i][11]*2*2*2*2*2*2*2*2*2*2*2
      +data[i][10]*2*2*2*2*2*2*2*2*2*2
      +data[i][9] *2*2*2*2*2*2*2*2*2
      +data[i][8] *2*2*2*2*2*2*2*2
      +data[i][7] *2*2*2*2*2*2*2
      +data[i][6] *2*2*2*2*2*2
      +data[i][5] *2*2*2*2*2
      +data[i][4] *2*2*2*2
      +data[i][3] *2*2*2
      +data[i][2] *2*2
      +data[i][1] *2
      +data[i][0] *1
      );
endcase

//--------------------------------------------------------------------------
////Only 6 valid decimal points can be displayed
//--------------------------------------------------------------------------

always @(posedge clk)   
if(wvld)for(i=NUM-1;i>=0;i=i-1 )
begin
        if(i==0)
        begin
            if(unfold[i]>0)  $fwrite(file,"  %e\n",unfold[i]);
            else             $fwrite(file," %e\n" ,unfold[i]);
        end
        else
        begin
            if(unfold[i]>0)  $fwrite(file,"  %e"  ,unfold[i]);
            else             $fwrite(file," %e"   ,unfold[i]);
        end
end

always @(posedge clk)   
for(i=NUM-1;i>=0;i=i-1 )
if(wvld) wdata_out[i]=unfold[i];
else     wdata_out[i]=0;









endmodule
