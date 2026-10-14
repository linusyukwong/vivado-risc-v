# Alveo V80

Port of the U200 Rocket SoC to `xcv80-lsva4737-2MHP-e-S`, using
`CONFIG=rocket64w1`, `ROOTFS=NFS`, and Vivado 2025.1.

The design uses the installed 32 GiB DDR4 DIMM and exposes 14 GiB to Rocket.
`Rocket64w1` targets 200 MHz. Pass `ROCKET_FREQ_MHZ=200` explicitly
if `workspace/config` contains an older frequency override.

`riscv-2025.1.tcl` uses AVED's `axi_noc_mc_ddr4_1` DIMM profile: one x4
RDIMM rank, 72-bit interface with ECC, DDR4-3200, and a 200 MHz differential reference
clock. `top.xdc` copies the DIMM pin assignments from AVED, retaining
`CH0_DDR4_0_1` and `sys_clk0_1` port names. This profile follows the
32 GB Micron MTA18ASF4G72PZ-3G2F1 described in
[AMD's DIMM specification](https://docs.amd.com/r/en-US/ds1013-v80/DDR4-DIMM-Specification).
The onboard 4 GB DDR4 bank is separate from this expansion DIMM.

The native NoC uses DDR_CH2 at `0x0600_0000_0000`.
`memory-address.v` translates the CPU wrapper's zero-based memory bus
into this physical aperture. The CPU and device tree retain the RAM
base `0x80000000` and size `0x380000000` (14 GiB), so the existing
OpenSBI, U-Boot and Linux memory map is retained.

| Address space | First byte | Last byte | Size |
| --- | --- | --- | --- |
| CPU RAM | `0x80000000` | `0x3ffffffff` | 14 GiB |
| Wrapper memory AXI, used | `0x000000000` | `0x37fffffff` | 14 GiB |
| DDR_CH2, used by Rocket | `0x060000000000` | `0x06037fffffff` | 14 GiB |
| DDR_CH2, NoC aperture | `0x060000000000` | `0x0603ffffffff` | 16 GiB |
| Physical DIMM | `0x060000000000` | `0x0607ffffffff` | 32 GiB |

The AXI and NoC aperture is rounded to 16 GiB; Rocket only issues RAM
accesses within its 14 GiB window. The design script assigns the native
DDR segment and configures the DIMM capacity and ECC.
The design has no HBM controller or HBM reference-clock ports.

The memory adapter sets `AxCACHE[1]` (modifiable) so the NoC can resize
normal RAM transactions. It permits one outstanding AXI read burst:
Rocket expects non-interleaved responses, while the NoC can interleave
reads from different AXI IDs. The gate waits for an accepted `RLAST`
before admitting another address. Writes remain independent.
For `Rocket64w1`, a full-mode AXI register slice follows this adapter,
registering all five channels between the CPU and NoC. It adds transaction
latency while preserving ordering, backpressure, and the single-read limit.
The slice uses the CPU's clock and active-low reset.

UART1 uses PS_MIO 20/21. `uart-router.v` translates the existing registers
to Versal's PL011 (`uartpsv`) registers and initializes it to approximately
115200 baud (100 MHz reference, integer divisor 54, fractional divisor
16/64, and divide-by-16). It preserves
the existing AXI UART MMIO registers at `0x60010000`, interrupt 1, and
`ttyAU0` console. Native UART status polling generates the PL interrupt.
UART0 remains available for platform firmware diagnostics. The existing
register ABI uses offset `0` for RX reads, `4` for TX writes, `8` for
status and `12` for control; reading offset `4` is unsupported. Native status
is polled every 1024 UART-domain cycles (10.24 microseconds). Either FIFO
reset request flushes both native FIFOs, because PL011 shares their enable.
The UART interrupt enters the Rocket wrapper's three-stage synchronizer;
its path into the first stage is bounded to one CPU cycle.

QSFP0 uses only its first lane (channel 0), running 10GBASE-R at
10.3125 Gb/s NRZ through native `gtwiz_versal:1.0`. Channels 1–3 are
disabled; the native wizard still exposes the whole quad's pad bundle.
The GTM initialization masks retain their required wizard defaults:
TX PCS `1`, TX PMA `3`, RX PCS `7`, RX PMA `255`. These enable the
component resets needed at startup; they must not be tied to zero.
See [AMD GTM reset initialization](https://docs.amd.com/r/en-US/am017-versal-gtm-transceivers/Reset-and-initialization).
The soft 10G MAC/PCS comes from the same `verilog-ethernet` library used
on U200. `ethernet/ethernet-versal-10g.v` connects its 64-bit frame FIFOs
directly to the existing DMA at `0x60020000`, interrupt 3, preserving the NFS driver path.
TX and RX frame FIFOs drop bad and oversized frames.

The same file includes the gearbox for GTM's raw fabric interface. It packs
66-bit PCS blocks into 64-bit GT words and reconstructs them on RX, with
one-bit alignment
slips controlled by the PHY. The 161.1328125 MHz GT clocks are converted
to 156.25 MHz PCS clocks with exact MMCM ratios (`192 / 11 / 18`). The RX
clock follows the recovered CDR clock via RXPROGDIVCLK. Vivado represents
the GT frequency as a rounded 161.133 MHz enum; the fixed primitive ratios
prevent FIFO drift. See [AMD GTM RX clock division](https://docs.amd.com/r/en-US/am017-versal-gtm-transceivers/RX-Programmable-Divider).

Use a 10G-compatible QSFP module/cable or breakout with the peer connected
to the first lane. Module management is outside this PL datapath; configure
the module and the board's 322.265625 MHz QSFP0 reference clock before NFS.

This port loads Linux over JTAG and mounts an NFS root. It does not include
the U200 host PCIe/QDMA path, its external DDR4 controllers, or SPI MCS
flash programming. The Versal build produces `riscv_wrapper.pdi`, containing
platform configuration, instead of a `.bit`/`.mcs` pair.

```sh
source /tools/Xilinx/2025.1/Vivado/settings64.sh
make BOARD=v80 CONFIG=rocket64w1 ROOTFS=NFS ROCKET_FREQ_MHZ=200 MAX_THREADS=8 bitstream
make BOARD=v80 CONFIG=rocket64w1 ROOTFS=NFS \
  ROOTFS_URL=192.168.0.100:/home/nfsroot/192.168.0.243 bootloader
make BOARD=v80 CONFIG=rocket64w1 ROOTFS=NFS jtag-boot
```

The tested V80 boot copies the ROM device tree to `0x86000000`,
reserves 512 KiB at `0x80000000` for resident OpenSBI, then boots Linux
using that RAM copy. This keeps the FDT outside kernel relocation and
compressed-image buffers. The default firmware uses DHCP. Hardware validation
stopped U-Boot autoboot and supplied static `ip=` boot arguments explicitly;
the exact commands are recorded in the hardware test report below.

The normal repository prerequisites for generating Rocket HDL and building
Linux/OpenSBI/U-Boot still apply. `JAVA_PATH`,
`CROSS_COMPILE_LINUX`, `CROSS_COMPILE_NO_OS_TOOLS`, and
`NO_OS_TOOLCHAIN_STAMP` can be set in `workspace/config` to use an existing
toolchain. Source the Vivado 2025.1 `settings64.sh` before building or
programming; it adds both `vivado` and `xsdb` to `PATH` and selects the
2025.1 runtime. Set `JAVA_PATH` in `workspace/config` to a Java 11 installation,
such as the runtime bundled with Vivado 2025.1, for the SBT 1.3.13 launcher.
On the AlmaLinux 9 build pod used for validation, export
`LD_PRELOAD=/lib64/libudev.so.1` before launching Vivado.
The wrapper is generated with `-e` to expose native BSCAN; it does not
instantiate BSCANE2.
JTAG boot requires an accessible V80 and a working hardware server. The shared
`board/jtag-boot-versal.tcl` applies the JTAG boot-mode override and includes
USER1 in the debug scan mask (`mdm-detect-bscan-mask 15`). Scanning is disabled during
PDI configuration and restored afterward. If standard XSDB hart discovery
fails with DTM `0xa9`/`0x89`, the helper loads through direct USER1 scans,
using the custom 40-bit DMI and SBA. `VERSAL_RAW_DMI=1` forces this fallback
(`V80_RAW_DMI=1` is also accepted).
The loader restores mask 15 on exit and handles ELF segment data and BSS.
BOOM v3 single stepping is unsupported, so the fallback uses halt/resume.

DDR, CIPS, pins and the boot-mode override are derived from AMD AVED
at commit `26c2fa0c38791639c1f08205f01ab4655dcaf66c`. Copyright notices
are preserved in the extracted files; the AVED tree is not copied into
this board directory. The reference files are
`hw/amd_v80_gen5x8_25.1/src/bd/create_bd_design.tcl`,
`hw/amd_v80_gen5x8_25.1/src/constraints/impl.pins.xdc` and
`deploy/scripts/versal_change_boot_mode.tcl` in the AVED tree.

`board/timing-constraints.tcl` bounds the native CIPS TCK crossings to the
CPU. CPU and Ethernet DMA share a clock and retain ordinary setup and hold
checks.

For `Rocket64w1`, `synthesis.tcl` applies a 5 ns clock to the CPU's separate
out-of-context synthesis run and enables global retiming. Routing uses
`NoTimingRelaxation` to retain the original timing goal. `floorplan.tcl`
places the CPU in six clock regions (`X5Y2:X7Y3`), with a soft frontend
subregion at `X5Y3` and a soft FP subregion at `X6Y2`. A soft memory
pipeline group spans `X6Y2:X7Y3`, grouping the cache, LSU, integer register
file, register read, memory issue, and CSR blocks.
`clock-root.tcl` requests the CPU/IO clock root after `opt_design` has created
the MBUFGCE, before placement. Check the placed `CLOCK_ROOT` as well as the
requested `USER_CLOCK_ROOT`; Vivado can rebalance the tree.
The startup reset exception ends at the first reset synchronizer's D pin;
CPU datapaths remain timed. `check-timing.tcl` rejects PDI generation when
implemented setup or hold timing fails. For a failing implementation,
`refine-timing.tcl` first refines physical timing with a temporary additional
100 ps setup uncertainty, then restores the original user uncertainty.
It repairs short hold paths by rerouting input branches with at least 200 ps
of setup slack. It adds no timing exceptions. A 200 MHz clock setting alone is
not evidence of timing closure; inspect `v80_timing_summary.rpt` in the
implementation run directory.

The routed `Rocket64w1` implementation validated on 2026-10-14, using
`ROOTFS=NFS`, Vivado 2025.1 and eight threads, met all timing constraints:

| Check | Worst slack | Total violation | Failing endpoints |
| --- | ---: | ---: | ---: |
| Setup, 5 ns CPU clock | 0.006 ns | 0.000 ns | 0 |
| Hold | 0.000 ns | 0.000 ns | 0 |
| Pulse width | 0.000 ns | 0.000 ns | 0 |

All 139,378 routable nets were fully routed, with no routing errors.
The reports contained no unclocked registers or unconstrained internal
endpoints, and bus-skew constraints passed. The checkpoint and reports are
in `workspace/build-v80-rocket64w1-200-nfs/rtl-hold-branches/pass2/`;
device-image generation and its independent reports are in
`workspace/build-v80-rocket64w1-200-nfs/closed-200MHz/`.
The production refinement hook was also run from the earlier routed
checkpoint and reproduced these timing results and the final routing checksum.
Hardware validation also passed on `pve-r740-16` on 2026-10-14. This exact PDI
booted OpenSBI, U-Boot and Linux 7.0.12 with an Alpine RISC-V root filesystem
mounted read-write over NFSv4 at `192.168.0.100:/srv/v80-test-200mhz`.
The board uses `192.168.0.243` on the host's dedicated 10 Gb/s link.
All ten repeated integer, floating-point, branch/call and memory checks
matched their native reference hashes. Each run swept a 16 MiB memory working
set four times. A 32 MiB NFS copy passed byte comparison and host/client SHA-256
checks; bidirectional ping had no packet loss, and the host NIC reported no
RX, TX or CRC errors. A host-timed RTC check estimated 200.03 MHz, consistent
with the 200 MHz target within its UART sampling uncertainty.

The complete results, boot commands, console logs and test sources are under
`workspace/build-v80-rocket64w1-200-nfs/hardware-pve-r740-16/`, with
`hardware-result.json` as the test manifest. The board was left running Linux;
its console is `/dev/ttyUSB3` at 115200 baud on that host. The test NFS root and
its runtime export remain active. Test coverage and limits are recorded in
the manifest.

SSH is enabled in this test NFS root with public-key authentication only.
From a machine with a key authorized for `almalinux` on `pve-r740-16`, connect with:

```sh
ssh -J pve-r740-16 root@192.168.0.243
```

The board's `root/.ssh/authorized_keys` was copied from that host account.
The test init script starts `sshd` on boot; passwords are disabled.
The successful connection and effective configuration are recorded in
`hardware-pve-r740-16/ssh-result.json` and `ssh-check.log` under the build directory.

`patches/riscv-boom.patch` moves loop-predictor index comparisons before
existing registers, moves TAGE selection before its F2-to-F3 register
boundary, bypasses compressed decoding for a saved halfword
known to start a 32-bit instruction, and moves FP load recoding after the
existing writeback register. Integer register-file writes use a pending
stage with forwarding on reads. These changes preserve interface cycle timing.
Frontend history comparisons select between precomputed equality results,
and cache/MSHR address comparisons move before the existing S1-to-S2 registers.
The carried-instruction PC and ordinary compressed-instruction expansion are
computed before the existing one-entry F3 queue. Store-data-queue readiness is
registered alongside its allocation bitmap update, retaining the same cycle timing.
The fully associative micro-BTB selects the first matching way with a priority
one-hot mux, preserving the original last-way selection on a miss.
It computes targets for each way before selection, keeping target addition
parallel with tag matching and preserving the same prediction cycle.
The `tests/check_boom_{loop,tage,frontend,ghist,edgepc,f3expand,ubtb,fp,regfile,mshr,sdq}_equivalence.py` scripts check
generated Verilog with Yosys; pass `--gold`, `--gate`, and optionally
`--yosys` (validated with YoWASP Yosys 0.69). Frontend and FP checks require before/after files differing only
in the respective module, and the frontend check also proves the saved
halfword invariant. The register-file check covers every effective stored
value as well as all read outputs.

The validated run used `MAX_THREADS=8` with a 224 GiB pod memory limit.
After an interrupted build, reduce to `MAX_THREADS=4` (or fewer) and run one
implementation at a time. The setting is propagated to synthesis and
implementation subprocesses. Keep `ROOTFS=NFS` in rebuild commands.

The board directory follows the `x3522pv` layout: `ethernet-v80.tcl`
registers Ethernet sources and constraints and creates the standalone GT
and PCS clock IPs. `ethernet/ethernet-versal-10g.v` instantiates those IPs,
the reference-clock and user-clock buffers, and the soft MAC/PCS and
gearboxes. The versioned RISC-V design script connects the Ethernet RTL
wrapper to the DMA and QSFP ports. The XDC files hold pin constraints;
`ethernet/ethernet-versal-10g.tcl` handles Ethernet timing, and the common
board timing script handles native CIPS BSCAN.
