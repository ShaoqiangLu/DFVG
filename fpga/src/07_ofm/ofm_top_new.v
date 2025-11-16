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

module ofm_top_new #(
  // NUM indicates the number of the input data for each cycle
  // Currently only supports 32, 64
  parameter                     NUM   =   32                    ,
  parameter                     PSUM_NUM  =2                    ,
  // IDW indicates the data width of each input data
  parameter                     IDW   =   42                    ,
  // ADW indicates the data width of each intermediate data
  parameter                     ADW   =   32                    ,
  // ODW indicates the data width of each output data
  parameter                     ODW   =   16                    ,
  localparam                    AIDW  =   PSUM_NUM*NUM*IDW      ,
  localparam                    AADW  =   PSUM_NUM*NUM*ADW      ,
  localparam                    AODW  =   PSUM_NUM*NUM*ODW               
  ) (
  input                         clk                             ,
  input                         reset                           ,
  input         [     2 : 0]    ofm_din_enc                     ,
  input         [     6 : 0]    ofm_concat_num                  ,  
  input         [     4 : 0]    ofm_snum                        ,
  input         [     9 : 0]    bias_snum                       ,
  input                         ofm_start                       ,     
  input         [    10 : 0]    ofm_wbase                       ,
  input         [    10 : 0]    ofm_rbase                       ,
  input         [    15 : 0]    ofm_pp                          ,
  input                         bias_sel                        ,
  input                         ofm_tmp_sel                     ,
  input                         ofm_output_sel                  ,
  output reg                    ofm_done           =0           ,  
  input         [AADW-1 : 0]    bias_data                       ,
  input                         bias_rvld                       ,
  input         [AIDW-1 : 0]    ofm_din                         ,
  input                         ofm_din_vld                     ,
  input                         ofm_din_done                    ,
  
  input         [    10 : 0]    nvm_raddr                       ,
  input                         nvm_raddr_vld                   ,
  input                         nvm_raddr_done                  ,
  output reg    [AODW-1 : 0]    nvm_rdata          =0           ,
  output                        nvm_rdata_vld                   ,
  output                        nvm_rdata_done                  ,
  input  wire   [   10 : 0]     back_waddr                      ,                      
  input  wire   [AODW-1: 0]     back_wdata                      ,
  input  wire                   back_wvld                       ,
  input  wire                   back_wdone                      ,
  output wire                   back_rstart                     ,
  input         [    10 : 0]    back_raddr                      ,
  input                         back_raddr_vld                  ,
  output reg    [AODW-1 : 0]    back_rdata         =0           ,
  output                        back_rdata_vld                               
  );
   
  wire [32*42-1:0] ofm_din_dly    ;
  wire             ofm_din_vld_dly;
  
  reg  [42-1:0]    ofm_din_dly_r[32-1:0]  ;
  reg              ofm_din_vld_dly_r    =0;
  
  
  generate for(genvar i=0;i<NUM;i=i+1 )//11,pe_o Q42_26---->ofm_shift Q42_37
  begin:test
  
    always @(posedge clk)
    if(reset)begin
        ofm_din_dly_r[i]    <=0;
    end else begin
        ofm_din_dly_r[i]    <=ofm_din_dly[i*42+:42];
    end

  end
  endgenerate
  
    always @(posedge clk)
    if(reset)begin
        ofm_din_vld_dly_r   <=0;
    end else begin
        ofm_din_vld_dly_r  <=ofm_din_vld_dly;
    end



  (*keep_hierarchy="yes"*)dly_cell#(
    .DLY                        ( 53                           ),
    .DW                         ( 42*32+1                      )
  ) dly_stest(                    
    .dout                       ( {ofm_din_dly,ofm_din_vld_dly}),
    .din                        ( {ofm_din,    ofm_din_vld    }),
    .clk                        ( clk                          ),
    .reset                      ( reset                        )
  );

  localparam        UB        = {1'b0, {(IDW-1){1'b1}}}         ;
  localparam        LB        = {1'b1, {(IDW-1){1'b0}}}         ;
  localparam        ADD_DW    =   NUM * (IDW+1)                 ;
  localparam        OFM_RAM_CYCLE     =  2                      ; 


  reg [AIDW-1:0]       ofm_din_shift        =0;
  (*max_fanout=32*)reg ofm_din_shift_vld    =0;
  reg                  ofm_din_shift_done   =0;
  (*max_fanout=32*)reg[2:0] ofm_din_enc_r1  =0;
  (*max_fanout=32*)reg[2:0] ofm_din_enc_r2_r=0;
  (*max_fanout=32*)reg[2:0] ofm_din_enc_r2  =0;  
  (*max_fanout=32*)reg[6:0] ofm_din_num     =0;
  (*max_fanout=32*)reg[6:0] ofm_concat_num_r=0;
  reg  [     6 : 0]  concat_cnt         = 0;
  reg  [AIDW-1 : 0]  concat_data        = 0;
  reg                concat_vld         = 0;
  reg                concat_done        = 0; 
  reg[9:0]           bias_snum_1=0         ;
  (*max_fanout=32*)  reg bias_vld1      = 0;
  (*max_fanout=32*)  reg bias_vld2      = 0;
  reg[AADW-1:0]      bias_data_1=0         ;
  reg  [AIDW-1 : 0]  bias_shift         = 0;
  (*max_fanout=32*)  reg bias_shift_vld = 0;
  (*max_fanout=32*)  reg bias_flay_r= 0    ;
  (*max_fanout=32*)  reg bias_flay= 0      ;  
  reg  [AIDW-1 : 0]  r1_bias_hold=0        ;
  reg                r1_bias_hold_vld=0    ;
  reg                r1_bias_hold_done=0   ;
  reg  [AIDW-1 : 0]  r2_bias_hold=0        ;
  reg                r2_bias_hold_vld=0    ;
  reg                r2_bias_hold_done=0   ;
  reg  [AIDW-1 : 0]  r3_bias_hold=0        ;
  reg                r3_bias_hold_vld=0    ;
  reg                r3_bias_hold_done=0   ;
  reg  [AIDW-1 : 0]  bias_hold=0           ;
  reg                bias_hold_vld=0       ;
  reg                bias_hold_done=0      ;
  reg  [AIDW-1 : 0]  r1_adder_ina       = 0;
  reg                r1_adder_ina_vld   = 0;
  reg                r1_adder_ina_done  = 0;
  reg  [AIDW-1 : 0]  r2_adder_ina       = 0;
  reg                r2_adder_ina_vld   = 0;
  reg                r2_adder_ina_done  = 0;
  reg  [AIDW-1 : 0]  r3_adder_ina       = 0;
  reg                r3_adder_ina_vld   = 0;
  reg                r3_adder_ina_done  = 0;
  reg  [AIDW-1 : 0]  r4_adder_ina       = 0;
  reg                r4_adder_ina_vld   = 0;
  reg                r4_adder_ina_done  = 0;
  reg  [AIDW-1 : 0]  adder_ina=0           ;
  reg                adder_ina_vld=0       ;
  reg                adder_ina_done     = 0;
  reg                ofm_tmp_sel_r =0      ;
  reg                bias_sel_r =0         ;
  (*max_fanout=32*) reg addr_inb_sel_1  = 0;
  (*max_fanout=32*) reg addr_inb_sel_2  = 0;
  (*max_fanout=32*) reg addr_inb_sel_3  = 0;
  (*max_fanout=32*) reg addr_inb_sel_4  = 0;
  (*max_fanout=32*) reg addr_inb_sel_5  = 0;
  (*max_fanout=32*) reg addr_inb_sel_6  = 0;
  (*max_fanout=32*) reg [32:0]addr_inb_sel_7  = 0;
  reg  [AIDW-1 : 0]  adder_inb    =0       ;
  reg                adder_inb_vld =0      ;
  reg                adder_out_vld_r    = 0;
  reg                adder_out_done_r   = 0;
  wire [ADD_DW-1:0]  adder_out             ;
  reg                adder_out_vld      = 0;
  reg                adder_out_done     = 0;
  reg                cut_data_vld_r     = 0;
  reg                cut_data_done_r    = 0;
  reg  [AADW-1 : 0]  cut_data           = 0;
  reg                cut_data_vld       = 0;
  reg                cut_data_done      = 0;
  reg                ofm_output_sel_1   = 0;
  reg                ofm_output_sel_2   = 0;
  reg                ofm_output_sel_3   = 0;
  reg                ofm_output_sel_4   = 0;
  reg                ofm_output_sel_5   = 0;
  reg                ofm_output_sel_6   = 0;
  reg                ofm_output_sel_7   = 0;
  reg                ofm_output_sel_8   = 0;
  reg                ofm_output_sel_9   = 0;
  reg                ofm_output_sel_10  = 0;
  reg                ofm_output_sel_11  = 0;
  reg  [31:0]        ofm_output_sel_12  = 0;
  reg  [AADW-1 : 0]  round_data         = 0;
  reg                round_data_vld     = 0;
  reg                round_data_done    = 0;
  wire [    10 : 0]  ofm_wbase_wo          ;
  wire               ofm_start_wo          ;
  reg  [    10 : 0]  ofm_pp_wo          = 0;
  reg                ofm_wen            = 0;
  reg  [    10 : 0]  ofm_waddr          = 0;
  wire               ofm_wdone             ;
  wire               ofm_ram0_web          ;
  wire [    10 : 0]  ofm_ram0_addrb        ;
  reg  [  1023 : 0]  ofm_ram0_dinb      = 0;
  reg                ofm_tmp_sel1       = 0;
  reg                ofm_tmp_sel2       = 0;
  reg                ofm_tmp_sel3       = 0;
  reg                ofm_rstart1        = 0;
  reg                ofm_rstart2        = 0;
  reg                ofm_rstart3        = 0;
  reg  [    10 : 0]  ofm_rbase1         = 0;
  reg  [    10 : 0]  ofm_rbase2         = 0;
  reg  [    10 : 0]  ofm_rbase3         = 0;
  (*max_fanout=32*)reg ofm_reading      = 0;
  (*max_fanout=32*)reg ofm_reading1     = 0;
  (*max_fanout=32*)reg ofm_reading2     = 0;
  (*max_fanout=32*)reg ofm_reading3     = 0;
  (*max_fanout=32*)reg [32:0]ofm_reading4= 0;
  reg  [    10 : 0]  ofm_raddr          = 0;
  reg  [    10 : 0]  ofm_ram0_addra     = 0;
  wire [  1023 : 0]  ofm_ram0_douta        ;
  reg  [ AIDW-1: 0]  ram_rdata_tmp      = 0;
  wire               ram_rdata_tmp_vld     ;
  wire               ram_rdata_tmp_done    ;
  reg [10:0]         back_waddr_r       = 0;
  reg                back_wvld_r        = 0;
  reg [10:0]         r_ofm_sync_waddr   = 0;
  reg                r_ofm_sync_wvld    = 0;
  
  // ---------------------------------------------------------------------------
  // shift the input data to have same dot position according to ofm_snum 
  // considering saturation
  // todo: no need to all shift_num cases, may change quantization
  // ---------------------------------------------------------------------------
  generate 
  for(genvar i=0;i<NUM;i=i+1 )//11,pe_o Q42_26---->ofm_shift Q42_37
  begin:ishift
        reg [4:0]    ofm_snum_r=0          ;
        reg [IDW-1:0]ofm_din_shift_r=0     ;
        reg [IDW-1:0]ofm_din_r=0           ;
        always @(posedge clk)
        begin
            if(ofm_start)ofm_snum_r<=ofm_snum;
            ofm_din_shift_r<=$signed(ofm_din[i*IDW+:IDW])<<ofm_snum_r;
            ofm_din_r      <=        ofm_din[i*IDW+:IDW]             ; 
        end
        
        always @(posedge clk)
        if(ofm_din_shift_r[IDW-1] == ofm_din_r[IDW-1])
             ofm_din_shift[i*IDW+:IDW]     <=  ofm_din_shift_r   ;
        else if(ofm_din_r[IDW-1])
             ofm_din_shift[i*IDW+:IDW]     <=  LB                ;
        else ofm_din_shift[i*IDW+:IDW]     <=  UB                ;
  end
  
  //-------------------------------------------------------------
  reg                  ofm_din_shift_vld_r  =0;
  reg                  ofm_din_shift_done_r =0;
  always @(posedge clk)
  begin
    ofm_din_shift_vld_r                 <= ofm_din_vld          ;
    ofm_din_shift_done_r                <= ofm_din_done         ;
    ofm_din_shift_vld                   <= ofm_din_shift_vld_r  ;
    ofm_din_shift_done                  <= ofm_din_shift_done_r ;
  end  
  
  endgenerate



  // ---------------------------------------------------------------------------
  // concatenate valid inputs into channel_num_s channels
  // currently, data_in_num supports: 2, 4, 8, 16, 32, .NUM;
  // while channel_num_s supports: even numbers from 2 to NUM
  // ---------------------------------------------------------------------------
  always @(posedge clk) 
  begin
  if(ofm_start)ofm_din_enc_r1<=ofm_din_enc;
    case(ofm_din_enc_r1)
    3'h0    : ofm_din_num     =    2                            ;
    3'h1    : ofm_din_num     =    4                            ;
    3'h2    : ofm_din_num     =    8                            ;
    3'h3    : ofm_din_num     =   32;//                            ;//16
    3'h4    : ofm_din_num     =   32                            ;
    default : ofm_din_num     =   64                            ;
    endcase
  end
  //first in data at MSB,most significant bit, the high bit is [n-1]
  //In order to gather 32 42bit data

  always @(posedge clk) if(ofm_start)ofm_din_enc_r2_r<=ofm_din_enc;
  always @(posedge clk) ofm_din_enc_r2  <=ofm_din_enc_r2_r      ;
  always @(posedge clk) 
  if(ofm_din_shift_vld)
  begin
     case (ofm_din_enc_r2)//3---[1344-42*16=672-1:0],[672-1:0]
        3'h0 : concat_data<={concat_data[AIDW-IDW* 2-1:0],ofm_din_shift[IDW* 2-1:0]};
        3'h1 : concat_data<={concat_data[AIDW-IDW* 4-1:0],ofm_din_shift[IDW* 4-1:0]};
        3'h2 : concat_data<={concat_data[AIDW-IDW* 8-1:0],ofm_din_shift[IDW* 8-1:0]}; 
        3'h3 : concat_data<={concat_data[AIDW-IDW*16-1:0],ofm_din_shift[IDW*16-1:0]};
        3'h4 : if(NUM==32) concat_data  <= ofm_din_shift        ;
               else concat_data<={concat_data[AIDW-IDW*32-1:0],ofm_din_shift[IDW*32-1:0]}; 
        default :   concat_data  <=  ofm_din_shift              ;
     endcase
  end   else        concat_data   <=    0                       ;


  reg ofm_start_1=0;
  reg ofm_start_2=0;
  
  
  always @(posedge clk)
  begin
     ofm_start_1 <=ofm_start;
     ofm_start_2 <=ofm_start_1;
  end
   
  always @(posedge clk)
  if(ofm_start_2)
  begin
      concat_cnt      <=     0                                  ;
      concat_vld      <=     0                                  ;
      concat_done     <=     0                                  ;
      ofm_concat_num_r<=ofm_concat_num                          ;
  end
  else 
  if(ofm_din_shift_vld)
  begin
       if(concat_cnt+ofm_din_num==ofm_concat_num_r)
       begin
            concat_cnt<=     0                                  ;
            concat_vld<=     1                                  ;
            if(ofm_din_shift_done) concat_done<=    1           ;
            else                   concat_done<=    0           ;
       end
       else 
       begin
            concat_cnt<= concat_cnt + ofm_din_num               ;//0,16,  0,16,  0,16,
            concat_vld<=     0                                  ;
            concat_done<=    0                                  ;    
       end
  end
  else
  begin
      concat_cnt      <=     0                                  ;
      concat_vld      <=     0                                  ;
      concat_done     <=     0                                  ;
  end



  
  // ---------------------------------------------------------------------------
  // shift bias to have same dot position according to bias_snum
  // considering saturation
  // todo: no need to include all shift num cases, change in quantization
  // ---------------------------------------------------------------------------

  
  always @(posedge clk)if(ofm_start)bias_snum_1<=bias_snum      ;
  always @(posedge clk)bias_data_1<=bias_data                   ;
  generate for(genvar i=0; i<NUM; i=i+1) 
  begin:b_f//8,bias_data Q32_31---->bias_shift Q42_39,why no is 37 ?
        reg [9:0] bias_snum_r  =0          ;
        reg [IDW-1:0] bias_sft_r   =0      ;
        reg [IDW-1:0] bias_data_r  =0      ;
        always @(posedge clk)bias_snum_r<=bias_snum_1           ;
        always @(posedge clk)begin
          bias_sft_r <=$signed({{(IDW-ADW){bias_data_1[i*ADW+ADW-1]}}, 
                       bias_data_1[i*ADW+:ADW]})<<bias_snum_r     ;
          bias_data_r<=$signed({{(IDW-ADW){bias_data_1[i*ADW+ADW-1]}}, 
                       bias_data_1[i*ADW+:ADW]})                  ;
        end
        
        always @(posedge clk)
        if(bias_sft_r[IDW-1]==bias_data_r[IDW-1])
              bias_shift[i*IDW+:IDW]        <=  bias_sft_r      ;
        else if (bias_sft_r[IDW-1])
              bias_shift[i*IDW+:IDW]        <=  LB              ;
        else
              bias_shift[i*IDW+:IDW]        <=  UB              ;    
  end
  endgenerate



  always @(posedge clk) 
  if(bias_sel)
  bias_flay_r <= (~ofm_din_shift_vld) && ofm_din_shift_vld_r    ;
  else bias_flay_r <= 0;
 
  always @(posedge clk) 
  begin
    bias_vld1     <= bias_rvld;
    bias_vld2     <= bias_vld1;
    bias_shift_vld<=bias_vld2;
    bias_flay     <=bias_flay_r;
    r1_bias_hold_done<=concat_done&r1_bias_hold_vld;
  end

  always @(posedge clk) r1_bias_hold     <=  bias_shift           ;

  always @(posedge clk)
  if(bias_flay)r1_bias_hold_vld <=  bias_shift_vld               ;
  else  if(r1_bias_hold_done)r1_bias_hold_vld <=  0              ;
 

  // ---------------------------------------------------------------------------
  // Output accumulator
  // adder_ina: comes from concat_data
  // adder_inb: comes from bias_shift or temp results (ofm_ram)
  // Q42_37 + Q42_39 ==Q43_????
  // ---------------------------------------------------------------------------
  //dealy=3,bias is 2cycle,bias--1st--> bias_trig-->bias_shift
  //tmp_data is raddr(concat_vld)--2clk-->ram_dout--1clk-->tmp
  always @(posedge clk) begin
    r1_adder_ina        <=  concat_data                          ;
    r1_adder_ina_vld    <=  concat_vld                           ;
    r1_adder_ina_done   <=  concat_done                          ;
    
    r2_adder_ina        <=  r1_adder_ina                         ; 
    r2_adder_ina_vld    <=  r1_adder_ina_vld                     ;
    r2_adder_ina_done   <=  r1_adder_ina_done                    ;

    r3_adder_ina        <=  r2_adder_ina                         ; 
    r3_adder_ina_vld    <=  r2_adder_ina_vld                     ;
    r3_adder_ina_done   <=  r2_adder_ina_done                    ;

    r4_adder_ina        <=  r3_adder_ina                         ;
    r4_adder_ina_vld    <=  r3_adder_ina_vld                     ;
    r4_adder_ina_done   <=  r3_adder_ina_done                    ;

    adder_ina           <=  r4_adder_ina                         ;
    adder_ina_vld       <=  r4_adder_ina_vld                     ;
    adder_ina_done      <=  r4_adder_ina_done                    ;


    r2_bias_hold        <=  r1_bias_hold                         ; 
    r2_bias_hold_vld    <=  r1_bias_hold_vld                     ; 
    r2_bias_hold_done   <=  r1_bias_hold_done                    ; 

    r3_bias_hold        <=  r2_bias_hold                         ; 
    r3_bias_hold_vld    <=  r2_bias_hold_vld                     ; 
    r3_bias_hold_done   <=  r2_bias_hold_done                    ; 


    bias_hold           <=  r3_bias_hold                         ; 
    bias_hold_vld       <=  r3_bias_hold_vld                     ; 
    bias_hold_done      <=  r3_bias_hold_done                    ; 
    
  end
  

  always @(posedge clk)if(ofm_start)ofm_tmp_sel_r<=ofm_tmp_sel   ;
  always @(posedge clk)if(ofm_start)bias_sel_r   <=bias_sel      ;
  
  
  always @(posedge clk)
  begin
  addr_inb_sel_1<=(~ofm_tmp_sel_r)&&bias_sel_r;
  addr_inb_sel_2<=addr_inb_sel_1;
  addr_inb_sel_3<=addr_inb_sel_2;
  addr_inb_sel_4<=addr_inb_sel_3;
  addr_inb_sel_5<=addr_inb_sel_4;
  addr_inb_sel_6<=addr_inb_sel_5;
  addr_inb_sel_7<={33{addr_inb_sel_6}};
  
  ofm_reading1  <=ofm_reading;
  ofm_reading2  <=ofm_reading1;
  ofm_reading3  <=ofm_reading2;
  ofm_reading4  <={33{ofm_reading3}};
  end
  
  
  
  always @(posedge clk) 
  if(addr_inb_sel_7[32])   adder_inb_vld <=bias_hold_vld                         ;
  else if(ofm_reading4[32])adder_inb_vld <=ram_rdata_tmp_vld                     ;
  else                     adder_inb_vld <=r4_adder_ina_vld                      ;
  generate for (genvar i=0;i<NUM;i=i+1) begin:inb   

  always @(posedge clk) 
  if(addr_inb_sel_7[i])    adder_inb[i*42+:42] <=bias_hold[i*42+:42]             ;
  else if(ofm_reading4[i]) adder_inb[i*42+:42] <=ram_rdata_tmp[i*42+:42]         ;
  else                     adder_inb[i*42+:42] <=0                               ;
        
  end
  endgenerate

  generate for (genvar i=0;i<NUM;i=i+1) begin:add   
  (*keep_hierarchy="yes"*)ADD_ofm ADD (
    .CLK    (clk                            ), // input  wire CLK
    .A      (adder_ina[IDW*i+:IDW]          ), // input  wire [41 : 0] A
    .B      (adder_inb[IDW*i+:IDW]          ), // input  wire [41 : 0] B
    .S      (adder_out[(IDW+1)*i+:(IDW+1)]  )  // output wire [42 : 0] S
  );         
  end
  endgenerate

  always @(posedge clk)begin
        adder_out_vld_r <= adder_ina_vld&&adder_inb_vld         ;
        adder_out_done_r<= adder_ina_done                       ;
        adder_out_vld   <= adder_out_vld_r                      ;
        adder_out_done  <= adder_out_done_r                     ;
  end
  

  // ---------------------------------------------------------------------------
  // cut data: 43-----33----->32
  // every time after adder, data will be cut: IDW+1 -> ADW 
  // consider saturation, use floor
  // ---------------------------------------------------------------------------
  generate for ( genvar i=0; i<NUM; i=i+1 ) begin
        reg [(ADW+1)-1:0] cut_data_r=0     ;//32+1
        reg [(IDW+1)-1:0] adder_out_r=0    ;//34+1
        always @(posedge clk) begin
        cut_data_r<=$signed(adder_out[i*(IDW+1)+:(IDW+1)])>>((IDW+1)-(ADW+1));//42-32=10?
        adder_out_r<=adder_out[i*(IDW+1)+:(IDW+1)]              ;
        end
    always @(posedge clk) begin
    if ((adder_out_r[(IDW+1)-1]  == cut_data_r[(ADW+1)-1])
        &(adder_out_r[(IDW+1)-1] == cut_data_r[(ADW+1)-2]))
        cut_data[i*ADW+:ADW] <= cut_data_r[0+:ADW]              ;
    else if(adder_out_r[(IDW+1)-1])
        cut_data[i*ADW+:ADW] <= {1'b1, {(ADW-1){1'b0}}}         ;
    else
        cut_data[i*ADW+:ADW] <= {1'b0, {(ADW-1){1'b1}}}         ;
    end
  end
  endgenerate
  
  always @(posedge clk)
  begin
      cut_data_vld_r            <= adder_out_vld                ;
      cut_data_done_r           <= adder_out_done               ;
      cut_data_vld              <= cut_data_vld_r               ;
      cut_data_done             <= cut_data_done_r              ;
  end

  always @(posedge clk)
  begin
       if(ofm_start)ofm_output_sel_1   <= ofm_output_sel   ;
       ofm_output_sel_2   <= ofm_output_sel_1 ;
       ofm_output_sel_3   <= ofm_output_sel_2 ;
       ofm_output_sel_4   <= ofm_output_sel_3 ;
       ofm_output_sel_5   <= ofm_output_sel_4 ;
       ofm_output_sel_6   <= ofm_output_sel_5 ;
       ofm_output_sel_7   <= ofm_output_sel_6 ;
       ofm_output_sel_8   <= ofm_output_sel_7 ;
       ofm_output_sel_9   <= ofm_output_sel_8 ;
       ofm_output_sel_10  <= ofm_output_sel_9 ;
       ofm_output_sel_11  <= ofm_output_sel_10;
       ofm_output_sel_12  <= {32{ofm_output_sel_11}};
  end




  // ---------------------------------------------------------------------------
  // round data signals
  // for ofm_output_sel = 1, data is cut ADW -> ODW
  // we use the most significant bits, and need round
  // ---------------------------------------------------------------------------
  generate for (genvar i=0; i<NUM; i=i+1)
  begin
    always @(posedge clk)
    if(ofm_output_sel_12[i]& 
        (cut_data[i*ADW+ODW+:ODW]=={1'b0,{(ODW-1){1'b1}}}||cut_data[i*ADW+ODW-1]==0 ))
        round_data[i*ADW+:ADW]<={cut_data[i*ADW+ODW+:ODW]+0,{ODW{1'b0}}};
    else if(ofm_output_sel_12[i] )
        round_data[i*ADW+:ADW]<={cut_data[i*ADW+ODW+:ODW]+1,{ODW{1'b1}}};
    else
        round_data[i*ADW+:ADW]<= cut_data[i*ADW+:ADW]           ;
  end
  endgenerate
  always @(posedge clk)begin
    round_data_vld               <= cut_data_vld                ;
    round_data_done              <= cut_data_done               ;
  end
  // ---------------------------------------------------------------------------
  // Write RAM
  // ---------------------------------------------------------------------------
  // write data to ofm_bram on port b
  // pp = 0: octrl ram0, nvm ram1; 
  // pp = 1: octrl ram1, nvm ram0

  (*keep_hierarchy="yes"*)dly_cell #(
    .DLY                        ( 13-1                                  ),
    .DW                         ( 11+1                                  )
  ) dly_wvst (
    .dout                       ( {ofm_wbase_wo,ofm_start_wo} ),
    .din                        ( {ofm_wbase,ofm_start}),
    .clk                        ( clk                                   ),
    .reset                      ( 1'b0                                 ) 
  );

  always @(posedge clk)
  if(round_data_vld)ofm_wen           <=      1'b1          ;
  else              ofm_wen           <=      1'b0          ;
  
  always @(posedge clk)
  if (ofm_start_wo)ofm_waddr     <=      ofm_wbase_wo        ;
  else if(ofm_wen) ofm_waddr     <=      ofm_waddr + 1       ;



  
  always @(posedge clk)
  begin
        back_waddr_r <= back_waddr;
        back_wvld_r  <= back_wvld ;
  end
  
  assign  ofm_ram0_web    = back_wvld_r ? 1'b1           :ofm_wen  ;
  assign  ofm_ram0_addrb  = back_wvld_r ? back_waddr_r   :ofm_waddr;





  always @(posedge clk) ofm_pp_wo<=ofm_pp;
  
  generate for (genvar i = 0; i < NUM; i = i + 1) 
  begin
      always @(posedge clk)
      if(back_wvld)   ofm_ram0_dinb[i*32+:32]<= {back_wdata[i*16+:16],16'd0}     ;
      else            ofm_ram0_dinb[i*32+:32]<=  round_data[i*32+:32]            ;
  end
  endgenerate




  //read out is 1 cycle


  (*keep_hierarchy="yes"*)tdpram # (
    .ADDR_WIDTH                 ( 11                                ),//11
    .DATA_WIDTH                 ( 1024                              ),
    .MEM_TYPE                   ( "block"                           ),
    .RD_DLY                     ( OFM_RAM_CYCLE                     )
  ) RAM0 (
    .douta                      (                                   ),
    .wea                        ( ofm_ram0_web                      ),
    .addra                      ( ofm_ram0_addrb                    ),         
    .dina                       ( ofm_ram0_dinb                     ),
    .dinb                       ( 1024'h0                           ),    
    .ena                        ( 1'b1                              ),
    .enb                        ( 1'b1                              ),
    .web                        ( 1'b0                             ),
    .addrb                      ( ofm_ram0_addra                    ),
    .doutb                      ( ofm_ram0_douta                    ),
    .clk                        ( clk                               ),
    .reset                      ( 1'b0                        )
  );




  // ---------------------------------------------------------------------------
  // read data on port a
  // ---------------------------------------------------------------------------
  always @(posedge clk)
  if ( reset )                        ofm_reading   <=  1'b0        ;
  else if (concat_done)               ofm_reading   <=  1'b0        ;
  else if (ofm_rstart3&&ofm_tmp_sel3) ofm_reading   <=  1'b1        ;
  
  always @(posedge clk)
  begin
     if(ofm_tmp_sel)
     ofm_rstart1  <=ofm_start ;
     ofm_rstart2  <=ofm_rstart1 ;
     ofm_rstart3  <=ofm_rstart2 ;
  end

  always @(posedge clk)
  begin
     if(ofm_start&ofm_tmp_sel)
     ofm_rbase1  <=ofm_rbase ;
     ofm_rbase2  <=ofm_rbase1 ;
     ofm_rbase3  <=ofm_rbase2 ;
  end

  always @(posedge clk)
  begin
     if(ofm_start)
     ofm_tmp_sel1  <=ofm_tmp_sel  ;
     ofm_tmp_sel2  <=ofm_tmp_sel1 ;
     ofm_tmp_sel3  <=ofm_tmp_sel2 ;
  end
  
  

  always @(posedge clk)
  begin
        if(ofm_rstart3)                  ofm_raddr<=  ofm_rbase3 ;
        else if (ofm_reading&concat_vld) ofm_raddr<=  ofm_raddr+1;
  end
 
  

 always @(posedge clk)
 begin
     if(nvm_raddr_vld)          ofm_ram0_addra<=nvm_raddr ;
     else if(back_raddr_vld)    ofm_ram0_addra<=back_raddr;
     else                       ofm_ram0_addra<=ofm_raddr ;
 end


  //32bit,0---->42bit
  generate for(genvar i=0;i<NUM; i=i+1) 
  begin:tmpo
    always @(posedge clk)    
    ram_rdata_tmp[i*IDW+:IDW]<={ofm_ram0_douta[i*ADW+:ADW],{(IDW-ADW){1'b0}}};      
  end
  endgenerate

  
  //0:raddr,  1:ram_raddr,  2:ram_out,  3:ram_temp
  (*keep_hierarchy="yes"*)dly_cell #(
    .DLY                        ( 4                                     ),
    .DW                         ( 2                                     )
  ) dly_tmp_vd (
    .dout                       ( {ram_rdata_tmp_vld,
                                   ram_rdata_tmp_done}),
    .din                        ( {ofm_reading&&concat_vld,
                                   ofm_reading&&concat_done            }),
    .clk                        ( clk                                   ),
    .reset                      ( 1'b0                                 ) 
  );


  //[31:16]---->[15:0]
  generate for ( genvar i = 0; i < NUM; i = i + 1 ) begin
    always @(posedge clk)
    nvm_rdata[i*ODW+:ODW] <=  ofm_ram0_douta[i*2*ODW+ODW +: ODW];
  end
  endgenerate



  //[31:16]---->[15:0]
  generate for ( genvar i = 0; i < NUM; i = i + 1 ) begin
    always @(posedge clk)
    back_rdata[i*ODW+:ODW] <= ofm_ram0_douta[i*2*ODW+ODW +: ODW];
  end
  endgenerate


  // ---------------------------------------------------------------------------
  // finish signal
  // ofm_concat     --> adder_in      : 3
  // adder_in       --> adder_out     : 1
  // adder_out      --> cut_data      : 1
  // cut_data       --> round_data    : 1
  // ---------------------------------------------------------------------------
  always @(posedge clk) ofm_done      <= ofm_wdone                    ;


 assign ofm_wdone=round_data_done;
 

  //1,raddr, 2,ram_out, 3,nvm_out
  (*keep_hierarchy="yes"*)dly_cell#(
    .DLY                        ( 4                                     ),
    .DW                         ( 4                                     )
  ) dly_nrv(                    
    .dout                       ( {nvm_rdata_vld,nvm_rdata_done,back_rstart,back_rdata_vld}),
    .din                        ( {nvm_raddr_vld,nvm_raddr_done,back_wdone ,back_raddr_vld}),
    .clk                        ( clk                                   ),
    .reset                      ( 1'b0                                 )
  );










endmodule
