# Do not emit a PDI that fails the requested CPU clock's setup/hold timing.
source [file join [file dirname [file normalize [info script]]] refine-timing.tcl]
report_timing_summary -delay_type min_max -report_unconstrained \
    -check_timing_verbose -file v80_timing_summary.rpt
report_timing -delay_type max -max_paths 50 -file v80_critical_paths.rpt
report_bus_skew -file v80_bus_skew.rpt
foreach delay {max min} {
    set failing [get_timing_paths -quiet -delay_type $delay -slack_lesser_than 0 -max_paths 1]
    if {[llength $failing]} {
        error "V80 $delay timing failed: slack [get_property SLACK $failing] ns; see v80_timing_summary.rpt"
    }
}
write_checkpoint -force riscv_wrapper_timing_closed.dcp
