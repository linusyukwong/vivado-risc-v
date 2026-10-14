# Refine the nearly closed 200 MHz Rocket64w1 implementation before the final
# timing gate. These commands change physical routing, never timing exceptions.
proc v80_hold_path_branches {report} {
    set result {}
    set blocks [split [string map [list "Slack (" "\u0000"] $report] "\u0000"]
    foreach block [lrange $blocks 1 end] {
        if {![regexp {: +(-?[0-9.]+)ns} $block -> slack] || $slack >= 0} {continue}
        set separators 0
        set pins {}
        foreach line [split $block "\n"] {
            if {[regexp {^  -{10,}} $line]} {
                incr separators
                if {$separators > 2} {break}
                continue
            }
            if {$separators == 2 && [regexp {^\s+(riscv_i/\S+)\s*$} $line -> pin]} {
                lappend pins $pin
            }
        }
        if {[llength $pins]} {lappend result $pins}
    }
    return $result
}

proc v80_refine_timing {} {
    set cpu [get_cells -quiet -hier -filter {ORIG_REF_NAME == Rocket64w1 || REF_NAME =~ *Rocket64w1}]
    set clock [get_clocks -quiet clkout1_primitive]
    if {[llength $cpu] != 1 || [llength $clock] != 1 ||
        abs([get_property PERIOD $clock] - 5.0) > 0.001} {return}
    set setup_bad [get_timing_paths -quiet -delay_type max -slack_lesser_than 0 -max_paths 1]
    set hold_bad [get_timing_paths -quiet -delay_type min -slack_lesser_than 0 -max_paths 1]
    if {![llength $setup_bad] && ![llength $hold_bad]} {return}

    # Preserve any original user uncertainty commands. The board normally has
    # zero user uncertainty; MMCM/clock jitter remains part of ordinary STA.
    write_xdc -force v80_pre_refine.xdc
    set fd [open v80_pre_refine.xdc r]
    set original_uncertainty {}
    set command ""
    foreach line [split [read $fd] "\n"] {
        append command $line "\n"
        if {![info complete $command]} {continue}
        if {[regexp {^\s*set_clock_uncertainty\s} $command]} {
            lappend original_uncertainty $command
        }
        set command ""
    }
    close $fd

    phys_opt_design -clock_opt
    # Tighten optimization by 100 ps, then restore the original constraints
    # before any acceptance report or device image is written.
    set_clock_uncertainty -setup 0.100 $clock
    phys_opt_design -directive AggressiveExplore
    route_design -directive NoTimingRelaxation -tns_cleanup
    phys_opt_design -directive Explore
    set_clock_uncertainty -setup 0.000 $clock
    foreach command $original_uncertainty {uplevel #0 $command}
    write_checkpoint -force riscv_wrapper_refined.dcp

    # Delay short input branches with ample setup slack. Delaying a shared
    # output net can hurt an unrelated critical setup path after its mux.
    for {set pass 0} {$pass < 3} {incr pass} {
        set failing [get_timing_paths -quiet -delay_type min -slack_lesser_than 0 -max_paths 100]
        if {![llength $failing]} {break}
        if {[llength $failing] >= 100} {break}
        set report [report_timing -delay_type min -max_paths 100 -input_pins -return_string]
        set done [dict create]
        foreach candidates [v80_hold_path_branches $report] {
            foreach name $candidates {
                set pin [get_pins -quiet $name]
                if {![llength $pin] || [get_property DIRECTION $pin] ne "IN"} {continue}
                if {[dict exists $done $name]} {break}
                set hold [get_timing_paths -delay_type min -through $pin -max_paths 1]
                set hold_slack [get_property SLACK $hold]
                if {$hold_slack >= 0} {break}
                set setup [get_timing_paths -delay_type max -through $pin -max_paths 1]
                set setup_slack [get_property SLACK $setup]
                if {$setup_slack < 0.200} {continue}
                set nd [get_net_delays -of_objects [get_nets -of_objects $pin] -to $pin -interconnect_only]
                if {[llength $nd] != 1} {continue}
                set target [expr {int(ceil([get_property FAST_MIN $nd] - 1000.0*$hold_slack + 25.0))}]
                set max_target [expr {int(ceil([get_property SLOW_MAX $nd] + min(500.0, 500.0*$setup_slack)))}]
                puts "V80 hold branch: $name; setup $setup_slack ns; min/max routing $target/$max_target ps"
                route_design -unroute -pins $pin
                route_design -pins $pin -min_delay $target -max_delay $max_target
                dict set done $name 1
                break
            }
        }
        if {![dict size $done]} {break}
        route_design -finalize
    }
    report_route_status -file v80_route_status.rpt
}

v80_refine_timing
