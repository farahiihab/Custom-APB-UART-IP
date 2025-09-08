vlib work
vlog uart_Rx.v Rx_tb.v  +cover -covercells
vsim -voptargs=+acc work.tb_uart_rx -cover
add wave *
run -all