import fpu_define::*;

module fpu_exe (
    input  logic        clk_i,
    input  logic        rst_ni,
    input  logic [31:0] data1_i,
    input  logic [31:0] data2_i,
    input  logic [31:0] data3_i,
    input  logic [32:0] extend1_i,
    input  logic [32:0] extend2_i,
    input  logic [32:0] extend3_i,
    input  logic [32:0] class1_i,
    input  logic [32:0] class2_i,
    input  logic [32:0] class3_i,

    input fpu_operation_type req_op_i,
    input  logic [3:0]  op_class_i,
    input  logic        req_valid_i,
    input  logic [2:0]  req_rm_i,
    input  logic [4:0]  req_tag_i,
    input  logic        req_ready_i,

    output fpu_fma_in_type  data_FMA_reg_o,
    output fpu_div_in_type  data_DIV_reg_o,
    output fpu_cvt_in_type  data_CVT_reg_o,
    output fpu_misc_in_type data_MISC_reg_o
);
  
  fpu_fma_in_type  data_FMA_reg_i;
  fpu_div_in_type  data_DIV_reg_i;
  fpu_cvt_in_type  data_CVT_reg_i;
  fpu_misc_in_type data_MISC_reg_i;

  always_comb begin
    
    data_FMA_reg_i.extend1 = extend1_i;
    data_FMA_reg_i.extend2 = extend2_i;
    data_FMA_reg_i.extend3 = extend3_i;
    data_FMA_reg_i.class1 = class1_i;
    data_FMA_reg_i.class2 = class2_i;
    data_FMA_reg_i.class3 = class3_i;
    data_FMA_reg_i.op = req_op_i;
    data_FMA_reg_i.rm = req_rm_i;
    data_FMA_reg_i.req_valid = req_valid_i;
    data_FMA_reg_i.req_tag = req_tag_i;

    data_DIV_reg_i.extend1 = extend1_i;
    data_DIV_reg_i.extend2 = extend2_i;
    data_DIV_reg_i.class1 = class1_i;
    data_DIV_reg_i.class2 = class2_i;
    data_DIV_reg_i.op = req_op_i;
    data_DIV_reg_i.rm = req_rm_i;
    data_DIV_reg_i.req_valid = req_valid_i;
    data_DIV_reg_i.req_tag = req_tag_i;

    data_CVT_reg_i.data = data1_i;
    data_CVT_reg_i.extend = extend1_i;
    data_CVT_reg_i.op = req_op_i;
    data_CVT_reg_i.rm = req_rm_i;
    data_CVT_reg_i.classification = class1_i;
    data_CVT_reg_i.req_valid = req_valid_i;
    data_CVT_reg_i.req_tag = req_tag_i;

    data_MISC_reg_i.data1 = data1_i;
    data_MISC_reg_i.data2 = data2_i;
    data_MISC_reg_i.extend1 = extend1_i;
    data_MISC_reg_i.extend2 = extend2_i;
    data_MISC_reg_i.op = req_op_i;
    data_MISC_reg_i.rm = req_rm_i;
    data_MISC_reg_i.class1 = class1_i;
    data_MISC_reg_i.class2 = class2_i;
    data_MISC_reg_i.req_valid = req_valid_i;
    data_MISC_reg_i.req_tag = req_tag_i;

  end

  always_ff @(posedge clk_i or posedge rst_ni) begin
    if (rst_ni) begin
        data_FMA_reg_o <= 0;
        data_DIV_reg_o <= 0;
        data_CVT_reg_o <= 0;
        data_MISC_reg_o <= 0;
    end else begin
        if (req_valid_i & req_ready_i) begin
            if (op_class_i == FMA) begin
                data_FMA_reg_o <= data_FMA_reg_i;
                data_DIV_reg_o <= 0;
                data_CVT_reg_o <= 0;
                data_MISC_reg_o <= 0;
            end else if (op_class_i == DIV) begin
                data_FMA_reg_o <= 0;
                data_DIV_reg_o <= data_DIV_reg_i;
                data_CVT_reg_o <= 0;
                data_MISC_reg_o <= 0;
            end else if (op_class_i == CVT) begin
                data_FMA_reg_o <= 0;
                data_DIV_reg_o <= 0;
                data_CVT_reg_o <= data_CVT_reg_i;
                data_MISC_reg_o <= 0;
            end else if (op_class_i == MISC) begin
                data_FMA_reg_o <= 0;
                data_DIV_reg_o <= 0;
                data_CVT_reg_o <= 0;
                data_MISC_reg_o <= data_MISC_reg_i;
            end
        end
    end

  end



endmodule