`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/15/2024 12:04:11 PM
// Design Name: 
// Module Name: nvm_top_synth
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


module nvm_top_synth_old(
    input        clk      ,
    input        reset    ,
    input  [7:0] data_in  ,
    output [7:0] data_out 
);


  wire        [   10 : 0]           nvm_raddr                   ;//
  wire                              nvm_raddr_vld               ;//
  wire                              nvm_raddr_done              ;//
  wire                              nvm_done                    ;//
  reg         [  511 : 0]           nvm_rdata      =0           ;
  reg                               nvm_rdata_vld  =0           ;
  reg                               nvm_rdata_done =0           ;
  reg         [  511 : 0]           res_rdata      =0           ;
  reg                               res_rdata_vld  =0           ;
  reg                               res_rdata_done =0           ;
  reg                               nvm_idir       =2           ;
  reg         [    5 : 0]           nvm_inum       =3           ;
  reg                               nvm_odir       =0           ;
  reg         [    5 : 0]           nvm_onum       =0           ;
  reg         [   11 : 0]           nvm_xnum       =11          ;
  reg         [   11 : 0]           nvm_ynum       =13          ;
  reg         [   11 : 0]           nvm_bnum       =9           ;
  reg         [   11 : 0]           nvm_gnum       =10          ;
  reg         [   10 : 0]           nvm_rnum       =64          ;//64
  reg         [    6 : 0]           nvm_rstep      =24          ;//24
  reg                               nvm_rstart     =0           ;

  reg                               res_en         =1           ;
  reg                               ln_en          =1           ;
  reg                               sf_en          =0           ;
  reg                               gelu_en        =0           ;
  reg                               tr_en          =0           ;
  
  reg                               gamma_wstart   =0           ;
  reg                               gamma_wvld     =0           ;
  reg         [  511 : 0]           gamma_wdata    =0           ;
  reg                               beta_wstart    =0           ;
  reg                               beta_wvld      =0           ;
  reg         [  511 : 0]           beta_wdata     =0           ;

  reg                               ddr_wrdy       =1           ;
  wire        [  511 : 0]           ddr_wdata                   ;
  wire                              ddr_wvld                    ;


  //-------------------------------------------------------------
  reg  [20:0] test_cnt = 0;
  always @(posedge clk) test_cnt <= test_cnt+1;

  always @(posedge clk) nvm_rstart<= test_cnt==1000;


  integer i;
  
  reg  r1_nvm_raddr_vld  =0;
  reg  r1_nvm_raddr_done =0;
  reg  r2_nvm_raddr_vld  =0;
  reg  r2_nvm_raddr_done =0;
  reg  r3_nvm_raddr_vld  =0;
  reg  r3_nvm_raddr_done =0;
  always @(posedge clk)
  begin
    r1_nvm_raddr_vld   <= nvm_raddr_vld     ;
    r1_nvm_raddr_done  <= nvm_raddr_done    ;
    r2_nvm_raddr_vld   <= r1_nvm_raddr_vld  ;
    r2_nvm_raddr_done  <= r1_nvm_raddr_done ;
    r3_nvm_raddr_vld   <= r2_nvm_raddr_vld  ;
    r3_nvm_raddr_done  <= r2_nvm_raddr_done ;
    nvm_rdata_vld      <= r3_nvm_raddr_vld  ;
    nvm_rdata_done     <= r3_nvm_raddr_done ;

    if(res_en)begin
        res_rdata_vld      <= r3_nvm_raddr_vld  ;
        res_rdata_done     <= r3_nvm_raddr_done ;
    end else begin
        res_rdata_vld      <= 0;
        res_rdata_done     <= 0;
    end


  end
  
  always @(posedge clk)
  begin
      if(r3_nvm_raddr_vld) 
            for(i=0;i<32;i=i+1)nvm_rdata[i*32+:32]<= test_cnt * i;
      else  nvm_rdata<=0;
      
      if(r3_nvm_raddr_vld&&res_en) 
            for(i=0;i<32;i=i+1)res_rdata[i*32+:32]<= test_cnt * $random();
      else  res_rdata<=0;
  
  
  end
  


//----------------------------------------------
nvm_top_old #(
  .DW  (16),
  .NUM (32),
  .PLEN(24) 
)u0_nvm_top_old(
  .nvm_raddr          (nvm_raddr          ),
  .nvm_raddr_vld      (nvm_raddr_vld      ),
  .nvm_raddr_done     (nvm_raddr_done     ),
  .nvm_done           (nvm_done           ),
  .nvm_rdata          (nvm_rdata          ),
  .nvm_rdata_vld      (nvm_rdata_vld      ),
  .nvm_rdata_done     (nvm_rdata_done     ),
  .res_rdata          (res_rdata          ),
  .res_rdata_vld      (res_rdata_vld      ),
  .res_rdata_done     (res_rdata_done     ),
  .nvm_rstart         (nvm_rstart         ),
  .nvm_idir           (nvm_idir           ),
  .nvm_inum           (nvm_inum           ),
  .nvm_odir           (nvm_odir           ),
  .nvm_onum           (nvm_onum           ),
  .nvm_xnum           (nvm_xnum           ),
  .nvm_ynum           (nvm_ynum           ),
  .nvm_bnum           (nvm_bnum           ),
  .nvm_gnum           (nvm_gnum           ),
  .nvm_rnum           (nvm_rnum           ),
  .nvm_rstep          (nvm_rstep          ),

  .res_en             (res_en             ),
  .ln_en              (ln_en              ),
  .sf_en              (sf_en              ),
  .gelu_en            (gelu_en            ),
  .tr_en              (tr_en              ),
  .gamma_wstart       (gamma_wstart       ),
  .gamma_wvld         (gamma_wvld         ),
  .gamma_wdata        (gamma_wdata        ),
  .beta_wstart        (beta_wstart        ),
  .beta_wvld          (beta_wvld          ),
  .beta_wdata         (beta_wdata         ),
  .ddr_wrdy           (ddr_wrdy           ),
  .ddr_wdata          (ddr_wdata          ),
  .ddr_wvld           (ddr_wvld           ),

  .clk                (clk                ),
  .reset              (reset              )  
);


  reg [15:0] bg_cnt=0;
//  reg                               gamma_wstart   =0           ;
//  reg                               gamma_wvld     =0           ;
//  reg         [  511 : 0]           gamma_wdata    =0           ;
//  reg                               beta_wstart    =0           ;
//  reg                               beta_wvld      =0           ;
//  reg         [  511 : 0]           beta_wdata     =0           ;

  always @(posedge clk)
  begin
      if(ln_en&& nvm_rstart)    bg_cnt  <=200;
      else if(bg_cnt==0)        bg_cnt  <=0;
      else                      bg_cnt  <=bg_cnt-1;
  end

  always @(posedge clk)
  begin
  
  
        gamma_wstart<=bg_cnt==180;
    if(bg_cnt<=173 && bg_cnt>=150)
    begin
        gamma_wvld<=1;
        for(i=0;i<32;i=i+1)
        gamma_wdata[i*32+:32]<= test_cnt * $random();
    end else begin
        gamma_wvld <=0;
        gamma_wdata<=0;
    end
    
    
  
  
          beta_wstart<=bg_cnt==130;
    if(bg_cnt<=123 && bg_cnt>=100)
    begin
        beta_wvld<=1;
        for(i=0;i<32;i=i+1)
        beta_wdata[i*32+:32]<= test_cnt * $random();
    end else begin
        beta_wvld <=0;
        beta_wdata<=0;
    end
    
  
  end






































endmodule
