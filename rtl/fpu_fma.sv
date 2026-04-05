import fpu_define::*;

module fpu_fma (
    input  logic            clk_i,
    input  logic            rst_ni,
    input  logic            reg_empty,
    input  fpu_fma_in_type  fma_i,
    output fpu_fma_out_type fma_o,
    input  lzc_128_out_type lzc_o,
    output lzc_128_in_type  lzc_i
);

  typedef struct packed {
    logic [2:0] rm;
    logic snan;
    logic qnan;
    logic dbz;
    logic infs;
    logic zero;
    logic sign_mul;
    logic [10:0] exponent_mul;
    logic [76:0] mantissa_mul;
    logic sign_add;
    logic [10:0] exponent_add;
    logic [76:0] mantissa_add;
    logic exponent_neg;
    logic ready;
    logic req_valid;
    logic [4:0]  req_tag;
  } fpu_fma_reg_type_1;

  typedef struct packed {
    logic [32:0] a;
    logic [32:0] b;
    logic [32:0] c;
    logic [9:0] class_a;
    logic [9:0] class_b;
    logic [9:0] class_c;
    logic [2:0] rm;
    logic snan;
    logic qnan;
    logic dbz;
    logic infs;
    logic zero;
    logic sign_a;
    logic [8:0] exponent_a;
    logic [23:0] mantissa_a;
    logic sign_b;
    logic [8:0] exponent_b;
    logic [23:0] mantissa_b;
    logic sign_c;
    logic [8:0] exponent_c;
    logic [23:0] mantissa_c;
    logic sign_mul;
    logic [10:0] exponent_mul;
    logic [76:0] mantissa_mul;
    logic sign_add;
    logic [10:0] exponent_add;
    logic [76:0] mantissa_add;
    logic [76:0] mantissa_l;
    logic [76:0] mantissa_r;
    logic [10:0] exponent_dif;
    logic [5:0] counter_dif;
    logic exponent_neg;
    logic ready;
    logic req_valid;
    logic [4:0]  req_tag;
  } fpu_fma_var_type_1;

  typedef struct packed {
    logic sign_rnd;
    logic [10:0] exponent_rnd;
    logic [24:0] mantissa_rnd;
    logic [2:0] rm;
    logic [2:0] grs;
    logic snan;
    logic qnan;
    logic dbz;
    logic infs;
    logic zero;
    logic diff;
    logic ready;
    logic req_valid;
    logic [4:0]  req_tag;
  } fpu_fma_reg_type_2;

  typedef struct packed {
    logic [2:0] rm;
    logic snan;
    logic qnan;
    logic dbz;
    logic infs;
    logic zero;
    logic diff;
    logic sign_mul;
    logic [10:0] exponent_mul;
    logic [76:0] mantissa_mul;
    logic sign_add;
    logic [10:0] exponent_add;
    logic [76:0] mantissa_add;
    logic exponent_neg;
    logic sign_mac;
    logic [10:0] exponent_mac;
    logic [76:0] mantissa_mac;
    logic [6:0] counter_mac;
    logic [10:0] counter_sub;
    logic [7:0] bias;
    logic sign_rnd;
    logic [10:0] exponent_rnd;
    logic [24:0] mantissa_rnd;
    logic [2:0] grs;
    logic ready;
    logic req_valid;
    logic [4:0]  req_tag;
  } fpu_fma_var_type_2;

  typedef struct packed {
    fpu_rnd_in_type rnd;
    logic ready;
    logic req_valid;
    logic [4:0]  req_tag;
  } fpu_fma_var_type_3;

  fpu_fma_reg_type_1 r_1;
  fpu_fma_reg_type_2 r_2;
  fpu_fma_out_type r_3;

  fpu_fma_reg_type_1 rin_1;
  fpu_fma_reg_type_2 rin_2;
  fpu_fma_out_type rin_3;

  fpu_fma_var_type_1 v_1;
  fpu_fma_var_type_2 v_2;
  fpu_fma_var_type_3 v_3;

  always_comb begin

    v_1.a = fma_i.data1;
    v_1.b = fma_i.data2;
    v_1.c = fma_i.data3;
    v_1.class_a = fma_i.class1;
    v_1.class_b = fma_i.class2;
    v_1.class_c = fma_i.class3;
    v_1.fmt = fma_i.fmt;
    v_1.rm = fma_i.rm;
    v_1.snan = 0;
    v_1.qnan = 0;
    v_1.dbz = 0;
    v_1.infs = 0;
    v_1.zero = 0;
    v_1.ready = fma_i.op.fmadd | fma_i.op.fmsub | fma_i.op.fnmsub | fma_i.op.fnmadd | fma_i.op.fadd | fma_i.op.fsub | fma_i.op.fmul;
    v_1.req_valid = fma_i.req_valid;
    v_1.req_tag = fma_i.req_tag;

    if (fma_i.op.fadd | fma_i.op.fsub) begin
      v_1.c = v_1.b;
      v_1.class_c = v_1.class_b;
      v_1.b = 33'h07F800000;
      v_1.class_b = 10'h040;
    end

    if (fma_i.op.fmul) begin
      v_1.c = {v_1.a[32] ^ v_1.b[32], 32'h00000000};
      v_1.class_c = 0;
    end

    v_1.sign_a = v_1.a[32];
    v_1.exponent_a = v_1.a[31:23];
    v_1.mantissa_a = {|v_1.exponent_a, v_1.a[22:0]};

    v_1.sign_b = v_1.b[32];
    v_1.exponent_b = v_1.b[31:23];
    v_1.mantissa_b = {|v_1.exponent_b, v_1.b[22:0]};

    v_1.sign_c = v_1.c[32];
    v_1.exponent_c = v_1.c[31:23];
    v_1.mantissa_c = {|v_1.exponent_c, v_1.c[22:0]};

    v_1.sign_add = v_1.sign_c ^ (fma_i.op.fmsub | fma_i.op.fnmadd | fma_i.op.fsub);
    v_1.sign_mul = (v_1.sign_a ^ v_1.sign_b) ^ (fma_i.op.fnmsub | fma_i.op.fnmadd);

    if (v_1.class_a[8] | v_1.class_b[8] | v_1.class_c[8]) begin
      v_1.snan = 1;
    end else if (((v_1.class_a[3] | v_1.class_a[4]) & (v_1.class_b[0] | v_1.class_b[7])) | ((v_1.class_b[3] | v_1.class_b[4]) & (v_1.class_a[0] | v_1.class_a[7]))) begin
      v_1.snan = 1;
    end else if (v_1.class_a[9] | v_1.class_b[9] | v_1.class_c[9]) begin
      v_1.qnan = 1;
    end else if (((v_1.class_a[0] | v_1.class_a[7]) | (v_1.class_b[0] | v_1.class_b[7])) & ((v_1.class_c[0] | v_1.class_c[7]) & (v_1.sign_add != v_1.sign_mul))) begin
      v_1.snan = 1;
    end else if ((v_1.class_a[0] | v_1.class_a[7]) | (v_1.class_b[0] | v_1.class_b[7]) | (v_1.class_c[0] | v_1.class_c[7])) begin
      v_1.infs = 1;
    end

    v_1.exponent_add = $signed({2'h0, v_1.exponent_c});
    v_1.exponent_mul = $signed({2'h0, v_1.exponent_a}) + $signed({2'h0, v_1.exponent_b}) - 11'd255;

    if (&v_1.exponent_c) begin
      v_1.exponent_add = 11'h1FF;
    end
    if (&v_1.exponent_a | &v_1.exponent_b) begin
      v_1.exponent_mul = 11'h1FF;
    end

    v_1.mantissa_add[76:74] = 0;
    v_1.mantissa_add[73:50] = v_1.mantissa_c;
    v_1.mantissa_add[49:0] = 0;
    v_1.mantissa_mul[76:75] = 0;
    v_1.mantissa_mul[74:27] = v_1.mantissa_a * v_1.mantissa_b;
    v_1.mantissa_mul[26:0] = 0;

    v_1.exponent_dif = $signed(v_1.exponent_mul) - $signed(v_1.exponent_add);
    v_1.counter_dif = 0;

    v_1.exponent_neg = v_1.exponent_dif[10];

    if (v_1.exponent_neg) begin
      v_1.counter_dif = 27;
      if ($signed(v_1.exponent_dif) > -27) begin
        v_1.counter_dif = -v_1.exponent_dif[5:0];
      end
      v_1.mantissa_l = v_1.mantissa_add;
      v_1.mantissa_r = v_1.mantissa_mul;
    end else begin
      v_1.counter_dif = 50;
      if ($signed(v_1.exponent_dif) < 50) begin
        v_1.counter_dif = v_1.exponent_dif[5:0];
      end
      v_1.mantissa_l = v_1.mantissa_mul;
      v_1.mantissa_r = v_1.mantissa_add;
    end

    v_1.mantissa_r = v_1.mantissa_r >> v_1.counter_dif;

    if (v_1.exponent_neg) begin
      v_1.mantissa_add = v_1.mantissa_l;
      v_1.mantissa_mul = v_1.mantissa_r;
    end else begin
      v_1.mantissa_add = v_1.mantissa_r;
      v_1.mantissa_mul = v_1.mantissa_l;
    end

    rin_1.fmt = v_1.fmt;
    rin_1.rm = v_1.rm;
    rin_1.snan = v_1.snan;
    rin_1.qnan = v_1.qnan;
    rin_1.dbz = v_1.dbz;
    rin_1.infs = v_1.infs;
    rin_1.zero = v_1.zero;
    rin_1.sign_mul = v_1.sign_mul;
    rin_1.exponent_mul = v_1.exponent_mul;
    rin_1.mantissa_mul = v_1.mantissa_mul;
    rin_1.sign_add = v_1.sign_add;
    rin_1.exponent_add = v_1.exponent_add;
    rin_1.mantissa_add = v_1.mantissa_add;
    rin_1.exponent_neg = v_1.exponent_neg;
    rin_1.ready = v_1.ready;
    rin_1.req_valid = v_1.req_valid;
    rin_1.req_tag = v_1.req_tag;

  end

  always_comb begin

    v_2.fmt          = r_1.fmt;
    v_2.rm           = r_1.rm;
    v_2.snan         = r_1.snan;
    v_2.qnan         = r_1.qnan;
    v_2.dbz          = r_1.dbz;
    v_2.infs         = r_1.infs;
    v_2.zero         = r_1.zero;
    v_2.sign_mul     = r_1.sign_mul;
    v_2.exponent_mul = r_1.exponent_mul;
    v_2.mantissa_mul = r_1.mantissa_mul;
    v_2.sign_add     = r_1.sign_add;
    v_2.exponent_add = r_1.exponent_add;
    v_2.mantissa_add = r_1.mantissa_add;
    v_2.exponent_neg = r_1.exponent_neg;
    v_2.ready        = r_1.ready;
    v_2.req_valid    = r_1.req_valid;
    v_2.req_tag      = r_1.req_tag;

    if (v_2.exponent_neg) begin
      v_2.exponent_mac = v_2.exponent_add;
    end else begin
      v_2.exponent_mac = v_2.exponent_mul;
    end

    if (v_2.sign_add) begin
      v_2.mantissa_add = ~v_2.mantissa_add;
    end
    if (v_2.sign_mul) begin
      v_2.mantissa_mul = ~v_2.mantissa_mul;
    end

    v_2.mantissa_mac = v_2.mantissa_add + v_2.mantissa_mul + {76'h0,v_2.sign_add} + {76'h0,v_2.sign_mul};
    v_2.sign_mac = v_2.mantissa_mac[76];

    v_2.zero = ~|v_2.mantissa_mac;

    if (v_2.zero) begin
      v_2.sign_mac = v_2.sign_add & v_2.sign_mul;
    end else if (v_2.sign_mac) begin
      v_2.mantissa_mac = -v_2.mantissa_mac;
    end

    v_2.diff = v_2.sign_add ^ v_2.sign_mul;

    v_2.bias = 126;

    lzc_i.a = {v_2.mantissa_mac[75:0], {52{1'b1}}};
    v_2.counter_mac = ~lzc_o.c;
    v_2.mantissa_mac = v_2.mantissa_mac << v_2.counter_mac;

    v_2.sign_rnd = v_2.sign_mac;
    v_2.exponent_rnd = v_2.exponent_mac - {3'h0, v_2.bias} - {4'h0, v_2.counter_mac};

    v_2.counter_sub = 0;
    if ($signed(v_2.exponent_rnd) <= 0) begin
      v_2.counter_sub = 63;
      if ($signed(v_2.exponent_rnd) > -63) begin
        v_2.counter_sub = 11'h1 - v_2.exponent_rnd;
      end
      v_2.exponent_rnd = 0;
    end

    v_2.mantissa_mac = v_2.mantissa_mac >> v_2.counter_sub[5:0];

    v_2.mantissa_rnd = {1'h0, v_2.mantissa_mac[75:52]};
    v_2.grs = {v_2.mantissa_mac[51:50], |v_2.mantissa_mac[49:0]};

    rin_2.sign_rnd = v_2.sign_rnd;
    rin_2.exponent_rnd = v_2.exponent_rnd;
    rin_2.mantissa_rnd = v_2.mantissa_rnd;
    rin_2.fmt = v_2.fmt;
    rin_2.rm = v_2.rm;
    rin_2.grs = v_2.grs;
    rin_2.snan = v_2.snan;
    rin_2.qnan = v_2.qnan;
    rin_2.dbz = v_2.dbz;
    rin_2.infs = v_2.infs;
    rin_2.diff = v_2.diff;
    rin_2.zero = v_2.zero;
    rin_2.ready = v_2.ready;
    rin_2.req_valid = v_2.req_valid;
    rin_2.req_tag = v_2.req_tag;

  end

  fpu_rnd u_fpu_rnd (
    .rnd_i (v_3.fp_rnd),
    .rnd_o ({rin_3.result , rin_3.flags})
  );

  always_comb begin

    v_3.fp_rnd.sig = r_2.sign_rnd;
    v_3.fp_rnd.expo = r_2.exponent_rnd;
    v_3.fp_rnd.mant = r_2.mantissa_rnd;
    v_3.fp_rnd.rema = 2'h0;
    v_3.fp_rnd.fmt = r_2.fmt;
    v_3.fp_rnd.rm = r_2.rm;
    v_3.fp_rnd.grs = r_2.grs;
    v_3.fp_rnd.snan = r_2.snan;
    v_3.fp_rnd.qnan = r_2.qnan;
    v_3.fp_rnd.dbz = r_2.dbz;
    v_3.fp_rnd.infs = r_2.infs;
    v_3.fp_rnd.zero = r_2.zero;
    v_3.fp_rnd.diff = r_2.diff;
    v_3.ready = r_2.ready;
    v_3.req_valid = r_2.req_valid;
    v_3.req_tag = r_2.req_tag;

    rin_3.req_valid = v_3.req_valid;
    rin_3.req_tag = v_3.req_tag;

  end

  always_comb begin
        fma_o = r_3;
  end

  always_ff @(posedge clk_i or posedge rst_ni) begin
    if (rst_ni) begin
        r_1 <= 0;
        r_2 <= 0;
        r_2 <= 0;
    end else if (reg_empty == 0) begin
        r_1 <= r_1;
        r_2 <= r_2;
        r_3 <= r_3;
    end else begin
        r_1 <= rin_1;
        r_2 <= rin_2;
        r_3 <= rin_3;
    end
  end

endmodule
