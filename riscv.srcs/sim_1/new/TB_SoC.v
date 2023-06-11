`timescale 1ns / 1ps
`default_nettype none
`define DBG

module TB_SoC;

reg clk_in = 0;
wire [3:0] led;

SoC dut (
    .clk_in(clk_in),
    .led(led),
    .uart_rx(1'b1)
);

always #5 clk_in = ~clk_in;

initial begin
    repeat (34) begin
        #10;
    end
    
    $finish;  // End simulation
end

endmodule
