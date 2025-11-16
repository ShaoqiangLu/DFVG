
`ifdef OPU_PARAMETER

localparam  AXI_M00_ADDR         = 64'h0000_0000_0000_0000               ;
localparam  AXI_M01_ADDR         = 64'h0000_0004_0000_0000               ;
localparam  AXI_M02_ADDR         = 64'h0000_0008_0000_0000               ;
localparam  AXI_M03_ADDR         = 64'h0000_000C_0000_0000               ;
localparam  AXI_S00_WRID         = 0                                     ;
localparam  AXI_S01_WRID         = 2                                     ;
localparam  AXI_S02_WRID         = 4                                     ;
localparam  AXI_S03_WRID         = 6                                     ;
localparam  AXI_S04_WRID         = 8                                     ;
localparam  INST_HIGH1           = 4'h0                                  ;
localparam  INST_HIGH2           = 4'h4                                  ;
localparam  INST_HIGH3           = 4'h8                                  ;
localparam  INST_HIGH4           = 4'hC                                  ;
localparam  DDR4_DONE_CYCLE      = 1000                                  ;
localparam  PCIE_CLOK_CYCLE      = 4000                                  ;
localparam  PCIE_DONE_CYCLE      = 1500                                  ;
localparam  DLY_SYNC             = 4                                     ;

`ifdef INST_SEQLEN64_CORE1
        localparam  INST_OFFSET1 = 25'd2884128 ;localparam INST_START1 =1;
        localparam  INST_OFFSET2 = 25'd2884128 ;localparam INST_START2 =0;
        localparam  INST_OFFSET3 = 25'd2884128 ;localparam INST_START3 =0;
        localparam  INST_OFFSET4 = 25'd2884128 ;localparam INST_START4 =0;
        localparam  INST_FILE1   = "/home/lsq/Desktop/opu/multi/back_ok/rtl_inst/l64_core1/dram_0_data";
        localparam  INST_FILE2   = "";
        localparam  INST_FILE3   = "";
        localparam  INST_FILE4   = "";
`elsif INST_SEQLEN64_CORE2
        localparam  INST_OFFSET1 = 25'd1442088 ;localparam INST_START1 =1;
        localparam  INST_OFFSET2 = 25'd1442088 ;localparam INST_START2 =1;
        localparam  INST_OFFSET3 = 25'd1442088 ;localparam INST_START3 =0;
        localparam  INST_OFFSET4 = 25'd1442088 ;localparam INST_START4 =0;
        localparam  INST_FILE1   = "/home/lsq/Desktop/opu/multi/back/l64_2core_ok/dram_0_data";
        localparam  INST_FILE2   = "/home/lsq/Desktop/opu/multi/back/l64_2core_ok/dram_1_data";
        localparam  INST_FILE3   = "";
        localparam  INST_FILE4   = "";
`elsif INST_SEQLEN64_CORE4
        localparam  INST_OFFSET1 = 25'd721068 ;localparam INST_START1 =1;
        localparam  INST_OFFSET2 = 25'd721068 ;localparam INST_START2 =1;
        localparam  INST_OFFSET3 = 25'd721068 ;localparam INST_START3 =1;
        localparam  INST_OFFSET4 = 25'd721068 ;localparam INST_START4 =1;
        localparam  INST_FILE1   = "/home/lsq/Desktop/opu/multi/back_ok/rtl_inst/l64_core4/dram_0_data";
        localparam  INST_FILE2   = "/home/lsq/Desktop/opu/multi/back_ok/rtl_inst/l64_core4/dram_1_data";
        localparam  INST_FILE3   = "/home/lsq/Desktop/opu/multi/back_ok/rtl_inst/l64_core4/dram_2_data";
        localparam  INST_FILE4   = "/home/lsq/Desktop/opu/multi/back_ok/rtl_inst/l64_core4/dram_3_data";
//-------------------------------------------------------------------------------------------------------------------
`elsif INST_SEQLEN128_CORE1
        localparam  INST_OFFSET1 = 25'd3125328 ;localparam INST_START1 =1;
        localparam  INST_OFFSET2 = 25'd3125328 ;localparam INST_START2 =0;
        localparam  INST_OFFSET3 = 25'd3125328 ;localparam INST_START3 =0;
        localparam  INST_OFFSET4 = 25'd3125328 ;localparam INST_START4 =0;
        localparam  INST_FILE1   = "/home/lsq/Desktop/opu/multi/back_ok/rtl_inst/l128_core1/dram_0_data";
        localparam  INST_FILE2   = "";
        localparam  INST_FILE3   = "";
        localparam  INST_FILE4   = "";
`elsif INST_SEQLEN128_CORE2
        localparam  INST_OFFSET1 = 25'd1562712 ;localparam INST_START1 =1;
        localparam  INST_OFFSET2 = 25'd1562712 ;localparam INST_START2 =0;
        localparam  INST_OFFSET3 = 25'd1562712 ;localparam INST_START3 =0;
        localparam  INST_OFFSET4 = 25'd1562712 ;localparam INST_START4 =0;
        localparam  INST_FILE1   = "/home/lsq/Desktop/opu/multi/back_ok/rtl_inst/l128_core2/dram_0_data";
        localparam  INST_FILE2   = "/home/lsq/Desktop/opu/multi/back_ok/rtl_inst/l128_core2/dram_1_data";
        localparam  INST_FILE3   = "";  
        localparam  INST_FILE4   = "";
`elsif INST_SEQLEN128_CORE4
        localparam  INST_OFFSET1 = 25'd781404 ;localparam INST_START1 =1;
        localparam  INST_OFFSET2 = 25'd781404 ;localparam INST_START2 =0;
        localparam  INST_OFFSET3 = 25'd781404 ;localparam INST_START3 =0;
        localparam  INST_OFFSET4 = 25'd781404 ;localparam INST_START4 =0;
        localparam  INST_FILE1   = "/home/lsq/Desktop/opu/multi/back_ok/rtl_inst/l128_core4/dram_0_data";
        localparam  INST_FILE2   = "/home/lsq/Desktop/opu/multi/back_ok/rtl_inst/l128_core4/dram_1_data";
        localparam  INST_FILE3   = "/home/lsq/Desktop/opu/multi/back_ok/rtl_inst/l128_core4/dram_2_data";
        localparam  INST_FILE4   = "/home/lsq/Desktop/opu/multi/back_ok/rtl_inst/l128_core4/dram_3_data";
//------------------------------------------------------------------------------------------------------------
`elsif INST_SEQLEN224_CORE1
        localparam  INST_OFFSET1 = 25'd3732960 ;localparam INST_START1 =1;
        localparam  INST_OFFSET2 = 25'd3732960 ;localparam INST_START2 =0;
        localparam  INST_OFFSET3 = 25'd3732960 ;localparam INST_START3 =0;
        localparam  INST_OFFSET4 = 25'd3732960 ;localparam INST_START4 =0;
        localparam  INST_FILE1   = "/home/lsq/Desktop/opu/multi/back_ok/rtl_inst/l224_core1/dram_0_data";
        localparam  INST_FILE2   = "";
        localparam  INST_FILE3   = "";
        localparam  INST_FILE4   = "";
