`timescale 1ns/1ps
module tb_uart_apb_top;
  // ---------------- Params ----------------
  localparam integer CLK_FREQ   = 100_000_000;
  localparam integer OVS        = 16;
  localparam integer CLK_PERIOD = 10;    // 100 MHz

  // APB
  reg         PCLK, PRESETn, PSEL, PENABLE, PWRITE;
  reg  [31:0] PADDR, PWDATA;
  wire [31:0] PRDATA;
  wire        PREADY;

  // UART pins
  wire tx_uart;
  // Divider we program (TB mirror so we can time manual RX bits)
  integer     BAUDDIV_VAL = 651; // 100e6 / (9600*16)

  // Addresses (match your regfile)
  localparam CTRL   = 32'h00;
  localparam STATUS = 32'h04;
  localparam TXDATA = 32'h08;
  localparam RXDATA = 32'h0C;
  //localparam BAUDIV = 32'h10;

  // ------------- DUT (top) -------------
  uart_apb_top #(
    .oversample(OVS),
    .data_bits (8),
    .clk_freq  (CLK_FREQ)
  ) dut (
    .PCLK   (PCLK),
    .PRESETn(PRESETn),
    .PSEL   (PSEL),
    .PENABLE(PENABLE),
    .PWRITE (PWRITE),
    .PADDR  (PADDR),
    .PWDATA (PWDATA),
    .PRDATA (PRDATA),
    .PREADY (PREADY),
    .rx     (tx_uart),
    .tx     (tx_uart)
  );

  // ------------- Clock -------------
  initial begin
    PCLK = 1'b0;
    forever #(CLK_PERIOD/2) PCLK = ~PCLK;
  end

   task do_write;
    input [31:0] addr;
    input [31:0] data;
    begin
      @(posedge PCLK);
      PADDR   = addr;
      PWDATA  = data;
      PWRITE  = 1;
      PSEL    = 1;
      PENABLE = 0;

      @(posedge PCLK);
      PENABLE = 1;

      @(posedge PCLK);
      while (!PREADY) @(posedge PCLK);

      PSEL    = 0;
      PENABLE = 0;
      PWRITE  = 0;

      $display("[%0t] WRITE 0x%0h = 0x%0h", $time, addr, data);
    end
  endtask

  task do_read;
    input  [31:0] addr;
    output [31:0] data;
    begin
      @(posedge PCLK);
      PADDR   = addr;
      PWRITE  = 0;
      PSEL    = 1;
      PENABLE = 0;

      @(posedge PCLK);
      PENABLE = 1;

      @(posedge PCLK);
      while (!PREADY) @(posedge PCLK);

      data = PRDATA;

      PSEL    = 0;
      PENABLE = 0;

      $display("[%0t] READ  0x%0h -> 0x%0h", $time, addr, data);
    end
  endtask
  localparam integer DVSR     =651;  // much faster than 651
  localparam integer SB_TICK  = 16;
  localparam integer DATA_BITS= 8;
  localparam integer STOP_BITS= 1;
  localparam integer BIT_CLKS = DVSR * SB_TICK;  // 256 sysclks per bit
  localparam integer FRAME_CLKS = BIT_CLKS * (1 + DATA_BITS + STOP_BITS); // 2560 sysclks per frame

  // === Test Sequence ===
  reg [31:0] rdata;

    initial begin
    // Init APB signals
    PADDR=0; PWDATA=0; PWRITE=0; PSEL=0; PENABLE=0;
    $display("=== UART APB Test Start ===");

    // Reset
    PRESETn = 0;
    repeat (5) @(posedge PCLK);
    PRESETn = 1;

    // 1. Read CTRL and STATS at reset
    do_read(CTRL, rdata);
    do_read(STATUS, rdata);

    // 2. Enable TX and RX
    do_write(CTRL, 32'h3); // TX_EN=1, RX_EN=1
    // 3. Transmit byte 0xA5
    do_write(TXDATA, 32'h5A);

    // wait for frame to complete
    repeat (FRAME_CLKS*2) @(posedge PCLK);

    // 4. Read STATS
    do_read(STATUS, rdata);

    // 5. Read RX_DATA
    do_read(RXDATA, rdata);
    if (rdata[7:0] == 8'h5A)
      $display("PASS: RX got expected 0x5A");
    else
      $display("FAIL: RX got 0x%0h, expected 0x5A", rdata[7:0]);
    $display("=== UART APB Test End ===");
    $stop;
  end
endmodule
