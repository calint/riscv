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
    
    // start pipeline
    #clk_tk
    
    // 0: 00000013 addi x0,x0,0
    #clk_tk
    
    // 4: 12345537 lui x10,0x12345
    #clk_tk
    if (dut.regs.mem[10]==32'h1234_5000) $display("test 1 passed"); else $display("test 1 FAILED"); 
    
    // 8: 67850513 addi x10,x10,1656 # 12345678
    #clk_tk
    if (dut.regs.mem[10]==32'h1234_5678) $display("test 2 passed"); else $display("test 2 FAILED"); 
        
    // c: 00300593 addi x11,x0,3
    #clk_tk
    if (dut.regs.mem[11]==32'h3) $display("test 3 passed"); else $display("test 3 FAILED"); 

    // 10: 0045a613 slti x12,x11,4
    #clk_tk
    if (dut.regs.mem[12]==32'h1) $display("test 4 passed"); else $display("test 4 FAILED"); 

    // 14: fff5a613 slti x12,x11,-1
    #clk_tk
    if (dut.regs.mem[12]==32'h0) $display("test 5 passed"); else $display("test 5 FAILED"); 

    // 18: 0045b613 sltiu x12,x11,4
    #clk_tk
    if (dut.regs.mem[12]==32'h1) $display("test 6 passed"); else $display("test 6 FAILED"); 
    
    // 1c: fff5b613 sltiu x12,x11,-1
    #clk_tk
    if (dut.regs.mem[12]==32'h1) $display("test 7 passed"); else $display("test 7 FAILED"); 

    // 20: fff64693 xori x13,x12,-1
    #clk_tk
    if (dut.regs.mem[13]==32'hffff_fffe) $display("test 8 passed"); else $display("test 8 FAILED"); 
   
    $finish;
end

endmodule