`elsif INST_SEQLEN224_CORE2
        localparam  INST_OFFSET1 = 25'd1866480 ;localparam INST_START1 =1;
        localparam  INST_OFFSET2 = 25'd1866480 ;localparam INST_START2 =0;
        localparam  INST_OFFSET3 = 25'd1866480 ;localparam INST_START3 =0;
        localparam  INST_OFFSET4 = 25'd1866480 ;localparam INST_START4 =0;
        localparam  INST_FILE1   = "/home/lsq/Desktop/opu/multi/back_ok/rtl_inst/l224_core2/dram_0_data";
        localparam  INST_FILE2   = "/home/lsq/Desktop/opu/multi/back_ok/rtl_inst/l224_core2/dram_1_data";
        localparam  INST_FILE3   = "";
        localparam  INST_FILE4   = "";
`elsif INST_SEQLEN224_CORE4
        localparam  INST_OFFSET1 = 25'd933240 ;localparam INST_START1 =1;
        localparam  INST_OFFSET2 = 25'd933240 ;localparam INST_START2 =0;
        localparam  INST_OFFSET3 = 25'd933240 ;localparam INST_START3 =0;
        localparam  INST_OFFSET4 = 25'd933240 ;localparam INST_START4 =0;
        localparam  INST_FILE1   = "/home/lsq/Desktop/opu/multi/back_ok/rtl_inst/l224_core4/dram_0_data";
        localparam  INST_FILE2   = "/home/lsq/Desktop/opu/multi/back_ok/rtl_inst/l224_core4/dram_1_data";
        localparam  INST_FILE3   = "/home/lsq/Desktop/opu/multi/back_ok/rtl_inst/l224_core4/dram_2_data";
        localparam  INST_FILE4   = "/home/lsq/Desktop/opu/multi/back_ok/rtl_inst/l224_core4/dram_3_data";
//------------------------------------------------------------------------------------------------------------
`elsif INST_SEQLEN256_CORE1
        localparam  INST_OFFSET1 = 25'd3718320 ;localparam INST_START1 =1;
        localparam  INST_OFFSET2 = 25'd3718320 ;localparam INST_START2 =0;
        localparam  INST_OFFSET3 = 25'd3718320 ;localparam INST_START3 =0;
        localparam  INST_OFFSET4 = 25'd3718320 ;localparam INST_START4 =0;
        localparam  INST_FILE1   = "/home/lsq/Desktop/opu/multi/back_ok/rtl_inst/l256_core1/dram_0_data";
        localparam  INST_FILE2   = "";
        localparam  INST_FILE3   = "";
        localparam  INST_FILE4   = "";
`elsif INST_SEQLEN256_CORE2
        localparam  INST_OFFSET1 = 25'd1859256 ;localparam INST_START1 =1;
        localparam  INST_OFFSET2 = 25'd1859256 ;localparam INST_START2 =0;
        localparam  INST_OFFSET3 = 25'd1859256 ;localparam INST_START3 =0;
        localparam  INST_OFFSET4 = 25'd1859256 ;localparam INST_START4 =0;
        localparam  INST_FILE1   ="/home/lsq/Desktop/opu/multi/back_ok/rtl_inst/l256_core2/dram_0_data";
        localparam  INST_FILE2   ="/home/lsq/Desktop/opu/multi/back_ok/rtl_inst/l256_core2/dram_1_data";
        localparam  INST_FILE3   ="";
        localparam  INST_FILE4   ="";
`elsif INST_SEQLEN256_CORE4
        localparam  INST_OFFSET1 = 25'd929724 ;localparam INST_START1 =1;
        localparam  INST_OFFSET2 = 25'd929724 ;localparam INST_START2 =0;
        localparam  INST_OFFSET3 = 25'd929724 ;localparam INST_START3 =0;
        localparam  INST_OFFSET4 = 25'd929724 ;localparam INST_START4 =0;
        localparam  INST_FILE1   ="/home/lsq/Desktop/opu/multi/back_ok/rtl_inst/l256_core4/dram_0_data";
        localparam  INST_FILE2   ="/home/lsq/Desktop/opu/multi/back_ok/rtl_inst/l256_core4/dram_1_data";
        localparam  INST_FILE3   ="/home/lsq/Desktop/opu/multi/back_ok/rtl_inst/l256_core4/dram_2_data";
        localparam  INST_FILE4   ="/home/lsq/Desktop/opu/multi/back_ok/rtl_inst/l256_core4/dram_3_data";
//------------------------------------------------------------------------------------------------------------
`elsif INST_SEQLEN512_CORE1
        localparam  INST_OFFSET1 = 25'd5346672 ;localparam INST_START1 =1;
        localparam  INST_OFFSET2 = 25'd5346672 ;localparam INST_START2 =0;
        localparam  INST_OFFSET3 = 25'd5346672 ;localparam INST_START3 =0;
        localparam  INST_OFFSET4 = 25'd5346672 ;localparam INST_START4 =0;
        localparam  INST_FILE1   ="/home/lsq/Desktop/opu/multi/back_ok/rtl_inst/l512_core1/dram_0_data";
        localparam  INST_FILE2   ="";
        localparam  INST_FILE3   ="";
        localparam  INST_FILE4   ="";
`elsif INST_SEQLEN512_CORE2
        localparam  INST_OFFSET1 = 25'd2673528 ;localparam INST_START1 =1;
        localparam  INST_OFFSET2 = 25'd2673528 ;localparam INST_START2 =0;
        localparam  INST_OFFSET3 = 25'd2673528 ;localparam INST_START3 =0;
        localparam  INST_OFFSET4 = 25'd2673528 ;localparam INST_START4 =0;
        localparam  INST_FILE1   ="/home/lsq/Desktop/opu/multi/back_ok/rtl_inst/l512_core2/dram_0_data";
        localparam  INST_FILE2   ="/home/lsq/Desktop/opu/multi/back_ok/rtl_inst/l512_core2/dram_1_data";
        localparam  INST_FILE3   ="";
        localparam  INST_FILE4   ="";
`elsif INST_SEQLEN512_CORE4
        localparam  INST_OFFSET1 = 25'd1336956 ;localparam INST_START1 =1;
        localparam  INST_OFFSET2 = 25'd1336956 ;localparam INST_START2 =0;
        localparam  INST_OFFSET3 = 25'd1336956 ;localparam INST_START3 =0;
        localparam  INST_OFFSET4 = 25'd1336956 ;localparam INST_START4 =0;
        localparam  INST_FILE1   ="/home/lsq/Desktop/opu/multi/back_ok/rtl_inst/l512_core4/dram_0_data";
        localparam  INST_FILE2   ="/home/lsq/Desktop/opu/multi/back_ok/rtl_inst/l512_core4/dram_1_data";
        localparam  INST_FILE3   ="/home/lsq/Desktop/opu/multi/back_ok/rtl_inst/l512_core4/dram_2_data";
        localparam  INST_FILE4   ="/home/lsq/Desktop/opu/multi/back_ok/rtl_inst/l512_core4/dram_3_data";
