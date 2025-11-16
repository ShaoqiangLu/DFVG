
#-----------------------------------------------------------------------------------
#U200 SPI Bitstream Configuration Setting
#Flash model  mt25qu01g-spi-x1_x2_x4
#start address 0x01002000
#-----------------------------------------------------------------------------------
set_property CONFIG_MODE SPIx4 [current_design]
set_property CONFIG_VOLTAGE 1.8 [current_design]
set_property BITSTREAM.CONFIG.CONFIGFALLBACK Enable [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 85.0 [current_design]
set_property BITSTREAM.CONFIG.EXTMASTERCCLK_EN disable [current_design]
set_property BITSTREAM.CONFIG.SPI_FALL_EDGE YES [current_design]
set_property BITSTREAM.CONFIG.UNUSEDPIN Pullup [current_design]
set_property BITSTREAM.CONFIG.SPI_32BIT_ADDR Yes [current_design]
#-----------------------------------------------------------------------------------

#-----------------------------------------------------------------------------------
# Binding of FPGA regions
#-----------------------------------------------------------------------------------
#create_pblock OPU0
#add_cells_to_pblock [get_pblocks OPU0] [get_cells -quiet [list MIG0]]
#resize_pblock [get_pblocks OPU0] -add {CLOCKREGION_X0Y0:CLOCKREGION_X5Y4}
#set_property IS_SOFT FALSE [get_pblocks OPU0]

#create_pblock OPU1
#add_cells_to_pblock [get_pblocks OPU1] [get_cells -quiet [list MIG1 MIG2]]
#resize_pblock [get_pblocks OPU1] -add {CLOCKREGION_X0Y5:CLOCKREGION_X5Y9}
#set_property IS_SOFT FALSE [get_pblocks OPU1]


#create_pblock OPU2
#add_cells_to_pblock [get_pblocks OPU2] [get_cells -quiet [list MIG3]]
#resize_pblock [get_pblocks OPU2] -add {CLOCKREGION_X0Y10:CLOCKREGION_X5Y14}
#set_property IS_SOFT FALSE [get_pblocks OPU2]


#set_property USER_SLR_ASSIGNMENT SLR0 [get_cells {CORE_TOP1/u0_ifm_top CORE_TOP1/u0_ker_top CORE_TOP1/u0_nvm_top CORE_TOP1/u0_ofm_top CORE_TOP1/u0_pe_top}]
#set_property USER_SLR_ASSIGNMENT SLR1 [get_cells {AXI_M2S3 MIG1 MIG2 PCIE_TOP CORE_TOP1/u0_bias_top CORE_TOP1/u0_ddr_top CORE_TOP1/u0_div_top CORE_TOP1/u0_inst_top CORE_TOP2/u0_bias_top CORE_TOP2/u0_ddr_top CORE_TOP2/u0_div_top CORE_TOP2/u0_inst_top }]
#set_property USER_SLR_ASSIGNMENT SLR2 [get_cells {CORE_TOP2/u0_ifm_top CORE_TOP2/u0_ker_top CORE_TOP2/u0_nvm_top CORE_TOP2/u0_ofm_top CORE_TOP2/u0_pe_top u_ILA}]


#-------------------------------------------------------------------------------------------------------------------
# DDR4 RDIMM Controller 0, 72-bit Data Interface, x4 Componets, Single Rank
#     <<<NOTE>>> DQS Clock strobes have been swapped from JEDEC standard to match Xilinx MIG Clock order:
#                JEDEC Order   DQS ->  0  9  1 10  2 11  3 12  4 13  5 14  6 15  7 16  8 17
#                Xil MIG Order DQS ->  0  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17
#-------------------------------------------------------------------------------------------------------------------
set_property -dict {PACKAGE_PIN AT36 IOSTANDARD SSTL12_DCI} [get_ports {c0_ddr4_adr[0]}]
set_property -dict {PACKAGE_PIN AV36 IOSTANDARD SSTL12_DCI} [get_ports {c0_ddr4_adr[1]}]
set_property -dict {PACKAGE_PIN AV37 IOSTANDARD SSTL12_DCI} [get_ports {c0_ddr4_adr[2]}]
set_property -dict {PACKAGE_PIN AW35 IOSTANDARD SSTL12_DCI} [get_ports {c0_ddr4_adr[3]}]
set_property -dict {PACKAGE_PIN AW36 IOSTANDARD SSTL12_DCI} [get_ports {c0_ddr4_adr[4]}]
set_property -dict {PACKAGE_PIN AY36 IOSTANDARD SSTL12_DCI} [get_ports {c0_ddr4_adr[5]}]
set_property -dict {PACKAGE_PIN AY35 IOSTANDARD SSTL12_DCI} [get_ports {c0_ddr4_adr[6]}]
set_property -dict {PACKAGE_PIN BA40 IOSTANDARD SSTL12_DCI} [get_ports {c0_ddr4_adr[7]}]
set_property -dict {PACKAGE_PIN BA37 IOSTANDARD SSTL12_DCI} [get_ports {c0_ddr4_adr[8]}]
set_property -dict {PACKAGE_PIN BB37 IOSTANDARD SSTL12_DCI} [get_ports {c0_ddr4_adr[9]}]
set_property -dict {PACKAGE_PIN AR35 IOSTANDARD SSTL12_DCI} [get_ports {c0_ddr4_adr[10]}]
set_property -dict {PACKAGE_PIN BA39 IOSTANDARD SSTL12_DCI} [get_ports {c0_ddr4_adr[11]}]
set_property -dict {PACKAGE_PIN BB40 IOSTANDARD SSTL12_DCI} [get_ports {c0_ddr4_adr[12]}]
set_property -dict {PACKAGE_PIN AN36 IOSTANDARD SSTL12_DCI} [get_ports {c0_ddr4_adr[13]}]
set_property -dict {PACKAGE_PIN AP35 IOSTANDARD SSTL12_DCI} [get_ports {c0_ddr4_adr[14]}]
set_property -dict {PACKAGE_PIN AP36 IOSTANDARD SSTL12_DCI} [get_ports {c0_ddr4_adr[15]}]
set_property -dict {PACKAGE_PIN AR36 IOSTANDARD SSTL12_DCI} [get_ports {c0_ddr4_adr[16]}]
set_property -dict {PACKAGE_PIN AU31 IOSTANDARD LVCMOS12} [get_ports c0_ddr4_reset_n]
set_property -dict {PACKAGE_PIN AR33 IOSTANDARD SSTL12_DCI} [get_ports c0_ddr4_cs_n]
set_property -dict {PACKAGE_PIN AP34 IOSTANDARD SSTL12_DCI} [get_ports c0_ddr4_odt]
set_property -dict {PACKAGE_PIN AT35 IOSTANDARD SSTL12_DCI} [get_ports {c0_ddr4_ba[0]}]
set_property -dict {PACKAGE_PIN AT34 IOSTANDARD SSTL12_DCI} [get_ports {c0_ddr4_ba[1]}]
set_property -dict {PACKAGE_PIN BC39 IOSTANDARD SSTL12_DCI} [get_ports {c0_ddr4_bg[1]}]
set_property -dict {PACKAGE_PIN BC37 IOSTANDARD SSTL12_DCI} [get_ports {c0_ddr4_bg[0]}]
set_property -dict {PACKAGE_PIN AW38 IOSTANDARD DIFF_SSTL12_DCI} [get_ports c0_ddr4_ck_c]
set_property -dict {PACKAGE_PIN AV38 IOSTANDARD DIFF_SSTL12_DCI} [get_ports c0_ddr4_ck_t]
set_property -dict {PACKAGE_PIN AU36 IOSTANDARD SSTL12_DCI} [get_ports c0_ddr4_parity]
set_property -dict {PACKAGE_PIN BB39 IOSTANDARD SSTL12_DCI} [get_ports c0_ddr4_act_n]
set_property -dict {PACKAGE_PIN BC38 IOSTANDARD SSTL12_DCI} [get_ports c0_ddr4_cke]
set_property -dict {PACKAGE_PIN BF43 IOSTANDARD POD12_DCI} [get_ports {c0_ddr4_dq[66]}]
set_property -dict {PACKAGE_PIN BF42 IOSTANDARD POD12_DCI} [get_ports {c0_ddr4_dq[67]}]
set_property -dict {PACKAGE_PIN BF38 IOSTANDARD DIFF_POD12_DCI} [get_ports {c0_ddr4_dqs_c[16]}]
set_property -dict {PACKAGE_PIN BE38 IOSTANDARD DIFF_POD12_DCI} [get_ports {c0_ddr4_dqs_t[16]}]
set_property -dict {PACKAGE_PIN BD40 IOSTANDARD POD12_DCI} [get_ports {c0_ddr4_dq[64]}]
set_property -dict {PACKAGE_PIN BD39 IOSTANDARD POD12_DCI} [get_ports {c0_ddr4_dq[65]}]
set_property -dict {PACKAGE_PIN BF41 IOSTANDARD POD12_DCI} [get_ports {c0_ddr4_dq[71]}]
set_property -dict {PACKAGE_PIN BE40 IOSTANDARD POD12_DCI} [get_ports {c0_ddr4_dq[70]}]
set_property -dict {PACKAGE_PIN BF37 IOSTANDARD POD12_DCI} [get_ports {c0_ddr4_dq[68]}]
set_property -dict {PACKAGE_PIN BE37 IOSTANDARD POD12_DCI} [get_ports {c0_ddr4_dq[69]}]
set_property -dict {PACKAGE_PIN BF40 IOSTANDARD DIFF_POD12_DCI} [get_ports {c0_ddr4_dqs_c[17]}]
set_property -dict {PACKAGE_PIN BF39 IOSTANDARD DIFF_POD12_DCI} [get_ports {c0_ddr4_dqs_t[17]}]
set_property -dict {PACKAGE_PIN AU32 IOSTANDARD POD12_DCI} [get_ports {c0_ddr4_dq[34]}]
set_property -dict {PACKAGE_PIN AT32 IOSTANDARD POD12_DCI} [get_ports {c0_ddr4_dq[35]}]
set_property -dict {PACKAGE_PIN AM32 IOSTANDARD DIFF_POD12_DCI} [get_ports {c0_ddr4_dqs_c[8]}]
set_property -dict {PACKAGE_PIN AM31 IOSTANDARD DIFF_POD12_DCI} [get_ports {c0_ddr4_dqs_t[8]}]
set_property -dict {PACKAGE_PIN AM30 IOSTANDARD POD12_DCI} [get_ports {c0_ddr4_dq[33]}]
set_property -dict {PACKAGE_PIN AL30 IOSTANDARD POD12_DCI} [get_ports {c0_ddr4_dq[32]}]
set_property -dict {PACKAGE_PIN AR32 IOSTANDARD POD12_DCI} [get_ports {c0_ddr4_dq[38]}]
set_property -dict {PACKAGE_PIN AR31 IOSTANDARD POD12_DCI} [get_ports {c0_ddr4_dq[39]}]
set_property -dict {PACKAGE_PIN AN32 IOSTANDARD POD12_DCI} [get_ports {c0_ddr4_dq[37]}]
set_property -dict {PACKAGE_PIN AN31 IOSTANDARD POD12_DCI} [get_ports {c0_ddr4_dq[36]}]
set_property -dict {PACKAGE_PIN AP31 IOSTANDARD DIFF_POD12_DCI} [get_ports {c0_ddr4_dqs_c[9]}]
set_property -dict {PACKAGE_PIN AP30 IOSTANDARD DIFF_POD12_DCI} [get_ports {c0_ddr4_dqs_t[9]}]
set_property -dict {PACKAGE_PIN AV32 IOSTANDARD POD12_DCI} [get_ports {c0_ddr4_dq[25]}]
set_property -dict {PACKAGE_PIN AV31 IOSTANDARD POD12_DCI} [get_ports {c0_ddr4_dq[24]}]
set_property -dict {PACKAGE_PIN AW33 IOSTANDARD DIFF_POD12_DCI} [get_ports {c0_ddr4_dqs_c[6]}]
set_property -dict {PACKAGE_PIN AV33 IOSTANDARD DIFF_POD12_DCI} [get_ports {c0_ddr4_dqs_t[6]}]
set_property -dict {PACKAGE_PIN AW34 IOSTANDARD POD12_DCI} [get_ports {c0_ddr4_dq[27]}]
set_property -dict {PACKAGE_PIN AV34 IOSTANDARD POD12_DCI} [get_ports {c0_ddr4_dq[26]}]
set_property -dict {PACKAGE_PIN AY31 IOSTANDARD POD12_DCI} [get_ports {c0_ddr4_dq[29]}]
set_property -dict {PACKAGE_PIN AW31 IOSTANDARD POD12_DCI} [get_ports {c0_ddr4_dq[28]}]
set_property -dict {PACKAGE_PIN BA35 IOSTANDARD POD12_DCI} [get_ports {c0_ddr4_dq[30]}]
set_property -dict {PACKAGE_PIN BA34 IOSTANDARD POD12_DCI} [get_ports {c0_ddr4_dq[31]}]
set_property -dict {PACKAGE_PIN BA33 IOSTANDARD DIFF_POD12_DCI} [get_ports {c0_ddr4_dqs_c[7]}]
set_property -dict {PACKAGE_PIN BA32 IOSTANDARD DIFF_POD12_DCI} [get_ports {c0_ddr4_dqs_t[7]}]
set_property -dict {PACKAGE_PIN BB32 IOSTANDARD POD12_DCI} [get_ports {c0_ddr4_dq[17]}]
set_property -dict {PACKAGE_PIN BB31 IOSTANDARD POD12_DCI} [get_ports {c0_ddr4_dq[16]}]
set_property -dict {PACKAGE_PIN BB36 IOSTANDARD DIFF_POD12_DCI} [get_ports {c0_ddr4_dqs_c[4]}]
set_property -dict {PACKAGE_PIN BB35 IOSTANDARD DIFF_POD12_DCI} [get_ports {c0_ddr4_dqs_t[4]}]
set_property -dict {PACKAGE_PIN AY33 IOSTANDARD POD12_DCI} [get_ports {c0_ddr4_dq[19]}]
set_property -dict {PACKAGE_PIN AY32 IOSTANDARD POD12_DCI} [get_ports {c0_ddr4_dq[18]}]
set_property -dict {PACKAGE_PIN BC33 IOSTANDARD POD12_DCI} [get_ports {c0_ddr4_dq[21]}]
set_property -dict {PACKAGE_PIN BC32 IOSTANDARD POD12_DCI} [get_ports {c0_ddr4_dq[20]}]
set_property -dict {PACKAGE_PIN BC34 IOSTANDARD POD12_DCI} [get_ports {c0_ddr4_dq[23]}]
set_property -dict {PACKAGE_PIN BB34 IOSTANDARD POD12_DCI} [get_ports {c0_ddr4_dq[22]}]
set_property -dict {PACKAGE_PIN BD31 IOSTANDARD DIFF_POD12_DCI} [get_ports {c0_ddr4_dqs_c[5]}]
set_property -dict {PACKAGE_PIN BC31 IOSTANDARD DIFF_POD12_DCI} [get_ports {c0_ddr4_dqs_t[5]}]
set_property -dict {PACKAGE_PIN BE33 IOSTANDARD POD12_DCI} [get_ports {c0_ddr4_dq[58]}]
set_property -dict {PACKAGE_PIN BD33 IOSTANDARD POD12_DCI} [get_ports {c0_ddr4_dq[57]}]
set_property -dict {PACKAGE_PIN BE36 IOSTANDARD DIFF_POD12_DCI} [get_ports {c0_ddr4_dqs_c[14]}]
set_property -dict {PACKAGE_PIN BE35 IOSTANDARD DIFF_POD12_DCI} [get_ports {c0_ddr4_dqs_t[14]}]
set_property -dict {PACKAGE_PIN BD35 IOSTANDARD POD12_DCI} [get_ports {c0_ddr4_dq[59]}]
set_property -dict {PACKAGE_PIN BD34 IOSTANDARD POD12_DCI} [get_ports {c0_ddr4_dq[56]}]
set_property -dict {PACKAGE_PIN BF33 IOSTANDARD POD12_DCI} [get_ports {c0_ddr4_dq[61]}]
set_property -dict {PACKAGE_PIN BF32 IOSTANDARD POD12_DCI} [get_ports {c0_ddr4_dq[60]}]
set_property -dict {PACKAGE_PIN BF35 IOSTANDARD POD12_DCI} [get_ports {c0_ddr4_dq[63]}]
set_property -dict {PACKAGE_PIN BF34 IOSTANDARD POD12_DCI} [get_ports {c0_ddr4_dq[62]}]
set_property -dict {PACKAGE_PIN BE32 IOSTANDARD DIFF_POD12_DCI} [get_ports {c0_ddr4_dqs_c[15]}]
set_property -dict {PACKAGE_PIN BE31 IOSTANDARD DIFF_POD12_DCI} [get_ports {c0_ddr4_dqs_t[15]}]
set_property -dict {PACKAGE_PIN AP29 IOSTANDARD POD12_DCI} [get_ports {c0_ddr4_dq[40]}]
set_property -dict {PACKAGE_PIN AP28 IOSTANDARD POD12_DCI} [get_ports {c0_ddr4_dq[41]}]
set_property -dict {PACKAGE_PIN AL29 IOSTANDARD DIFF_POD12_DCI} [get_ports {c0_ddr4_dqs_c[10]}]
set_property -dict {PACKAGE_PIN AL28 IOSTANDARD DIFF_POD12_DCI} [get_ports {c0_ddr4_dqs_t[10]}]
set_property -dict {PACKAGE_PIN AN27 IOSTANDARD POD12_DCI} [get_ports {c0_ddr4_dq[42]}]
set_property -dict {PACKAGE_PIN AM27 IOSTANDARD POD12_DCI} [get_ports {c0_ddr4_dq[43]}]
set_property -dict {PACKAGE_PIN AR28 IOSTANDARD POD12_DCI} [get_ports {c0_ddr4_dq[47]}]
set_property -dict {PACKAGE_PIN AR27 IOSTANDARD POD12_DCI} [get_ports {c0_ddr4_dq[46]}]
set_property -dict {PACKAGE_PIN AN29 IOSTANDARD POD12_DCI} [get_ports {c0_ddr4_dq[44]}]
set_property -dict {PACKAGE_PIN AM29 IOSTANDARD POD12_DCI} [get_ports {c0_ddr4_dq[45]}]
set_property -dict {PACKAGE_PIN AT30 IOSTANDARD DIFF_POD12_DCI} [get_ports {c0_ddr4_dqs_c[11]}]
set_property -dict {PACKAGE_PIN AR30 IOSTANDARD DIFF_POD12_DCI} [get_ports {c0_ddr4_dqs_t[11]}]
set_property -dict {PACKAGE_PIN AV27 IOSTANDARD POD12_DCI} [get_ports {c0_ddr4_dq[49]}]
set_property -dict {PACKAGE_PIN AU27 IOSTANDARD POD12_DCI} [get_ports {c0_ddr4_dq[50]}]
set_property -dict {PACKAGE_PIN AU30 IOSTANDARD DIFF_POD12_DCI} [get_ports {c0_ddr4_dqs_c[12]}]
set_property -dict {PACKAGE_PIN AU29 IOSTANDARD DIFF_POD12_DCI} [get_ports {c0_ddr4_dqs_t[12]}]
set_property -dict {PACKAGE_PIN AT28 IOSTANDARD POD12_DCI} [get_ports {c0_ddr4_dq[48]}]
set_property -dict {PACKAGE_PIN AT27 IOSTANDARD POD12_DCI} [get_ports {c0_ddr4_dq[51]}]
set_property -dict {PACKAGE_PIN AV29 IOSTANDARD POD12_DCI} [get_ports {c0_ddr4_dq[52]}]
set_property -dict {PACKAGE_PIN AV28 IOSTANDARD POD12_DCI} [get_ports {c0_ddr4_dq[55]}]
set_property -dict {PACKAGE_PIN AY30 IOSTANDARD POD12_DCI} [get_ports {c0_ddr4_dq[53]}]
set_property -dict {PACKAGE_PIN AW30 IOSTANDARD POD12_DCI} [get_ports {c0_ddr4_dq[54]}]
set_property -dict {PACKAGE_PIN AY28 IOSTANDARD DIFF_POD12_DCI} [get_ports {c0_ddr4_dqs_c[13]}]
set_property -dict {PACKAGE_PIN AY27 IOSTANDARD DIFF_POD12_DCI} [get_ports {c0_ddr4_dqs_t[13]}]
set_property -dict {PACKAGE_PIN BA28 IOSTANDARD POD12_DCI} [get_ports {c0_ddr4_dq[2]}]
set_property -dict {PACKAGE_PIN BA27 IOSTANDARD POD12_DCI} [get_ports {c0_ddr4_dq[3]}]
set_property -dict {PACKAGE_PIN BB30 IOSTANDARD DIFF_POD12_DCI} [get_ports {c0_ddr4_dqs_c[0]}]
set_property -dict {PACKAGE_PIN BA30 IOSTANDARD DIFF_POD12_DCI} [get_ports {c0_ddr4_dqs_t[0]}]
set_property -dict {PACKAGE_PIN AW29 IOSTANDARD POD12_DCI} [get_ports {c0_ddr4_dq[1]}]
set_property -dict {PACKAGE_PIN AW28 IOSTANDARD POD12_DCI} [get_ports {c0_ddr4_dq[0]}]
set_property -dict {PACKAGE_PIN BC27 IOSTANDARD POD12_DCI} [get_ports {c0_ddr4_dq[6]}]
set_property -dict {PACKAGE_PIN BB27 IOSTANDARD POD12_DCI} [get_ports {c0_ddr4_dq[7]}]
set_property -dict {PACKAGE_PIN BB29 IOSTANDARD POD12_DCI} [get_ports {c0_ddr4_dq[4]}]
set_property -dict {PACKAGE_PIN BA29 IOSTANDARD POD12_DCI} [get_ports {c0_ddr4_dq[5]}]
set_property -dict {PACKAGE_PIN BC26 IOSTANDARD DIFF_POD12_DCI} [get_ports {c0_ddr4_dqs_c[1]}]
set_property -dict {PACKAGE_PIN BB26 IOSTANDARD DIFF_POD12_DCI} [get_ports {c0_ddr4_dqs_t[1]}]
set_property -dict {PACKAGE_PIN BF28 IOSTANDARD POD12_DCI} [get_ports {c0_ddr4_dq[9]}]
set_property -dict {PACKAGE_PIN BE28 IOSTANDARD POD12_DCI} [get_ports {c0_ddr4_dq[8]}]
set_property -dict {PACKAGE_PIN BD29 IOSTANDARD DIFF_POD12_DCI} [get_ports {c0_ddr4_dqs_c[2]}]
set_property -dict {PACKAGE_PIN BD28 IOSTANDARD DIFF_POD12_DCI} [get_ports {c0_ddr4_dqs_t[2]}]
set_property -dict {PACKAGE_PIN BE30 IOSTANDARD POD12_DCI} [get_ports {c0_ddr4_dq[10]}]
set_property -dict {PACKAGE_PIN BD30 IOSTANDARD POD12_DCI} [get_ports {c0_ddr4_dq[11]}]
set_property -dict {PACKAGE_PIN BF27 IOSTANDARD POD12_DCI} [get_ports {c0_ddr4_dq[12]}]
set_property -dict {PACKAGE_PIN BE27 IOSTANDARD POD12_DCI} [get_ports {c0_ddr4_dq[13]}]
set_property -dict {PACKAGE_PIN BF30 IOSTANDARD POD12_DCI} [get_ports {c0_ddr4_dq[14]}]
set_property -dict {PACKAGE_PIN BF29 IOSTANDARD POD12_DCI} [get_ports {c0_ddr4_dq[15]}]
set_property -dict {PACKAGE_PIN BE26 IOSTANDARD DIFF_POD12_DCI} [get_ports {c0_ddr4_dqs_c[3]}]
set_property -dict {PACKAGE_PIN BD26 IOSTANDARD DIFF_POD12_DCI} [get_ports {c0_ddr4_dqs_t[3]}]



#-------------------------------------------------------------------------------------------------------------------
# DDR4 RDIMM Controller 1, 72-bit Data Interface, x4 Componets, Single Rank
#     <<<NOTE>>> DQS Clock strobes have been swapped from JEDEC standard to match Xilinx MIG Clock order:
#                JEDEC Order   DQS ->  0  9  1 10  2 11  3 12  4 13  5 14  6 15  7 16  8 17
#                Xil MIG Order DQS ->  0  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17
#-------------------------------------------------------------------------------------------------------------------
#set_property -dict {PACKAGE_PIN AW25 IOSTANDARD SSTL12_DCI} [get_ports c1_ddr4_act_n]
#set_property -dict {PACKAGE_PIN AN24 IOSTANDARD SSTL12_DCI} [get_ports {c1_ddr4_adr[0]}]
#set_property -dict {PACKAGE_PIN AT24 IOSTANDARD SSTL12_DCI} [get_ports {c1_ddr4_adr[1]}]
#set_property -dict {PACKAGE_PIN AW24 IOSTANDARD SSTL12_DCI} [get_ports {c1_ddr4_adr[2]}]
#set_property -dict {PACKAGE_PIN AN26 IOSTANDARD SSTL12_DCI} [get_ports {c1_ddr4_adr[3]}]
#set_property -dict {PACKAGE_PIN AY22 IOSTANDARD SSTL12_DCI} [get_ports {c1_ddr4_adr[4]}]
#set_property -dict {PACKAGE_PIN AY23 IOSTANDARD SSTL12_DCI} [get_ports {c1_ddr4_adr[5]}]
#set_property -dict {PACKAGE_PIN AV24 IOSTANDARD SSTL12_DCI} [get_ports {c1_ddr4_adr[6]}]
#set_property -dict {PACKAGE_PIN BA22 IOSTANDARD SSTL12_DCI} [get_ports {c1_ddr4_adr[7]}]
#set_property -dict {PACKAGE_PIN AY25 IOSTANDARD SSTL12_DCI} [get_ports {c1_ddr4_adr[8]}]
#set_property -dict {PACKAGE_PIN BA23 IOSTANDARD SSTL12_DCI} [get_ports {c1_ddr4_adr[9]}]
#set_property -dict {PACKAGE_PIN AM26 IOSTANDARD SSTL12_DCI} [get_ports {c1_ddr4_adr[10]}]
#set_property -dict {PACKAGE_PIN BA25 IOSTANDARD SSTL12_DCI} [get_ports {c1_ddr4_adr[11]}]
#set_property -dict {PACKAGE_PIN BB22 IOSTANDARD SSTL12_DCI} [get_ports {c1_ddr4_adr[12]}]
#set_property -dict {PACKAGE_PIN AL24 IOSTANDARD SSTL12_DCI} [get_ports {c1_ddr4_adr[13]}]
#set_property -dict {PACKAGE_PIN AL25 IOSTANDARD SSTL12_DCI} [get_ports {c1_ddr4_adr[14]}]
#set_property -dict {PACKAGE_PIN AM25 IOSTANDARD SSTL12_DCI} [get_ports {c1_ddr4_adr[15]}]
#set_property -dict {PACKAGE_PIN AN23 IOSTANDARD SSTL12_DCI} [get_ports {c1_ddr4_adr[16]}]
#set_property -dict {PACKAGE_PIN AU24 IOSTANDARD SSTL12_DCI} [get_ports {c1_ddr4_ba[0]}]
#set_property -dict {PACKAGE_PIN AP26 IOSTANDARD SSTL12_DCI} [get_ports {c1_ddr4_ba[1]}]
#set_property -dict {PACKAGE_PIN BC22 IOSTANDARD SSTL12_DCI} [get_ports {c1_ddr4_bg[0]}]
#set_property -dict {PACKAGE_PIN AW26 IOSTANDARD SSTL12_DCI} [get_ports {c1_ddr4_bg[1]}]
#set_property -dict {PACKAGE_PIN BB25 IOSTANDARD SSTL12_DCI} [get_ports c1_ddr4_cke]
#set_property -dict {PACKAGE_PIN AW23 IOSTANDARD SSTL12_DCI} [get_ports c1_ddr4_odt]
#set_property -dict {PACKAGE_PIN AV23 IOSTANDARD SSTL12_DCI} [get_ports c1_ddr4_cs_n]
#set_property -dict {PACKAGE_PIN AT25 IOSTANDARD DIFF_SSTL12_DCI} [get_ports c1_ddr4_ck_t]
#set_property -dict {PACKAGE_PIN AU25 IOSTANDARD DIFF_SSTL12_DCI} [get_ports c1_ddr4_ck_c]
#set_property -dict {PACKAGE_PIN AT23 IOSTANDARD SSTL12_DCI} [get_ports c1_ddr4_parity]
#set_property -dict {PACKAGE_PIN AN13 IOSTANDARD POD12_DCI} [get_ports {c1_ddr4_dq[24]}]
#set_property -dict {PACKAGE_PIN AM13 IOSTANDARD POD12_DCI} [get_ports {c1_ddr4_dq[26]}]
#set_property -dict {PACKAGE_PIN AT13 IOSTANDARD DIFF_POD12_DCI} [get_ports {c1_ddr4_dqs_c[6]}]
#set_property -dict {PACKAGE_PIN AT14 IOSTANDARD DIFF_POD12_DCI} [get_ports {c1_ddr4_dqs_t[6]}]
#set_property -dict {PACKAGE_PIN AR13 IOSTANDARD POD12_DCI} [get_ports {c1_ddr4_dq[25]}]
#set_property -dict {PACKAGE_PIN AP13 IOSTANDARD POD12_DCI} [get_ports {c1_ddr4_dq[27]}]
#set_property -dict {PACKAGE_PIN AM14 IOSTANDARD POD12_DCI} [get_ports {c1_ddr4_dq[28]}]
#set_property -dict {PACKAGE_PIN AL14 IOSTANDARD POD12_DCI} [get_ports {c1_ddr4_dq[30]}]
#set_property -dict {PACKAGE_PIN AT15 IOSTANDARD POD12_DCI} [get_ports {c1_ddr4_dq[31]}]
#set_property -dict {PACKAGE_PIN AR15 IOSTANDARD POD12_DCI} [get_ports {c1_ddr4_dq[29]}]
#set_property -dict {PACKAGE_PIN AP14 IOSTANDARD DIFF_POD12_DCI} [get_ports {c1_ddr4_dqs_c[7]}]
#set_property -dict {PACKAGE_PIN AN14 IOSTANDARD DIFF_POD12_DCI} [get_ports {c1_ddr4_dqs_t[7]}]
#set_property -dict {PACKAGE_PIN AV13 IOSTANDARD POD12_DCI} [get_ports {c1_ddr4_dq[9]}]
#set_property -dict {PACKAGE_PIN AU13 IOSTANDARD POD12_DCI} [get_ports {c1_ddr4_dq[8]}]
#set_property -dict {PACKAGE_PIN AY15 IOSTANDARD DIFF_POD12_DCI} [get_ports {c1_ddr4_dqs_c[2]}]
#set_property -dict {PACKAGE_PIN AW15 IOSTANDARD DIFF_POD12_DCI} [get_ports {c1_ddr4_dqs_t[2]}]
#set_property -dict {PACKAGE_PIN AW13 IOSTANDARD POD12_DCI} [get_ports {c1_ddr4_dq[10]}]
#set_property -dict {PACKAGE_PIN AW14 IOSTANDARD POD12_DCI} [get_ports {c1_ddr4_dq[11]}]
#set_property -dict {PACKAGE_PIN AV14 IOSTANDARD POD12_DCI} [get_ports {c1_ddr4_dq[14]}]
#set_property -dict {PACKAGE_PIN AU14 IOSTANDARD POD12_DCI} [get_ports {c1_ddr4_dq[12]}]
#set_property -dict {PACKAGE_PIN BA11 IOSTANDARD POD12_DCI} [get_ports {c1_ddr4_dq[15]}]
#set_property -dict {PACKAGE_PIN AY11 IOSTANDARD POD12_DCI} [get_ports {c1_ddr4_dq[13]}]
#set_property -dict {PACKAGE_PIN AY12 IOSTANDARD DIFF_POD12_DCI} [get_ports {c1_ddr4_dqs_c[3]}]
#set_property -dict {PACKAGE_PIN AY13 IOSTANDARD DIFF_POD12_DCI} [get_ports {c1_ddr4_dqs_t[3]}]
#set_property -dict {PACKAGE_PIN BA13 IOSTANDARD POD12_DCI} [get_ports {c1_ddr4_dq[18]}]
#set_property -dict {PACKAGE_PIN BA14 IOSTANDARD POD12_DCI} [get_ports {c1_ddr4_dq[19]}]
#set_property -dict {PACKAGE_PIN BB10 IOSTANDARD DIFF_POD12_DCI} [get_ports {c1_ddr4_dqs_c[4]}]
#set_property -dict {PACKAGE_PIN BB11 IOSTANDARD DIFF_POD12_DCI} [get_ports {c1_ddr4_dqs_t[4]}]
#set_property -dict {PACKAGE_PIN BB12 IOSTANDARD POD12_DCI} [get_ports {c1_ddr4_dq[17]}]
#set_property -dict {PACKAGE_PIN BA12 IOSTANDARD POD12_DCI} [get_ports {c1_ddr4_dq[16]}]
#set_property -dict {PACKAGE_PIN BA7 IOSTANDARD POD12_DCI} [get_ports {c1_ddr4_dq[22]}]
#set_property -dict {PACKAGE_PIN BA8 IOSTANDARD POD12_DCI} [get_ports {c1_ddr4_dq[23]}]
#set_property -dict {PACKAGE_PIN BC9 IOSTANDARD POD12_DCI} [get_ports {c1_ddr4_dq[20]}]
#set_property -dict {PACKAGE_PIN BB9 IOSTANDARD POD12_DCI} [get_ports {c1_ddr4_dq[21]}]
#set_property -dict {PACKAGE_PIN BA9 IOSTANDARD DIFF_POD12_DCI} [get_ports {c1_ddr4_dqs_c[5]}]
#set_property -dict {PACKAGE_PIN BA10 IOSTANDARD DIFF_POD12_DCI} [get_ports {c1_ddr4_dqs_t[5]}]
#set_property -dict {PACKAGE_PIN BD7 IOSTANDARD POD12_DCI} [get_ports {c1_ddr4_dq[1]}]
#set_property -dict {PACKAGE_PIN BC7 IOSTANDARD POD12_DCI} [get_ports {c1_ddr4_dq[2]}]
#set_property -dict {PACKAGE_PIN BF9 IOSTANDARD DIFF_POD12_DCI} [get_ports {c1_ddr4_dqs_c[0]}]
#set_property -dict {PACKAGE_PIN BF10 IOSTANDARD DIFF_POD12_DCI} [get_ports {c1_ddr4_dqs_t[0]}]
#set_property -dict {PACKAGE_PIN BD8 IOSTANDARD POD12_DCI} [get_ports {c1_ddr4_dq[3]}]
#set_property -dict {PACKAGE_PIN BD9 IOSTANDARD POD12_DCI} [get_ports {c1_ddr4_dq[0]}]
#set_property -dict {PACKAGE_PIN BF7 IOSTANDARD POD12_DCI} [get_ports {c1_ddr4_dq[7]}]
#set_property -dict {PACKAGE_PIN BE7 IOSTANDARD POD12_DCI} [get_ports {c1_ddr4_dq[6]}]
#set_property -dict {PACKAGE_PIN BE10 IOSTANDARD POD12_DCI} [get_ports {c1_ddr4_dq[5]}]
#set_property -dict {PACKAGE_PIN BD10 IOSTANDARD POD12_DCI} [get_ports {c1_ddr4_dq[4]}]
#set_property -dict {PACKAGE_PIN BF8 IOSTANDARD DIFF_POD12_DCI} [get_ports {c1_ddr4_dqs_c[1]}]
#set_property -dict {PACKAGE_PIN BE8 IOSTANDARD DIFF_POD12_DCI} [get_ports {c1_ddr4_dqs_t[1]}]
#set_property -dict {PACKAGE_PIN AM15 IOSTANDARD POD12_DCI} [get_ports {c1_ddr4_dq[56]}]
#set_property -dict {PACKAGE_PIN AL15 IOSTANDARD POD12_DCI} [get_ports {c1_ddr4_dq[57]}]
#set_property -dict {PACKAGE_PIN AR16 IOSTANDARD DIFF_POD12_DCI} [get_ports {c1_ddr4_dqs_c[14]}]
#set_property -dict {PACKAGE_PIN AP16 IOSTANDARD DIFF_POD12_DCI} [get_ports {c1_ddr4_dqs_t[14]}]
#set_property -dict {PACKAGE_PIN AN16 IOSTANDARD POD12_DCI} [get_ports {c1_ddr4_dq[59]}]
#set_property -dict {PACKAGE_PIN AN17 IOSTANDARD POD12_DCI} [get_ports {c1_ddr4_dq[58]}]
#set_property -dict {PACKAGE_PIN AL16 IOSTANDARD POD12_DCI} [get_ports {c1_ddr4_dq[63]}]
#set_property -dict {PACKAGE_PIN AL17 IOSTANDARD POD12_DCI} [get_ports {c1_ddr4_dq[62]}]
#set_property -dict {PACKAGE_PIN AR18 IOSTANDARD POD12_DCI} [get_ports {c1_ddr4_dq[60]}]
#set_property -dict {PACKAGE_PIN AP18 IOSTANDARD POD12_DCI} [get_ports {c1_ddr4_dq[61]}]
#set_property -dict {PACKAGE_PIN AM16 IOSTANDARD DIFF_POD12_DCI} [get_ports {c1_ddr4_dqs_c[15]}]
#set_property -dict {PACKAGE_PIN AM17 IOSTANDARD DIFF_POD12_DCI} [get_ports {c1_ddr4_dqs_t[15]}]
#set_property -dict {PACKAGE_PIN AU16 IOSTANDARD POD12_DCI} [get_ports {c1_ddr4_dq[50]}]
#set_property -dict {PACKAGE_PIN AU17 IOSTANDARD POD12_DCI} [get_ports {c1_ddr4_dq[51]}]
#set_property -dict {PACKAGE_PIN AW18 IOSTANDARD DIFF_POD12_DCI} [get_ports {c1_ddr4_dqs_c[12]}]
#set_property -dict {PACKAGE_PIN AV18 IOSTANDARD DIFF_POD12_DCI} [get_ports {c1_ddr4_dqs_t[12]}]
#set_property -dict {PACKAGE_PIN AV16 IOSTANDARD POD12_DCI} [get_ports {c1_ddr4_dq[48]}]
#set_property -dict {PACKAGE_PIN AV17 IOSTANDARD POD12_DCI} [get_ports {c1_ddr4_dq[49]}]
#set_property -dict {PACKAGE_PIN AT17 IOSTANDARD POD12_DCI} [get_ports {c1_ddr4_dq[55]}]
#set_property -dict {PACKAGE_PIN AT18 IOSTANDARD POD12_DCI} [get_ports {c1_ddr4_dq[54]}]
#set_property -dict {PACKAGE_PIN BB16 IOSTANDARD POD12_DCI} [get_ports {c1_ddr4_dq[53]}]
#set_property -dict {PACKAGE_PIN BB17 IOSTANDARD POD12_DCI} [get_ports {c1_ddr4_dq[52]}]
#set_property -dict {PACKAGE_PIN AY16 IOSTANDARD DIFF_POD12_DCI} [get_ports {c1_ddr4_dqs_c[13]}]
#set_property -dict {PACKAGE_PIN AW16 IOSTANDARD DIFF_POD12_DCI} [get_ports {c1_ddr4_dqs_t[13]}]
#set_property -dict {PACKAGE_PIN AY17 IOSTANDARD POD12_DCI} [get_ports {c1_ddr4_dq[40]}]
#set_property -dict {PACKAGE_PIN AY18 IOSTANDARD POD12_DCI} [get_ports {c1_ddr4_dq[42]}]
#set_property -dict {PACKAGE_PIN BC12 IOSTANDARD DIFF_POD12_DCI} [get_ports {c1_ddr4_dqs_c[10]}]
#set_property -dict {PACKAGE_PIN BC13 IOSTANDARD DIFF_POD12_DCI} [get_ports {c1_ddr4_dqs_t[10]}]
#set_property -dict {PACKAGE_PIN BA17 IOSTANDARD POD12_DCI} [get_ports {c1_ddr4_dq[41]}]
#set_property -dict {PACKAGE_PIN BA18 IOSTANDARD POD12_DCI} [get_ports {c1_ddr4_dq[43]}]
#set_property -dict {PACKAGE_PIN BB15 IOSTANDARD POD12_DCI} [get_ports {c1_ddr4_dq[45]}]
#set_property -dict {PACKAGE_PIN BA15 IOSTANDARD POD12_DCI} [get_ports {c1_ddr4_dq[44]}]
#set_property -dict {PACKAGE_PIN BD11 IOSTANDARD POD12_DCI} [get_ports {c1_ddr4_dq[47]}]
#set_property -dict {PACKAGE_PIN BC11 IOSTANDARD POD12_DCI} [get_ports {c1_ddr4_dq[46]}]
#set_property -dict {PACKAGE_PIN BC14 IOSTANDARD DIFF_POD12_DCI} [get_ports {c1_ddr4_dqs_c[11]}]
#set_property -dict {PACKAGE_PIN BB14 IOSTANDARD DIFF_POD12_DCI} [get_ports {c1_ddr4_dqs_t[11]}]
#set_property -dict {PACKAGE_PIN BD13 IOSTANDARD POD12_DCI} [get_ports {c1_ddr4_dq[35]}]
#set_property -dict {PACKAGE_PIN BD14 IOSTANDARD POD12_DCI} [get_ports {c1_ddr4_dq[33]}]
#set_property -dict {PACKAGE_PIN BE11 IOSTANDARD DIFF_POD12_DCI} [get_ports {c1_ddr4_dqs_c[8]}]
#set_property -dict {PACKAGE_PIN BE12 IOSTANDARD DIFF_POD12_DCI} [get_ports {c1_ddr4_dqs_t[8]}]
#set_property -dict {PACKAGE_PIN BF12 IOSTANDARD POD12_DCI} [get_ports {c1_ddr4_dq[34]}]
#set_property -dict {PACKAGE_PIN BE13 IOSTANDARD POD12_DCI} [get_ports {c1_ddr4_dq[32]}]
#set_property -dict {PACKAGE_PIN BD15 IOSTANDARD POD12_DCI} [get_ports {c1_ddr4_dq[36]}]
#set_property -dict {PACKAGE_PIN BD16 IOSTANDARD POD12_DCI} [get_ports {c1_ddr4_dq[37]}]
#set_property -dict {PACKAGE_PIN BF13 IOSTANDARD POD12_DCI} [get_ports {c1_ddr4_dq[39]}]
#set_property -dict {PACKAGE_PIN BF14 IOSTANDARD POD12_DCI} [get_ports {c1_ddr4_dq[38]}]
#set_property -dict {PACKAGE_PIN BF15 IOSTANDARD DIFF_POD12_DCI} [get_ports {c1_ddr4_dqs_c[9]}]
#set_property -dict {PACKAGE_PIN BE15 IOSTANDARD DIFF_POD12_DCI} [get_ports {c1_ddr4_dqs_t[9]}]
#set_property -dict {PACKAGE_PIN BF25 IOSTANDARD POD12_DCI} [get_ports {c1_ddr4_dq[64]}]
#set_property -dict {PACKAGE_PIN BF24 IOSTANDARD POD12_DCI} [get_ports {c1_ddr4_dq[65]}]
#set_property -dict {PACKAGE_PIN BD24 IOSTANDARD DIFF_POD12_DCI} [get_ports {c1_ddr4_dqs_c[16]}]
#set_property -dict {PACKAGE_PIN BC24 IOSTANDARD DIFF_POD12_DCI} [get_ports {c1_ddr4_dqs_t[16]}]
#set_property -dict {PACKAGE_PIN BE25 IOSTANDARD POD12_DCI} [get_ports {c1_ddr4_dq[67]}]
#set_property -dict {PACKAGE_PIN BD25 IOSTANDARD POD12_DCI} [get_ports {c1_ddr4_dq[66]}]
#set_property -dict {PACKAGE_PIN BF23 IOSTANDARD POD12_DCI} [get_ports {c1_ddr4_dq[70]}]
#set_property -dict {PACKAGE_PIN BE23 IOSTANDARD POD12_DCI} [get_ports {c1_ddr4_dq[71]}]
#set_property -dict {PACKAGE_PIN BD23 IOSTANDARD POD12_DCI} [get_ports {c1_ddr4_dq[68]}]
#set_property -dict {PACKAGE_PIN BC23 IOSTANDARD POD12_DCI} [get_ports {c1_ddr4_dq[69]}]
#set_property -dict {PACKAGE_PIN BF22 IOSTANDARD DIFF_POD12_DCI} [get_ports {c1_ddr4_dqs_c[17]}]
#set_property -dict {PACKAGE_PIN BE22 IOSTANDARD DIFF_POD12_DCI} [get_ports {c1_ddr4_dqs_t[17]}]





#-------------------------------------------------------------------------------------------------------------------
# DDR4 RDIMM Controller 2, 72-bit Data Interface, x4 Componets, Single Rank
#     <<<NOTE>>> DQS Clock strobes have been swapped from JEDEC standard to match Xilinx MIG Clock order:
#                JEDEC Order   DQS ->  0  9  1 10  2 11  3 12  4 13  5 14  6 15  7 16  8 17
#                Xil MIG Order DQS ->  0  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17
#-------------------------------------------------------------------------------------------------------------------
#set_property -dict {PACKAGE_PIN B31 IOSTANDARD SSTL12_DCI} [get_ports c2_ddr4_act_n]
#set_property -dict {PACKAGE_PIN L29 IOSTANDARD SSTL12_DCI} [get_ports {c2_ddr4_adr[0]}]
#set_property -dict {PACKAGE_PIN A33 IOSTANDARD SSTL12_DCI} [get_ports {c2_ddr4_adr[1]}]
#set_property -dict {PACKAGE_PIN C33 IOSTANDARD SSTL12_DCI} [get_ports {c2_ddr4_adr[2]}]
#set_property -dict {PACKAGE_PIN J29 IOSTANDARD SSTL12_DCI} [get_ports {c2_ddr4_adr[3]}]
#set_property -dict {PACKAGE_PIN H31 IOSTANDARD SSTL12_DCI} [get_ports {c2_ddr4_adr[4]}]
#set_property -dict {PACKAGE_PIN G31 IOSTANDARD SSTL12_DCI} [get_ports {c2_ddr4_adr[5]}]
#set_property -dict {PACKAGE_PIN C32 IOSTANDARD SSTL12_DCI} [get_ports {c2_ddr4_adr[6]}]
#set_property -dict {PACKAGE_PIN B32 IOSTANDARD SSTL12_DCI} [get_ports {c2_ddr4_adr[7]}]
#set_property -dict {PACKAGE_PIN A32 IOSTANDARD SSTL12_DCI} [get_ports {c2_ddr4_adr[8]}]
#set_property -dict {PACKAGE_PIN D31 IOSTANDARD SSTL12_DCI} [get_ports {c2_ddr4_adr[9]}]
#set_property -dict {PACKAGE_PIN A34 IOSTANDARD SSTL12_DCI} [get_ports {c2_ddr4_adr[10]}]
#set_property -dict {PACKAGE_PIN E31 IOSTANDARD SSTL12_DCI} [get_ports {c2_ddr4_adr[11]}]
#set_property -dict {PACKAGE_PIN M30 IOSTANDARD SSTL12_DCI} [get_ports {c2_ddr4_adr[12]}]
#set_property -dict {PACKAGE_PIN F33 IOSTANDARD SSTL12_DCI} [get_ports {c2_ddr4_adr[13]}]
#set_property -dict {PACKAGE_PIN A35 IOSTANDARD SSTL12_DCI} [get_ports {c2_ddr4_adr[14]}]
#set_property -dict {PACKAGE_PIN G32 IOSTANDARD SSTL12_DCI} [get_ports {c2_ddr4_adr[15]}]
#set_property -dict {PACKAGE_PIN K30 IOSTANDARD SSTL12_DCI} [get_ports {c2_ddr4_adr[16]}]
#set_property -dict {PACKAGE_PIN D33 IOSTANDARD SSTL12_DCI} [get_ports {c2_ddr4_ba[0]}]
#set_property -dict {PACKAGE_PIN B36 IOSTANDARD SSTL12_DCI} [get_ports {c2_ddr4_ba[1]}]
#set_property -dict {PACKAGE_PIN C31 IOSTANDARD SSTL12_DCI} [get_ports {c2_ddr4_bg[0]}]
#set_property -dict {PACKAGE_PIN J30 IOSTANDARD SSTL12_DCI} [get_ports {c2_ddr4_bg[1]}]
#set_property -dict {PACKAGE_PIN G30 IOSTANDARD SSTL12_DCI} [get_ports c2_ddr4_cke]
#set_property -dict {PACKAGE_PIN E33 IOSTANDARD SSTL12_DCI} [get_ports c2_ddr4_odt]
#set_property -dict {PACKAGE_PIN B35 IOSTANDARD SSTL12_DCI} [get_ports c2_ddr4_cs_n]
#set_property -dict {PACKAGE_PIN C34 IOSTANDARD DIFF_SSTL12_DCI} [get_ports c2_ddr4_ck_t]
#set_property -dict {PACKAGE_PIN B34 IOSTANDARD DIFF_SSTL12_DCI} [get_ports c2_ddr4_ck_c]
#set_property -dict {PACKAGE_PIN D36 IOSTANDARD LVCMOS12} [get_ports c2_ddr4_reset_n]
#set_property -dict {PACKAGE_PIN M29 IOSTANDARD SSTL12_DCI} [get_ports c2_ddr4_parity]
#set_property -dict {PACKAGE_PIN C26 IOSTANDARD POD12_DCI} [get_ports {c2_ddr4_dq[25]}]
#set_property -dict {PACKAGE_PIN D26 IOSTANDARD POD12_DCI} [get_ports {c2_ddr4_dq[24]}]
#set_property -dict {PACKAGE_PIN A28 IOSTANDARD DIFF_POD12_DCI} [get_ports {c2_ddr4_dqs_c[6]}]
#set_property -dict {PACKAGE_PIN A27 IOSTANDARD DIFF_POD12_DCI} [get_ports {c2_ddr4_dqs_t[6]}]
#set_property -dict {PACKAGE_PIN B27 IOSTANDARD POD12_DCI} [get_ports {c2_ddr4_dq[26]}]
#set_property -dict {PACKAGE_PIN B26 IOSTANDARD POD12_DCI} [get_ports {c2_ddr4_dq[27]}]
#set_property -dict {PACKAGE_PIN C28 IOSTANDARD POD12_DCI} [get_ports {c2_ddr4_dq[31]}]
#set_property -dict {PACKAGE_PIN C27 IOSTANDARD POD12_DCI} [get_ports {c2_ddr4_dq[30]}]
#set_property -dict {PACKAGE_PIN A30 IOSTANDARD POD12_DCI} [get_ports {c2_ddr4_dq[29]}]
#set_property -dict {PACKAGE_PIN A29 IOSTANDARD POD12_DCI} [get_ports {c2_ddr4_dq[28]}]
#set_property -dict {PACKAGE_PIN B29 IOSTANDARD DIFF_POD12_DCI} [get_ports {c2_ddr4_dqs_c[7]}]
#set_property -dict {PACKAGE_PIN C29 IOSTANDARD DIFF_POD12_DCI} [get_ports {c2_ddr4_dqs_t[7]}]
#set_property -dict {PACKAGE_PIN E27 IOSTANDARD POD12_DCI} [get_ports {c2_ddr4_dq[17]}]
#set_property -dict {PACKAGE_PIN F27 IOSTANDARD POD12_DCI} [get_ports {c2_ddr4_dq[16]}]
#set_property -dict {PACKAGE_PIN D30 IOSTANDARD DIFF_POD12_DCI} [get_ports {c2_ddr4_dqs_c[4]}]
#set_property -dict {PACKAGE_PIN D29 IOSTANDARD DIFF_POD12_DCI} [get_ports {c2_ddr4_dqs_t[4]}]
#set_property -dict {PACKAGE_PIN D28 IOSTANDARD POD12_DCI} [get_ports {c2_ddr4_dq[19]}]
#set_property -dict {PACKAGE_PIN E28 IOSTANDARD POD12_DCI} [get_ports {c2_ddr4_dq[18]}]
#set_property -dict {PACKAGE_PIN F29 IOSTANDARD POD12_DCI} [get_ports {c2_ddr4_dq[23]}]
#set_property -dict {PACKAGE_PIN F28 IOSTANDARD POD12_DCI} [get_ports {c2_ddr4_dq[22]}]
#set_property -dict {PACKAGE_PIN G27 IOSTANDARD POD12_DCI} [get_ports {c2_ddr4_dq[20]}]
#set_property -dict {PACKAGE_PIN G26 IOSTANDARD POD12_DCI} [get_ports {c2_ddr4_dq[21]}]
#set_property -dict {PACKAGE_PIN H27 IOSTANDARD DIFF_POD12_DCI} [get_ports {c2_ddr4_dqs_c[5]}]
#set_property -dict {PACKAGE_PIN H26 IOSTANDARD DIFF_POD12_DCI} [get_ports {c2_ddr4_dqs_t[5]}]
#set_property -dict {PACKAGE_PIN H28 IOSTANDARD POD12_DCI} [get_ports {c2_ddr4_dq[10]}]
#set_property -dict {PACKAGE_PIN J28 IOSTANDARD POD12_DCI} [get_ports {c2_ddr4_dq[8]}]
#set_property -dict {PACKAGE_PIN J26 IOSTANDARD DIFF_POD12_DCI} [get_ports {c2_ddr4_dqs_c[2]}]
#set_property -dict {PACKAGE_PIN J25 IOSTANDARD DIFF_POD12_DCI} [get_ports {c2_ddr4_dqs_t[2]}]
#set_property -dict {PACKAGE_PIN G29 IOSTANDARD POD12_DCI} [get_ports {c2_ddr4_dq[11]}]
#set_property -dict {PACKAGE_PIN H29 IOSTANDARD POD12_DCI} [get_ports {c2_ddr4_dq[9]}]
#set_property -dict {PACKAGE_PIN K27 IOSTANDARD POD12_DCI} [get_ports {c2_ddr4_dq[15]}]
#set_property -dict {PACKAGE_PIN L27 IOSTANDARD POD12_DCI} [get_ports {c2_ddr4_dq[13]}]
#set_property -dict {PACKAGE_PIN K26 IOSTANDARD POD12_DCI} [get_ports {c2_ddr4_dq[14]}]
#set_property -dict {PACKAGE_PIN K25 IOSTANDARD POD12_DCI} [get_ports {c2_ddr4_dq[12]}]
#set_property -dict {PACKAGE_PIN L28 IOSTANDARD DIFF_POD12_DCI} [get_ports {c2_ddr4_dqs_c[3]}]
#set_property -dict {PACKAGE_PIN M27 IOSTANDARD DIFF_POD12_DCI} [get_ports {c2_ddr4_dqs_t[3]}]
#set_property -dict {PACKAGE_PIN P25 IOSTANDARD POD12_DCI} [get_ports {c2_ddr4_dq[1]}]
#set_property -dict {PACKAGE_PIN R25 IOSTANDARD POD12_DCI} [get_ports {c2_ddr4_dq[0]}]
#set_property -dict {PACKAGE_PIN M26 IOSTANDARD DIFF_POD12_DCI} [get_ports {c2_ddr4_dqs_c[0]}]
#set_property -dict {PACKAGE_PIN N26 IOSTANDARD DIFF_POD12_DCI} [get_ports {c2_ddr4_dqs_t[0]}]
#set_property -dict {PACKAGE_PIN L25 IOSTANDARD POD12_DCI} [get_ports {c2_ddr4_dq[3]}]
#set_property -dict {PACKAGE_PIN M25 IOSTANDARD POD12_DCI} [get_ports {c2_ddr4_dq[2]}]
#set_property -dict {PACKAGE_PIN P26 IOSTANDARD POD12_DCI} [get_ports {c2_ddr4_dq[4]}]
#set_property -dict {PACKAGE_PIN R26 IOSTANDARD POD12_DCI} [get_ports {c2_ddr4_dq[5]}]
#set_property -dict {PACKAGE_PIN N28 IOSTANDARD POD12_DCI} [get_ports {c2_ddr4_dq[7]}]
#set_property -dict {PACKAGE_PIN N27 IOSTANDARD POD12_DCI} [get_ports {c2_ddr4_dq[6]}]
#set_property -dict {PACKAGE_PIN P28 IOSTANDARD DIFF_POD12_DCI} [get_ports {c2_ddr4_dqs_c[1]}]
#set_property -dict {PACKAGE_PIN R28 IOSTANDARD DIFF_POD12_DCI} [get_ports {c2_ddr4_dqs_t[1]}]
#set_property -dict {PACKAGE_PIN P30 IOSTANDARD POD12_DCI} [get_ports {c2_ddr4_dq[40]}]
#set_property -dict {PACKAGE_PIN R30 IOSTANDARD POD12_DCI} [get_ports {c2_ddr4_dq[41]}]
#set_property -dict {PACKAGE_PIN M31 IOSTANDARD DIFF_POD12_DCI} [get_ports {c2_ddr4_dqs_c[10]}]
#set_property -dict {PACKAGE_PIN N31 IOSTANDARD DIFF_POD12_DCI} [get_ports {c2_ddr4_dqs_t[10]}]
#set_property -dict {PACKAGE_PIN N29 IOSTANDARD POD12_DCI} [get_ports {c2_ddr4_dq[43]}]
#set_property -dict {PACKAGE_PIN P29 IOSTANDARD POD12_DCI} [get_ports {c2_ddr4_dq[42]}]
#set_property -dict {PACKAGE_PIN N32 IOSTANDARD POD12_DCI} [get_ports {c2_ddr4_dq[47]}]
#set_property -dict {PACKAGE_PIN P31 IOSTANDARD POD12_DCI} [get_ports {c2_ddr4_dq[46]}]
#set_property -dict {PACKAGE_PIN L32 IOSTANDARD POD12_DCI} [get_ports {c2_ddr4_dq[44]}]
#set_property -dict {PACKAGE_PIN M32 IOSTANDARD POD12_DCI} [get_ports {c2_ddr4_dq[45]}]
#set_property -dict {PACKAGE_PIN R31 IOSTANDARD DIFF_POD12_DCI} [get_ports {c2_ddr4_dqs_c[11]}]
#set_property -dict {PACKAGE_PIN T30 IOSTANDARD DIFF_POD12_DCI} [get_ports {c2_ddr4_dqs_t[11]}]
#set_property -dict {PACKAGE_PIN B37 IOSTANDARD POD12_DCI} [get_ports {c2_ddr4_dq[65]}]
#set_property -dict {PACKAGE_PIN C36 IOSTANDARD POD12_DCI} [get_ports {c2_ddr4_dq[64]}]
#set_property -dict {PACKAGE_PIN A39 IOSTANDARD DIFF_POD12_DCI} [get_ports {c2_ddr4_dqs_c[16]}]
#set_property -dict {PACKAGE_PIN B39 IOSTANDARD DIFF_POD12_DCI} [get_ports {c2_ddr4_dqs_t[16]}]
#set_property -dict {PACKAGE_PIN A38 IOSTANDARD POD12_DCI} [get_ports {c2_ddr4_dq[67]}]
#set_property -dict {PACKAGE_PIN A37 IOSTANDARD POD12_DCI} [get_ports {c2_ddr4_dq[66]}]
#set_property -dict {PACKAGE_PIN C39 IOSTANDARD POD12_DCI} [get_ports {c2_ddr4_dq[68]}]
#set_property -dict {PACKAGE_PIN D39 IOSTANDARD POD12_DCI} [get_ports {c2_ddr4_dq[69]}]
#set_property -dict {PACKAGE_PIN A40 IOSTANDARD POD12_DCI} [get_ports {c2_ddr4_dq[70]}]
#set_property -dict {PACKAGE_PIN B40 IOSTANDARD POD12_DCI} [get_ports {c2_ddr4_dq[71]}]
#set_property -dict {PACKAGE_PIN C38 IOSTANDARD DIFF_POD12_DCI} [get_ports {c2_ddr4_dqs_c[17]}]
#set_property -dict {PACKAGE_PIN C37 IOSTANDARD DIFF_POD12_DCI} [get_ports {c2_ddr4_dqs_t[17]}]
#set_property -dict {PACKAGE_PIN E35 IOSTANDARD POD12_DCI} [get_ports {c2_ddr4_dq[35]}]
#set_property -dict {PACKAGE_PIN F35 IOSTANDARD POD12_DCI} [get_ports {c2_ddr4_dq[32]}]
#set_property -dict {PACKAGE_PIN E40 IOSTANDARD DIFF_POD12_DCI} [get_ports {c2_ddr4_dqs_c[8]}]
#set_property -dict {PACKAGE_PIN E39 IOSTANDARD DIFF_POD12_DCI} [get_ports {c2_ddr4_dqs_t[8]}]
#set_property -dict {PACKAGE_PIN D38 IOSTANDARD POD12_DCI} [get_ports {c2_ddr4_dq[34]}]
#set_property -dict {PACKAGE_PIN E38 IOSTANDARD POD12_DCI} [get_ports {c2_ddr4_dq[33]}]
#set_property -dict {PACKAGE_PIN F38 IOSTANDARD POD12_DCI} [get_ports {c2_ddr4_dq[38]}]
#set_property -dict {PACKAGE_PIN G38 IOSTANDARD POD12_DCI} [get_ports {c2_ddr4_dq[39]}]
#set_property -dict {PACKAGE_PIN E37 IOSTANDARD POD12_DCI} [get_ports {c2_ddr4_dq[37]}]
#set_property -dict {PACKAGE_PIN E36 IOSTANDARD POD12_DCI} [get_ports {c2_ddr4_dq[36]}]
#set_property -dict {PACKAGE_PIN F37 IOSTANDARD DIFF_POD12_DCI} [get_ports {c2_ddr4_dqs_c[9]}]
#set_property -dict {PACKAGE_PIN G37 IOSTANDARD DIFF_POD12_DCI} [get_ports {c2_ddr4_dqs_t[9]}]
#set_property -dict {PACKAGE_PIN G36 IOSTANDARD POD12_DCI} [get_ports {c2_ddr4_dq[57]}]
#set_property -dict {PACKAGE_PIN H36 IOSTANDARD POD12_DCI} [get_ports {c2_ddr4_dq[56]}]
#set_property -dict {PACKAGE_PIN H38 IOSTANDARD DIFF_POD12_DCI} [get_ports {c2_ddr4_dqs_c[14]}]
#set_property -dict {PACKAGE_PIN J38 IOSTANDARD DIFF_POD12_DCI} [get_ports {c2_ddr4_dqs_t[14]}]
#set_property -dict {PACKAGE_PIN H37 IOSTANDARD POD12_DCI} [get_ports {c2_ddr4_dq[58]}]
#set_property -dict {PACKAGE_PIN J36 IOSTANDARD POD12_DCI} [get_ports {c2_ddr4_dq[59]}]
#set_property -dict {PACKAGE_PIN G35 IOSTANDARD POD12_DCI} [get_ports {c2_ddr4_dq[62]}]
#set_property -dict {PACKAGE_PIN G34 IOSTANDARD POD12_DCI} [get_ports {c2_ddr4_dq[63]}]
#set_property -dict {PACKAGE_PIN K38 IOSTANDARD POD12_DCI} [get_ports {c2_ddr4_dq[61]}]
#set_property -dict {PACKAGE_PIN K37 IOSTANDARD POD12_DCI} [get_ports {c2_ddr4_dq[60]}]
#set_property -dict {PACKAGE_PIN H34 IOSTANDARD DIFF_POD12_DCI} [get_ports {c2_ddr4_dqs_c[15]}]
#set_property -dict {PACKAGE_PIN H33 IOSTANDARD DIFF_POD12_DCI} [get_ports {c2_ddr4_dqs_t[15]}]
#set_property -dict {PACKAGE_PIN K33 IOSTANDARD POD12_DCI} [get_ports {c2_ddr4_dq[51]}]
#set_property -dict {PACKAGE_PIN L33 IOSTANDARD POD12_DCI} [get_ports {c2_ddr4_dq[50]}]
#set_property -dict {PACKAGE_PIN L36 IOSTANDARD DIFF_POD12_DCI} [get_ports {c2_ddr4_dqs_c[12]}]
#set_property -dict {PACKAGE_PIN L35 IOSTANDARD DIFF_POD12_DCI} [get_ports {c2_ddr4_dqs_t[12]}]
#set_property -dict {PACKAGE_PIN J35 IOSTANDARD POD12_DCI} [get_ports {c2_ddr4_dq[48]}]
#set_property -dict {PACKAGE_PIN K35 IOSTANDARD POD12_DCI} [get_ports {c2_ddr4_dq[49]}]
#set_property -dict {PACKAGE_PIN J34 IOSTANDARD POD12_DCI} [get_ports {c2_ddr4_dq[52]}]
#set_property -dict {PACKAGE_PIN J33 IOSTANDARD POD12_DCI} [get_ports {c2_ddr4_dq[53]}]
#set_property -dict {PACKAGE_PIN N34 IOSTANDARD POD12_DCI} [get_ports {c2_ddr4_dq[54]}]
#set_property -dict {PACKAGE_PIN P34 IOSTANDARD POD12_DCI} [get_ports {c2_ddr4_dq[55]}]
#set_property -dict {PACKAGE_PIN L34 IOSTANDARD DIFF_POD12_DCI} [get_ports {c2_ddr4_dqs_c[13]}]
#set_property -dict {PACKAGE_PIN M34 IOSTANDARD DIFF_POD12_DCI} [get_ports {c2_ddr4_dqs_t[13]}]



#-------------------------------------------------------------------------------------------------------------------
# DDR4 RDIMM Controller 3, 72-bit Data Interface, x4 Componets, Single Rank
#     <<<NOTE>>> DQS Clock strobes have been swapped from JEDEC standard to match Xilinx MIG Clock order:
#                JEDEC Order   DQS ->  0  9  1 10  2 11  3 12  4 13  5 14  6 15  7 16  8 17
#                Xil MIG Order DQS ->  0  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17
#-------------------------------------------------------------------------------------------------------------------
#set_property -dict {PACKAGE_PIN K15  IOSTANDARD SSTL12_DCI     } [get_ports c3_ddr4_adr[0]   ]; # Bank 70  VCCO - VCC1V2 Net "DDR4_C3_ADR0"     - IO_L7N_T1L_N1_QBC_AD13N_70
#set_property -dict {PACKAGE_PIN B15  IOSTANDARD SSTL12_DCI     } [get_ports c3_ddr4_adr[1]   ]; # Bank 70  VCCO - VCC1V2 Net "DDR4_C3_ADR1"      - IO_L21P_T3L_N4_AD8P_70
#set_property -dict {PACKAGE_PIN F14  IOSTANDARD SSTL12_DCI     } [get_ports c3_ddr4_adr[2]   ]; # Bank 70  VCCO - VCC1V2 Net "DDR4_C3_ADR2"      - IO_L18N_T2U_N11_AD2N_70
#set_property -dict {PACKAGE_PIN A15  IOSTANDARD SSTL12_DCI     } [get_ports c3_ddr4_adr[3]   ]; # Bank 70  VCCO - VCC1V2 Net "DDR4_C3_ADR3"      - IO_L21N_T3L_N5_AD8N_70
#set_property -dict {PACKAGE_PIN C14  IOSTANDARD SSTL12_DCI     } [get_ports c3_ddr4_adr[4]   ]; # Bank 70  VCCO - VCC1V2 Net "DDR4_C3_ADR4"      - IO_L20N_T3L_N3_AD1N_70
#set_property -dict {PACKAGE_PIN A14  IOSTANDARD SSTL12_DCI     } [get_ports c3_ddr4_adr[5]   ]; # Bank 70  VCCO - VCC1V2 Net "DDR4_C3_ADR5"      - IO_L19N_T3L_N1_DBC_AD9N_70
#set_property -dict {PACKAGE_PIN B14  IOSTANDARD SSTL12_DCI     } [get_ports c3_ddr4_adr[6]   ]; # Bank 70  VCCO - VCC1V2 Net "DDR4_C3_ADR6"      - IO_L19P_T3L_N0_DBC_AD9P_70
#set_property -dict {PACKAGE_PIN E13  IOSTANDARD SSTL12_DCI     } [get_ports c3_ddr4_adr[7]   ]; # Bank 70  VCCO - VCC1V2 Net "DDR4_C3_ADR7"      - IO_L15N_T2L_N5_AD11N_70
#set_property -dict {PACKAGE_PIN F13  IOSTANDARD SSTL12_DCI     } [get_ports c3_ddr4_adr[8]   ]; # Bank 70  VCCO - VCC1V2 Net "DDR4_C3_ADR8"      - IO_L15P_T2L_N4_AD11P_70
#set_property -dict {PACKAGE_PIN A13  IOSTANDARD SSTL12_DCI     } [get_ports c3_ddr4_adr[9]   ]; # Bank 70  VCCO - VCC1V2 Net "DDR4_C3_ADR9"      - IO_L24N_T3U_N11_70
#set_property -dict {PACKAGE_PIN D14  IOSTANDARD SSTL12_DCI     } [get_ports c3_ddr4_adr[10]  ]; # Bank 70  VCCO - VCC1V2 Net "DDR4_C3_ADR10"     - IO_L20P_T3L_N2_AD1P_70
#set_property -dict {PACKAGE_PIN C13  IOSTANDARD SSTL12_DCI     } [get_ports c3_ddr4_adr[11]  ]; # Bank 70  VCCO - VCC1V2 Net "DDR4_C3_ADR11"     - IO_L22N_T3U_N7_DBC_AD0N_70
#set_property -dict {PACKAGE_PIN B13  IOSTANDARD SSTL12_DCI     } [get_ports c3_ddr4_adr[12]  ]; # Bank 70  VCCO - VCC1V2 Net "DDR4_C3_ADR12"     - IO_L24P_T3U_N10_70
#set_property -dict {PACKAGE_PIN K16  IOSTANDARD SSTL12_DCI     } [get_ports c3_ddr4_adr[13]  ]; # Bank 70  VCCO - VCC1V2 Net "DDR4_C3_ADR13"    - IO_L9P_T1L_N4_AD12P_70
#set_property -dict {PACKAGE_PIN D15  IOSTANDARD SSTL12_DCI     } [get_ports c3_ddr4_adr[14]  ]; # Bank 70  VCCO - VCC1V2 Net "DDR4_C3_ADR14"     - IO_T2U_N12_70
#set_property -dict {PACKAGE_PIN E15  IOSTANDARD SSTL12_DCI     } [get_ports c3_ddr4_adr[15]  ]; # Bank 70  VCCO - VCC1V2 Net "DDR4_C3_ADR15"     - IO_L17N_T2U_N9_AD10N_70
#set_property -dict {PACKAGE_PIN F15  IOSTANDARD SSTL12_DCI     } [get_ports c3_ddr4_adr[16]  ]; # Bank 70  VCCO - VCC1V2 Net "DDR4_C3_ADR16"     - IO_L18P_T2U_N10_AD2P_70
#set_property -dict {PACKAGE_PIN B16  IOSTANDARD SSTL12_DCI     } [get_ports c3_ddr4_cs_n     ]; # Bank 70  VCCO - VCC1V2 Net "DDR4_C3_CS_B0"     - IO_L23N_T3U_N9_70
#set_property -dict {PACKAGE_PIN C16  IOSTANDARD SSTL12_DCI     } [get_ports c3_ddr4_odt      ]; # Bank 70  VCCO - VCC1V2 Net "DDR4_C3_ODT0"      - IO_L23P_T3U_N8_70
#set_property -dict {PACKAGE_PIN D13  IOSTANDARD SSTL12_DCI     } [get_ports c3_ddr4_bg[0]    ]; # Bank 70  VCCO - VCC1V2 Net "DDR4_C3_BG0"       - IO_L22P_T3U_N6_DBC_AD0P_70
#set_property -dict {PACKAGE_PIN J13  IOSTANDARD SSTL12_DCI     } [get_ports c3_ddr4_bg[1]    ]; # Bank 70  VCCO - VCC1V2 Net "DDR4_C3_BG1"      - IO_L12N_T1U_N11_GC_70
#set_property -dict {PACKAGE_PIN J15  IOSTANDARD SSTL12_DCI     } [get_ports c3_ddr4_ba[0]    ]; # Bank 70  VCCO - VCC1V2 Net "DDR4_C3_BA0"      - IO_L9N_T1L_N5_AD12N_70
#set_property -dict {PACKAGE_PIN H14  IOSTANDARD SSTL12_DCI     } [get_ports c3_ddr4_ba[1]    ]; # Bank 70  VCCO - VCC1V2 Net "DDR4_C3_BA1"       - IO_L14P_T2L_N2_GC_70
#set_property -dict {PACKAGE_PIN H13  IOSTANDARD SSTL12_DCI     } [get_ports c3_ddr4_act_n    ]; # Bank 70  VCCO - VCC1V2 Net "DDR4_C3_ACT_B"     - IO_L14N_T2L_N3_GC_70
#set_property -dict {PACKAGE_PIN L13  IOSTANDARD DIFF_SSTL12_DCI} [get_ports c3_ddr4_ck_c     ]; # Bank 70  VCCO - VCC1V2 Net "DDR4_C3_CK_C0"    - IO_L10N_T1U_N7_QBC_AD4N_70
#set_property -dict {PACKAGE_PIN L14  IOSTANDARD DIFF_SSTL12_DCI} [get_ports c3_ddr4_ck_t     ]; # Bank 70  VCCO - VCC1V2 Net "DDR4_C3_CK_T0"    - IO_L10P_T1U_N6_QBC_AD4P_70
#set_property -dict {PACKAGE_PIN K13  IOSTANDARD SSTL12_DCI     } [get_ports c3_ddr4_cke      ]; # Bank 70  VCCO - VCC1V2 Net "DDR4_C3_CKE0"     - IO_T1U_N12_70
#set_property -dict {PACKAGE_PIN J14  IOSTANDARD SSTL12_DCI     } [get_ports c3_ddr4_parity   ]; # Bank 70  VCCO - VCC1V2 Net "DDR4_C3_PAR"      - IO_L12P_T1U_N10_GC_70
#set_property -dict {PACKAGE_PIN D21  IOSTANDARD LVCMOS12       } [get_ports c3_ddr4_reset_n  ]; # Bank 71  VCCO - VCC1V2 Net "DDR4_C3_RESET_N"   - IO_T2U_N12_71
#set_property -dict {PACKAGE_PIN B24  IOSTANDARD POD12_DCI      } [get_ports c3_ddr4_dq[34]   ]; # Bank 72  VCCO - VCC1V2 Net "DDR4_C3_DQ34"      - IO_L23N_T3U_N9_72
#set_property -dict {PACKAGE_PIN B25  IOSTANDARD POD12_DCI      } [get_ports c3_ddr4_dq[35]   ]; # Bank 72  VCCO - VCC1V2 Net "DDR4_C3_DQ35"      - IO_L23P_T3U_N8_72
#set_property -dict {PACKAGE_PIN A24  IOSTANDARD DIFF_POD12_DCI } [get_ports c3_ddr4_dqs_c[8] ]; # Bank 72  VCCO - VCC1V2 Net "DDR4_C3_DQS_C4"    - IO_L22N_T3U_N7_DBC_AD0N_72
#set_property -dict {PACKAGE_PIN A25  IOSTANDARD DIFF_POD12_DCI } [get_ports c3_ddr4_dqs_t[8] ]; # Bank 72  VCCO - VCC1V2 Net "DDR4_C3_DQS_T4"    - IO_L22P_T3U_N6_DBC_AD0P_72
#set_property -dict {PACKAGE_PIN A22  IOSTANDARD POD12_DCI      } [get_ports c3_ddr4_dq[33]   ]; # Bank 72  VCCO - VCC1V2 Net "DDR4_C3_DQ33"      - IO_L24N_T3U_N11_72
#set_property -dict {PACKAGE_PIN A23  IOSTANDARD POD12_DCI      } [get_ports c3_ddr4_dq[32]   ]; # Bank 72  VCCO - VCC1V2 Net "DDR4_C3_DQ32"      - IO_L24P_T3U_N10_72
#set_property -dict {PACKAGE_PIN C23  IOSTANDARD POD12_DCI      } [get_ports c3_ddr4_dq[39]   ]; # Bank 72  VCCO - VCC1V2 Net "DDR4_C3_DQ39"      - IO_L21N_T3L_N5_AD8N_72
#set_property -dict {PACKAGE_PIN C24  IOSTANDARD POD12_DCI      } [get_ports c3_ddr4_dq[38]   ]; # Bank 72  VCCO - VCC1V2 Net "DDR4_C3_DQ38"      - IO_L21P_T3L_N4_AD8P_72
#set_property -dict {PACKAGE_PIN B22  IOSTANDARD POD12_DCI      } [get_ports c3_ddr4_dq[36]   ]; # Bank 72  VCCO - VCC1V2 Net "DDR4_C3_DQ36"      - IO_L20N_T3L_N3_AD1N_72
#set_property -dict {PACKAGE_PIN C22  IOSTANDARD POD12_DCI      } [get_ports c3_ddr4_dq[37]   ]; # Bank 72  VCCO - VCC1V2 Net "DDR4_C3_DQ37"      - IO_L20P_T3L_N2_AD1P_72
#set_property -dict {PACKAGE_PIN D23  IOSTANDARD DIFF_POD12_DCI } [get_ports c3_ddr4_dqs_c[9] ]; # Bank 72  VCCO - VCC1V2 Net "DDR4_C3_DQS_C13"   - IO_L19N_T3L_N1_DBC_AD9N_72
#set_property -dict {PACKAGE_PIN D24  IOSTANDARD DIFF_POD12_DCI } [get_ports c3_ddr4_dqs_t[9] ]; # Bank 72  VCCO - VCC1V2 Net "DDR4_C3_DQS_T13"   - IO_L19P_T3L_N0_DBC_AD9P_72
#set_property -dict {PACKAGE_PIN E22  IOSTANDARD POD12_DCI      } [get_ports c3_ddr4_dq[57]   ]; # Bank 72  VCCO - VCC1V2 Net "DDR4_C3_DQ57"      - IO_L17N_T2U_N9_AD10N_72
#set_property -dict {PACKAGE_PIN F22  IOSTANDARD POD12_DCI      } [get_ports c3_ddr4_dq[56]   ]; # Bank 72  VCCO - VCC1V2 Net "DDR4_C3_DQ56"      - IO_L17P_T2U_N8_AD10P_72
#set_property -dict {PACKAGE_PIN E23  IOSTANDARD DIFF_POD12_DCI } [get_ports c3_ddr4_dqs_c[14]]; # Bank 72  VCCO - VCC1V2 Net "DDR4_C3_DQS_C7"    - IO_L16N_T2U_N7_QBC_AD3N_72
#set_property -dict {PACKAGE_PIN F23  IOSTANDARD DIFF_POD12_DCI } [get_ports c3_ddr4_dqs_t[14]]; # Bank 72  VCCO - VCC1V2 Net "DDR4_C3_DQS_T7"    - IO_L16P_T2U_N6_QBC_AD3P_72
#set_property -dict {PACKAGE_PIN G21  IOSTANDARD POD12_DCI      } [get_ports c3_ddr4_dq[59]   ]; # Bank 72  VCCO - VCC1V2 Net "DDR4_C3_DQ59"      - IO_L18N_T2U_N11_AD2N_72
#set_property -dict {PACKAGE_PIN G22  IOSTANDARD POD12_DCI      } [get_ports c3_ddr4_dq[58]   ]; # Bank 72  VCCO - VCC1V2 Net "DDR4_C3_DQ58"      - IO_L18P_T2U_N10_AD2P_72
#set_property -dict {PACKAGE_PIN E25  IOSTANDARD POD12_DCI      } [get_ports c3_ddr4_dq[61]   ]; # Bank 72  VCCO - VCC1V2 Net "DDR4_C3_DQ61"      - IO_L15N_T2L_N5_AD11N_72
#set_property -dict {PACKAGE_PIN F25  IOSTANDARD POD12_DCI      } [get_ports c3_ddr4_dq[62]   ]; # Bank 72  VCCO - VCC1V2 Net "DDR4_C3_DQ62"      - IO_L15P_T2L_N4_AD11P_72
#set_property -dict {PACKAGE_PIN F24  IOSTANDARD POD12_DCI      } [get_ports c3_ddr4_dq[60]   ]; # Bank 72  VCCO - VCC1V2 Net "DDR4_C3_DQ60"      - IO_L14N_T2L_N3_GC_72
#set_property -dict {PACKAGE_PIN G25  IOSTANDARD POD12_DCI      } [get_ports c3_ddr4_dq[63]   ]; # Bank 72  VCCO - VCC1V2 Net "DDR4_C3_DQ63"      - IO_L14P_T2L_N2_GC_72
#set_property -dict {PACKAGE_PIN H22  IOSTANDARD DIFF_POD12_DCI } [get_ports c3_ddr4_dqs_c[15]]; # Bank 72  VCCO - VCC1V2 Net "DDR4_C3_DQS_C16"   - IO_L13N_T2L_N1_GC_QBC_72
#set_property -dict {PACKAGE_PIN H23  IOSTANDARD DIFF_POD12_DCI } [get_ports c3_ddr4_dqs_t[15]]; # Bank 72  VCCO - VCC1V2 Net "DDR4_C3_DQS_T16"   - IO_L13P_T2L_N0_GC_QBC_72
#set_property -dict {PACKAGE_PIN J23  IOSTANDARD POD12_DCI      } [get_ports c3_ddr4_dq[9]    ]; # Bank 72  VCCO - VCC1V2 Net "DDR4_C3_DQ9"       - IO_L11N_T1U_N9_GC_72
#set_property -dict {PACKAGE_PIN J24  IOSTANDARD POD12_DCI      } [get_ports c3_ddr4_dq[8]    ]; # Bank 72  VCCO - VCC1V2 Net "DDR4_C3_DQ8"       - IO_L11P_T1U_N8_GC_72
#set_property -dict {PACKAGE_PIN H21  IOSTANDARD DIFF_POD12_DCI } [get_ports c3_ddr4_dqs_c[2] ]; # Bank 72  VCCO - VCC1V2 Net "DDR4_C3_DQS_C1"    - IO_L10N_T1U_N7_QBC_AD4N_72
#set_property -dict {PACKAGE_PIN J21  IOSTANDARD DIFF_POD12_DCI } [get_ports c3_ddr4_dqs_t[2] ]; # Bank 72  VCCO - VCC1V2 Net "DDR4_C3_DQS_T1"    - IO_L10P_T1U_N6_QBC_AD4P_72
#set_property -dict {PACKAGE_PIN G24  IOSTANDARD POD12_DCI      } [get_ports c3_ddr4_dq[11]   ]; # Bank 72  VCCO - VCC1V2 Net "DDR4_C3_DQ11"      - IO_L12N_T1U_N11_GC_72
#set_property -dict {PACKAGE_PIN H24  IOSTANDARD POD12_DCI      } [get_ports c3_ddr4_dq[10]   ]; # Bank 72  VCCO - VCC1V2 Net "DDR4_C3_DQ10"      - IO_L12P_T1U_N10_GC_72
#set_property -dict {PACKAGE_PIN L23  IOSTANDARD POD12_DCI      } [get_ports c3_ddr4_dq[13]   ]; # Bank 72  VCCO - VCC1V2 Net "DDR4_C3_DQ13"      - IO_L9N_T1L_N5_AD12N_72
#set_property -dict {PACKAGE_PIN L24  IOSTANDARD POD12_DCI      } [get_ports c3_ddr4_dq[12]   ]; # Bank 72  VCCO - VCC1V2 Net "DDR4_C3_DQ12"      - IO_L9P_T1L_N4_AD12P_72
#set_property -dict {PACKAGE_PIN K21  IOSTANDARD POD12_DCI      } [get_ports c3_ddr4_dq[15]   ]; # Bank 72  VCCO - VCC1V2 Net "DDR4_C3_DQ15"      - IO_L8N_T1L_N3_AD5N_72
#set_property -dict {PACKAGE_PIN K22  IOSTANDARD POD12_DCI      } [get_ports c3_ddr4_dq[14]   ]; # Bank 72  VCCO - VCC1V2 Net "DDR4_C3_DQ14"      - IO_L8P_T1L_N2_AD5P_72
#set_property -dict {PACKAGE_PIN L22  IOSTANDARD DIFF_POD12_DCI } [get_ports c3_ddr4_dqs_c[3] ]; # Bank 72  VCCO - VCC1V2 Net "DDR4_C3_DQS_C10"   - IO_L7N_T1L_N1_QBC_AD13N_72
#set_property -dict {PACKAGE_PIN M22  IOSTANDARD DIFF_POD12_DCI } [get_ports c3_ddr4_dqs_t[3] ]; # Bank 72  VCCO - VCC1V2 Net "DDR4_C3_DQS_T10"   - IO_L7P_T1L_N0_QBC_AD13P_72
#set_property -dict {PACKAGE_PIN N24  IOSTANDARD POD12_DCI      } [get_ports c3_ddr4_dq[1]    ]; # Bank 72  VCCO - VCC1V2 Net "DDR4_C3_DQ1"       - IO_L5N_T0U_N9_AD14N_72
#set_property -dict {PACKAGE_PIN P24  IOSTANDARD POD12_DCI      } [get_ports c3_ddr4_dq[0]    ]; # Bank 72  VCCO - VCC1V2 Net "DDR4_C3_DQ0"       - IO_L5P_T0U_N8_AD14P_72
#set_property -dict {PACKAGE_PIN R22  IOSTANDARD DIFF_POD12_DCI } [get_ports c3_ddr4_dqs_c[0] ]; # Bank 72  VCCO - VCC1V2 Net "DDR4_C3_DQS_C0"    - IO_L4N_T0U_N7_DBC_AD7N_72
#set_property -dict {PACKAGE_PIN T22  IOSTANDARD DIFF_POD12_DCI } [get_ports c3_ddr4_dqs_t[0] ]; # Bank 72  VCCO - VCC1V2 Net "DDR4_C3_DQS_T0"    - IO_L4P_T0U_N6_DBC_AD7P_72
#set_property -dict {PACKAGE_PIN R23  IOSTANDARD POD12_DCI      } [get_ports c3_ddr4_dq[3]    ]; # Bank 72  VCCO - VCC1V2 Net "DDR4_C3_DQ3"       - IO_L6N_T0U_N11_AD6N_72
#set_property -dict {PACKAGE_PIN T24  IOSTANDARD POD12_DCI      } [get_ports c3_ddr4_dq[2]    ]; # Bank 72  VCCO - VCC1V2 Net "DDR4_C3_DQ2"       - IO_L6P_T0U_N10_AD6P_72
#set_property -dict {PACKAGE_PIN N23  IOSTANDARD POD12_DCI      } [get_ports c3_ddr4_dq[4]    ]; # Bank 72  VCCO - VCC1V2 Net "DDR4_C3_DQ4"       - IO_L3N_T0L_N5_AD15N_72
#set_property -dict {PACKAGE_PIN P23  IOSTANDARD POD12_DCI      } [get_ports c3_ddr4_dq[6]    ]; # Bank 72  VCCO - VCC1V2 Net "DDR4_C3_DQ6"       - IO_L3P_T0L_N4_AD15P_72
#set_property -dict {PACKAGE_PIN P21  IOSTANDARD POD12_DCI      } [get_ports c3_ddr4_dq[5]    ]; # Bank 72  VCCO - VCC1V2 Net "DDR4_C3_DQ5"       - IO_L2N_T0L_N3_72
#set_property -dict {PACKAGE_PIN R21  IOSTANDARD POD12_DCI      } [get_ports c3_ddr4_dq[7]    ]; # Bank 72  VCCO - VCC1V2 Net "DDR4_C3_DQ7"       - IO_L2P_T0L_N2_72
#set_property -dict {PACKAGE_PIN N21  IOSTANDARD DIFF_POD12_DCI } [get_ports c3_ddr4_dqs_c[1] ]; # Bank 72  VCCO - VCC1V2 Net "DDR4_C3_DQS_C9"    - IO_L1N_T0L_N1_DBC_72
#set_property -dict {PACKAGE_PIN N22  IOSTANDARD DIFF_POD12_DCI } [get_ports c3_ddr4_dqs_t[1] ]; # Bank 72  VCCO - VCC1V2 Net "DDR4_C3_DQS_T9"    - IO_L1P_T0L_N0_DBC_72
#set_property -dict {PACKAGE_PIN B21  IOSTANDARD POD12_DCI      } [get_ports c3_ddr4_dq[43]   ]; # Bank 71  VCCO - VCC1V2 Net "DDR4_C3_DQ43"      - IO_L23N_T3U_N9_71
#set_property -dict {PACKAGE_PIN C21  IOSTANDARD POD12_DCI      } [get_ports c3_ddr4_dq[42]   ]; # Bank 71  VCCO - VCC1V2 Net "DDR4_C3_DQ42"      - IO_L23P_T3U_N8_71
#set_property -dict {PACKAGE_PIN B17  IOSTANDARD DIFF_POD12_DCI } [get_ports c3_ddr4_dqs_c[10]]; # Bank 71  VCCO - VCC1V2 Net "DDR4_C3_DQS_C5"    - IO_L22N_T3U_N7_DBC_AD0N_71
#set_property -dict {PACKAGE_PIN C17  IOSTANDARD DIFF_POD12_DCI } [get_ports c3_ddr4_dqs_t[10]]; # Bank 71  VCCO - VCC1V2 Net "DDR4_C3_DQS_T5"    - IO_L22P_T3U_N6_DBC_AD0P_71
#set_property -dict {PACKAGE_PIN C18  IOSTANDARD POD12_DCI      } [get_ports c3_ddr4_dq[41]   ]; # Bank 71  VCCO - VCC1V2 Net "DDR4_C3_DQ41"      - IO_L24N_T3U_N11_71
#set_property -dict {PACKAGE_PIN C19  IOSTANDARD POD12_DCI      } [get_ports c3_ddr4_dq[40]   ]; # Bank 71  VCCO - VCC1V2 Net "DDR4_C3_DQ40"      - IO_L24P_T3U_N10_71
#set_property -dict {PACKAGE_PIN A20  IOSTANDARD POD12_DCI      } [get_ports c3_ddr4_dq[46]   ]; # Bank 71  VCCO - VCC1V2 Net "DDR4_C3_DQ46"      - IO_L21N_T3L_N5_AD8N_71
#set_property -dict {PACKAGE_PIN B20  IOSTANDARD POD12_DCI      } [get_ports c3_ddr4_dq[47]   ]; # Bank 71  VCCO - VCC1V2 Net "DDR4_C3_DQ47"      - IO_L21P_T3L_N4_AD8P_71
#set_property -dict {PACKAGE_PIN A17  IOSTANDARD POD12_DCI      } [get_ports c3_ddr4_dq[45]   ]; # Bank 71  VCCO - VCC1V2 Net "DDR4_C3_DQ45"      - IO_L20N_T3L_N3_AD1N_71
#set_property -dict {PACKAGE_PIN A18  IOSTANDARD POD12_DCI      } [get_ports c3_ddr4_dq[44]   ]; # Bank 71  VCCO - VCC1V2 Net "DDR4_C3_DQ44"      - IO_L20P_T3L_N2_AD1P_71
#set_property -dict {PACKAGE_PIN A19  IOSTANDARD DIFF_POD12_DCI } [get_ports c3_ddr4_dqs_c[11]]; # Bank 71  VCCO - VCC1V2 Net "DDR4_C3_DQS_C14"   - IO_L19N_T3L_N1_DBC_AD9N_71
#set_property -dict {PACKAGE_PIN B19  IOSTANDARD DIFF_POD12_DCI } [get_ports c3_ddr4_dqs_t[11]]; # Bank 71  VCCO - VCC1V2 Net "DDR4_C3_DQS_T14"   - IO_L19P_T3L_N0_DBC_AD9P_71
#set_property -dict {PACKAGE_PIN E20  IOSTANDARD POD12_DCI      } [get_ports c3_ddr4_dq[51]   ]; # Bank 71  VCCO - VCC1V2 Net "DDR4_C3_DQ51"      - IO_L17N_T2U_N9_AD10N_71
#set_property -dict {PACKAGE_PIN F20  IOSTANDARD POD12_DCI      } [get_ports c3_ddr4_dq[49]   ]; # Bank 71  VCCO - VCC1V2 Net "DDR4_C3_DQ49"      - IO_L17P_T2U_N8_AD10P_71
#set_property -dict {PACKAGE_PIN F17  IOSTANDARD DIFF_POD12_DCI } [get_ports c3_ddr4_dqs_c[12]]; # Bank 71  VCCO - VCC1V2 Net "DDR4_C3_DQS_C6"    - IO_L16N_T2U_N7_QBC_AD3N_71
#set_property -dict {PACKAGE_PIN F18  IOSTANDARD DIFF_POD12_DCI } [get_ports c3_ddr4_dqs_t[12]]; # Bank 71  VCCO - VCC1V2 Net "DDR4_C3_DQS_T6"    - IO_L16P_T2U_N6_QBC_AD3P_71
#set_property -dict {PACKAGE_PIN E17  IOSTANDARD POD12_DCI      } [get_ports c3_ddr4_dq[48]   ]; # Bank 71  VCCO - VCC1V2 Net "DDR4_C3_DQ48"      - IO_L18N_T2U_N11_AD2N_71
#set_property -dict {PACKAGE_PIN E18  IOSTANDARD POD12_DCI      } [get_ports c3_ddr4_dq[50]   ]; # Bank 71  VCCO - VCC1V2 Net "DDR4_C3_DQ50"      - IO_L18P_T2U_N10_AD2P_71
#set_property -dict {PACKAGE_PIN D19  IOSTANDARD POD12_DCI      } [get_ports c3_ddr4_dq[52]   ]; # Bank 71  VCCO - VCC1V2 Net "DDR4_C3_DQ52"      - IO_L15N_T2L_N5_AD11N_71
#set_property -dict {PACKAGE_PIN D20  IOSTANDARD POD12_DCI      } [get_ports c3_ddr4_dq[53]   ]; # Bank 71  VCCO - VCC1V2 Net "DDR4_C3_DQ53"      - IO_L15P_T2L_N4_AD11P_71
#set_property -dict {PACKAGE_PIN H18  IOSTANDARD POD12_DCI      } [get_ports c3_ddr4_dq[54]   ]; # Bank 71  VCCO - VCC1V2 Net "DDR4_C3_DQ54"      - IO_L14N_T2L_N3_GC_71
#set_property -dict {PACKAGE_PIN J18  IOSTANDARD POD12_DCI      } [get_ports c3_ddr4_dq[55]   ]; # Bank 71  VCCO - VCC1V2 Net "DDR4_C3_DQ55"      - IO_L14P_T2L_N2_GC_71
#set_property -dict {PACKAGE_PIN G19  IOSTANDARD DIFF_POD12_DCI } [get_ports c3_ddr4_dqs_c[13]]; # Bank 71  VCCO - VCC1V2 Net "DDR4_C3_DQS_C15"   - IO_L13N_T2L_N1_GC_QBC_71
#set_property -dict {PACKAGE_PIN H19  IOSTANDARD DIFF_POD12_DCI } [get_ports c3_ddr4_dqs_t[13]]; # Bank 71  VCCO - VCC1V2 Net "DDR4_C3_DQS_T15"   - IO_L13P_T2L_N0_GC_QBC_71
#set_property -dict {PACKAGE_PIN F19  IOSTANDARD POD12_DCI      } [get_ports c3_ddr4_dq[18]   ]; # Bank 71  VCCO - VCC1V2 Net "DDR4_C3_DQ18"      - IO_L11N_T1U_N9_GC_71
#set_property -dict {PACKAGE_PIN G20  IOSTANDARD POD12_DCI      } [get_ports c3_ddr4_dq[16]   ]; # Bank 71  VCCO - VCC1V2 Net "DDR4_C3_DQ16"      - IO_L11P_T1U_N8_GC_71
#set_property -dict {PACKAGE_PIN K20  IOSTANDARD DIFF_POD12_DCI } [get_ports c3_ddr4_dqs_c[4] ]; # Bank 71  VCCO - VCC1V2 Net "DDR4_C3_DQS_C2"    - IO_L10N_T1U_N7_QBC_AD4N_71
#set_property -dict {PACKAGE_PIN L20  IOSTANDARD DIFF_POD12_DCI } [get_ports c3_ddr4_dqs_t[4] ]; # Bank 71  VCCO - VCC1V2 Net "DDR4_C3_DQS_T2"    - IO_L10P_T1U_N6_QBC_AD4P_71
#set_property -dict {PACKAGE_PIN G17  IOSTANDARD POD12_DCI      } [get_ports c3_ddr4_dq[19]   ]; # Bank 71  VCCO - VCC1V2 Net "DDR4_C3_DQ19"      - IO_L12N_T1U_N11_GC_71
#set_property -dict {PACKAGE_PIN H17  IOSTANDARD POD12_DCI      } [get_ports c3_ddr4_dq[17]   ]; # Bank 71  VCCO - VCC1V2 Net "DDR4_C3_DQ17"      - IO_L12P_T1U_N10_GC_71
#set_property -dict {PACKAGE_PIN J19  IOSTANDARD POD12_DCI      } [get_ports c3_ddr4_dq[23]   ]; # Bank 71  VCCO - VCC1V2 Net "DDR4_C3_DQ23"      - IO_L9N_T1L_N5_AD12N_71
#set_property -dict {PACKAGE_PIN J20  IOSTANDARD POD12_DCI      } [get_ports c3_ddr4_dq[20]   ]; # Bank 71  VCCO - VCC1V2 Net "DDR4_C3_DQ20"      - IO_L9P_T1L_N4_AD12P_71
#set_property -dict {PACKAGE_PIN L18  IOSTANDARD POD12_DCI      } [get_ports c3_ddr4_dq[22]   ]; # Bank 71  VCCO - VCC1V2 Net "DDR4_C3_DQ22"      - IO_L8N_T1L_N3_AD5N_71
#set_property -dict {PACKAGE_PIN L19  IOSTANDARD POD12_DCI      } [get_ports c3_ddr4_dq[21]   ]; # Bank 71  VCCO - VCC1V2 Net "DDR4_C3_DQ21"      - IO_L8P_T1L_N2_AD5P_71
#set_property -dict {PACKAGE_PIN K17  IOSTANDARD DIFF_POD12_DCI } [get_ports c3_ddr4_dqs_c[5] ]; # Bank 71  VCCO - VCC1V2 Net "DDR4_C3_DQS_C11"   - IO_L7N_T1L_N1_QBC_AD13N_71
#set_property -dict {PACKAGE_PIN K18  IOSTANDARD DIFF_POD12_DCI } [get_ports c3_ddr4_dqs_t[5] ]; # Bank 71  VCCO - VCC1V2 Net "DDR4_C3_DQS_T11"   - IO_L7P_T1L_N0_QBC_AD13P_71
#set_property -dict {PACKAGE_PIN M19  IOSTANDARD POD12_DCI      } [get_ports c3_ddr4_dq[24]   ]; # Bank 71  VCCO - VCC1V2 Net "DDR4_C3_DQ24"      - IO_L5N_T0U_N9_AD14N_71
#set_property -dict {PACKAGE_PIN M20  IOSTANDARD POD12_DCI      } [get_ports c3_ddr4_dq[25]   ]; # Bank 71  VCCO - VCC1V2 Net "DDR4_C3_DQ25"      - IO_L5P_T0U_N8_AD14P_71
#set_property -dict {PACKAGE_PIN P18  IOSTANDARD DIFF_POD12_DCI } [get_ports c3_ddr4_dqs_c[6] ]; # Bank 71  VCCO - VCC1V2 Net "DDR4_C3_DQS_C3"    - IO_L4N_T0U_N7_DBC_AD7N_71
#set_property -dict {PACKAGE_PIN P19  IOSTANDARD DIFF_POD12_DCI } [get_ports c3_ddr4_dqs_t[6] ]; # Bank 71  VCCO - VCC1V2 Net "DDR4_C3_DQS_T3"    - IO_L4P_T0U_N6_DBC_AD7P_71
#set_property -dict {PACKAGE_PIN R17  IOSTANDARD POD12_DCI      } [get_ports c3_ddr4_dq[27]   ]; # Bank 71  VCCO - VCC1V2 Net "DDR4_C3_DQ27"      - IO_L6N_T0U_N11_AD6N_71
#set_property -dict {PACKAGE_PIN R18  IOSTANDARD POD12_DCI      } [get_ports c3_ddr4_dq[26]   ]; # Bank 71  VCCO - VCC1V2 Net "DDR4_C3_DQ26"      - IO_L6P_T0U_N10_AD6P_71
#set_property -dict {PACKAGE_PIN N18  IOSTANDARD POD12_DCI      } [get_ports c3_ddr4_dq[30]   ]; # Bank 71  VCCO - VCC1V2 Net "DDR4_C3_DQ30"      - IO_L3N_T0L_N5_AD15N_71
#set_property -dict {PACKAGE_PIN N19  IOSTANDARD POD12_DCI      } [get_ports c3_ddr4_dq[31]   ]; # Bank 71  VCCO - VCC1V2 Net "DDR4_C3_DQ31"      - IO_L3P_T0L_N4_AD15P_71
#set_property -dict {PACKAGE_PIN R20  IOSTANDARD POD12_DCI      } [get_ports c3_ddr4_dq[28]   ]; # Bank 71  VCCO - VCC1V2 Net "DDR4_C3_DQ28"      - IO_L2N_T0L_N3_71
#set_property -dict {PACKAGE_PIN T20  IOSTANDARD POD12_DCI      } [get_ports c3_ddr4_dq[29]   ]; # Bank 71  VCCO - VCC1V2 Net "DDR4_C3_DQ29"      - IO_L2P_T0L_N2_71
#set_property -dict {PACKAGE_PIN M17  IOSTANDARD DIFF_POD12_DCI } [get_ports c3_ddr4_dqs_c[7] ]; # Bank 71  VCCO - VCC1V2 Net "DDR4_C3_DQS_C12"   - IO_L1N_T0L_N1_DBC_71
#set_property -dict {PACKAGE_PIN N17  IOSTANDARD DIFF_POD12_DCI } [get_ports c3_ddr4_dqs_t[7] ]; # Bank 71  VCCO - VCC1V2 Net "DDR4_C3_DQS_T12"   - IO_L1P_T0L_N0_DBC_71
#set_property -dict {PACKAGE_PIN N13  IOSTANDARD POD12_DCI      } [get_ports c3_ddr4_dq[66]   ]; # Bank 70  VCCO - VCC1V2 Net "DDR4_C3_DQ66"     - IO_L5N_T0U_N9_AD14N_70
#set_property -dict {PACKAGE_PIN N14  IOSTANDARD POD12_DCI      } [get_ports c3_ddr4_dq[67]   ]; # Bank 70  VCCO - VCC1V2 Net "DDR4_C3_DQ67"     - IO_L5P_T0U_N8_AD14P_70
#set_property -dict {PACKAGE_PIN P15  IOSTANDARD DIFF_POD12_DCI } [get_ports c3_ddr4_dqs_c[16]]; # Bank 70  VCCO - VCC1V2 Net "DDR4_C3_DQS_C8"   - IO_L4N_T0U_N7_DBC_AD7N_70
#set_property -dict {PACKAGE_PIN R16  IOSTANDARD DIFF_POD12_DCI } [get_ports c3_ddr4_dqs_t[16]]; # Bank 70  VCCO - VCC1V2 Net "DDR4_C3_DQS_T8"   - IO_L4P_T0U_N6_DBC_AD7P_70
#set_property -dict {PACKAGE_PIN M16  IOSTANDARD POD12_DCI      } [get_ports c3_ddr4_dq[64]   ]; # Bank 70  VCCO - VCC1V2 Net "DDR4_C3_DQ64"     - IO_L6N_T0U_N11_AD6N_70
#set_property -dict {PACKAGE_PIN N16  IOSTANDARD POD12_DCI      } [get_ports c3_ddr4_dq[65]   ]; # Bank 70  VCCO - VCC1V2 Net "DDR4_C3_DQ65"     - IO_L6P_T0U_N10_AD6P_70
#set_property -dict {PACKAGE_PIN P13  IOSTANDARD POD12_DCI      } [get_ports c3_ddr4_dq[70]   ]; # Bank 70  VCCO - VCC1V2 Net "DDR4_C3_DQ70"     - IO_L3N_T0L_N5_AD15N_70
#set_property -dict {PACKAGE_PIN P14  IOSTANDARD POD12_DCI      } [get_ports c3_ddr4_dq[71]   ]; # Bank 70  VCCO - VCC1V2 Net "DDR4_C3_DQ71"     - IO_L3P_T0L_N4_AD15P_70
#set_property -dict {PACKAGE_PIN R15  IOSTANDARD POD12_DCI      } [get_ports c3_ddr4_dq[69]   ]; # Bank 70  VCCO - VCC1V2 Net "DDR4_C3_DQ69"     - IO_L2N_T0L_N3_70
#set_property -dict {PACKAGE_PIN T15  IOSTANDARD POD12_DCI      } [get_ports c3_ddr4_dq[68]   ]; # Bank 70  VCCO - VCC1V2 Net "DDR4_C3_DQ68"     - IO_L2P_T0L_N2_70
#set_property -dict {PACKAGE_PIN R13  IOSTANDARD DIFF_POD12_DCI } [get_ports c3_ddr4_dqs_c[17]]; # Bank 70  VCCO - VCC1V2 Net "DDR4_C3_DQS_C17"  - IO_L1N_T0L_N1_DBC_70
#set_property -dict {PACKAGE_PIN T13  IOSTANDARD DIFF_POD12_DCI } [get_ports c3_ddr4_dqs_t[17]]; # Bank 70  VCCO - VCC1V2 Net "DDR4_C3_DQS_T17"  - IO_L1P_T0L_N0_DBC_70



#-----------------------------------------------------------------------------------
# DDR4
#-----------------------------------------------------------------------------------
set_property -dict {PACKAGE_PIN AY38 IOSTANDARD LVDS} [get_ports c0_sys_clk_n]
set_property -dict {PACKAGE_PIN AY37 IOSTANDARD LVDS} [get_ports c0_sys_clk_p]
#set_property -dict {PACKAGE_PIN AW19 IOSTANDARD LVDS           } [get_ports c1_sys_clk_n     ]; # Bank 64 VCCO - VCC1V2 Net "SYSCLK1_300_N" - IO_L11N_T1U_N9_GC_64
#set_property -dict {PACKAGE_PIN AW20 IOSTANDARD LVDS           } [get_ports c1_sys_clk_p     ]; # Bank 64 VCCO - VCC1V2 Net "SYSCLK1_300_P" - IO_L11P_T1U_N8_GC_64
#set_property -dict {PACKAGE_PIN E32  IOSTANDARD DIFF_POD12_DCI } [get_ports c2_sys_clk_n     ]; # Bank 47 VCCO - VCC1V2 Net "SYSCLK2_300_N" - IO_L13N_T2L_N1_GC_QBC_47
#set_property -dict {PACKAGE_PIN F32  IOSTANDARD DIFF_POD12_DCI } [get_ports c2_sys_clk_p     ]; # Bank 47 VCCO - VCC1V2 Net "SYSCLK2_300_P" - IO_L13P_T2L_N0_GC_QBC_47
#set_property -dict {PACKAGE_PIN H16  IOSTANDARD DIFF_POD12_DCI } [get_ports c3_sys_clk_n     ]; # Bank 70 VCCO - VCC1V2 Net "SYSCLK3_300_N" - IO_L13N_T2L_N1_GC_QBC_70
#set_property -dict {PACKAGE_PIN J16  IOSTANDARD DIFF_POD12_DCI } [get_ports c3_sys_clk_p     ]; # Bank 70 VCCO - VCC1V2 Net "SYSCLK3_300_P" - IO_L13P_T2L_N0_GC_QBC_70

set_property -dict {PACKAGE_PIN BA38 IOSTANDARD LVCMOS12} [get_ports c0_sys_rst]
#set_property -dict {PACKAGE_PIN AY26 IOSTANDARD LVCMOS12       } [get_ports c1_sys_rst  ]; # Bank 65 VCCO - VCC1V2 Net "DDR4_C1_ALERT_B"  - IO_L11N_T1U_N9_GC_A11_D27_65
#set_property -dict {PACKAGE_PIN F30  IOSTANDARD LVCMOS12       } [get_ports c2_sys_rst  ]; # Bank 47 VCCO - VCC1V2 Net "DDR4_C2_ALERT_B" - IO_L11N_T1U_N9_GC_47
#set_property -dict {PACKAGE_PIN G15  IOSTANDARD LVCMOS12       } [get_ports c3_sys_rst  ]; # Bank 70  VCCO - VCC1V2 Net "DDR4_C3_ALERT_B"  - IO_L11N_T1U_N9_GC_70


#set_false_path -from [get_ports c1_sys_rst]
#set_false_path -from [get_ports c2_sys_rst]
#set_false_path -from [get_ports c3_sys_rst]

#set_property PULLDOWN true [get_ports c1_sys_rst]
#set_property PULLDOWN true [get_ports c2_sys_rst]
#set_property PULLDOWN true [get_ports c3_sys_rst]


#-----------------------------------------------------------------------------------
# PCIE
#-----------------------------------------------------------------------------------
set_property PACKAGE_PIN AF2 [get_ports {pci_exp_rxp[0]}]
set_property PACKAGE_PIN AF1 [get_ports {pci_exp_rxn[0]}]
set_property PACKAGE_PIN AF7 [get_ports {pci_exp_txp[0]}]
set_property PACKAGE_PIN AF6 [get_ports {pci_exp_txn[0]}]
set_property PACKAGE_PIN AG4 [get_ports {pci_exp_rxp[1]}]
set_property PACKAGE_PIN AG3 [get_ports {pci_exp_rxn[1]}]
set_property PACKAGE_PIN AG9 [get_ports {pci_exp_txp[1]}]
set_property PACKAGE_PIN AG8 [get_ports {pci_exp_txn[1]}]
set_property PACKAGE_PIN AH2 [get_ports {pci_exp_rxp[2]}]
set_property PACKAGE_PIN AH1 [get_ports {pci_exp_rxn[2]}]
set_property PACKAGE_PIN AH7 [get_ports {pci_exp_txp[2]}]
set_property PACKAGE_PIN AH6 [get_ports {pci_exp_txn[2]}]
set_property PACKAGE_PIN AJ4 [get_ports {pci_exp_rxp[3]}]
set_property PACKAGE_PIN AJ3 [get_ports {pci_exp_rxn[3]}]
set_property PACKAGE_PIN AJ9 [get_ports {pci_exp_txp[3]}]
set_property PACKAGE_PIN AJ8 [get_ports {pci_exp_txn[3]}]
set_property PACKAGE_PIN AK2 [get_ports {pci_exp_rxp[4]}]
set_property PACKAGE_PIN AK1 [get_ports {pci_exp_rxn[4]}]
set_property PACKAGE_PIN AK7 [get_ports {pci_exp_txp[4]}]
set_property PACKAGE_PIN AK6 [get_ports {pci_exp_txn[4]}]
set_property PACKAGE_PIN AL4 [get_ports {pci_exp_rxp[5]}]
set_property PACKAGE_PIN AL3 [get_ports {pci_exp_rxn[5]}]
set_property PACKAGE_PIN AL9 [get_ports {pci_exp_txp[5]}]
set_property PACKAGE_PIN AL8 [get_ports {pci_exp_txn[5]}]
set_property PACKAGE_PIN AM2 [get_ports {pci_exp_rxp[6]}]
set_property PACKAGE_PIN AM1 [get_ports {pci_exp_rxn[6]}]
set_property PACKAGE_PIN AM7 [get_ports {pci_exp_txp[6]}]
set_property PACKAGE_PIN AM6 [get_ports {pci_exp_txn[6]}]
set_property PACKAGE_PIN AN4 [get_ports {pci_exp_rxp[7]}]
set_property PACKAGE_PIN AN3 [get_ports {pci_exp_rxn[7]}]
set_property PACKAGE_PIN AN9 [get_ports {pci_exp_txp[7]}]
set_property PACKAGE_PIN AN8 [get_ports {pci_exp_txn[7]}]
set_property PACKAGE_PIN AP2 [get_ports {pci_exp_rxp[8]}]
set_property PACKAGE_PIN AP1 [get_ports {pci_exp_rxn[8]}]
set_property PACKAGE_PIN AP7 [get_ports {pci_exp_txp[8]}]
set_property PACKAGE_PIN AP6 [get_ports {pci_exp_txn[8]}]
set_property PACKAGE_PIN AR4 [get_ports {pci_exp_rxp[9]}]
set_property PACKAGE_PIN AR3 [get_ports {pci_exp_rxn[9]}]
set_property PACKAGE_PIN AR9 [get_ports {pci_exp_txp[9]}]
set_property PACKAGE_PIN AR8 [get_ports {pci_exp_txn[9]}]
set_property PACKAGE_PIN AT2 [get_ports {pci_exp_rxp[10]}]
set_property PACKAGE_PIN AT1 [get_ports {pci_exp_rxn[10]}]
set_property PACKAGE_PIN AT7 [get_ports {pci_exp_txp[10]}]
set_property PACKAGE_PIN AT6 [get_ports {pci_exp_txn[10]}]
set_property PACKAGE_PIN AU4 [get_ports {pci_exp_rxp[11]}]
set_property PACKAGE_PIN AU3 [get_ports {pci_exp_rxn[11]}]
set_property PACKAGE_PIN AU9 [get_ports {pci_exp_txp[11]}]
set_property PACKAGE_PIN AU8 [get_ports {pci_exp_txn[11]}]
set_property PACKAGE_PIN AV2 [get_ports {pci_exp_rxp[12]}]
set_property PACKAGE_PIN AV1 [get_ports {pci_exp_rxn[12]}]
set_property PACKAGE_PIN AV7 [get_ports {pci_exp_txp[12]}]
set_property PACKAGE_PIN AV6 [get_ports {pci_exp_txn[12]}]
set_property PACKAGE_PIN AW4 [get_ports {pci_exp_rxp[13]}]
set_property PACKAGE_PIN AW3 [get_ports {pci_exp_rxn[13]}]
set_property PACKAGE_PIN BB5 [get_ports {pci_exp_txp[13]}]
set_property PACKAGE_PIN BB4 [get_ports {pci_exp_txn[13]}]
set_property PACKAGE_PIN BA2 [get_ports {pci_exp_rxp[14]}]
set_property PACKAGE_PIN BA1 [get_ports {pci_exp_rxn[14]}]
set_property PACKAGE_PIN BD5 [get_ports {pci_exp_txp[14]}]
set_property PACKAGE_PIN BD4 [get_ports {pci_exp_txn[14]}]
set_property PACKAGE_PIN BC2 [get_ports {pci_exp_rxp[15]}]
set_property PACKAGE_PIN BC1 [get_ports {pci_exp_rxn[15]}]
set_property PACKAGE_PIN BF5 [get_ports {pci_exp_txp[15]}]
set_property PACKAGE_PIN BF4 [get_ports {pci_exp_txn[15]}]
#-----------------------------------------------------------------------------------
set_property -dict {PACKAGE_PIN BD21 IOSTANDARD LVCMOS12} [get_ports pci_exp_rst_n]
set_property PACKAGE_PIN AM10 [get_ports pci_exp_clk_n]
set_property PACKAGE_PIN AM11 [get_ports pci_exp_clk_p]





####################################################################################
# Constraints from file : 'c0_DDR4_mig_board.xdc'
####################################################################################

set_false_path -from [get_ports c0_sys_rst]
set_property PULLDOWN true [get_ports c0_sys_rst]
set_false_path -from [get_ports pci_exp_rst_n]
set_property PULLUP true [get_ports pci_exp_rst_n]
create_clock -period 10.000 -name sys_clk [get_ports pci_exp_clk_p]

####################################################################################
# Constraints from file : 'Block_AXI_M1S2_auto_cc_0_clocks.xdc'
####################################################################################

