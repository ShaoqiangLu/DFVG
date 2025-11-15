# scripts/synthesize.tcl
# Synthesis script for DFVG FPGA draft engine (non-project flow)

# Arguments:
#   argv0: top module name (e.g., draft_top)
#   argv1: project name  (unused but kept for compatibility)
#   argv2: build directory

set TOP_MODULE   [lindex $argv 0]
set PROJECT_NAME [lindex $argv 1]
set BUILD_DIR    [lindex $argv 2]

# TODO: change this to your actual FPGA part number
set PART "xczu3eg-sbva484-1"

puts "[INFO] Top module   : $TOP_MODULE"
puts "[INFO] Project name : $PROJECT_NAME"
puts "[INFO] Build dir    : $BUILD_DIR"
puts "[INFO] Part         : $PART"

file mkdir $BUILD_DIR

# Read RTL sources
# You can extend these glob patterns if needed.
set verilog_files  [glob -nocomplain ./src/*.v]
set sv_files       [glob -nocomplain ./src/*.sv]
set vhdl_files     [glob -nocomplain ./src/*.vhd]

if {[llength $verilog_files] > 0} {
    puts "[INFO] Reading Verilog files: $verilog_files"
    read_verilog $verilog_files
}
if {[llength $sv_files] > 0} {
    puts "[INFO] Reading SystemVerilog files: $sv_files"
    read_verilog -sv $sv_files
}
if {[llength $vhdl_files] > 0} {
    puts "[INFO] Reading VHDL files: $vhdl_files"
    read_vhdl $vhdl_files
}

# Read constraints
set xdc_files [glob -nocomplain ./constraints/*.xdc]
if {[llength $xdc_files] > 0} {
    puts "[INFO] Reading XDC constraints: $xdc_files"
    read_xdc $xdc_files
} else {
    puts "[WARN] No XDC constraint files found under ./constraints/"
}

# Run synthesis
puts "[INFO] Running synth_design..."
synth_design -top $TOP_MODULE -part $PART

# Save synthesis results
write_checkpoint -force $BUILD_DIR/post_synth.dcp
report_timing_summary    -file $BUILD_DIR/timing_synth.rpt
report_utilization       -file $BUILD_DIR/util_synth.rpt

puts "[INFO] Synthesis completed. Checkpoints and reports are in $BUILD_DIR."
