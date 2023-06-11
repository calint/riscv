`timescale 1ns / 1ps
`default_nettype none
//`define DBG

module RAM_Interface #(
    parameter ADDR_WIDTH = 18, // 2**18 = RAM depth in words
    parameter DATA_WIDTH = 32
)(
    input wire clkA,
    input wire enaA,
    input wire [1:0] weA, // b01 - byte, b10 - half word, b11 - word
    input wire [ADDR_WIDTH+1:0] addrA, // bytes addressable
    input wire [DATA_WIDTH-1:0] dinA,
    output wire [DATA_WIDTH-1:0] doutA
);

wire [DATA_WIDTH-1:0] doutB;
reg [ADDR_WIDTH-1:0] ram_addrA;
reg [DATA_WIDTH-1:0] ram_dinA;
reg [3:0] ram_weA;

integer addr_lower;
always @* begin
    ram_addrA = addrA >> 2;
    addr_lower = addrA & 2'b11;
    case(weA)
    2'b00:; // no write
    2'b01: begin // byte
        case(addr_lower)
        2'b00: begin
            ram_weA = 4'b0001;
            ram_dinA = dinA;
        end
        2'b01: begin
            ram_weA = 4'b0010;
            ram_dinA = dinA << 8;
        end
        2'b10: begin
            ram_weA = 4'b0100;
            ram_dinA = dinA << 16;
        end
        2'b11: begin
            ram_weA = 4'b1000;
            ram_dinA = dinA << 24;
        end
        endcase
    end
    2'b10: begin // half word
        case(addr_lower)
        2'b00: begin
            ram_weA = 4'b0011;
            ram_dinA = dinA;
        end
        2'b01: ; // exception
        2'b10: begin
            ram_weA = 4'b1100;
            ram_dinA = dinA << 16;
        end
        2'b11: ; // exception
        endcase    
    end
    2'b11: begin // word
        ram_weA = 4'b1111;
        ram_dinA = dinA;
    end
    endcase
end

RAM #(
    .ADDR_WIDTH(ADDR_WIDTH)
) ram (
    .clkA(clkA),
    .enaA(enaA),
    .weA(ram_weA),
    .addrA(ram_addrA),
    .dinA(ram_dinA),
    .doutA(doutA),
    .clkB(clkA),
    .enaB(0),
    .weB(0),
    .addrB(0),
    .dinB(0),
    .doutB(doutB)
);


endmodule

`undef DBG
`default_nettype wire