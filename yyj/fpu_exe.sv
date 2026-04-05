import fpu_define::*;

module fpu_exe(
    input logic clk_i,
    input logic rst_ni,

    input logic [31:0] data1_i,
    input logic [31:0] data2_i,
    input logic [31:0] data3_i,
    input logic [32:0] extend1_i,
    input logic [32:0] extend2_i,
    input logic [32:0] extend3_i,
    input logic [32:0] class1_i,
    input logic [32:0] class2_i,
    input logic [32:0] class3_i,
    input fpu_operation_type req_op_i,
    input logic [3:0] op_class_i,
    input logic [2:0] req_rm_i,
    input logic [4:0] req_tag_i,

    input logic req_valid_i,
    // 用这个也行req_ready_o
    input logic misc_ready_i,
    input logic cvt_ready_i,
    input logic fma_ready_i,
    input logic div_ready_i,

    output fpu_fma_in_type  req_data_FMA_reg_o,
    output fpu_div_in_type  req_data_DIV_reg_o,
    output fpu_cvt_in_type  req_data_CVT_reg_o,
    output fpu_misc_in_type req_data_MISC_reg_o,

    output logic misc_start_o

);

    // 输入寄存器控制
    fpu_fma_in_type  req_data_FMA;
    fpu_div_in_type  req_data_DIV;
    fpu_cvt_in_type  req_data_CVT;
    fpu_misc_in_type req_data_MISC;

    // MISC
    assign req_data_MISC.data1 = data1_i;
    assign req_data_MISC.data2 = data2_i;
    assign req_data_MISC.extend1 = extend1_i;
    assign req_data_MISC.extend2 = extend2_i;
    assign req_data_MISC.op = req_op_i;
    assign req_data_MISC.rm = req_op_i;
    assign req_data_MISC.class1 = class1_i;
    assign req_data_MISC.class2 = class2_i;
    assign req_data_MISC._tag = req_tag_i;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (~rst_ni) begin
            req_data_MISC_reg_o <= '0;
            misc_start_o <= '0;
        end else if (req_valid_i & misc_ready_i) begin
            req_data_MISC_reg_o <= req_data_MISC;
            misc_start_o <= 1'b1;
        end else begin
            misc_start_o <= 1'b0;
        end
    end

    // CVT

    // FMA

    // DIV


endmodule