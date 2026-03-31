module fprf (
    input  logic        clk,
    input  logic        rst_n,

    input  logic [4:0]  rs1_addr,
    input  logic [4:0]  rs2_addr,
    input  logic [4:0]  rs3_addr,
    input  logic [4:0]  rd_addr,
    input  logic        wr,
    input  logic [31:0] wdata,

    output logic [31:0] rs1_data,
    output logic [31:0] rs2_data,
    output logic [31:0] rs3_data
);
  timeunit 1ns; timeprecision 1ps;

  logic [31:0] registers [0:31];

  assign rs1_data = registers[rs1_addr];
  assign rs2_data = registers[rs2_addr];
  assign rs3_data = registers[rs3_addr];

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      integer i;
      for (i = 0; i < 32; i = i + 1) begin
        registers[i] <= 32'h00000000;
      end
    end else begin
      if (wr) begin
        registers[rd_addr] <= wdata;
      end
    end
  end
    
endmodule