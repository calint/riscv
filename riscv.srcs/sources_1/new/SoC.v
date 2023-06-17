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
reg [31:0] pc_nxt; // next value of program counter
wire [31:0] ir; // instruction register
wire [6:0] opcode = ir[6:0];
wire [4:0] rd = ir[11:7];
wire [2:0] funct3 = ir[14:12];
wire [4:0] rs1 = ir[19:15];
wire [4:0] rs2 = ir[24:20];
wire [6:0] funct7 = ir[31:25];
wire signed [31:0] I_imm12 = {{20{ir[31]}}, ir[31:20]};
wire [31:0] U_imm20 = {ir[31:12], {12{1'b0}}};
wire signed [31:0] S_imm12 = {{20{ir[31]}}, ir[31:25], ir[11:7]};
wire signed [31:0] B_imm12 = {{20{ir[31]}}, ir[31], ir[7], ir[30:25], ir[11:8], 1'b0};
wire signed [31:0] J_imm20 = {{20{ir[31]}}, ir[31], ir[19:12], ir[20], ir[30:21], 1'b0};

reg [31:0] regs_rd_wd; // data to be written to register 'rd' if 'regs_rd_we' is enabled
reg regs_rd_we;
wire signed [31:0] regs_rd1; // register value of 'rs1'
wire signed [31:0] regs_rd2; // register value of 'rs2'
reg [1:0] ram_weA;
reg [2:0] ram_reA;
reg [31:0] ram_addrA;
reg [31:0] ram_dinA;
wire [31:0] ram_doutA;

reg is_ld; // previous instruction was 'ld'
reg [4:0] ld_rd; // previous instruction 'rd'
reg regs_we3; // enabled when previous instruction was 'ld' to write 'ram_doutA' to register 'ld_rd'

// if last instruction was a load to a register that is used in the instruction 
wire signed [31:0] rs1_dat = regs_we3 && rs1 == ld_rd ? ram_doutA : regs_rd1;
wire signed [31:0] rs2_dat = regs_we3 && rs2 == ld_rd ? ram_doutA : regs_rd2;

//reg signed [31:0] rs1_dat;
//reg signed [31:0] rs2_dat;

reg bubble; // signals that next instruction is a bubble
reg is_bubble; // signals that current innstruction is a bubble

always @* begin
    regs_rd_we = 0;
    regs_rd_wd = 0;
    ram_addrA = 0;
    ram_dinA = 0;
    ram_weA = 0;
    ram_reA = 0;
    is_ld = 0;
    bubble = 0;
    pc_nxt = pc + 4;

//    $display("%0t: ir=%h, pc=%0d, pc_nxt=%0d, is_bubble=%0d rst=%0d, opcode=%0b", $time, ir, pc, pc_nxt, is_bubble, rst, opcode);    

    // note. in iverilog commented code below creates inifinite loop with
    // SoC and RAM_Interface triggering each other without (obvious) signal change
    //rs1_dat = regs_we3 && rs1 == ld_rd ? ram_doutA : regs_rd1;
    //rs2_dat = regs_we3 && rs2 == ld_rd ? ram_doutA : regs_rd2;

    if (!is_bubble) begin
        case (opcode)
        7'b0110111: begin // LUI
            regs_rd_wd = U_imm20;
            regs_rd_we = 1;
//            $display("%0t: ir=%h, LUI %0h", $time, ir, U_imm20);
        end
        7'b0010011: begin // logical ops immediate
            regs_rd_we = 1;
            case (funct3)
            3'b000: begin // ADDI
                regs_rd_wd = rs1_dat + I_imm12;
//                $display("%0t: ir=%h, ADDI x%0d = %0h + %0h", $time, ir, rd, rs1_dat, I_imm12);
            end
            3'b010: begin // SLTI
                regs_rd_wd = rs1_dat < I_imm12 ? 1 : 0;
            end
            3'b011: begin // SLTIU
                regs_rd_wd = $unsigned(rs1_dat) < $unsigned(I_imm12) ? 1 : 0;
            end
            3'b100: begin // XORI
                regs_rd_wd = rs1_dat ^ I_imm12;
            end
            3'b110: begin // ORI
                regs_rd_wd = rs1_dat | I_imm12;
            end
            3'b111: begin // ANDI
                regs_rd_wd = rs1_dat & I_imm12;
            end
            3'b001: begin // SLLI
                regs_rd_wd = rs1_dat << rs2;
            end
            3'b101: begin // SRLI and SRAI
                regs_rd_wd = ir[30] ? rs1_dat >>> rs2 : rs1_dat >> rs2;
            end
            endcase
        end
        7'b0110011: begin // logical ops
            regs_rd_we = 1;
            case (funct3)
            3'b000: begin // ADD and SUB
                regs_rd_wd = ir[30] ? rs1_dat - rs2_dat : rs1_dat + rs2_dat;        
            end
            3'b001: begin // SLL
                regs_rd_wd = rs1_dat << (rs2_dat & 5'b11111);
            end
            3'b010: begin // SLT
                regs_rd_wd = rs1_dat < rs2_dat ? 1 : 0;
            end
            3'b011: begin // SLTU
                regs_rd_wd = $unsigned(rs1_dat) < $unsigned(rs2_dat) ? 1 : 0;
            end
            3'b100: begin // XOR
                regs_rd_wd = rs1_dat ^ rs2_dat;
            end
            3'b101: begin // SRL and SRA
                regs_rd_wd = ir[30] ? rs1_dat >>> (rs2_dat & 5'b11111) : rs1_dat >> (rs2_dat & 5'b11111);
            end
            3'b110: begin // OR
                regs_rd_wd = rs1_dat | rs2_dat;
            end
            3'b111: begin // AND
                regs_rd_wd = rs1_dat & rs2_dat;
            end
            endcase
        end
        7'b0100011: begin // store
            ram_addrA = rs1_dat + S_imm12;
            ram_dinA = rs2_dat;
            case (funct3)
            3'b000: begin // SB
                ram_weA = 2'b01; // write byte
            end
            3'b001: begin // SH
                ram_weA = 2'b10; // write half word
            end
            3'b010: begin // SW
                ram_weA = 2'b11; // write word
            end
            endcase
        end
        7'b0000011: begin // load
            ram_addrA = rs1_dat + I_imm12;
            is_ld = 1;
            case (funct3)
            3'b000: begin // LB
                ram_reA = 3'b101; // read sign extended byte
            end
            3'b001: begin // LH
                ram_reA = 3'b110; // read sign extended half word
            end
            3'b010: begin // LW
                ram_reA = 3'b111; // read word (signed)
            end
            3'b100: begin // LBU
                ram_reA = 3'b001; // read unsigned byte
            end
            3'b101: begin // LHU
                ram_reA = 3'b010; // read unsigned half word
            end
            endcase
        end
        // note. auipc, jumps and branches:
        //       pc is ahead one instruction (+4)
        //       thus -4 when branching
        //       and no +4 to return address
        7'b0010111: begin // AUIPC
            regs_rd_wd = pc + U_imm20 - 4;
            regs_rd_we = 1;
        end
        7'b1101111: begin // JAL
            regs_rd_wd = pc; 
            regs_rd_we = 1;
            pc_nxt = pc + J_imm20 - 4;
            bubble = 1;
//            $display("%0t: ir=%h, opcode=%0b JAL pc_nxt=%0h", $time, ir, opcode, pc_nxt);
        end
        7'b1100111: begin // JALR
            regs_rd_wd = pc;
            regs_rd_we = 1;
            pc_nxt = rs1_dat + I_imm12;
            bubble = 1;
        end
        7'b1100011: begin // branches
            case (funct3)
            3'b000: begin // BEQ
                if (rs1_dat == rs2_dat) begin
                    pc_nxt = pc + B_imm12 - 4;
                    bubble = 1;                    
                end
            end
            3'b001: begin // BNE
                if (rs1_dat != rs2_dat) begin
                    pc_nxt = pc + B_imm12 - 4;
                    bubble = 1;
                end
            end
            3'b100: begin // BLT
                if (rs1_dat < rs2_dat) begin
                    pc_nxt = pc + B_imm12 - 4;
                    bubble = 1;
                end
            end
            3'b101: begin // BGE
                if (rs1_dat >= rs2_dat) begin
                    pc_nxt = pc + B_imm12 - 4;
                    bubble = 1;
                end
            end
            3'b110: begin // BLTU
                if ($unsigned(rs1_dat) < $unsigned(rs2_dat)) begin
                    pc_nxt = pc + B_imm12 - 4;
                    bubble = 1;
                end
            end
            3'b111: begin // BGEU
//                $display("%0t: ir=%h, BGEU %0h >= %0h", $time, ir, rs1_dat, rs2_dat);
                if ($unsigned(rs1_dat) >= $unsigned(rs2_dat)) begin
                    pc_nxt = pc + B_imm12 - 4;
                    bubble = 1;
                end
            end
            endcase
        end
        endcase // case (opcode)
    end
end

always @(posedge clk) begin
    if (rst) begin
        pc <= 0;
        is_bubble <= 0;
    end else begin
//        $display("**********************************************");
//        $display("*** %0t: ir=%0h, pc=%0d, pc_nxt=%0d", $time, ir, pc, pc_nxt);
        regs_we3 <= is_ld ? 1 : 0; // if this is a 'load' from ram enable write to register 'ld_rd' during next instruction (one cycle delay for data ready from ram)
        ld_rd <= rd; // save the destination register for next cycle write
        is_bubble <= bubble; // if instruction generates bubble of next instruction (branch, jumps instructions)
        pc <= pc_nxt;
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
    .ra3(ld_rd), // register to write from ram out (load instructions)
    .wd3(ram_doutA), // data to write to register 'ra3' when 'we3' is enabled
    .we3(regs_we3)
);

RAM_Interface #(
    .ADDR_WIDTH(15), // 2**15 = RAM depth in words
    .DATA_FILE(RAM_FILE)
) ram (
    .rst(rst),
    // port A: data memory, read / write byte addressable ram
    .clk(clk),
    .weA(ram_weA), // b01 - byte, b10 - half word, b11 - word
    .reA(ram_reA), // reA[2] sign extended, b01 - byte, b10 - half word, b11 - word
    .addrA(ram_addrA), // byte addressable
    .dinA(ram_dinA), // data to write depending on 'weA'
    .doutA(ram_doutA), // data out depending on 'reA' one cycle later
    
    // port B: instruction memory, byte addressed, bottom 2 bits ignored, word aligned
    .addrB(pc),
    .doutB(ir),

    .leds({led0_b, led0_g, led0_r, led[3:0]})
);

endmodule

`undef DBG
`default_nettype wire