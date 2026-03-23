import fpu_wire::*;

module fpu_class (
    input  fpu_class_in_type   class_i,
    output fpu_class_out_type  class_o,
    input  lzc_32_out_type     lzc_o,
    output lzc_32_in_type      lzc_i
);
  timeunit 1ns; timeprecision 1ps;

endmodule