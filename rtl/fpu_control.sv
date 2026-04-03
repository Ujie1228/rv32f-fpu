import fpu_define::*;

module fpu_control (
    input  logic        clk_i,
    input  logic        rst_ni,
    input  logic        op_class_i,
    input  logic        req_valid_i,
    input  logic        resp_ready_i,
    input  logic        busy,  
    input  fpu_fma_out_type  data_FMA_reg_i,
    input  fpu_div_out_type  data_DIV_reg_i,
    input  fpu_cvt_out_type  data_CVT_reg_i,
    input  fpu_misc_out_type data_MISC_reg_i,

    output logic        reg_empty_fma_i,
    output logic        reg_empty_div_i,
    output logic        reg_empty_cvt_i,
    output logic        reg_empty_misc_i,
    
    output logic        req_ready_o,
    output logic        resp_valid_o,
    output logic [31:0] resp_result_o,
    output logic [4:0]  resp_flags_o,
    output logic [4:0]  resp_tag_o
);

  logic req_ready_fma;
  logic req_ready_div;
  logic req_ready_cvt;
  logic req_ready_misc;

  always_comb begin

    resp_valid_o = (data_FMA_reg_i.resp_valid_o | data_DIV_reg_i.resp_valid_o | data_CVT_reg_i.resp_valid_o | data_MISC_reg_i.resp_valid_o);
    
    reg_empty_fma_i = ~data_FMA_reg_i.req_valid;
    reg_empty_div_i = ~data_DIV_reg_i.req_valid;
    reg_empty_cvt_i = ~data_CVT_reg_i.req_valid;
    reg_empty_misc_i = ~data_MISC_reg_i.req_valid;

    req_ready_fma = reg_empty_fma_i;
    req_ready_div = reg_empty_div_i;
    req_ready_cvt = reg_empty_cvt_i;
    req_ready_misc = reg_empty_misc_i;

    if (req_valid_i) begin
        if ((op_class_i == FMA) & req_ready_fma) begin
            req_ready_o = 1;
        end else if ((op_class_i == DIV) & req_ready_div & (busy == 0)) begin
            req_ready_o = 1;
        end else if ((op_class_i == CVT) & req_ready_cvt) begin
            req_ready_o = 1;
        end else if ((op_class_i == MISC) & req_ready_misc) begin
            req_ready_o = 1;
        end else begin
            req_ready_o = 0;
        end
    end

  end
  
  always_ff @(posedge clk_i or posedge rst_ni) begin
    if (rst_ni) begin
        resp_result_o <= 0;
        resp_flags_o <= 0;
        resp_tag_o <= 0;
        data_FMA_reg_i.req_valid <= 0;
        data_DIV_reg_i.req_valid <= 0;
        data_CVT_reg_i.req_valid <= 0;
        data_MISC_reg_i.req_valid <= 0;
    end else if ((op_class_i == FMA) & data_FMA_reg_i.resp_valid_o & resp_ready_i) begin
        resp_result_o <= data_FMA_reg_i.result;
        resp_flags_o <= data_FMA_reg_i.flags;
        resp_tag_o <= data_FMA_reg_i.req_tag;
        data_FMA_reg_i.req_valid <= 0;
    end else if ((op_class_i == DIV) & data_DIV_reg_i.resp_valid_o & resp_ready_i) begin
        resp_result_o <= data_DIV_reg_i.result;
        resp_flags_o <= data_DIV_reg_i.flags;
        resp_tag_o <= data_DIV_reg_i.req_tag;
        data_DIV_reg_i.req_valid <= 0;
    end else if ((op_class_i == CVT) & data_CVT_reg_i.resp_valid_o & resp_ready_i) begin
        resp_result_o <= data_CVT_reg_i.result;
        resp_flags_o <= data_CVT_reg_i.flags;
        resp_tag_o <= data_CVT_reg_i.req_tag;
        data_CVT_reg_i.req_valid <= 0;
    end else if ((op_class_i == MISC) & data_MISC_reg_i.resp_valid_o & resp_ready_i) begin
        resp_result_o <= data_MISC_reg_i.result;
        resp_flags_o <= data_MISC_reg_i.flags;
        resp_tag_o <= data_MISC_reg_i.req_tag;
        data_MISC_reg_i.req_valid <= 0;
    end
  end

endmodule