//------------------------------------------------------------------------------------------------------------
`elsif INST_SPARSE125_CORE4_D64
        localparam  INST_OFFSET1 = 25'd983100 ;localparam INST_START1 =1;
        localparam  INST_OFFSET2 = 25'd983100 ;localparam INST_START2 =0;
        localparam  INST_OFFSET3 = 25'd983100 ;localparam INST_START3 =0;
        localparam  INST_OFFSET4 = 25'd983100 ;localparam INST_START4 =0;
        localparam  INST_FILE1   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/dense/64/dram_0_data";
        localparam  INST_FILE2   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/dense/64/dram_1_data";
        localparam  INST_FILE3   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/dense/64/dram_2_data";
        localparam  INST_FILE4   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/dense/64/dram_3_data";
`elsif INST_SPARSE125_CORE4_D64_1
        localparam  INST_OFFSET1 = 25'd983100 ;localparam INST_START1 =1;
        localparam  INST_OFFSET2 = 25'd983100 ;localparam INST_START2 =0;
        localparam  INST_OFFSET3 = 25'd983100 ;localparam INST_START3 =0;
        localparam  INST_OFFSET4 = 25'd983100 ;localparam INST_START4 =0;
        localparam  INST_FILE1   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/dense/64_1/dram_0_data";
        localparam  INST_FILE2   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/dense/64_1/dram_1_data";
        localparam  INST_FILE3   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/dense/64_1/dram_2_data";
        localparam  INST_FILE4   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/dense/64_1/dram_3_data";
`elsif INST_SPARSE125_CORE4_D64_33
        localparam  INST_OFFSET1 = 25'd987707 ;localparam INST_START1 =1;
        localparam  INST_OFFSET2 = 25'd987707 ;localparam INST_START2 =0;
        localparam  INST_OFFSET3 = 25'd987707 ;localparam INST_START3 =0;
        localparam  INST_OFFSET4 = 25'd987707 ;localparam INST_START4 =0;
        localparam  INST_FILE1   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/dense/64_33/dram_0_data";
        localparam  INST_FILE2   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/dense/64_33/dram_1_data";
        localparam  INST_FILE3   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/dense/64_33/dram_2_data";
        localparam  INST_FILE4   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/dense/64_33/dram_3_data";
`elsif INST_SPARSE125_CORE4_D128
        localparam  INST_OFFSET1 = 25'd985788 ;localparam INST_START1 =1;
        localparam  INST_OFFSET2 = 25'd985788 ;localparam INST_START2 =0;
        localparam  INST_OFFSET3 = 25'd985788 ;localparam INST_START3 =0;
        localparam  INST_OFFSET4 = 25'd985788 ;localparam INST_START4 =0;
        localparam  INST_FILE1   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/dense/128/dram_0_data";
        localparam  INST_FILE2   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/dense/128/dram_1_data";
        localparam  INST_FILE3   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/dense/128/dram_2_data";
        localparam  INST_FILE4   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/dense/128/dram_3_data";
`elsif INST_SPARSE125_CORE4_D128_1
        localparam  INST_OFFSET1 = 25'd985788 ;localparam INST_START1 =1;
        localparam  INST_OFFSET2 = 25'd985788 ;localparam INST_START2 =0;
        localparam  INST_OFFSET3 = 25'd985788 ;localparam INST_START3 =0;
        localparam  INST_OFFSET4 = 25'd985788 ;localparam INST_START4 =0;
        localparam  INST_FILE1   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/dense/128_1/dram_0_data";
        localparam  INST_FILE2   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/dense/128_1/dram_1_data";
        localparam  INST_FILE3   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/dense/128_1/dram_2_data";
        localparam  INST_FILE4   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/dense/128_1/dram_3_data";
`elsif INST_SPARSE125_CORE4_D128_33
        localparam  INST_OFFSET1 = 25'd990395 ;localparam INST_START1 =1;
        localparam  INST_OFFSET2 = 25'd990395 ;localparam INST_START2 =0;
        localparam  INST_OFFSET3 = 25'd990395 ;localparam INST_START3 =0;
        localparam  INST_OFFSET4 = 25'd990395 ;localparam INST_START4 =0;
        localparam  INST_FILE1   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/dense/128_33/dram_0_data";
        localparam  INST_FILE2   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/dense/128_33/dram_1_data";
        localparam  INST_FILE3   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/dense/128_33/dram_2_data";
        localparam  INST_FILE4   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/dense/128_33/dram_3_data";
`elsif INST_SPARSE125_CORE4_D128_65
        localparam  INST_OFFSET1 = 25'd995003 ;localparam INST_START1 =1;
        localparam  INST_OFFSET2 = 25'd995003 ;localparam INST_START2 =0;
        localparam  INST_OFFSET3 = 25'd995003 ;localparam INST_START3 =0;
        localparam  INST_OFFSET4 = 25'd995003 ;localparam INST_START4 =0;
        localparam  INST_FILE1   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/dense/128_65/dram_0_data";
        localparam  INST_FILE2   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/dense/128_65/dram_1_data";
        localparam  INST_FILE3   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/dense/128_65/dram_2_data";
        localparam  INST_FILE4   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/dense/128_65/dram_3_data";
`elsif INST_SPARSE125_CORE4_D256
        localparam  INST_OFFSET1 = 25'd991164 ;localparam INST_START1 =1;
        localparam  INST_OFFSET2 = 25'd991164 ;localparam INST_START2 =0;
        localparam  INST_OFFSET3 = 25'd991164 ;localparam INST_START3 =0;
        localparam  INST_OFFSET4 = 25'd991164 ;localparam INST_START4 =0;
        localparam  INST_FILE1   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/dense/256/dram_0_data";
        localparam  INST_FILE2   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/dense/256/dram_1_data";
        localparam  INST_FILE3   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/dense/256/dram_2_data";
        localparam  INST_FILE4   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/dense/256/dram_3_data";
