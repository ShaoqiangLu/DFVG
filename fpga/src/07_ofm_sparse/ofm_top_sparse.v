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
//layer1: x Q16_11,y Q16_17(15)--->p Q32_26   add Q37_26   pe_o Q42_26 ----->bias Q32_31     psum Q16_13 -----> output Q16_13
//layer2: x Q16_11,y Q16_15------->p Q32_26   add Q37_26   pe_o Q42_26 ----->bias Q32_31     psum Q16_12 -----> output Q16_12
//layer3: x Q16_11,y Q16_15------->p Q32_26   add Q37_26   pe_o Q42_26 ----->bias Q32_30     psum Q16_12 -----> output Q16_12
//layer4: x Q16_12,y Q16_12------->p Q32_24   add Q37_24   pe_o Q42_24 ----->bias Q32_29     psum Q16_8  -----> output Q16_15
//layer5: x Q16_15,y Q16_13------->p Q32_28   add Q37_28   pe_o Q42_28 ----->                psum Q16_14 -----> output Q16_14
//layer6: x Q16_14,y Q16_15------->p Q32_29   add Q37_29   pe_o Q42_29 ----->bias Q32_31     psum Q16_14 -----> output Q16_9
//layer7: x Q16_9 ,y Q16_16------->p Q32_25   add Q37_25   pe_o Q42_25 ----->bias Q32_31     psum Q16_11 -----> output Q16_11
//layer8: x Q16_11,y Q16_14------->p Q32_25   add Q37_25   pe_o Q42_25 ----->bias Q32_31     psum Q16_9  -----> output Q16_11

