import fpu_wire::*;

module fpu_mac (
    input reset,
    input clock,
    input  fpu_mac_in_type   mac_i,
    output fpu_mac_out_type  mac_o
);
  timeunit 1ns; timeprecision 1ps;

endmodule