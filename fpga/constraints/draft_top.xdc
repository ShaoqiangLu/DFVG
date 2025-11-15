###############################################
# Clock & Reset constraints for draft_top
###############################################

# Primary clock: clk (e.g., 200 MHz)
# TODO: change PACKAGE_PIN and IOSTANDARD according to your board.
set_property PACKAGE_PIN <CLK_PIN> [get_ports clk]
set_property IOSTANDARD LVCMOS18 [get_ports clk]
create_clock -name sys_clk -period 5.000 [get_ports clk]  ; # 200 MHz

# Active-low reset: rst_n
# TODO: change PACKAGE_PIN and IOSTANDARD according to your board.
set_property PACKAGE_PIN <RST_PIN> [get_ports rst_n]
set_property IOSTANDARD LVCMOS18 [get_ports rst_n]
set_property PULLUP true [get_ports rst_n]

# Optional: mark reset as asynchronous
set_false_path -from [get_ports rst_n]

###############################################
# Example GPIOs (optional, placeholder)
###############################################

# Example output bus: debug_bus[7:0]
# TODO: change pins to match your board if you actually use these ports.
# set_property PACKAGE_PIN <PIN0> [get_ports {debug_bus[0]}]
# set_property PACKAGE_PIN <PIN1> [get_ports {debug_bus[1]}]
# set_property IOSTANDARD LVCMOS18 [get_ports {debug_bus[*]}]

###############################################
# Timing / Misc constraints
###############################################

# Allow Vivado to ignore paths that are purely debug
# set_false_path -to [get_ports {debug_bus[*]}]
