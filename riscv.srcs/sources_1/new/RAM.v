`timescale 1ns / 1ps
//
`default_nettype none
//`define DBG

// from: https://docs.xilinx.com/r/en-US/ug901-vivado-synthesis/Byte-Write-Enable-True-Dual-Port-with-Byte-Wide-Write-Enable-Verilog

module RAM #(
    parameter NUM_COL = 4,
    parameter COL_WIDTH = 8,
    parameter ADDR_WIDTH = 12,  // 2**12 = RAM depth
    parameter DATA_WIDTH = NUM_COL * COL_WIDTH,  // data width in bits
    parameter DATA_FILE = "RAM.mem"
) (
    input wire clkA,
    input wire enaA,
    input wire [NUM_COL-1:0] weA,
    input wire [ADDR_WIDTH-1:0] addrA,
    input wire [DATA_WIDTH-1:0] dinA,
    output reg [DATA_WIDTH-1:0] doutA,
    input wire clkB,
    input wire enaB,
    input wire [NUM_COL-1:0] weB,
    input wire [ADDR_WIDTH-1:0] addrB,
    input wire [DATA_WIDTH-1:0] dinB,
    output reg [DATA_WIDTH-1:0] doutB
);

  reg [DATA_WIDTH-1:0] ram_block[(2**ADDR_WIDTH)-1:0];

  initial begin
    $readmemh(DATA_FILE, ram_block);
  end

  integer i;

  // Port-A Operation
  always @(posedge clkA) begin
    if (enaA) begin
      for (i = 0; i < NUM_COL; i = i + 1) begin
        if (weA[i]) begin
          ram_block[addrA][i*COL_WIDTH+:COL_WIDTH] <= dinA[i*COL_WIDTH+:COL_WIDTH];
        end
      end
      doutA <= ram_block[addrA];
    end
  end

  // Port-B Operation:
  always @(posedge clkB) begin
    if (enaB) begin
      for (i = 0; i < NUM_COL; i = i + 1) begin
        if (weB[i]) begin
          ram_block[addrB][i*COL_WIDTH+:COL_WIDTH] <= dinB[i*COL_WIDTH+:COL_WIDTH];
        end
      end
      doutB <= ram_block[addrB];
    end
  end

endmodule

`undef DBG
`default_nettype wire
