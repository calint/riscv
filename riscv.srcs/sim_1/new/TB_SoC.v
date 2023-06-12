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
    
    // first stage in pipeline
    #clk_tk
    
    // 0:	00000013 addi x0,x0,0
    #clk_tk
    
    // 4:	12345537 lui x10,0x12345
    #clk_tk
    if (dut.regs.mem[10]==32'h1234_5000) $display("test 1 passed"); else $display("test 1 FAILED"); 
    
    // 8:	67850513 addi x10,x10,1656 # 12345678
    #clk_tk
    if (dut.regs.mem[10]==32'h1234_5678) $display("test 2 passed"); else $display("test 2 FAILED"); 
        
    $finish;
end

endmodule