`elsif INST_SPARSE125_CORE4_D256_1
        localparam  INST_OFFSET1 = 25'd991164 ;localparam INST_START1 =1;
        localparam  INST_OFFSET2 = 25'd991164 ;localparam INST_START2 =0;
        localparam  INST_OFFSET3 = 25'd991164 ;localparam INST_START3 =0;
        localparam  INST_OFFSET4 = 25'd991164 ;localparam INST_START4 =0;
        localparam  INST_FILE1   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/dense/256_1/dram_0_data";
        localparam  INST_FILE2   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/dense/256_1/dram_1_data";
        localparam  INST_FILE3   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/dense/256_1/dram_2_data";
        localparam  INST_FILE4   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/dense/256_1/dram_3_data";
`elsif INST_SPARSE125_CORE4_D512
        localparam  INST_OFFSET1 = 25'd1014204 ;localparam INST_START1 =1;
        localparam  INST_OFFSET2 = 25'd1014204 ;localparam INST_START2 =0;
        localparam  INST_OFFSET3 = 25'd1014204 ;localparam INST_START3 =0;
        localparam  INST_OFFSET4 = 25'd1014204 ;localparam INST_START4 =0;
        localparam  INST_FILE1   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/dense/512/dram_0_data";
        localparam  INST_FILE2   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/dense/512/dram_1_data";
        localparam  INST_FILE3   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/dense/512/dram_2_data";
        localparam  INST_FILE4   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/dense/512/dram_3_data";
`elsif INST_SPARSE125_CORE4_D512_1
        localparam  INST_OFFSET1 = 25'd1014204 ;localparam INST_START1 =1;
        localparam  INST_OFFSET2 = 25'd1014204 ;localparam INST_START2 =0;
        localparam  INST_OFFSET3 = 25'd1014204 ;localparam INST_START3 =0;
        localparam  INST_OFFSET4 = 25'd1014204 ;localparam INST_START4 =0;
        localparam  INST_FILE1   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/dense/512_1/dram_0_data";
        localparam  INST_FILE2   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/dense/512_1/dram_1_data";
        localparam  INST_FILE3   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/dense/512_1/dram_2_data";
        localparam  INST_FILE4   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/dense/512_1/dram_3_data"; 
//----------------------------------------------------------------------------------------------------------------------
`elsif INST_SPARSE125_CORE4_2S64
        localparam  INST_OFFSET1 = 25'd692796 ;localparam INST_START1 =1;
        localparam  INST_OFFSET2 = 25'd692796 ;localparam INST_START2 =0;
        localparam  INST_OFFSET3 = 25'd692796 ;localparam INST_START3 =0;
        localparam  INST_OFFSET4 = 25'd692796 ;localparam INST_START4 =0;
        localparam  INST_FILE1   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/sparse2/64/dram_0_data";
        localparam  INST_FILE2   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/sparse2/64/dram_1_data";
        localparam  INST_FILE3   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/sparse2/64/dram_2_data";
        localparam  INST_FILE4   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/sparse2/64/dram_3_data";
`elsif INST_SPARSE125_CORE4_2S64_1
        localparam  INST_OFFSET1 = 25'd692796 ;localparam INST_START1 =1;
        localparam  INST_OFFSET2 = 25'd692796 ;localparam INST_START2 =0;
        localparam  INST_OFFSET3 = 25'd692796 ;localparam INST_START3 =0;
        localparam  INST_OFFSET4 = 25'd692796 ;localparam INST_START4 =0;
        localparam  INST_FILE1   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/sparse2/64_1/dram_0_data";
        localparam  INST_FILE2   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/sparse2/64_1/dram_1_data";
        localparam  INST_FILE3   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/sparse2/64_1/dram_2_data";
        localparam  INST_FILE4   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/sparse2/64_1/dram_3_data";
`elsif INST_SPARSE125_CORE4_2S64_33
        localparam  INST_OFFSET1 = 25'd697403 ;localparam INST_START1 =1;
        localparam  INST_OFFSET2 = 25'd697403 ;localparam INST_START2 =0;
        localparam  INST_OFFSET3 = 25'd697403 ;localparam INST_START3 =0;
        localparam  INST_OFFSET4 = 25'd697403 ;localparam INST_START4 =0;
        localparam  INST_FILE1   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/sparse2/64_33/dram_0_data";
        localparam  INST_FILE2   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/sparse2/64_33/dram_1_data";
        localparam  INST_FILE3   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/sparse2/64_33/dram_2_data";
        localparam  INST_FILE4   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/sparse2/64_33/dram_3_data";
`elsif INST_SPARSE125_CORE4_2S128
        localparam  INST_OFFSET1 = 25'd695484; localparam INST_START1 =1;
        localparam  INST_OFFSET2 = 25'd695484; localparam INST_START2 =0;
        localparam  INST_OFFSET3 = 25'd695484; localparam INST_START3 =0;
        localparam  INST_OFFSET4 = 25'd695484; localparam INST_START4 =0;
        localparam  INST_FILE1   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/sparse2/128/dram_0_data";
        localparam  INST_FILE2   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/sparse2/128/dram_1_data";
        localparam  INST_FILE3   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/sparse2/128/dram_2_data";
        localparam  INST_FILE4   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/sparse2/128/dram_3_data";
`elsif INST_SPARSE125_CORE4_2S128_1
        localparam  INST_OFFSET1 = 25'd695484; localparam INST_START1 =1;
        localparam  INST_OFFSET2 = 25'd695484; localparam INST_START2 =0;
        localparam  INST_OFFSET3 = 25'd695484; localparam INST_START3 =0;
        localparam  INST_OFFSET4 = 25'd695484; localparam INST_START4 =0;
        localparam  INST_FILE1   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/sparse2/128_1/dram_0_data";
        localparam  INST_FILE2   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/sparse2/128_1/dram_1_data";
        localparam  INST_FILE3   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/sparse2/128_1/dram_2_data";
        localparam  INST_FILE4   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/sparse2/128_1/dram_3_data";
`elsif INST_SPARSE125_CORE4_2S128_33
        localparam  INST_OFFSET1 = 25'd700091; localparam INST_START1 =1;
        localparam  INST_OFFSET2 = 25'd700091; localparam INST_START2 =0;
        localparam  INST_OFFSET3 = 25'd700091; localparam INST_START3 =0;
        localparam  INST_OFFSET4 = 25'd700091; localparam INST_START4 =0;
        localparam  INST_FILE1   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/sparse2/128_33/dram_0_data";
        localparam  INST_FILE2   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/sparse2/128_33/dram_1_data";
        localparam  INST_FILE3   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/sparse2/128_33/dram_2_data";
        localparam  INST_FILE4   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/sparse2/128_33/dram_3_data";
`elsif INST_SPARSE125_CORE4_2S128_65
        localparam  INST_OFFSET1 = 25'd704699; localparam INST_START1 =1;
        localparam  INST_OFFSET2 = 25'd704699; localparam INST_START2 =0;
        localparam  INST_OFFSET3 = 25'd704699; localparam INST_START3 =0;
        localparam  INST_OFFSET4 = 25'd704699; localparam INST_START4 =0;
        localparam  INST_FILE1   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/sparse2/128_65/dram_0_data";
        localparam  INST_FILE2   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/sparse2/128_65/dram_1_data";
        localparam  INST_FILE3   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/sparse2/128_65/dram_2_data";
        localparam  INST_FILE4   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/sparse2/128_65/dram_3_data";
