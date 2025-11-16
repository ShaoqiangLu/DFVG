`timescale 1ns / 1ps
// -----------------------------------------------------------------------------
// Copyright      : UCLA EDA LAB
// -----------------------------------------------------------------------------
// Engineer       : Chen Wu
// Design Name    : opu series
// Module Name    : nvm_top
// Target Devices : 325t, Alveo U200
// Tool Versions  : Vivado 2020.1, Modelsim 2019.4
// Description    : 
//    Post processes including: residual, GeLU, Softmax, LayerNormalization,
//    Transpose. Each feature can be enabled or not.
//    Attention   : In this design, DW * NUM must be 512 (DDR Datawidth)
//
// Revision       :
// Version        Date        Author        Descriptin
// 1.0            2022-04-08  Chen Wu       Initial version
// -----------------------------------------------------------------------------

`include "core_param.vh"
module nvm_top_old #(
  parameter             DW        =     16                        ,
  parameter             NUM       =     32                        ,
  parameter             PLEN      =     24                        ,
  localparam            ADW       =     NUM*DW                    
)(
  input                               clk                         ,
  input                               reset                       ,
  input                               nvm_osel                    ,
  input         [   10 : 0]           nvm_rnum                    ,
  input         [    6 : 0]           nvm_rstep                   ,
  input         [   11 : 0]           nvm_xnum                    ,
  input         [   11 : 0]           nvm_ynum                    ,
  input         [   11 : 0]           nvm_bnum                    ,
  input         [   11 : 0]           nvm_gnum                    ,
  input                               nvm_sync                    ,
  output        [  127 : 0]           nvm_sum_tx                  , 
  input         [  127 : 0]           nvm_sum_rx                  , 
  input                               tr_en                       ,
  input                               res_en                      ,
  input                               ln_en                       ,
  input         [  3 :  0 ]           act_type                    ,
  input                               act_en                      ,
  input                               div_en                      ,
  input                               sf_en                       ,
  input                               nvm_start                   ,
  output  reg                         nvm_done      =0            ,
  output  reg   [   10 : 0]           nvm_raddr     = 0           ,
  output  wire                        nvm_raddr_vld               ,
  output  wire                        nvm_raddr_done              ,
  input         [ADW-1 : 0]           nvm_rdata                   ,
  input                               nvm_rdata_vld               ,
  input                               nvm_rdata_done              ,
  input         [  511 : 0]           res_rdata                   ,
  input                               res_rdata_vld               ,
  input         [  511 : 0]           gamma_wdata                 , 
  input                               gamma_wvld                  ,
  input                               gamma_wstart                ,
  input         [  511 : 0]           beta_wdata                  ,
  input                               beta_wvld                   ,
  input                               beta_wstart                 ,

  output  reg   [   10 : 0]           back_waddr        =0        ,                      
  output  reg   [ADW-1 : 0]           back_wdata        =0        ,
  output  reg                         back_wvld         =0        ,
  output  reg                         back_wdone        =0        ,
  input   wire                        back_rstart                 ,
  output  reg   [   10 : 0]           back_raddr        =0        ,
  output  reg                         back_raddr_vld    =0        ,
  input         [ADW-1 : 0]           back_rdata                  ,
  input   wire                        back_rdata_vld              , 


  input                               nvm_idir                    ,
  input         [    5 : 0]           nvm_inum                    ,
  input                               nvm_odir                    ,
  input         [    5 : 0]           nvm_onum                    ,

  
  output  reg   [  511 : 0]           ddr_wdata                   ,
  output  reg                         ddr_wvld                    ,
  input                               ddr_wrdy                    
);

  reg           [6 : 0]               nvm_row_cnt       = 0       ;
  reg           [9 : 0]               nvm_cnt           = 0       ;
  wire                                nvm_row_done                ;
  wire                                nvm_row_done_all            ;
  reg                                 nvm_running       = 0       ;
