set board_dir [file dirname [file normalize [info script]]]
source [file join $board_dir run-pre.tcl]
set clock_file [file join $board_dir rocket64w1-ooc.xdc]
read_xdc $clock_file
set_property USED_IN {synthesis out_of_context} [get_files $clock_file]
