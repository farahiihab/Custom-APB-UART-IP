module uart_top#(
    parameter oversample = 16,
    parameter data_bits = 8,
    parameter clk_freq = 100_000_000
)(
    input clk,PRESETn,rx,rx_en,tx_en,rx_rst,tx_rst, s_tick,tx_start,
    input [data_bits-1:0] tx_data,  
    output tx, rx_done, rx_error, rx_busy, tx_busy, tx_done,
    output [data_bits-1:0] rx_data
);
//baud generator
baud_gen #(.clk_freq(clk_freq),.oversample(oversample),.baud_rate(9600))
 baud_inst (.clk(clk),.rst(PRESETn),.baud_clk(s_tick),.div_in(0));
//uart receiver
uart_rx #(.data_bits(data_bits),.clk_freq(clk_freq),.oversample(oversample)) rx_inst (
    .clk(clk),.PRESETn(PRESETn),.rx(rx),.rx_en(rx_en),.rx_rst(rx_rst),.s_tick(s_tick),
    .data_out(rx_data),.rx_done(rx_done),.rx_error(rx_error),.rx_busy(rx_busy));
//uart transmitter
uart_tx #(.clk_freq(clk_freq),.oversample(oversample),.data_bits(data_bits)) tx_inst (
    .clk(clk),.PRESETn(PRESETn),.tx_start(tx_start),.tx_en(tx_en),.s_tick(s_tick),
    .data_in(tx_data),.tx(tx),.tx_done(tx_done),.tx_busy(tx_busy),.tx_rst(tx_rst));
endmodule