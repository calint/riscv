`timescale 1ns / 1ps
//
`default_nettype none
//`define DBG

module Top (
    input wire clk, // 12 MHz system clock
    input wire reset,
    output wire [3:0] led,
    output wire led0_b,
    output wire led0_g,
    output wire led0_r,
    input wire uart_rx,
    output wire uart_tx,
    input wire btn
);

wire clk_50MHz;
wire clk_locked;

clocking clocking(
    .reset(reset),
    .clk_in1(clk),
    .clk_out1(clk_50MHz),
    .locked(clk_locked)
);

SoC #(
//    .RAM_FILE("/home/c/w/riscv/riscv.srcs/sim_1/new/RAM.mem"),
//    .RAM_FILE("/home/c/w/riscv/riscv.srcs/sim_3/new/RAM.mem"),
//    .RAM_FILE("/home/c/w/riscv/riscv.srcs/sources_1/new/os.mem"),
    .RAM_FILE("os.mem"),
    .CLK_FREQ(50_000_000),
    .BAUD_RATE(9600)
) soc (
    .clk(clk_50MHz),
    .rst(reset || !clk_locked),
    .led(led),
    .led0_b(led0_b),
    .led0_g(led0_g),
    .led0_r(led0_r),
    .uart_rx(uart_rx),
    .uart_tx(uart_tx),
    .btn(btn)
);

endmodule

`undef DBG
`default_nettype wire