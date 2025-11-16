
set_false_path -from [get_clocks -of_objects [get_pins PCIE_TOP/XDMA_IP_i/inst/pcie4_ip_i/inst/gt_top_i/diablo_gt.diablo_gt_phy_wrapper/phy_clk_i/bufg_gt_userclk/O]] -to [get_clocks -of_objects [get_pins MIG0/inst/u_ddr4_infrastructure/gen_mmcme4.u_mmcme_adv_inst/CLKOUT0]]
set_output_delay -clock [get_clocks c0_sys_clk_p] -min -add_delay -0.050 [get_ports c0_ddr4_reset_n]
set_output_delay -clock [get_clocks c0_sys_clk_p] -max -add_delay 0.350 [get_ports c0_ddr4_reset_n]

####################################################################################
# Constraints from file : 'Block_AXI_M1S2_auto_cc_0_clocks.xdc'
####################################################################################

set_false_path -from [get_clocks -of_objects [get_pins MIG0/inst/u_ddr4_infrastructure/gen_mmcme4.u_mmcme_adv_inst/CLKOUT0]] -to [get_clocks c0_sys_clk_p]
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets clk]
