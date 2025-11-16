

//opu_parameter

//----------------------------------------------------------------------------------
// Selection of optimized versions.
//----------------------------------------------------------------------------------
//`define SYNC_RUN
//`define PE_NEW
//`define DESIGN_BM_MULTI_CYCLE
`define SIM_CODE
`define SIM_DSP_PE
`define SIM_MIG
`define SIM_XDMA
`define SIM_DIV
`define AXI_BYPASS
`define ROUTER_SYNC
//`define ON_CHIP_DECODE
`define DESIGN_OPU_CORE1
`define PE_SPARSE
//----------------------------------------------------------------------------------
// Configure the running instructions.
//----------------------------------------------------------------------------------
//`define DEBUG_CORE4
//`define DEBUG_CORE3
//`define DEBUG_CORE2
`define DEBUG_CORE1
`define DEBUG_ENABLE
`define DEBUG_MODEL "seqlen64"
`define DEBUG_PATH  "/home/lsq/Desktop/opu/rtl/chatopu/chatopu_ok/10_data/"

//----------------------------------------------------------------------------------
//`define INST_DATA_TXT
//----------------------------------------------------------------------------------
//`define INST_SPARSE125_NEW_CORE4_2
//`define INST_SPARSE125_NEW_CORE1_2//-----------ok
//`define INST_SPARSE350_CORE1_2
//`define INST_SPARSE350_CORE1_2_gen1
//`define INST_SPARSE350_CORE1_2_gen1_new
//
//`define INST_OPT350M_CORE1_LEN128_DENSE
//`define INST_OPT350M_CORE4_LEN128_DENSE
//`define INST_OPT350M_CORE1_LEN128_DENSE_OUT1
//`define INST_OPT350M_CORE4_LEN128_DENSE_OUT1
//`define INST_OPT350M_CORE1_LEN128_SPARSE2
//`define INST_OPT350M_CORE4_LEN128_SPARSE2
//`define INST_OPT350M_CORE1_LEN128_SPARSE2_OUT1
//`define INST_OPT350M_CORE4_LEN128_SPARSE2_OUT1
//
`define INST_OPT125M_CORE1_LEN64_SPARSE2//----ok
//`define INST_OPT125M_CORE4_LEN64_SPARSE2
//
//`define INST_SPARSE125_CORE4_D64
//`define INST_SPARSE125_CORE4_D64_1
//`define INST_SPARSE125_CORE4_D64_33
//`define INST_SPARSE125_CORE4_D128
//`define INST_SPARSE125_CORE4_D128_1
//`define INST_SPARSE125_CORE4_D128_33
//`define INST_SPARSE125_CORE4_D128_65
//`define INST_SPARSE125_CORE4_D256
//`define INST_SPARSE125_CORE4_D256_1
//`define INST_SPARSE125_CORE4_D512//my pao
//`define INST_SPARSE125_CORE4_D512_1
//------------------------------------
//`define INST_SPARSE125_CORE4_2S64
//`define INST_SPARSE125_CORE4_2S64_1
//`define INST_SPARSE125_CORE4_2S64_33
//`define INST_SPARSE125_CORE4_2S128
//`define INST_SPARSE125_CORE4_2S128_1
//`define INST_SPARSE125_CORE4_2S128_33
//`define INST_SPARSE125_CORE4_2S128_65
//`define INST_SPARSE125_CORE4_2S256
//`define INST_SPARSE125_CORE4_2S256_1
//`define INST_SPARSE125_CORE4_2S512
//`define INST_SPARSE125_CORE4_2S512_1
//-------------------------------------
//`define INST_SPARSE125_CORE4_3S64
//`define INST_SPARSE125_CORE4_3S64_1
//`define INST_SPARSE125_CORE4_3S64_33
//`define INST_SPARSE125_CORE4_3S128
//`define INST_SPARSE125_CORE4_3S128_1
//`define INST_SPARSE125_CORE4_3S128_33
//`define INST_SPARSE125_CORE4_3S128_65
//`define INST_SPARSE125_CORE4_3S256
//`define INST_SPARSE125_CORE4_3S256_1
//`define INST_SPARSE125_CORE4_3S512
//`define INST_SPARSE125_CORE4_3S512_1


//----------------------------------------------------------------------------------
// design
//----------------------------------------------------------------------------------
`ifdef DESIGN_OPU_CORE2
    `define DESIGN_OPU_CORE2_OR_CORE4
`elsif DESIGN_OPU_CORE4
    `define DESIGN_OPU_CORE2_OR_CORE4
`endif

`ifdef ROUTER_SYNC
    `ifdef  DESIGN_OPU_CORE2
        `define ROUTER_SYNC2
    `elsif  DESIGN_OPU_CORE4 
        `define ROUTER_SYNC4
    `endif
`endif


//----------------------------------------------------------------------------------
// ofm
//----------------------------------------------------------------------------------
`define OFM_DLY_BIAS  87
`define OFM_DLY_START 89
`define OFM_DLY_DONE  73

//----------------------------------------------------------------------------------
// inst
//----------------------------------------------------------------------------------
`ifndef OPU_PARAMETER
`define OPU_PARAMETER
`endif

`define INST_OFM_DLY  14
`define INST_NVM_DLY  5




