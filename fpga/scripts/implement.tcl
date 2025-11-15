# scripts/implement.tcl
# Implementation (place & route) script for DFVG FPGA draft engine

set TOP_MODULE   [lindex $argv 0]
set PROJECT_NAME [lindex $argv 1]
set BUILD_DIR    [lindex $argv 2]

puts "[INFO] Implementation for top: $TOP_MODULE"
puts "[INFO] Build dir: $BUILD_DIR"

set SYNTH_DCP "$BUILD_DIR/post_synth.dcp"

if {![file exists $SYNTH_DCP]} {
    puts "[ERROR] Synthesis checkpoint not found: $SYNTH_DCP"
    exit 1
}

open_checkpoint $SYNTH_DCP

# Optimization, placement, routing
puts "[INFO] Running opt_design..."
opt_design

puts "[INFO] Running place_design..."
place_design

puts "[INFO] Running route_design..."
route_design

# Save implementation checkpoint & reports
write_checkpoint -force $BUILD_DIR/post_impl.dcp
report_timing_summary -file $BUILD_DIR/timing_impl.rpt
report_utilization    -file $BUILD_DIR/util_impl.rpt
report_power          -file $BUILD_DIR/power_impl.rpt

puts "[INFO] Implementation completed. Checkpoints and reports are in $BUILD_DIR."
