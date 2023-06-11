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

// Clock generator
always #5 clk_in = ~clk_in;

// Stimulus generation
initial begin
    #10;  // Wait for some initial cycles
    
    repeat (32) begin
        #10;  // Wait for 10 cycles
    end
    
    $finish;  // End simulation
end

// Monitor
always @(posedge clk_in) begin
    $display("led: %h", led);
end

endmodule
