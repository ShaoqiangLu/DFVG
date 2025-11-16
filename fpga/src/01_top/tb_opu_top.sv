`timescale 1ps/1ps
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
`include "opu_parameter.vh"

module tb_opu_top;
  import     arch_package::*                        ;
  localparam ADDR_WIDTH                    = 17     ;
  localparam DQ_WIDTH                      = 72     ;
  localparam DQS_WIDTH                     = 18     ;
  localparam DRAM_WIDTH                    = 4      ;
  localparam tCK                           = 833    ;
  localparam DDR_CYCLE                     = 3333   ;//300Mhz
  localparam NUM_PHYSICAL_PARTS= DQ_WIDTH/DRAM_WIDTH;
  localparam ODT_WIDTH_RDIMM               = 1      ;
  localparam CKE_WIDTH_RDIMM               = 1      ;
  localparam CS_WIDTH_RDIMM                = 1      ;
  localparam RANK_WIDTH_RDIMM              = 1      ;
  localparam RDIMM_SLOTS                   = 1      ;
  localparam BANK_WIDTH_RDIMM              = 2      ;
  localparam BANK_GROUP_WIDTH_RDIMM        = 2      ;
  localparam DM_DBI                        = "NONE" ;
  localparam DM_WIDTH_RDIMM                = 18     ;
  localparam MEM_PART_WIDTH                = "x4"   ;
  localparam REG_CTRL                      = "ON"   ;
  localparam RANK_WIDTH                    = 1      ;
  localparam CA_MIRROR                     = "OFF"  ;
  localparam UTYPE_density CONFIGURED_DENSITY= _16G ;
  localparam MRS                           = 3'b000 ;
  localparam REF                           = 3'b001 ;
  localparam PRE                           = 3'b010 ;
  localparam ACT                           = 3'b011 ;
  localparam WR                            = 3'b100 ;
  localparam RD                            = 3'b101 ;
  localparam ZQC                           = 3'b110 ;
  localparam NOP                           = 3'b111 ;
  localparam PCIE_CYCLE                    = 10000  ;//100Mhz
  reg                   c0_sys_rst                  ;
  wire                  c0_sys_clk_p                ;
  wire                  c0_sys_clk_n                ;
  wire                  c0_ddr4_act_n               ;
  wire  [16:0]          c0_ddr4_adr                 ;
  wire  [1 :0]          c0_ddr4_ba                  ;
  wire  [1 :0]          c0_ddr4_bg                  ;
  wire                  c0_ddr4_cke                 ;
  wire                  c0_ddr4_odt                 ;
  wire                  c0_ddr4_cs_n                ;
  wire                  c0_ddr4_ck_t                ;
  wire                  c0_ddr4_ck_c                ;
  wire                  c0_ddr4_reset_n             ;
  wire                  c0_ddr4_parity              ;
  wire  [71:0]          c0_ddr4_dq                  ;
  wire  [17:0]          c0_ddr4_dqs_c               ;
  wire  [17:0]          c0_ddr4_dqs_t               ;
  reg                   c0_sys_clk_init             ;
`ifdef DESIGN_OPU_CORE2_OR_CORE4
  reg                   c1_sys_rst                  ;
  wire                  c1_sys_clk_p                ;
  wire                  c1_sys_clk_n                ;
  wire                  c1_ddr4_act_n               ;
  wire  [16:0]          c1_ddr4_adr                 ;
  wire  [1 :0]          c1_ddr4_ba                  ;
  wire  [1 :0]          c1_ddr4_bg                  ;
  wire                  c1_ddr4_cke                 ;
  wire                  c1_ddr4_odt                 ;
  wire                  c1_ddr4_cs_n                ;
  wire                  c1_ddr4_ck_t                ;
  wire                  c1_ddr4_ck_c                ;
  wire                  c1_ddr4_reset_n             ;
  wire                  c1_ddr4_parity              ;
  wire  [71:0]          c1_ddr4_dq                  ;
  wire  [17:0]          c1_ddr4_dqs_c               ;
  wire  [17:0]          c1_ddr4_dqs_t               ;
  reg                   c1_sys_clk_init             ;
`endif

