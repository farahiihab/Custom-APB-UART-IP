`timescale 1ns/1ps

module tb_uart_tx;

  // Parameters
  localparam CLK_PERIOD = 10;    // 100 MHz clock
  localparam DATA_BITS  = 8;

  // DUT ports
  reg  clk, rst_n;
  reg  tx_start, tx_en;
  reg  [DATA_BITS-1:0] data_in;
  wire tx, s_tick;
  wire tx_done;
  wire tx_busy;

  // Instantiate DUT
  uart_tx #(
    .clk_freq(100_000_000),
    .oversample(16),
    .data_bits(DATA_BITS)
  ) dut (
    .clk(clk),
    .PRESETn(rst_n),
    .tx_start(tx_start),
    .tx_en(tx_en),
    .s_tick(s_tick),
    .data_in(data_in),
    .tx(tx),
    .tx_done(tx_done),
    .tx_busy(tx_busy)
  );
  baud_gen #(
    .clk_freq(100_000_000),
    .oversample(16),
    .baud_rate(9600)
  ) baud_inst (
    .clk(clk),
    .rst(rst_n),
    .baud_clk(s_tick), .div_in(0)
  );
  // Clock generation
  initial begin
    clk = 0;
    forever #(CLK_PERIOD/2) clk = ~clk;
  end

  // Apply reset
  initial begin
    rst_n = 0;
    tx_en = 0;
    tx_start = 0;
    data_in = 0;
    #(10*CLK_PERIOD);
    rst_n = 1;
    tx_en = 1;  // enable TX
  end

  // Monitor
  always @(posedge clk) begin
    $display("Time=%0t | tx=%b | tx_busy=%b | tx_done=%b | state=%0d | counter=%0d", 
              $time, tx, tx_busy, tx_done, dut.cs, dut.counter);
  end

  // Task to transmit a byte
  task send_byte;
    input [7:0] byte;
    begin
      @(posedge clk);
      data_in  <= byte;
      tx_start <= 1;
      @(posedge clk);
      tx_start <= 0;
      // wait until transmission done
      wait (tx_done);
      $display("[%0t] Sent byte 0x%0h done", $time, byte);
    end
  endtask

  // Test sequence
  initial begin
    @(posedge rst_n);  // wait for reset deassert
    #(20*CLK_PERIOD);

    send_byte(8'h55);   // send 0x55
    #(200*CLK_PERIOD);
    send_byte(8'hA5);   // send 0xA5
    #(20*CLK_PERIOD);
    send_byte(8'hFF);   // send 0xFF

    #(2000*CLK_PERIOD);
    $stop;
  end

endmodule
