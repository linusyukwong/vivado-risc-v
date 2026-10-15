
################################################################
# This is a generated script based on design: riscv
#
# Though there are limitations about the generated script,
# the main purpose of this utility is to make learning
# IP Integrator Tcl commands easier.
################################################################

namespace eval _tcl {
proc get_script_folder {} {
   set script_path [file normalize [info script]]
   set script_folder [file dirname $script_path]
   return $script_folder
}
}
variable script_folder
set script_folder [_tcl::get_script_folder]

################################################################
# Check if script is running in correct Vivado version.
################################################################
set scripts_vivado_version 2025.2
set current_vivado_version [version -short]

if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
   puts ""
   catch {common::send_gid_msg -ssname BD::TCL -id 2041 -severity "ERROR" "This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Please run the script in Vivado <$scripts_vivado_version> then open the design in Vivado <$current_vivado_version>. Upgrade the design by running \"Tools => Report => Report IP Status...\", then run write_bd_tcl to create an updated script."}

   return 1
}

################################################################
# START
################################################################

# CHANGE DESIGN NAME HERE
variable design_name
set design_name riscv
create_bd_design $design_name
current_bd_design $design_name

set files [list \
  [file join $script_folder uart-router.v] \
  [file join $script_folder memory-address.v] \
]
add_files -norecurse -fileset $source_fileset $files

##################################################################
# DESIGN PROCs
##################################################################

# Hierarchical cell: IO
proc create_hier_cell_IO { parentCell nameHier } {

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]
  set parentObj [get_bd_cells $parentCell]
  current_bd_instance $parentObj
  set dma_intf [get_bd_intf_pins RocketChip/DMA_AXI4]

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S01_AXI
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M00_AXI
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M01_AXI
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:gt_rtl:1.0 qsfp
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 qsfp_refclk

  # Create pins
  create_bd_pin -dir I -type clk axi_clock
  create_bd_pin -dir I -type clk clock100MHz
  create_bd_pin -dir I -type rst axi_reset
  create_bd_pin -dir I -type rst uart_resetn
  create_bd_pin -dir I mdio_int
  create_bd_pin -dir O uart_interrupt
  create_bd_pin -dir O ethernet_interrupt

  # Create instance: Control, and set properties
  set Control [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 Control ]
  set_property -dict [list CONFIG.NUM_SI 1 CONFIG.NUM_MI 2 CONFIG.NUM_CLKS 2] $Control

  # Create instance: UART
  set UART [ create_bd_cell -type module -reference v80_uart_router UART ]

  # Create instance: PS_UART, and set properties
  set PS_UART [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 PS_UART ]
  set_property -dict [list CONFIG.NUM_SI 1 CONFIG.NUM_MI 1] $PS_UART

  # Create instance: Ethernet, and set properties
  set Ethernet [ create_bd_cell -type module -reference ethernet Ethernet ]
  set_property -dict [list CONFIG.axis_word_bits 64 \
      CONFIG.dma_word_bits [get_property CONFIG.DATA_WIDTH $dma_intf] CONFIG.enable_mdio 0 \
      CONFIG.dma_addr_bits [get_property CONFIG.ADDR_WIDTH $dma_intf]] $Ethernet

  # Create instance: ethernet_versal_10g_0
  set ethernet_versal_10g_0 [ create_bd_cell -type module -reference ethernet_versal_10g ethernet_versal_10g_0 ]

  # Create interface connections
  connect_bd_intf_net [get_bd_intf_pins S01_AXI] [get_bd_intf_pins Control/S00_AXI]
  connect_bd_intf_net [get_bd_intf_pins M00_AXI] [get_bd_intf_pins PS_UART/M00_AXI]
  connect_bd_intf_net [get_bd_intf_pins M01_AXI] [get_bd_intf_pins Ethernet/M_AXI]
  connect_bd_intf_net [get_bd_intf_pins qsfp] [get_bd_intf_pins ethernet_versal_10g_0/QSFP]
  connect_bd_intf_net [get_bd_intf_pins qsfp_refclk] [get_bd_intf_pins ethernet_versal_10g_0/QSFP_REFCLK]
  connect_bd_intf_net [get_bd_intf_pins Ethernet/TX_AXIS] [get_bd_intf_pins ethernet_versal_10g_0/ETH0_TX_AXIS]
  connect_bd_intf_net [get_bd_intf_pins ethernet_versal_10g_0/ETH0_RX_AXIS] [get_bd_intf_pins Ethernet/RX_AXIS]
  connect_bd_intf_net [get_bd_intf_pins Control/M00_AXI] [get_bd_intf_pins UART/S_AXI]
  connect_bd_intf_net [get_bd_intf_pins UART/M_AXI] [get_bd_intf_pins PS_UART/S00_AXI]
  connect_bd_intf_net [get_bd_intf_pins Control/M01_AXI] [get_bd_intf_pins Ethernet/S_AXI_LITE]

  # Create port connections
  connect_bd_net [get_bd_pins axi_clock] [get_bd_pins Control/aclk] \
      [get_bd_pins Ethernet/clock] [get_bd_pins ethernet_versal_10g_0/eth_clock]
  connect_bd_net [get_bd_pins clock100MHz] [get_bd_pins Control/aclk1] \
      [get_bd_pins UART/clock] [get_bd_pins PS_UART/aclk]
  connect_bd_net [get_bd_pins axi_reset] [get_bd_pins Control/aresetn] \
      [get_bd_pins Ethernet/async_resetn] [get_bd_pins ethernet_versal_10g_0/eth_resetn]
  connect_bd_net [get_bd_pins uart_resetn] [get_bd_pins UART/resetn] [get_bd_pins PS_UART/aresetn]
  connect_bd_net [get_bd_pins mdio_int] [get_bd_pins Ethernet/mdio_int]
  connect_bd_net [get_bd_pins uart_interrupt] [get_bd_pins UART/interrupt]
  connect_bd_net [get_bd_pins ethernet_interrupt] [get_bd_pins Ethernet/interrupt]
  connect_bd_net [get_bd_pins ethernet_versal_10g_0/eth_status] [get_bd_pins Ethernet/status_vector]

  # Restore current instance
  current_bd_instance $oldCurInst
}


# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell } {

  variable script_folder
  variable design_name
  variable rocket_memory_channel_name
  global riscv_clock_frequency

  if { $parentCell eq "" } {
    set parentCell [get_bd_cells /]
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]
  set parentObj [get_bd_cells $parentCell]
  current_bd_instance $parentObj

  # Create interface ports
  set sys_clk0_1 [create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 sys_clk0_1]
  set_property CONFIG.FREQ_HZ 200000000 $sys_clk0_1
  set CH0_DDR4_0_1 [create_bd_intf_port -mode Master -vlnv xilinx.com:interface:ddr4_rtl:1.0 CH0_DDR4_0_1]
  set qsfp0_4x [create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gt_rtl:1.0 qsfp0_4x]
  set qsfp0_322mhz [create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 qsfp0_322mhz]
  set_property CONFIG.FREQ_HZ 322265625 $qsfp0_322mhz

  # Create instance: CIPS, and set properties
  set CIPS [ create_bd_cell -type ip -vlnv xilinx.com:ip:versal_cips:3.4 CIPS ]
  # MIO voltages and peripheral routing copied from AVED 25.1.
  set ps_pmc_config { \
        BOOT_MODE {Custom} \
        CLOCK_MODE {Custom} \
        DDR_MEMORY_MODE {Custom} \
        DESIGN_MODE {1} \
        DEVICE_INTEGRITY_MODE {Custom} \
        IO_CONFIG_MODE {Custom} \
        PCIE_APERTURES_DUAL_ENABLE {0} \
        PCIE_APERTURES_SINGLE_ENABLE {1} \
        PMC_BANK_1_IO_STANDARD {LVCMOS3.3} \
        PMC_CRP_OSPI_REF_CTRL_FREQMHZ {200} \
        PMC_CRP_PL0_REF_CTRL_FREQMHZ {100} \
        PMC_CRP_PL1_REF_CTRL_FREQMHZ {33.3333333} \
        PMC_CRP_PL2_REF_CTRL_FREQMHZ {250} \
        PMC_GLITCH_CONFIG {{DEPTH_SENSITIVITY 1} {MIN_PULSE_WIDTH 0.5} {TYPE CUSTOM} {VCC_PMC_VALUE 0.88}} \
        PMC_GLITCH_CONFIG_1 {{DEPTH_SENSITIVITY 1} {MIN_PULSE_WIDTH 0.5} {TYPE CUSTOM} {VCC_PMC_VALUE 0.88}} \
        PMC_GLITCH_CONFIG_2 {{DEPTH_SENSITIVITY 1} {MIN_PULSE_WIDTH 0.5} {TYPE CUSTOM} {VCC_PMC_VALUE 0.88}} \
        PMC_GPIO_EMIO_PERIPHERAL_ENABLE {0} \
        PMC_MIO11 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE GPIO}} \
        PMC_MIO12 {{AUX_IO 0} {DIRECTION out} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE GPIO}} \
        PMC_MIO13 {{AUX_IO 0} {DIRECTION inout} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Reserved}} \
        PMC_MIO17 {{AUX_IO 0} {DIRECTION out} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE GPIO}} \
        PMC_MIO26 {{AUX_IO 0} {DIRECTION out} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE GPIO}} \
        PMC_MIO27 {{AUX_IO 0} {DIRECTION out} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE GPIO}} \
        PMC_MIO28 {{AUX_IO 0} {DIRECTION out} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE GPIO}} \
        PMC_MIO29 {{AUX_IO 0} {DIRECTION out} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE GPIO}} \
        PMC_MIO30 {{AUX_IO 0} {DIRECTION out} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE GPIO}} \
        PMC_MIO31 {{AUX_IO 0} {DIRECTION out} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE GPIO}} \
        PMC_MIO32 {{AUX_IO 0} {DIRECTION out} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE GPIO}} \
        PMC_MIO33 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE GPIO}} \
        PMC_MIO34 {{AUX_IO 0} {DIRECTION out} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE GPIO}} \
        PMC_MIO35 {{AUX_IO 0} {DIRECTION out} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE GPIO}} \
        PMC_MIO36 {{AUX_IO 0} {DIRECTION out} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE GPIO}} \
        PMC_MIO37 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE GPIO}} \
        PMC_MIO38 {{AUX_IO 0} {DIRECTION out} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE GPIO}} \
        PMC_MIO39 {{AUX_IO 0} {DIRECTION out} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE GPIO}} \
        PMC_MIO40 {{AUX_IO 0} {DIRECTION out} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE GPIO}} \
        PMC_MIO41 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE GPIO}} \
        PMC_MIO42 {{AUX_IO 0} {DIRECTION out} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE GPIO}} \
        PMC_MIO43 {{AUX_IO 0} {DIRECTION out} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE GPIO}} \
        PMC_MIO44 {{AUX_IO 0} {DIRECTION out} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE GPIO}} \
        PMC_MIO48 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE GPIO}} \
        PMC_MIO49 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE GPIO}} \
        PMC_MIO50 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE GPIO}} \
        PMC_MIO51 {{AUX_IO 0} {DIRECTION out} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE GPIO}} \
        PMC_MIO_EN_FOR_PL_PCIE {0} \
        PMC_OSPI_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 0 .. 11}} {MODE Single}} \
        PMC_REF_CLK_FREQMHZ {33.333333} \
        PMC_SD0_DATA_TRANSFER_MODE {8Bit} \
        PMC_SD0_PERIPHERAL {{CLK_100_SDR_OTAP_DLY 0x00} {CLK_200_SDR_OTAP_DLY 0x2} {CLK_50_DDR_ITAP_DLY 0x1E} {CLK_50_DDR_OTAP_DLY 0x5} {CLK_50_SDR_ITAP_DLY 0x2C} {CLK_50_SDR_OTAP_DLY 0x5} {ENABLE 1} {IO\
  {PMC_MIO 13 .. 25}}} \
        PMC_SD0_SLOT_TYPE {eMMC} \
        PMC_USE_PMC_NOC_AXI0 {0} \
        PS_BANK_2_IO_STANDARD {LVCMOS3.3} \
        PS_BOARD_INTERFACE {Custom} \
        PS_CRL_CPM_TOPSW_REF_CTRL_FREQMHZ {1000} \
        PS_GEN_IPI0_ENABLE {0} \
        PS_GEN_IPI1_ENABLE {0} \
        PS_GEN_IPI2_ENABLE {0} \
        PS_GEN_IPI3_ENABLE {1} \
        PS_GEN_IPI3_MASTER {R5_0} \
        PS_GEN_IPI4_ENABLE {1} \
        PS_GEN_IPI4_MASTER {R5_0} \
        PS_GEN_IPI5_ENABLE {1} \
        PS_GEN_IPI5_MASTER {R5_1} \
        PS_GEN_IPI6_ENABLE {1} \
        PS_GEN_IPI6_MASTER {R5_1} \
        PS_GPIO_EMIO_PERIPHERAL_ENABLE {0} \
        PS_I2C0_PERIPHERAL {{ENABLE 1} {IO {PS_MIO 2 .. 3}}} \
        PS_I2C1_PERIPHERAL {{ENABLE 1} {IO {PS_MIO 0 .. 1}}} \
        PS_IRQ_USAGE {{CH0 1} {CH1 1} {CH10 0} {CH11 0} {CH12 0} {CH13 0} {CH14 0} {CH15 0} {CH2 0} {CH3 0} {CH4 0} {CH5 0} {CH6 0} {CH7 0} {CH8 0} {CH9 0}} \
        PS_KAT_ENABLE {0} \
        PS_KAT_ENABLE_1 {0} \
        PS_KAT_ENABLE_2 {0} \
        PS_MIO10 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE GPIO}} \
        PS_MIO11 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE GPIO}} \
        PS_MIO12 {{AUX_IO 0} {DIRECTION inout} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Reserved}} \
        PS_MIO13 {{AUX_IO 0} {DIRECTION out} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE GPIO}} \
        PS_MIO14 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE GPIO}} \
        PS_MIO18 {{AUX_IO 0} {DIRECTION out} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE GPIO}} \
        PS_MIO19 {{AUX_IO 0} {DIRECTION out} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE GPIO}} \
        PS_MIO22 {{AUX_IO 0} {DIRECTION out} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE GPIO}} \
        PS_MIO23 {{AUX_IO 0} {DIRECTION out} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE GPIO}} \
        PS_MIO24 {{AUX_IO 0} {DIRECTION out} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE GPIO}} \
        PS_MIO25 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE GPIO}} \
        PS_MIO4 {{AUX_IO 0} {DIRECTION out} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE GPIO}} \
        PS_MIO5 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE GPIO}} \
        PS_MIO6 {{AUX_IO 0} {DIRECTION out} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE GPIO}} \
        PS_MIO7 {{AUX_IO 0} {DIRECTION out} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE GPIO}} \
        PS_MIO8 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE Reserved}} \
        PS_MIO9 {{AUX_IO 0} {DIRECTION out} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 1} {SLEW slow} {USAGE Reserved}} \
        PS_M_AXI_LPD_DATA_WIDTH {32} \
        PS_NUM_FABRIC_RESETS {1} \
        PS_PCIE1_PERIPHERAL_ENABLE {0} \
        PS_PCIE2_PERIPHERAL_ENABLE {0} \
        PS_PCIE_EP_RESET1_IO {PMC_MIO 24} \
        PS_PCIE_EP_RESET2_IO {PMC_MIO 25} \
        PS_PCIE_RESET {ENABLE 0} \
        PS_PL_CONNECTIVITY_MODE {Custom} \
        PS_SPI0 {{GRP_SS0_ENABLE 1} {GRP_SS0_IO {PS_MIO 15}} {GRP_SS1_ENABLE 0} {GRP_SS1_IO {PMC_MIO 14}} {GRP_SS2_ENABLE 0} {GRP_SS2_IO {PMC_MIO 13}} {PERIPHERAL_ENABLE 1} {PERIPHERAL_IO {PS_MIO 12 .. 17}}}\
  \
        PS_SPI1 {{GRP_SS0_ENABLE 0} {GRP_SS0_IO {PS_MIO 9}} {GRP_SS1_ENABLE 0} {GRP_SS1_IO {PS_MIO 8}} {GRP_SS2_ENABLE 0} {GRP_SS2_IO {PS_MIO 7}} {PERIPHERAL_ENABLE 0} {PERIPHERAL_IO {PS_MIO 6 .. 11}}} \
        PS_TTC0_PERIPHERAL_ENABLE {1} \
        PS_TTC1_PERIPHERAL_ENABLE {1} \
        PS_TTC2_PERIPHERAL_ENABLE {1} \
        PS_TTC3_PERIPHERAL_ENABLE {1} \
        PS_UART0_PERIPHERAL {{ENABLE 1} {IO {PS_MIO 8 .. 9}}} \
        PS_UART1_PERIPHERAL {{ENABLE 1} {IO {PS_MIO 20 .. 21}}} \
        PS_USE_FPD_CCI_NOC {0} \
        PS_USE_M_AXI_FPD {0} \
        PS_USE_M_AXI_LPD {0} \
        PS_USE_NOC_LPD_AXI0 {0} \
        PS_USE_PMCPL_CLK0 {1} \
        PS_USE_PMCPL_CLK1 {0} \
        PS_USE_PMCPL_CLK2 {0} \
        PS_USE_S_AXI_LPD {1} \
        SMON_ALARMS {Set_Alarms_On} \
        SMON_ENABLE_TEMP_AVERAGING {0} \
        SMON_MEAS100 {{ALARM_ENABLE 1} {ALARM_LOWER 0.00} {ALARM_UPPER 4.00} {AVERAGE_EN 0} {ENABLE 1} {MODE {4 V unipolar}} {NAME VCCO_500} {SUPPLY_NUM 9}} \
        SMON_MEAS101 {{ALARM_ENABLE 1} {ALARM_LOWER 0.00} {ALARM_UPPER 4.00} {AVERAGE_EN 0} {ENABLE 1} {MODE {4 V unipolar}} {NAME VCCO_501} {SUPPLY_NUM 10}} \
        SMON_MEAS102 {{ALARM_ENABLE 1} {ALARM_LOWER 0.00} {ALARM_UPPER 4.00} {AVERAGE_EN 0} {ENABLE 1} {MODE {4 V unipolar}} {NAME VCCO_502} {SUPPLY_NUM 11}} \
        SMON_MEAS103 {{ALARM_ENABLE 1} {ALARM_LOWER 0.00} {ALARM_UPPER 4.00} {AVERAGE_EN 0} {ENABLE 1} {MODE {4 V unipolar}} {NAME VCCO_503} {SUPPLY_NUM 12}} \
        SMON_MEAS104 {{ALARM_ENABLE 1} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 1} {MODE {2 V unipolar}} {NAME VCCO_700} {SUPPLY_NUM 13}} \
        SMON_MEAS105 {{ALARM_ENABLE 1} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 1} {MODE {2 V unipolar}} {NAME VCCO_701} {SUPPLY_NUM 14}} \
        SMON_MEAS106 {{ALARM_ENABLE 1} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 1} {MODE {2 V unipolar}} {NAME VCCO_702} {SUPPLY_NUM 15}} \
        SMON_MEAS118 {{ALARM_ENABLE 1} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 1} {MODE {2 V unipolar}} {NAME VCC_PMC} {SUPPLY_NUM 0}} \
        SMON_MEAS119 {{ALARM_ENABLE 1} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 1} {MODE {2 V unipolar}} {NAME VCC_PSFP} {SUPPLY_NUM 1}} \
        SMON_MEAS120 {{ALARM_ENABLE 1} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 1} {MODE {2 V unipolar}} {NAME VCC_PSLP} {SUPPLY_NUM 2}} \
        SMON_MEAS121 {{ALARM_ENABLE 1} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 1} {MODE {2 V unipolar}} {NAME VCC_RAM} {SUPPLY_NUM 3}} \
        SMON_MEAS122 {{ALARM_ENABLE 1} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 1} {MODE {2 V unipolar}} {NAME VCC_SOC} {SUPPLY_NUM 4}} \
        SMON_MEAS47 {{ALARM_ENABLE 1} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 1} {MODE {2 V unipolar}} {NAME GTYP_AVCCAUX_104} {SUPPLY_NUM 20}} \
        SMON_MEAS48 {{ALARM_ENABLE 1} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 1} {MODE {2 V unipolar}} {NAME GTYP_AVCCAUX_105} {SUPPLY_NUM 21}} \
        SMON_MEAS64 {{ALARM_ENABLE 1} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 1} {MODE {2 V unipolar}} {NAME GTYP_AVCC_104} {SUPPLY_NUM 18}} \
        SMON_MEAS65 {{ALARM_ENABLE 1} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 1} {MODE {2 V unipolar}} {NAME GTYP_AVCC_105} {SUPPLY_NUM 19}} \
        SMON_MEAS81 {{ALARM_ENABLE 1} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 1} {MODE {2 V unipolar}} {NAME GTYP_AVTT_104} {SUPPLY_NUM 22}} \
        SMON_MEAS82 {{ALARM_ENABLE 1} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 1} {MODE {2 V unipolar}} {NAME GTYP_AVTT_105} {SUPPLY_NUM 23}} \
        SMON_MEAS96 {{ALARM_ENABLE 1} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 1} {MODE {2 V unipolar}} {NAME VCCAUX} {SUPPLY_NUM 6}} \
        SMON_MEAS97 {{ALARM_ENABLE 1} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 1} {MODE {2 V unipolar}} {NAME VCCAUX_PMC} {SUPPLY_NUM 7}} \
        SMON_MEAS98 {{ALARM_ENABLE 1} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 1} {MODE {2 V unipolar}} {NAME VCCAUX_SMON} {SUPPLY_NUM 8}} \
        SMON_MEAS99 {{ALARM_ENABLE 1} {ALARM_LOWER 0.00} {ALARM_UPPER 2.00} {AVERAGE_EN 0} {ENABLE 1} {MODE {2 V unipolar}} {NAME VCCINT} {SUPPLY_NUM 5}} \
        SMON_TEMP_AVERAGING_SAMPLES {0} \
        SMON_VOLTAGE_AVERAGING_SAMPLES {8} \
        PS_USE_BSCAN_USER1 {1} \
        PS_S_AXI_LPD_DATA_WIDTH {32} \
        PS_CRL_UART1_REF_CTRL_FREQMHZ {100} \
      }
  set_property -dict [list CONFIG.PS_PMC_CONFIG $ps_pmc_config CONFIG.PS_PMC_CONFIG_APPLIED 1] $CIPS

  # Create instance: clk_wiz_0, and set properties
  set clk_wiz_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wizard:1.0 clk_wiz_0 ]
  set_property -dict [list CONFIG.PRIM_IN_FREQ 100 CONFIG.PRIM_SOURCE Global_buffer \
      CONFIG.CLKOUT_REQUESTED_OUT_FREQUENCY "$riscv_clock_frequency,100,100,100,100,100,100" \
      CONFIG.CLKOUT_USED {true,true,false,false,false,false,false} CONFIG.USE_RESET false CONFIG.USE_LOCKED true] $clk_wiz_0

  # Create instance: RocketChip
  create_rocketchip_instance
  set rocket_bscan [get_bd_intf_pins -quiet RocketChip/S_BSCAN]
  if {[llength $rocket_bscan] != 1} {
    error "V80 requires RocketChip/S_BSCAN. Regenerate rocket.vhdl with VHDL_OPTIONS=-e using make BOARD=v80."
  }

  # Create instance: zero, and set properties
  set zero [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilconstant:1.0 zero ]
  set_property CONFIG.CONST_VAL 0 $zero

  # Create instance: reset_inv, and set properties
  set reset_inv [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilvector_logic:1.0 reset_inv ]
  set_property -dict [list CONFIG.C_OPERATION not CONFIG.C_SIZE 1] $reset_inv

  # Create instance: Memory_Address, and set properties
  set Memory_Address [ create_bd_cell -type module -reference v80_memory_address Memory_Address ]
  set mem_intf [get_bd_intf_pins [eval $rocket_memory_channel_name 0]]
  set_property -dict [list CONFIG.DATA_WIDTH [get_property CONFIG.DATA_WIDTH $mem_intf] \
      CONFIG.ID_WIDTH [get_property CONFIG.ID_WIDTH $mem_intf]] $Memory_Address

  # Create instance: DDR, and set properties
  set DDR [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_noc:1.1 DDR ]
  # V80 32 GiB ECC DDR4 RDIMM profile from AVED's axi_noc_mc_ddr4_1.
  # Use a direct PL AXI slave instead of AVED's two INI slave ports.
  set_property -dict [list \
      CONFIG.CONTROLLERTYPE {DDR4_SDRAM} \
      CONFIG.MC0_CONFIG_NUM {config21} \
      CONFIG.MC0_FLIPPED_PINOUT {false} \
      CONFIG.MC_CHAN_REGION0 {DDR_CH2} \
      CONFIG.MC_COMPONENT_WIDTH {x4} \
      CONFIG.MC_DATAWIDTH {72} \
      CONFIG.MC_INIT_MEM_USING_ECC_SCRUB {true} \
      CONFIG.MC_INPUTCLK0_PERIOD {5000} \
      CONFIG.MC_MEMORY_DEVICETYPE {RDIMMs} \
      CONFIG.MC_MEMORY_SPEEDGRADE {DDR4-3200AA(22-22-22)} \
      CONFIG.MC_NO_CHANNELS {Single} \
      CONFIG.MC_PARITY {true} \
      CONFIG.MC_RANK {1} \
      CONFIG.MC_ROWADDRESSWIDTH {18} \
      CONFIG.MC_STACKHEIGHT {1} \
      CONFIG.MC_SYSTEM_CLOCK {Differential} \
      CONFIG.NUM_CLKS {1} \
      CONFIG.NUM_MC {1} \
      CONFIG.NUM_MCP {4} \
      CONFIG.NUM_MI {0} \
      CONFIG.NUM_NMI {0} \
      CONFIG.NUM_NSI {0} \
      CONFIG.NUM_SI {1} \
    ] $DDR
  set_property -dict [list CONFIG.CONNECTIONS {MC_0 {read_bw {800} write_bw {800} read_avg_burst {4} write_avg_burst {4}}} CONFIG.CATEGORY pl] [get_bd_intf_pins DDR/S00_AXI]
  set_property CONFIG.ASSOCIATED_BUSIF S00_AXI [get_bd_pins DDR/aclk0]

  # Create instance: IO
  create_hier_cell_IO [current_bd_instance .] IO

  # Create instance: UART_Reset, and set properties
  # Synchronize reset deassertion for the 100 MHz UART/PS AXI domain.
  set UART_Reset [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 UART_Reset ]
  # aux_reset_in is tied low below; select active-high auxiliary reset.
  set_property CONFIG.C_AUX_RESET_HIGH 1 $UART_Reset

  # Create instance: IRQ, and set properties
  set IRQ [ create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:ilconcat:1.0 IRQ ]
  set_property CONFIG.NUM_PORTS 8 $IRQ

  # Create interface connections
  # Native PMC BSCAN connects directly to the RISC-V Debug Module.
  set cips_bscan [get_bd_intf_pins -quiet -of_objects $CIPS -filter {VLNV =~ *:bscan_rtl:*}]
  if {[llength $cips_bscan] != 1} {
    error "V80 requires exactly one native CIPS BSCAN interface; check PS_USE_BSCAN_USER1."
  }
  connect_bd_intf_net $cips_bscan $rocket_bscan
  connect_bd_intf_net [get_bd_intf_ports sys_clk0_1] [get_bd_intf_pins DDR/sys_clk0]
  connect_bd_intf_net [get_bd_intf_ports CH0_DDR4_0_1] [get_bd_intf_pins DDR/CH0_DDR4_0]
  connect_bd_intf_net $mem_intf [get_bd_intf_pins Memory_Address/S_AXI]
  connect_bd_intf_net [get_bd_intf_pins Memory_Address/M_AXI] [get_bd_intf_pins DDR/S00_AXI]
  connect_bd_intf_net [get_bd_intf_pins RocketChip/IO_AXI4] [get_bd_intf_pins IO/S01_AXI]
  connect_bd_intf_net [get_bd_intf_pins IO/M00_AXI] [get_bd_intf_pins CIPS/S_AXI_LPD]
  connect_bd_intf_net [get_bd_intf_pins IO/M01_AXI] [get_bd_intf_pins RocketChip/DMA_AXI4]
  connect_bd_intf_net [get_bd_intf_ports qsfp0_4x] [get_bd_intf_pins IO/qsfp]
  connect_bd_intf_net [get_bd_intf_ports qsfp0_322mhz] [get_bd_intf_pins IO/qsfp_refclk]

  # Create port connections
  connect_bd_net [get_bd_pins CIPS/pl0_ref_clk] [get_bd_pins clk_wiz_0/clk_in1]
  connect_bd_net [get_bd_pins zero/dout] [get_bd_pins RocketChip/S_BSCAN_bscanid_en] \
      [get_bd_pins UART_Reset/aux_reset_in] [get_bd_pins UART_Reset/mb_debug_sys_rst] [get_bd_pins IO/mdio_int]
  connect_bd_net [get_bd_pins CIPS/pl0_resetn] [get_bd_pins reset_inv/Op1] [get_bd_pins RocketChip/mem_ok]
  connect_bd_net [get_bd_pins reset_inv/Res] [get_bd_pins RocketChip/sys_reset]
  connect_bd_net [get_bd_pins clk_wiz_0/locked] [get_bd_pins RocketChip/clock_ok] \
      [get_bd_pins RocketChip/io_ok] [get_bd_pins UART_Reset/dcm_locked]
  connect_bd_net [get_bd_pins clk_wiz_0/clk_out1] [get_bd_pins RocketChip/clock] \
      [get_bd_pins DDR/aclk0] [get_bd_pins Memory_Address/clock] [get_bd_pins IO/axi_clock]
  connect_bd_net [get_bd_pins clk_wiz_0/clk_out2] [get_bd_pins IO/clock100MHz] \
      [get_bd_pins CIPS/s_axi_lpd_aclk] [get_bd_pins UART_Reset/slowest_sync_clk]
  connect_bd_net [get_bd_pins RocketChip/aresetn] [get_bd_pins Memory_Address/resetn] \
      [get_bd_pins IO/axi_reset] [get_bd_pins UART_Reset/ext_reset_in]
  connect_bd_net [get_bd_pins UART_Reset/peripheral_aresetn] [get_bd_pins IO/uart_resetn]
  connect_bd_net [get_bd_pins IO/uart_interrupt] [get_bd_pins IRQ/In0]
  connect_bd_net [get_bd_pins IO/ethernet_interrupt] [get_bd_pins IRQ/In2]
  connect_bd_net [get_bd_pins zero/dout] \
      [get_bd_pins IRQ/In1] \
      [get_bd_pins IRQ/In3] \
      [get_bd_pins IRQ/In4] \
      [get_bd_pins IRQ/In5] \
      [get_bd_pins IRQ/In6] \
      [get_bd_pins IRQ/In7]
  connect_bd_net [get_bd_pins IRQ/dout] [get_bd_pins RocketChip/interrupts]

  # Create address segments
  assign_bd_address -offset 0x60010000 -range 0x10000 -target_address_space [get_bd_addr_spaces RocketChip/IO_AXI4] [get_bd_addr_segs IO/UART/S_AXI/reg0]
  assign_bd_address -offset 0x60020000 -range 0x10000 -target_address_space [get_bd_addr_spaces RocketChip/IO_AXI4] [get_bd_addr_segs IO/Ethernet/S_AXI_LITE/reg0]
  assign_bd_address -offset 0 -range 0x400000000 -target_address_space [get_bd_addr_spaces [eval $rocket_memory_channel_name 0]] [get_bd_addr_segs Memory_Address/S_AXI/reg0]
  assign_bd_address -offset 0 -range [expr {1 << [get_property CONFIG.ADDR_WIDTH [get_bd_intf_pins RocketChip/DMA_AXI4]]}] \
      -target_address_space [get_bd_addr_spaces IO/Ethernet/M_AXI] [get_bd_addr_segs RocketChip/DMA_AXI4/reg0]
  assign_bd_address -target_address_space [get_bd_addr_spaces IO/UART/M_AXI]
  # Map the zero-based Rocket bus to the first 16 GiB of DDR_CH2.
  # The CPU and device tree expose 14 GiB of this power-of-two window.
  assign_bd_address -offset 0x060000000000 -range 0x400000000 \
      -target_address_space [get_bd_addr_spaces Memory_Address/M_AXI] \
      [get_bd_addr_segs DDR/S00_AXI/C0_DDR_CH2] -force

  # Restore current instance
  current_bd_instance $oldCurInst

  validate_bd_design
  save_bd_design

  set_property STEPS.POST_ROUTE_PHYS_OPT_DESIGN.IS_ENABLED true [get_runs impl_1]
  set_property STEPS.POST_ROUTE_PHYS_OPT_DESIGN.ARGS.DIRECTIVE Explore [get_runs impl_1]
}
# End of create_root_design()

##################################################################
# MAIN FLOW
##################################################################

create_root_design ""
