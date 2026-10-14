# Module references have separate synthesis runs; top-level synthesis options
# and implementation clocks do not optimize the CPU's OOC netlist.
set board_dir [file dirname [file normalize [info script]]]
set run_pre [file join $board_dir run-pre.tcl]
if {![llength [get_files -quiet $run_pre]]} {
    add_files -norecurse -fileset utils_1 $run_pre
}
set_property STEPS.SYNTH_DESIGN.TCL.PRE $run_pre [get_runs synth_1]
set_property STEPS.INIT_DESIGN.TCL.PRE $run_pre [get_runs impl_1]
open_bd_design [get_files riscv.bd]
if {[get_property VLNV [get_bd_cells RocketChip]] eq "xilinx.com:module_ref:Rocket64w1:1.0"} {
    # Also register the floorplan when rebuilding an existing project.
    set floorplan [file join $board_dir floorplan.tcl]
    if {![llength [get_files -quiet $floorplan]]} {
        add_files -norecurse -fileset constrs_1 $floorplan
    }
    set_property FILE_TYPE TCL [get_files $floorplan]
    set_property USED_IN_SYNTHESIS false [get_files $floorplan]
    set_property PROCESSING_ORDER LATE [get_files $floorplan]
    generate_target all [get_files riscv.bd]
    if {![llength [get_runs -quiet riscv_RocketChip_0_synth_1]]} {
        create_ip_run [get_files riscv.bd]
    }
    set cpu_run [get_runs riscv_RocketChip_0_synth_1]
    set hook [file join $board_dir rocket64w1-synth-pre.tcl]
    if {![llength [get_files -quiet $hook]]} {
        add_files -norecurse -fileset utils_1 $hook
    }
    set_property strategy {Vivado Synthesis Defaults} $cpu_run
    set_property STEPS.SYNTH_DESIGN.ARGS.GLOBAL_RETIMING on $cpu_run
    set_property STEPS.SYNTH_DESIGN.TCL.PRE $hook $cpu_run
    reset_run $cpu_run
    set_property strategy Performance_ExplorePostRoutePhysOpt [get_runs impl_1]
    set_property STEPS.PLACE_DESIGN.ARGS.DIRECTIVE Explore [get_runs impl_1]
    set_property -dict [list {STEPS.PLACE_DESIGN.ARGS.MORE OPTIONS} {}] [get_runs impl_1]
    set clock_root [file join $board_dir clock-root.tcl]
    if {![llength [get_files -quiet $clock_root]]} {
        add_files -norecurse -fileset utils_1 $clock_root
    }
    set_property STEPS.PLACE_DESIGN.TCL.PRE $clock_root [get_runs impl_1]
    # Retain the original timing goal throughout routing.
    set_property STEPS.ROUTE_DESIGN.ARGS.DIRECTIVE NoTimingRelaxation [get_runs impl_1]
    set_property -dict [list {STEPS.ROUTE_DESIGN.ARGS.MORE OPTIONS} {-tns_cleanup}] [get_runs impl_1]
    set timing_check [file join $board_dir check-timing.tcl]
    if {![llength [get_files -quiet $timing_check]]} {
        add_files -norecurse -fileset utils_1 $timing_check
    }
    set_property STEPS.WRITE_DEVICE_IMAGE.TCL.PRE $timing_check [get_runs impl_1]
}
