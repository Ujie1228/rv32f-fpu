import fpu_define::*;
import lzc_define::*;

module fpu_top (
    input   logic            clk_i,
    input   logic            rst_ni,
    input   fpu_top_in_type  top_i,
    output  fpu_top_out_type top_o
);

  //lzc
  lzc_32_in_type  lzc1_32_i;
  lzc_32_out_type lzc1_32_o;
  lzc_32_in_type  lzc2_32_i;
  lzc_32_out_type lzc2_32_o;
  lzc_32_in_type  lzc3_32_i;
  lzc_32_out_type lzc3_32_o;
  lzc_32_in_type  lzc4_32_i;
  lzc_32_out_type lzc4_32_o;
  lzc_128_in_type lzc_128_i;
  lzc_128_out_type lzc_128_o;

  logic busy;

  lzc_32 u1_lzc_32 (
    .data  (lzc1_32_i.data),
    .cnt   (lzc1_32_o.cnt),
    .valid (lzc1_32_o.valid)
  );

  lzc_32 u2_lzc_32 (
    .data  (lzc2_32_i.data),
    .cnt   (lzc2_32_o.cnt),
    .valid (lzc2_32_o.valid)
  );

  lzc_32 u3_lzc_32 (
    .data  (lzc3_32_i.data),
    .cnt   (lzc3_32_o.cnt),
    .valid (lzc3_32_o.valid)
  );

  lzc_32 u4_lzc_32 (
    .data  (lzc4_32_i.data),
    .cnt   (lzc4_32_o.cnt),
    .valid (lzc4_32_o.valid)
  );

  lzc_128 u_lzc_128 (
    .data  (lzc_128_i.data),
    .cnt   (lzc_128_o.cnt),
    .valid (lzc_128_o.valid)
  );

  // extend
  logic [32:0] extend1;
  logic [32:0] extend2;
  logic [32:0] extend3;

  logic [9:0] class1;
  logic [9:0] class2;
  logic [9:0] class3;

  fpu_ext u1_fpu_ext (
    .data_i   (top_i.req_data1_i),
    .extend_o (extend1),
    .class_o  (class1),
    .lzc_o    (lzc1_32_o),
    .lzc_i    (lzc1_32_i)
  );
  
  fpu_ext u2_fpu_ext (
    .data_i   (top_i.req_data2_i),
    .extend_o (extend2),
    .class_o  (class2),
    .lzc_o    (lzc2_32_o),
    .lzc_i    (lzc2_32_i)
  );

  fpu_ext u3_fpu_ext (
    .data_i   (top_i.req_data2_i),
    .extend_o (extend3),
    .class_o  (class3),
    .lzc_o    (lzc3_32_o),
    .lzc_i    (lzc3_32_i)
  );  

  // op_class
  logic [3:0] op_class;
  fpu_operation_type op;

  assign op = top_i.req_op_i;

  always_comb begin
      op_class = MISC;
    if (op.fmadd | op.fmsub | op.fnmadd | op.fnmsub | op.fadd | op.fsub | op.fmul) begin
      op_class = FMA;
    end else if (op.fdiv | op.fsqrt) begin
      op_class = DIV;
    end else if (op.fcvt_i2f | op.fcvt_f2i) begin
      op_class = CVT;
    end else if (op.fsgnj | op.fcmp | op.fmax | op.fclass) begin
      op_class = MISC;
    end
  end


  //reg
  fpu_fma_in_type  req_data_FMA_reg;
  fpu_div_in_type  req_data_DIV_reg;
  fpu_cvt_in_type  req_data_CVT_reg;
  fpu_misc_in_type req_data_MISC_reg;

  fpu_fma_out_type  data_FMA_reg_o;
  fpu_div_out_type  data_DIV_reg_o;
  fpu_cvt_out_type  data_CVT_reg_o;
  fpu_misc_out_type data_MISC_reg_o;

  //empty
  logic reg_empty_fma;
  logic reg_empty_div;
  logic reg_empty_cvt;
  logic reg_empty_misc;

  //exe
  fpu_exe u_fpu_exe (
    .clk_i     (clk_i),
    .rst_ni    (rst_ni),
    .data1_i   (top_i.req_data1_i),
    .data2_i   (top_i.req_data2_i),
    .data3_i   (top_i.req_data3_i),
    .extend1_i (extend1),
    .extend2_i (extend2),
    .extend3_i (extend3),
    .class1_i  (class1),
    .class2_i  (class2),
    .class3_i  (class3),

    .req_op_i    (top_i.req_op_i),
    .op_class_i  (op_class),
    .req_valid_i (top_i.req_valid_i),
    .req_rm_i    (top_i.req_rm_i),
    .req_tag_i   (top_i.req_tag_i),
    .req_ready_i (top_o.req_ready_o),

    .data_FMA_reg_o  (req_data_FMA_reg),
    .data_DIV_reg_o  (req_data_DIV_reg),
    .data_CVT_reg_o  (req_data_CVT_reg),
    .data_MISC_reg_o (req_data_MISC_reg)
  );

  //fma
  fpu_fma u_fpu_fma (
    .clk_i     (clk_i),
    .rst_ni    (rst_ni),
    .reg_empty (reg_empty_fma),
    .fma_i     (data_FMA_reg_i),
    .fma_o     (data_FMA_reg_o),
    .lzc_o     (lzc_128_o),
    .lzc_i     (lzc_128_i)
  );

  //div
  fpu_div u_fpu_div (
    .clk_i(clk_i),
    .rst_ni(rst_ni),
    .reg_empty(reg_empty_div),
    .div_i(data_DIV_reg_i),
    .div_o(data_DIV_reg_o)
  );

  //cvt
  fpu_cvt u_fpu_cvt (
    .clk_i     (clk_i),
    .rst_ni    (rst_ni),
    .reg_empty (reg_empty_cvt),
    .cvt_i     (data_CVT_reg_i),
    .cvt_o     (data_CVT_reg_o),
    .lzc_o     (lzc4_32_o),
    .lzc_i     (lzc4_32_i)
  );

  // //misc
  // fpu_misc u_fpu_misc (
  //   .clk_i     (clk_i),
  //   .rst_ni    (rst_ni),
  //   .reg_empty (reg_empty_misc),
  //   .misc_i    (data_MISC_reg_i),
  //   .misc_o    (data_MISC_reg_o)
  // );

  //control
  fpu_control u_fpu_control (
    .clk_i           (clk_i),
    .rst_ni          (rst_ni),
    .op_class_i      (op_class),
    .req_valid_i     (top_i.req_valid_i),
    .resp_ready_i    (top_i.resp_ready_i),
    .busy            (busy),
    .data_FMA_reg_i  (data_FMA_reg_o),
    .data_DIV_reg_i  (data_DIV_reg_o),
    .data_CVT_reg_i  (data_CVT_reg_o),
    .data_MISC_reg_i (data_MISC_reg_o),

    .reg_empty_fma_i  (reg_empty_fma),
    .reg_empty_div_i  (reg_empty_div),
    .reg_empty_cvt_i  (reg_empty_cvt),
    .reg_empty_misc_i (reg_empty_misc),
    
    .req_ready_o   (top_o.req_ready_o),
    .resp_valid_o  (top_o.resp_valid_o),
    .resp_result_o (top_o.resp_result_o),
    .resp_flags_o  (top_o.resp_flags_o),
    .resp_tag_o    (top_o.resp_tag_o)
  );

  //busy

  always_ff @(posedge clk_i or posedge rst_ni) begin
    if (rst_ni) begin
      busy <= 0;
    end else if (top_i.req_valid_i & top_o.req_ready_o & (op_class == DIV)) begin
      busy <= 1;
    end else if ((op_class == DIV) & data_DIV_reg_o.resp_valid_o & top_i.resp_ready_i) begin
      busy <= 0;
    end
  end

endmodule