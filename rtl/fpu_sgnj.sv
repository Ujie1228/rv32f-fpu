import fpu_define::*;

module fpu_sgnj (
    input  fpu_sgnj_in_type   sgnj_i,
    output fpu_sgnj_out_type  sgnj_o
);
  timeunit 1ns; timeprecision 1ps;

  logic [31:0] data1;
  logic [31:0] data2;
  logic [1:0]  fmt;
  logic [2:0]  rm;
  logic [31:0] result;

  always_comb begin

    data1 = sgnj_i.data1;
    data2 = sgnj_i.data2;
    fmt = sgnj_i.fmt;
    rm = sgnj_i.rm;

    result = 0;

    result[30:0] = data1[30:0];

    case (rm)
      3'b000: result[31] = data2[31];
      3'b001: result[31] = ~data2[31];
      3'b010: result[31] = data1[31] ^ data2[31];
      default: result[31] = 1'b0;
    endcase

    sgnj_o.result = result;

  end

endmodule