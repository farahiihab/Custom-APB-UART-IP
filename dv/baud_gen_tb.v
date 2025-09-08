`timescale 1ns/1ps

module tb_baud_gen;
    localparam clk_freq = 100_000_000;
    localparam oversample = 16;
    localparam baud_rate = 9600;
  // Clock and reset
  reg clk;
  reg rst;
  wire baud_clk;
  reg [31:0] baud_div;

  // Instantiate DUT
  baud_gen #(
    .clk_freq(clk_freq),
    .oversample(oversample),
    .baud_rate(baud_rate)
  ) dut (
    .clk(clk),
    .rst(rst),
    .baud_clk(baud_clk),
    .div_in(baud_div)
  );

  // Clock Generation (100 MHz -> 10 ns period)
  localparam clk_period = 10;
  initial begin
    clk = 0;
    forever #(clk_period/2) clk = ~clk;
  end

  // Test Sequence
  initial begin
    // Apply reset
    rst = 1'b0;
    baud_div = 32'd0; // Example divisor for 9600 baud with 16x oversampling
    #(clk_period*5);
    rst = 1'b1;

    // Run long enough to see multiple ticks
    #(clk_period*200000);

    baud_div = 32'd54; // Change divisor to simulate different baud rate
    #(clk_period*200000);

    $stop;
  end

  // Monitor tick pulses
  initial begin
    $monitor("Time=%0t ns | baud_clk=%b | counter=%0d | divisor=%0d", 
              $time, baud_clk, dut.counter, dut.divisor);
  end

endmodule
