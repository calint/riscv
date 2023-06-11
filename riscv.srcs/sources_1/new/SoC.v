`timescale 1ns / 1ps
`default_nettype none
//`define DBG

module SoC(
    input wire clk_in,
    output wire [3:0] led,
    output wire led0_b,
    output wire led0_g,
    output wire led0_r,
    input wire uart_rx,
    output wire uart_tx,
    input wire btn
);

reg [31:0] addr = 0;
reg [31:0] din = 0;
wire [31:0] dout;
reg [2:0] weA = 2'b01; // write byte 
reg [2:0] reA = 3'b000; // read none

RAM_Interface #(
    .ADDR_WIDTH(18), // 2**18 = RAM depth in words
    .DATA_WIDTH(32)
) ram (
    // port A: read / write byte addressable ram (data memory)
    .clkA(clk_in),
    .enaA(1),
    .weA(weA), // b01 - byte, b10 - half word, b11 - word
    .reA(reA), // reA[2] sign extended, b01 - byte, b10 - half word, b11 - word
    .addrA(addr), // bytes addressable
    .dinA(din),
    .doutA(dout)
    
    // port B: read word addressable ram (instruction memory)
);

reg stp = 0;

always @(posedge clk_in) begin
    if (stp == 0) begin
        addr <= addr + 1;
        din <= din + 1;
        if (addr == 15) begin
            weA <= 0;
            reA <= 3'b101; // read sign extended byte
            addr <= 0;
            stp <= 1;
        end
    end else if (stp == 1) begin
        addr <= addr + 1;
    end
end

endmodule

`undef DBG
`default_nettype wire