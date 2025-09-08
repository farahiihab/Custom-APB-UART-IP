module uart_tb;
localparam clk_period = 10;
localparam oversample = 16;
localparam clk_freq = 100_000_000;
localparam data_bits = 8;
reg clk, PRESETn,rx,rx_rst,tx_en,tx_rst,rx_en;
wire s_tick;
wire tx, rx_done, rx_error, rx_busy, tx_busy, tx_done;
reg tx_start;
wire [data_bits-1:0] rx_data;
reg [data_bits-1:0] tx_data;
baud_gen #(.clk_freq(clk_freq),.oversample(oversample),.baud_rate(9600)) baud_inst (
    .clk(clk),.rst(PRESETn),.baud_clk(s_tick),.div_in(0)
);
uart_top #(.oversample(oversample),.clk_freq(clk_freq),.data_bits(data_bits)) 
uart_inst (.clk(clk),.PRESETn(PRESETn),.rx(rx),.tx(tx), .s_tick(s_tick),
.rx_rst(rx_rst),.tx_en(tx_en),.rx_en(rx_en),.tx_rst(tx_rst),.rx_data(rx_data),
.tx_data(tx_data),.rx_done(rx_done),.rx_error(rx_error),.rx_busy(rx_busy),.tx_busy(tx_busy),
  .tx_done(tx_done),.tx_start(tx_start));

reg [data_bits-1:0] data_expected;
initial begin
    clk = 0;
    forever #(clk_period/2) clk = ~clk; 
end
initial begin
    PRESETn = 0;
    rx = 1;
    tx_data = 8'h00;
    tx_start = 0;
    #(20*clk_period);
    PRESETn = 1;
    @(posedge clk); 
    rx_en = 1; tx_en = 1; rx_rst = 0; tx_rst = 1;
    @(posedge clk);  
    rx_rst = 1; tx_rst = 0;
    wait_s_ticks(32);
    //test 1
    data_expected = 8'h55; 
    send_and_expect(8'h55);
    //test2
    data_expected = 8'hF1;
    send_and_expect(8'hF1);
    //test 3
    data_expected = 8'hA3;
    send_and_expect(8'hA3);
    // test 4
    data_expected = 8'h3C;
    send_and_expect(8'h3C);   
    //test 5
    send_byte_bad_stop(8'hC7);
    #(2000*clk_period);
    $display("Simulation complete");
    $stop;
end
task wait_s_ticks(input integer count);
        integer i;
        begin
            for (i=0; i<count; i=i+1)
                @(posedge s_tick);
        end
    endtask
task send_bit(input val);
    begin
      rx = val;
      wait_s_ticks(16); // one bit time
    end
endtask

task send_byte(input [7:0] data);
integer i;
begin
    send_bit(0);              // start
    for (i=0; i<8; i=i+1)
    send_bit(data[i]);      // data bits LSB-first
    send_bit(1);              // stop
    $display("[%0t] Sent byte 0x%0h", $time, data);
end
endtask

task send_byte_bad_stop(input [7:0] data);
integer i;
begin
    send_bit(0);
    for (i=0; i<8; i=i+1)
    send_bit(data[i]);
    send_bit(0);              // bad stop
    $display("[%0t] Sent BAD STOP 0x%0h", $time, data);
end
endtask
task send_and_expect(input [7:0] d);
begin
    data_expected = d;  
    @(negedge clk);
    tx_data  = d;
    tx_start = 1;
    @(negedge clk);
    tx_start = 0;    
    send_byte(d);
    
end
endtask
always @(posedge clk) begin
    if (rx_done) begin
      if (rx_data === data_expected) begin
        $display("  [SUCCESS] Received expected data: 0x%0h", rx_data);
      end else begin
        $display("  [FAIL] Received 0x%0h, expected 0x%0h", rx_data, data_expected);
      end
    end
end
always @(posedge clk) begin
// Show TX line transitions
$display("Time=%0t | RX=%b TX=%b", $time, rx, tx);
end
endmodule