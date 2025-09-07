module uart_tx#(
    parameter clk_freq = 100_000_000,
    parameter oversample = 16,
    parameter data_bits = 8
)(
    input clk, PRESETn, tx_rst,
    input tx_start, tx_en, s_tick,
    input [data_bits-1:0] data_in,
    output reg tx,
    output reg tx_done, tx_busy
);
    localparam idle  = 3'b000;
    localparam start = 3'b001;
    localparam data  = 3'b010;
    localparam stop  = 3'b011;
    localparam err   = 3'b100;

reg [2:0] cs,ns;
reg [2:0] counter;
reg [data_bits-1:0] data_reg;
//state memory
always @(posedge clk or negedge PRESETn) begin
    if (!PRESETn || tx_rst) begin
        cs <= idle;
    end else begin
        cs <= ns;
    end
end
//next state logic
always @(*) begin
    case(cs) 
    idle: 
        if (tx_start && tx_en) begin
            ns = start;
        end else begin
            ns = idle;
        end
    start: 
        if (s_tick) begin
            ns = data;
        end else begin
            ns = start;
        end
    data: 
        if (s_tick) begin
            if (counter == data_bits - 1) begin
                ns = stop;
            end else begin
                ns = data;
            end
        end else begin
            ns = data;
        end
    stop:
        if (s_tick) begin
            ns = idle;
        end else
            ns = stop;
    default: ns = idle;
    endcase
end
//output logic
always @(posedge clk or negedge PRESETn) begin
    if (!PRESETn || tx_rst) begin
        tx <= 1'b1; 
        tx_done <= 1'b0;
        counter <= 3'b0;
        data_reg <= {data_bits{1'b0}};
        tx_busy <= 1'b0;
    end else begin
        case(cs)
        idle: begin
            tx <= 1'b1; 
            tx_done <= 1'b0;
            tx_busy <= 1'b0;
        end
        start: begin
            tx <= 1'b0; 
            tx_done <= 1'b0;
            tx_busy <= 1'b1;
            if(s_tick)
            data_reg <= data_in; // load data on start
            counter <= 3'b0; 
        end
        data: begin
            tx <= data_reg[0];
            tx_done <= 1'b1;
            if (s_tick) begin
                counter <= counter + 1;
                data_reg <= {1'b0, data_reg[data_bits-1:1]}; // right shift
            end
        end
        stop: begin
            tx <= 1'b1; 
            tx_busy <= 1'b1;
            if (s_tick) begin
                tx_done <= 1'b1;
                tx_busy <= 1'b0;
            end
            end
        default: begin
            tx <= 1'b1; 
            tx_done <= 1'b0;    
        end
        endcase
        if (!tx_en) begin
            tx_busy <= 1'b0;
            tx_done <= 1'b0;
            tx <= 1'b1; 
            cs <= idle;
        end
    end
end
endmodule