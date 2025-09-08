module tb_uart_rx;
  localparam CLK_PERIOD  = 10; 
  localparam DATA_BITS = 8;  
  reg clk, PRESETn, rx_rst,rx_en;
  reg rx;
  wire [DATA_BITS-1:0] data_out;
  wire rx_done, rx_error, rx_busy, s_tick;


  uart_rx #(
    .data_bits(DATA_BITS),
    .clk_freq(100_000_000),
    .oversample(16)
  ) dut (
    .clk(clk), .PRESETn(PRESETn), .rx_rst(rx_rst),
    .rx(rx), .rx_en(rx_en),.data_out(data_out),
    .rx_done(rx_done), .rx_error(rx_error), .rx_busy(rx_busy),.s_tick(s_tick)
  );

    baud_gen #(.clk_freq(100_000_000),.oversample(16),.baud_rate(9600)) baud_inst (
        .clk(clk),.rst(PRESETn),.baud_clk(s_tick),.div_in(0));

   initial begin
    clk = 0;
    forever #(CLK_PERIOD/2) clk = ~clk;
  end
   task wait_s_ticks(input integer count);
        integer i;
        begin
            for (i=0; i<count; i=i+1)
                @(posedge s_tick);
        end
    endtask
   task pulse_rx_rst();
    begin
      rx_rst = 1'b1;
      @(posedge clk);
      rx_rst = 1'b0;
    end
  endtask
    // Send one bit for 16 s_ticks
    task send_bit(input val);
        begin
            rx = val;
            wait_s_ticks(16); // 16 ticks per bit (matches oversample)
        end
    endtask

    // Send a full byte LSB first
    task send_byte(input [7:0] data);
        integer i;
        begin
            send_bit(0); // Start bit
            for (i=0; i<8; i=i+1)
                send_bit(data[i]);
            send_bit(1); // Stop bit
            $display("[%0t] Sent byte 0x%0h", $time, data);
        end
    endtask
    //trigger err state
    task send_byte_bad_stop(input [7:0] data);
    integer i;
    begin
      send_bit(0);                 
      for (i=0; i<8; i=i+1)
        send_bit(data[i]);
      send_bit(0);                 // <-- BAD STOP (should be 1)
      $display("[%0t] Sent BAD-STOP byte 0x%0h", $time, data);
    end
  endtask
  reg [7:0] data_expected;
  always @(posedge clk) begin
    if (rx_done) begin
      if (data_out === data_expected) begin
        $display("  [SUCCESS] Received expected data: 0x%0h", data_out);
      end else begin
        $display("  [FAIL] Received 0x%0h, expected 0x%0h", data_out, data_expected);
      end
    end
  end
    // Monitor outputs
    always @(posedge clk) begin
        if(rx_done) begin
        $display("Time=%0t | rx=%b | rx_busy=%b | rx_done=%b | data_out=0x%0h",
                 $time, rx, rx_busy, rx_done, data_out);
        end
    end

initial begin
  rx     = 1'b1;
  rx_en  = 1'b1;
  PRESETn = 1'b0;
  rx_rst = 1'b1;

  #(20*CLK_PERIOD);
  PRESETn = 1'b1;
  rx_rst = 1'b0;
  wait_s_ticks(32);

  // Byte 1
  data_expected = 8'h55;
  send_byte(8'h55);
  // // Byte 2
  data_expected = 8'hF1;
  send_byte(8'hF1);
  // // Byte 3
  data_expected = 8'hA3;
  send_byte(8'hA3);
  // Byte with bad stop bit
  data_expected = 8'h3C;
  send_byte_bad_stop(8'h3C);

   #1000;
  $display("Testbench completed");
  $stop;
end
endmodule