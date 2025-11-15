# scripts/generate_bitstream.tcl
# Bitstream generation script for DFVG FPGA draft engine

set TOP_MODULE   [lindex $argv 0]
set PROJECT_NAME [lindex $argv 1]
set BUILD_DIR    [lindex $argv 2]

puts "[INFO] Generating bitstream for top: $TOP_MODULE"
puts "[INFO] Build dir : $BUILD_DIR"
puts "[INFO] Project   : $PROJECT_NAME"

set IMPL_DCP "$BUILD_DIR/post_impl.dcp"
set BIT_FILE "$BUILD_DIR/$PROJECT_NAME.bit"

if {![file exists $IMPL_DCP]} {
    puts "[ERROR] Implementation checkpoint not found: $IMPL_DCP"
    exit 1
}

open_checkpoint $IMPL_DCP

puts "[INFO] Writing bitstream to $BIT_FILE..."
write_bitstream -force $BIT_FILE

puts "[INFO] Bitstream generation completed."
puts "[INFO] Output bitstream: $BIT_FILE"
