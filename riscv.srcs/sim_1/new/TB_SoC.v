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
   
   // 24: 0016e693 ori x13,x13,1
    #clk_tk
    if (dut.regs.mem[13]==32'hffff_ffff) $display("test 9 passed"); else $display("test 9 FAILED"); 

    // 28: 0026f693 andi x13,x13,2
    #clk_tk
    if (dut.regs.mem[13]==32'h2) $display("test 10 passed"); else $display("test 10 FAILED"); 

    // 2c: 00369693 slli x13,x13,0x3
    #clk_tk
    if (dut.regs.mem[13]==16) $display("test 11 passed"); else $display("test 11 FAILED"); 

    // 30: 0036d693 srli x13,x13,0x3
    #clk_tk
    if (dut.regs.mem[13]==2) $display("test 12 passed"); else $display("test 12 FAILED"); 

    // 34: fff6c693 xori x13,x13,-1
    #clk_tk
    if (dut.regs.mem[13]==-3) $display("test 13 passed"); else $display("test 13 FAILED"); 
    
    // 38: 4016d693 srai x13,x13,0x1
    #clk_tk
    if (dut.regs.mem[13]==-2) $display("test 14 passed"); else $display("test 14 FAILED"); 

    // 3c: 00c68733 add x14,x13,x12
    #clk_tk
    if (dut.regs.mem[14]==-1) $display("test 15 passed"); else $display("test 15 FAILED"); 

    // 40: 40c70733 sub x14,x14,x12
    #clk_tk
    if (dut.regs.mem[14]==-2) $display("test 16 passed"); else $display("test 16 FAILED"); 
    
    // 44: 00c617b3 sll x15,x12,x12
    #clk_tk
    if (dut.regs.mem[15]==2) $display("test 17 passed"); else $display("test 17 FAILED"); 

    // 48: 00f62833 slt x16,x12,x15
    #clk_tk
    if (dut.regs.mem[16]==1) $display("test 18 passed"); else $display("test 18 FAILED"); 
    
    // 4c: 00c62833 slt x16,x12,x12
    #clk_tk
    if (dut.regs.mem[16]==0) $display("test 19 passed"); else $display("test 19 FAILED"); 

    // 50: 00d83833 sltu x16,x16,x13
    #clk_tk
    if (dut.regs.mem[16]==1) $display("test 20 passed"); else $display("test 20 FAILED"); 

    // 54: 00d84833 xor x17,x16,x13
    #clk_tk
    if (dut.regs.mem[17]==-1) $display("test 21 passed"); else $display("test 21 FAILED"); 

    // 58: 0105d933 srl x18,x11,x16
    #clk_tk
    if (dut.regs.mem[18]==1) $display("test 22 passed"); else $display("test 22 FAILED"); 

    // 5c: 4108d933 sra x18,x17,x16
    #clk_tk
    if (dut.regs.mem[18]==-1) $display("test 23 passed"); else $display("test 23 FAILED"); 

    // 60: 00b869b3 or x19,x16,x11
    #clk_tk
    if (dut.regs.mem[19]==3) $display("test 24 passed"); else $display("test 24 FAILED"); 

    // 64: 0109f9b3 and x19,x19,x16
    #clk_tk
    if (dut.regs.mem[19]==1) $display("test 25 passed"); else $display("test 25 FAILED"); 

    $finish;
end

endmodule
