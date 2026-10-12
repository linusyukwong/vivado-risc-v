/*

Copyright (c) 2021-2026 Eugene Tarassov
Copyright (c) 2014-2018 Alex Forencich

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

*/

`timescale 1ns / 1ps

module ethernet_versal_10g (

    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 eth_gt_user_clock CLK",
       X_INTERFACE_PARAMETER = "FREQ_HZ 156250000" *)
    output wire eth_gt_user_clock,

    /* ETH0 AXIS */
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 ETH0_TX_AXIS TDATA" *)
    input wire [63:0] eth_tx_axis_tdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 ETH0_TX_AXIS TKEEP" *)
    input wire [7:0] eth_tx_axis_tkeep,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 ETH0_TX_AXIS TVALID" *)
    input wire eth_tx_axis_tvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 ETH0_TX_AXIS TREADY" *)
    output wire eth_tx_axis_tready,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 ETH0_TX_AXIS TLAST" *)
    input wire eth_tx_axis_tlast,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 ETH0_TX_AXIS TUSER" *)
    input wire eth_tx_axis_tuser,

    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 ETH0_RX_AXIS TDATA" *)
    output wire [63:0] eth_rx_axis_tdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 ETH0_RX_AXIS TKEEP" *)
    output wire [7:0] eth_rx_axis_tkeep,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 ETH0_RX_AXIS TVALID" *)
    output wire eth_rx_axis_tvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 ETH0_RX_AXIS TREADY" *)
    input wire eth_rx_axis_tready,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 ETH0_RX_AXIS TLAST" *)
    output wire eth_rx_axis_tlast,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 ETH0_RX_AXIS TUSER" *)
    output wire eth_rx_axis_tuser,

    output wire [15:0] eth_status,

    /* QSFP0: the GT wizard exposes the full quad; only channel 0 is enabled. */
    (* X_INTERFACE_INFO = "xilinx.com:interface:gt:1.0 QSFP GTX_P" *)
    output wire [3:0] qsfp_tx_p,
    (* X_INTERFACE_INFO = "xilinx.com:interface:gt:1.0 QSFP GTX_N" *)
    output wire [3:0] qsfp_tx_n,
    (* X_INTERFACE_INFO = "xilinx.com:interface:gt:1.0 QSFP GRX_P" *)
    input wire [3:0] qsfp_rx_p,
    (* X_INTERFACE_INFO = "xilinx.com:interface:gt:1.0 QSFP GRX_N" *)
    input wire [3:0] qsfp_rx_n,
    (* X_INTERFACE_INFO = "xilinx.com:interface:diff_clock:1.0 QSFP_REFCLK CLK_P",
       X_INTERFACE_PARAMETER = "FREQ_HZ 322265625" *)
    input wire qsfp_mgt_refclk_p,
    (* X_INTERFACE_INFO = "xilinx.com:interface:diff_clock:1.0 QSFP_REFCLK CLK_N" *)
    input wire qsfp_mgt_refclk_n,

    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 eth_clock CLK",
       X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF ETH0_TX_AXIS:ETH0_RX_AXIS, ASSOCIATED_RESET eth_resetn" *)
    input wire eth_clock,
    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 eth_resetn RST",
       X_INTERFACE_PARAMETER = "POLARITY ACTIVE_LOW" *)
    input wire eth_resetn
);

// Interface configuration
localparam TX_FIFO_DEPTH = 4096;
localparam RX_FIFO_DEPTH = 16384;

// GTM raw-word clocks and 156.25 MHz PCS clocks
wire gt_refclk;
wire gt_tx_outclk, gt_rx_outclk;
wire gt_tx_clk, gt_rx_clk;
wire gt_tx_clr, gt_rx_clr;
wire gt_tx_clrb_leaf, gt_rx_clrb_leaf;
wire gt_tx_done, gt_rx_done;
wire tx_clk, rx_clk;
wire tx_locked, rx_locked;
wire [255:0] gt_tx_data, gt_rx_data;
reg gt_rx_reset_req = 0;

IBUFDS_GTME5 ibufds_gtme5_qsfp_refclk_inst (
    .I(qsfp_mgt_refclk_p),
    .IB(qsfp_mgt_refclk_n),
    .CEB(1'b0),
    .O(gt_refclk),
    .ODIV2()
);

MBUFG_GT #(.SIM_DEVICE("VERSAL_HBM")) mbufg_gt_tx_usrclk_inst (
    .CE(1'b1),
    .CEMASK(1'b0),
    .CLR(gt_tx_clr),
    .CLRB_LEAF(gt_tx_clrb_leaf),
    .CLRMASK(1'b0),
    .DIV(3'd0),
    .I(gt_tx_outclk),
    .O1(gt_tx_clk),
    .O2(),
    .O3(),
    .O4()
);

MBUFG_GT #(.SIM_DEVICE("VERSAL_HBM")) mbufg_gt_rx_usrclk_inst (
    .CE(1'b1),
    .CEMASK(1'b0),
    .CLR(gt_rx_clr),
    .CLRB_LEAF(gt_rx_clrb_leaf),
    .CLRMASK(1'b0),
    .DIV(3'd0),
    .I(gt_rx_outclk),
    .O1(gt_rx_clk),
    .O2(),
    .O3(),
    .O4()
);

// 161.1328125 MHz * 192 / 11 / 18 = 156.25 MHz.
// TX and RX use separate MMCMs; RX follows the recovered CDR clock.
ethernet_pcs_clock tx_pcs_clock_inst (
    .clk_in1(gt_tx_clk),
    .clk_out1(tx_clk),
    .locked(tx_locked)
);

ethernet_pcs_clock rx_pcs_clock_inst (
    .clk_in1(gt_rx_clk),
    .clk_out1(rx_clk),
    .locked(rx_locked)
);

assign eth_gt_user_clock = tx_clk;

gtwiz_versal_0 qsfp_gt_inst (
    .gtpowergood(),
    .gtwiz_freerun_clk(eth_clock),
    .QUAD0_GTREFCLK0(gt_refclk),
    .QUAD0_TX0_outclk(gt_tx_outclk),
    .QUAD0_RX0_outclk(gt_rx_outclk),
    .QUAD0_rxp(qsfp_rx_p),
    .QUAD0_rxn(qsfp_rx_n),
    .QUAD0_txp(qsfp_tx_p),
    .QUAD0_txn(qsfp_tx_n),
    .QUAD0_TX0_usrclk(gt_tx_clk),
    .QUAD0_RX0_usrclk(gt_rx_clk),
    .INTF0_TX0_ch_txdata(gt_tx_data),
    .INTF0_TX0_ch_txmaincursor(7'd64),
    .INTF0_TX0_ch_txrate(8'd0),
    .INTF0_RX0_ch_rxrate(8'd0),
    .INTF0_RX0_ch_rxdata(gt_rx_data),
    .INTF0_TX_clr_out(gt_tx_clr),
    .INTF0_TX_clrb_leaf_out(gt_tx_clrb_leaf),
    .INTF0_RX_clr_out(gt_rx_clr),
    .INTF0_RX_clrb_leaf_out(gt_rx_clrb_leaf),
    .INTF0_rst_all_in(!eth_resetn),
    .INTF0_rst_tx_pll_and_datapath_in(1'b0),
    .INTF0_rst_tx_datapath_in(1'b0),
    .INTF0_rst_tx_done_out(gt_tx_done),
    .INTF0_rst_rx_pll_and_datapath_in(1'b0),
    .INTF0_rst_rx_datapath_in(gt_rx_reset_req),
    .INTF0_rst_rx_done_out(gt_rx_done)
);

// Soft MAC/PCS and GTM 64b/66b gearboxes
wire tx_rst, rx_rst, gt_tx_rst, gt_rx_rst;
wire tx_reset = !eth_resetn || !gt_tx_done || !tx_locked;
wire rx_reset = !eth_resetn || !gt_rx_done || !rx_locked;
sync_reset #(.N(4)) tx_reset_sync (.clk(tx_clk), .rst(tx_reset), .out(tx_rst));
sync_reset #(.N(4)) rx_reset_sync (.clk(rx_clk), .rst(rx_reset), .out(rx_rst));
sync_reset #(.N(4)) gt_tx_reset_sync (.clk(gt_tx_clk), .rst(tx_reset), .out(gt_tx_rst));
sync_reset #(.N(4)) gt_rx_reset_sync (.clk(gt_rx_clk), .rst(rx_reset), .out(gt_rx_rst));
wire [63:0] tx_pcs_data, rx_pcs_data, tx_raw_data;
wire [1:0] tx_pcs_hdr, rx_pcs_hdr;
wire bitslip, rx_reset_req;
wire tx_running, rx_running, tx_fault, rx_fault;
gearbox_versal_10g_tx tx_gearbox (
    .pcs_clk(tx_clk), .pcs_rst(tx_rst), .pcs_data(tx_pcs_data), .pcs_hdr(tx_pcs_hdr),
    .gt_clk(gt_tx_clk), .gt_rst(gt_tx_rst), .gt_data(tx_raw_data), .running(tx_running), .fault(tx_fault)
);
assign gt_tx_data = {192'b0, tx_raw_data};
gearbox_versal_10g_rx rx_gearbox (
    .gt_clk(gt_rx_clk), .gt_rst(gt_rx_rst), .gt_data(gt_rx_data[63:0]),
    .pcs_clk(rx_clk), .pcs_rst(rx_rst), .bitslip(bitslip),
    .pcs_data(rx_pcs_data), .pcs_hdr(rx_pcs_hdr), .running(rx_running), .fault(rx_fault)
);
eth_mac_phy_10g_fifo #(
    .BIT_REVERSE(0),
    .BITSLIP_LOW_CYCLES(64),
    .TX_FIFO_DEPTH(TX_FIFO_DEPTH),
    .RX_FIFO_DEPTH(RX_FIFO_DEPTH)
)
eth_mac_phy_10g_fifo_inst (
    .tx_clk(tx_clk), .tx_rst(tx_rst), .rx_clk(rx_clk), .rx_rst(rx_rst),
    .logic_clk(eth_clock), .logic_rst(!eth_resetn), .ptp_sample_clk(1'b0),
    .tx_axis_tdata(eth_tx_axis_tdata), .tx_axis_tkeep(eth_tx_axis_tkeep), .tx_axis_tvalid(eth_tx_axis_tvalid),
    .tx_axis_tready(eth_tx_axis_tready), .tx_axis_tlast(eth_tx_axis_tlast), .tx_axis_tuser(eth_tx_axis_tuser),
    .rx_axis_tdata(eth_rx_axis_tdata), .rx_axis_tkeep(eth_rx_axis_tkeep), .rx_axis_tvalid(eth_rx_axis_tvalid),
    .rx_axis_tready(eth_rx_axis_tready), .rx_axis_tlast(eth_rx_axis_tlast), .rx_axis_tuser(eth_rx_axis_tuser),
    .serdes_tx_data(tx_pcs_data), .serdes_tx_hdr(tx_pcs_hdr),
    .serdes_rx_data(rx_pcs_data), .serdes_rx_hdr(rx_pcs_hdr),
    .serdes_rx_bitslip(bitslip), .serdes_rx_reset_req(rx_reset_req),
    .tx_fifo_overflow(eth_status[0]), .tx_fifo_bad_frame(eth_status[1]),
    .tx_fifo_good_frame(eth_status[2]), .tx_error_underflow(eth_status[3]),
    .rx_error_bad_frame(eth_status[4]), .rx_error_bad_fcs(eth_status[5]),
    .rx_fifo_overflow(eth_status[6]), .rx_fifo_bad_frame(eth_status[7]),
    .rx_fifo_good_frame(eth_status[8]), .rx_block_lock(eth_status[9]),
    .rx_high_ber(eth_status[10]), .rx_status(eth_status[11]),
    .rx_bad_block(eth_status[12]),
    .ptp_ts_96(96'b0), .ptp_ts_step(1'b0), .m_axis_tx_ptp_ts_ready(1'b1),
    .cfg_ifg(8'd12), .cfg_tx_enable(1'b1), .cfg_rx_enable(1'b1),
    .cfg_tx_prbs31_enable(1'b0), .cfg_rx_prbs31_enable(1'b0)
);
// Preserve watchdog reset pulses across the RX -> free-running eth_clock CDC.
reg reset_toggle = 0;
always @(posedge rx_clk or negedge eth_resetn)
    if (!eth_resetn) reset_toggle <= 0;
    else if (rx_reset_req) reset_toggle <= !reset_toggle;
(* ASYNC_REG = "TRUE" *) reg [2:0] reset_sync = 0;
(* ASYNC_REG = "TRUE" *) reg [2:0] status_sync1 = 0, status_sync2 = 0;
always @(posedge eth_clock) begin
    if (!eth_resetn) begin
        reset_sync <= 0; gt_rx_reset_req <= 0;
        status_sync1 <= 0; status_sync2 <= 0;
    end else begin
        reset_sync <= {reset_sync[1:0], reset_toggle};
        gt_rx_reset_req <= reset_sync[2] ^ reset_sync[1];
        status_sync1 <= {tx_running && rx_running, rx_fault, tx_fault};
        status_sync2 <= status_sync1;
    end
end
assign eth_status[15:13] = status_sync2;
endmodule

// GTM has no 64b/66b gearbox. Bit 0 is the first bit on the wire.
// 32 PCS blocks (32*66 bits) occupy 33 raw GT words (33*64 bits).
// The PCS clocks are exactly 32/33 of their corresponding GT clocks.
module gearbox_versal_10g_tx (
    input wire pcs_clk, input wire pcs_rst,
    input wire [63:0] pcs_data, input wire [1:0] pcs_hdr,
    input wire gt_clk, input wire gt_rst,
    output reg [63:0] gt_data = 0,
    output reg running = 0, output wire fault
);
    wire [65:0] block_data;
    wire block_valid, input_ready;
    wire [7:0] depth;
    reg input_started = 0, input_fault = 0, read_fault = 0;
    (* ASYNC_REG = "TRUE" *) reg overflow_sync1 = 0, overflow_sync2 = 0;
    assign fault = read_fault || overflow_sync2;
    always @(posedge pcs_clk) begin
        if (pcs_rst) begin input_started <= 0; input_fault <= 0; end
        else begin
            if (input_ready) input_started <= 1;
            if (input_started && !input_ready) input_fault <= 1;
        end
    end
    always @(posedge gt_clk) begin
        if (gt_rst) begin overflow_sync1 <= 0; overflow_sync2 <= 0; end
        else begin overflow_sync1 <= input_fault; overflow_sync2 <= overflow_sync1; end
    end
    reg [127:0] buffer_reg = 0;
    reg [6:0] count_reg = 0;
    wire take = running && count_reg < 64;
    wire [127:0] merged = buffer_reg | ({62'b0, block_data} << count_reg);
    axis_async_fifo #(.DEPTH(128), .DATA_WIDTH(66), .KEEP_ENABLE(0),
        .LAST_ENABLE(0), .USER_ENABLE(0), .RAM_PIPELINE(1)) blocks (
        .s_clk(pcs_clk), .s_rst(pcs_rst), .s_axis_tdata({pcs_data, pcs_hdr}),
        .s_axis_tkeep(9'h1ff), .s_axis_tvalid(1'b1), .s_axis_tready(input_ready),
        .s_axis_tlast(1'b0), .s_axis_tid(8'b0), .s_axis_tdest(8'b0), .s_axis_tuser(1'b0),
        .m_clk(gt_clk), .m_rst(gt_rst), .m_axis_tdata(block_data),
        .m_axis_tvalid(block_valid), .m_axis_tready(take),
        .s_pause_req(1'b0), .m_pause_req(1'b0), .m_status_depth(depth)
    );
    // Startup fill absorbs arbitrary MMCM phase and FIFO synchronizer latency.
    // Never insert/delete bits once running; an underrun forces reacquisition.
    always @(posedge gt_clk) begin
        if (gt_rst) begin
            gt_data <= 0; buffer_reg <= 0; count_reg <= 0;
            running <= 0; read_fault <= 0;
        end else if (!running) begin
            gt_data <= 0;
            if (depth >= 16 && block_valid) running <= 1;
        end else if (take) begin
            if (block_valid) begin
                gt_data <= merged[63:0];
                buffer_reg <= merged >> 64;
                count_reg <= count_reg + 2;
            end else begin
                gt_data <= 0; buffer_reg <= 0; count_reg <= 0;
                running <= 0; read_fault <= 1;
            end
        end else begin
            gt_data <= buffer_reg[63:0];
            buffer_reg <= buffer_reg >> 64;
            count_reg <= count_reg - 64;
        end
    end
endmodule

module gearbox_versal_10g_rx (
    input wire gt_clk, input wire gt_rst, input wire [63:0] gt_data,
    input wire pcs_clk, input wire pcs_rst, input wire bitslip,
    output wire [63:0] pcs_data, output wire [1:0] pcs_hdr,
    output reg running = 0, output wire fault
);
    (* ASYNC_REG = "TRUE" *) reg slip_sync1 = 0, slip_sync2 = 0;
    reg slip_last = 0;
    wire slip = slip_sync2 && !slip_last;
    // Bitslip can leave 65 pending bits: 65 + 64 needs a 129-bit buffer.
    reg [128:0] buffer_reg = 0;
    reg [6:0] count_reg = 0;
    wire [128:0] appended = buffer_reg | ({65'b0, gt_data} << count_reg);
    wire [128:0] merged = slip ? appended >> 1 : appended;
    wire [7:0] count = {1'b0, count_reg} + 64 - slip;
    wire emit_block = count >= 66;
    wire input_ready, block_valid;
    wire [65:0] block_data;
    wire [7:0] depth;
    reg input_started = 0, input_fault = 0, read_fault = 0;
    (* ASYNC_REG = "TRUE" *) reg overflow_sync1 = 0, overflow_sync2 = 0;
    assign fault = read_fault || overflow_sync2;
    always @(posedge gt_clk) begin
        if (gt_rst) begin input_started <= 0; input_fault <= 0; end
        else begin
            if (input_ready) input_started <= 1;
            if (input_started && emit_block && !input_ready) input_fault <= 1;
        end
    end
    always @(posedge pcs_clk) begin
        if (pcs_rst) begin overflow_sync1 <= 0; overflow_sync2 <= 0; end
        else begin overflow_sync1 <= input_fault; overflow_sync2 <= overflow_sync1; end
    end
    // Discard one serial bit per bitslip request. Leave the FIFO running;
    // the PHY waits 64 PCS clocks, longer than the queued alignment latency.
    always @(posedge gt_clk) begin
        if (gt_rst) begin
            slip_sync1 <= 0; slip_sync2 <= 0; slip_last <= 0;
            buffer_reg <= 0; count_reg <= 0;
        end else begin
            slip_sync1 <= bitslip; slip_sync2 <= slip_sync1; slip_last <= slip_sync2;
            buffer_reg <= emit_block ? merged >> 66 : merged;
            count_reg <= emit_block ? count - 66 : count;
        end
    end
    axis_async_fifo #(.DEPTH(128), .DATA_WIDTH(66), .KEEP_ENABLE(0),
        .LAST_ENABLE(0), .USER_ENABLE(0), .RAM_PIPELINE(1)) blocks (
        .s_clk(gt_clk), .s_rst(gt_rst), .s_axis_tdata(merged[65:0]),
        .s_axis_tkeep(9'h1ff), .s_axis_tvalid(emit_block), .s_axis_tready(input_ready),
        .s_axis_tlast(1'b0), .s_axis_tid(8'b0), .s_axis_tdest(8'b0), .s_axis_tuser(1'b0),
        .m_clk(pcs_clk), .m_rst(pcs_rst), .m_axis_tdata(block_data),
        .m_axis_tvalid(block_valid), .m_axis_tready(running),
        .s_pause_req(1'b0), .m_pause_req(1'b0), .m_status_depth(depth)
    );
    assign pcs_data = running && block_valid ? block_data[65:2] : 64'b0;
    assign pcs_hdr = running && block_valid ? block_data[1:0] : 2'b00;
    always @(posedge pcs_clk) begin
        if (pcs_rst) begin running <= 0; read_fault <= 0; end
        else if (!running) begin
            if (depth >= 16 && block_valid) running <= 1;
        end else if (!block_valid) begin running <= 0; read_fault <= 1; end
    end
endmodule
