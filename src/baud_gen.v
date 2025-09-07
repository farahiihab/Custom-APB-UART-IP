module baud_gen#(
    parameter clk_freq = 100_000_000,
    parameter oversample = 16,
    parameter baud_rate = 9600
)(
    input clk,
    input rst,
    input [31:0] div_in,
    output reg baud_clk
);
    wire [31:0] divisor;
    reg [31:0] div_latched;
    reg [31:0] counter;
    assign divisor = (div_in != 0)? div_in : (clk_freq / (baud_rate * oversample));
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            counter <= 32'b0;
            baud_clk <= 0;
            div_latched <= 0;
        end else begin
            baud_clk <= 0;
            if(divisor != div_latched) begin
                div_latched <= divisor;
                counter <= 0;
            end else if (counter == (div_latched - 1)) begin
                counter <= 32'b0;
                baud_clk <= 1;
            end else begin
                counter <= counter + 1;
            end
        end
    end
endmodule