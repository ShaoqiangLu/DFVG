// -----------------------------------------------------------------------------
// Copyright      : UCLA EDA LAB
// -----------------------------------------------------------------------------
// Engineer       : Chen Wu
// Design Name    : opu series
// Module Name    : tb_ofm_top
// Target Devices : 325t, Alveo U200
// Tool Versions  : Vivado 2020.1, Modelsim 2019.4
// Description    : 
//    Testbench for the ofm top module.
//
// Revision       :
// Version        Date        Author        Descriptin
// 1.0            2022-04-07  Chen Wu       Initial version
// 2.0            2023-08-25  Shaoqiang     Implementation in U200
// -----------------------------------------------------------------------------


module ofmnvm_synth #(
  parameter             DW        =     16                       ,
  parameter             NUM       =     32                       ,
  parameter             PLEN      =     24                       ,
  parameter             PDW       =     42                       ,
  parameter             BDW       =     42                       ,
  parameter             ODW       =     16                        
  ) (
  input                               sys_clk_p                  ,
  input                               sys_clk_n                  ,
  input                               sys_rst              
  );
  wire      reset       ; 
  wire      clk         ;
  IBUFDS u0_IBUFDS 
  (
        .O (clk        ), // 1-bit output: Buffer output
        .I (sys_clk_p  ), // 1-bit  input: Diff_p buffer input 
        .IB(sys_clk_n  )  // 1-bit  input: Diff_n buffer input
   );                     
  assign reset=sys_rst;
  


 //----------------------------------------------------------------
 // ofm
   wire   [    10 : 0]          ofm_woffset                       ;  
   wire   [    10 : 0]          ofm_roffset                       ;  
   wire   [    10 : 0]          ofm_wbase                         ;
   wire   [    10 : 0]          ofm_rbase                         ; 
   wire   [     2 : 0]          ofm_din_enc                       ;
   wire   [     6 : 0]          concat_num                        ;   
   wire   [     4 : 0]          ofm_snum                          ;
   wire   [     9 : 0]          bias_snum                         ;
   wire                         bias_sel                          ;
   wire                         tmp_sel                           ;
   wire                         output_sel                        ;
   wire                         nvm_osel                          ; 
   wire                         ofm_pp                            ; 
   
   wire                         ofm_start                         ; 
   wire                         ofm_done                          ; 
   
   wire   [PDW*NUM-1:0]         ofm_din                           ;
   wire                         ofm_din_vld                       ;
   wire                         ofm_din_done                      ;
   wire   [BDW*NUM-1:0]         bias_data                         ;
   wire                         bias_rvld                         ;
   
   wire   [    10  : 0]         nvm_raddr                         ;
   wire                         nvm_raddr_vld                     ;
   wire   [ODW*NUM-1:0]         nvm_rdata                         ;
   wire                         nvm_rdata_vld                     ;  

   wire   [   10    : 0]        back_waddr                        ;                      
   wire   [ODW*NUM-1: 0]        back_wdata                        ;
   wire                         back_wvld                         ;
   wire                         back_wdone                        ;   
   
   wire                         back_rstart                       ;   
   wire      [ 10 : 0]          back_raddr                        ;
   wire                         back_raddr_vld                    ;
   wire    [ODW*NUM-1: 0]       back_rdata                        ;
   wire                         back_rdata_vld                    ;
   
 //-----------------------------------------------------------------
 // nvm

   wire      [   10 : 0]        nvm_rnum                          ;
   wire      [    6 : 0]        nvm_rstep                         ;
   wire                         nvm_idir                          ;
   wire      [    5 : 0]        nvm_inum                          ;
   wire                         nvm_odir                          ;
   wire      [    5 : 0]        nvm_onum                          ;
   wire      [   11 : 0]        nvm_xnum                          ;
   wire      [   11 : 0]        nvm_ynum                          ;
   wire      [   11 : 0]        nvm_bnum                          ;
   wire      [   11 : 0]        nvm_gnum                          ;
   wire                         tr_en                             ;  
   wire                         res_en                            ;
   wire                         ln_en                             ;      
   wire      [   3  : 0]        act_type                          ;
   wire                         act_en                            ;
   wire                         div_en                            ;
   wire                         sf_en                             ;
   wire      [ 32*8-1:0]        pos                               ;   

   wire                         nvm_rstart                        ;
   wire                         nvm_done                          ;
   
   wire                         res_rvld                          ;
   wire      [  511 : 0]        res_rdata                         ;

   wire      [  511 : 0]        beta_wdata                        ;
   wire                         beta_wvld                         ;
   wire                         beta_wstart                       ;
   wire      [  511 : 0]        gamma_wdata                       ;
   wire                         gamma_wvld                        ;
   wire                         gamma_wstart                      ;
   
   wire      [ 511  : 0]        ddr_wdata                         ;
   wire                         ddr_wvld                          ;
   reg                          ddr_wvld_r                        ;
   wire                         ddr_wdone                         ;
   wire                         ddr_wrdy                          ;

             
  //---------------------------------------------------------------
  //layer
   reg       [ 9   : 0  ]       init_cnt                          ;
   wire      [ 9   : 0  ]       layer_cnt                         ;
   reg       [ 9   : 0  ]       layer_cnt_r                       ;
   
   reg                          layer_start                       ;  
   
   wire                         layer_done                        ; 
   wire                         layer_done_r1                     ;//5000
   wire                         layer_done_r2                     ;//100


   always @(posedge clk) 
   begin
   if( reset )
       init_cnt                 <=  200                           ;
   else
   if( init_cnt == 0)
       init_cnt                 <=  init_cnt                      ;
   else
       init_cnt                 <=  init_cnt-1                    ;
   end
  
   always @(posedge clk) 
   begin
   if( reset )
       ddr_wvld_r               <=  0                              ;
   else
       ddr_wvld_r               <=  ddr_wvld                       ;
   end
   assign ddr_wdone             =   ddr_wvld_r&(~ddr_wvld)         ; 
   assign ddr_wrdy              =   1'b1                           ;  

  
  dly_cell #(
    .DLY                       ( 5000                              ),
    .DW                        ( 1                                 )
  ) dly_done1(
    .dout                      ( layer_done_r1                     ),
    .din                       ( init_cnt==1 ||
                               ( ddr_wdone&&(  
                                               layer_cnt_r==1   //1 -->2
                                             ||layer_cnt_r==2   //2 -->3
                                             ||layer_cnt_r==3   //3 -->4                                   
                                             ||layer_cnt_r==15  //4 -->5
                                             ||layer_cnt_r==27  //5 -->6       
                                             ||layer_cnt_r==28  //6 -->7
                                             ||layer_cnt_r==32  //7 -->8
                                             ||layer_cnt_r==33  //8 -->9
                                             ||layer_cnt_r==34  //9 -->10
                                             ||layer_cnt_r==35  //10-->11                                          
                                             ||layer_cnt_r==36  //11-->12                                           
                                             ||layer_cnt_r==48  //12-->13  
                                             ||layer_cnt_r==60  //13-->14                                              
                                             ||layer_cnt_r==61  //14-->15                                                                                  
                                             ||layer_cnt_r==65  //15-->16   
                                             ||layer_cnt_r==66  //16-->17   
                                                                                                                                           
                                             ))),
    .clk                       ( clk                               ),
    .reset                     ( reset                             ) 
  );

  dly_cell #(
    .DLY                       ( 100                               ),
    .DW                        ( 1                                 )
  ) dly_done2(
    .dout                      ( layer_done_r2                     ),
    .din                       ( ddr_wdone&&(
                               (
                                layer_cnt_r>=4  && layer_cnt_r<=15-1)
                             ||(layer_cnt_r>=16 && layer_cnt_r<=27-1)
                             ||(layer_cnt_r>=29 && layer_cnt_r<=32-1)                         
                             ||(layer_cnt_r>=37 && layer_cnt_r<=48-1)
                             ||(layer_cnt_r==49 && layer_cnt_r<=60-1)                           
                             ||(layer_cnt_r>=62 && layer_cnt_r<=65-1)                         
                                                                   )),
    .clk                       ( clk                               ),
    .reset                     ( reset                             ) 
  );





