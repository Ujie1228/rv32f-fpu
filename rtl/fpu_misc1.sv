import fpu_define::*;

module fpu_misc(
    input logic clk_i,
    input logic rst_ni,
    input logic misc_stall_i,
    input logic misc_start_i,
    input  fpu_misc_in_type  misc_i,

    output fpu_misc_out_type misc_o,
    output logic misc_ready_o,
    output logic misc_data_vld_o
);

endmodule// outports wire

