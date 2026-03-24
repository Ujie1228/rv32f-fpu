import fpu_wire::*;

module fpu_cvt (
    input  fpu_cvt_f2i_in_type   cvt_f2i_i,
    output fpu_cvt_f2i_out_type  cvt_f2i_o,
    input  fpu_cvt_i2f_in_type   cvt_i2f_i,
    output fpu_cvt_i2f_out_type  cvt_i2f_o,
    input  lzc_32_out_type       lzc_o,
    output lzc_32_in_type        lzc_i
);
  timeunit 1ns; timeprecision 1ps;

  fpu_cvt_f2i_var_type f2i_v;
  fpu_cvt_i2f_var_type i2f_v;
  
  always_comb begin

    f2i_v.ext_data = cvt_f2i_i.ext_data;
    f2i_v.op = cvt_f2i_i.op.fcvt_op;
    f2i_v.rm = cvt_f2i_i.rm;
    f2i_v.classification = cvt_f2i_i.classification;

    f2i_v.flags = 0;
    f2i_v.result = 0;

    f2i_v.snan = f2i_v.classification[8];
    f2i_v.qnan = f2i_v.classification[9];
    f2i_v.infs = f2i_v.classification[0] | f2i_v.classification[7];
    f2i_v.zero = 0;

    if (f2i_v.op == 0) begin
      f2i_v.exponent_bias = 34;  //有符号
    end else begin
      f2i_v.exponent_bias = 35;  //无符号
    end

    f2i_v.sign_cvt = f2i_v.ext_data[32];
    f2i_v.exponent_cvt = f2i_v.ext_data[31:23] - 10'd252;
    f2i_v.mantissa_cvt = {36'h1, f2i_v.ext_data[22:0]};

    if (f2i_v.classification[3] | f2i_v.classification[4]) begin  //+0 -0
      f2i_v.mantissa_cvt[23] = 0;
    end

    f2i_v.oor = 0;  //溢出标志
    if ($signed(f2i_v.exponent_cvt) > $signed(f2i_v.exponent_bias)) begin
      f2i_v.oor = 1;
    end else if ($signed(f2i_v.exponent_cvt) > 0) begin
      f2i_v.mantissa_cvt = f2i_v.mantissa_cvt << f2i_v.exponent_cvt;
    end

    f2i_v.mantissa_uint = f2i_v.mantissa_cvt[58:26];  //有效整数部分

    f2i_v.grs = {f2i_v.mantissa_cvt[25:24], |f2i_v.mantissa_cvt[23:0]};
    f2i_v.odd = f2i_v.mantissa_uint[0] | |f2i_v.grs[1:0];

    f2i_v.flags[0] = |f2i_v.grs;

    f2i_v.rnded = 0;  //进位标志
    if (f2i_v.rm == 0) begin           //RNE
      if (f2i_v.grs[2] & f2i_v.odd) begin
        f2i_v.rnded = 1;
      end
    end else if (f2i_v.rm == 1) begin  //RTZ
      f2i_v.rnded = 0;
    end else if (f2i_v.rm == 2) begin  //RDN
      if (f2i_v.sign_cvt & f2i_v.flags[0]) begin
        f2i_v.rnded = 1;
      end
    end else if (f2i_v.rm == 3) begin  //RUP
      if (~f2i_v.sign_cvt & f2i_v.flags[0]) begin
        f2i_v.rnded = 1;
      end
    end else if (f2i_v.rm == 4) begin  //RMM
      if (f2i_v.grs[2] & f2i_v.flags[0]) begin
        f2i_v.rnded = 1;
      end
    end

    f2i_v.mantissa_uint = f2i_v.mantissa_uint + {32'h0, f2i_v.rnded};

    f2i_v.or_1 = f2i_v.mantissa_uint[32];
    f2i_v.or_2 = f2i_v.mantissa_uint[31];
    f2i_v.or_3 = |f2i_v.mantissa_uint[30:0];

    f2i_v.zero = ~(f2i_v.or_1 | f2i_v.or_2 | f2i_v.or_3);

    f2i_v.oor_32u = f2i_v.or_1;  //无符号整数溢出标志
    f2i_v.oor_32s = f2i_v.or_1;  //有符号整数溢出标志

    if (f2i_v.sign_cvt) begin
      if (f2i_v.op == 0) begin
        f2i_v.oor_32s = f2i_v.oor_32s | (f2i_v.or_2 & f2i_v.or_3);
      end else if (f2i_v.op == 1) begin
        f2i_v.oor = f2i_v.oor | f2i_v.zero;
      end
    end else begin
      f2i_v.oor_32s = f2i_v.oor_32s | f2i_v.or_2;
    end

    f2i_v.oor_32u = (f2i_v.op == 1) & (f2i_v.oor_32u | f2i_v.oor | f2i_v.infs | f2i_v.snan | f2i_v.qnan);
    f2i_v.oor_32s = (f2i_v.op == 0) & (f2i_v.oor_32s | f2i_v.oor | f2i_v.infs | f2i_v.snan | f2i_v.qnan);

    if (f2i_v.sign_cvt) begin
      f2i_v.mantissa_uint = -f2i_v.mantissa_uint;
    end

    if (v_f2i.op == 0) begin
      v_f2i.result = v_f2i.mantissa_uint[31:0];
      if (v_f2i.oor_32s) begin
        v_f2i.result = 32'h7FFFFFFF;
        v_f2i.flags  = 5'b10000;
        if (v_f2i.sign_cvt) begin
          if (~(v_f2i.snan | v_f2i.qnan)) begin
            v_f2i.result = 32'h80000000;
          end
        end
      end
    end else if (v_f2i.op == 1) begin
      v_f2i.result = v_f2i.mantissa_uint[31:0];
      if (v_f2i.oor_32u) begin
        v_f2i.result = 32'hFFFFFFFF;
        v_f2i.flags  = 5'b10000;
      end
      if (v_f2i.sign_cvt) begin
        if (~(v_f2i.snan | v_f2i.qnan)) begin
          v_f2i.result = 32'h00000000;
        end
      end
    end

    cvt_f2i_o.result = f2i_v.result;
    cvt_f2i_o.flags  = f2i_v.flags;

  end

  always_comb begin

    i2f_v.data = fp_cvt_i2f_i.data;
    i2f_v.op = fp_cvt_i2f_i.op.fcvt_op;
    i2f_v.fmt = fp_cvt_i2f_i.fmt;
    i2f_v.rm = fp_cvt_i2f_i.rm;

    i2f_v.snan = 0;
    i2f_v.qnan = 0;
    i2f_v.dbz = 0;
    i2f_v.infs = 0;
    i2f_v.zero = 0;

    i2f_v.exponent_bias = 127;

    i2f_v.sign_uint = 0;

    if (i2f_v.op == 0) begin
      i2f_v.sign_uint = i2f_v.data[31];
    end

    if (i2f_v.sign_uint) begin
      i2f_v.data = -i2f_v.data;
    end
    
    i2f_v.mantissa_uint = i2f_v.data[31:0];
    i2f_v.exponent_uint = 31;

    i2f_v.zero = ~|i2f_v.mantissa_uint;

    lzc_i.data = i2f_v.mantissa_uint;
    i2f_v.counter_uint = ~lzc_o.cnt;

    i2f_v.mantissa_uint = i2f_v.mantissa_uint << i2f_v.counter_uint;

    i2f_v.sign_rnd = i2f_v.sign_uint;      //符号位
    i2f_v.exponent_rnd = {6'h0,i2f_v.exponent_uint} + {4'h0,i2f_v.exponent_bias} - {6'h0,i2f_v.counter_uint};  //指数位

    i2f_v.mantissa_rnd = {1'h0, i2f_v.mantissa_uint[31:8]};    //尾数位
    i2f_v.grs = {i2f_v.mantissa_uint[7:6], |i2f_v.mantissa_uint[5:0]};

    cvt_i2f_o.fp_rnd.sig = i2f_v.sign_rnd;
    cvt_i2f_o.fp_rnd.expo = i2f_v.exponent_rnd;
    cvt_i2f_o.fp_rnd.mant = i2f_v.mantissa_rnd;
    cvt_i2f_o.fp_rnd.rema = 2'h0;
    cvt_i2f_o.fp_rnd.fmt = i2f_v.fmt;
    cvt_i2f_o.fp_rnd.rm = i2f_v.rm;
    cvt_i2f_o.fp_rnd.grs = i2f_v.grs;
    cvt_i2f_o.fp_rnd.snan = i2f_v.snan;
    cvt_i2f_o.fp_rnd.qnan = i2f_v.qnan;
    cvt_i2f_o.fp_rnd.dbz = i2f_v.dbz;
    cvt_i2f_o.fp_rnd.infs = i2f_v.infs;
    cvt_i2f_o.fp_rnd.zero = i2f_v.zero;
    cvt_i2f_o.fp_rnd.diff = 1'h0;

  end

endmodule