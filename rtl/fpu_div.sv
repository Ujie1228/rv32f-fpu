import fpu_define::*;

module fpu_div #(
    parameter PERFORMANCE = 0
) (
    input logic clk_i,
    input logic rst_ni,

    input logic div_stall_i,
    input logic div_start_i,

    input  var fpu_div_in_type  fpu_fdiv_i,
    output var fpu_div_out_type fpu_fdiv_o,
    output var fpu_div_reg_out  div_reg_o,
    input  var fpu_mac_out_type fpu_mac_o,
    output var fpu_mac_in_type  fpu_mac_i,
    input  var fpu_rnd_out_type div_rnd_i,

    output logic div_ready_o,
    output logic div_data_vld_o,

    input logic div_reg_empty_i  // keep vld_o high until result is consumed
);

  localparam logic [2:0] DIV_IDLE   = 3'd0;
  localparam logic [2:0] DIV_ITER   = 3'd1;
  localparam logic [2:0] DIV_PRERND = 3'd2;
  localparam logic [2:0] DIV_RND    = 3'd3;
  localparam logic [2:0] DIV_OUT    = 3'd4;

  fpu_fdiv_reg_fixed_type r_fix;
  fpu_fdiv_reg_fixed_type rin_fix;

  // keep interface unchanged
  assign fpu_mac_i.a  = '0;
  assign fpu_mac_i.b  = '0;
  assign fpu_mac_i.c  = '0;
  assign fpu_mac_i.op = 1'b0;

  // keep original meaning: this signal only tells upstream whether DIV can accept a new request
  assign div_ready_o = ~div_stall_i;

  // --------------------------------------------------------------------------
  // next-state logic
  // --------------------------------------------------------------------------
  always_comb begin
    rin_fix = r_fix;

    case (r_fix.state)

      DIV_IDLE: begin
        rin_fix.ready = 1'b0;

        if (div_start_i) begin
          rin_fix = init_fpu_fdiv_reg_fixed;

          rin_fix.a       = fpu_fdiv_i.extend1;
          rin_fix.b       = fpu_fdiv_i.extend2;
          rin_fix.class_a = fpu_fdiv_i.class1;
          rin_fix.class_b = fpu_fdiv_i.class2;
          rin_fix.fmt     = 2'b00;
          rin_fix.rm      = fpu_fdiv_i.rm;

          if (fpu_fdiv_i.op.fdiv) begin
            rin_fix.state  = DIV_ITER;
            rin_fix.istate = 5'd25;
          end else if (fpu_fdiv_i.op.fsqrt) begin
            rin_fix.state  = DIV_ITER;
            rin_fix.istate = 5'd24;
          end else begin
            rin_fix.state  = DIV_IDLE;
            rin_fix.istate = '0;
          end

          rin_fix.snan = 1'b0;
          rin_fix.qnan = 1'b0;
          rin_fix.dbz  = 1'b0;
          rin_fix.infs = 1'b0;
          rin_fix.zero = 1'b0;
          rin_fix.ready = 1'b0;

          if (fpu_fdiv_i.op.fsqrt) begin
            rin_fix.b = 33'h07F800000;
            rin_fix.class_b = '0;
          end

          if (rin_fix.class_a[8] | rin_fix.class_b[8]) begin
            rin_fix.snan = 1'b1;
          end else if ((rin_fix.class_a[3] | rin_fix.class_a[4]) &
                       (rin_fix.class_b[3] | rin_fix.class_b[4])) begin
            rin_fix.snan = 1'b1;
          end else if ((rin_fix.class_a[0] | rin_fix.class_a[7]) &
                       (rin_fix.class_b[0] | rin_fix.class_b[7])) begin
            rin_fix.snan = 1'b1;
          end else if (rin_fix.class_a[9] | rin_fix.class_b[9]) begin
            rin_fix.qnan = 1'b1;
          end

          if ((rin_fix.class_a[0] | rin_fix.class_a[7]) &
              (rin_fix.class_b[1] | rin_fix.class_b[2] | rin_fix.class_b[3] |
               rin_fix.class_b[4] | rin_fix.class_b[5] | rin_fix.class_b[6])) begin
            rin_fix.infs = 1'b1;
          end else if ((rin_fix.class_b[3] | rin_fix.class_b[4]) &
                       (rin_fix.class_a[1] | rin_fix.class_a[2] |
                        rin_fix.class_a[5] | rin_fix.class_a[6])) begin
            rin_fix.dbz = 1'b1;
          end

          if ((rin_fix.class_a[3] | rin_fix.class_a[4]) |
              (rin_fix.class_b[0] | rin_fix.class_b[7])) begin
            rin_fix.zero = 1'b1;
          end

          if (fpu_fdiv_i.op.fsqrt) begin
            if (rin_fix.class_a[7]) begin
              rin_fix.infs = 1'b1;
            end
            if (rin_fix.class_a[0] | rin_fix.class_a[1] | rin_fix.class_a[2]) begin
              rin_fix.snan = 1'b1;
            end
          end

          rin_fix.sign_fdiv = rin_fix.a[32] ^ rin_fix.b[32];

          rin_fix.exponent_fdiv = {2'h0, rin_fix.a[31:23]} - {2'h0, rin_fix.b[31:23]};
          if (fpu_fdiv_i.op.fsqrt) begin
            rin_fix.exponent_fdiv =
                ($signed({2'h0, rin_fix.a[31:23]}) + $signed(-11'd253)) >>> 1;
          end

          rin_fix.q = '0;
          rin_fix.m = {4'h1, rin_fix.b[22:0], 1'h0};
          rin_fix.r = {5'h1, rin_fix.a[22:0]};
          rin_fix.op = 1'b0;

          if (fpu_fdiv_i.op.fsqrt) begin
            rin_fix.m = '0;
            if (rin_fix.a[23] == 1'b0) begin
              rin_fix.r = {rin_fix.r[26:0], 1'b0};
            end
            rin_fix.op = 1'b1;
          end
        end
      end

      DIV_ITER: begin
        rin_fix.ready = 1'b0;

        if (r_fix.op == 1'b1) begin
          rin_fix.m = {1'h0, r_fix.q, 1'h0};
          rin_fix.m[r_fix.istate] = 1'b1;
        end

        rin_fix.r = {r_fix.r[26:0], 1'b0};
        rin_fix.e = $signed(rin_fix.r) - $signed(rin_fix.m);

        // keep original behavior exactly
        if (rin_fix.e[26] == 1'b0) begin
          rin_fix.q[r_fix.istate] = 1'b1;
          rin_fix.r = rin_fix.e;
        end

        if (r_fix.istate == 0) begin
          rin_fix.state = DIV_PRERND;
        end else begin
          rin_fix.istate = r_fix.istate - 5'd1;
        end
      end

      DIV_PRERND: begin
        // compute pre-round data and store it into next-state
        // next cycle r_fix drives fpu_rnd and ready goes high
        rin_fix.state = DIV_RND;
        rin_fix.ready = 1'b1;

        rin_fix.mantissa_fdiv = {r_fix.q, r_fix.r[26:0], 25'h0};

        rin_fix.counter_fdiv = 2'd0;
        if (rin_fix.mantissa_fdiv[77] == 1'b0) begin
          rin_fix.counter_fdiv = 2'd1;
        end

        rin_fix.mantissa_fdiv = rin_fix.mantissa_fdiv << rin_fix.counter_fdiv;

        rin_fix.sign_rnd = r_fix.sign_fdiv;

        rin_fix.exponent_bias = 8'd127;

        rin_fix.exponent_rnd = r_fix.exponent_fdiv +
                               {3'h0, rin_fix.exponent_bias} -
                               {9'h0, rin_fix.counter_fdiv};

        rin_fix.counter_rnd = 11'd0;
        if ($signed(rin_fix.exponent_rnd) <= 0) begin
          rin_fix.counter_rnd = 11'd25;
          if ($signed(rin_fix.exponent_rnd) > -25) begin
            rin_fix.counter_rnd = 11'h1 - rin_fix.exponent_rnd;
          end
          rin_fix.exponent_rnd = 11'd0;
        end

        rin_fix.mantissa_fdiv = rin_fix.mantissa_fdiv >> rin_fix.counter_rnd[5:0];

        rin_fix.mantissa_rnd = {1'h0, rin_fix.mantissa_fdiv[77:54]};
        rin_fix.grs = {rin_fix.mantissa_fdiv[53:52], |(rin_fix.mantissa_fdiv[51:0])};
      end

      DIV_RND: begin
        // current-state r_fix is now driving a stable pre-round input into fpu_rnd
        // capture rounded result into next-state
        rin_fix.state = DIV_OUT;
        rin_fix.ready = 1'b0;

        rin_fix.result = div_rnd_i.result;
        rin_fix.flags  = div_rnd_i.flags;
      end

      DIV_OUT: begin
        // keep internal result until output register can accept it
        rin_fix.ready = 1'b0;
        if (div_reg_empty_i) begin
          rin_fix.state = DIV_IDLE;
        end else begin
          rin_fix.state = DIV_OUT;
        end
      end

      default: begin
        rin_fix = init_fpu_fdiv_reg_fixed;
      end
    endcase
  end

  // --------------------------------------------------------------------------
  // current-state output logic
  // --------------------------------------------------------------------------
  always_comb begin
    fpu_fdiv_o.fpu_rnd.sig  = r_fix.sign_rnd;
    fpu_fdiv_o.fpu_rnd.expo = r_fix.exponent_rnd;
    fpu_fdiv_o.fpu_rnd.mant = r_fix.mantissa_rnd;
    fpu_fdiv_o.fpu_rnd.rema = 2'h0;               // keep original fixed-path behavior
    fpu_fdiv_o.fpu_rnd.fmt  = r_fix.fmt;
    fpu_fdiv_o.fpu_rnd.rm   = r_fix.rm;
    fpu_fdiv_o.fpu_rnd.grs  = r_fix.grs;
    fpu_fdiv_o.fpu_rnd.snan = r_fix.snan;
    fpu_fdiv_o.fpu_rnd.qnan = r_fix.qnan;
    fpu_fdiv_o.fpu_rnd.dbz  = r_fix.dbz;
    fpu_fdiv_o.fpu_rnd.infs = r_fix.infs;
    fpu_fdiv_o.fpu_rnd.zero = r_fix.zero;
    fpu_fdiv_o.fpu_rnd.diff = 1'b0;
    fpu_fdiv_o.ready        = r_fix.ready;
  end

  // --------------------------------------------------------------------------
  // state register
  // --------------------------------------------------------------------------
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (~rst_ni) begin
      r_fix <= init_fpu_fdiv_reg_fixed;
    end else begin
      r_fix <= rin_fix;
    end
  end

  // --------------------------------------------------------------------------
  // output register / valid hold
  // --------------------------------------------------------------------------
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (~rst_ni) begin
      div_reg_o       <= '0;
      div_data_vld_o  <= 1'b0;
    end else if (~div_reg_empty_i) begin
      // keep output until it is consumed
      div_data_vld_o <= div_data_vld_o;
      div_reg_o      <= div_reg_o;
    end else if (r_fix.state == DIV_OUT) begin
      // current-state already holds rounded result
      div_reg_o.result <= r_fix.result;
      div_reg_o.flags  <= r_fix.flags;
      div_reg_o.tag    <= fpu_fdiv_i.tag;
      div_data_vld_o   <= 1'b1;
    end else begin
      div_data_vld_o <= 1'b0;
    end
  end

endmodule