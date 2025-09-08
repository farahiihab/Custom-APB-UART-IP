`timescale 1ns/1ns
module tb_apb_uart;
reg PCLK, PRESETn, PSEL, PENABLE, PWRITE;
reg [31:0] PADDR, PWDATA;
wire [31:0] PRDATA;
wire PREADY;
wire tx_en, rx_en, tx_rst, rx_rst;
wire [7:0]  tx_data;
reg  [7:0]  rx_data;
//wire [31:0] baud_div;
reg tx_busy, rx_busy, tx_done, rx_done, rx_error;
apb_regfile dut (
  .PCLK(PCLK), .PRESETn(PRESETn), .PSEL(PSEL), .PENABLE(PENABLE), .PWRITE(PWRITE),
  .PADDR(PADDR), .PWDATA(PWDATA), .PRDATA(PRDATA), .PREADY(PREADY),
  .tx_en(tx_en), .rx_en(rx_en), .tx_rst(tx_rst), .rx_rst(rx_rst),
  .tx_data(tx_data), .rx_data(rx_data), 
  .tx_busy(tx_busy), .rx_busy(rx_busy), .tx_done(tx_done), .rx_done(rx_done), .rx_error(rx_error)
);
initial begin
  PCLK = 0;
  forever #5 PCLK = ~PCLK; 
end
task apb_write(input [31:0] addr, input [31:0] data);
begin
  @(posedge PCLK);
  PSEL   <= 1;  PWRITE <= 1;  PENABLE <= 0;
  PADDR  <= addr;  PWDATA <= data;
  @(posedge PCLK);
  PENABLE <= 1;
  @(posedge PCLK); 
  // deassert
  PSEL <= 0; PENABLE <= 0; PWRITE <= 0; PADDR <= 0; PWDATA <= 0;
end
endtask
task apb_read(input [31:0] addr, output [31:0] data);
  begin
    @(posedge PCLK);
    PSEL = 1;  PWRITE = 0;  PENABLE = 0;
    PADDR  = addr;
    @(posedge PCLK);
    PENABLE <= 1;
    while (!PREADY) @(posedge PCLK);
    data = PRDATA;
    PSEL=0; PENABLE=0; PADDR=0; PWDATA=0;
  end
endtask
reg [31:0] rtmp;
initial begin
  PSEL=0; PENABLE=0; PWRITE=0; PADDR=0; PWDATA=0;
  rx_data = 8'h00;
  tx_busy = 0; rx_busy = 0; tx_done = 0; rx_done = 0; rx_error = 0;

  // Reset (active-low)
  PRESETn = 0;
  repeat (4) @(posedge PCLK);
  PRESETn = 1;
  repeat (2) @(posedge PCLK);

  // 1) Write BAUD_DIV (e.g., 100e6 / (9600*16) = 651)
  // apb_write(32'h10, 32'd651);
  // if (baud_div !== 32'd651) begin
  //   $display("BAUD_DIV write failed: got %0d", baud_div);
  //   $stop;
  // end

  // 2) Enable TX/RX, deassert soft resets (CTRL = 0b0000_1111)
  // bit0: tx_en, bit1: rx_en, bit2: tx_rst, bit3: rx_rst
  apb_write(32'h00, 32'h0000_000F);
  //delay
  repeat (2) @(posedge PCLK);
  // check outputs reflect CTRL bits
  if (tx_en !== 1 || rx_en !== 1 || tx_rst !== 1 || rx_rst !== 1) begin
    $display("CTRL write failed: tx_en=%0b rx_en=%0b tx_rst=%0b rx_rst=%0b",
            tx_en, rx_en, tx_rst, rx_rst);
    $stop;
  end else begin
  $display("CTRL succeeded: tx_en=%0b rx_en=%0b tx_rst=%0b rx_rst=%0b",
            tx_en, rx_en, tx_rst, rx_rst);
  end 

  // 3) Write TX_DATA and see it appear on tx_data port
  apb_write(32'h08, 32'h0000_005A);
  repeat (2) @(posedge PCLK);
  if (tx_data !== 8'h5A) begin
    $display("TX_DATA write failed: tx_data=%0h", tx_data);
    $stop;
  end else begin
    $display("TX_DATA write succeeded: tx_data=%0h", tx_data);
  end

  // 4) Drive RX side inputs and read them back via RX_DATA/STATUS
  rx_data  = 8'hA3;
  tx_busy  = 1;  rx_busy = 1;  tx_done = 0;  rx_done = 1;  rx_error = 0;
  apb_read(32'h0C, rtmp);
  repeat (2) @(posedge PCLK);
  $display("Read RX_DATA = 0x%0h", rtmp[7:0]);
  if (rtmp[7:0] !== 8'hA3) $error("RX_DATA readback mismatch");

  apb_read(32'h04, rtmp);
  repeat (2) @(posedge PCLK);
  $display("Read STATUS = 0x%08h", rtmp);
  // Optional: tweak these masks to your STATUS encoding
  // Example check: at least these bits made it through
  if (rtmp[0] !== tx_busy)  $error("STATUS tx_busy mismatch");
  if (rtmp[1] !== rx_busy)  $error("STATUS rx_busy mismatch");
  if (rtmp[2] !== tx_done)  $error("STATUS tx_done mismatch");
  if (rtmp[3] !== rx_done)  $error("STATUS rx_done mismatch");
  if (rtmp[4] !== rx_error) $error("STATUS rx_error mismatch");

  // 5) Assert soft resets via CTRL (set bits low/high per your semantics)
  // If your design uses 1=assert reset, then write zeros to deassert etc.
  apb_write(32'h00, 32'h0000_0000);
  repeat (2) @(posedge PCLK);
  $display("CTRL cleared: tx_en=%0b rx_en=%0b tx_rst=%0b rx_rst=%0b",
            tx_en, rx_en, tx_rst, rx_rst);

  $display(">> APB regfile smoke test done.");
  $stop;
end

// Simple monitor
initial begin
  $monitor("t=%0t | PRESETn=%b PSEL=%b PEN=%b PWRITE=%b PADDR=%h PWDATA=%h | PRDATA=%h PREADY=%b | CTRL: tx_en=%b rx_en=%b tx_rst=%b rx_rst=%b | tx_data=%h",
            $time, PRESETn, PSEL, PENABLE, PWRITE, PADDR, PWDATA, PRDATA, PREADY,
            tx_en, rx_en, tx_rst, rx_rst, tx_data);
end

endmodule