assign layer_done   =   layer_done_r1 || layer_done_r2             ; 

   always @(posedge clk) 
   if( reset ) begin
       layer_start              <=  0                              ;
       layer_cnt_r              <=  0                              ;
   end
   else
   if ( layer_done )
   begin
        layer_start             <=  layer_done                     ;
        layer_cnt_r             <=  layer_cnt_r+1                  ;
   end
   else layer_start             <=  0                              ;

assign  layer_cnt= 
                   (                   layer_cnt_r==1  )? 1  //[1,64,64  ,12],1536   ,
                  :(                   layer_cnt_r==2  )? 2  //[1,64,64  ,12],1536   ,                   
                  :(                   layer_cnt_r==3  )? 3  //[1,64,64  ,12],1536   ,                   
                  :(layer_cnt_r>=4  && layer_cnt_r<=15 )? 4  //[1,64,64  ,12],128x12 ,sf                   
                  :(layer_cnt_r>=16 && layer_cnt_r<=27 )? 5  //[1,64,768 ,1 ],128x12 ,                   
                  :(                   layer_cnt_r==28 )? 6  //[1,64,768 ,1 ],1536   ,ln                   
                  :(layer_cnt_r>=29 && layer_cnt_r<=32 )? 7  //[1,64,3072,1 ],1536x4 ,act                    
                  :(                   layer_cnt_r==33 )? 8  //[1,64,768 ,1 ],1536   ,ln                    
                  :(                   layer_cnt_r==34 )? 9  //[1,64,64  ,12],1536   ,                    
                  :(                   layer_cnt_r==35 )? 10 //[1,64,64  ,12],1536   ,                                    
                  :(                   layer_cnt_r==36 )? 11 //[1,64,64  ,12],1536   ,                                       
                  :(layer_cnt_r>=37 && layer_cnt_r<=48 )? 12 //[1,64,64  ,12],128x12 ,sf                    
                  :(layer_cnt_r==49 && layer_cnt_r<=60 )? 13 //[1,64,768 ,1 ],128x12 ,                                        
                  :(                   layer_cnt_r==61 )? 14 //[1,64,768 ,1 ],1536   ,ln                    
                  :(layer_cnt_r>=62 && layer_cnt_r<=65 )? 15 //[1,64,3072,1 ],1536x4 ,act                   
                  :(                   layer_cnt_r==66 )? 16 //[1,64,768 ,1 ],1536   ,ln                              
                                                        
                  :0;



  //---------------------------------------------------------------
  ofm_top #(
    .NUM                       ( NUM                              ),
    .IDW                       ( PDW                              ),
    .ADW                       ( BDW                              ),
    .ODW                       ( ODW                              ))
  u0_ofm_top( 
    .layer_cnt                 ( layer_cnt                        ),//synth
    
    .ofm_woffset               ( ofm_woffset                      ),//ofm_test  
    .ofm_roffset               ( ofm_roffset                      ),    
    .ofm_wbase                 ( ofm_wbase                        ),
    .ofm_rbase                 ( ofm_rbase                        ),    
    .ofm_din_enc               ( ofm_din_enc                      ),
    .ofm_snum                  ( ofm_snum                         ),
    .concat_num                ( concat_num                       ),
    .bias_snum                 ( bias_snum                        ),
    .bias_sel                  ( bias_sel                         ),
    .tmp_sel                   ( tmp_sel                          ),
    .output_sel                ( output_sel                       ),
    .nvm_osel                  ( nvm_osel                         ),    
    .ofm_pp                    ( ofm_pp                           ),  
    
    .ofm_start                 ( ofm_start                        ),    
    .ofm_done                  ( ofm_done                         ),    
  
    .ofm_din                   ( ofm_din                          ),//ofm_test
    .ofm_din_vld               ( ofm_din_vld                      ),
    .ofm_din_done              ( ofm_din_done                     ),
    .bias_data                 ( bias_data                        ),
    .bias_rvld                 ( bias_rvld                        ),

    .nvm_raddr                 ( nvm_raddr                        ),//nvm
    .nvm_raddr_vld             ( nvm_raddr_vld                    ),
    .nvm_rdata                 ( nvm_rdata                        ),
    .nvm_rdata_vld             ( nvm_rdata_vld                    ),
    
    .back_waddr                ( back_waddr                       ),//nvm                      
    .back_wdata                ( back_wdata                       ),
    .back_wvld                 ( back_wvld                        ),
    .back_wdone                ( back_wdone                       ),
    
    .back_rstart               ( back_rstart                      ),//nvm
    .back_raddr                ( back_raddr                       ),
    .back_raddr_vld            ( back_raddr_vld                   ),
    .back_rdata                ( back_rdata                       ),
    .back_rdata_vld            ( back_rdata_vld                   ),
    
    
    .clk                       ( clk                              ),
    .reset                     ( reset                            )
  );

 //---------------------------------------------------------------

  nvm_top #(
    .DW                        ( DW                               ),
    .NUM                       ( NUM                              ),
    .PLEN                      ( PLEN                             ),
    .POS_WIDTH                 ( 8                                ),
    .NUM_SEGS                  ( NUM                              ) 
  ) u0_nvm_top (
    .layer_cnt                 ( layer_cnt                        ),//synth
    
    .nvm_osel                  ( nvm_osel                         ),
    .nvm_rnum                  ( nvm_rnum                         ),
    .nvm_rstep                 ( nvm_rstep                        ),
    .nvm_idir                  ( nvm_idir                         ),
    .nvm_inum                  ( nvm_inum                         ),
    .nvm_odir                  ( nvm_odir                         ),
    .nvm_onum                  ( nvm_onum                         ),
    .nvm_xnum                  ( nvm_xnum                         ),
    .nvm_ynum                  ( nvm_ynum                         ),
    .nvm_bnum                  ( nvm_bnum                         ),
    .nvm_gnum                  ( nvm_gnum                         ),
    .tr_en                     ( tr_en                            ),
    .res_en                    ( res_en                           ),
    .ln_en                     ( ln_en                            ),
    .act_type                  ( act_type                         ),    
    .act_en                    ( act_en                           ),
    .div_en                    ( div_en                           ),
    .sf_en                     ( sf_en                            ),
    .pos                       ( pos                              ),
    
    .nvm_rstart                ( nvm_rstart                       ),//nvm_test
    .nvm_done                  ( nvm_done                         ),    
    
    .nvm_raddr                 ( nvm_raddr                        ),//ofm
    .nvm_raddr_vld             ( nvm_raddr_vld                    ),
    .nvm_rdata                 ( nvm_rdata                        ),
    .nvm_rdata_vld             ( nvm_rdata_vld                    ),
    .res_rvld                  ( res_rvld                         ),
    .res_rdata                 ( res_rdata                        ),//nvm_test
    .gamma_wdata               ( gamma_wdata                      ),//nvm_test
    .gamma_wvld                ( gamma_wvld                       ),
    .gamma_wstart              ( gamma_wstart                     ),
    .beta_wdata                ( beta_wdata                       ),
    .beta_wvld                 ( beta_wvld                        ),
    .beta_wstart               ( beta_wstart                      ),    

    .back_waddr                ( back_waddr                       ),//ofm                      
    .back_wdata                ( back_wdata                       ),
    .back_wvld                 ( back_wvld                        ),
    .back_wdone                ( back_wdone                       ),
    
    .back_rstart               ( back_rstart                      ),//ofm
    .back_raddr                ( back_raddr                       ),
    .back_raddr_vld            ( back_raddr_vld                   ),
    .back_rdata                ( back_rdata                       ),
    .back_rdata_vld            ( back_rdata_vld                   ),

    .ddr_wdata                 ( ddr_wdata                        ),//top
    .ddr_wvld                  ( ddr_wvld                         ),
    .ddr_wrdy                  ( ddr_wrdy                         ),
    .clk                       ( clk                              ),
    .reset                     ( reset                            )  
  );

 //----------------------------------------------------------
  ofm_test #(
    .NUM                       ( NUM                              ),//32
    .IDW                       ( PDW                              ),//42
    .ADW                       ( BDW                              ),//32
    .ODW                       ( ODW                              ))//16
  u0_ofm_test(
    .layer_start               ( layer_start                      ),
    .layer_cnt                 ( layer_cnt_r                      ),

    .ofm_woffset               ( ofm_woffset                      ), 
    .ofm_roffset               ( ofm_roffset                      ),
    .ofm_wbase                 ( ofm_wbase                        ),
    .ofm_rbase                 ( ofm_rbase                        ),
    .ofm_din_enc               ( ofm_din_enc                      ),
    .ofm_snum                  ( ofm_snum                         ),
    .concat_num                ( concat_num                       ),
    .bias_snum                 ( bias_snum                        ),
    .bias_sel                  ( bias_sel                         ),
    .tmp_sel                   ( tmp_sel                          ),
    .output_sel                ( output_sel                       ),
    .nvm_osel                  ( nvm_osel                         ),    
    .ofm_pp                    ( ofm_pp                           ),    
    .ofm_start                 ( ofm_start                        ),
    .ofm_done                  ( ofm_done                         ), 
      
    .ofm_din                   ( ofm_din                          ),
    .ofm_din_vld               ( ofm_din_vld                      ),
    .ofm_din_done              ( ofm_din_done                     ),
    .bias_data                 ( bias_data                        ),
    .bias_rvld                 ( bias_rvld                        ),

    .clk                       ( clk                              ),
    .reset                     ( reset                            )
  );
  
 //---------------------------------------------------------------
  nvm_test1 #(
    .DW                        ( DW                               ),//16
    .NUM                       ( NUM                              ),//32
    .PLEN                      ( PLEN                             ) //24
  ) u0_nvm_test1(
    .layer_start               ( layer_start                      ),
    .layer_cnt                 ( layer_cnt_r                      ),
       
    .nvm_rnum                  ( nvm_rnum                         ),
    .nvm_rstep                 ( nvm_rstep                        ),
    .nvm_idir                  ( nvm_idir                         ),
    .nvm_inum                  ( nvm_inum                         ),
    .nvm_odir                  ( nvm_odir                         ),
    .nvm_onum                  ( nvm_onum                         ),
    .nvm_xnum                  ( nvm_xnum                         ),
    .nvm_ynum                  ( nvm_ynum                         ),
    .nvm_bnum                  ( nvm_bnum                         ),
    .nvm_gnum                  ( nvm_gnum                         ),

    .tr_en                     ( tr_en                            ),
    .res_en                    ( res_en                           ),
    .ln_en                     ( ln_en                            ),
    .act_type                  ( act_type                         ),    
    .act_en                    ( act_en                           ),
    .div_en                    ( div_en                           ),
    .sf_en                     ( sf_en                            ),
    .pos                       ( pos                              ),
     
    .ofm_done                  ( ofm_done                         ),
    .nvm_rstart                ( nvm_rstart                       ),
   
    .nvm_raddr_vld             ( nvm_raddr_vld                    ),
    .nvm_raddr                 ( nvm_raddr                        ),
    .res_rvld                  ( res_rvld                         ),
    .res_rdata                 ( res_rdata                        ), 
    .gamma_wdata               ( gamma_wdata                      ),
    .gamma_wvld                ( gamma_wvld                       ),
    .gamma_wstart              ( gamma_wstart                     ),
    .beta_wdata                ( beta_wdata                       ),
    .beta_wvld                 ( beta_wvld                        ),
    .beta_wstart               ( beta_wstart                      ),
    
    .clk                       ( clk                              ),
    .reset                     ( reset                            )  
  );


  //-------------------------------------------------------------------
  //Simulation

   always @(posedge clk)
   if(layer_start && layer_cnt==1)begin
   $display("************************************************************");
   $display("\n");
   $display("Simulation start:$time=%p",$realtime);
   $display("\n");
   $display("************************************************************");
   end

    wire                       sim_done                               ;              
    dly_cell #(
      .DLY                     ( 1000                                 ),
      .DW                      ( 1                                    )
    ) dly_simd(
      .dout                    ( sim_done                             ),
      .din                     ( layer_cnt==10                        ),
      .clk                     ( clk                                  ),
      .reset                   ( reset                                )
    );

   always @(posedge clk)
   if(sim_done)begin
   $display("************************************************************");
   $display("\n");
   $display("Simulation completed:$time=%p",$realtime);
   $display("\n");
   $display("************************************************************");
   $stop();
   end