`elsif INST_SPARSE125_CORE4_2S256
        localparam  INST_OFFSET1 = 25'd700860; localparam INST_START1 =1;
        localparam  INST_OFFSET2 = 25'd700860; localparam INST_START2 =0;
        localparam  INST_OFFSET3 = 25'd700860; localparam INST_START3 =0;
        localparam  INST_OFFSET4 = 25'd700860; localparam INST_START4 =0;
        localparam  INST_FILE1   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/sparse2/256/dram_0_data";
        localparam  INST_FILE2   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/sparse2/256/dram_1_data";
        localparam  INST_FILE3   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/sparse2/256/dram_2_data";
        localparam  INST_FILE4   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/sparse2/256/dram_3_data";
`elsif INST_SPARSE125_CORE4_2S256_1
        localparam  INST_OFFSET1 = 25'd700860; localparam INST_START1 =1;
        localparam  INST_OFFSET2 = 25'd700860; localparam INST_START2 =0;
        localparam  INST_OFFSET3 = 25'd700860; localparam INST_START3 =0;
        localparam  INST_OFFSET4 = 25'd700860; localparam INST_START4 =0;
        localparam  INST_FILE1   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/sparse2/256_1/dram_0_data";
        localparam  INST_FILE2   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/sparse2/256_1/dram_1_data";
        localparam  INST_FILE3   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/sparse2/256_1/dram_2_data";
        localparam  INST_FILE4   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/sparse2/256_1/dram_3_data";
`elsif INST_SPARSE125_CORE4_2S512
        localparam  INST_OFFSET1 = 25'd723900; localparam INST_START1 =1;
        localparam  INST_OFFSET2 = 25'd723900; localparam INST_START2 =0;
        localparam  INST_OFFSET3 = 25'd723900; localparam INST_START3 =0;
        localparam  INST_OFFSET4 = 25'd723900; localparam INST_START4 =0;
        localparam  INST_FILE1   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/sparse2/512/dram_0_data";
        localparam  INST_FILE2   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/sparse2/512/dram_1_data";
        localparam  INST_FILE3   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/sparse2/512/dram_2_data";
        localparam  INST_FILE4   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/sparse2/512/dram_3_data";
`elsif INST_SPARSE125_CORE4_2S512_1
        localparam  INST_OFFSET1 = 25'd723900; localparam INST_START1 =1;
        localparam  INST_OFFSET2 = 25'd723900; localparam INST_START2 =0;
        localparam  INST_OFFSET3 = 25'd723900; localparam INST_START3 =0;
        localparam  INST_OFFSET4 = 25'd723900; localparam INST_START4 =0;
        localparam  INST_FILE1   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/sparse2/512_1/dram_0_data";
        localparam  INST_FILE2   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/sparse2/512_1/dram_1_data";
        localparam  INST_FILE3   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/sparse2/512_1/dram_2_data";
        localparam  INST_FILE4   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/sparse2/512_1/dram_3_data";
//----------------------------------------------------------------------------------------------------------------------
`elsif INST_SPARSE125_CORE4_3S64
        localparam  INST_OFFSET1 = 25'd582204; localparam INST_START1 =1;
        localparam  INST_OFFSET2 = 25'd582204; localparam INST_START2 =0;
        localparam  INST_OFFSET3 = 25'd582204; localparam INST_START3 =0;
        localparam  INST_OFFSET4 = 25'd582204; localparam INST_START4 =0;
        localparam  INST_FILE1   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/sparse3/64/dram_0_data";
        localparam  INST_FILE2   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/sparse3/64/dram_1_data";
        localparam  INST_FILE3   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/sparse3/64/dram_2_data";
        localparam  INST_FILE4   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/sparse3/64/dram_3_data";
`elsif INST_SPARSE125_CORE4_3S64_1
        localparam  INST_OFFSET1 = 25'd582204; localparam INST_START1 =1;
        localparam  INST_OFFSET2 = 25'd582204; localparam INST_START2 =0;
        localparam  INST_OFFSET3 = 25'd582204; localparam INST_START3 =0;
        localparam  INST_OFFSET4 = 25'd582204; localparam INST_START4 =0;
        localparam  INST_FILE1   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/sparse3/64_1/dram_0_data";
        localparam  INST_FILE2   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/sparse3/64_1/dram_1_data";
        localparam  INST_FILE3   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/sparse3/64_1/dram_2_data";
        localparam  INST_FILE4   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/sparse3/64_1/dram_3_data";
`elsif INST_SPARSE125_CORE4_3S64_33
        localparam  INST_OFFSET1 = 25'd586811; localparam INST_START1 =1;
        localparam  INST_OFFSET2 = 25'd586811; localparam INST_START2 =0;
        localparam  INST_OFFSET3 = 25'd586811; localparam INST_START3 =0;
        localparam  INST_OFFSET4 = 25'd586811; localparam INST_START4 =0;
        localparam  INST_FILE1   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/sparse3/64_33/dram_0_data";
        localparam  INST_FILE2   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/sparse3/64_33/dram_1_data";
        localparam  INST_FILE3   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/sparse3/64_33/dram_2_data";
        localparam  INST_FILE4   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/sparse3/64_33/dram_3_data";
`elsif INST_SPARSE125_CORE4_3S128
        localparam  INST_OFFSET1 = 25'd584892; localparam INST_START1 =1;
        localparam  INST_OFFSET2 = 25'd584892; localparam INST_START2 =0;
        localparam  INST_OFFSET3 = 25'd584892; localparam INST_START3 =0;
        localparam  INST_OFFSET4 = 25'd584892; localparam INST_START4 =0;
        localparam  INST_FILE1   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/sparse3/128/dram_0_data";
        localparam  INST_FILE2   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/sparse3/128/dram_1_data";
        localparam  INST_FILE3   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/sparse3/128/dram_2_data";
        localparam  INST_FILE4   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/sparse3/128/dram_3_data";
