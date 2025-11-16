`timescale 1ns / 1ps
// -----------------------------------------------------------------------------
// Copyright      : UCLA EDA LAB
// -----------------------------------------------------------------------------
// Engineer       : Chen Wu
// Design Name    : opu series
// Module Name    : res_top
// Target Devices : 325t, Alveo U200
// Tool Versions  : Vivado 2020.1, Modelsim 2019.4
// Description    : 
//    Residual top.
//    Delay: 2 cycles
//
// Revision       :
// Version        Date        Author        Descriptin
// 1.0            2022-04-08  Chen Wu       Initial version
// -----------------------------------------------------------------------------


module res_top_old # (
  parameter               NUM         =     32                      ,
  parameter               DW          =     16                      ,

  localparam              ADW         =     NUM * DW                
  ) (
  output  reg       [ADW-1 : 0]       res_dout_data = 0             ,
  output  reg                         res_dout_vld  = 0             ,
  output  reg                         res_dout_done = 0             ,

  input             [ADW-1 : 0]       nvm_rdata                     ,
  input                               nvm_rdata_vld                 ,
  input                               nvm_rdata_done                ,
  input             [ADW-1 : 0]       res_rdata                     ,
  input                               res_rdata_vld                 ,

  input                               res_en                        ,

  input                               clk                           ,
  input                               reset                         
  );

  reg                                res_en_r                       ;
  reg              [ADW-1 : 0]       r1_nvm_rdata                   ;
  reg                                r1_nvm_rdata_vld               ;
  reg                                r1_nvm_rdata_done              ;
  reg              [ADW-1 : 0]       r1_res_rdata                   ;
  reg                                r1_res_rdata_vld               ;
  reg                                r1_res_rdata_done              ;
  always @(posedge clk)
  begin
    res_en_r          <= res_en        ;
    r1_nvm_rdata      <= nvm_rdata     ;
    r1_nvm_rdata_vld  <= nvm_rdata_vld ;
    r1_nvm_rdata_done <= nvm_rdata_done;
    r1_res_rdata      <= res_rdata     ;
    r1_res_rdata_vld  <= res_rdata_vld ;
  end







  localparam              RDW         =     NUM * (DW+1)            ;
  localparam              LB          =     {1'b1, {(DW-1){1'b0}}}  ;
  localparam              UB          =     {1'b0, {(DW-1){1'b1}}}  ;

  reg               [RDW-1 : 0]       res_add_out = 0               ;

  genvar i;
  generate for ( i = 0; i < NUM; i = i + 1 ) begin: RES_ADD
    always @(posedge clk) begin
      if ( res_en_r )
        res_add_out[(DW+1)*i +: DW+1] <=  $signed(r1_nvm_rdata[DW*i +: DW])  + 
                                          $signed(r1_res_rdata[DW*i +: DW])  ;
      else
        res_add_out[(DW+1)*i +: DW+1] <=  $signed(r1_nvm_rdata[DW*i +: DW])  ;
    end
  end
  endgenerate




  generate for ( i = 0; i < NUM; i = i + 1 ) begin: RES_CUT
    always @(posedge clk) begin
      if ( res_add_out[(DW+1)*i+DW] == res_add_out[(DW+1)*i+DW-1] )
        res_dout_data[DW*i +: DW]  <=  res_add_out[(DW+1)*i +: DW]       ;
      else if ( res_add_out[(DW+1)*i+DW] )
        res_dout_data[DW*i +: DW]  <=  LB                                ;
      else
        res_dout_data[DW*i +: DW]  <=  UB                                ;
    end
  end
  endgenerate



 reg r1_res_dout_vld  =0 ;
 reg r1_res_dout_done =0 ;

 always @(posedge clk) begin
 if(res_en_r)
 begin
     r1_res_dout_vld  <= r1_nvm_rdata_vld  && r1_res_rdata_vld ;
     r1_res_dout_done <= r1_nvm_rdata_done;
 end else
 begin
     r1_res_dout_vld  <= r1_nvm_rdata_vld ;
     r1_res_dout_done <= r1_nvm_rdata_done;
 end


 res_dout_vld     <= r1_res_dout_vld  ;
 res_dout_done    <= r1_res_dout_done ;


 end





endmodule