// -----------------------------------------------------------------------------
// Copyright      : UCLA EDA LAB
// -----------------------------------------------------------------------------
// Engineer       : Chen Wu
// Design Name    : opu series
// Module Name    : topu_core_top
// Target Devices : 325t, Alveo U200
// Tool Versions  : Vivado 2020.1, Modelsim 2019.4
// Description    : 
//    The top module for transformer-opu core
//
// Revision       :
// Version        Date        Author        Descriptin
// 1.0            2022-04-07  Chen Wu       Initial version
// 2.0            2023-09-03  Shaoqiang     Simulation 97 layers,and
//                                          implementation on FPGA of U200.
// 3.0            2024-05-20  Shaoqiang     Testing and Implementation
//                2024-7-3    Shaoqiang     code number is 28811 row
// -----------------------------------------------------------------------------

`ifndef DEBUG_UTIL
`define DEBUG_UTIL "rtl_debug_util"
`endif


localparam  DEBUG_LAYER_NUM     = 8; 
localparam  DEBUG_DIR_COM       = {DEBUG_DIR,"rtl_com/"}        ;           
localparam  DEBUG_DIR_DATA      = {DEBUG_DIR,"rtl_debug/"}      ;  
//------------------------------------------------------------------------------------
localparam  DEBUG_UTIL          = {`DEBUG_UTIL,".txt"}          ;`define EN_DEBUG_UTIL 
localparam  DEBUG_INST          = "rtl_inst_dec.txt"            ;`define EN_DEBUG_INST    
//-----------------------------------------------------------------------------------------
localparam  DEBUG_LOAD_KER      = "_debug_load_ker.txt"         ;`define EN_DEBUG_LOAD_KER           
localparam  DEBUG_LOAD_IFM      = "_debug_load_ifm.txt"         ;`define EN_DEBUG_LOAD_IFM          
localparam  DEBUG_DMA_BM        = "_debug_dma_bm.txt"           ;`define EN_DEBUG_DMA_BM            
localparam  DEBUG_DMA_KER       = "_debug_dma_ker.txt"          ;`define EN_DEBUG_DMA_KER            
localparam  DEBUG_DMA_IFM       = "_debug_dma_ifm.txt"          ;`define EN_DEBUG_DMA_IFM            
localparam  DEBUG_PE_OUT        = "_debug_pe_out.txt"           ;`define EN_DEBUG_PE_OUT             
localparam  DEBUG_OFM_ALIGN     = "_debug_ofm_align.txt"        ;`define EN_DEBUG_OFM_ALIGN          
localparam  DEBUG_OFM_MERGE     = "_debug_ofm_merge.txt"        ;`define EN_DEBUG_OFM_MERGE          
localparam  DEBUG_OFM_COLLECT   = "_debug_ofm_collect.txt"      ;`define EN_DEBUG_OFM_COLLECT        
localparam  DEBUG_OFM_CONCAT    = "_debug_ofm_concat.txt"       ;`define EN_DEBUG_OFM_CONCAT         
localparam  DEBUG_OFM_ADDER_INA = "_debug_ofm_adder_ina.txt"    ;`define EN_DEBUG_OFM_ADDER_INA      
localparam  DEBUG_OFM_ADDER_INB = "_debug_ofm_adder_inb.txt"    ;`define EN_DEBUG_OFM_ADDER_INB      
localparam  DEBUG_OFM_ADDER_OUT = "_debug_ofm_adder_out.txt"    ;`define EN_DEBUG_OFM_ADDER_OUT      
localparam  DEBUG_OFM_PSUM      = "_debug_ofm_psum.txt"         ;`define EN_DEBUG_OFM_PSUM           
localparam  DEBUG_OFM_PSUM_CUT  = "_debug_ofm_psum_cut.txt"     ;`define EN_DEBUG_OFM_PSUM_CUT       
localparam  DEBUG_NVM_RDATA     = "_debug_nvm_rdata.txt"        ;`define EN_DEBUG_NVM_RDATA          
localparam  DEBUG_NVM_BACK_WDATA= "_debug_nvm_back_wdata.txt"   ;`define EN_DEBUG_NVM_BACK_WDATA   
localparam  DEBUG_DDR_STORE     = "_debug_ddr_store.txt"        ;`define EN_DEBUG_DDR_STORE               
localparam  DEBUG_POINT_STORE   = "_debug_point_store.txt"      ;`define EN_DEBUG_POINT_STORE             


//---------------------------------------------------------------------------------------------------------
//
//---------------------------------------------------------------------------------------------------------

`ifdef DEBUG_CORE1
`ifdef EN_DEBUG_INST
tb_display_inst#(
    .FILE0              (DEBUG_DIR_COM      ),
    .FILE1              (DEBUG_INST         ),
    .IDW                (32                 )
)u_inst(
    .clk                (d_clk              ),
    .reset              (d_reset            ),
    .wvld               (d_inst_rvld        ),
    .wdata              (d_inst_rdata       )
);
`endif
`endif


`ifdef EN_DEBUG_UTIL
tb_display_util#(
    .FILE0              (DEBUG_DIR_COM      ),
    .FILE1              (DEBUG_UTIL         )
)u_util(
    .clk                (d_clk              ),
    .core_layer_start   (d_layer_start      ),
    .core_layer_done    (d_layer_done       ),
    .core_layer_cnt     (d_layer_cnt        ),
    .core_latency_cnt   (d_latency_cnt      ),
    .axi_util_load      (d_axi_util_load    ),
    .axi_util_store     (d_axi_util_store   ),
    .pe_act_val         (d_pe_act_val       ),
    .d_nvm_total        (d_nvm_total        ),
    .d_nvm_dsp          (d_nvm_dsp          ),
    .d_nvm_div          (d_nvm_div          ),
    .d_nvm_sync         (d_nvm_sync         ),
    .d_nvm_back         (d_nvm_back         )  
);
`endif


//---------------------------------------------------------
//
//---------------------------------------------------------
`ifdef EN_DEBUG_LOAD_KER
for(genvar g=1;g<=DEBUG_LAYER_NUM;g=g+1 )
begin:load_ker
tb_display_data#(
    .FILE0(DEBUG_DIR_DATA               ),
    .FILE1(DEBUG_LOAD_KER               ),
    .LAYER(g                            ),  
    .NUM  (32                           ),
    .IDW  (16                           ),
    .ODW  (16                           ),
    .HEX  (1                            ),
    .MSB  (1                            )
)u_display_data(
    .clk  (d_clk                        ),
    .layer(d_layer_cnt                  ), 
    .wvld (d_ddr_load_vld_ker           ),
    .wdata(d_ddr_load_data_ker          )     
);
end
`endif

//---------------------------------------------------------
//
//---------------------------------------------------------
`ifdef EN_DEBUG_LOAD_IFM
for(genvar g=1;g<=DEBUG_LAYER_NUM;g=g+1 )
begin:load_ifm
tb_display_data#(
    .FILE0(DEBUG_DIR_DATA               ),
    .FILE1(DEBUG_LOAD_IFM               ),
    .LAYER(g                            ), 
    .NUM  (32                           ),
    .IDW  (16                           ),
    .ODW  (16                           ),
    .HEX  (1                            ),
    .MSB  (1                            )
    
)u_tb_display_data(
    .clk  (d_clk),
    .layer(d_layer_cnt                  ), 
    .wvld (d_ddr_load_vld_ifm           ),
    .wdata(d_ddr_load_data_ifm          )     
);
end
`endif

//---------------------------------------------------------
//
//---------------------------------------------------------
`ifdef EN_DEBUG_DMA_KER
for(genvar g=1;g<=DEBUG_LAYER_NUM;g=g+1 )
begin:dma_ker
tb_display_data#(
    .FILE0(DEBUG_DIR_DATA               ),
    .FILE1(DEBUG_DMA_KER                ),
    .LAYER(g                            ),  
    .NUM  (32                           ),
    .IDW  (16                           ),
    .ODW  (16                           ),
    .HEX  (1                            ),
    .MSB  (1                            )
    
)u_tb_display_data(
    .clk  (d_clk                        ),
    .layer(d_layer_cnt                  ), 
    .wvld (d_ker_dma_vld                ),
    .wdata(d_ker_dma_data               )     
);
end
`endif

//---------------------------------------------------------
//
//---------------------------------------------------------
`ifdef EN_DEBUG_DMA_BM
for(genvar g=1;g<=DEBUG_LAYER_NUM;g=g+1 )
begin:dma_bm
tb_display_data#(
    .FILE0(DEBUG_DIR_DATA               ),
    .FILE1(DEBUG_DMA_BM                 ),
    .LAYER(g                            ),  
    .NUM  (32                           ),
    .IDW  (8                            ),
    .ODW  (8                            ),
    .HEX  (0                            ),
    .MSB  (1                            )
)u_tb_display_data(
    .clk  (d_clk                        ),
    .layer(d_layer_cnt                  ), 
    .wvld (d_ker_dma_vld                ),
    .wdata(d_bm_dma_data                )     
);
end
`endif


//---------------------------------------------------------
//
//---------------------------------------------------------
`ifdef EN_DEBUG_DMA_IFM
for(genvar g=1;g<=DEBUG_LAYER_NUM;g=g+1 )
begin:dma_ifm
tb_display_data#(
    .FILE0(DEBUG_DIR_DATA               ),
    .FILE1(DEBUG_DMA_IFM                ),
    .LAYER(g                            ),  
    .NUM  (32                           ),
    .IDW  (16                           ),
    .ODW  (16                           ),
    .HEX  (1                            ),
    .MSB  (1                            ) 
)u_tb_display_data(
    .clk  (d_clk                        ),
    .layer(d_layer_cnt                  ), 
    .wvld (d_ifm_dma_vld                ),
    .wdata(d_ifm_dma_data               )     
);
end
`endif

//---------------------------------------------------------
//
//---------------------------------------------------------
`ifdef EN_DEBUG_PE_OUT
for(genvar g=1;g<=DEBUG_LAYER_NUM;g=g+1 )
begin:pe_out
tb_display_data#(
    .FILE0(DEBUG_DIR_DATA               ),
    .FILE1(DEBUG_PE_OUT                 ),
    .LAYER(g                            ),  
    .NUM  (128                          ),
    .IDW  (37                           ),
    .ODW  (42                           ),
    .HEX  (1                            ),
    .MSB  (0                            )
)u_tb_display_data(
    .clk  (d_clk                        ),
    .layer(d_layer_cnt                  ), 
    .wvld (|d_pe_result_vld             ),
    .wdata( d_pe_result_data            )     
);
end
`endif

//---------------------------------------------------------
//
//---------------------------------------------------------
`ifdef EN_DEBUG_OFM_ALIGN
for(genvar g=1;g<=DEBUG_LAYER_NUM;g=g+1 )
begin:ofm_align
tb_display_data#(
    .FILE0(DEBUG_DIR_DATA               ),
    .FILE1(DEBUG_OFM_ALIGN              ),
    .LAYER(g                            ),  
    .NUM  (128                          ),
    .IDW  (37                           ),
    .ODW  (42                           ),
    .HEX  (1                            ),
    .MSB  (0                            )
)u_tb_display_data(
    .clk  (d_clk),
    .layer(d_layer_cnt                  ), 
    .wvld (|d_align_data_vld            ),
    .wdata( d_align_data                )     
);
end
`endif

//---------------------------------------------------------
//
//---------------------------------------------------------
`ifdef EN_DEBUG_OFM_MERGE
for(genvar g=1;g<=DEBUG_LAYER_NUM;g=g+1 )
begin:ofm_merge
tb_display_data#(
    .FILE0(DEBUG_DIR_DATA               ),
    .FILE1(DEBUG_OFM_MERGE              ),
    .LAYER(g                            ),  
    .NUM  (128                          ),
    .IDW  (37                           ),
    .ODW  (42                           ),
    .HEX  (1                            ),
    .MSB  (0                            ) 
)u_tb_display_data(
    .clk  (d_clk),
    .layer(d_layer_cnt                  ), 
    .wvld (|d_merge_data_vld            ),
    .wdata( d_merge_data                )     
);
end
`endif

//---------------------------------------------------------
//
//---------------------------------------------------------
`ifdef EN_DEBUG_OFM_COLLECT
for(genvar g=1;g<=DEBUG_LAYER_NUM;g=g+1 )
begin:ofm_collect
tb_display_data#(
    .FILE0(DEBUG_DIR_DATA               ),
    .FILE1(DEBUG_OFM_COLLECT            ),
    .LAYER(g                            ),  
    .NUM  (128                          ),
    .IDW  (37                           ),
    .ODW  (42                           ),
    .HEX  (1                            ),
    .MSB  (0                            )
)u_tb_display_data(
    .clk  (d_clk                        ),
    .layer(d_layer_cnt                  ), 
    .wvld (|d_collect_data_vld          ),
    .wdata( d_collect_data              )     
);
end
`endif

//---------------------------------------------------------
//
//---------------------------------------------------------
`ifdef EN_DEBUG_OFM_CONCAT
for(genvar g=1;g<=DEBUG_LAYER_NUM;g=g+1 )
begin:ofm_concat
tb_display_data#(
    .FILE0(DEBUG_DIR_DATA               ),
    .FILE1(DEBUG_OFM_CONCAT             ),
    .LAYER(g                            ),  
    .NUM  (128                          ),
    .IDW  (37                           ),
    .ODW  (42                           ),
    .HEX  (1                            ),
    .MSB  (0                            ) 
)u_tb_display_data(
    .clk  (d_clk                        ),
    .layer(d_layer_cnt                  ), 
    .wvld (|d_concat_vld                ),
    .wdata( d_concat_data               )     
);
end
`endif

//---------------------------------------------------------
//
//---------------------------------------------------------
`ifdef EN_DEBUG_OFM_ADDER_INA
for(genvar g=1;g<=DEBUG_LAYER_NUM;g=g+1 )
begin:adder_ina
tb_display_data#(
    .FILE0(DEBUG_DIR_DATA               ),
    .FILE1(DEBUG_OFM_ADDER_INA          ),
    .LAYER(g                            ),  
    .NUM  (128                          ),
    .IDW  (42                           ),
    .ODW  (42                           ),
    .HEX  (1                            ),
    .MSB  (0                            )
)u_tb_display_data(
    .clk  (d_clk),
    .layer(d_layer_cnt                  ), 
    .wvld (d_adder_ina_vld              ),
    .wdata(d_adder_ina                  )     
);
end
`endif

//---------------------------------------------------------
//
//---------------------------------------------------------
`ifdef EN_DEBUG_OFM_ADDER_INB
for(genvar g=1;g<=DEBUG_LAYER_NUM;g=g+1 )
begin:adder_inb
tb_display_data#(
    .FILE0(DEBUG_DIR_DATA               ),
    .FILE1(DEBUG_OFM_ADDER_INB          ),
    .LAYER(g                            ),  
    .NUM  (128                          ),
    .IDW  (42                           ),
    .ODW  (42                           ),
    .HEX  (1                            ),
    .MSB  (0                            )
)u_tb_display_data(
    .clk  (d_clk                        ),
    .layer(d_layer_cnt                  ), 
    .wvld (d_adder_ina_vld              ),
    .wdata(d_adder_inb                  )     
);
end
`endif

//---------------------------------------------------------
//
//---------------------------------------------------------
`ifdef EN_DEBUG_OFM_ADDER_OUT
for(genvar g=1;g<=DEBUG_LAYER_NUM;g=g+1 )
begin:adder_out
tb_display_data#(
    .FILE0(DEBUG_DIR_DATA               ),
    .FILE1(DEBUG_OFM_ADDER_OUT          ),
    .LAYER(g                            ),  
    .NUM  (128                          ),
    .IDW  (42                           ),
    .ODW  (42                           ),
    .HEX  (1                            ),
    .MSB  (0                            )
)u_tb_display_data(
    .clk  (d_clk                        ),
    .layer(d_layer_cnt                  ), 
    .wvld (d_adder_out_vld              ),
    .wdata(d_adder_out                  )     
);
end
`endif

//---------------------------------------------------------
//
//---------------------------------------------------------
`ifdef EN_DEBUG_OFM_PSUM
for(genvar g=1;g<=DEBUG_LAYER_NUM;g=g+1 )
begin:ofm_psum
tb_display_data#(
    .FILE0(DEBUG_DIR_DATA               ),
    .FILE1(DEBUG_OFM_PSUM               ),
    .LAYER(g                            ),  
    .NUM  (128                          ),
    .IDW  (32                           ),
    .ODW  (32                           ),
    .HEX  (1                            ),
    .MSB  (0                            )
)u_tb_display_data(
    .clk  (d_clk                        ),
    .layer(d_layer_cnt                  ), 
    .wvld (d_psum_data_vld              ),
    .wdata(d_psum_data                  )     
);
end
`endif

//---------------------------------------------------------
//
//---------------------------------------------------------
`ifdef EN_DEBUG_OFM_PSUM_CUT
for(genvar g=1;g<=DEBUG_LAYER_NUM;g=g+1 )
begin:ofm_cut
tb_display_data#(
    .FILE0(DEBUG_DIR_DATA               ),
    .FILE1(DEBUG_OFM_PSUM_CUT           ),
    .LAYER(g                            ),  
    .NUM  (128                          ),
    .IDW  (32                           ),
    .ODW  (16                           ),
    .HEX  (1                            ),
    .MSB  (0                            ) 
)u_tb_display_data(
    .clk  (d_clk                        ),
    .layer(d_layer_cnt                  ), 
    .wvld (d_psum_cut_data_vld          ),
    .wdata(d_psum_cut_data              )     
);
end
`endif

//---------------------------------------------------------
//
//---------------------------------------------------------
`ifdef EN_DEBUG_NVM_RDATA
for(genvar g=1;g<=DEBUG_LAYER_NUM;g=g+1 )
begin:nvm_rdata
tb_display_data#(
    .FILE0(DEBUG_DIR_DATA               ),
    .FILE1(DEBUG_NVM_RDATA              ),
    .LAYER(g                            ),  
    .NUM  (32                           ),
    .IDW  (16                           ),
    .ODW  (16                           ),
    .HEX  (1                            ),
    .MSB  (1                            )
)u_tb_display_data(
    .clk  (d_clk                        ),
    .layer(d_layer_cnt                  ), 
    .wvld (d_nvm_rdata_vld              ),
    .wdata(d_nvm_rdata                  )     
);
end
`endif

//---------------------------------------------------------
//
//---------------------------------------------------------
`ifdef EN_DEBUG_NVM_BACK_WDATA
for(genvar g=1;g<=DEBUG_LAYER_NUM;g=g+1 )
begin:nvm_wback
tb_display_data#(
    .FILE0(DEBUG_DIR_DATA               ),
    .FILE1(DEBUG_NVM_BACK_WDATA         ),
    .LAYER(g                            ),  
    .NUM  (32                           ),
    .IDW  (16                           ),
    .ODW  (16                           ),
    .HEX  (1                            ),
    .MSB  (1                            )
)u_tb_display_data(
    .clk  (d_clk                        ),
    .layer(d_layer_cnt                  ), 
    .wvld (d_back_rdata_vld             ),
    .wdata(d_back_rdata                 )     
);
end
`endif

//---------------------------------------------------------
//
//---------------------------------------------------------
`ifdef EN_DEBUG_DDR_STORE
for(genvar g=1;g<=DEBUG_LAYER_NUM;g=g+1 )
begin:ddr_store
tb_display_data#(
    .FILE0(DEBUG_DIR_DATA               ),
    .FILE1(DEBUG_DDR_STORE              ),
    .LAYER(g                            ),  
    .NUM  (32                           ),
    .IDW  (16                           ),
    .ODW  (16                           ),
    .HEX  (1                            ),
    .MSB  (0                            )
)u_tb_display_data(
    .clk  (d_clk                        ),
    .layer(d_layer_cnt                  ), 
    .wvld (d_ddr_store_vld              ),
    .wdata(d_ddr_store_data             )     
);
end
`endif


//---------------------------------------------------------
//
//---------------------------------------------------------
`ifdef EN_DEBUG_POINT_STORE
for(genvar g=1;g<=DEBUG_LAYER_NUM;g=g+1 )
begin:point_store
tb_display_float#(
    .FILE0(DEBUG_DIR_DATA               ),
    .FILE1(DEBUG_POINT_STORE            ),
    .LAYER(g                            ),  
    .NUM  (32                           ),
    .IDW  (16                           )
)u_tb_display_float(
    .clk  (d_clk                        ),
    .layer(d_layer_cnt                  ), 
    .wvld (d_ddr_store_vld              ),
    .wdata(d_ddr_store_data             ),
    .wdata_out()    
);
end
`endif
