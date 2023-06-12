`timescale 1ns / 1ps
`default_nettype none
//`define DBG

module Registers #(
    parameter ADDR_WIDTH = 5,
    parameter WIDTH = 32
)(
    input wire clk,
    input wire [ADDR_WIDTH-1:0] rs1,
    input wire [ADDR_WIDTH-1:0] rs2,
    input wire [ADDR_WIDTH-1:0] rd,
    input wire [WIDTH-1:0] rd_wd, // data to write to register 'rd' when 'rd_we' is enabled
    input wire rd_we,
    output wire [WIDTH-1:0] rd1, // value of register 'ra1'
    output wire [WIDTH-1:0] rd2, // value of register 'ra2'
    input wire [ADDR_WIDTH-1:0] ra3, // register address 3
    input wire [WIDTH-1:0] wd3, // data to write to register 'ra3' when 'we3' is enabled
    input wire we3
);

reg signed [WIDTH-1:0] mem [0:2**ADDR_WIDTH-1];

assign rd1 = mem[rs1];
assign rd2 = mem[rs2];

integer i;
initial begin
    for (i = 0; i < 2**ADDR_WIDTH; i = i + 1) begin
        mem[i] = {WIDTH{1'b0}};
    end
end

always @(posedge clk) begin
    `ifdef DBG
        $display("%0t: clk+: Registers (rs1,rs2,rd)=(%0h,%0h,%0h)", $time, rs1, rs2, rd);
    `endif

    // write first the 'wd3' which is from a 'ld'
    // then the 'wd2' which might overwrite the 'wd3'
    //   example: ld r1 r7 ; add r7 r7
    if (we3) 
        mem[ra3] <= wd3;
    if (rd_we)
        mem[rd] <= rd_wd;
end

endmodule

`undef DBG
`default_nettype wire