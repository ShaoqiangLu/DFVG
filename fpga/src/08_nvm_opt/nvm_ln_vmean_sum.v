`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/11/24 16:57:15
// Design Name: 
// Module Name: comparator
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

module nvm_ln_vmean_sum #(
    parameter           NUM_ELEMS                       = 32            ,
    parameter           DW_IN                           = 16            ,
    parameter           DW_multi                        = 40            ,
    parameter           DW_PKG                          = 16              
)(
    input                                               clk             ,
    input                                               rst             ,
    input               [7-1:0]                         nvm_rstep       ,
    input                                               data_in_val     ,
    input                                               data_in_done    ,
    input               [NUM_ELEMS*DW_IN-1:0]           data_in         ,
    output wire         [DW_multi-1:0]                  sum_out         ,
    output wire                                         sum_out_val     ,
    output wire                                         sum_out_done    ,
    output wire         [DW_PKG-1:0]                    pkg_out_acc     
);

  //---------------------------------------------------------------------------
  //Add 32 data within a cycle
  //SUM_WIDTH=16+5=21, 2**5=32
  //---------------------------------------------------------------------------
  localparam SUM_WIDTH = DW_IN+$clog2(NUM_ELEMS)                        ;//5 
  wire [SUM_WIDTH-1:0]   sum_single_cycle_data                          ; 
  wire                   sum_single_cycle_val                           ; 
  wire                   sum_single_cycle_done                          ; 
  (*keep_hierarchy="yes"*)nvm_ln_vsum # (
        .IN_WIDTH       ( DW_IN                                         ),
        .NUM_ELEMS      ( NUM_ELEMS                                     )
  )u0_vsum(
        .clk            ( clk                                           ),
        .data           ( data_in                                       ),//ln1:mean1 Q21_14,mean2 Q39_28
        .sum            ( sum_single_cycle_data                         ) //ln2:mean1  Q21_9,   
  );


  reg [2*3-1:0] dly_vla_done    =0  ;
  always @(posedge clk)
  begin
         dly_vla_done[0*2+:2]  <=  {data_in_val,data_in_done}           ;
         dly_vla_done[1*2+:2]  <=  dly_vla_done[0*2+:2]                 ;
         dly_vla_done[2*2+:2]  <=  dly_vla_done[1*2+:2]                 ;
  end
  assign sum_single_cycle_val   =  dly_vla_done[(3-1)*2+1]              ;
  assign sum_single_cycle_done  =  dly_vla_done[(3-1)*2+0]              ;


  //---------------------------------------------------------------------------
  //The accumulation of the current cycle and the next cycle
  //---------------------------------------------------------------------------
  wire                          sum_next_cycle_first                    ;
  reg signed[DW_multi-1:0]      sum_next_cycle_data=0                   ;//ln1:mean1 Q64_14,mean2 Q64_28
  reg                           sum_next_cycle_val =0                   ;//ln2:mean1 Q64_9
  reg                           sum_next_cycle_done=0                   ;
  
  assign sum_next_cycle_first=sum_single_cycle_val&(~sum_next_cycle_val);
  always @(posedge clk)
  if (sum_single_cycle_val)
  begin
        if(sum_next_cycle_done|sum_next_cycle_first)
          sum_next_cycle_data<={{(DW_multi-SUM_WIDTH)
         {sum_single_cycle_data[SUM_WIDTH-1]}},sum_single_cycle_data}   ;
        else sum_next_cycle_data<=sum_next_cycle_data+ 
         {{(DW_multi-SUM_WIDTH){sum_single_cycle_data[SUM_WIDTH-1]}},
                                sum_single_cycle_data}                  ;
  end else                      sum_next_cycle_data<=0                  ;

  always @(posedge clk)
  begin
    sum_next_cycle_val  <=      sum_single_cycle_val                    ;
    sum_next_cycle_done <=      sum_single_cycle_done                   ;
  end

 //---------------------------------------------------------------------------
 //At the end of each line. Record current data
 //---------------------------------------------------------------------------
  reg signed[DW_multi-1:0]      sum_multi_cycle_data    =0              ;//ln1:mean1 Q64_14,mean2 Q64_28 
  wire                          sum_multi_cycle_val                     ;//ln2:mean1 Q64_9               
  wire                          sum_multi_cycle_done                    ;
  always @(posedge clk) 
  if(sum_next_cycle_done |sum_multi_cycle_done)
  sum_multi_cycle_data     <=   sum_next_cycle_data                     ;

  (*dont_touch="true"*)reg [7-1:0]r_nvm_rstep  =0                       ;
  always @(posedge clk)           r_nvm_rstep <=  nvm_rstep             ;
  
  (*keep_hierarchy="yes"*)nvm_dly_cnt #(
    .CDW                 ( 7                                            ),
    .DW                  ( 2                                            ),
    .DEEP                ( 64                                           )
  ) cnt_sum_multi_vd(
    .dout                ({sum_multi_cycle_val,sum_multi_cycle_done}    ),
    .din                 ({sum_next_cycle_val ,sum_next_cycle_done}     ),
    .cnt                 ( r_nvm_rstep                                  ),
    .clk                 ( clk                                          ),
    .reset               ( rst                                          )
  );

 //----------------------------------------------------------------------------
 //Calculate the length of the data packet
 //----------------------------------------------------------------------------
 reg    [DW_PKG-1:0]            pkg_acc =0                              ;//Q16_0
 reg    [DW_PKG-1:0]            pkg_len =0                              ;
 always @(posedge clk)
 if(sum_single_cycle_val)begin
 if(sum_next_cycle_done)        pkg_acc <= NUM_ELEMS                    ;       
 else                           pkg_acc <= pkg_acc+NUM_ELEMS            ; 
 end else                       pkg_acc <= 0                            ;

 always @(posedge clk)
 if(sum_next_cycle_done|sum_multi_cycle_done) pkg_len<=pkg_acc          ;


 //----------------------------------------------------------------------------
 //
 //----------------------------------------------------------------------------
 assign     sum_out             =   sum_multi_cycle_data                ;
 assign     sum_out_val         =   sum_multi_cycle_val                 ;
 assign     sum_out_done        =   sum_multi_cycle_done                ;
 assign     pkg_out_acc         =   pkg_len                             ;


endmodule
