vlib work
vlog uart.v uart_tb.v  +cover -covercells
vsim -voptargs=+acc work.uart_tb -cover
add wave *
run -all