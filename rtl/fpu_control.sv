import fpu_define::*;

module fpu_control (
    input  logic        clk_i,
    input  logic        rst_ni,
    input fpu_fma_out_type  data_FMA_reg_i,
    input fpu_div_out_type  data_DIV_reg_i,
    input fpu_cvt_out_type  data_CVT_reg_i,
    input fpu_misc_out_type data_MISC_reg_i,
    
    output logic        req_ready_o,
    output logic        resp_valid_o,
    output logic [31:0] resp_result_o,
    output logic [4:0] resp_flags_o,
    output logic [4:0]  resp_tag_o
);





endmodule