`elsif INST_SPARSE125_CORE4_3S128_1
        localparam  INST_OFFSET1 = 25'd584892; localparam INST_START1 =1;
        localparam  INST_OFFSET2 = 25'd584892; localparam INST_START2 =0;
        localparam  INST_OFFSET3 = 25'd584892; localparam INST_START3 =0;
        localparam  INST_OFFSET4 = 25'd584892; localparam INST_START4 =0;
        localparam  INST_FILE1   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/sparse3/128_1/dram_0_data";
        localparam  INST_FILE2   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/sparse3/128_1/dram_1_data";
        localparam  INST_FILE3   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/sparse3/128_1/dram_2_data";
        localparam  INST_FILE4   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/sparse3/128_1/dram_3_data";
`elsif INST_SPARSE125_CORE4_3S128_33
        localparam  INST_OFFSET1 = 25'd589499; localparam INST_START1 =1;
        localparam  INST_OFFSET2 = 25'd589499; localparam INST_START2 =0;
        localparam  INST_OFFSET3 = 25'd589499; localparam INST_START3 =0;
        localparam  INST_OFFSET4 = 25'd589499; localparam INST_START4 =0;
        localparam  INST_FILE1   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/sparse3/128_33/dram_0_data";
        localparam  INST_FILE2   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/sparse3/128_33/dram_1_data";
        localparam  INST_FILE3   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/sparse3/128_33/dram_2_data";
        localparam  INST_FILE4   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/sparse3/128_33/dram_3_data";
`elsif INST_SPARSE125_CORE4_3S128_65
        localparam  INST_OFFSET1 = 25'd594107; localparam INST_START1 =1;
        localparam  INST_OFFSET2 = 25'd594107; localparam INST_START2 =0;
        localparam  INST_OFFSET3 = 25'd594107; localparam INST_START3 =0;
        localparam  INST_OFFSET4 = 25'd594107; localparam INST_START4 =0;
        localparam  INST_FILE1   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/sparse3/128_65/dram_0_data";
        localparam  INST_FILE2   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/sparse3/128_65/dram_1_data";
        localparam  INST_FILE3   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/sparse3/128_65/dram_2_data";
        localparam  INST_FILE4   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/sparse3/128_65/dram_3_data";
`elsif INST_SPARSE125_CORE4_3S256
        localparam  INST_OFFSET1 = 25'd590268; localparam INST_START1 =1;
        localparam  INST_OFFSET2 = 25'd590268; localparam INST_START2 =0;
        localparam  INST_OFFSET3 = 25'd590268; localparam INST_START3 =0;
        localparam  INST_OFFSET4 = 25'd590268; localparam INST_START4 =0;
        localparam  INST_FILE1   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/sparse3/256/dram_0_data";
        localparam  INST_FILE2   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/sparse3/256/dram_1_data";
        localparam  INST_FILE3   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/sparse3/256/dram_2_data";
        localparam  INST_FILE4   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/sparse3/256/dram_3_data";
`elsif INST_SPARSE125_CORE4_3S256_1
        localparam  INST_OFFSET1 = 25'd590268; localparam INST_START1 =1;
        localparam  INST_OFFSET2 = 25'd590268; localparam INST_START2 =0;
        localparam  INST_OFFSET3 = 25'd590268; localparam INST_START3 =0;
        localparam  INST_OFFSET4 = 25'd590268; localparam INST_START4 =0;
        localparam  INST_FILE1   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/sparse3/256_1/dram_0_data";
        localparam  INST_FILE2   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/sparse3/256_1/dram_1_data";
        localparam  INST_FILE3   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/sparse3/256_1/dram_2_data";
        localparam  INST_FILE4   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/sparse3/256_1/dram_3_data";
`elsif INST_SPARSE125_CORE4_3S512
        localparam  INST_OFFSET1 = 25'd613308; localparam INST_START1 =1;
        localparam  INST_OFFSET2 = 25'd613308; localparam INST_START2 =0;
        localparam  INST_OFFSET3 = 25'd613308; localparam INST_START3 =0;
        localparam  INST_OFFSET4 = 25'd613308; localparam INST_START4 =0;
        localparam  INST_FILE1   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/sparse3/512/dram_0_data";
        localparam  INST_FILE2   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/sparse3/512/dram_1_data";
        localparam  INST_FILE3   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/sparse3/512/dram_2_data";
        localparam  INST_FILE4   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/sparse3/512/dram_3_data";
`elsif INST_SPARSE125_CORE4_3S512_1
        localparam  INST_OFFSET1 = 25'd613308; localparam INST_START1 =1;
        localparam  INST_OFFSET2 = 25'd613308; localparam INST_START2 =0;
        localparam  INST_OFFSET3 = 25'd613308; localparam INST_START3 =0;
        localparam  INST_OFFSET4 = 25'd613308; localparam INST_START4 =0;
        localparam  INST_FILE1   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/sparse3/512_1/dram_0_data";
        localparam  INST_FILE2   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/sparse3/512_1/dram_1_data";
        localparam  INST_FILE3   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/sparse3/512_1/dram_2_data";
        localparam  INST_FILE4   ="/home/lsq/Desktop/opu/sparse/Compiler-Backend-master4/ins/sparse3/512_1/dram_3_data";

`elsif INST_SPARSE125_NEW_CORE4_2
        localparam  INST_OFFSET1 = 25'd366984; localparam INST_START1 =1;
        localparam  INST_OFFSET2 = 25'd366984; localparam INST_START2 =0;
        localparam  INST_OFFSET3 = 25'd366984; localparam INST_START3 =0;
        localparam  INST_OFFSET4 = 25'd366984; localparam INST_START4 =0;
        localparam  INST_FILE1   ="/home/lsq/Desktop/opu/complier/opt-n2m4-artifacts_core4_2/dram_0_data_merge";
        localparam  INST_FILE2   ="/home/lsq/Desktop/opu/complier/opt-n2m4-artifacts_core4_2/dram_1_data_merge";
        localparam  INST_FILE3   ="/home/lsq/Desktop/opu/complier/opt-n2m4-artifacts_core4_2/dram_2_data_merge";
        localparam  INST_FILE4   ="/home/lsq/Desktop/opu/complier/opt-n2m4-artifacts_core4_2/dram_3_data_merge";
`elsif INST_SPARSE125_NEW_CORE1_2
        `define     DEBUG_UTIL     "rtl_opt125m_core1_len64_sparse2_test"
        localparam  INST_OFFSET1 = 25'd1467168; localparam INST_START1 =1;
        localparam  INST_OFFSET2 = 25'd1467168; localparam INST_START2 =0;
        localparam  INST_OFFSET3 = 25'd1467168; localparam INST_START3 =0;
        localparam  INST_OFFSET4 = 25'd1467168; localparam INST_START4 =0;
        localparam  INST_FILE1   ="/home/lsq/Desktop/opu/complier/Compiler-Backend/opt-n2m4-artifacts/dram_0_data_merge";
        localparam  INST_FILE2   ="/home/lsq/Desktop/opu/complier/Compiler-Backend/opt-n2m4-artifacts/dram_0_data_merge";
        localparam  INST_FILE3   ="/home/lsq/Desktop/opu/complier/Compiler-Backend/opt-n2m4-artifacts/dram_0_data_merge";
        localparam  INST_FILE4   ="/home/lsq/Desktop/opu/complier/Compiler-Backend/opt-n2m4-artifacts/dram_0_data_merge";
