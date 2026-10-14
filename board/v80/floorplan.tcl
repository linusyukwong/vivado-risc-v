# Keep the single BOOM tile and its TileLink fabric in a compact area.
# Use six clock regions with the clock-constrained, retimed CPU netlist.
# Four hard regions produced level-5 local routing congestion.
# Do not include the CIPS, NoC, DDR PHY or Ethernet transceiver hard blocks.
set v80_rocket [get_cells -quiet -hier -filter {ORIG_REF_NAME == Rocket64w1 || REF_NAME =~ *Rocket64w1}]
if {[llength $v80_rocket] == 1} {
    create_pblock pblock_v80_rocket64w1
    resize_pblock [get_pblocks pblock_v80_rocket64w1] -add {CLOCKREGION_X5Y2:CLOCKREGION_X7Y3}
    add_cells_to_pblock [get_pblocks pblock_v80_rocket64w1] $v80_rocket
    set_property IS_SOFT false [get_pblocks pblock_v80_rocket64w1]
    set v80_tile $v80_rocket/rocket_system/tile_prci_domain/element_reset_domain_boom_tile
    foreach {name hierarchy region} [list \
        frontend $v80_tile/frontend CLOCKREGION_X5Y3:CLOCKREGION_X5Y3 \
        fp $v80_tile/core/FpPipeline CLOCKREGION_X6Y2:CLOCKREGION_X6Y2] {
        set child [create_pblock pblock_v80_$name]
        set_property PARENT pblock_v80_rocket64w1 $child
        resize_pblock $child -add $region
        add_cells_to_pblock $child [get_cells $hierarchy]
        # Encourage locality without forcing congested arithmetic/decode logic
        # to stay inside an undersized child region during placement refinement.
        set_property IS_SOFT true $child
    }
}

# Encourage locality on the remaining cache/LSU/register-read critical paths.
# Keep this child soft so the placer can escape local congestion.
set parent [get_pblocks -quiet pblock_v80_rocket64w1]
if {[llength $parent]} {
    set cpu [get_cells -quiet -hier -filter {ORIG_REF_NAME == Rocket64w1 || REF_NAME =~ *Rocket64w1}]
    set tile $cpu/rocket_system/tile_prci_domain/element_reset_domain_boom_tile
    set memory_cells [get_cells -quiet [list $tile/dcache $tile/lsu \
        $tile/core/iregfile $tile/core/iregister_read $tile/core/mem_issue_unit $tile/core/csr]]
    if {[llength $memory_cells] != 6} {
        error "V80 memory floorplan expected six blocks, found $memory_cells"
    }
    set child [create_pblock pblock_v80_memory_pipeline]
    set_property PARENT pblock_v80_rocket64w1 $child
    resize_pblock $child -add {CLOCKREGION_X6Y2:CLOCKREGION_X7Y3}
    add_cells_to_pblock $child $memory_cells
    set_property IS_SOFT true $child
    puts "V80 memory locality pblock: $memory_cells"
}
