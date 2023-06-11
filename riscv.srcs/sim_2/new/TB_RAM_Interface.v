`timescale 1ns / 1ps
`default_nettype none
`define DBG

module TB_RAM_Interface;


localparam clk_tk = 10;
reg clk = 0;
always #(clk_tk/2) clk = ~clk;

reg enaA = 1;
reg [1:0] weA = 0;
reg [20-1:0] addrA = 0;
reg [31:0] dinA = 0;
wire [31:0] doutA;

RAM_Interface #(
    .ADDR_WIDTH(18), // 2**18 = RAM depth in words
    .DATA_WIDTH(32)
) dut (
    .clkA(clk),
    .enaA(enaA),
    .weA(weA), // b01 - byte, b10 - half word, b11 - word
    .addrA(addrA), // bytes addressable
    .dinA(dinA),
    .doutA(doutA)
);

initial begin
    // write bytes
    weA = 1;
    dinA = 8'h12;    
    addrA = 0;
    #clk_tk

    dinA = 8'h34;    
    addrA = 1;
    #clk_tk

    dinA = 8'h56;    
    addrA = 2;
    #clk_tk
    
    dinA = 8'h78;    
    addrA = 3;
    #clk_tk

    if (dut.ram.ram_block[0]==32'h78563412) $display("test 1 passed"); else $display("test 1 FAILED");

    // read word        
    weA = 0;
    addrA = 0;
    #clk_tk

    if (doutA==32'h78563412) $display("test 2 passed"); else $display("test 2 FAILED");

    // write half words
    weA = 2;
    dinA = 16'h1234;    
    addrA = 4;
    #clk_tk

    dinA = 16'h5678;    
    addrA = 6;
    #clk_tk
    
//    $display("%h",dut.ram.ram_block[1]);
    if (dut.ram.ram_block[1]==32'h56781234) $display("test 3 passed"); else $display("test 3 FAILED");

    // read word
    weA = 0;
    addrA = 4;
    #clk_tk

    if (doutA==32'h56781234) $display("test 4 passed"); else $display("test 4 FAILED");
    
    $finish;
end

endmodule
