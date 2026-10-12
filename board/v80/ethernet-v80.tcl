set files [list \
  [file normalize "../../ethernet/verilog-ethernet/rtl/eth_mac_phy_10g_fifo.v"] \
  [file normalize "../../ethernet/verilog-ethernet/rtl/eth_mac_phy_10g.v"] \
  [file normalize "../../ethernet/verilog-ethernet/rtl/eth_mac_phy_10g_rx.v"] \
  [file normalize "../../ethernet/verilog-ethernet/rtl/eth_mac_phy_10g_tx.v"] \
  [file normalize "../../ethernet/verilog-ethernet/rtl/axis_baser_rx_64.v"] \
  [file normalize "../../ethernet/verilog-ethernet/rtl/axis_baser_tx_64.v"] \
  [file normalize "../../ethernet/verilog-ethernet/rtl/eth_phy_10g_rx_if.v"] \
  [file normalize "../../ethernet/verilog-ethernet/rtl/eth_phy_10g_tx_if.v"] \
  [file normalize "../../ethernet/verilog-ethernet/rtl/eth_phy_10g_rx_ber_mon.v"] \
  [file normalize "../../ethernet/verilog-ethernet/rtl/eth_phy_10g_rx_frame_sync.v"] \
  [file normalize "../../ethernet/verilog-ethernet/rtl/eth_phy_10g_rx_watchdog.v"] \
  [file normalize "../../ethernet/verilog-ethernet/rtl/lfsr.v"] \
  [file normalize "../../ethernet/verilog-ethernet/rtl/ptp_clock_cdc.v"] \
  [file normalize "../../ethernet/verilog-ethernet/lib/axis/rtl/sync_reset.v"] \
  [file normalize "../../ethernet/verilog-ethernet/lib/axis/rtl/axis_adapter.v"] \
  [file normalize "../../ethernet/verilog-ethernet/lib/axis/rtl/axis_async_fifo.v"] \
  [file normalize "../../ethernet/verilog-ethernet/lib/axis/rtl/axis_async_fifo_adapter.v"] \
  [file normalize "../../ethernet/ethernet-versal-10g.v"] \
  [file normalize "../../ethernet/ethernet.v"] \
]
add_files -norecurse -fileset $source_fileset $files

set files [list \
  [file normalize ../../board/${vivado_board_name}/ethernet.xdc] \
  [file normalize ../../ethernet/ethernet-versal-10g.tcl] \
  [file normalize ../../ethernet/verilog-ethernet/lib/axis/syn/vivado/sync_reset.tcl] \
  [file normalize ../../ethernet/verilog-ethernet/lib/axis/syn/vivado/axis_async_fifo.tcl] \
]
add_files -norecurse -fileset $constraint_fileset $files

create_ip -name gtwiz_versal -vendor xilinx.com -library ip -module_name gtwiz_versal_0

set_property -dict [list \
    CONFIG.GT_TYPE {GTM} \
    CONFIG.INTF0_PRESET {GTM-NRZ_Ethernet_10G} \
    CONFIG.INTF0_NO_OF_LANES {1} \
    CONFIG.QUAD0_PROT0_LANES {1} \
    CONFIG.NO_OF_QUADS {1} \
    CONFIG.QUAD0_PROT0_RX1_EN {false} \
    CONFIG.QUAD0_PROT0_RX2_EN {false} \
    CONFIG.QUAD0_PROT0_RX3_EN {false} \
    CONFIG.QUAD0_PROT0_TX1_EN {false} \
    CONFIG.QUAD0_PROT0_TX2_EN {false} \
    CONFIG.QUAD0_PROT0_TX3_EN {false} \
    CONFIG.QUAD0_GT_GPIO_EN {false} \
    CONFIG.INTF0_GT_SETTINGS(LR0_SETTINGS) {
        TX_REFCLK_FREQUENCY 322.265625 RX_REFCLK_FREQUENCY 322.265625
        TX_USER_DATA_WIDTH 64 RX_USER_DATA_WIDTH 64
        TXPROGDIV_FREQ_VAL 161.133 RXPROGDIV_FREQ_VAL 161.133
    } \
] [get_ips gtwiz_versal_0]

# Expose the TX main cursor so the RTL keeps the validated drive setting.
set_property CONFIG.INTF0_OPTIONAL_PORTS {ch_txmaincursor true} [get_ips gtwiz_versal_0]

create_ip -name clk_wizard -vendor xilinx.com -library ip -module_name ethernet_pcs_clock

# Exact GT-word-to-PCS ratio; the generated module is instantiated once per direction.
set_property -dict [list \
    CONFIG.PRIM_IN_FREQ {161.133} \
    CONFIG.PRIM_SOURCE {Global_buffer} \
    CONFIG.CLKOUT_REQUESTED_OUT_FREQUENCY {156.25,100,100,100,100,100,100} \
    CONFIG.CLKOUT_USED {true,false,false,false,false,false,false} \
    CONFIG.USE_RESET {false} \
    CONFIG.USE_LOCKED {true} \
    CONFIG.OVERRIDE_PRIMITIVE {true} \
    CONFIG.CLKFBOUT_MULT {192} \
    CONFIG.DIVCLK_DIVIDE {11} \
    CONFIG.CLKOUT1_DIVIDE {18} \
] [get_ips ethernet_pcs_clock]
