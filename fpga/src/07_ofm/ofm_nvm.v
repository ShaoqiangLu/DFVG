`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/11/2023 07:22:47 PM
// Design Name: 
// Module Name: ofm_nvm
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


module ofm_nvm#(
  parameter  DW1 =16,
  parameter  DW2 =16
  )(

 
    
    );



// ------------------------------------------------------------   
//ofm
  assign  ofm_roffset            =   'd1                      ;
  assign  ofm_woffset            =   'd1                      ;
  assign  nvm_osel               = ~tr_en                     ;
  (*keep_hierarchy="yes" *)
  ofm_top #(
    .NUM                          ( DOUT_NUM                  ),
    .IDW                          ( INDW / DOUT_NUM / PE_NUM  ),
    .ADW                          ( DW * 2                    ),
    .ODW                          ( DW                        ) 
  ) u0_ofm_top (
    .layer_cnt                    ( layer_cnt                 ),
 
    .ofm_woffset                  ( ofm_woffset               ),
    .ofm_roffset                  ( ofm_roffset               ),    
    .ofm_wbase                    ( ofm_wbase                 ),
    .ofm_rbase                    ( ofm_rbase                 ),    
    .ofm_din_enc                  ( pe_output_num             ),
    .ofm_concat_num               ( ofm_concat_num            ),    
    .ofm_snum                     ( ofm_snum                  ),
    .bias_snum                    ( bias_snum                 ),
    .bias_sel                     ( bias_sel                  ),
    .ofm_tmp_sel                  ( ofm_tmp_sel               ),
    .ofm_output_sel               ( ofm_output_sel            ),
    .nvm_osel                     ( nvm_osel                  ),  
      
    .ofm_pp                       ( ofm_pp                    ),  
    .ofm_start                    ( ofm_start                 ),    
    .ofm_done                     ( ofm_done                  ),    
  
    .ofm_din                      ( pe_dout                   ),
    .ofm_din_vld                  ( pe_dout_vld               ),
    .ofm_din_done                 ( pe_done                   ),
    .bias_data                    ( bias_rdata                ),
    .bias_rvld                    ( bias_rvld                 ),

    .nvm_raddr                    ( nvm_raddr                 ),
    .nvm_raddr_vld                ( nvm_raddr_vld             ),
    .nvm_rdata                    ( nvm_rdata                 ),
    .nvm_rdata_vld                ( nvm_rdata_vld             ),
    
    .back_waddr                   ( back_waddr                ),                     
    .back_wdata                   ( back_wdata                ),
    .back_wvld                    ( back_wvld                 ),
    .back_wdone                   ( back_wdone                ),
    
    .back_rstart                  ( back_rstart               ),
    .back_raddr                   ( back_raddr                ),
    .back_raddr_vld               ( back_raddr_vld            ),
    .back_rdata                   ( back_rdata                ),
    .back_rdata_vld               ( back_rdata_vld            ),
    
    .clk                          ( clk                       ),
    .reset                        ( reset                     )

  );





// -----------------------------------------------------------
//nvm
  assign  gamma_wvld  =   ddr_rvld    & (ddr_rid == 5)        ;
  assign  gamma_wstart=   ddr_rstart  & (ddr_rid == 5)        ;
  assign  beta_wvld   =   ddr_rvld    & (ddr_rid == 6)        ;
  assign  beta_wstart =   ddr_rstart  & (ddr_rid == 6)        ;
  assign  nvm_rstart  =   ddr_wstart                          ;
  (*keep_hierarchy="yes" *)
  nvm_top #(
    .DW                           ( DW                        ),
    .NUM                          ( DOUT_NUM                  ),
    .PLEN                         ( 32                        ) 
  ) u0_nvm_top (
    .layer_cnt                    ( layer_cnt                 ),
    .nvm_osel                     ( nvm_osel                  ),
    .nvm_rnum                     ( nvm_rnum                  ),
    .nvm_rstep                    ( nvm_rstep                 ),
    .nvm_idir                     ( nvm_idir                  ),
    .nvm_inum                     ( nvm_inum                  ),
    .nvm_odir                     ( nvm_odir                  ),
    .nvm_onum                     ( nvm_onum                  ),
    .nvm_xnum                     ( nvm_xnum                  ),
    .nvm_ynum                     ( nvm_ynum                  ),
    .nvm_bnum                     ( nvm_bnum                  ),
    .nvm_gnum                     ( nvm_gnum                  ),
    .tr_en                        ( tr_en                     ),
    .res_en                       ( res_en                    ),
    .ln_en                        ( ln_en                     ),
    .act_type                     ( act_type                  ),    
    .act_en                       ( act_en                    ),
    .div_en                       ( sf_en                     ),
    .sf_en                        ( sf_en                     ),
    .nvm_pos                      ( {(8*32){1'b0}}            ),
    .nvm_rstart                   ( nvm_rstart                ),
    .nvm_done                     ( nvm_done                  ),    
    .nvm_raddr                    ( nvm_raddr                 ),
    .nvm_raddr_vld                ( nvm_raddr_vld             ),
    .nvm_rdata                    ( nvm_rdata                 ),
    .nvm_rdata_vld                ( nvm_rdata_vld             ),
    .res_rdata                    ( res_rdata                 ),
    .res_rvld                     ( res_rvld                  ),
    .gamma_wdata                  ( ddr_rdata                 ),
    .gamma_wvld                   ( gamma_wvld                ),
    .gamma_wstart                 ( gamma_wstart              ),
    .beta_wdata                   ( ddr_rdata                 ),
    .beta_wvld                    ( beta_wvld                 ),
    .beta_wstart                  ( beta_wstart               ),    
    .back_waddr                   ( back_waddr                ),                      
    .back_wdata                   ( back_wdata                ),
    .back_wvld                    ( back_wvld                 ),
    .back_wdone                   ( back_wdone                ),
    .back_rstart                  ( back_rstart               ),
    .back_raddr                   ( back_raddr                ),
    .back_raddr_vld               ( back_raddr_vld            ),
    .back_rdata                   ( back_rdata                ),
    .back_rdata_vld               ( back_rdata_vld            ),
    .ddr_wdata                    ( ddr_wdata                 ),
    .ddr_wvld                     ( ddr_wvld                  ),
    .ddr_wrdy                     ( ddr_wrdy                  ),
    .clk                          ( clk                       ),
    .reset                        ( reset                     ) 
  );

endmodule
