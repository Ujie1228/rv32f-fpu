import fpu_wire::*;

module fpu_top (
    input   reset,
    input   clock,
    input   fpu_top_in_type top_i,
    output  fpu_top_out_type top_o,
    input   clear
);
  timeunit 1ns; timeprecision 1ps;

  lzc_32_in_type   lzc1_32_i;
  lzc_32_out_type  lzc1_32_o;
  lzc_32_in_type   lzc2_32_i;
  lzc_32_out_type  lzc2_32_o;
  lzc_32_in_type   lzc3_32_i;
  lzc_32_out_type  lzc3_32_o;
  lzc_32_in_type   lzc4_32_i;
  lzc_32_out_type  lzc4_32_o;

  fpu_class_in_type   class1_i;
  fpu_class_out_type  class1_o;
  fpu_class_in_type   class2_i;
  fpu_class_out_type  class2_o;
  fpu_class_in_type   class3_i;
  fpu_class_out_type  class3_o;

  fpu_cmp_in_type    cmp_i;
  fpu_cmp_out_type   cmp_o;

  fpu_max_in_type    max_i;
  fpu_max_out_type   max_o;

  fpu_sgnj_in_type   sgnj_i;
  fpu_sgnj_out_type  sgnj_o;

  fpu_cvt_f2i_in_type   cvt_f2i_i;
  fpu_cvt_f2i_out_type  cvt_f2i_o;
  fpu_cvt_i2f_in_type   cvt_i2f_i;
  fpu_cvt_i2f_out_type  cvt_i2f_o;

  fpu_fma_in_type    fma_i;
  fpu_fma_out_type   fma_o;

  fpu_mac_in_type    mac_i;
  fpu_mac_out_type   mac_o;

  fpu_div_sqrt_in_type   div_sqrt_i;
  fpu_div_sqrt_out_type  div_sqrt_o;

  fpu_rnd_in_type    rnd_i;
  fpu_rnd_out_type   rnd_o;

  lzc_32 lzc_32_comp_1 (
      .data (lzc1_32_i.data),
      .cnt  (lzc1_32_o.cnt),
      .valid(lzc1_32_o.valid)
  );

  lzc_32 lzc_32_comp_2 (
      .data (lzc2_32_i.data),
      .cnt  (lzc2_32_o.cnt),
      .valid(lzc2_32_o.valid)
  );

  lzc_32 lzc_32_comp_3 (
      .data (lzc3_32_i.data),
      .cnt  (lzc3_32_o.cnt),
      .valid(lzc3_32_o.valid)
  );

  lzc_32 lzc_32_comp_4 (
      .data (lzc4_32_i.data),
      .cnt  (lzc4_32_o.cnt),
      .valid(lzc4_32_o.valid)
  );

  fpu_class fpu_class_comp_1 (
      .class_i(class1_i),
      .class_o(class1_o),
      .lzc_o  (lzc1_32_o),
      .lzc_i  (lzc1_32_i)
  );

  fpu_class fpu_class_comp_2 (
      .class_i(class2_i),
      .class_o(class2_o),
      .lzc_o  (lzc2_32_o),
      .lzc_i  (lzc2_32_i)
  );

  fpu_class fpu_class_comp_3 (
      .class_i(class3_i),
      .class_o(class3_o),
      .lzc_o  (lzc3_32_o),
      .lzc_i  (lzc3_32_i)
  );

  fpu_cmp fpu_cmp_comp (
      .cmp_i(cmp_i),
      .cmp_o(cmp_o)
  );

  fpu_max fpu_max_comp (
      .max_i(max_i),
      .max_o(max_o)
  );

  fpu_sgnj fpu_sgnj_comp (
      .sgnj_i(sgnj_i),
      .sgnj_o(sgnj_o)
  );

  fpu_cvt fpu_cvt_comp (
      .cvt_f2i_i(cvt_f2i_i),
      .cvt_f2i_o(cvt_f2i_o),
      .cvt_i2f_i(cvt_i2f_i),
      .cvt_i2f_o(cvt_i2f_o),
      .lzc_o(lzc4_32_o),
      .lzc_i(lzc4_32_i)
  );

  fpu_fma fpu_fma_comp (

  );

  fpu_mac fpu_mac_comp (
      .reset(reset),
      .clock(clock),
      .mac_i(mac_i),
      .mac_o(mac_o)
  );

  fpu_div_sqrt fpu_div_sqrt_comp (

  );

  fpu_rnd fpu_rnd_comp (
      .rnd_i(rnd_i),
      .rnd_o(rnd_o)
  );


  logic [31:0] data1;
  logic [31:0] data2;
  logic [31:0] data3;
  fp_operation_type op;
  logic [1:0] fmt;
  logic [2:0] rm;

  logic [31:0] result;
  logic [4:0] flags;
  logic ready;

  logic [32:0] ext_data1;
  logic [32:0] ext_data2;
  logic [32:0] ext_data3;

  logic [9:0] class1;
  logic [9:0] class2;
  logic [9:0] class3;

  fpu_rnd_in_type rnd;

  always_comb begin

    if (top_i.enable) begin
      data1 = top_i.data1;
      data2 = top_i.data2;
      data3 = top_i.data3;
      op = top_i.op;
      fmt = top_i.fmt;
      rm = top_i.rm;
    end else begin
      data1 = 0;
      data2 = 0;
      data3 = 0;
      op = 0;
      fmt = 0;
      rm = 0;
    end

    result = 0;
    flags = 0;
    ready = top_i.enable;

    class1_i.data = data1;
    class1_i.fmt = fmt;
    class2_i.data = data2;
    class2_i.fmt = fmt;
    class3_i.data = data3;
    class3_i.fmt = fmt;

    ext_data1 = class1_o.ext_data;
    ext_data2 = class2_o.ext_data;
    ext_data3 = class3_o.ext_data;

    class1 = class1_o.classification;
    class2 = class2_o.classification;
    class3 = class3_o.classification;

    cmp_i.ext_data1 = ext_data1;
    cmp_i.ext_data2 = ext_data2;
    cmp_i.rm = rm;
    cmp_i.class1 = class1;
    cmp_i.class2 = class2;

    max_i.data1 = data1;
    max_i.data2 = data2;
    max_i.ext_data1 = ext_data1;
    max_i.ext_data2 = ext_data2;
    max_i.fmt = fmt;
    max_i.rm = rm;
    max_i.class1 = class1;
    max_i.class2 = class2;

    sgnj_i.data1 = data1;
    sgnj_i.data2 = data2;
    sgnj_i.fmt = fmt;
    sgnj_i.rm = rm;

    cvt_f2i_i.ext_data = ext_data1;
    cvt_f2i_i.op = op;
    cvt_f2i_i.rm = rm;
    cvt_f2i_i.classification = class1;

    cvt_i2f_i.data = data1;
    cvt_i2f_i.op = op;
    cvt_i2f_i.fmt = fmt;
    cvt_i2f_i.rm = rm;

    rnd = init_fpu_rnd_in;

    if (fma_o.ready) begin
      rnd = fpu_fma_o.rnd;
    end else if (div_sqrt_o.ready) begin
      rnd = fpu_fdiv_o.rnd;
    end else if (op.fcvt_i2f) begin
      rnd = fpu_cvt_i2f_o.rnd;
    end

    rnd_i = rnd;

    if (fma_o.ready) begin
      result = rnd_o.result;
      flags  = rnd_o.flags;
      ready  = 1;
    end else if (div_sqrt_o.ready) begin
      result = rnd_o.result;
      flags  = rnd_o.flags;
      ready  = 1;
    end else if (op.fmadd | op.fmsub | op.fnmadd | op.fnmsub | op.fadd | op.fsub | op.fmul) begin
      ready = 0;
    end else if (op.fdiv | op.fsqrt) begin
      ready = 0;
    end else if (op.fclass) begin
      result = {22'h0, class1};
      flags  = 0;
    end else if (op.fcmp) begin
      result = cmp_o.result;
      flags  = cmp_o.flags;
    end else if (op.fmax) begin
      result = max_o.result;
      flags  = max_o.flags;
    end else if (op.fsgnj) begin
      result = sgnj_o.result;
      flags  = 0;
    end else if (op.fcvt_i2f) begin
      result = rnd_o.result;
      flags  = rnd_o.flags;
    end else if (op.fcvt_f2i) begin
      result = cvt_f2i_o.result;
      flags  = cvt_f2i_o.flags;
    end else if (op.fmv_f2i) begin
      result = data1;
      flags  = 0;
    end else if (op.fmv_i2f) begin
      result = data1;
      flags  = 0;
    end

    if (clear == 1) begin
      result = 0;
      flags = 0;
      ready = 0;
    end

    top_o.result = result;
    top_o.flags  = flags;
    top_o.ready  = ready;

  end

endmodule