//  reg                                 nvm_done_flay     = 0       ;
//  reg                                 nvm_done_flay_r   = 0       ;

  wire          [ADW-1 : 0]           res_dout_data               ;
  wire                                res_dout_vld                ;
  wire                                res_dout_done               ;

  reg           [ADW-1 : 0]           gelu_din = 0                ;
  reg                                 gelu_din_vld  = 0           ;
  reg                                 gelu_din_done = 0           ;
  
  
  
  wire          [ADW-1 : 0]           gelu_dout                   ;
  wire                                gelu_dout_vld               ;
  wire                                gelu_dout_done              ;

  reg                                 sf_running = 0              ;
  wire                                sf_fifo_wen                 ;
  wire          [  ADW : 0]           sf_fifo_wdata               ;
  wire                                sf_fifo_pfull               ;
  reg           [15:0]                sf_fifo_ren_cnt=0;
  wire                                sf_fifo_ren                 ;
  wire          [  ADW : 0]           sf_fifo_rdata               ;
  wire                                sf_fifo_empty               ;


  wire          [ADW-1 : 0]           sf_din                      ;
  reg                                 sf_din_vld    =0            ;
  wire                                sf_din_done                 ;
  wire          [ADW-1 : 0]           sf_dout                     ;
  wire                                sf_dout_vld                 ;
  wire                                sf_dout_done                ;

  reg                                 ln_fifo_wen = 0             ;
  reg           [  ADW : 0]           ln_fifo_wdata = 0           ;
  wire                                ln_fifo_pfull               ;
  reg           [15:0]                ln_fifo_ren_cnt=0;
  wire                                ln_fifo_ren                 ;
  wire          [  ADW : 0]           ln_fifo_rdata               ;
  wire                                ln_fifo_empty               ;

  wire                                ln_fifo_start               ;
  wire                                ln_fifo_ready               ;
  wire          [ADW-1 : 0]           ln_din                      ;
  reg                                 ln_din_vld       =0         ;
  wire                                ln_din_done                 ;
  wire          [ADW-1 : 0]           ln_dout                     ;
  wire                                ln_dout_vld                 ;
  wire                                ln_dout_done                ;


  wire          [ADW-1 : 0]           tr_dout                     ;
  wire                                tr_dout_vld                 ;
  wire                                tr_dout_done                ;

  //--------------------------------------------------------------
  //************Generate Read Address from ofm_top****************
  //--------------------------------------------------------------
  reg nvm_osel_r=0;always @(posedge clk)nvm_osel_r<=nvm_osel;
  always @(posedge clk) begin
  if(reset) begin
      nvm_row_cnt         <=    0                                 ;
  end else
    if ( nvm_start  )
      nvm_row_cnt         <=    0                                 ;
    else if ( nvm_row_done )
      nvm_row_cnt         <=    0                                 ;
    else if ( nvm_raddr_vld )
      nvm_row_cnt         <=    nvm_row_cnt + 1                   ;//form 0 to 23
  end
  assign  nvm_row_done = nvm_raddr_vld &(nvm_row_cnt+1==nvm_rstep);
 
   always @(posedge clk) begin
  if(reset) begin
      nvm_cnt             <=    0                                 ;
  end else
    if ( nvm_start  )
      nvm_cnt             <=    0                                 ;
    else if ( nvm_row_done_all )
      nvm_cnt             <=    0                                 ;
    else if ( nvm_row_done )
      nvm_cnt             <=    nvm_cnt + 1                       ;//form 0 to 64
  end
  assign   nvm_row_done_all= nvm_row_done &(nvm_cnt+1==nvm_rnum) ;


  always @(posedge clk) begin
    if ( reset )
      nvm_running         <=    0                                 ;
    else if ( nvm_row_done_all)
      nvm_running         <=    0                                 ;
    else if ( nvm_start  )
      nvm_running         <=    1                                 ;
  end


  assign nvm_raddr_vld= nvm_running                               ; 

  always @(posedge clk) begin
  if(reset)begin
          nvm_raddr <= 11'h0                                      ; 
  end else
    if (nvm_start ||nvm_row_done_all) 
          nvm_raddr <= 11'h0                                      ;
    else 
    if (~nvm_osel) begin 
        if (nvm_raddr_vld )nvm_raddr <= nvm_raddr + 1             ;//0,1,2,3
    end
    else begin  
         if (nvm_row_done )nvm_raddr <= nvm_cnt + 1               ;//1,65,129
    else if (nvm_raddr_vld)nvm_raddr <= nvm_raddr + nvm_rnum      ;//0,64,128,---1472
    end
  end

  assign nvm_raddr_done =nvm_row_done                             ;


  //----------------------------------------------------------------------
  // Residual
  // fixed 2 cycles delay
  //----------------------------------------------------------------------
  res_top_old # (
    .NUM                        ( NUM                             ),
    .DW                         ( DW                              ) 
  ) RES (
    .res_dout_data              ( res_dout_data                   ),
    .res_dout_vld               ( res_dout_vld                    ),
    .res_dout_done              ( res_dout_done                   ),
    .nvm_rdata                  ( nvm_rdata                       ),
    .nvm_rdata_vld              ( nvm_rdata_vld                   ),
    .nvm_rdata_done             ( nvm_rdata_done                  ),
    .res_rdata                  ( res_rdata                       ),
    .res_rdata_vld              ( res_rdata_vld                   ),
    .res_en                     ( res_en                          ),
    .clk                        ( clk                             ),
    .reset                      ( reset                           )
  );