`ifdef DESIGN_OPU_CORE4
  reg                   c2_sys_rst                  ;
  wire                  c2_sys_clk_p                ;
  wire                  c2_sys_clk_n                ;
  wire                  c2_ddr4_act_n               ;
  wire  [16:0]          c2_ddr4_adr                 ;
  wire  [1 :0]          c2_ddr4_ba                  ;
  wire  [1 :0]          c2_ddr4_bg                  ;
  wire                  c2_ddr4_cke                 ;
  wire                  c2_ddr4_odt                 ;
  wire                  c2_ddr4_cs_n                ;
  wire                  c2_ddr4_ck_t                ;
  wire                  c2_ddr4_ck_c                ;
  wire                  c2_ddr4_reset_n             ;
  wire                  c2_ddr4_parity              ;
  wire  [71:0]          c2_ddr4_dq                  ;
  wire  [17:0]          c2_ddr4_dqs_c               ;
  wire  [17:0]          c2_ddr4_dqs_t               ;
  reg                   c2_sys_clk_init             ;
  reg                   c3_sys_rst                  ;
  wire                  c3_sys_clk_p                ;
  wire                  c3_sys_clk_n                ;
  wire                  c3_ddr4_act_n               ;
  wire  [16:0]          c3_ddr4_adr                 ;
  wire  [1 :0]          c3_ddr4_ba                  ;
  wire  [1 :0]          c3_ddr4_bg                  ;
  wire                  c3_ddr4_cke                 ;
  wire                  c3_ddr4_odt                 ;
  wire                  c3_ddr4_cs_n                ;
  wire                  c3_ddr4_ck_t                ;
  wire                  c3_ddr4_ck_c                ;
  wire                  c3_ddr4_reset_n             ;
  wire                  c3_ddr4_parity              ;
  wire  [71:0]          c3_ddr4_dq                  ;
  wire  [17:0]          c3_ddr4_dqs_c               ;
  wire  [17:0]          c3_ddr4_dqs_t               ;
  reg                   c3_sys_clk_init             ;
`endif
  wire                  pci_exp_rst_n               ;
  wire                  pci_exp_clk_p               ;
  wire                  pci_exp_clk_n               ;
  wire  [15:0]          pci_exp_txp                 ;
  wire  [15:0]          pci_exp_txn                 ;
  wire  [15:0]          pci_exp_rxp                 ;
  wire  [15:0]          pci_exp_rxn                 ;
  reg   [16:0]          ADR_MOD                     ;
  reg   [31:0]          STR_CMD                     ;


//--------------------------------------------------------------------------
// Reset Generation  Clock Generation
//--------------------------------------------------------------------------
  localparam C0_CLK_GAP =1000;
  localparam C1_CLK_GAP =1000;//2000
  localparam C2_CLK_GAP =1000;//3000
  localparam C3_CLK_GAP =1000;//4000
  
  initial begin c0_sys_clk_init = 1'b0           ;
    #           C0_CLK_GAP;
    forever     c0_sys_clk_init=#(DDR_CYCLE/2)~ 
                c0_sys_clk_init; end
  assign        c0_sys_clk_p =  
                c0_sys_clk_init  ;
  assign        c0_sys_clk_n = ~
                c0_sys_clk_init  ;
  initial begin c0_sys_rst=1 ;repeat(50)@(posedge        
                c0_sys_clk_p);
                c0_sys_rst=0 ;end