//----------------------------------------------------------------------------------------

    point#(
        .Q    ( 16                          ),
        .P    ( 13                          ),//---13
        .N    ( 32                          ),
        .F    ( "/home/lsq/Desktop/opu/rtl/src/12_data/rtl1/rtl1_3_b_ofmap_1.txt" )
    )point1(  
        .ctrl (ddr_wvld&&(layer_cnt==1)     ),
        .in   (ddr_wdata                    ),
        .out  (                             ),
        .clk  (clk                          ));

    point#(
        .Q    ( 16                          ),
        .P    ( 12                          ),//---12
        .N    ( 32                          ),
        .F    ( "/home/lsq/Desktop/opu/rtl/src/12_data/rtl2/rtl2_3_b_ofmap_2.txt" )
    )point2(  
        .ctrl (ddr_wvld&&(layer_cnt==2)     ),
        .in   (ddr_wdata                    ),
        .out  (                             ),
        .clk  (clk                          ));

    point#(
        .Q    ( 16                          ),
        .P    ( 12                          ),//---12
        .N    ( 32                          ),
        .F    ( "/home/lsq/Desktop/opu/rtl/src/12_data/rtl3/rtl3_3_b_ofmap_3.txt" )
    )point3(  
        .ctrl (ddr_wvld&&(layer_cnt==3)     ),
        .in   (ddr_wdata                    ),
        .out  (                             ),
        .clk  (clk                          ));

    point#(
        .Q    ( 16                          ),
        .P    ( 15                          ),//---15
        .N    ( 32                          ),
        .F    ( "/home/lsq/Desktop/opu/rtl/src/12_data/rtl4/rtl4_3_b_ofmap_4.txt" )
    )point4(  
        .ctrl (ddr_wvld&&(layer_cnt==4)     ),
        .in   (ddr_wdata                    ),
        .out  (                             ),
        .clk  (clk                          ));

    point#(
        .Q    ( 16                          ),
        .P    ( 14                          ),//---14
        .N    ( 32                          ),
        .F    ( "/home/lsq/Desktop/opu/rtl/src/12_data/rtl5/rtl5_3_b_ofmap_5.txt" )
    )point5(  
        .ctrl (ddr_wvld&&(layer_cnt==5)     ),
        .in   (ddr_wdata                    ),
        .out  (                             ),
        .clk  (clk                          ));

    point#(
        .Q    ( 16                          ),
        .P    ( 9                           ),//---9
        .N    ( 32                          ),
        .F    ( "/home/lsq/Desktop/opu/rtl/src/12_data/rtl6/rtl6_3_b_ofmap_6.txt" )
    )point6(  
        .ctrl (ddr_wvld&&(layer_cnt==6)     ),
        .in   (ddr_wdata                    ),
        .out  (                             ),
        .clk  (clk                          ));

    point#(
        .Q    ( 16                          ),
        .P    ( 11                          ),//---11
        .N    ( 32                          ),
        .F    ( "/home/lsq/Desktop/opu/rtl/src/12_data/rtl7/rtl7_3_b_ofmap_7.txt" )
    )point7(  
        .ctrl (ddr_wvld&&(layer_cnt==7)     ),
        .in   (ddr_wdata                    ),
        .out  (                             ),
        .clk  (clk                          ));

    point#(
        .Q    ( 16                          ),
        .P    ( 11                          ),//---11
        .N    ( 32                          ),
        .F    ( "/home/lsq/Desktop/opu/rtl/src/12_data/rtl8/rtl8_3_b_ofmap_8.txt" )
    )point8(  
        .ctrl (ddr_wvld&&(layer_cnt==8)     ),
        .in   (ddr_wdata                    ),
        .out  (                             ),
        .clk  (clk                          ));

 integer ii=0,td1,td2,td3,td4,td5,td6,td7,td8;
 initial begin
 td1 = $fopen("/home/lsq/Desktop/opu/rtl/src/12_data/rtl1/rtl1_3_debug_store.txt","w");
 td2 = $fopen("/home/lsq/Desktop/opu/rtl/src/12_data/rtl2/rtl2_3_debug_store.txt","w");
 td3 = $fopen("/home/lsq/Desktop/opu/rtl/src/12_data/rtl3/rtl3_3_debug_store.txt","w");
 td4 = $fopen("/home/lsq/Desktop/opu/rtl/src/12_data/rtl4/rtl4_3_debug_store.txt","w");
 td5 = $fopen("/home/lsq/Desktop/opu/rtl/src/12_data/rtl5/rtl5_3_debug_store.txt","w");
 td6 = $fopen("/home/lsq/Desktop/opu/rtl/src/12_data/rtl6/rtl6_3_debug_store.txt","w");
 td7 = $fopen("/home/lsq/Desktop/opu/rtl/src/12_data/rtl7/rtl7_3_debug_store.txt","w");
 td8 = $fopen("/home/lsq/Desktop/opu/rtl/src/12_data/rtl8/rtl8_3_debug_store.txt","w");
 end

 always @(posedge clk)
 if(layer_cnt==1)//"x1":[1,768 ,64,1 ],[13,16],transpose
 begin
    if(ddr_wvld) for(ii=31;ii>=0;ii=ii-1)
    begin
         if(ii==0)$fwrite(td1,"%h\n",ddr_wdata[ii*16+:16])     ;
         else     $fwrite(td1,"%h ", ddr_wdata[ii*16+:16])     ;  
    end
 end
 else
 if(layer_cnt==2)//"x2":[1,768 ,64,1 ],[12,16],no
 begin
    if(ddr_wvld) for(ii=31;ii>=0;ii=ii-1)
    begin
         if(ii==0)$fwrite(td2,"%h\n",ddr_wdata[ii*16+:16])     ;
         else     $fwrite(td2,"%h ", ddr_wdata[ii*16+:16])     ;  
    end
 end
 else
 if(layer_cnt==3)//"x3":[1,768 ,64,1 ],[12,16],no
 begin
    if(ddr_wvld) for(ii=31;ii>=0;ii=ii-1)
    begin
         if(ii==0)$fwrite(td3,"%h\n",ddr_wdata[ii*16+:16])     ;
         else     $fwrite(td3,"%h ", ddr_wdata[ii*16+:16])     ;  
    end
 end
 else
 if(layer_cnt==4)//"x4":[1,64  ,64,12],[15,16],softmax
 begin
    if(ddr_wvld) for(ii=31;ii>=0;ii=ii-1)
    begin
         if(ii==0)$fwrite(td4,"%h\n",ddr_wdata[ii*16+:16])     ;
         else     $fwrite(td4,"%h ", ddr_wdata[ii*16+:16])     ;  
    end
 end
 else
 if(layer_cnt==5)//"x5":[1,64  ,64,12],[14,16],no
 begin
    if(ddr_wvld) for(ii=31;ii>=0;ii=ii-1)
    begin
         if(ii==0)$fwrite(td5,"%h\n",ddr_wdata[ii*16+:16])     ;
         else     $fwrite(td5,"%h ", ddr_wdata[ii*16+:16])     ;  
    end
 end
 else
 if(layer_cnt==6)//"x6":[1,768 ,64,1 ],[9 ,16],layernorm
 begin
    if(ddr_wvld) for(ii=31;ii>=0;ii=ii-1)
    begin
         if(ii==0)$fwrite(td6,"%h\n",ddr_wdata[ii*16+:16])     ;
         else     $fwrite(td6,"%h ", ddr_wdata[ii*16+:16])     ; 
    end 
 end
 else
 if(layer_cnt==7)//"x7":[1,3072,64,1 ],[11,16],gelu
 begin
    if(ddr_wvld) for(ii=31;ii>=0;ii=ii-1)
    begin
         if(ii==0)$fwrite(td7,"%h\n",ddr_wdata[ii*16+:16])     ;
         else     $fwrite(td7,"%h ", ddr_wdata[ii*16+:16])     ;  
    end
 end
 else
 if(layer_cnt==8)//"x8":[1,768 ,64,1 ],[11,16],layernorm
 begin
    if(ddr_wvld) for(ii=31;ii>=0;ii=ii-1)
    begin
         if(ii==0)$fwrite(td8,"%h\n",ddr_wdata[ii*16+:16])     ;
         else     $fwrite(td8,"%h ", ddr_wdata[ii*16+:16])     ;  
    end 
 end



endmodule