`elsif INST_SPARSE350_CORE1_2
        localparam  INST_OFFSET1 = 25'd472448; localparam INST_START1 =1;
        localparam  INST_OFFSET2 = 25'd472448; localparam INST_START2 =0;
        localparam  INST_OFFSET3 = 25'd472448; localparam INST_START3 =0;
        localparam  INST_OFFSET4 = 25'd472448; localparam INST_START4 =0;
        localparam  INST_FILE1   ="/home/lsq/Desktop/opu/complier/Compiler-Backend-350m_8l/opt-350m-prefill-artifacts/dram_0_data_merge";
        localparam  INST_FILE2   ="/home/lsq/Desktop/opu/complier/Compiler-Backend-350m_8l/opt-350m-prefill-artifacts/dram_0_data_merge";
        localparam  INST_FILE3   ="/home/lsq/Desktop/opu/complier/Compiler-Backend-350m_8l/opt-350m-prefill-artifacts/dram_0_data_merge";
        localparam  INST_FILE4   ="/home/lsq/Desktop/opu/complier/Compiler-Backend-350m_8l/opt-350m-prefill-artifacts/dram_0_data_merge";
`elsif INST_SPARSE350_CORE1_2_gen1
        localparam  INST_OFFSET1 = 25'd226047; localparam INST_START1 =1;
        localparam  INST_OFFSET2 = 25'd226047; localparam INST_START2 =0;
        localparam  INST_OFFSET3 = 25'd226047; localparam INST_START3 =0;
        localparam  INST_OFFSET4 = 25'd226047; localparam INST_START4 =0;
        localparam  INST_FILE1   = "/home/lsq/Desktop/opu/complier/Compiler-Backend-master_810_1/opt-350m-gen-artifacts/dram_0_data_merge";
        localparam  INST_FILE2   = "/home/lsq/Desktop/opu/complier/Compiler-Backend-master_810_1/opt-350m-gen-artifacts/dram_0_data_merge";
        localparam  INST_FILE3   = "/home/lsq/Desktop/opu/complier/Compiler-Backend-master_810_1/opt-350m-gen-artifacts/dram_0_data_merge";
        localparam  INST_FILE4   = "/home/lsq/Desktop/opu/complier/Compiler-Backend-master_810_1/opt-350m-gen-artifacts/dram_0_data_merge";

//----------------------------------------------------------------------------------
//
//----------------------------------------------------------------------------------
`elsif INST_OPT350M_CORE1_LEN128_DENSE
        `define     DEBUG_UTIL     "rtl_opt350m_core1_len128_dense"
        localparam  INST_OFFSET1 = 25'd890240; localparam INST_START1 =1;
        localparam  INST_OFFSET2 = 25'd890240; localparam INST_START2 =0;
        localparam  INST_OFFSET3 = 25'd890240; localparam INST_START3 =0;
        localparam  INST_OFFSET4 = 25'd890240; localparam INST_START4 =0;
        localparam  INST_FILE1   ={"/home/lsq/Desktop/opu/complier/Compiler-Backend-master_810/inst/test_opt_350m_c128","/dram_0_data_merge"};
        localparam  INST_FILE2   ={""};
        localparam  INST_FILE3   ={""};
        localparam  INST_FILE4   ={""};
`elsif INST_OPT350M_CORE4_LEN128_DENSE
        `define     DEBUG_UTIL     "rtl_opt350m_core4_len128_dense"
        localparam  INST_OFFSET1 = 25'd222560; localparam INST_START1 =1;
        localparam  INST_OFFSET2 = 25'd222560; localparam INST_START2 =0;
        localparam  INST_OFFSET3 = 25'd222560; localparam INST_START3 =0;
        localparam  INST_OFFSET4 = 25'd222560; localparam INST_START4 =0;
        localparam  INST_FILE1   ={"/home/lsq/Desktop/opu/complier/Compiler-Backend-master_810/inst/test_opt_350m_c128_4core","/dram_0_data_merge"};
        localparam  INST_FILE2   ={"/home/lsq/Desktop/opu/complier/Compiler-Backend-master_810/inst/test_opt_350m_c128_4core","/dram_0_data_merge"};
        localparam  INST_FILE3   ={"/home/lsq/Desktop/opu/complier/Compiler-Backend-master_810/inst/test_opt_350m_c128_4core","/dram_0_data_merge"};
        localparam  INST_FILE4   ={"/home/lsq/Desktop/opu/complier/Compiler-Backend-master_810/inst/test_opt_350m_c128_4core","/dram_0_data_merge"};
//
`elsif INST_OPT350M_CORE1_LEN128_DENSE_OUT1
        `define     DEBUG_UTIL     "rtl_opt350m_core1_len128_dense_out1"
        localparam  INST_OFFSET1 = 25'd398079; localparam INST_START1 =1;
        localparam  INST_OFFSET2 = 25'd398079; localparam INST_START2 =0;
        localparam  INST_OFFSET3 = 25'd398079; localparam INST_START3 =0;
        localparam  INST_OFFSET4 = 25'd398079; localparam INST_START4 =0;
        localparam  INST_FILE1   ={"/home/lsq/Desktop/opu/complier/Compiler-Backend-master_810/inst/test_opt_350m_c128_o1","/dram_0_data_merge"};
        localparam  INST_FILE2   ={""};                                                                                                       
        localparam  INST_FILE3   ={""};                                                                                                       
        localparam  INST_FILE4   ={""};                                                                                                       
`elsif INST_OPT350M_CORE4_LEN128_DENSE_OUT1
        `define     DEBUG_UTIL     "rtl_opt350m_core4_len128_dense_out1"
        localparam  INST_OFFSET1 = 25'd99519; localparam INST_START1 =1;
        localparam  INST_OFFSET2 = 25'd99519; localparam INST_START2 =0;
        localparam  INST_OFFSET3 = 25'd99519; localparam INST_START3 =0;
        localparam  INST_OFFSET4 = 25'd99519; localparam INST_START4 =0;
        localparam  INST_FILE1   ={"/home/lsq/Desktop/opu/complier/Compiler-Backend-master_810/inst/test_opt_350m_c128_o1_4core","/dram_0_data_merge"};
        localparam  INST_FILE2   ={"/home/lsq/Desktop/opu/complier/Compiler-Backend-master_810/inst/test_opt_350m_c128_o1_4core","/dram_0_data_merge"};
        localparam  INST_FILE3   ={"/home/lsq/Desktop/opu/complier/Compiler-Backend-master_810/inst/test_opt_350m_c128_o1_4core","/dram_0_data_merge"};
        localparam  INST_FILE4   ={"/home/lsq/Desktop/opu/complier/Compiler-Backend-master_810/inst/test_opt_350m_c128_o1_4core","/dram_0_data_merge"};
