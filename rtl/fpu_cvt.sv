import fp_wire::*;

module fpu_cvt #(
    parameter RISCV = 0
) (
    input  fpu_cvt_f2i_in_type   cvt_f2i_i,
    output fpu_cvt_f2i_out_type  cvt_f2i_o,
    input  fpu_cvt_i2f_in_type   cvt_i2f_i,
    output fpu_cvt_i2f_out_type  cvt_i2f_o,
    input  lzc_32_out_type       lzc_o,
    output lzc_32_in_type        lzc_i
);
  timeunit 1ns; timeprecision 1ps;

  fpu_cvt_f2i_var_type cvt_f2i_v;
  fpu_cvt_i2f_var_type cvt_i2f_v;

  generate
  


  endgenerate


endmodule