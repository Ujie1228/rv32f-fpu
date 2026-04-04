import fpu_define::*;

module fpu_control(
    input logic clk_i,
    input logic rst_ni,

    input logic [3:0] op_class_i,
    // req_ready
    input logic misc_ready_i,
    input logic cvt_ready_i,
    input logic fma_ready_i,
    input logic div_ready_i,

    output logic req_ready_o,
    // resp_valid
    input logic misc_data_vld_i,
    input logic cvt_data_vld_i,
    input logic fma_data_vld_i,
    input logic div_data_vld_i,

    output logic resp_valid_o,
    // stall 
    input logic misc_reg_empty_i,
    input logic cvt_reg_empty_i,
    input logic fma_reg_empty_i,
    input logic div_reg_empty_i,
    input logic div_busy_i,

    output logic misc_stall_o,
    output logic cvt_stall_o,
    output logic fma_stall_o,
    output logic div_stall_o
);

    // top.req_ready
    always_comb begin
        req_ready_o = 1'b1;
        case(op_class_i)
            MISC: req_ready_o = misc_ready_i;
            CVT:  req_ready_o = cvt_ready_i;
            FMA:  req_ready_o = fma_ready_i;
            DIV:  req_ready_o = div_ready_i;
        endcase
    end 

    // stall
    assign misc_stall_o = ~misc_reg_empty_i;
    assign cvt_stall_o = ~cvt_reg_empty_i;
    assign fma_stall_o = ~fma_reg_empty_i;
    assign div_stall_o = (~div_reg_empty_i) | div_busy_i;

    // top.resp_valid
    assign resp_valid_o = misc_data_vld_i | cvt_data_vld_i | fma_data_vld_i | div_data_vld_i;

endmodule