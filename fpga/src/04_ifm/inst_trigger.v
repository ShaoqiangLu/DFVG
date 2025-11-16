`timescale 1ns / 1ps
// -----------------------------------------------------------------------------
// UCLA EDA LAB
// -----------------------------------------------------------------------------
// Engineer       : Chen Wu
// Design Name    : opu series
// Module Name    : inst_top
// Target Devices : 325t
// Tool Versions  : Vivado 2020.1, Modelsim 2019.4
// Description    : 
//    Write instructions from DDR to inst ram
//    Fetch instructions from inst ram
//    Decode instructions
//
// Revision       :
// Version        Date        Author        Descriptin
// 1.0            2021-04-12  Chen Wu       Initial version
// 2.0            2023-09-11  Shaoqiang     Simulation 97 layers,and       
//                                          implementation on FPGA of U200.
// 3.0            2024-8-4    Shaoqiang     Reorganize the code.
// -----------------------------------------------------------------------------
//iniatl=0:(reset)
//dec_ddr_rstart_trig=0---->wait=state_rdone
//dec_ifm_rstart_trig=0---->wait=ifm_rdone_inst
//dec_ofm_rstart_trig=0---->wait=0
//dec_ddr_wstart_trig=0---->wait=ofm_rdone_final
//
//round=1:
//dec_ddr_rstart_trig=2---->wait=layer_start                    //frist load
//dec_ifm_rstart_trig=4---->wait=0
//dec_ofm_rstart_trig=0---->wait=0
//dec_ddr_wstart_trig=2---->wait=0
//
//round=2:
//dec_ddr_rstart_trig=0---->wait=state_rdone        
//dec_ifm_rstart_trig=1---->wait=state_rdone                    //frist dma
//dec_ofm_rstart_trig=1---->wait=dec_ifm_rstart                 //frist dma
//dec_ddr_wstart_trig=2---->wait=0
//
//round=3:
//dec_ddr_rstart_trig=1---->wait=ddr_rfinish_and_ifm_rfinish    //usual
//dec_ifm_rstart_trig=2---->wait=ddr_rfinish_and_ifm_rfinish    //usual
//dec_ofm_rstart_trig=1---->wait=dec_ifm_rstart
//dec_ddr_wstart_trig=2---->wait=0
//...............................
//hold to running
//...............................
//round=289:
//dec_ddr_rstart_trig=4---->wait=0                              //no  load
//dec_ifm_rstart_trig=2---->wait=ddr_rfinish_and_ifm_rfinish    //end dma
//dec_ofm_rstart_trig=1---->wait=dec_ifm_rstart                 //end dma
//dec_ddr_wstart_trig=2---->wait=0                        
//round=290:
//dec_ddr_rstart_trig=4---->wait=0
//dec_ifm_rstart_trig=4---->wait=0
//dec_ofm_rstart_trig=1---->wait=dec_ifm_rstart                             
//dec_ddr_wstart_trig=0---->wait=ofm_rdone_final                //write ddr
//...............................
//layer finish
//...............................        
//round=291:
//dec_ddr_rstart_trig=2---->wait=layer_start                    //frist load
//dec_ifm_rstart_trig=4---->wait=0
//dec_ofm_rstart_trig=1---->wait=dec_ifm_rstart                         
//dec_ddr_wstart_trig=2---->wait=0    
//round=292:
//dec_ddr_rstart_trig=0---->wait=state_rdone
//dec_ifm_rstart_trig=1---->wait=state_rdone                    //frist dma
//dec_ofm_rstart_trig=1---->wait=dec_ifm_rstart                 //frist dma
//dec_ddr_wstart_trig=2---->wait=0    
//round=293:
//dec_ddr_rstart_trig=1---->wait=ddr_rfinish_and_ifm_rfinish    //usual
//dec_ifm_rstart_trig=2---->wait=ddr_rfinish_and_ifm_rfinish    //usual
//dec_ofm_rstart_trig=1---->wait=dec_ifm_rstart
//dec_ddr_wstart_trig=2---->wait=0
//...............................
//hold to running
//...............................

  
//----------------------------------------------------------------------
module inst_trigger
(
  input           [32-1:0]  inst_round                              ,
  input           [3 -1:0]  dec_ddr_rstart_trig                     ,
  input           [3 -1:0]  dec_ifm_rstart_trig                     ,
  input           [3 -1:0]  dec_ofm_rstart_trig                     ,
  input           [3 -1:0]  dec_ddr_wstart_trig                     ,
  output  reg     [8 -1:0]  dec_ddr_rstart_r    =0                  ,
  output  reg               dec_ddr_rstart      =0                  ,
  output  reg               dec_ifm_rstart      =0                  ,
  output  reg               dec_ofm_rstart      =0                  ,
  output  reg               dec_ddr_wstart      =0                  ,
  output  wire              dec_nvm_rstart                          ,
  input         [6 -1:0]    ddr_rtype                               ,
  input                     layer_start                             ,
  input                     state_rdone                             ,
  input                     ifm_rdone_inst                          ,
  input                     ofm_rdone                               ,
  input                     ofm_rdone_final                         ,
  input                     ddr_wdone                               ,
  input                     nvm_rdone                               ,
  output  wire              layer_trig                              , 
  output  wire              layer_final                             ,
  input                     clk                                     ,
  input                     reset                   
);

  integer                   i=0,j=0                                 ;
  reg                       ddr_rfinish         =0                  ;
  reg                       ifm_rfinish         =0                  ;
  reg                       ofm_rfinish         =0                  ;
  reg                       ddr_wfinish         =0                  ;
  reg                       nvm_rfinish         =0                  ;
  wire                      ddr_rfinish_and_ifm_rfinish             ; 
  wire                      ofm_rdone_final_rfinish                 ;


  always @(posedge clk)// or posedge state_rdone
  if (ddr_rfinish_and_ifm_rfinish)        
                             ddr_rfinish <=  1'b0                   ;
  else if (state_rdone&&dec_ifm_rstart_trig==2)      
                             ddr_rfinish <=  1'b1                   ;



  always @(posedge clk)// or posedge ifm_rdone_inst
  if (ddr_rfinish_and_ifm_rfinish||ofm_rdone_final_rfinish)
                             ifm_rfinish <=  1'b0                   ;
  else if (ifm_rdone_inst)   ifm_rfinish <=  1'b1                   ;

  assign ddr_rfinish_and_ifm_rfinish = ddr_rfinish&&ifm_rfinish     ;

//  assign ddr_rfinish_and_ifm_rfinish_ctrl=dec_ddr_rtype[3]?
//         ofm_rdone_final:ddr_rfinish_and_ifm_rfinish              ;

  always @(posedge clk)
  if (dec_ofm_rstart||ofm_rdone_final_rfinish)        
                             ofm_rfinish <=  1'b0                   ;
  else if (ofm_rdone)        ofm_rfinish <=  1'b1                   ;

  always @(posedge clk)
  if (dec_ddr_wstart||dec_ifm_rstart)        
                             ddr_wfinish <=  1'b0                   ;
  else if (ddr_wdone)        ddr_wfinish <=  1'b1                   ;

  always @(posedge clk)
  if (dec_nvm_rstart||dec_ifm_rstart)        
                             nvm_rfinish <=  1'b0                   ;
  else if (nvm_rdone)        nvm_rfinish <=  1'b1                   ;


//---------------------------------------------------------------------
//Obtain the signal for the layer_start of the action
//---------------------------------------------------------------------

  always @(posedge clk)
  begin
  case (dec_ddr_rstart_trig )
      3'h0: dec_ddr_rstart  <=  state_rdone                         ;//frist
      3'h1: dec_ddr_rstart  <=  ddr_rfinish_and_ifm_rfinish         ;//after usual
      3'h2: dec_ddr_rstart  <=  layer_start                         ;//inital
      3'h3: dec_ddr_rstart  <=  ddr_wdone                           ;
      3'h4: dec_ddr_rstart  <=  1'b0                                ;//end
      3'h5: dec_ddr_rstart  <=  ifm_rdone_inst                      ;
      3'h6: dec_ddr_rstart  <=  ddr_rfinish&&ofm_rfinish            ;
      3'h7: dec_ddr_rstart  <=  ddr_rfinish&&ddr_wfinish            ;
  endcase
  end


  always @(posedge clk)
  begin
  case (dec_ddr_rstart_trig )
      3'h0: dec_ddr_rstart_r  <={8{state_rdone                 }}   ;//frist
      3'h1: dec_ddr_rstart_r  <={8{ddr_rfinish_and_ifm_rfinish }}   ;//after usual
      3'h2: dec_ddr_rstart_r  <={8{layer_start                 }}   ;//inital
      3'h3: dec_ddr_rstart_r  <={8{ddr_wdone                   }}   ;
      3'h4: dec_ddr_rstart_r  <={8{1'b0                        }}   ;//end
      3'h5: dec_ddr_rstart_r  <={8{ifm_rdone_inst              }}   ;
      3'h6: dec_ddr_rstart_r  <={8{ddr_rfinish&&ofm_rfinish    }}   ;
      3'h7: dec_ddr_rstart_r  <={8{ddr_rfinish&&ddr_wfinish    }}   ;
  endcase
  end

  always @(posedge clk)
  begin
  case (dec_ifm_rstart_trig )
      3'h0: dec_ifm_rstart  <=  ifm_rdone_inst                      ;
      3'h1: dec_ifm_rstart  <=  state_rdone                         ;//iniatl
      3'h2: dec_ifm_rstart  <=  ddr_rfinish_and_ifm_rfinish         ;//after usual
      3'h3: dec_ifm_rstart  <=  ddr_wdone  
                             &&(dec_ddr_wstart_trig !=1)  
                             &&(dec_ddr_wstart_trig !=6)            ;
      3'h4,3'h5,3'h6,3'h7:
            dec_ifm_rstart  <=  1'b0                                ;
  endcase
  end


  always @(posedge clk)
  begin
  case (dec_ofm_rstart_trig)
      3'h0: dec_ofm_rstart  <=  1'b0                                ;
      3'h1: dec_ofm_rstart  <=  dec_ifm_rstart                      ;
      3'h2,3'h3,3'h4,3'h5,3'h6,3'h7:
            dec_ofm_rstart  <=  1'b0                                ;
  endcase
  end

  //state_rdone

  assign ofm_rdone_final_rfinish=ddr_rtype[3]?
         state_rdone:ofm_rdone_final;

  always @(posedge clk)
  begin
  case (dec_ddr_wstart_trig)
      3'h0: dec_ddr_wstart   <=  ofm_rdone_final_rfinish            ;
      3'h1: dec_ddr_wstart   <=  ddr_wdone                          ;
      3'h2: dec_ddr_wstart   <=  1'b0                               ;
      3'h3: dec_ddr_wstart   <=  ddr_rfinish&&nvm_rfinish           ;
      3'h4: dec_ddr_wstart   <=  state_rdone                        ;
      3'h5: dec_ddr_wstart   <=  ddr_rfinish&&ddr_wfinish           ;
      3'h6: dec_ddr_wstart   <=  state_rdone                        ;
      3'h7: dec_ddr_wstart   <=  1'b0                               ;
  endcase
  end

  assign  dec_nvm_rstart = dec_ddr_wstart                           ;
  
  assign  layer_trig     = ddr_wdone&&(dec_ddr_rstart_trig==3'h2)   ;
  assign  layer_final    = ddr_wdone&&(dec_ddr_rstart_trig==3'h4)   ;  

  //---------------------------------------------------------------



endmodule

