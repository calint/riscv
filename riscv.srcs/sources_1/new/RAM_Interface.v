`timescale 1ns / 1ps
`default_nettype none
//`define DBG

module RAM_Interface #(
    parameter ADDR_WIDTH = 16, // 2**16 = RAM depth in 4 byte words
    parameter DATA_WIDTH = 32,
    parameter DATA_FILE = "RAM.mem",
    parameter CLK_FREQ = 50_000_000,
    parameter BAUD_RATE = 9600,
    parameter TOP_ADDR = {(ADDR_WIDTH+2){1'b1}},
    parameter ADDR_LEDS = TOP_ADDR, // address of leds, 7 bits, rgb 4:6 enabled is off
    parameter ADDR_UART_OUT = TOP_ADDR-1, // send byte address
    parameter ADDR_UART_IN = TOP_ADDR-2 // received byte address, must be read with 'lbu'
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
    output wire uart_tx,
    input wire uart_rx
);

// RAM
reg [ADDR_WIDTH-1:0] ram_addrA;
reg [DATA_WIDTH-1:0] ram_dinA;
wire [DATA_WIDTH-1:0] ram_doutA;
reg [3:0] ram_weA;

// write
reg [1:0] addr_lower_w;
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
reg [ADDR_WIDTH+1:0] addrA_prev; // address used in previous cycle
reg [2:0] reA_prev; // reA from previous cycle used in this cycle (due to one cycle delay of data ready)

// uarttx
reg [7:0] uarttx_data;
reg uarttx_go;
wire uarttx_bsy;

// uartrx
wire uartrx_dr; // data ready
wire [7:0] uartrx_data; // data being read
reg uartrx_go; // enabled to start receiving and disabled to acknowledge that data has been read
reg [7:0] uartrx_data_read; // data from 'uartrx_data' when 'uartrx_dr' (data ready) enabled

always @* begin
//    doutA = 0; // ? note. uncommenting this creates infinite loop when simulating with iverilog
    // create the 'doutA' based on the 'addrA' in previous cycle (one cycle delay for data ready)
    if (addrA_prev == ADDR_UART_OUT && reA_prev == 3'b001) begin
        // read unsigned byte from uart_tx
        doutA = {{24{1'b0}}, uarttx_data};
    end else if (addrA_prev == ADDR_UART_IN && reA_prev == 3'b001) begin
        // read unsigned byte from uart_rx
        doutA = {{24{1'b0}}, uartrx_data_read};
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

always @(posedge clk) begin
    if (rst) begin
        leds <= 7'b111_0000; // turn off all leds
        uarttx_data <= 0;
        uarttx_go <= 0;
        uartrx_go <= 1;
        uartrx_data_read <= 0;
    end else begin
        reA_prev <= reA;
        addrA_prev <= addrA;
        // if previous command was a read from uart then reset the read data
        if (addrA_prev == ADDR_UART_IN && reA_prev == 3'b001) begin
            uartrx_data_read <= 0;
        end
        // if uart has data ready then copy the data from uart and acknowledge (uartrx_go = 0)
        if (uartrx_dr && uartrx_go) begin
            uartrx_data_read <= uartrx_data;
            uartrx_go <= 0;
        end
        // if previous cycle acknowledged receiving data then start receiving next data (uartrx_go = 1)
        if (uartrx_go == 0) begin
            uartrx_go <= 1;
        end
        // if uart done sending data then acknowledge (uarttx_go = 0)
        if (!uarttx_bsy && uarttx_go) begin
            uarttx_data <= 0;
            uarttx_go <= 0;
        end
        // if writing to leds
        if (addrA == ADDR_LEDS && weA == 2'b01) begin
            leds <= dinA[6:0];
        // if writing to uart
        end else if (addrA == ADDR_UART_OUT && weA == 2'b01) begin
            uarttx_data <= dinA[7:0];
            uarttx_go <= 1;
        end
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
    .data(uarttx_data), // data to send
    .go(uarttx_go), // enable to start transmission, disable after 'data' has been read
    .tx(uart_tx), // uart tx wire
    .bsy(uarttx_bsy) // enabled while sendng
);

UartRx #(
    .CLK_FREQ(CLK_FREQ),
    .BAUD_RATE(BAUD_RATE)
) uartrx (
    .rst(rst),
    .clk(clk),
    .rx(uart_rx),
    .go(uartrx_go),
    .data(uartrx_data),
    .dr(uartrx_dr) // enabled when data is ready
);

endmodule

`undef DBG
`default_nettype wire