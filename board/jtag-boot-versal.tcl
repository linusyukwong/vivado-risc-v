# Copyright (C) 2023 - 2025 Advanced Micro Devices, Inc.
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.

# Direct USER1 transport for Rocket custom 40-bit DMI on native CIPS BSCAN.
# XSDB 2025.1 can fail discovery with DTM 0xa9/0x89; these scans wait for
# each response and use SBA to load RAM without requiring an XSDB hart.
namespace eval versal_debug {
proc wait_response {seq response} {
    # req/done are the asynchronous request/acknowledge handshake. Wait
    # using NOP scans so a pending command is not reset or issued twice.
    for {set poll 0} {$poll < 100} {incr poll} {
        set flags [expr {$response >> 32}]
        if {$flags & 0x7c} {error [format "RAW_DMI_ERROR flags=0x%x data=0x%08x" $flags [expr {$response & 0xffffffff}]]}
        if {!($flags & 3)} {return $response}
        $seq clear
        $seq atomic 1
        $seq state IDLE 100
        $seq drshift -integer -capture -state IDLE 40 0
        $seq state IDLE 100
        set response [lindex [$seq run -integer] end]
    }
    error "RAW_DMI_RESPONSE_TIMEOUT"
}
proc dmi {address {value {}}} {
    set packet [expr {($address << 32) | ($value eq "" ? 0 : (0x8000000000 | ($value & 0xffffffff)))}]
    set seq [jtag sequence]
    $seq atomic 1
    $seq state RESET 16
    $seq irshift -register user1 -state IDLE
    # Native XSDB probing can leave the custom transport locked. Unlock
    # explicitly; TAP reset alone does not clear JtagExtBscan's lock bit.
    $seq drshift -integer -state IDLE 40 0xfe00000000
    $seq state IDLE 32
    $seq drshift -integer -state IDLE 40 $packet
    $seq state IDLE 100
    $seq drshift -integer -capture -state IDLE 40 0
    $seq state IDLE 100
    $seq drshift -integer -capture -state IDLE 40 0
    try {
        set response [wait_response $seq [lindex [$seq run -integer] end]]
    } finally {$seq delete}
    return [expr {$response & 0xffffffff}]
}
proc sba_check {} {
    for {set i 0} {$i < 100} {incr i} {
        set status [dmi 0x38]
        if {!($status & 0x200000)} {
            if {$status & 0x407000} {error [format "SBA_ERROR status=0x%08x" $status]}
            return $status
        }
    }
    error "SBA busy timeout"
}
proc sba_read {address} {
    # Clear all sticky bus errors before starting the next read.
    dmi 0x38 0x00547000
    dmi 0x3a [expr {$address >> 32}]
    dmi 0x39 [expr {$address & 0xffffffff}]
    sba_check
    return [dmi 0x3c]
}
proc dmi_write_batch {requests} {
    set seq [jtag sequence]
    $seq atomic 0
    $seq state RESET 16
    $seq irshift -register user1 -state IDLE
    $seq drshift -integer -state IDLE 40 0xfe00000000
    $seq state IDLE 32
    foreach request $requests {
        set packet [expr {(([lindex $request 0] | 0x80) << 32) | ([lindex $request 1] & 0xffffffff)}]
        $seq drshift -integer -state IDLE 40 $packet
        $seq state IDLE 32
    }
    $seq drshift -integer -capture -state IDLE 40 0
    $seq state IDLE 32
    $seq drshift -integer -capture -state IDLE 40 0
    try {
        wait_response $seq [lindex [$seq run -integer] end]
    } finally {$seq delete}
}
proc sba_write_words {address words} {
    dmi 0x38 0x00457000
    dmi 0x3a [expr {$address >> 32}]
    dmi 0x39 [expr {$address & 0xffffffff}]
    set requests {}
    foreach value $words {lappend requests [list 0x3c $value]}
    dmi_write_batch $requests
    sba_check
    set next [expr {([dmi 0x3a] << 32) | [dmi 0x39]}]
    if {$next != $address + 4*[llength $words]} {
        error [format "SBA write count mismatch: expected next address 0x%x, got 0x%x" [expr {$address+4*[llength $words]}] $next]
    }
}
proc abstract_wait {} {
    for {set i 0} {$i < 100} {incr i} {
        set status [dmi 0x16]
        if {!($status & 0x1000)} {
            if {$status & 0x700} {error [format "ABSTRACT_COMMAND_ERROR 0x%08x" $status]}
            return
        }
    }
    error "Abstract command busy timeout"
}
proc reg_write_gpr {number value} {
    dmi 0x16 0x700
    dmi 0x04 [expr {$value & 0xffffffff}]
    dmi 0x05 [expr {$value >> 32}]
    dmi 0x17 [expr {0x00330000 | $number}]
    abstract_wait
}
proc reg_read_gpr {number} {
    dmi 0x16 0x700
    dmi 0x17 [expr {0x00320000 | $number}]
    abstract_wait
    set low [dmi 0x04]
    set high [dmi 0x05]
    return [expr {($high << 32) | $low}]
}
proc load_binary {path address} {
    if {$address%4 || $address<0x80000000 || $address+[file size $path]>0x400000000} {error "Download is outside aligned 14 GiB RAM"}
    set input [open $path rb]
    set total [file size $path]
    set done 0
    set start [clock milliseconds]
    try {
        while {$done < $total} {
            set data [read $input 16384]
            if {[string length $data] % 4} {append data [string repeat \x00 [expr {4-[string length $data]%4}]]}
            binary scan $data i* signed_words
            set words {}
            foreach word $signed_words {lappend words [expr {$word & 0xffffffff}]}
            sba_write_words [expr {$address+$done}] $words
            # Check both ends of every chunk, detecting dropped writes.
            if {[sba_read [expr {$address+$done}]] != [lindex $words 0] ||
                [sba_read [expr {$address+$done+4*([llength $words]-1)}]] != [lindex $words end]} {error "Download verification failed at offset $done"}
            incr done [string length $data]
            if {$done % 1048576 == 0 || $done >= $total} {
                set seconds [expr {([clock milliseconds]-$start)/1000.0}]
                puts [format "RAW_DOWNLOAD file=%s done=%d total=%d seconds=%.2f" [file tail $path] $done $total $seconds]
                flush stdout
            }
        }
    } finally {close $input}
}
proc progbuf_exec {instruction} {
    dmi 0x16 0x700
    dmi 0x20 $instruction
    dmi 0x21 0x00100073
    dmi 0x17 0x00040000
    abstract_wait
}
proc reg_read {number} {
    if {$number >= 0x1000} {return [reg_read_gpr $number]}
    set saved [reg_read_gpr 0x1008]
    try {
        progbuf_exec [expr {($number << 20) | (2 << 12) | (8 << 7) | 0x73}]
        return [reg_read_gpr 0x1008]
    } finally {reg_write_gpr 0x1008 $saved}
}
proc reg_write {number value} {
    if {$number >= 0x1000} {return [reg_write_gpr $number $value]}
    set saved [reg_read_gpr 0x1008]
    try {
        reg_write_gpr 0x1008 $value
        progbuf_exec [expr {($number << 20) | (8 << 15) | (1 << 12) | 0x73}]
    } finally {reg_write_gpr 0x1008 $saved}
}

proc halt {} {
    # A write that first activates the debug module can ignore other fields.
    dmi 0x10 1
    after 20
    dmi 0x10 0x80000001
    for {set i 0} {$i<100} {incr i} {
        after 10
        if {([dmi 0x11]&0x300)==0x300} {
            dmi 0x10 1
            return
        }
    }
    error "RISC-V hart did not halt"
}
proc resume {entry} {
    # BOOM v3 does not support single stepping. Clear step and ebreak traps.
    reg_write 0x7b0 [expr {[reg_read 0x7b0]&~0x8004}]
    progbuf_exec 0x0000100f
    reg_write 0x7b1 $entry
    if {[reg_read 0x7b1] != $entry} {error "Entry register did not update"}
    dmi 0x10 0x40000001
    after 100
    dmi 0x10 1
}
proc unsigned_le {data offset size} {
    if {[string length $data] < $offset+$size} {error "Truncated ELF field"}
    binary scan [string range $data $offset [expr {$offset+$size-1}]] cu* bytes
    set value 0
    set shift 0
    foreach byte $bytes {set value [expr {$value|($byte<<$shift)}]; incr shift 8}
    return $value
}
proc load_elf {path} {
    set input [open $path rb]
    try {
        set header [read $input 64]
        if {[string range $header 0 5] ne "\x7fELF\x02\x01" || [unsigned_le $header 18 2] != 243} {error "Expected a little-endian RISC-V ELF64"}
        set entry [unsigned_le $header 24 8]
        set phoff [unsigned_le $header 32 8]
        set phsize [unsigned_le $header 54 2]
        set phnum [unsigned_le $header 56 2]
        if {$phsize<56 || $phnum>128 || $phoff+$phsize*$phnum>[file size $path]} {error "Invalid ELF program header table"}
        for {set i 0} {$i<$phnum} {incr i} {
            seek $input [expr {$phoff+$phsize*$i}]
            set ph [read $input $phsize]
            if {[unsigned_le $ph 0 4]!=1} continue
            set offset [unsigned_le $ph 8 8]
            set address [unsigned_le $ph 24 8]
            set filesz [unsigned_le $ph 32 8]
            set memsz [unsigned_le $ph 40 8]
            if {$filesz>$memsz || $offset+$filesz>[file size $path] || $address%4 || $address<0x80000000 || $address+$memsz>0x400000000} {error "Invalid ELF load segment"}
            set output [file tempfile temporary]
            fconfigure $output -translation binary
            try {
                seek $input $offset
                fcopy $input $output -size $filesz
                set remaining [expr {$memsz-$filesz}]
                while {$remaining>0} {
                    set count [expr {min(16384,$remaining)}]
                    puts -nonewline $output [string repeat \x00 $count]
                    incr remaining -$count
                }
                close $output
                set output {}
                puts [format "RAW_ELF_SEGMENT address=0x%x filesz=%d memsz=%d" $address $filesz $memsz]
                load_binary $temporary $address
            } finally {
                if {$output ne ""} {close $output}
                file delete -force $temporary
            }
        }
        if {$entry<0x80000000 || $entry>=0x400000000 || $entry%2} {error "Invalid ELF entry"}
        return $entry
    } finally {close $input}
}
}