//----------------------------------------------------------------------
// GeLU
// fixed 2 cycles delay
// fixed fraction length
//----------------------------------------------------------------------
genvar i                                                        ;
generate for ( i = 0; i < NUM; i = i + 1 ) begin:gi1
    reg   signed  [DW-1 : 0]    gelu_tmp0   =0                    ;
    reg   signed  [DW-1 : 0]    gelu_tmp0_r =0                    ;
    reg   signed  [DW-1 : 0]    gelu_tmp1   =0                    ;
    reg   signed  [DW-1 : 0]    res_dout_data_r1   =0             ;
    reg   signed  [DW-1 : 0]    res_dout_data_r2   =0             ;

    always @(posedge clk)  
    if(div_en) gelu_tmp0<={{3{res_dout_data[DW*i+DW-1]}},
                             res_dout_data[DW*i+DW-1:DW*i+3]};
    else       gelu_tmp0   <= res_dout_data[DW*i +: DW] ;

    always @(posedge clk) 
    begin
        gelu_tmp0_r     <= gelu_tmp0;
        res_dout_data_r1<= res_dout_data[DW-1:0];
        res_dout_data_r2<= res_dout_data_r1     ;
    end
    

    always @(posedge clk)  
    if(sf_en | act_en) gelu_tmp1<= ((~nvm_idir) ? 
                           ($signed(gelu_tmp0 <<< nvm_inum)) : 
                           ($signed(gelu_tmp0 >>> nvm_inum)));
    else               gelu_tmp1<= gelu_tmp0;
                          
    
    always @(posedge clk) begin
      if ( gelu_tmp1[DW-1] == gelu_tmp0_r[DW-1] )
        gelu_din[DW*i +: DW]    <=  gelu_tmp1                     ;
      else if ( res_dout_data_r2[DW*i+DW-1] )
        gelu_din[DW*i +: DW]    <=  {1'b1, {(DW-1){1'b0}}}        ;
      else
        gelu_din[DW*i +: DW]    <=  {1'b0, {(DW-1){1'b1}}}        ;
    end
end
endgenerate

generate begin:gi2
    reg      r1_gelu_din_vld  = 0           ;
    reg      r1_gelu_din_done = 0           ;
    reg      r2_gelu_din_vld  = 0           ;
    reg      r2_gelu_din_done = 0           ;
    
    always @(posedge clk)
    begin
        r1_gelu_din_vld  <= res_dout_vld    ;
        r1_gelu_din_done <= res_dout_done   ;
        r2_gelu_din_vld  <= r1_gelu_din_vld ;
        r2_gelu_din_done <= r1_gelu_din_done;
        gelu_din_vld     <= r2_gelu_din_vld ;
        gelu_din_done    <= r2_gelu_din_done;
    end
