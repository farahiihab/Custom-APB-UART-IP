module apb_interface(
    //APB ports
    input PCLK, PRESETn,PSEL, PENABLE,
    input [31:0]PADDR, PWDATA,  
    input PWRITE,
    output reg [31:0] PRDATA,
    output reg PREADY,

    //register file ports
    input [31:0] rf_rdata,
    output reg rf_wr_en, rf_rd_en,
    output reg [2:0] rf_addr,
    output reg [31:0] rf_wdata
);
always @(posedge PCLK or negedge PRESETn) begin
if (!PRESETn) begin
    PRDATA <= 32'b0;
    PREADY <= 1'b0;
    rf_wr_en <= 1'b0;
    rf_rd_en <= 1'b0;
    rf_addr <= 3'b0;
    rf_wdata <= 32'b0;
end else begin
    rf_wr_en <= 1'b0;
    rf_rd_en <= 1'b0;
    PREADY <= 0; 
    if(PSEL && !PENABLE) begin
            rf_addr <= PADDR[4:2]; 
            rf_wdata <= PWDATA; 
        end
    if (PSEL && PENABLE) begin
        PREADY <= 1'b1;
        if (PWRITE) begin
            rf_wr_en <= 1'b1;
        end else begin
            rf_rd_en <= 1'b1;
            PRDATA <= rf_rdata;
        end
    end
end
end 
endmodule
//PADDR EXPLANATION
//32-bit register = 4 bytes
//PADDR[4:2] = register address
// PADDR = 0x00 → PADDR[4:2] = 000 → index 0 → CTRL_REG
// PADDR = 0x04 → PADDR[4:2] = 001 → index 1 → STATS_REG
// PADDR = 0x08 → PADDR[4:2] = 010 → index 2 → TX_DATA
// PADDR = 0x0C → PADDR[4:2] = 011 → index 3 → RX_DATA
// PADDR = 0x10 → PADDR[4:2] = 100 → index 4 → BAUDIV
//PADDR[1:0] = byte address within register are always 0