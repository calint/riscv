`timescale 1ns / 1ps
`default_nettype none
//`define DBG

module SoC #(
    parameter RAM_FILE = "RAM.mem"
)(
    input wire clk,
    input wire rst,
    output wire [3:0] led,
    output wire led0_b,
    output wire led0_g,
    output wire led0_r,
    input wire uart_rx,
    output wire uart_tx,
    input wire btn
);

reg [31:0] pc; // program counter, byte addressed
wire [31:0] ir; // instruction register
wire [6:0] opcode = ir[6:0];
wire [4:0] rd = ir[11:7];
wire [2:0] funct3 = ir[14:12];
wire [4:0] rs1 = ir[19:15];
wire [4:0] rs2 = ir[24:20];
wire [6:0] funct7 = ir[31:25];
wire [11:0] imm12 = ir[31:20];
wire [19:0] upper_imm20 = ir[31:12];
wire [11:0] store_imm12 = {ir[31:25], ir[11:7]};
wire [11:0] branch_imm12 = {ir[31], ir[7], ir[30:25], ir[11:8]};
wire [20:0] jump_imm20 = {ir[31], ir[19:12], ir[20], ir[30:21], 1'b0};

reg [31:0] regs_rd_wd;
reg regs_rd_we;
wire [31:0] regs_rd1;
wire [31:0] regs_rd2;
reg [4:0] regs_ra3;
reg [31:0] regs_wd3;
reg regs_we3;
reg [1:0] ram_weA;
reg [2:0] ram_reA;
reg [31:0] ram_addrA;
reg [31:0] ram_dinA;
wire [31:0] ram_doutA;

assign led = ir[3:0];
assign led0_b = 1;
assign led0_g = ~btn;
assign led0_r = uart_rx;
assign uart_tx = 1;

always @(posedge clk) begin
    if (rst) begin
        pc <= 0;
        regs_rd_we <= 0;
        regs_we3 <= 0;
        ram_weA <= 0;
        ram_reA <= 0;
    end else begin
        pc <= pc + 4;
    end
end

Registers regs (
    .clk(clk),
    .rs1(rs1),
    .rs2(rs2),
    .rd(rd),
    .rd_wd(regs_rd_wd),
    .rd_we(regs_rd_we),
    .rd1(regs_rd1), // value of register 'rs1'
    .rd2(regs_rd2), // value of register 'rs2'
    .ra3(regs_ra3), // register address 3
    .wd3(regs_wd3), // data to write to register 'ra3' when 'we3' is enabled
    .we3(regs_we3)
);

RAM_Interface #(
    .ADDR_WIDTH(16), // 2**16 = RAM depth in words
    .DATA_FILE(RAM_FILE)
) ram (
    // port A: data memory, read / write byte addressable ram
    .clk(clk),
    .weA(ram_weA), // b01 - byte, b10 - half word, b11 - word
    .reA(ram_reA), // reA[2] sign extended, b01 - byte, b10 - half word, b11 - word
    .addrA(ram_addrA), // byte addressable
    .dinA(ram_dinA), // data to write depending on 'weA'
    .doutA(ram_doutA), // data out depending on 'reA' one cycle later
    
    // port B: instruction memory, byte addressed, bottom 2 bits ignored, word aligned
    .addrB(pc),
    .doutB(ir)
);

endmodule

`undef DBG
`default_nettype wire