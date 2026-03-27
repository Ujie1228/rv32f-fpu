module fcsr (
    input  logic        clk,
    input  logic        rst_n,

    input  logic [4:0]  flags,
    input  logic        flags_wr,
    input  logic [31:0] csr_wdata,
    input  logic        csr_wr,
    
    output logic [2:0]  frm_out,
    output logic [31:0] fcsr_data_o
);
  timeunit 1ns; timeprecision 1ps;

  logic [2:0] frm_reg;
  logic [4:0] fflags_reg;

  assign fcsr_data = {24'h000000, frm_reg, fflags_reg};
  assign frm_out = frm_reg;
  assign fcsr_data_o = fcsr_data;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      frm_reg    <= 3'b000;
      fflags_reg <= 5'b00000;
    end else begin
      if (csr_wr) begin
        frm_reg    <= csr_wdata[7:5];
        fflags_reg <= csr_wdata[4:0];
      end else if (flags_wr) begin
        fflags_reg <= (fflags_reg | flags); 
      end
    end
  end

    
endmodule