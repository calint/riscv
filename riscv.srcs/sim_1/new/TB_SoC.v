`timescale 1ns / 1ps
`default_nettype none
`define DBG

module TB_SoC;

localparam clk_tk = 10;
reg clk = 0;
always #(clk_tk/2) clk = ~clk;

reg rst = 1;

SoC #(
    .RAM_FILE("RAM.mem")
) dut (
    .clk(clk),
    .rst(rst)
);

initial begin
    // reset
    #clk_tk
    #clk_tk
    
    rst = 0;
    // run
    repeat (8) begin
        #clk_tk;
    end
    
    $finish;
end

endmodule