`ifdef DESIGN_OPU_CORE2_OR_CORE4
//-----------------------------------------------------
  initial begin c1_sys_clk_init = 1'b0           ;
    #           C1_CLK_GAP;
    forever     c1_sys_clk_init=#(DDR_CYCLE/2)~ 
                c1_sys_clk_init; end
  assign        c1_sys_clk_p =  
                c1_sys_clk_init  ;
  assign        c1_sys_clk_n = ~
                c1_sys_clk_init  ;
  initial begin c1_sys_rst=1 ;repeat(50)@(posedge        
                c1_sys_clk_p);
                c1_sys_rst=0 ;end
`endif

`ifdef DESIGN_OPU_CORE4
//-----------------------------------------------------
  initial begin c2_sys_clk_init = 1'b0           ;
    #           C2_CLK_GAP;
    forever     c2_sys_clk_init=#(DDR_CYCLE/2)~ 
                c2_sys_clk_init; end
  assign        c2_sys_clk_p =  
                c2_sys_clk_init  ;
  assign        c2_sys_clk_n = ~
                c2_sys_clk_init  ;
  initial begin c2_sys_rst=1 ;repeat(50)@(posedge        
                c2_sys_clk_p);
                c2_sys_rst=0 ;end

//----------------------------------------------------
  initial begin c3_sys_clk_init = 1'b0           ;
    #           C3_CLK_GAP;
    forever     c3_sys_clk_init=#(DDR_CYCLE/2)~ 
                c3_sys_clk_init; end
  assign        c3_sys_clk_p =  
                c3_sys_clk_init  ;
  assign        c3_sys_clk_n = ~
                c3_sys_clk_init  ;
  initial begin c3_sys_rst=1 ;repeat(50)@(posedge        
                c3_sys_clk_p);
                c3_sys_rst=0 ;end
`endif

