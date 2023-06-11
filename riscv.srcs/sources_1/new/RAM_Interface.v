`timescale 1ns / 1ps
`default_nettype none
//`define DBG

module RAM_Interface #(
    parameter ADDR_WIDTH = 16, // 2**16 = RAM depth in words
    parameter DATA_WIDTH = 32
)(
    // port A: read / write byte addressable ram (data memory)
    input wire clk,
    input wire [1:0] weA, // b01 - byte, b10 - half word, b11 - word
    input wire [2:0] reA, // reA[2] sign extended, b01: byte, b10: half word, b11: word
    input wire [ADDR_WIDTH+1:0] addrA, // byte addressable
    input wire [DATA_WIDTH-1:0] dinA, // sign extended byte, half word, word
    output reg [DATA_WIDTH-1:0] doutA, // data at 'addrA' according to 'reA'
    
    // port B: read word addressable ram (instruction memory)
    input wire [ADDR_WIDTH+1:0] addrB, // the lower 2 bits are ignored and only word aligned data returned
    output wire [DATA_WIDTH-1:0] doutB
);

reg [ADDR_WIDTH-1:0] ram_addrA;
reg [DATA_WIDTH-1:0] ram_dinA;
wire [DATA_WIDTH-1:0] ram_doutA;
reg [3:0] ram_weA;

reg [1:0] addr_lower_w;
// write
always @* begin
    ram_addrA = addrA >> 2;
    addr_lower_w = addrA & 2'b11;
    ram_weA = 0;
    ram_dinA = 0;
    case(weA)
    2'b00: begin
        ram_weA = 4'b0000;
    end
    2'b01: begin // byte
        case(addr_lower_w)
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
        case(addr_lower_w)
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

// read
reg [2:0] reA_prev; // previous reA used in the cycle when data is available
reg [1:0] addr_lower_r; // previous lower 2 bits of address to be used when data is available
always @(posedge clk) begin
    reA_prev <= reA;
    addr_lower_r <= addrA[1:0];
end

always @* begin
    doutA = 0;
    casex(reA_prev) // read size
    3'b000: begin // not a read
    end
    3'bx01: begin // byte
        case(addr_lower_r)
        2'b00: begin
            doutA = reA[2] ? {{24{ram_doutA[7]}}, ram_doutA[7:0]} : {{24{1'b0}}, ram_doutA[7:0]};
        end
        2'b01: begin
            doutA = reA[2] ? {{24{ram_doutA[15]}}, ram_doutA[15:8]} : {{24{1'b0}}, ram_doutA[15:8]};
        end
        2'b10: begin
            doutA = reA[2] ? {{24{ram_doutA[23]}}, ram_doutA[23:16]} : {{24{1'b0}}, ram_doutA[23:16]};
        end
        2'b11: begin
            doutA = reA[2] ? {{24{ram_doutA[31]}}, ram_doutA[31:24]} : {{24{1'b0}}, ram_doutA[31:24]};
        end
        endcase
    end
    3'bx10: begin // half word
        case(addr_lower_r)
        2'b00: begin
            doutA = reA[2] ? {{16{ram_doutA[15]}}, ram_doutA[15:0]} : {{24{1'b0}}, ram_doutA[15:0]};
        end
        2'b01: ; // exception
        2'b10: begin
            doutA = reA[2] ? {{16{ram_doutA[31]}}, ram_doutA[31:16]} : {{24{1'b0}}, ram_doutA[31:16]};
        end
        2'b11: ; // exception
        endcase    
    end
    3'b111: begin // word
        doutA = ram_doutA;
    end
    endcase
end

RAM #(
    .ADDR_WIDTH(ADDR_WIDTH)
) ram (
    .clkA(clk),
    .enaA(1'b1),
    .weA(ram_weA),
    .addrA(ram_addrA),
    .dinA(ram_dinA),
    .doutA(ram_doutA),
    .clkB(clk),
    .enaB(1'b1),
    .weB(4'b0000),
    .addrB(addrB[ADDR_WIDTH+1:2]),
    .dinB(0),
    .doutB(doutB)
);

endmodule

`undef DBG
`default_nettype wire