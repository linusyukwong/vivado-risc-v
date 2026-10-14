# Synthesis-only clocks for the separately synthesized module reference.
# Implementation derives both clocks from the actual MMCM and CIPS pins.
create_clock -name cpu_ooc -period 5.000 [get_ports clock]
create_clock -name jtag_ooc -period 15.000 [get_ports S_BSCAN_tck]
set_max_delay -datapath_only 5.000 -from [get_clocks jtag_ooc] -to [get_clocks cpu_ooc]
set_max_delay -datapath_only 15.000 -from [get_clocks cpu_ooc] -to [get_clocks jtag_ooc]
