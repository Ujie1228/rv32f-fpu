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
    input logic req_ready_i,  // op选择之后的ready
    input logic misc_ready_i,
    input logic cvt_ready_i,
    input logic fma_ready_i,
    input logic div_ready_i,
    input logic div_busy_i,

    input logic misc_stall_i,
    input logic div_stall_i,
    input logic cvt_stall_i,
    input logic fma_stall_i,

    output fpu_fma_in_type  req_data_FMA_reg_o,
    output fpu_div_in_type  req_data_DIV_reg_o,
    output fpu_cvt_in_type  req_data_CVT_reg_o,
    output fpu_misc_in_type req_data_MISC_reg_o,

    output logic misc_start_o,
    output logic div_start_o,
    output logic cvt_start_o,
    output logic fma_start_o,

    input logic resp_ready_i,
    input fpu_misc_out_type resp_misc_reg_i,
    input fpu_div_reg_out   resp_div_reg_i,
    input fpu_cvt_out_type  resp_cvt_reg_i,
    input fpu_fma_reg_out   resp_fma_reg_i,

    input logic  misc_data_vld_i,
    input logic  div_data_vld_i,
    input logic  cvt_data_vld_i,
    input logic  fma_data_vld_i,

    output logic misc_reg_empty_o,
    output logic div_reg_empty_o,
    output logic cvt_reg_empty_o,
    output logic fma_reg_empty_o,

    output logic [31:0] resp_result_o,
    output logic [4:0]  resp_flags_o,
    output logic [4:0]  resp_tag_o
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
    assign req_data_MISC.rm = req_rm_i;
    assign req_data_MISC.class1 = class1_i;
    assign req_data_MISC.class2 = class2_i;
    assign req_data_MISC.tag = req_tag_i;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (~rst_ni) begin
            req_data_MISC_reg_o <= '0;
            misc_start_o <= '0;
        end else if (misc_stall_i) begin
            misc_start_o <= misc_start_o;
        end else if (req_valid_i & misc_ready_i & (op_class_i ==MISC)) begin
            req_data_MISC_reg_o <= req_data_MISC;
            misc_start_o <= 1'b1;
        end else begin
            misc_start_o <= 1'b0;
        end
    end

    // CVT
    assign req_data_CVT.data = data1_i;
    assign req_data_CVT.extend = extend1_i;
    assign req_data_CVT.op = req_op_i;
    assign req_data_CVT.rm = req_rm_i;
    assign req_data_CVT.classification = class1_i;
    assign req_data_CVT.tag = req_tag_i;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (~rst_ni) begin
            req_data_CVT_reg_o <= '0;
            cvt_start_o <= '0;
        end else if (cvt_stall_i) begin
            cvt_start_o <= cvt_start_o;
        end else if (req_valid_i & cvt_ready_i & (op_class_i ==CVT)) begin
            req_data_CVT_reg_o <= req_data_CVT;
            cvt_start_o <= 1'b1;
        end else begin
            cvt_start_o <= 1'b0;
        end
    end
    
    // FMA
    assign req_data_FMA.extend1 = extend1_i;
    assign req_data_FMA.extend2 = extend2_i;
    assign req_data_FMA.extend3 = extend3_i;
    assign req_data_FMA.class1 = class1_i;
    assign req_data_FMA.class2 = class2_i;
    assign req_data_FMA.class3 = class3_i;
    assign req_data_FMA.op = req_op_i;
    assign req_data_FMA.rm = req_rm_i;
    assign req_data_FMA.tag = req_tag_i;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (~rst_ni) begin
            req_data_FMA_reg_o <= '0;
            fma_start_o <= '0;
        end else if (fma_stall_i) begin
            fma_start_o <= fma_start_o;
        end else if (req_valid_i & fma_ready_i & (op_class_i ==FMA)) begin
            req_data_FMA_reg_o <= req_data_FMA;
            fma_start_o <= 1'b1;
        end else begin
            fma_start_o <= 1'b0;
        end
    end

    // DIV
    assign req_data_DIV.extend1 = extend1_i;
    assign req_data_DIV.extend2 = extend2_i;
    assign req_data_DIV.class1 = class1_i;
    assign req_data_DIV.class2 = class2_i;
    assign req_data_DIV.op = req_op_i;
    assign req_data_DIV.rm = req_rm_i;
    assign req_data_DIV.tag = req_tag_i;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (~rst_ni) begin
            req_data_DIV_reg_o <= '0;
            div_start_o <= '0;
        end else if (div_stall_i) begin
            div_start_o <= div_start_o;
        end else if (req_valid_i & div_ready_i & (op_class_i ==DIV)) begin
            req_data_DIV_reg_o <= req_data_DIV;
            div_start_o <= 1'b1;
        end else begin
            div_start_o <= 1'b0;
        end
    end

    // 输出控制 & empty 设置优先级

    always_comb begin
        misc_reg_empty_o = 1'b1; //默认值
        div_reg_empty_o = 1'b1;
        cvt_reg_empty_o = 1'b1;
        fma_reg_empty_o = 1'b1;
        if (resp_ready_i) begin
            if (misc_data_vld_i) begin
                misc_reg_empty_o = 1'b1;
            end else if (div_data_vld_i) begin
                div_reg_empty_o = 1'b1;
            end else if (cvt_data_vld_i) begin
                cvt_reg_empty_o = 1'b1;
            end else if (fma_data_vld_i) begin
                fma_reg_empty_o = 1'b1;
            end
        end else if (~resp_ready_i) begin
            if (misc_data_vld_i) begin
                misc_reg_empty_o = 1'b0;
            end
            if (div_data_vld_i) begin
                div_reg_empty_o = 1'b0;
            end
            if (cvt_data_vld_i) begin
                cvt_reg_empty_o = 1'b0;
            end
            if (fma_data_vld_i) begin
                fma_reg_empty_o = 1'b0;    
            end
        end
    end

    // 优先级
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (~rst_ni) begin
            result_o <= 0;
        end else if (misc_data_vld_i & resp_ready_i) begin
            resp_result_o <= resp_misc_reg_i.result;
            resp_flags_o <= resp_misc_reg_i.flags;
            resp_tag_o <= resp_misc_reg_i.tag;
        end else if (div_data_vld_i & resp_ready_i) begin
            resp_result_o <= resp_div_reg_i.result;
            resp_flags_o <= resp_div_reg_i.flags;
            resp_tag_o <= resp_div_reg_i.tag;
        end else if (cvt_data_vld_i & resp_ready_i) begin
            resp_result_o <= resp_cvt_reg_i.result;
            resp_flags_o <= resp_cvt_reg_i.flags;
            resp_tag_o <= resp_cvt_reg_i.tag;
        end else if (fma_data_vld_i & resp_ready_i) begin
            resp_result_o <= resp_fma_reg_i.result;
            resp_flags_o <= resp_fma_reg_i.flags;
            resp_tag_o <= resp_fma_reg_i.tag;
        end
    end

endmodule