//--------------------------------------------------------------------------
//FPGA Memory Controller instantiation
//--------------------------------------------------------------------------
opu_top  OPU_TOP
(
    .c0_sys_rst             (c0_sys_rst                ),
    .c0_sys_clk_p           (c0_sys_clk_p              ),
    .c0_sys_clk_n           (c0_sys_clk_n              ), 
    .c0_ddr4_act_n          (c0_ddr4_act_n             ),
    .c0_ddr4_adr            (c0_ddr4_adr               ),
    .c0_ddr4_ba             (c0_ddr4_ba                ),
    .c0_ddr4_bg             (c0_ddr4_bg                ),
    .c0_ddr4_cke            (c0_ddr4_cke               ),
    .c0_ddr4_odt            (c0_ddr4_odt               ),
    .c0_ddr4_cs_n           (c0_ddr4_cs_n              ),
    .c0_ddr4_ck_t           (c0_ddr4_ck_t              ),
    .c0_ddr4_ck_c           (c0_ddr4_ck_c              ),
    .c0_ddr4_reset_n        (c0_ddr4_reset_n           ),
    .c0_ddr4_parity         (c0_ddr4_parity            ),
    .c0_ddr4_dq             (c0_ddr4_dq                ),
    .c0_ddr4_dqs_c          (c0_ddr4_dqs_c             ),
    .c0_ddr4_dqs_t          (c0_ddr4_dqs_t             ),
    
`ifdef DESIGN_OPU_CORE2_OR_CORE4
    .c1_sys_rst             (c1_sys_rst                ),
    .c1_sys_clk_p           (c1_sys_clk_p              ),
    .c1_sys_clk_n           (c1_sys_clk_n              ), 
    .c1_ddr4_act_n          (c1_ddr4_act_n             ),
    .c1_ddr4_adr            (c1_ddr4_adr               ),
    .c1_ddr4_ba             (c1_ddr4_ba                ),
    .c1_ddr4_bg             (c1_ddr4_bg                ),
    .c1_ddr4_cke            (c1_ddr4_cke               ),
    .c1_ddr4_odt            (c1_ddr4_odt               ),
    .c1_ddr4_cs_n           (c1_ddr4_cs_n              ),
    .c1_ddr4_ck_t           (c1_ddr4_ck_t              ),
    .c1_ddr4_ck_c           (c1_ddr4_ck_c              ),
    .c1_ddr4_reset_n        (c1_ddr4_reset_n           ),
    .c1_ddr4_parity         (c1_ddr4_parity            ),
    .c1_ddr4_dq             (c1_ddr4_dq                ),
    .c1_ddr4_dqs_c          (c1_ddr4_dqs_c             ),
    .c1_ddr4_dqs_t          (c1_ddr4_dqs_t             ),
`endif

`ifdef DESIGN_OPU_CORE4
    .c2_sys_rst             (c2_sys_rst                ),
    .c2_sys_clk_p           (c2_sys_clk_p              ),
    .c2_sys_clk_n           (c2_sys_clk_n              ), 
    .c2_ddr4_act_n          (c2_ddr4_act_n             ),
    .c2_ddr4_adr            (c2_ddr4_adr               ),
    .c2_ddr4_ba             (c2_ddr4_ba                ),
    .c2_ddr4_bg             (c2_ddr4_bg                ),
    .c2_ddr4_cke            (c2_ddr4_cke               ),
    .c2_ddr4_odt            (c2_ddr4_odt               ),
    .c2_ddr4_cs_n           (c2_ddr4_cs_n              ),
    .c2_ddr4_ck_t           (c2_ddr4_ck_t              ),
    .c2_ddr4_ck_c           (c2_ddr4_ck_c              ),
    .c2_ddr4_reset_n        (c2_ddr4_reset_n           ),
    .c2_ddr4_parity         (c2_ddr4_parity            ),
    .c2_ddr4_dq             (c2_ddr4_dq                ),
    .c2_ddr4_dqs_c          (c2_ddr4_dqs_c             ),
    .c2_ddr4_dqs_t          (c2_ddr4_dqs_t             ),

    .c3_sys_rst             (c3_sys_rst                ),
    .c3_sys_clk_p           (c3_sys_clk_p              ),
    .c3_sys_clk_n           (c3_sys_clk_n              ), 
    .c3_ddr4_act_n          (c3_ddr4_act_n             ),
    .c3_ddr4_adr            (c3_ddr4_adr               ),
    .c3_ddr4_ba             (c3_ddr4_ba                ),
    .c3_ddr4_bg             (c3_ddr4_bg                ),
    .c3_ddr4_cke            (c3_ddr4_cke               ),
    .c3_ddr4_odt            (c3_ddr4_odt               ),
    .c3_ddr4_cs_n           (c3_ddr4_cs_n              ),
    .c3_ddr4_ck_t           (c3_ddr4_ck_t              ),
    .c3_ddr4_ck_c           (c3_ddr4_ck_c              ),
    .c3_ddr4_reset_n        (c3_ddr4_reset_n           ),
    .c3_ddr4_parity         (c3_ddr4_parity            ),
    .c3_ddr4_dq             (c3_ddr4_dq                ),
    .c3_ddr4_dqs_c          (c3_ddr4_dqs_c             ),
    .c3_ddr4_dqs_t          (c3_ddr4_dqs_t             ),
`endif
    .pci_exp_rst_n          (pci_exp_rst_n             ),//i
    .pci_exp_clk_p          (pci_exp_clk_p             ),//i
    .pci_exp_clk_n          (pci_exp_clk_n             ),//i
    .pci_exp_txp            (pci_exp_txp               ),//o
    .pci_exp_txn            (pci_exp_txn               ),//o
    .pci_exp_rxp            (pci_exp_rxp               ),//i
    .pci_exp_rxn            (pci_exp_rxn               ) //i
     
);




