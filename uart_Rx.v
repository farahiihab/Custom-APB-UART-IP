module uart_rx #(
    parameter data_bits = 8,
    parameter clk_freq = 100_000_000,
    parameter oversample = 16
)(
    input clk, PRESETn,s_tick,
    input rx, rx_en, rx_rst,
    output reg [data_bits-1:0] data_out,
    output reg rx_done, rx_error, rx_busy
);
    // State encoding
    localparam idle  = 3'b000;
    localparam start = 3'b001;
    localparam data  = 3'b010;
    localparam stop  = 3'b011;
    localparam done  = 3'b100;
    localparam err   = 3'b101;
    localparam NBIT_IDX =(data_bits <= 2) ? 1 : $clog2(data_bits);
    localparam NTICK = (oversample <= 2) ? 1 : $clog2(oversample) + 1; 

    reg [2:0] cs,ns;
    reg [NBIT_IDX-1:0] bit_index;
    reg [NTICK-1:0] tick_cnt;
    reg [data_bits-1:0] data_reg;
    //wire [NTICK-1:0] mid = (oversample[NTICK-1:0] >> 1) - 1;

    always@ (posedge clk or negedge PRESETn) begin
        if(!PRESETn || rx_rst)begin
            cs <= idle;
        end else begin
            cs <= ns;
        end 
    end
// next state logic
    always @(*) begin
        ns = cs;
        case (cs)
        idle : begin
            if (!rx_en) begin
                ns = idle;
            end else if (rx == 1'b0)  // start bit detected
                ns = start;
        end 
        start : begin
            if(s_tick && tick_cnt == (oversample/2 - 1)) begin
                if(rx == 1'b0) begin // validate start bit
                    ns = data;
                end else begin
                    ns = idle; // false start bit
                end
            end
        end
        data: begin
            if(s_tick &&tick_cnt == (oversample - 1)) begin
                if (bit_index == data_bits - 1) begin
                    ns = stop;
                end else begin
                    ns = data;
                end
            end
        end
        stop: begin
            if(s_tick && tick_cnt == (oversample - 1)) begin
                if(rx == 1'b1) begin // validate stop bit
                    ns = done;
                end else begin
                    ns = err; // framing error
                end
            end
        end
        done: begin
                ns = idle;
        end
        err: ns = idle;
        default: ns = idle;
        endcase
    end
// output logic
always @(posedge clk or negedge PRESETn) begin
    if(!PRESETn || rx_rst) begin
        tick_cnt <= {NTICK{1'b0}};
        bit_index <= {NBIT_IDX{1'b0}};
        data_reg <= {data_bits{1'b0}};
        data_out <= {data_bits{1'b0}};
        rx_done <= 1'b0;
        rx_error <= 1'b0;
        rx_busy <= 1'b0;
    end else begin
        rx_done <= 0;
        case (cs)
        idle: begin
            tick_cnt <= {NTICK{1'b0}};
            bit_index <= {NBIT_IDX{1'b0}};
            rx_busy <= 1'b0;
        end
        start: begin
            rx_busy <= 1;
            if(s_tick) tick_cnt <= tick_cnt + 1;
            end
        data: begin
            if (s_tick) begin
            tick_cnt <= tick_cnt + 1;
            if (tick_cnt == (oversample-1)) begin
                tick_cnt <= {NTICK{1'b0}};
                data_reg <= {rx,data_reg[data_bits-1:1]}; // shift right, LSB first
                bit_index <= bit_index + 1;
            end
        end
        end
        stop: begin
            if (s_tick) begin
            tick_cnt <= tick_cnt + 1;
            if(tick_cnt == (oversample-1)) begin
                tick_cnt <= {NTICK{1'b0}};
            end
            end
        end
        done: begin
            data_out <= data_reg;
            rx_done <= 1'b1;
            rx_busy <= 0;
        end
        err: rx_error <= 1'b1;
        endcase
    end
end

 endmodule