# opt_design creates the MBUFGCE used for the 200/100 MHz CPU/IO clocks.
# Apply this after optimization, before placement; it does not exist when
# floorplan.tcl is first read during link_design.
set v80_clock_pins [get_pins -quiet -hier -filter {NAME =~ */clk_wiz_0/inst/clock_primitive_inst/MBUFGCE/O1 || NAME =~ */clk_wiz_0/inst/clock_primitive_inst/MBUFGCE/O2}]
if {[llength $v80_clock_pins] == 2} {
    set v80_clock_nets [get_nets -of_objects $v80_clock_pins]
    # The shared CPU/IO tree also reaches loads outside the CPU pblock.
    # Placement selected X5Y4 when X5Y3 was requested for this layout.
    set_property USER_CLOCK_ROOT X5Y4 $v80_clock_nets
    puts "V80 CPU/IO clock root request: X5Y4 on $v80_clock_nets"
} else {
    set v80_cpu_clock [get_clocks -of_objects [get_pins -hier RocketChip/clock]]
    if {[llength $v80_cpu_clock] && abs([get_property -min PERIOD $v80_cpu_clock] - 5.0) < 0.001} {
        error "Expected both MBUFGCE clock outputs for the V80 200 MHz design"
    }
}