//`define OFM_PARAMETER
`include "opu_parameter.vh"

module ofm_top_sparse #(
  parameter     NUM         =           32                  ,
  parameter     PNUM        =           4                   ,
  parameter     DW_PE       =           37                  ,
  parameter     DW_OFM      =           37                  ,
  parameter     DW_BIAS     =           32                  ,
  parameter     DW_ADD      =           42                  ,
  parameter     DW_RAM      =           32                  ,
  parameter     DW_NVM      =           16                  ,
  localparam    CNUM        =           NUM*PNUM   
)(
  input                                 clk                 ,
  input                                 reset               ,
  
  input         [ 3-1:0]                ofm_din_enc         ,
  input         [ 7-1:0]                ofm_concat_num      ,  
  input         [ 5-1:0]                ofm_din_snum        ,
  input         [ 5-1:0]                ofm_bias_snum       ,
  input                                 ofm_rstart          ,     
  input         [15-1:0]                ofm_wbase           ,
  input         [15-1:0]                ofm_rbase           ,
  input                                 ofm_pp              ,
  input                                 ofm_bias_sel        ,
  input                                 ofm_tmp_sel         ,
  input                                 ofm_output_sel      ,
  input [NUM-1:0][PNUM*DW_BIAS-1:0]     ofm_bias_data       ,
  input [NUM-1:0][PNUM*DW_PE-1:0]       ofm_din             ,
  input [NUM-1:0][PNUM-1:0]             ofm_din_vld         ,
  input [NUM-1:0]                       ofm_din_meg         ,
  output wire                           ofm_rdone           , 
  output wire                           ofm_rdone_final     ,
  
  input          [15-1:0]               nvm_raddr           ,
  input                                 nvm_raddr_vld       ,
  input                                 nvm_raddr_done      ,
  
  output wire                           nvm_rdata_vld       ,
  output wire                           nvm_rdata_done      ,
  output wire[DW_NVM*NUM-1:0]           nvm_rdata           ,
  
  input  wire[NUM-1:0][DW_NVM-1:0]      back_wdata          ,
  input  wire   [15-1:0]                back_waddr          ,                      
  input  wire   [4-1:0]                 back_wvld           ,
  input  wire                           back_wdone          ,
  
  input         [15-1:0]                back_raddr          ,
  input                                 back_raddr_vld      ,
  output wire[DW_NVM*NUM-1:0]           back_rdata          ,
  output wire                           back_rdata_vld      ,

  input                                 nvm_res_en          ,

  input [NUM-1:0][DW_NVM-1:0]           res_load_data       ,
  input                                 res_load_vld        ,
  input                                 res_load_done       ,
  
  output wire[NUM*DW_NVM-1:0]           nvm_res_rdata       ,
  output wire                           nvm_res_rdata_vld              
);

  localparam OFM_DLY_START = `OFM_DLY_START;
  localparam OFM_DLY_DONE  = `OFM_DLY_DONE;



integer i=0,j=0;
//--------------------------------------------------------------------
//Data alignment.
//--------------------------------------------------------------------
 wire [NUM*PNUM*DW_PE-1:0]              align_data          ;
 wire [NUM*PNUM-1:0]                    align_data_vld      ;
 wire [NUM-1:0]                         align_data_meg      ;

(*keep_hierarchy="yes"*)ofm_align#(
  .NUM                  (NUM                                ),
  .PNUM                 (PNUM                               ),
  .DW                   (DW_PE                              ) 
) u_ofm_align(
  .clk                  (clk                                ),
  .reset                (reset                              ),
  .ofm_din              (ofm_din                            ),
  .ofm_din_vld          (ofm_din_vld                        ),    
  .ofm_din_meg          (ofm_din_meg                        ),  
  .align_data           (align_data                         ),
  .align_data_vld       (align_data_vld                     ),    
  .align_data_meg       (align_data_meg                     )  
);



//--------------------------------------------------------------------
//result merging
//--------------------------------------------------------------------
 wire [NUM*PNUM*DW_PE-1:0]      merge_data                  ;
 wire [NUM*PNUM      -1:0]      merge_data_vld              ;


(*keep_hierarchy="yes"*)ofm_merge #(
  .NUM                  (NUM                                ),
  .PNUM                 (PNUM                               ),
  .DW                   (DW_PE                              )  
)u_ofm_merge(
  .clk                  (clk                                ),
  .reset                (reset                              ),
  .data_in              (align_data                         ),
  .data_in_vld          (align_data_vld                     ),    
  .data_in_meg          (align_data_meg                     ),  
  .data_out             (merge_data                         ),
  .data_out_vld         (merge_data_vld                     )
);

//--------------------------------------------------------------------
//Collect full bit width.
//--------------------------------------------------------------------

 wire [NUM*PNUM*DW_PE-1:0]  collect_data                    ;
 wire [NUM*PNUM      -1:0]  collect_data_vld                ;
 

(*keep_hierarchy="yes"*)ofm_collect #(
  .NUM                  (NUM                                ),
  .PNUM                 (PNUM                               ),
  .DW                   (DW_PE                              )  
)u_ofm_collect(
  .clk                  (clk                                ),
  .reset                (reset                              ),
  .data_in_vld          (merge_data_vld                     ),
  .data_in              (merge_data                         ),
  .data_out             (collect_data                       ),
  .data_out_vld         (collect_data_vld                   )
);



//--------------------------------------------------------------------
//Use FIFO to temporarily buffer.(no use)
//--------------------------------------------------------------------
  localparam            FIFO_DELAY      = 1                 ;
  localparam            FIFO_DEEP       = 32                ;
  localparam            FIFO_WIDTH      = CNUM*(DW_PE+1)    ;
  wire                  fifo_empty      = 0                 ;
  wire                  fifo_ren                            ;
  (*dont_touch="true"*)reg                 fifo_rvld    =0  ;
  (*dont_touch="true"*)reg[FIFO_WIDTH -1:0]fifo_rdata   =0  ;

  always @(posedge clk)
  begin
    fifo_rvld <=collect_data_vld[0]                         ;
        
    for(i=0;i<CNUM;i=i+1)
    fifo_rdata[i*(DW_PE+1)+:(DW_PE+1)]<=
    {collect_data[i*DW_PE+:DW_PE],collect_data_vld[i]}      ;
  end


//--------------------------------------------------------------------
// Connected unified data.
//--------------------------------------------------------------------
  wire                                  concat_vld          ;
  wire      [CNUM*DW_PE-1:0]            concat_data         ;
  (*dont_touch="true"*)reg[PNUM*15-1:0] ofm_raddr   =0      ;
  wire                                  ofm_raddr_vld       ;
  wire      [CNUM*32-1:0]               ram_rdata_tmp       ;
  wire                                  ram_rdata_vld       ;
  
  
  (*keep_hierarchy="yes"*)
  ofm_concat#(
    .NUM                (32                                 ),
    .PNUM               (4                                  ),
    .DW                 (37                                 ), 
    .FIFO_WIDTH         (FIFO_WIDTH                         )
  )u_ofm_concat(
    .clk                (clk                                ),       
    .reset              (reset                              ),
    .fifo_empty         (fifo_empty                         ),
    .fifo_ren           (fifo_ren                           ),
    .fifo_rvld          (fifo_rvld                          ),
    .fifo_rdata         (fifo_rdata                         ),
    .concat_vld         (concat_vld                         ),
    .concat_data        (concat_data                        )  
  );


//--------------------------------------------------------------------
// Delay instruction register   :gap 1 cycle
//--------------------------------------------------------------------

  wire [ 3-1:0]         r_ofm_din_enc                       ;
  wire [ 7-1:0]         r_ofm_concat_num                    ;  
  wire [ 5-1:0]         r_ofm_din_snum                      ;
  wire [ 5-1:0]         r_ofm_bias_snum                     ;
  wire                  r_ofm_rstart                        ;     
  wire [15-1:0]         r_ofm_wbase                         ;
  wire [15-1:0]         r_ofm_rbase                         ;
  wire                  r_ofm_pp                            ;
  wire                  r_ofm_bias_sel                      ;
  wire                  r_ofm_tmp_sel                       ;
  wire                  r_ofm_output_sel                    ;

(*keep_hierarchy="yes"*)dly_cell#(
    .DLY      ( OFM_DLY_START                               ),
    .DW       ( 55                                          )
)u_dly_start(                    
.dout({//-----------------------------------------------------
         r_ofm_din_enc                                      ,
         r_ofm_concat_num                                   ,
         r_ofm_din_snum                                     ,
         r_ofm_bias_snum                                    ,
         r_ofm_rstart                                       ,
         r_ofm_wbase                                        ,
         r_ofm_rbase                                        ,
         r_ofm_pp                                           ,
         r_ofm_bias_sel                                     ,
         r_ofm_tmp_sel                                      ,
         r_ofm_output_sel
}), .din({//------------------------------------------------------
         ofm_din_enc                                        ,
         ofm_concat_num                                     ,
         ofm_din_snum                                       ,
         ofm_bias_snum                                      ,
         ofm_rstart                                         ,
         ofm_wbase                                          ,
         ofm_rbase                                          ,
         ofm_pp                                             ,
         ofm_bias_sel                                       ,
         ofm_tmp_sel                                        ,
         ofm_output_sel
}),//--------------------------------------------------------
        .clk  ( clk  ),
        .reset( reset)
);


//--------------------------------------------------------------
//1:no
//2,3:shift
//4:reg
//--------------------------------------------------------------
  assign ofm_raddr_vld=concat_vld&r_ofm_tmp_sel             ;
 
  always @(posedge clk)
  for(i=0;i<PNUM;i=i+1)
  begin
    if(r_ofm_rstart)
    ofm_raddr[i*15+:15]<=r_ofm_rbase                        ;
    else if (ofm_raddr_vld) 
    ofm_raddr[i*15+:15]<=ofm_raddr[i*15+:15]+PNUM           ;
  end

  

//--------------------------------------------------------------
//Shifter, for decimal points.
//--------------------------------------------------------------
wire                            shift_vld                   ;
wire [CNUM*DW_ADD-1:0]          shift_data                  ;
wire [CNUM*DW_ADD-1:0]          shift_bias                  ;

(*keep_hierarchy="yes"*)ofm_shift #(
  .NUM                  (NUM                                ),
  .PNUM                 (PNUM                               ),
  .DW_OFM               (DW_OFM                             ),
  .DW_BIAS              (DW_BIAS                            ),
  .DW_ADD               (DW_ADD                             )   
)u_ofm_shift(
  .clk                  (clk                                ),
  .reset                (reset                              ),
  .ofm_din_snum         (r_ofm_din_snum                     ),
  .ofm_bias_snum        (r_ofm_bias_snum                    ),
  .ofm_vld_in           (concat_vld                         ),
  .ofm_data_in          (concat_data                        ),
  .ofm_bias_in          (ofm_bias_data                      ),
  .ofm_vld_out          (shift_vld                          ),
  .ofm_data_out         (shift_data                         ),
  .ofm_bias_out         (shift_bias                         )
);

//-----------------------------------------------------------------
//The accumulation of several rounds of results.
//-----------------------------------------------------------------
wire [CNUM*DW_ADD-1:0]  adder_result                        ;
wire                    adder_result_vld                    ;

(*keep_hierarchy="yes"*)ofm_adder#(
  .NUM                  (CNUM                               ),
  .DW_ADD               (DW_ADD                             ),
  .DW_RAM               (DW_RAM                             ),
  .DLY_INST_ADD         (3                                  )   
)u_ofm_adder(
  .clk                  (clk                                ),
  .reset                (reset                              ),
  .ofm_bias_sel         (r_ofm_bias_sel                     ),
  .ofm_tmp_sel          (r_ofm_tmp_sel                      ),
  .ofm_ina_vld          (shift_vld                          ),
  .ofm_ina              (shift_data                         ),
  .bias_inb_vld         (shift_vld                          ),
  .bias_inb             (shift_bias                         ),
  .temp_inb_vld         (ram_rdata_vld                      ),
  .temp_inb             (ram_rdata_tmp                      ),
  .adder_result         (adder_result                       ),
  .adder_result_vld     (adder_result_vld                   )     
);

//-----------------------------------------------------------------
//Cut off the data bit width.
//-----------------------------------------------------------------

wire [CNUM*DW_RAM-1:0]  ofm_wdata                           ;
wire [PNUM-1:0]         ofm_wdata_vld                       ;
wire [PNUM*15-1:0]      ofm_waddr                           ;


(*keep_hierarchy="yes"*)ofm_psum_cut#(
  .NUM                  (CNUM                               ),
  .PNUM                 (PNUM                               ),
  .DW_ADD               (DW_ADD                             ), 
  .DW_RAM               (DW_RAM                             ),
  .DW_NVM               (DW_NVM                             ),
  .DLY_INST_CUT         (9                                  )
)u_ofm_psum_cut(
  .clk                  (clk                                ),
  .reset                (reset                              ),
  .ofm_output_sel       (r_ofm_output_sel                   ),
  .ofm_rstart           (r_ofm_rstart                       ),
  .ofm_wbase            (r_ofm_wbase                        ),
  .data_in_vld          (adder_result_vld                   ),
  .data_in              (adder_result                       ),
  .ofm_wdata            (ofm_wdata                          ),
  .ofm_waddr            (ofm_waddr                          ),
  .ofm_wdata_vld        (ofm_wdata_vld                      )     
);


//-----------------------------------------------------------------
// NVM data
//-----------------------------------------------------------------
  wire    [PNUM*NUM*DW_RAM-1:0] ram_doutb                   ; 
  wire    [PNUM-1:0]            ram_doutb_tmp_vld           ; 
  wire    [PNUM-1:0]            ram_doutb_nvm_vld           ; 
  wire    [PNUM-1:0]            NVM_R_EN                    ;
  wire    [PNUM*15-1:0]         NVM_R_ADDR                  ;
  wire    [PNUM-1:0]            NVM_W_WEN                   ;
  wire    [PNUM*15-1:0]         NVM_W_ADDR                  ;                      
  wire    [NUM*DW_RAM-1:0]      NVM_W_DATA                  ;  

(*keep_hierarchy="yes"*)ofm_nvm_data #(
  .NUM                  (NUM                                ),
  .PNUM                 (PNUM                               ),
  .DW_NVM               (DW_NVM                             ),
  .DW_RAM               (DW_RAM                             ),
  .RAM_DATA             (NUM*DW_RAM                         ),
  .DLY_RAM_R            (6                                  )    
)u_ofm_nvm_data(
  .clk                  (clk                                ),
  .reset                (reset                              ),
  .nvm_raddr            (nvm_raddr                          ),
  .nvm_raddr_vld        (nvm_raddr_vld                      ),
  .nvm_raddr_done       (nvm_raddr_done                     ),
  .nvm_rdata            (nvm_rdata                          ),
  .nvm_rdata_vld        (nvm_rdata_vld                      ),
  .nvm_rdata_done       (nvm_rdata_done                     ),
  .back_raddr           (back_raddr                         ),
  .back_raddr_vld       (back_raddr_vld                     ),
  .back_rdata           (back_rdata                         ),
  .back_rdata_vld       (back_rdata_vld                     ),
  .NVM_R_EN             (NVM_R_EN                           ),
  .NVM_R_ADDR           (NVM_R_ADDR                         ),

`ifndef SIM_CODE
  .NVM_R_DATA           (ram_doutb                          ),