end
endgenerate


  //----------------------------------------------------------------------
  // gelu
  //----------------------------------------------------------------------
  GELU_driver #(
    .NUM_ELEMS                  ( NUM                             )
  ) GELU_old (
    .clk                        ( clk                             ),
    .rst                        ( reset                           ),
    .enable                     ( act_en                          ),
    .x_data                     ( gelu_din                        ),
    .x_vld                      ( gelu_din_vld                    ),
    .x_done                     ( gelu_din_done                   ),
    .y_data                     ( gelu_dout                       ),
    .y_vld                      ( gelu_dout_vld                   ),
    .y_done                     ( gelu_dout_done                  ) 
  );




  //----------------------------------------------------------------------
  // Softmax
  // 2 cycles ram; 2 cycles residual; 1 cycle shift; 3 cycles gepu;
  // Use fifo to buffer, keep the softmax only work for one package
  // Need to be optimized
  //----------------------------------------------------------------------
  assign sf_fifo_wdata    =     {gelu_dout_done, gelu_dout}      ;
  assign sf_fifo_wen      =      gelu_dout_vld                   ;
  //-------------------------------------------------------------
  localparam        FIFO_1_DELAY       = 1                       ;
  localparam        FIFO_1_DEEP        = 2048                    ;
  localparam        FIFO_1_WIDTH       = ADW+1                   ;
  (*keep_hierarchy="yes"*)sync_fifo #(
    .MEM_TYPE              ( "block"                             ),
    .RMODE                 ( "std"                               ),
    .FEATURES              ( "0002"                              ),
    .RLATENCY              ( FIFO_1_DELAY                        ),            
    .DEPTH                 ( FIFO_1_DEEP                         ),    
    .PFULL_THRESH          ( FIFO_1_DEEP-10                      ),       
    .RWIDTH                ( FIFO_1_WIDTH                        ),
    .WWIDTH                ( FIFO_1_WIDTH                        ),
    .PEMPTY_THRESH         ( 10                                  )
  ) FIFO1 (
    .aempty                (                                     ),
    .pempty                (                                     ),
    .empty                 ( sf_fifo_empty                       ),
    .rdata                 ( sf_fifo_rdata                       ),
    .ren                   ( sf_fifo_ren                         ),
    .full                  (                                     ),
    .afull                 (                                     ),
    .pfull                 ( sf_fifo_pfull                       ),
    .wdata                 ( sf_fifo_wdata                       ),
    .wen                   ( sf_fifo_wen                         ),
    .clk                   ( clk                                 ),
    .reset                 ( reset                               )
  );
  
  
  always @(posedge clk)
  if(sf_dout_done)     sf_fifo_ren_cnt <= 0;
  else if(sf_fifo_ren) sf_fifo_ren_cnt <= sf_fifo_ren_cnt+1;
  
  always @(posedge clk) begin
    if ( reset )
      sf_running          <=    0                                 ;
    else if(~sf_en)
      sf_running          <=    0                                 ;
    else if (sf_fifo_ren_cnt== nvm_rstep-1)
      sf_running          <=    1                                 ;
    else if (sf_dout_done )
      sf_running          <=    0                                 ;
  end

  assign sf_fifo_ren      =     sf_en?(~sf_running)&(~sf_fifo_empty)&(~ln_fifo_pfull)
                                                   :(~sf_fifo_empty)&(~ln_fifo_pfull);
  assign sf_din           =     sf_din_vld? sf_fifo_rdata[ADW-1:0]:0;
  assign sf_din_done      =     sf_din_vld? sf_fifo_rdata[ADW]    :0;
  always @(posedge clk)         sf_din_vld     <=sf_fifo_ren      ;



