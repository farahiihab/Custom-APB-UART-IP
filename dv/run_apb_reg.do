vlib work
vlog apb_rf_top.v apb_rf_top_tb.v  +cover -covercells
vsim -voptargs=+acc work.tb_apb_uart -cover
add wave *
run -all