//--------------------------------------------------------------------------
//Memory Model instantiation
//--------------------------------------------------------------------------
`ifndef SIM_MIG
 DDR4_wrap_top #(
    .MC_DQ_WIDTH        (DQ_WIDTH                      ),
    .MC_DQS_BITS        (DQS_WIDTH                     ),
    .MC_DM_WIDTH        (DM_WIDTH_RDIMM                ),
    .MC_CKE_NUM         (CKE_WIDTH_RDIMM               ),
    .MC_ODT_WIDTH       (ODT_WIDTH_RDIMM               ),
    .MC_ABITS           (ADDR_WIDTH                    ),
    .MC_BANK_WIDTH      (BANK_WIDTH_RDIMM              ),
    .MC_BANK_GROUP      (BANK_GROUP_WIDTH_RDIMM        ),
    .MC_CS_NUM          (CS_WIDTH_RDIMM                ),
    .MC_RANKS_NUM       (RANK_WIDTH_RDIMM              ),
    .NUM_PHYSICAL_PARTS (NUM_PHYSICAL_PARTS            ),
    .CALIB_EN           ("NO"                          ),
    .tCK                (tCK                           ),
    .tPDM               (                              ),
    .MIN_TOTAL_R2R_DELAY(                              ),
    .MAX_TOTAL_R2R_DELAY(                              ),
    .TOTAL_FBT_DELAY    (                              ),
    .MEM_PART_WIDTH     (MEM_PART_WIDTH                ),
    .MC_CA_MIRROR       (CA_MIRROR                     ),
    // .SDRAM("DDR4"),
    `ifdef SAMSUNG
    .DDR_SIM_MODEL      ("SAMSUNG"                     ),
    `else         
    .DDR_SIM_MODEL      ("MICRON"                      ),
    `endif
    .DM_DBI             (DM_DBI                        ),
    .MC_REG_CTRL        (REG_CTRL                      ),
    .DIMM_MODEL         ("RDIMM"                       ),
    .RDIMM_SLOTS        (RDIMM_SLOTS                   ),
    .CONFIGURED_DENSITY (CONFIGURED_DENSITY            )
) c0_DDR4_SIM 
(
    .ddr4_act_n         (c0_ddr4_act_n                 ),
    .ddr4_addr          (c0_ddr4_adr                   ),
    .ddr4_ba            (c0_ddr4_ba                    ),
    .ddr4_bg            (c0_ddr4_bg                    ),
    .ddr4_cke           (c0_ddr4_cke                   ),
    .ddr4_odt           (c0_ddr4_odt                   ),
    .ddr4_cs_n          (c0_ddr4_cs_n                  ),
    .ddr4_ck_t          (c0_ddr4_ck_t                  ),
    .ddr4_ck_c          (c0_ddr4_ck_c                  ),
    .ddr4_reset_n       (c0_ddr4_reset_n               ),
    .ddr4_par           (c0_ddr4_parity                ),
    .ddr4_dq            (c0_ddr4_dq                    ), // in out
    .ddr4_dqs_c         (c0_ddr4_dqs_c                 ), // in out
    .ddr4_dqs_t         (c0_ddr4_dqs_t                 ), // in out
    .ddr4_dm_dbi_n      (                              ), // in out
    .ddr4_alert_n       (                              )  // in out
);
`endif

`ifdef DESIGN_OPU_CORE2_OR_CORE4
`ifndef SIM_MIG	      
 DDR4_wrap_top #(
    .MC_DQ_WIDTH        (DQ_WIDTH                      ),
    .MC_DQS_BITS        (DQS_WIDTH                     ),
    .MC_DM_WIDTH        (DM_WIDTH_RDIMM                ),
    .MC_CKE_NUM         (CKE_WIDTH_RDIMM               ),
    .MC_ODT_WIDTH       (ODT_WIDTH_RDIMM               ),
    .MC_ABITS           (ADDR_WIDTH                    ),
    .MC_BANK_WIDTH      (BANK_WIDTH_RDIMM              ),
    .MC_BANK_GROUP      (BANK_GROUP_WIDTH_RDIMM        ),
    .MC_CS_NUM          (CS_WIDTH_RDIMM                ),
    .MC_RANKS_NUM       (RANK_WIDTH_RDIMM              ),
    .NUM_PHYSICAL_PARTS (NUM_PHYSICAL_PARTS            ),
    .CALIB_EN           ("NO"                          ),
    .tCK                (tCK                           ),
    .tPDM               (                              ),
    .MIN_TOTAL_R2R_DELAY(                              ),
    .MAX_TOTAL_R2R_DELAY(                              ),
    .TOTAL_FBT_DELAY    (                              ),
    .MEM_PART_WIDTH     (MEM_PART_WIDTH                ),
    .MC_CA_MIRROR       (CA_MIRROR                     ),
    // .SDRAM("DDR4"),
    `ifdef SAMSUNG
    .DDR_SIM_MODEL      ("SAMSUNG"                     ),
    `else         
    .DDR_SIM_MODEL      ("MICRON"                      ),
    `endif
    .DM_DBI             (DM_DBI                        ),
    .MC_REG_CTRL        (REG_CTRL                      ),
    .DIMM_MODEL         ("RDIMM"                       ),
    .RDIMM_SLOTS        (RDIMM_SLOTS                   ),
    .CONFIGURED_DENSITY (CONFIGURED_DENSITY            )
) c1_DDR4_SIM 
(
    .ddr4_act_n         (c1_ddr4_act_n                 ),
    .ddr4_addr          (c1_ddr4_adr                   ),
    .ddr4_ba            (c1_ddr4_ba                    ),
    .ddr4_bg            (c1_ddr4_bg                    ),
    .ddr4_cke           (c1_ddr4_cke                   ),
    .ddr4_odt           (c1_ddr4_odt                   ),
    .ddr4_cs_n          (c1_ddr4_cs_n                  ),
    .ddr4_ck_t          (c1_ddr4_ck_t                  ),
    .ddr4_ck_c          (c1_ddr4_ck_c                  ),
    .ddr4_reset_n       (c1_ddr4_reset_n               ),
    .ddr4_par           (c1_ddr4_parity                ),
    .ddr4_dq            (c1_ddr4_dq                    ), // in out
    .ddr4_dqs_c         (c1_ddr4_dqs_c                 ), // in out
    .ddr4_dqs_t         (c1_ddr4_dqs_t                 ), // in out
    .ddr4_dm_dbi_n      (                              ), // in out
    .ddr4_alert_n       (                              )  // in out
);
`endif
`endif

