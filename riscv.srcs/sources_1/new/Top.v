`timescale 1ns / 1ps
`default_nettype none
//`define DBG

module Top (
    input wire clk_in1,
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

Clocking clocking(
  .reset(reset),
  .clk_in1(clk_in1),
  .clk_out1(clk_50MHz),
  .clk_locked(clk_locked)
);

SoC #(
    .RAM_FILE("/home/c/w/riscv/riscv.srcs/sources_1/new/os.mem")
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