# Configure the Versal platform and boot the RISC-V NFS system.
set kernel linux-stable/arch/riscv/boot/Image
set firmware workspace/boot.elf
foreach path [list $::env(BITSTREAM) $kernel $firmware] {
    if {![file exists $path] || [file size $path] == 0} {error "Missing boot input: $path"}
}
connect -url $::env(HW_SERVER_URL)
try {
    # Avoid scanning USER1 while CIPS and its BSCAN clock are reconfigured.
    configparams mdm-detect-bscan-mask 0
    # Override the boot mode to JTAG and reset with MULTIBOOT at zero.
    targets -set -filter {name =~ "Versal*"}
    mwr 0xf1260200 0x0100
    mrd 0xf1260200
    mwr -force 0xF1110004 0x0
    targets -set -filter {name =~ "PMC"}
    rst
    after 2000
    targets -set -filter {name =~ "Versal*"}
    device program $::env(BITSTREAM)
    after 10000
    configparams mdm-detect-bscan-mask 15
    after 2000
    if {([info exists ::env(VERSAL_RAW_DMI)] && $::env(VERSAL_RAW_DMI)) ||
        ([info exists ::env(V80_RAW_DMI)] && $::env(V80_RAW_DMI))} {
        set native_status 1
        set native_error "Direct USER1 transport requested"
    } else {
        set native_status [catch {
            targets -set -filter {name =~ "Hart #0*"}
            stop
            targets -set -filter {name =~ "RISC-V*"}
            dow -data $kernel 0x81000000
            targets -set -filter {name =~ "Hart #0*"}
            dow -clear $firmware
            rwr a0 0
            rwr a1 0x10080
            rwr s0 0x80000000
            con
        } native_error]
    }
    if {$native_status} {
        puts "Native XSDB boot unavailable: $native_error"
        puts "Loading through the Rocket custom DMI on CIPS USER1"
        configparams mdm-detect-bscan-mask 0
        # XSDB's pause-before-shift sequence returns empty custom DMI data.
        configparams jtag-pause-before-shift 0
        jtag targets -set -filter {name =~ "xcv*"}
        jtag freq 1000000
        versal_debug::halt
        jtag freq 10000000
        versal_debug::load_binary $kernel 0x81000000
        set entry [versal_debug::load_elf $firmware]
        jtag freq 1000000
        versal_debug::reg_write 0x100a 0
        versal_debug::reg_write 0x100b 0x10080
        versal_debug::reg_write 0x1008 0x80000000
        versal_debug::resume $entry
        puts [format "RISC-V firmware started at 0x%x" $entry]
    }
} finally {
    configparams mdm-detect-bscan-mask 15
    disconnect
}
