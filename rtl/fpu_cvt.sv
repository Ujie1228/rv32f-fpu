import fpu_define::*;
import lzc_define::*;
module fpu_cvt (
    input  logic            clk_i,
    input  logic            rst_ni,
    input  logic            reg_empty,
    input  fpu_cvt_in_type  cvt_i,
    output fpu_cvt_out_type cvt_o,
    input  lzc_32_out_type  lzc_o,
    output lzc_32_in_type   lzc_i
);

  typedef struct packed {
    logic [32:0] extend;
    fpu_operation_type op;
    logic [2:0] rm;
    logic [9:0] classification;
  } fpu_cvt_f2i_in_type;

  typedef struct packed {
    logic [31:0] result;
    logic [4:0]  flags;
  } fpu_cvt_f2i_out_type;

  typedef struct packed {
    logic [32:0] extend;
    logic [1:0] op;
    logic [2:0] rm;
    logic [9:0] classification;
    logic [31:0] result;
    logic [4:0] flags;
    logic snan;
    logic qnan;
    logic infs;
    logic zero;
    logic sign_cvt;
    logic [9:0] exponent_cvt;
    logic [58:0] mantissa_cvt;
    logic [9:0] exponent_bias;
    logic [32:0] mantissa_uint;
    logic [2:0] grs;
    logic odd;
    logic rnded;
    logic oor;
    logic or_1;
    logic or_2;
    logic or_3;
    logic or_4;
    logic or_5;
    logic oor_64u;
    logic oor_64s;
    logic oor_32u;
    logic oor_32s;
  } fpu_cvt_f2i_var_type;

  typedef struct packed {
    logic [31:0] data;
    fp_operation_type op;
    logic [2:0] rm;
  } fpu_cvt_i2f_in_type;

  typedef struct packed {
    fpu_rnd_in_type rnd;
  } fpu_cvt_i2f_out_type;

  typedef struct packed {
    logic [31:0] data;
    logic [1:0] op;
    logic [1:0] fmt;
    logic [2:0] rm;
    logic snan;
    logic qnan;
    logic dbz;
    logic infs;
    logic zero;
    logic sign_uint;
    logic [4:0] exponent_uint;
    logic [31:0] mantissa_uint;
    logic [4:0] counter_uint;
    logic [6:0] exponent_bias;
    logic sign_rnd;
    logic [10:0] exponent_rnd;
    logic [24:0] mantissa_rnd;
    logic [2:0] grs;
  } fpu_cvt_i2f_var_type;

  fpu_cvt_f2i_in_type  cvt_f2i_i;
  fpu_cvt_f2i_out_type cvt_f2i_o;
  fpu_cvt_i2f_in_type  cvt_i2f_i;
  fpu_cvt_i2f_out_type cvt_i2f_o;
  fpu_cvt_f2i_var_type f2i_v;
  fpu_cvt_i2f_var_type i2f_v;
  fpu_rnd_out_type     r_1;
  
  assign cvt_f2i_i.extend = cvt_i.extend;
  assign cvt_f2i_i.op = cvt_i.op;
  assign cvt_f2i_i.rm = cvt_i.rm;
  assign cvt_f2i_i.classification = cvt_i.classification;

  assign cvt_i2f_i.data = cvt_i.data;
  assign cvt_i2f_i.op = cvt_i.op;
  assign cvt_i2f_i.rm = cvt_i.rm;

  always_comb begin

    f2i_v.extend = cvt_f2i_i.extend;
    f2i_v.op = cvt_f2i_i.op.fcvt_uf2i;
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

    f2i_v.sign_cvt = f2i_v.extend[32];
    f2i_v.exponent_cvt = f2i_v.extend[31:23] - 10'd252;
    f2i_v.mantissa_cvt = {36'h1, f2i_v.extend[22:0]};

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

  fpu_rnd u_fpu_rnd (
    .rnd_i (cvt_i2f_o.rnd),
    .rnd_o (r_1)
  );

  always_comb begin

    i2f_v.data = fp_cvt_i2f_i.data;
    i2f_v.op = fp_cvt_i2f_i.op.fcvt_ui2f;
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

    cvt_i2f_o.rnd.sig = i2f_v.sign_rnd;
    cvt_i2f_o.rnd.expo = i2f_v.exponent_rnd;
    cvt_i2f_o.rnd.mant = i2f_v.mantissa_rnd;
    cvt_i2f_o.rnd.rema = 2'h0;
    cvt_i2f_o.rnd.fmt = i2f_v.fmt;
    cvt_i2f_o.rnd.rm = i2f_v.rm;
    cvt_i2f_o.rnd.grs = i2f_v.grs;
    cvt_i2f_o.rnd.snan = i2f_v.snan;
    cvt_i2f_o.rnd.qnan = i2f_v.qnan;
    cvt_i2f_o.rnd.dbz = i2f_v.dbz;
    cvt_i2f_o.rnd.infs = i2f_v.infs;
    cvt_i2f_o.rnd.zero = i2f_v.zero;
    cvt_i2f_o.rnd.diff = 1'h0;

  end

  always_ff @(posedge clk_i or posedge rst_ni) begin
    if (rst_ni) begin
      cvt_o <= 0;
    end else if (reg_empty) begin
      cvt_o.req_valid <= cvt_i.req_valid;
      cvt_o.req_tag <= cvt_i.req_tag;
      if (cvt_i.op.fcvt_i2f) begin
        cvt_o.result <= r_1.result;
        cvt_o.flags <= r_1.flags;
      end else if (cvt_i.op.fcvt_f2i) begin
        cvt_o.result <= cvt_f2i_o.result;
        cvt_o.flags <= cvt_f2i_o.flags;
      end
    end
  end

endmodule