`ifdef DESIGN_OPU_CORE4
`ifndef SIM_MIG
 DDR4_wrap_top #(
    .MC_DQ_WIDTH        (DQ_WIDTH                      ),
    .MC_DQS_BITS        (DQS_WIDTH                     ),
    .MC_DM_WIDTH        (DM_WIDTH_RDIMM                ),
    .MC_CKE_NUM         (CKE_WIDTH_RDIMM               ),
    .MC_ODT_WIDTH       (ODT_WIDTH_RDIMM               ),
    .MC_ABITS           (ADDR_WIDTH                    ),
    .MC_BANK_WIDTH      (BANK_WIDTH_RDIMM              ),
    .MC_BANK_GROUP      (BANK_GROUP_WIDTH_RDIMM        ),
    .MC_CS_NUM          (CS_WIDTH_RDIMM                ),
    .MC_RANKS_NUM       (RANK_WIDTH_RDIMM              ),
    .NUM_PHYSICAL_PARTS (NUM_PHYSICAL_PARTS            ),
    .CALIB_EN           ("NO"                          ),
    .tCK                (tCK                           ),
    .tPDM               (                              ),
    .MIN_TOTAL_R2R_DELAY(                              ),
    .MAX_TOTAL_R2R_DELAY(                              ),
    .TOTAL_FBT_DELAY    (                              ),
    .MEM_PART_WIDTH     (MEM_PART_WIDTH                ),
    .MC_CA_MIRROR       (CA_MIRROR                     ),
    // .SDRAM("DDR4"),
    `ifdef SAMSUNG
    .DDR_SIM_MODEL      ("SAMSUNG"                     ),
    `else         
    .DDR_SIM_MODEL      ("MICRON"                      ),
    `endif
    .DM_DBI             (DM_DBI                        ),
    .MC_REG_CTRL        (REG_CTRL                      ),
    .DIMM_MODEL         ("RDIMM"                       ),
    .RDIMM_SLOTS        (RDIMM_SLOTS                   ),
    .CONFIGURED_DENSITY (CONFIGURED_DENSITY            )
) c2_DDR4_SIM 
(
    .ddr4_act_n         (c2_ddr4_act_n                 ),
    .ddr4_addr          (c2_ddr4_adr                   ),
    .ddr4_ba            (c2_ddr4_ba                    ),
    .ddr4_bg            (c2_ddr4_bg                    ),
    .ddr4_cke           (c2_ddr4_cke                   ),
    .ddr4_odt           (c2_ddr4_odt                   ),
    .ddr4_cs_n          (c2_ddr4_cs_n                  ),
    .ddr4_ck_t          (c2_ddr4_ck_t                  ),
    .ddr4_ck_c          (c2_ddr4_ck_c                  ),
    .ddr4_reset_n       (c2_ddr4_reset_n               ),
    .ddr4_par           (c2_ddr4_parity                ),
    .ddr4_dq            (c2_ddr4_dq                    ), // in out
    .ddr4_dqs_c         (c2_ddr4_dqs_c                 ), // in out
    .ddr4_dqs_t         (c2_ddr4_dqs_t                 ), // in out
    .ddr4_dm_dbi_n      (                              ), // in out
    .ddr4_alert_n       (                              )  // in out
);
 DDR4_wrap_top #(
    .MC_DQ_WIDTH        (DQ_WIDTH                      ),
    .MC_DQS_BITS        (DQS_WIDTH                     ),
    .MC_DM_WIDTH        (DM_WIDTH_RDIMM                ),
    .MC_CKE_NUM         (CKE_WIDTH_RDIMM               ),
    .MC_ODT_WIDTH       (ODT_WIDTH_RDIMM               ),
    .MC_ABITS           (ADDR_WIDTH                    ),
    .MC_BANK_WIDTH      (BANK_WIDTH_RDIMM              ),
    .MC_BANK_GROUP      (BANK_GROUP_WIDTH_RDIMM        ),
    .MC_CS_NUM          (CS_WIDTH_RDIMM                ),
    .MC_RANKS_NUM       (RANK_WIDTH_RDIMM              ),
    .NUM_PHYSICAL_PARTS (NUM_PHYSICAL_PARTS            ),
    .CALIB_EN           ("NO"                          ),
    .tCK                (tCK                           ),
    .tPDM               (                              ),
    .MIN_TOTAL_R2R_DELAY(                              ),
    .MAX_TOTAL_R2R_DELAY(                              ),
    .TOTAL_FBT_DELAY    (                              ),
    .MEM_PART_WIDTH     (MEM_PART_WIDTH                ),
    .MC_CA_MIRROR       (CA_MIRROR                     ),
    // .SDRAM("DDR4"),
    `ifdef SAMSUNG
    .DDR_SIM_MODEL      ("SAMSUNG"                     ),
    `else         
    .DDR_SIM_MODEL      ("MICRON"                      ),
    `endif
    .DM_DBI             (DM_DBI                        ),
    .MC_REG_CTRL        (REG_CTRL                      ),
    .DIMM_MODEL         ("RDIMM"                       ),
    .RDIMM_SLOTS        (RDIMM_SLOTS                   ),
    .CONFIGURED_DENSITY (CONFIGURED_DENSITY            )
) c3_DDR4_SIM 
(
    .ddr4_act_n         (c3_ddr4_act_n                 ),
    .ddr4_addr          (c3_ddr4_adr                   ),
    .ddr4_ba            (c3_ddr4_ba                    ),
    .ddr4_bg            (c3_ddr4_bg                    ),
    .ddr4_cke           (c3_ddr4_cke                   ),
    .ddr4_odt           (c3_ddr4_odt                   ),
    .ddr4_cs_n          (c3_ddr4_cs_n                  ),
    .ddr4_ck_t          (c3_ddr4_ck_t                  ),
    .ddr4_ck_c          (c3_ddr4_ck_c                  ),
    .ddr4_reset_n       (c3_ddr4_reset_n               ),
    .ddr4_par           (c3_ddr4_parity                ),
    .ddr4_dq            (c3_ddr4_dq                    ), // in out
    .ddr4_dqs_c         (c3_ddr4_dqs_c                 ), // in out
    .ddr4_dqs_t         (c3_ddr4_dqs_t                 ), // in out
    .ddr4_dm_dbi_n      (                              ), // in out
    .ddr4_alert_n       (                              )  // in out
);
`endif
`endif

