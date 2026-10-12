# UART1 uses PS_MIO 20 (RX) and 21 (TX), configured by CIPS.
# These dedicated MIO pads are not PL ports and must not receive PACKAGE_PIN.

# UART status is in the 100 MHz domain. The Rocket wrapper samples its
# interrupt through three ASYNC_REG stages in the CPU domain. Bound the
# path into the first stage to one CPU cycle, as for the other peripheral
# interrupt CDCs in timing-constraints.tcl.
set v80_cpu_clock [get_clocks -of_objects [get_pins -hier RocketChip/clock]]
set v80_uart_clock [get_clocks -of_objects [get_pins -hier -filter {NAME =~ */IO/UART/clock}]]
set_max_delay -datapath_only [get_property -min PERIOD $v80_cpu_clock] \
    -from $v80_uart_clock \
    -through [get_pins -hier -filter {NAME =~ */IO/UART/interrupt}] \
    -to [get_pins -hier -filter {NAME =~ */RocketChip/inst/interrupts_ss1_reg*/D}]