//
`elsif INST_OPT350M_CORE1_LEN128_SPARSE2
        `define     DEBUG_UTIL     "rtl_opt350m_core1_len128_sparse2"
        localparam  INST_OFFSET1 = 25'd546176; localparam INST_START1 =1;
        localparam  INST_OFFSET2 = 25'd546176; localparam INST_START2 =0;
        localparam  INST_OFFSET3 = 25'd546176; localparam INST_START3 =0;
        localparam  INST_OFFSET4 = 25'd546176; localparam INST_START4 =0;
        localparam  INST_FILE1   ={"/home/lsq/Desktop/opu/complier/Compiler-Backend-master_810/inst/test_sparse_opt_350m_c128","/dram_0_data_merge"};
        localparam  INST_FILE2   ={""};                                                                                                       
        localparam  INST_FILE3   ={""};                                                                                                       
        localparam  INST_FILE4   ={""};                                                                                                       
`elsif INST_OPT350M_CORE4_LEN128_SPARSE2
        `define     DEBUG_UTIL     "rtl_opt350m_core4_len128_sparse2"
        localparam  INST_OFFSET1 = 25'd136544; localparam INST_START1 =1;
        localparam  INST_OFFSET2 = 25'd136544; localparam INST_START2 =0;
        localparam  INST_OFFSET3 = 25'd136544; localparam INST_START3 =0;
        localparam  INST_OFFSET4 = 25'd136544; localparam INST_START4 =0;
        localparam  INST_FILE1   ={"/home/lsq/Desktop/opu/complier/Compiler-Backend-master_810/inst/test_sparse_opt_350m_c128_4core","/dram_0_data_merge"};
        localparam  INST_FILE2   ={"/home/lsq/Desktop/opu/complier/Compiler-Backend-master_810/inst/test_sparse_opt_350m_c128_4core","/dram_0_data_merge"};
        localparam  INST_FILE3   ={"/home/lsq/Desktop/opu/complier/Compiler-Backend-master_810/inst/test_sparse_opt_350m_c128_4core","/dram_0_data_merge"};
        localparam  INST_FILE4   ={"/home/lsq/Desktop/opu/complier/Compiler-Backend-master_810/inst/test_sparse_opt_350m_c128_4core","/dram_0_data_merge"};
//
`elsif INST_OPT350M_CORE1_LEN128_SPARSE2_OUT1
        `define     DEBUG_UTIL     "rtl_opt350m_core1_len128_sparse2_out1"
        localparam  INST_OFFSET1 = 25'd226047; localparam INST_START1 =1;
        localparam  INST_OFFSET2 = 25'd226047; localparam INST_START2 =0;
        localparam  INST_OFFSET3 = 25'd226047; localparam INST_START3 =0;
        localparam  INST_OFFSET4 = 25'd226047; localparam INST_START4 =0;
        localparam  INST_FILE1   ={"/home/lsq/Desktop/opu/complier/Compiler-Backend-master_810/inst/test_sparse_opt_350m_c128_o1","/dram_0_data_merge"};
        localparam  INST_FILE2   ={""};                                                                                                       
        localparam  INST_FILE3   ={""};                                                                                                       
        localparam  INST_FILE4   ={""};                                                                                                       
`elsif INST_OPT350M_CORE4_LEN128_SPARSE2_OUT1
        `define     DEBUG_UTIL     "rtl_opt350m_core4_len128_sparse2_out1"
        localparam  INST_OFFSET1 = 25'd56511; localparam INST_START1 =1;
        localparam  INST_OFFSET2 = 25'd56511; localparam INST_START2 =0;
        localparam  INST_OFFSET3 = 25'd56511; localparam INST_START3 =0;
        localparam  INST_OFFSET4 = 25'd56511; localparam INST_START4 =0;
        localparam  INST_FILE1   ={"/home/lsq/Desktop/opu/complier/Compiler-Backend-master_810/inst/test_sparse_opt_350m_c128_o1_4core","/dram_0_data_merge"};
        localparam  INST_FILE2   ={"/home/lsq/Desktop/opu/complier/Compiler-Backend-master_810/inst/test_sparse_opt_350m_c128_o1_4core","/dram_0_data_merge"};
        localparam  INST_FILE3   ={"/home/lsq/Desktop/opu/complier/Compiler-Backend-master_810/inst/test_sparse_opt_350m_c128_o1_4core","/dram_0_data_merge"};
        localparam  INST_FILE4   ={"/home/lsq/Desktop/opu/complier/Compiler-Backend-master_810/inst/test_sparse_opt_350m_c128_o1_4core","/dram_0_data_merge"};
//
`elsif INST_OPT125M_CORE1_LEN64_SPARSE2
        `define     DEBUG_UTIL     "rtl_opt125m_core1_len64_sparse2"
        localparam  INST_OFFSET1 = 25'd1491768; localparam INST_START1 =1;
        localparam  INST_OFFSET2 = 25'd1491768; localparam INST_START2 =0;
        localparam  INST_OFFSET3 = 25'd1491768; localparam INST_START3 =0;
        localparam  INST_OFFSET4 = 25'd1491768; localparam INST_START4 =0;
        localparam  INST_FILE1   ={"/home/lsq/Desktop/opu/complier/Compiler-Backend-master_810/inst/test_sparse_opt_125m_8l","/dram_0_data_merge"};
        localparam  INST_FILE2   ={"","/dram_0_data_merge"};
        localparam  INST_FILE3   ={"","/dram_0_data_merge"};
        localparam  INST_FILE4   ={"","/dram_0_data_merge"};
`elsif INST_OPT125M_CORE4_LEN64_SPARSE2
        `define     DEBUG_UTIL     "rtl_opt125m_core4_len64_sparse2"
        localparam  INST_OFFSET1 = 25'd373134; localparam INST_START1 =1;
        localparam  INST_OFFSET2 = 25'd373134; localparam INST_START2 =0;
        localparam  INST_OFFSET3 = 25'd373134; localparam INST_START3 =0;
        localparam  INST_OFFSET4 = 25'd373134; localparam INST_START4 =0;
        localparam  INST_FILE1   ={"/home/lsq/Desktop/opu/complier/Compiler-Backend-master_810/inst/test_sparse_opt_125m_8l_4core","/dram_0_data_merge"};
        localparam  INST_FILE2   ={"","/dram_0_data_merge"};
        localparam  INST_FILE3   ={"","/dram_0_data_merge"};
        localparam  INST_FILE4   ={"","/dram_0_data_merge"};




        
//------------------------------------------------------------------------------------------------------------
`endif//INST
`endif//OPU_PARAMETER