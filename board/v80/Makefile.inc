BOARD_PART           ?= NONE
XILINX_PART          ?= xcv80-lsva4737-2MHP-e-S
ROOTFS               ?= NFS
MEMORY_SIZE          ?= 0x400000000
FPGA_FNM             ?= riscv_wrapper.pdi
FPGA_WRITE_STEP      ?= write_device_image
JTAG_BOOT_TCL        ?= board/jtag-boot-versal.tcl
VIVADO_SYNTHESIS_SETUP = board/v80/synthesis.tcl
VIVADO_SYNTHESIS_DEPS = $(VIVADO_SYNTHESIS_SETUP) \
  board/v80/rocket64w1-synth-pre.tcl board/v80/rocket64w1-ooc.xdc \
  board/v80/run-pre.tcl board/v80/check-timing.tcl board/v80/clock-root.tcl \
  board/v80/refine-timing.tcl