//----------------------------------------------------------------------
//SF
//----------------------------------------------------------------------
  soft_max_old #(
    .DATA_WIDTH                 ( DW                              ), 
    .NUM_ELEMS                  ( NUM                             ), 
    .MAX_PKG_LEN                ( 2                               )
  ) SoftMax (
    .clk                        ( clk                             ),
    .rst                        ( reset                           ),
    .enable                     ( sf_en                           ),
    .nvm_rstep                  ( nvm_rstep                       ),
    .sf_din_vld                 ( sf_din_vld                      ),
    .sf_din_done                ( sf_din_done                     ),
    .sf_din                     ( sf_din                          ),
    .sf_dout                    ( sf_dout                         ),
    .sf_dout_vld                ( sf_dout_vld                     ),
    .sf_dout_done               ( sf_dout_done                    )
  );



  //-------------------------------------------------------------------
  // Use fifo to handshake with LN
  //-------------------------------------------------------------------
  generate for ( i = 0; i < NUM; i = i + 1 ) begin:gli1
    reg     [DW-1 : 0]          sf_dout_r     =0                  ;
    reg     [DW-1 : 0]          ln_tmp        =0                  ;
    always @(posedge clk)sf_dout_r <= sf_dout[DW*i +: DW]         ;
    always @(posedge clk)ln_tmp    <= (sf_en | act_en) ?
                                ((~nvm_odir) ? 
                                (sf_dout[DW*i +: DW]<<<nvm_onum)  :
                                (sf_dout[DW*i +: DW]>>>nvm_onum)) :
                                 sf_dout[DW*i +: DW]              ;
    always @(posedge clk) begin
      if ( ln_tmp[DW-1] == sf_dout_r[DW-1] )
        ln_fifo_wdata[DW*i +: DW]   <=  ln_tmp                    ;
      else if ( sf_dout_r[DW*i+DW-1] )
        ln_fifo_wdata[DW*i +: DW]   <=  {1'b1, {(DW-1){1'b0}}}    ;
      else
        ln_fifo_wdata[DW*i +: DW]   <=  {1'b0, {(DW-1){1'b1}}}    ;
    end
  end
  endgenerate



generate 
     reg sf_dout_vld_r1  =0;
     reg sf_dout_done_r1 =0;
     reg sf_dout_done_r2 =0;
  always @(posedge clk)
  begin
     sf_dout_done_r1 <= sf_dout_done   ;
     sf_dout_done_r2 <= sf_dout_done_r1;
     sf_dout_vld_r1  <= sf_dout_vld    ;
     
       if ( sf_dout_vld_r1 ) begin
         ln_fifo_wdata[ADW]  <=    sf_dout_done_r1  ;
         ln_fifo_wen         <=    1                ;
       end else begin
         ln_fifo_wdata[ADW]  <=    0                ;
         ln_fifo_wen         <=    0                ;
       end
  end      
endgenerate

  //----------------------------------------------------------------
  localparam        FIFO_2_DELAY       = 1                        ;
  localparam        FIFO_2_DEEP        = 2048                     ;
  localparam        FIFO_2_WIDTH       = ADW+1                    ;
  (*keep_hierarchy="yes"*)sync_fifo #(
    .MEM_TYPE                   ( "block"                         ),
    .RMODE                      ( "std"                           ),
    .FEATURES                   ( "0002"                          ),
    .RLATENCY                   ( FIFO_1_DELAY                    ),            
    .DEPTH                      ( FIFO_1_DEEP                     ),    
    .PFULL_THRESH               ( FIFO_1_DEEP-10                  ),       
    .RWIDTH                     ( FIFO_1_WIDTH                    ),
    .WWIDTH                     ( FIFO_1_WIDTH                    ),
    .PEMPTY_THRESH              ( 10                              )
  ) old_FIFO2 (
    .aempty                     (                                 ),
    .pempty                     (                                 ),
    .empty                      ( ln_fifo_empty                   ),
    .rdata                      ( ln_fifo_rdata                   ),
    .ren                        ( ln_fifo_ren                     ),
    .full                       (                                 ),
    .afull                      (                                 ),
    .pfull                      ( ln_fifo_pfull                   ),
    .wdata                      ( ln_fifo_wen?ln_fifo_wdata:0     ),
    .wen                        ( ln_fifo_wen                     ),

    .clk                        ( clk                             ),
    .reset                      ( reset                           )
  );
  
  assign ln_fifo_start    =     ln_fifo_wen && ln_fifo_empty       ;
  always @(posedge clk)         ln_din_vld <= ln_fifo_ren          ;
  assign ln_din           =     ln_din_vld?ln_fifo_rdata[ADW-1:0]:0;
  assign ln_din_done      =     ln_din_vld?ln_fifo_rdata[ADW]    :0;
  




