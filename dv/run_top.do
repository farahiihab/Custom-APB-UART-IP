vlib work
vlog uart_apb_top.v uart_apb_top_tb.v  +cover -covercells
vsim -voptargs=+acc work.tb_uart_apb_top -cover
add wave *
run -all