`else
  .NVM_R_DATA           (~ram_doutb_tmp_vld[0]?ram_doutb:0  ),
`endif
  .NVM_R_VLD            (ram_doutb_nvm_vld                  ),
  //   
  .NVM_W_WEN            (NVM_W_WEN                          ),
  .NVM_W_ADDR           (NVM_W_ADDR                         ),                      
  .NVM_W_DATA           (NVM_W_DATA                         ),
  .back_waddr           (back_waddr                         ),                      
  .back_wdata           (back_wdata                         ),
  .back_wvld            (back_wvld                          ),
  .back_wdone           (back_wdone                         ),
  
  .nvm_res_en           (nvm_res_en                         ),
  .res_load_data        (res_load_data                      ),
  .res_load_vld         (res_load_vld                       ),
  .res_load_done        (res_load_done                      ),
  .nvm_res_rdata        (nvm_res_rdata                      ),
  .nvm_res_rdata_vld    (nvm_res_rdata_vld                  )
);


//--------------------------------------------------------------------
// psum buffer 2cycle
//--------------------------------------------------------------------



`ifndef SIM_CODE
assign ram_rdata_tmp = ram_doutb                            ;
`else
assign ram_rdata_tmp =~ram_rdata_vld?0:ram_doutb            ;
`endif
assign ram_rdata_vld = ram_doutb_tmp_vld[0]                 ;

(*keep_hierarchy="yes"*)ofm_buffer #(
  .NUM                  (NUM                                ),
  .PNUM                 (PNUM                               ),
  .DW_RAM               (DW_RAM                             ),
  .DW_NVM               (DW_NVM                             ),
  .RAM_CYCLE            (2                                  ),
  .RAM_ADDR             (15                                 ),
  .RAM_DATA             (1024                               )
)u_ofm_buffer(
  .clk                  (clk                                ),
  .reset                (reset                              ),
  .ofm_wvld             (ofm_wdata_vld                      ),
  .ofm_waddr            (ofm_waddr                          ),
  .ofm_wdata            (ofm_wdata                          ),
  .ofm_raddr            (ofm_raddr                          ),
  .ofm_raddr_vld        ({PNUM{ofm_raddr_vld}}              ),
  .NVM_R_EN             (NVM_R_EN                           ),
  .NVM_R_ADDR           (NVM_R_ADDR                         ),   
  .NVM_W_WEN            (NVM_W_WEN                          ),
  .NVM_W_ADDR           (NVM_W_ADDR                         ),                      
  .NVM_W_DATA           ({PNUM{NVM_W_DATA}}                 ),
  .ram_doutb            (ram_doutb                          ), 
  .ram_rvld_ofm         (ram_doutb_tmp_vld                  ), 
  .ram_rvld_nvm         (ram_doutb_nvm_vld                  ) 
);

//--------------------------------------------------------------------
// 
//--------------------------------------------------------------------
  reg   [15-1:0]         ofm_wbase_final        =0          ;
  wire                   ofm_rstart_final                   ;
  
  always @(posedge clk)
  if(ofm_rdone_final)
  ofm_wbase_final   <=   0                                  ;
  else if(~r_ofm_output_sel&&r_ofm_rstart)  
  ofm_wbase_final   <=   r_ofm_wbase                        ;
  
  assign ofm_rstart_final=(ofm_wbase_final==r_ofm_wbase)
         &r_ofm_rstart&r_ofm_output_sel                     ;


  reg [OFM_DLY_DONE*2-1:0]dly_done_reg  =0                  ;
  
  always @(posedge clk)
  for(i=0;i<OFM_DLY_DONE;i=i+1)
  if(i==0)dly_done_reg[i*2+:2]<={ofm_rstart_final,r_ofm_rstart};
  else    dly_done_reg[i*2+:2]<=dly_done_reg[(i-1)*2+:2]    ;
  
 
  assign ofm_rdone_final=dly_done_reg[(OFM_DLY_DONE-1)*2+1+:1];
  assign ofm_rdone      =dly_done_reg[(OFM_DLY_DONE-1)*2+0+:1];


  `ifdef SIM_CODE
    reg [37-1:0]        test_ofm_din     [128-1:0]          ;
    reg [37-1:0]        test_align_data  [128-1:0]          ;
    reg [37-1:0]        test_merge_data  [128-1:0]          ;
    reg [37-1:0]        test_collect_data[128-1:0]          ;
    reg [37-1:0]        test_concat_data [128-1:0]          ;
  
   always @(*)
   for(i=0;i<128;i=i+1)
   begin
       test_ofm_din     [i] <= ofm_din     [i]              ;
       test_align_data  [i] <= align_data  [i*37+:37]       ;
       test_merge_data  [i] <= merge_data  [i*37+:37]       ;
       test_collect_data[i] <= collect_data[i*37+:37]       ;
       test_concat_data [i] <= concat_data [i*37+:37]       ;
   end

  `endif









endmodule
