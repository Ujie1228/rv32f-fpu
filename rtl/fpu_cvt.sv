import lzc_define::*;
import fpu_define::*;

module fpu_cvt #(
    parameter RISCV = 1 // 默认执行RISC-V标准
) (
    input logic     clk_i,
    input logic     rst_ni,

    input logic cvt_stall_i,
    input logic cvt_start_i,
    
    input   fpu_cvt_in_type  cvt_reg_i,
    output  fpu_cvt_out_type cvt_reg_o,
    input   lzc_32_out_type  lzc_i,
    output  lzc_32_in_type   lzc_o,
    input   fpu_rnd_out_type cvt_rnd_i,
    output  fpu_rnd_in_type  cvt_rnd_o,

    output logic cvt_ready_o,
    output logic cvt_data_vld_o
);

    //cvt_o
    fpu_cvt_out_type cvt_o;

    fpu_cvt_f2i_in_type  fp_cvt_f2i_i;
    fpu_cvt_f2i_out_type fp_cvt_f2i_o;
    fpu_cvt_i2f_in_type  fp_cvt_i2f_i;
    fpu_cvt_i2f_out_type fp_cvt_i2f_o;

    fpu_cvt_f2i_var_type v_f2i;
    fpu_cvt_i2f_var_type v_i2f;
    
    // start
    logic start_n;
    
    assign start_n = cvt_start_i;

    assign fp_cvt_f2i_i.extend = cvt_reg_i.extend;
    assign fp_cvt_f2i_i.op = cvt_reg_i.op;
    assign fp_cvt_f2i_i.rm = cvt_reg_i.rm;
    assign fp_cvt_f2i_i.classification = cvt_reg_i.classification;

    assign fp_cvt_i2f_i.data = cvt_reg_i.data;
    assign fp_cvt_i2f_i.op = cvt_reg_i.op;
    assign fp_cvt_i2f_i.rm = cvt_reg_i.rm;

    // ready
    assign cvt_ready_o = ~cvt_stall_i;

    generate

      if (RISCV == 0) begin

        always_comb begin

          v_f2i.extend = fp_cvt_f2i_i.extend;
          v_f2i.op = fp_cvt_f2i_i.op.fcvt_op;
          v_f2i.rm = fp_cvt_f2i_i.rm;
          v_f2i.classification = fp_cvt_f2i_i.classification;

          v_f2i.flags = 0;
          v_f2i.result = 0;

          v_f2i.snan = v_f2i.classification[8];
          v_f2i.qnan = v_f2i.classification[9];
          v_f2i.infs = v_f2i.classification[0] | v_f2i.classification[7];
          v_f2i.zero = 0;

          if (v_f2i.op == 0) begin
              v_f2i.exponent_bias = 34;
          end else begin
              v_f2i.exponent_bias = 35;
          end

          v_f2i.sign_cvt = v_f2i.extend[32];
          v_f2i.exponent_cvt = v_f2i.extend[31:23] - 10'd252;
          v_f2i.mantissa_cvt = {36'h1, v_f2i.extend[22:0]};

          if ((v_f2i.classification[3] | v_f2i.classification[4]) == 1) begin
            v_f2i.mantissa_cvt[23] = 0;
          end

          v_f2i.oor = 0;

          if ($signed(v_f2i.exponent_cvt) > $signed({2'h0, v_f2i.exponent_bias})) begin
            v_f2i.oor = 1;
          end else if ($signed(v_f2i.exponent_cvt) > 0) begin
            v_f2i.mantissa_cvt = v_f2i.mantissa_cvt << v_f2i.exponent_cvt;
          end

          v_f2i.mantissa_uint = v_f2i.mantissa_cvt[58:26];

          v_f2i.grs = {v_f2i.mantissa_cvt[25:24], |v_f2i.mantissa_cvt[23:0]};
          v_f2i.odd = v_f2i.mantissa_uint[0] | |v_f2i.grs[1:0];

          v_f2i.flags[0] = |v_f2i.grs;

          v_f2i.rnded = 0;
          if (v_f2i.rm == 0) begin  //rne
            if (v_f2i.grs[2] & v_f2i.odd) begin
              v_f2i.rnded = 1;
            end
          end else if (v_f2i.rm == 2) begin  //rdn
            if (v_f2i.sign_cvt & v_f2i.flags[0]) begin
              v_f2i.rnded = 1;
            end
          end else if (v_f2i.rm == 3) begin  //rup
            if (~v_f2i.sign_cvt & v_f2i.flags[0]) begin
              v_f2i.rnded = 1;
            end
          end else if (v_f2i.rm == 4) begin  //rmm
            if (v_f2i.grs[2] & v_f2i.flags[0]) begin
              v_f2i.rnded = 1;
            end
          end

          v_f2i.mantissa_uint = v_f2i.mantissa_uint + {32'h0, v_f2i.rnded};

          v_f2i.or_1 = v_f2i.mantissa_uint[32];
          v_f2i.or_2 = v_f2i.mantissa_uint[31];
          v_f2i.or_3 = |v_f2i.mantissa_uint[30:0];

          v_f2i.zero = ~(v_f2i.or_1 | v_f2i.or_2 | v_f2i.or_3);

          v_f2i.oor_32u = v_f2i.or_1;
          v_f2i.oor_32s = v_f2i.or_1;

          if (v_f2i.sign_cvt) begin
            if (v_f2i.op == 0) begin
              v_f2i.oor_32s = v_f2i.oor_32s | (v_f2i.or_2 & v_f2i.or_3);
            end else if (v_f2i.op == 1) begin
              v_f2i.oor = v_f2i.oor | v_f2i.zero;
            end
          end else begin
            v_f2i.oor_32s = v_f2i.oor_32s | v_f2i.or_2;
          end

          v_f2i.oor_32u = (v_f2i.op == 1) & (v_f2i.oor_32u | v_f2i.oor | v_f2i.infs | v_f2i.snan | v_f2i.qnan);
          v_f2i.oor_32s = (v_f2i.op == 0) & (v_f2i.oor_32s | v_f2i.oor | v_f2i.infs | v_f2i.snan | v_f2i.qnan);

          if (v_f2i.sign_cvt) begin
            v_f2i.mantissa_uint = -v_f2i.mantissa_uint;
          end

          if (v_f2i.op == 0) begin
            v_f2i.result = v_f2i.mantissa_uint[31:0];
            if (v_f2i.oor_32s) begin
              v_f2i.result = 32'h80000000;
              v_f2i.flags  = 5'b10000;
            end
          end else if (v_f2i.op == 1) begin
            v_f2i.result = v_f2i.mantissa_uint[31:0];
            if (v_f2i.oor_32u) begin
              v_f2i.result = 32'hFFFFFFFF;
              v_f2i.flags  = 5'b10000;
            end
          end

          fp_cvt_f2i_o.result = v_f2i.result;
          fp_cvt_f2i_o.flags  = v_f2i.flags;

        end

      end

      if (RISCV == 1) begin

        always_comb begin

          v_f2i.extend = fp_cvt_f2i_i.extend;
          v_f2i.op = fp_cvt_f2i_i.op.fcvt_op;
          v_f2i.rm = fp_cvt_f2i_i.rm;
          v_f2i.classification = fp_cvt_f2i_i.classification;

          v_f2i.flags = 0;
          v_f2i.result = 0;

          v_f2i.snan = v_f2i.classification[8];
          v_f2i.qnan = v_f2i.classification[9];
          v_f2i.infs = v_f2i.classification[0] | v_f2i.classification[7];
          v_f2i.zero = 0;

          if (v_f2i.op == 0) begin
            v_f2i.exponent_bias = 34;
          end else begin
            v_f2i.exponent_bias = 35;
          end

          v_f2i.sign_cvt = v_f2i.extend[32];
          v_f2i.exponent_cvt = v_f2i.extend[31:23] - 10'd252;
          v_f2i.mantissa_cvt = {36'h1, v_f2i.extend[22:0]};

          if ((v_f2i.classification[3] | v_f2i.classification[4]) == 1) begin
            v_f2i.mantissa_cvt[23] = 0;
          end

          v_f2i.oor = 0;

          if ($signed(v_f2i.exponent_cvt) > $signed({2'h0, v_f2i.exponent_bias})) begin
            v_f2i.oor = 1;
          end else if ($signed(v_f2i.exponent_cvt) > 0) begin
            v_f2i.mantissa_cvt = v_f2i.mantissa_cvt << v_f2i.exponent_cvt;
          end

          v_f2i.mantissa_uint = v_f2i.mantissa_cvt[58:26];

          v_f2i.grs = {v_f2i.mantissa_cvt[25:24], |v_f2i.mantissa_cvt[23:0]};
          v_f2i.odd = v_f2i.mantissa_uint[0] | |v_f2i.grs[1:0];

          v_f2i.flags[0] = |v_f2i.grs;

          v_f2i.rnded = 0;
          if (v_f2i.rm == 0) begin  //rne
            if (v_f2i.grs[2] & v_f2i.odd) begin
              v_f2i.rnded = 1;
            end
          end else if (v_f2i.rm == 2) begin  //rdn
            if (v_f2i.sign_cvt & v_f2i.flags[0]) begin
              v_f2i.rnded = 1;
            end
          end else if (v_f2i.rm == 3) begin  //rup
            if (~v_f2i.sign_cvt & v_f2i.flags[0]) begin
              v_f2i.rnded = 1;
            end
          end else if (v_f2i.rm == 4) begin  //rmm
            if (v_f2i.grs[2] & v_f2i.flags[0]) begin
              v_f2i.rnded = 1;
            end
          end

          v_f2i.mantissa_uint = v_f2i.mantissa_uint + {32'h0, v_f2i.rnded};

          v_f2i.or_1 = v_f2i.mantissa_uint[32];
          v_f2i.or_2 = v_f2i.mantissa_uint[31];
          v_f2i.or_3 = |v_f2i.mantissa_uint[30:0];

          v_f2i.zero = ~(v_f2i.or_1 | v_f2i.or_2 | v_f2i.or_3);

          v_f2i.oor_32u = v_f2i.or_1;
          v_f2i.oor_32s = v_f2i.or_1;

          if (v_f2i.sign_cvt) begin
            if (v_f2i.op == 0) begin
              v_f2i.oor_32s = v_f2i.oor_32s | (v_f2i.or_2 & v_f2i.or_3);
            end else if (v_f2i.op == 1) begin
              v_f2i.oor = v_f2i.oor | v_f2i.zero;
            end
          end else begin
            v_f2i.oor_32s = v_f2i.oor_32s | v_f2i.or_2;
          end

          v_f2i.oor_32u = (v_f2i.op == 1) & (v_f2i.oor_32u | v_f2i.oor | v_f2i.infs | v_f2i.snan | v_f2i.qnan);
          v_f2i.oor_32s = (v_f2i.op == 0) & (v_f2i.oor_32s | v_f2i.oor | v_f2i.infs | v_f2i.snan | v_f2i.qnan);

          if (v_f2i.sign_cvt) begin
            v_f2i.mantissa_uint = -v_f2i.mantissa_uint;
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

          fp_cvt_f2i_o.result = v_f2i.result;
          fp_cvt_f2i_o.flags  = v_f2i.flags;

        end

      end

    endgenerate

    always_comb begin

      v_i2f.data = fp_cvt_i2f_i.data;
      v_i2f.op = fp_cvt_i2f_i.op.fcvt_op;    
      v_i2f.fmt = 0;
      v_i2f.rm = fp_cvt_i2f_i.rm;

      v_i2f.snan = 0;
      v_i2f.qnan = 0;
      v_i2f.dbz = 0;
      v_i2f.infs = 0;
      v_i2f.zero = 0;

      v_i2f.exponent_bias = 127;

      v_i2f.sign_uint = 0;
      if (v_i2f.op == 0) begin
        v_i2f.sign_uint = v_i2f.data[31];
      end

      if (v_i2f.sign_uint) begin
        v_i2f.data = -v_i2f.data;
      end

      v_i2f.mantissa_uint = 32'hFFFFFFFF;
      v_i2f.exponent_uint = 0;

      v_i2f.mantissa_uint = v_i2f.data[31:0];
      v_i2f.exponent_uint = 31;

      v_i2f.zero = ~|v_i2f.mantissa_uint;

      lzc_o.data = v_i2f.mantissa_uint;
      v_i2f.counter_uint = ~lzc_i.cnt;

      v_i2f.mantissa_uint = v_i2f.mantissa_uint << v_i2f.counter_uint;

      v_i2f.sign_rnd = v_i2f.sign_uint;
      v_i2f.exponent_rnd = {6'h0,v_i2f.exponent_uint} + {4'h0,v_i2f.exponent_bias} - {6'h0,v_i2f.counter_uint};

      v_i2f.mantissa_rnd = {1'h0, v_i2f.mantissa_uint[31:8]};
      v_i2f.grs = {v_i2f.mantissa_uint[7:6], |v_i2f.mantissa_uint[5:0]};

      fp_cvt_i2f_o.fpu_rnd.sig = v_i2f.sign_rnd;
      fp_cvt_i2f_o.fpu_rnd.expo = v_i2f.exponent_rnd;
      fp_cvt_i2f_o.fpu_rnd.mant = v_i2f.mantissa_rnd;
      fp_cvt_i2f_o.fpu_rnd.rema = 2'h0;
      fp_cvt_i2f_o.fpu_rnd.fmt = v_i2f.fmt;
      fp_cvt_i2f_o.fpu_rnd.rm = v_i2f.rm;
      fp_cvt_i2f_o.fpu_rnd.grs = v_i2f.grs;
      fp_cvt_i2f_o.fpu_rnd.snan = v_i2f.snan;
      fp_cvt_i2f_o.fpu_rnd.qnan = v_i2f.qnan;
      fp_cvt_i2f_o.fpu_rnd.dbz = v_i2f.dbz;
      fp_cvt_i2f_o.fpu_rnd.infs = v_i2f.infs;
      fp_cvt_i2f_o.fpu_rnd.zero = v_i2f.zero;
      fp_cvt_i2f_o.fpu_rnd.diff = 1'h0;

    end

    assign cvt_rnd_o = fp_cvt_i2f_o.fpu_rnd ;

    always_comb begin
      cvt_o = '0;
      if (cvt_reg_i.op.fcvt_i2f) begin
          cvt_o.result = cvt_rnd_i.result;
          cvt_o.flags = cvt_rnd_i.flags;
          cvt_o.tag = cvt_reg_i.tag;
      end else if (cvt_reg_i.op.fcvt_f2i) begin
          cvt_o.result = fp_cvt_f2i_o.result;
          cvt_o.flags = fp_cvt_f2i_o.flags;
          cvt_o.tag = cvt_reg_i.tag;
      end
    end

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (~rst_ni) begin
            cvt_reg_o <= '0;
            cvt_data_vld_o <= '0;
        end else if (cvt_stall_i) begin
            cvt_reg_o <= cvt_reg_o;
            cvt_data_vld_o <= cvt_data_vld_o;
        end else if (start_n) begin
            cvt_reg_o <= cvt_o;
            cvt_data_vld_o <= 1'b1;
        end else begin
            cvt_data_vld_o <= 1'b0;
        end
    end


endmodule
