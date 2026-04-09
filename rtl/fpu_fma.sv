import lzc_define::*;
import fpu_define::*;

module fpu_fma (
    input clk_i,
    input rst_ni,

    input logic fma_stall_i,
    input logic fma_start_i,

    input  fpu_fma_in_type fpu_fma_i,
    output fpu_fma_out_type fpu_fma_o,
    output fpu_fma_reg_out fma_reg_o,
    input  fpu_rnd_out_type fma_rnd_i,

    input lzc_128_out_type lzc_i,
    output lzc_128_in_type lzc_o,

    output logic fma_ready_o,
    output logic fma_data_vld_o,

    input clear     // 暂不用
);

  fpu_fma_reg_type_1 r_1;
  fpu_fma_reg_type_2 r_2;

  fpu_fma_reg_type_1 rin_1;
  fpu_fma_reg_type_2 rin_2;

  fpu_fma_var_type_1 v_1;
  fpu_fma_var_type_2 v_2;

  assign fma_ready_o = ~fma_stall_i;

  always_comb begin

    v_1.a = fpu_fma_i.extend1;
    v_1.b = fpu_fma_i.extend2;
    v_1.c = fpu_fma_i.extend3;
    v_1.class_a = fpu_fma_i.class1;
    v_1.class_b = fpu_fma_i.class2;
    v_1.class_c = fpu_fma_i.class3;
    v_1.fmt = 0;
    v_1.rm = fpu_fma_i.rm;
    v_1.snan = 0;
    v_1.qnan = 0;
    v_1.dbz = 0;
    v_1.infs = 0;
    v_1.zero = 0;
    v_1.ready = fma_start_i;
    v_1.tag = fpu_fma_i.tag;

    if (fpu_fma_i.op.fadd | fpu_fma_i.op.fsub) begin
      v_1.c = v_1.b;
      v_1.class_c = v_1.class_b;
      v_1.b = 33'h07F800000;
      v_1.class_b = 10'h040;
    end

    if (fpu_fma_i.op.fmul) begin
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

    v_1.sign_add = v_1.sign_c ^ (fpu_fma_i.op.fmsub | fpu_fma_i.op.fnmadd | fpu_fma_i.op.fsub);
    v_1.sign_mul = (v_1.sign_a ^ v_1.sign_b) ^ (fpu_fma_i.op.fnmsub | fpu_fma_i.op.fnmadd);

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

    if (clear == 1) begin
      v_1.ready = 0;
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
    rin_1.tag = v_1.tag;
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
    v_2.tag          = r_1.tag;

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

    lzc_o.data = {v_2.mantissa_mac[75:0], {52{1'b1}}};
    v_2.counter_mac = ~lzc_i.cnt;
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

    if (clear == 1) begin
      v_2.ready = 0;
    end

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
    rin_2.tag = v_2.tag;

  end

  always_comb begin

    fpu_fma_o.fpu_rnd.sig = r_2.sign_rnd;
    fpu_fma_o.fpu_rnd.expo = r_2.exponent_rnd;
    fpu_fma_o.fpu_rnd.mant = r_2.mantissa_rnd;
    fpu_fma_o.fpu_rnd.rema = 2'h0;
    fpu_fma_o.fpu_rnd.fmt = r_2.fmt;
    fpu_fma_o.fpu_rnd.rm = r_2.rm;
    fpu_fma_o.fpu_rnd.grs = r_2.grs;
    fpu_fma_o.fpu_rnd.snan = r_2.snan;
    fpu_fma_o.fpu_rnd.qnan = r_2.qnan;
    fpu_fma_o.fpu_rnd.dbz = r_2.dbz;
    fpu_fma_o.fpu_rnd.infs = r_2.infs;
    fpu_fma_o.fpu_rnd.zero = r_2.zero;
    fpu_fma_o.fpu_rnd.diff = r_2.diff;
    fpu_fma_o.ready = r_2.ready;
    fpu_fma_o.tag = r_2.tag;

  end

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (~rst_ni) begin
      r_1 <= init_fpu_fma_reg_1;
      r_2 <= init_fpu_fma_reg_2;
    end else if (fma_stall_i) begin
      r_1 <= r_1;
      r_2 <= r_2;
      fma_reg_o <= fma_reg_o;
      fma_data_vld_o <= fma_data_vld_o;
    end else begin
      r_1 <= rin_1;
      r_2 <= rin_2;
      if (fpu_fma_o.ready) begin
        fma_reg_o.result <= fma_rnd_i.result;
        fma_reg_o.flags <= fma_rnd_i.flags;
        fma_reg_o.tag <= fpu_fma_o.tag;
        fma_data_vld_o <= 1'b1;
      end else begin
        fma_data_vld_o <= 1'b0;
      end
    end
  end 

endmodule
