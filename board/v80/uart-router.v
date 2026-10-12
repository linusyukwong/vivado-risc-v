`timescale 1ns/1ps
// Preserve riscv,axi-uart-1.0 registers while using the V80 PS UART1.
// Downstream clock and UART reference clock are configured to 100 MHz.
// Versal UART uses the PL011 register map (AMD uartpsv driver), not uartps.
module v80_uart_router (
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 clock CLK" *)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF S_AXI:M_AXI, ASSOCIATED_RESET resetn, FREQ_HZ 100000000" *)
    input wire clock,
    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 resetn RST" *)
    (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_LOW" *)
    input wire resetn,
    output wire interrupt,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI AWADDR" *)
    (* X_INTERFACE_PARAMETER = "PROTOCOL AXI4LITE, DATA_WIDTH 32, ID_WIDTH 0" *)
    input wire [15:0] s_axi_awaddr,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI AWVALID" *)
    input wire s_axi_awvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI AWREADY" *)
    output wire s_axi_awready,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI WDATA" *)
    input wire [31:0] s_axi_wdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI WSTRB" *)
    input wire [3:0] s_axi_wstrb,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI WVALID" *)
    input wire s_axi_wvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI WREADY" *)
    output wire s_axi_wready,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI BRESP" *)
    output reg [1:0] s_axi_bresp,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI BVALID" *)
    output reg s_axi_bvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI BREADY" *)
    input wire s_axi_bready,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI ARADDR" *)
    input wire [15:0] s_axi_araddr,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI ARVALID" *)
    input wire s_axi_arvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI ARREADY" *)
    output wire s_axi_arready,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI RDATA" *)
    output reg [31:0] s_axi_rdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI RRESP" *)
    output reg [1:0] s_axi_rresp,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI RVALID" *)
    output reg s_axi_rvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI RREADY" *)
    input wire s_axi_rready,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI AWADDR" *)
    (* X_INTERFACE_PARAMETER = "PROTOCOL AXI4LITE, DATA_WIDTH 32, ID_WIDTH 0" *)
    output reg [31:0] m_axi_awaddr,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI AWVALID" *)
    output reg m_axi_awvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI AWREADY" *)
    input wire m_axi_awready,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI WDATA" *)
    output reg [31:0] m_axi_wdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI WSTRB" *)
    output reg [3:0] m_axi_wstrb,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI WVALID" *)
    output reg m_axi_wvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI WREADY" *)
    input wire m_axi_wready,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI BRESP" *)
    input wire [1:0] m_axi_bresp,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI BVALID" *)
    input wire m_axi_bvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI BREADY" *)
    output wire m_axi_bready,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI ARADDR" *)
    output reg [31:0] m_axi_araddr,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI ARVALID" *)
    output reg m_axi_arvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI ARREADY" *)
    input wire m_axi_arready,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI RDATA" *)
    input wire [31:0] m_axi_rdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI RRESP" *)
    input wire [1:0] m_axi_rresp,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI RVALID" *)
    input wire m_axi_rvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI RREADY" *)
    output wire m_axi_rready
);
localparam IDLE=0, WRITE=1, READ=2;
reg [1:0] state;
reg [3:0] init_step;
reg [1:0] flush_step;
reg initialized, host_write, host_read;
reg aw_pending, w_pending;
reg [15:0] write_addr;
reg [31:0] write_data;
reg [3:0] write_strb;
reg [6:0] control;
reg [4:0] status;
reg [3:0] read_reg;
reg [9:0] poll_timer;
assign s_axi_awready = initialized && !aw_pending && !s_axi_bvalid;
assign s_axi_wready = initialized && !w_pending && !s_axi_bvalid;
assign s_axi_arready = initialized && state==IDLE && !aw_pending && !w_pending && !s_axi_rvalid;
assign m_axi_bready = state==WRITE;
assign m_axi_rready = state==READ;
assign interrupt = (control[4] && status[0]) || (control[5] && !status[3]);

task start_write;
 input [31:0] addr, data;
 begin
  m_axi_awaddr <= addr;
  m_axi_wdata <= data;
  m_axi_wstrb <= 4'hf;
  m_axi_awvalid <= 1;
  m_axi_wvalid <= 1;
  state <= WRITE;
 end
endtask

task start_read;
 input [31:0] addr;
 begin
  m_axi_araddr <= addr;
  m_axi_arvalid <= 1;
  state <= READ;
 end
endtask

always @(posedge clock) begin
 if (!resetn) begin
  state <= IDLE; init_step <= 0; flush_step <= 0; initialized <= 0;
  host_write <= 0; host_read <= 0;
  aw_pending <= 0; w_pending <= 0;
  write_addr <= 0; write_data <= 0; write_strb <= 0;
  control <= 0; status <= 5'b10100; read_reg <= 0; poll_timer <= 0;
  s_axi_bvalid <= 0; s_axi_bresp <= 0;
  s_axi_rvalid <= 0; s_axi_rresp <= 0; s_axi_rdata <= 0;
  m_axi_awvalid <= 0; m_axi_wvalid <= 0; m_axi_arvalid <= 0;
  m_axi_awaddr <= 0; m_axi_wdata <= 0; m_axi_wstrb <= 0; m_axi_araddr <= 0;
 end else begin
  poll_timer <= poll_timer + 1'b1;
  if (s_axi_bvalid && s_axi_bready) s_axi_bvalid <= 0;
  if (s_axi_rvalid && s_axi_rready) s_axi_rvalid <= 0;
  if (s_axi_awvalid && s_axi_awready) begin aw_pending <= 1; write_addr <= s_axi_awaddr; end
  if (s_axi_wvalid && s_axi_wready) begin w_pending <= 1; write_data <= s_axi_wdata; write_strb <= s_axi_wstrb; end
  if (m_axi_awvalid && m_axi_awready) m_axi_awvalid <= 0;
  if (m_axi_wvalid && m_axi_wready) m_axi_wvalid <= 0;
  if (m_axi_arvalid && m_axi_arready) m_axi_arvalid <= 0;
  case (state)
   IDLE: begin
    host_write <= 0; host_read <= 0;
    if (!initialized) begin
     // Disable UART, mask its native IRQs, set 115200 8N1, and flush FIFOs.
     // 100 MHz / (16 * (54 + 16/64)) = 115207.37 baud.
     case (init_step)
      0: start_write(32'hff010030, 32'h00000000); // UARTCR
      1: start_write(32'hff010038, 32'h00000000); // UARTIMSC
      2: start_write(32'hff010044, 32'h000007ff); // UARTICR
      3: start_write(32'hff010024, 32'd54);       // UARTIBRD
      4: start_write(32'hff010028, 32'd16);       // UARTFBRD
      5: start_write(32'hff01002c, 32'h00000060); // UARTLCR_H, FEN=0
      6: start_write(32'hff01002c, 32'h00000070); // UARTLCR_H, FEN=1
      7: start_write(32'hff010030, 32'h00000301); // UARTEN, TXE, RXE
      default: initialized <= 1;
     endcase
    end else if (aw_pending && w_pending && !s_axi_bvalid) begin
     aw_pending <= 0; w_pending <= 0;
     if (!write_strb[0]) begin s_axi_bvalid <= 1; s_axi_bresp <= 0; end
     else case (write_addr[3:0])
      4: begin
       start_write(32'hff010000, {24'b0,write_data[7:0]});
       host_write <= 1;
       status[2] <= 0;
      end
      12: begin
       control <= {write_data[6:4],4'b0};
       if (|write_data[1:0]) begin
        // PL011 has a shared FIFO flush: either reset request flushes both.
        flush_step <= 1;
        start_write(32'hff010030, 32'h00000000);
       end else start_write(32'hff010030,
        32'h00000201 | (write_data[6] ? 0 : 32'h00000100));
       host_write <= 1;
      end
      default: begin s_axi_bvalid <= 1; s_axi_bresp <= 2'b10; end
     endcase
    end else if (s_axi_arvalid && s_axi_arready) begin
     read_reg <= s_axi_araddr[3:0];
     case (s_axi_araddr[3:0])
      0: begin start_read(32'hff010000); host_read <= 1; end
      8: begin start_read(32'hff010018); host_read <= 1; end
      12: begin s_axi_rdata <= {25'b0,control}; s_axi_rresp <= 0; s_axi_rvalid <= 1; end
      default: begin s_axi_rdata <= 0; s_axi_rresp <= 2'b10; s_axi_rvalid <= 1; end
     endcase
    end else if (poll_timer==0) start_read(32'hff010018);
   end
   WRITE: if (m_axi_bvalid && m_axi_bready) begin
    state <= IDLE;
    if (!initialized) begin
     // Keep reset asserted if PS initialization fails; never mask AXI errors.
     if (m_axi_bresp==0) init_step <= init_step + 1'b1;
    end else if (host_write) begin
     if (flush_step != 0 && m_axi_bresp == 0) begin
      case (flush_step)
       1: begin start_write(32'hff01002c, 32'h00000060); flush_step <= 2; end
       2: begin start_write(32'hff01002c, 32'h00000070); flush_step <= 3; end
       3: begin
        start_write(32'hff010030, 32'h00000201 | (control[6] ? 0 : 32'h00000100));
        flush_step <= 0;
       end
      endcase
     end else begin
      flush_step <= 0; s_axi_bvalid <= 1; s_axi_bresp <= m_axi_bresp;
     end
    end
   end
   READ: if (m_axi_rvalid && m_axi_rready) begin
    state <= IDLE;
    if (!host_read || read_reg==8) begin
     if (m_axi_rresp==0) status <= {1'b1,m_axi_rdata[5],m_axi_rdata[7],m_axi_rdata[6],!m_axi_rdata[4]};
    end
    if (host_read) begin
     s_axi_rvalid <= 1; s_axi_rresp <= m_axi_rresp;
     if (read_reg==8) s_axi_rdata <= {27'b0,1'b1,m_axi_rdata[5],m_axi_rdata[7],m_axi_rdata[6],!m_axi_rdata[4]};
     else s_axi_rdata <= {24'b0,m_axi_rdata[7:0]};
    end
   end
  endcase
 end
end
endmodule
