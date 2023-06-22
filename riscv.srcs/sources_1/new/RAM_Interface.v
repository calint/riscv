`timescale 1ns / 1ps
`default_nettype none
//`define DBG

module RAM_Interface #(
    parameter ADDR_WIDTH = 16, // 2**16 = RAM depth in words
    parameter DATA_WIDTH = 32,
    parameter DATA_FILE = "RAM.mem",
    parameter CLK_FREQ = 50_000_000,
    parameter BAUD_RATE = 9600
)(
    input wire rst,
    
    // port A: data memory, read / write byte addressable ram
    input wire clk,
    input wire [1:0] weA, // b01 - byte, b10 - half word, b11 - word
    input wire [2:0] reA, // reA[2] sign extended, b01: byte, b10: half word, b11: word
    input wire [ADDR_WIDTH+1:0] addrA, // byte addressable
    input wire [DATA_WIDTH-1:0] dinA, // sign extended byte, half word, word
    output reg [DATA_WIDTH-1:0] doutA, // data at 'addrA' according to 'reA'
    
    // port B: instruction memory, byte addressed, bottom 2 bits ignored, word aligned
    input wire [ADDR_WIDTH+1:0] addrB,
    output wire [DATA_WIDTH-1:0] doutB,

    // I/O mapping of leds
    output reg [6:0] leds,
    
    // uart
    output wire uart_tx
);

reg [ADDR_WIDTH-1:0] ram_addrA;
reg [DATA_WIDTH-1:0] ram_dinA;
wire [DATA_WIDTH-1:0] ram_doutA;
reg [3:0] ram_weA;

reg [7:0] uarttx_out;
reg uarttx_go;
wire uarttx_bsy;

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
            ram_dinA[7:0] = dinA[7:0];
        end
        2'b01: begin
            ram_weA = 4'b0010;
            ram_dinA[15:8] = dinA[7:0];
        end
        2'b10: begin
            ram_weA = 4'b0100;
            ram_dinA[23:16] = dinA[7:0];
        end
        2'b11: begin
            ram_weA = 4'b1000;
            ram_dinA[31:24] = dinA[7:0];
        end
        endcase
    end
    2'b10: begin // half word
        case(addr_lower_w)
        2'b00: begin
            ram_weA = 4'b0011;
            ram_dinA[15:0] = dinA[15:0];
        end
        2'b01: ; // ? error
        2'b10: begin
            ram_weA = 4'b1100;
            ram_dinA[31:16] = dinA[15:0];
        end
        2'b11: ; // ? error
        endcase    
    end
    2'b11: begin // word
        // ? assert(addr_lower_w==0)
        ram_weA = 4'b1111;
        ram_dinA = dinA;
    end
    endcase
end

// read
reg [ADDR_WIDTH+1:0] addrA_prev;
reg [2:0] reA_prev; // reA at read used in the next cycle when data is ready

always @(posedge clk) begin
    if (rst) begin
        leds <= 7'b111_0000; // turn of all leds
        uarttx_out <= 0;
    end else begin
        reA_prev <= reA;
        addrA_prev <= addrA;
        if (!uarttx_bsy && uarttx_go) begin
//            $display("%0t: uarttx_bsy=false", $time);
            uarttx_out <= 0;
            uarttx_go <= 0;
        end
        if (addrA == {(ADDR_WIDTH+2){1'b1}} && weA == 2'b01) begin
            leds <= dinA[6:0];
        end else if (addrA == {(ADDR_WIDTH+2){1'b1}} - 1 && weA == 2'b01) begin
//            $display("%0t: addrA=%0h data=%0h", $time, addrA, dinA);
            uarttx_out <= dinA[7:0];
            uarttx_go <= 1;
        end
    end
end

always @* begin
    // create the 'doutA' based on the 'addrA' in previous cycle (one cycle delay for data ready)
    if (addrA_prev == {(ADDR_WIDTH+2){1'b1}} - 1 && reA_prev == 3'b001) begin
        // read unsigned byte from 0x1fffe
        doutA = {{24{1'b0}}, uarttx_out};
//        $display("%0t: get uarttx_out: doutA=%0h", $time, doutA);
    end else begin
        casex(reA_prev) // read size
        3'bx01: begin // byte
            case(addrA_prev[1:0])
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
            case(addrA_prev[1:0])
            2'b00: begin
                doutA = reA[2] ? {{16{ram_doutA[15]}}, ram_doutA[15:0]} : {{24{1'b0}}, ram_doutA[15:0]};
            end
            2'b01: doutA = 0; // ? error
            2'b10: begin
                doutA = reA[2] ? {{16{ram_doutA[31]}}, ram_doutA[31:16]} : {{24{1'b0}}, ram_doutA[31:16]};
            end
            2'b11: doutA = 0; // ? error
            endcase    
        end
        3'b111: begin // word
            // ? assert(addr_lower_w==0)
            doutA = ram_doutA;
        end
        default: doutA = 0;
        endcase
    end
end

RAM #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_FILE(DATA_FILE)
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


UartTx #(
    .CLK_FREQ(CLK_FREQ),
    .BAUD_RATE(BAUD_RATE)
) uarttx (
    .rst(rst),
    .clk(clk),
    .data(uarttx_out), // data to send
    .go(uarttx_go), // enable to start transmission, disable after 'data' has been read
    .tx(uart_tx), // uart tx wire
    .bsy(uarttx_bsy) // enabled while sendng
);

endmodule

`undef DBG
`default_nettype wire