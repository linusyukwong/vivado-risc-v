BOARD_PART           ?= NONE
XILINX_PART          ?= xcv80-lsva4737-2MHP-e-S
ROOTFS               ?= NFS
MEMORY_SIZE          ?= 0x400000000
FPGA_FNM             ?= riscv_wrapper.pdi
FPGA_WRITE_STEP      ?= write_device_image
JTAG_BOOT_TCL        ?= board/jtag-boot-versal.tcl
