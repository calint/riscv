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
reg [31:0] data = 32'h1234abcd;
wire [31:0] dob;
reg [3:0] weA = 0; 

RAM #(
    .ADDR_WIDTH(18)
) ram (
    .clkA(clk_in),
    .enaA(1),
    .weA(weA),
    .addrA(addr),
    .dinA(data),
    .doutA(led),
    .clkB(clk_in),
    .enaB(0),
    .weB(0),
    .addrB(0),
    .dinB(0),
    .doutB(dob)
);

reg stp = 0;

always @(posedge clk_in) begin
    if (stp == 0) begin
        addr <= addr + 1;
        //data <= data + 1;
        if (addr == 15) begin
            weA <= 0;
            stp <= 1;
            addr <= 0;
        end else begin
            weA <= weA + 1;
        end
    end else if (stp == 1) begin
        addr <= addr + 1;
    end
end

endmodule

`undef DBG
`default_nettype wire