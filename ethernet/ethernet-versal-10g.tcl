# First-stage CDC constraints for the soft MAC status and gearbox controls.
# FIFO Gray pointers and reset synchronizers have their own upstream scripts.
foreach mac [get_cells -hier -filter {ORIG_REF_NAME == eth_mac_phy_10g_fifo || REF_NAME == eth_mac_phy_10g_fifo}] {
    foreach direction {rx tx} {
        set source [get_cells -quiet [format {%s/%s_sync_reg_1_reg[*]} $mac $direction]]
        set first [get_cells -quiet [format {%s/%s_sync_reg_2_reg[*]} $mac $direction]]
        if {[llength $source] && [llength $first]} {
            set clocks [get_clocks -of_objects [get_pins -of_objects $source -filter {REF_PIN_NAME == C}]]
            set_max_delay -datapath_only [get_property -min PERIOD $clocks] -from $source -to $first
            set stages [get_cells -quiet [list [format {%s/%s_sync_reg_2_reg[*]} $mac $direction] [format {%s/%s_sync_reg_3_reg[*]} $mac $direction]]]
            set_property ASYNC_REG TRUE $stages
        }
    }
    set resets [get_pins -quiet -of_objects [get_cells -quiet "$mac/*sync_reg*_reg*"] -filter {REF_PIN_NAME == CLR || REF_PIN_NAME == PRE}]
    if {[llength $resets]} {set_false_path -to $resets}
}
foreach network [get_cells -hier -filter {ORIG_REF_NAME == ethernet_versal_10g || REF_NAME == ethernet_versal_10g}] {
    foreach name {slip_sync1_reg overflow_sync1_reg reset_sync_reg[0] status_sync1_reg[*]} {
        set first [get_cells -hier -quiet -filter [format {NAME =~ %s/*/%s || NAME =~ %s/%s} $network $name $network $name]]
        foreach cell $first {
            set destination [get_pins -of_objects $cell -filter {REF_PIN_NAME == D}]
            # Use launching flip-flops, including both inputs of combined status
            # flags. A constraint starting at a LUT output segments the timing path.
            set source [get_cells -of_objects [all_fanin -flat -startpoints_only -to $destination]]
            set clock [get_clocks -of_objects [get_pins -of_objects $cell -filter {REF_PIN_NAME == C}]]
            if {[llength $source] && [llength $clock]} {
                set_max_delay -datapath_only [get_property -min PERIOD $clock] -from $source -to $destination
            }
        }
    }
    set_false_path -to [get_pins -quiet "$network/reset_toggle_reg/CLR"]
}
