vlib work
vlog uart_Tx.v tx_tb.v  +cover -covercells
vsim -voptargs=+acc work.tb_uart_tx -cover
add wave *
run -all