//------------------------------------------------------
//PCIE interface on the PC side
//------------------------------------------------------
`ifndef SIM_XDMA
board board
(
    .pci_exp_rst_n     (pci_exp_rst_n),//o
    .pci_exp_clk_p     (pci_exp_clk_p),//o
    .pci_exp_clk_n     (pci_exp_clk_n),//o
    .pci_exp_txp_i     (pci_exp_txp  ),//i
    .pci_exp_txn_i     (pci_exp_txn  ),//i
    .pci_exp_rxp_o     (pci_exp_rxp  ),//o
    .pci_exp_rxn_o     (pci_exp_rxn  ) //o
);

`else
reg   pci_sys_clk_init  =0                              ;
reg   pci_sys_rst_n_init=0                              ;

initial 
begin
      pci_sys_clk_init  = 1'b0;
      forever pci_sys_clk_init  = 
      #(PCIE_CYCLE/2) ~pci_sys_clk_init                 ;
end
initial
begin
       pci_sys_rst_n_init=0                             ;   
       repeat (50) @(posedge pci_sys_clk_init)          ;
       pci_sys_rst_n_init=1                             ;
end
assign pci_exp_rst_n = pci_sys_rst_n_init               ;
assign pci_exp_clk_p = pci_sys_clk_init                 ;
assign pci_exp_clk_n =~pci_sys_clk_init                 ;
assign pci_exp_rxp=0                                    ;
assign pci_exp_rxn=0                                    ;
`endif



//--------------------------------------------------------------------------
// Translation of operation commands
//-------------------------------------------------------------------------- 
    wire        d_ddr4_act_n=c0_ddr4_act_n             ;
    wire [16:0] d_ddr4_adr  =c0_ddr4_adr               ;
    wire        d_ddr4_cs_n =c0_ddr4_cs_n              ;

    always @(*) if (d_ddr4_act_n)
    casez (d_ddr4_adr[16:14])
          WR,  RD: ADR_MOD = d_ddr4_adr                ;
          default: ADR_MOD = d_ddr4_adr                ;
    endcase else   ADR_MOD = d_ddr4_adr                ;
    
    always @(*)begin
    if (d_ddr4_cs_n)             STR_CMD = "DSEL"      ;
    else if (d_ddr4_act_n)
        casez (ADR_MOD[16:14])
         MRS:                    STR_CMD = "MRS"       ;
         REF:                    STR_CMD = "REF"       ;
         PRE:                    STR_CMD = "PRE"       ;
         WR:                     STR_CMD = "WR"        ; 
         RD:                     STR_CMD = "RD"        ;
         ZQC:                    STR_CMD = "ZQC"       ;
         NOP:                    STR_CMD = "NOP"       ;
        default:                 STR_CMD = "***"       ;
        endcase else             STR_CMD = "ACT"       ;
    end    


//----------------------------------------------------------------------------------
// debug
//----------------------------------------------------------------------------------
`ifdef DEBUG_ENABLE
    tb_debug_top DEBUG_TOP();
 //`include "tb_debug_header.vh"


`endif//DEBUG_ENABLE
   
   
   
   
endmodule