//----------------------------------------------------------------------
//LN
//----------------------------------------------------------------------


always @(posedge clk)
if(ln_en)
begin
    if(ln_fifo_ready&&ln_dout_done||ln_fifo_start)
                                ln_fifo_ren_cnt<=nvm_rstep;
    else if(ln_fifo_ren_cnt==0) ln_fifo_ren_cnt<=0;
    else                        ln_fifo_ren_cnt<=ln_fifo_ren_cnt-1;
end else                        ln_fifo_ren_cnt<=0;

assign  ln_fifo_ren =ln_en ?(ln_fifo_ren_cnt>=1&&ln_fifo_ren_cnt<=nvm_rstep)
                             &ddr_wrdy&(~ln_fifo_empty):(~ln_fifo_empty);
  layer_norm_old # (
    .DATA_WIDTH                 ( DW                              ),
    .OUT_WIDTH                  ( DW                              ),
    .NUM_ELEMS                  ( NUM                             ),
    .MAX_PKG_LEN                ( 24                              ) 
  ) LayerNorm (
    .clk                        ( clk                             ),
    .rst                        ( reset                           ),
    .enable                     ( ln_en                           ),
    .nvm_rstep                  ( nvm_rstep                       ),
    .xnum                       ( nvm_xnum                        ),
    .ynum                       ( nvm_ynum                        ),
    .bnum                       ( nvm_bnum                        ),
    .gnum                       ( nvm_gnum                        ),
    .ln_fifo_ready              ( ln_fifo_ready                   ),
    .ln_din                     ( ln_din                          ),
    .ln_din_vld                 ( ln_din_vld                      ),
    .ln_din_done                ( ln_din_done                     ),
    .ln_dout                    ( ln_dout                         ),
    .ln_dout_vld                ( ln_dout_vld                     ),
    .ln_dout_done               ( ln_dout_done                    ),
    .gamma_wstart               ( gamma_wstart                    ),
    .gamma_wvld                 ( gamma_wvld                      ),
    .gamma_wdata                ( gamma_wdata                     ),
    .beta_wstart                ( beta_wstart                     ),
    .beta_wvld                  ( beta_wvld                       ),
    .beta_wdata                 ( beta_wdata                      ),
    .sum_tx                     ( nvm_sum_tx                      ),
    .sum_rx                     ( nvm_sum_rx                      )
  );

  //----------------------------------------------------------------
  // Transpose
  //----------------------------------------------------------------
  reg     [ADW-1:0] tr_din        =0  ;
  reg               tr_din_vld    =0  ;
  reg               tr_din_done   =0  ;
  always @(posedge clk)
  if(tr_en)
  begin
        tr_din      <= nvm_rdata      ;
        tr_din_vld  <= nvm_rdata_vld  ;
        tr_din_done <= nvm_rdata_done ;
  end else begin
        tr_din      <= 0  ;
        tr_din_vld  <= 0  ;
        tr_din_done <= 0  ;
  end
  
  transpose_old #(
    .DW                         ( DW                              ),
    .NUM                        ( NUM                             )
  ) TR (
    .tr_dout                    ( tr_dout                         ),
    .tr_dout_vld                ( tr_dout_vld                     ),
    .tr_dout_done               ( tr_dout_done                    ),
    .tr_din                     ( tr_din                          ),
    .tr_din_vld                 ( tr_din_vld                      ),
    .tr_din_done                ( tr_din_done                     ),
    .enable                     ( tr_en                           ),
    .clk                        ( clk                             ),
    .reset                      ( reset                           )
  );




  //----------------------------------------------------------------
  // back write
  //----------------------------------------------------------------
  reg           [   10 : 0]           back_waddr1       =0          ; 
  reg           [   10 : 0]           back_waddr2       =0          ;
  wire                                back_waddr2_done_all          ;
  wire          [   10 : 0]           back_waddr3                   ;
  assign back_waddr2_done_all=ln_dout_vld&&(back_waddr2==nvm_rnum -1)
                                         &&(back_waddr1==nvm_rstep-1);
  always @(posedge clk)
  if(nvm_start)begin
      back_waddr1 <= 0;
      back_waddr2 <= 0;
  end
  else if(ln_dout_vld&&nvm_osel)
  begin
     if(back_waddr2_done_all)          back_waddr1<=back_waddr1     ;
     else if(back_waddr1==nvm_rstep-1) back_waddr1<=0;
     else                              back_waddr1<=back_waddr1+1   ;

     if(back_waddr2_done_all)          back_waddr2<=back_waddr2     ;
     else if(back_waddr1==nvm_rstep-1) back_waddr2<=back_waddr2+1   ;
  end
  assign back_waddr3 = ln_dout_vld?back_waddr1*nvm_rnum+back_waddr2:0;
  
  

  always @(posedge clk)
  if(nvm_osel)begin
      back_waddr <= back_waddr3             ;
      back_wdata <= ln_dout                 ;
      back_wvld  <= ln_dout_vld             ;
      back_wdone <= back_waddr2_done_all    ;
  end else begin
      back_waddr <= 0                       ;
      back_wdata <= 0                       ;
      back_wvld  <= 0                       ;
      back_wdone <= 0                       ;
  end

  //----------------------------------------------------------------
  // back read
  //----------------------------------------------------------------
  `ifndef ROUTER
  `ifndef DEBUG_CORE1
      wire [6:0] r_nvm_rstep=(ln_en)?nvm_rstep/4:nvm_rstep;
  `else
      wire [6:0] r_nvm_rstep=nvm_rstep;
  `endif
  `else
      wire [6:0] r_nvm_rstep=nvm_rstep;
  `endif
  
  
  wire                         back_raddr_done_all  ;
  always @(posedge clk)
  if(back_rstart)              back_raddr_vld<=1    ;
  else if(back_raddr_done_all) back_raddr_vld<=0    ;
  
  always @(posedge clk)
  if(back_rstart)              back_raddr    <=0    ;
  else if(back_raddr_done_all) back_raddr    <=0    ;
  else if(back_raddr_vld)      back_raddr    <=back_raddr+1;
  
  assign back_raddr_done_all=  back_raddr==(nvm_rnum*r_nvm_rstep-1);


  //--------------------------------------------------------------
  // DDR  output selection
  //--------------------------------------------------------------
  always @(posedge clk)
  if(!ddr_wrdy)
  begin
        ddr_wdata <= 0              ;
        ddr_wvld  <= 0              ;
  end 
  else if(tr_en)
  begin
        ddr_wdata <= tr_dout        ;
        ddr_wvld  <= tr_dout_vld    ;
  end
  else if(nvm_osel)
  begin
        ddr_wdata <= back_rdata     ;
        ddr_wvld  <= back_rdata_vld ;
  end
  else begin
        ddr_wdata <= ln_dout        ;
        ddr_wvld  <= ln_dout_vld    ;
  end



  //--------------------------------------------------------------
  // output done
  //--------------------------------------------------------------
  reg [16:0]  ddr_wvld_cnt=0  ;
  always @(posedge clk)
  if(nvm_start)     ddr_wvld_cnt<=0;
  else if(ddr_wvld) ddr_wvld_cnt<=ddr_wvld_cnt+1;

  always @(posedge clk)
  if(ddr_wvld_cnt==nvm_rnum*r_nvm_rstep-1) nvm_done <=1; 
  else                                     nvm_done <=0; 





endmodule