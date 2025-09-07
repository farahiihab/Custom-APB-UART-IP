module uart_regfile(
    //from apb bus
input clk,rst,wr_en,
input [2:0] addr,
input [31:0] wdata,
output reg [31:0] rdata,
//to/from uart
input tx_busy,tx_done, rx_busy, rx_error,rx_done,
input [7:0] rx_data,
output tx_en,rx_en,
output reg rx_rst,tx_rst,tx_start,
output reg [7:0] tx_data
//output reg [31:0] baud_div
);
reg [1:0] ctrl_en;
assign tx_en = ctrl_en[0];
assign rx_en = ctrl_en[1];
reg[7:0] rx_data_latch;
wire [31:0] STATS_REG = {27'd0, rx_error, rx_done, tx_done, rx_busy, tx_busy};
localparam  CTRL=3'd0,
            STATS=3'd1,
            TXDATA=3'd2,
            RXDATA=3'd3;
            //BAUDIV=3'd4;
//localparam [31:0] baud_default = 32'd651;

always @(posedge clk or negedge rst) begin
    if (!rst) begin
        ctrl_en <= 2'b00;
        rx_rst <= 1'b0;
        tx_rst <= 1'b0;
        rx_data_latch <= 8'b0;
        tx_data <= 8'b0;
       // baud_div <= baud_default;
        rdata <= 32'b0;
        tx_start <= 0;
    end else begin
        tx_rst <= 1'b0;
        if (rx_done) begin
            rx_data_latch <= rx_data;
        end
     if (wr_en) begin
        case(addr)
        CTRL: begin
            ctrl_en <= wdata[1:0];
            if (wdata[2]) tx_rst <= 1'b1;
            else tx_rst <= 1'b0;
            if (wdata[3]) rx_rst <= 1'b1;
            else rx_rst <= 1'b0;
        end
        TXDATA: begin
            if(wr_en) begin
            tx_data <= wdata[7:0];
            tx_start <=1'b1;
            end
        end
        // BAUDIV: begin
        //     baud_div <= wdata;
        // end
        endcase
     end
    end
end
always @(*) begin
    case(addr)
    CTRL: rdata = {28'b0,rx_rst,tx_rst, ctrl_en};
    STATS: rdata = STATS_REG;
    TXDATA: rdata = {24'b0, tx_data};
    RXDATA: rdata = {24'b0, rx_data_latch};
    //BAUDIV: rdata = baud_div;
    default: rdata = 32'b0;
    endcase
end
endmodule