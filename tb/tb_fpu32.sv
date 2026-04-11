`timescale 1ns/1ps

import fpu_define::*;

module tb_fpu_top;

  localparam time CLK_PERIOD = 10ns;
  localparam int  TIMEOUT_CYCLES = 400;

  logic clk_i;
  logic rst_ni;

  fpu_top_in_type  top_i;
  fpu_top_out_type top_o;

  int pass_count;
  int fail_count;
  int tag_seed;

  fpu_top dut (
    .clk_i  (clk_i),
    .rst_ni (rst_ni),
    .top_i  (top_i),
    .top_o  (top_o)
  );

  // --------------------------------------------------------------------------
  // Clock
  // --------------------------------------------------------------------------
  initial begin
    clk_i = 1'b0;
    forever #(CLK_PERIOD/2) clk_i = ~clk_i;
  end

  // --------------------------------------------------------------------------
  // Common IEEE-754 single constants
  // --------------------------------------------------------------------------
  localparam logic [31:0] F_PZERO    = 32'h00000000;
  localparam logic [31:0] F_NZERO    = 32'h80000000;
  localparam logic [31:0] F_HALF     = 32'h3F000000;
  localparam logic [31:0] F_ONE      = 32'h3F800000;
  localparam logic [31:0] F_ONEP5    = 32'h3FC00000;
  localparam logic [31:0] F_TWO      = 32'h40000000;
  localparam logic [31:0] F_THREE    = 32'h40400000;
  localparam logic [31:0] F_FOUR     = 32'h40800000;
  localparam logic [31:0] F_SIX      = 32'h40C00000;
  localparam logic [31:0] F_TEN      = 32'h41200000;
  localparam logic [31:0] F_NEG_ONE  = 32'hBF800000;
  localparam logic [31:0] F_NEG_TWO  = 32'hC0000000;
  localparam logic [31:0] F_NEG_TEN  = 32'hC1200000;
  localparam logic [31:0] F_INF      = 32'h7F800000;
  localparam logic [31:0] F_NINF     = 32'hFF800000;
  localparam logic [31:0] F_QNAN     = 32'h7FC00000;
  localparam logic [31:0] F_SNAN     = 32'h7FA00000;
  localparam logic [31:0] F_MIN_SUB  = 32'h00000001;

  // --------------------------------------------------------------------------
  // Helpers: op constructors
  // --------------------------------------------------------------------------
  function automatic fpu_operation_type op_none();
    fpu_operation_type op;
    op = '0;
    return op;
  endfunction

  function automatic fpu_operation_type op_fadd();
    fpu_operation_type op;
    op = '0;
    op.fadd = 1'b1;
    return op;
  endfunction

  function automatic fpu_operation_type op_fsub();
    fpu_operation_type op;
    op = '0;
    op.fsub = 1'b1;
    return op;
  endfunction

  function automatic fpu_operation_type op_fmul();
    fpu_operation_type op;
    op = '0;
    op.fmul = 1'b1;
    return op;
  endfunction

  function automatic fpu_operation_type op_fmadd();
    fpu_operation_type op;
    op = '0;
    op.fmadd = 1'b1;
    return op;
  endfunction

  function automatic fpu_operation_type op_fmsub();
    fpu_operation_type op;
    op = '0;
    op.fmsub = 1'b1;
    return op;
  endfunction

  function automatic fpu_operation_type op_fnmadd();
    fpu_operation_type op;
    op = '0;
    op.fnmadd = 1'b1;
    return op;
  endfunction

  function automatic fpu_operation_type op_fnmsub();
    fpu_operation_type op;
    op = '0;
    op.fnmsub = 1'b1;
    return op;
  endfunction

  function automatic fpu_operation_type op_fdiv();
    fpu_operation_type op;
    op = '0;
    op.fdiv = 1'b1;
    return op;
  endfunction

  function automatic fpu_operation_type op_fsqrt();
    fpu_operation_type op;
    op = '0;
    op.fsqrt = 1'b1;
    return op;
  endfunction

  function automatic fpu_operation_type op_fsgnj();
    fpu_operation_type op;
    op = '0;
    op.fsgnj = 1'b1;
    return op;
  endfunction

  function automatic fpu_operation_type op_fcmp();
    fpu_operation_type op;
    op = '0;
    op.fcmp = 1'b1;
    return op;
  endfunction

  function automatic fpu_operation_type op_fmax();
    fpu_operation_type op;
    op = '0;
    op.fmax = 1'b1;
    return op;
  endfunction

  function automatic fpu_operation_type op_fclass();
    fpu_operation_type op;
    op = '0;
    op.fclass = 1'b1;
    return op;
  endfunction

  function automatic fpu_operation_type op_fcvt_i2f(input bit is_unsigned);
    fpu_operation_type op;
    op = '0;
    op.fcvt_i2f = 1'b1;
    op.fcvt_op  = is_unsigned;
    return op;
  endfunction

  function automatic fpu_operation_type op_fcvt_f2i(input bit is_unsigned);
    fpu_operation_type op;
    op = '0;
    op.fcvt_f2i = 1'b1;
    op.fcvt_op  = is_unsigned;
    return op;
  endfunction

  // --------------------------------------------------------------------------
  // Helper tasks
  // --------------------------------------------------------------------------
  task automatic clear_req();
    top_i.req_valid_i = 1'b0;
    top_i.req_op_i    = '0;
    top_i.req_data1_i = '0;
    top_i.req_data2_i = '0;
    top_i.req_data3_i = '0;
    top_i.req_rm_i    = '0;
    top_i.req_tag_i   = '0;
  endtask

  task automatic reset_dut();
    begin
      top_i = '0;
      rst_ni = 1'b0;
      pass_count = 0;
      fail_count = 0;
      tag_seed   = 0;
      repeat (8) @(posedge clk_i);
      rst_ni = 1'b1;
      repeat (4) @(posedge clk_i);
    end
  endtask

  task automatic compare_response(
    input string       name,
    input logic [4:0]  exp_tag,
    input logic [31:0] exp_result,
    input logic [4:0]  exp_flags
  );
    begin
      #1;
      if ((top_o.resp_tag_o    !== exp_tag   ) ||
          (top_o.resp_result_o !== exp_result) ||
          (top_o.resp_flags_o  !== exp_flags )) begin
        fail_count++;
        $display("[FAIL] %s", name);
        $display("       expected tag=0x%0h result=0x%08h flags=0x%0h", exp_tag, exp_result, exp_flags);
        $display("       observed tag=0x%0h result=0x%08h flags=0x%0h", top_o.resp_tag_o, top_o.resp_result_o, top_o.resp_flags_o);
      end else begin
        pass_count++;
        $display("[PASS] %s -> tag=0x%0h result=0x%08h flags=0x%0h",
                 name, top_o.resp_tag_o, top_o.resp_result_o, top_o.resp_flags_o);
      end
    end
  endtask

  task automatic run_case(
    input string             name,
    input fpu_operation_type op,
    input logic [31:0]       data1,
    input logic [31:0]       data2,
    input logic [31:0]       data3,
    input logic [2:0]        rm,
    input logic [31:0]       exp_result,
    input logic [4:0]        exp_flags,
    input int                hold_resp_cycles = 0
  );
    logic [4:0] tag;
    int timeout;

    begin
      tag = tag_seed[4:0];
      tag_seed++;

      // Prepare request fields first, because req_ready depends on req_op_i.
      top_i.req_op_i    = op;
      top_i.req_data1_i = data1;
      top_i.req_data2_i = data2;
      top_i.req_data3_i = data3;
      top_i.req_rm_i    = rm;
      top_i.req_tag_i   = tag;
      top_i.req_valid_i = 1'b0;

      // Wait until request side is ready for this op class.
      timeout = 0;
      while (top_o.req_ready_o !== 1'b1) begin
        @(posedge clk_i);
        timeout++;
        if (timeout > TIMEOUT_CYCLES) begin
          fail_count++;
          $display("[FAIL] %s -> request timeout", name);
          clear_req();
          return;
        end
      end

      // Send one-cycle request.
      top_i.req_valid_i = 1'b1;
      @(posedge clk_i);
      top_i.req_valid_i = 1'b0;

      // Clear request payload after handshake.
      top_i.req_op_i    = '0;
      top_i.req_data1_i = '0;
      top_i.req_data2_i = '0;
      top_i.req_data3_i = '0;
      top_i.req_rm_i    = '0;
      top_i.req_tag_i   = '0;

      // Optional response backpressure.
      if (hold_resp_cycles > 0)
        top_i.resp_ready_i = 1'b0;
      else
        top_i.resp_ready_i = 1'b1;

      timeout = 0;
      while (top_o.resp_valid_o !== 1'b1) begin
        @(posedge clk_i);
        timeout++;
        if (timeout > TIMEOUT_CYCLES) begin
          fail_count++;
          $display("[FAIL] %s -> response timeout", name);
          top_i.resp_ready_i = 1'b1;
          return;
        end
      end

      // Hold backpressure and verify resp_valid stays asserted.
      repeat (hold_resp_cycles) begin
        #1;
        if (top_o.resp_valid_o !== 1'b1) begin
          fail_count++;
          $display("[FAIL] %s -> resp_valid dropped during backpressure", name);
          top_i.resp_ready_i = 1'b1;
          return;
        end
        @(posedge clk_i);
      end

      // Accept response.
      top_i.resp_ready_i = 1'b1;
      @(posedge clk_i);
      compare_response(name, tag, exp_result, exp_flags);

      // Leave one clean cycle.
      @(posedge clk_i);
    end
  endtask

  // --------------------------------------------------------------------------
  // Test suites
  // --------------------------------------------------------------------------
  task automatic test_fma_suite();
    begin
      $display("---- FMA SUITE ----");

      run_case("fadd_1p0_plus_2p0",
               op_fadd(), F_ONE, F_TWO, F_PZERO, 3'd0,
               F_THREE, 5'b00000);

      run_case("fsub_1p0_minus_2p0",
               op_fsub(), F_ONE, F_TWO, F_PZERO, 3'd0,
               F_NEG_ONE, 5'b00000);

      run_case("fmul_2p0_mul_3p0",
               op_fmul(), F_TWO, F_THREE, F_PZERO, 3'd0,
               F_SIX, 5'b00000);

      run_case("fmadd_2p0_3p0_4p0",
               op_fmadd(), F_TWO, F_THREE, F_FOUR, 3'd0,
               F_TEN, 5'b00000);

      run_case("fmsub_2p0_3p0_4p0",
               op_fmsub(), F_TWO, F_THREE, F_FOUR, 3'd0,
               F_TWO, 5'b00000);

      run_case("fnmadd_2p0_3p0_4p0",
               op_fnmadd(), F_TWO, F_THREE, F_FOUR, 3'd0,
               F_NEG_TEN, 5'b00000);

      run_case("fnmsub_2p0_3p0_4p0",
               op_fnmsub(), F_TWO, F_THREE, F_FOUR, 3'd0,
               F_NEG_TWO, 5'b00000);

      run_case("fmul_zero_mul_inf_invalid",
               op_fmul(), F_PZERO, F_INF, F_PZERO, 3'd0,
               F_QNAN, 5'b10000);

      run_case("fadd_inf_plus_one",
               op_fadd(), F_INF, F_ONE, F_PZERO, 3'd0,
               F_INF, 5'b00000);
    end
  endtask

  task automatic test_div_suite();
    begin
      $display("---- DIV SUITE ----");

      run_case("fdiv_6p0_div_3p0",
               op_fdiv(), F_SIX, F_THREE, F_PZERO, 3'd0,
               F_TWO, 5'b00000);

      run_case("fdiv_1p0_div_0p0",
               op_fdiv(), F_ONE, F_PZERO, F_PZERO, 3'd0,
               F_INF, 5'b01000);

      run_case("fdiv_0p0_div_0p0_invalid",
               op_fdiv(), F_PZERO, F_PZERO, F_PZERO, 3'd0,
               F_QNAN, 5'b10000);

      run_case("fsqrt_4p0",
               op_fsqrt(), F_FOUR, F_PZERO, F_PZERO, 3'd0,
               F_TWO, 5'b00000);

      run_case("fsqrt_neg1_invalid",
               op_fsqrt(), F_NEG_ONE, F_PZERO, F_PZERO, 3'd0,
               F_QNAN, 5'b10000);
    end
  endtask

  task automatic test_misc_suite();
    begin
      $display("---- MISC SUITE ----");

      // sgnj family, rm=0/1/2
      run_case("fsgnj_copy_sign",
               op_fsgnj(), F_NEG_ONE, F_TWO, F_PZERO, 3'd0,
               F_ONE, 5'b00000);

      run_case("fsgnjn_invert_sign",
               op_fsgnj(), F_NEG_ONE, F_TWO, F_PZERO, 3'd1,
               F_NEG_ONE, 5'b00000);

      run_case("fsgnjx_xor_sign",
               op_fsgnj(), F_NEG_ONE, F_TWO, F_PZERO, 3'd2,
               F_NEG_ONE, 5'b00000);

      // fcmp: rm=0 fle, rm=1 flt, rm=2 feq
      run_case("fle_1p0_le_2p0",
               op_fcmp(), F_ONE, F_TWO, F_PZERO, 3'd0,
               32'h00000001, 5'b00000);

      run_case("flt_2p0_lt_1p0",
               op_fcmp(), F_TWO, F_ONE, F_PZERO, 3'd1,
               32'h00000000, 5'b00000);

      run_case("feq_pzero_eq_nzero",
               op_fcmp(), F_PZERO, F_NZERO, F_PZERO, 3'd2,
               32'h00000001, 5'b00000);

      // fmax op with rm=0(min), rm=1(max) in this RTL
      run_case("fmin_1p0_neg2p0",
               op_fmax(), F_ONE, F_NEG_TWO, F_PZERO, 3'd0,
               F_NEG_TWO, 5'b00000);

      run_case("fmax_1p0_neg2p0",
               op_fmax(), F_ONE, F_NEG_TWO, F_PZERO, 3'd1,
               F_ONE, 5'b00000);

      // fclass low 10 bits
      run_case("fclass_pzero",
               op_fclass(), F_PZERO, F_PZERO, F_PZERO, 3'd0,
               32'h00000010, 5'b00000);

      run_case("fclass_ninf",
               op_fclass(), F_NINF, F_PZERO, F_PZERO, 3'd0,
               32'h00000001, 5'b00000);

      run_case("fclass_qnan",
               op_fclass(), F_QNAN, F_PZERO, F_PZERO, 3'd0,
               32'h00000200, 5'b00000);
    end
  endtask

  task automatic test_cvt_suite();
    begin
      $display("---- CVT SUITE ----");

      // i2f signed
      run_case("fcvt_i2f_s_0",
               op_fcvt_i2f(1'b0), 32'h00000000, F_PZERO, F_PZERO, 3'd0,
               F_PZERO, 5'b00000);

      run_case("fcvt_i2f_s_1",
               op_fcvt_i2f(1'b0), 32'h00000001, F_PZERO, F_PZERO, 3'd0,
               F_ONE, 5'b00000);

      run_case("fcvt_i2f_s_neg1",
               op_fcvt_i2f(1'b0), 32'hFFFFFFFF, F_PZERO, F_PZERO, 3'd0,
               F_NEG_ONE, 5'b00000);

      // i2f unsigned
      run_case("fcvt_i2f_u_2pow31",
               op_fcvt_i2f(1'b1), 32'h80000000, F_PZERO, F_PZERO, 3'd0,
               32'h4F000000, 5'b00000);

      // f2i signed
      run_case("fcvt_f2i_s_0p0",
               op_fcvt_f2i(1'b0), F_PZERO, F_PZERO, F_PZERO, 3'd0,
               32'h00000000, 5'b00000);

      run_case("fcvt_f2i_s_1p0",
               op_fcvt_f2i(1'b0), F_ONE, F_PZERO, F_PZERO, 3'd0,
               32'h00000001, 5'b00000);

      run_case("fcvt_f2i_s_neg1p0",
               op_fcvt_f2i(1'b0), F_NEG_ONE, F_PZERO, F_PZERO, 3'd0,
               32'hFFFFFFFF, 5'b00000);

      run_case("fcvt_f2i_s_1p5_rne",
               op_fcvt_f2i(1'b0), F_ONEP5, F_PZERO, F_PZERO, 3'd0,
               32'h00000002, 5'b00001);

      run_case("fcvt_f2i_s_1p5_rtz",
               op_fcvt_f2i(1'b0), F_ONEP5, F_PZERO, F_PZERO, 3'd1,
               32'h00000001, 5'b00001);

      // f2i unsigned
      run_case("fcvt_f2i_u_2p0",
               op_fcvt_f2i(1'b1), F_TWO, F_PZERO, F_PZERO, 3'd0,
               32'h00000002, 5'b00000);

      run_case("fcvt_f2i_u_2pow31",
               op_fcvt_f2i(1'b1), 32'h4F000000, F_PZERO, F_PZERO, 3'd0,
               32'h80000000, 5'b00000);
    end
  endtask

  task automatic test_backpressure_suite();
    begin
      $display("---- BACKPRESSURE SUITE ----");

      run_case("bp_fadd_hold_3",
               op_fadd(), F_ONE, F_TWO, F_PZERO, 3'd0,
               F_THREE, 5'b00000, 3);

      run_case("bp_fcvt_i2f_hold_2",
               op_fcvt_i2f(1'b0), 32'h00000001, F_PZERO, F_PZERO, 3'd0,
               F_ONE, 5'b00000, 2);

      run_case("bp_fdiv_hold_4",
               op_fdiv(), F_SIX, F_THREE, F_PZERO, 3'd0,
               F_TWO, 5'b00000, 4);

      run_case("bp_fclass_hold_2",
               op_fclass(), F_QNAN, F_PZERO, F_PZERO, 3'd0,
               32'h00000200, 5'b00000, 2);
    end
  endtask

  // --------------------------------------------------------------------------
  // Main
  // --------------------------------------------------------------------------
  initial begin
    top_i = '0;
    top_i.resp_ready_i = 1'b1;

    reset_dut();

    test_fma_suite();
    test_div_suite();
    test_misc_suite();
    test_cvt_suite();
    test_backpressure_suite();

    $display("============================================================");
    $display("TEST SUMMARY: PASS=%0d FAIL=%0d", pass_count, fail_count);
    $display("============================================================");

    if (fail_count == 0) begin
      $display("ALL TESTS PASSED");
    end else begin
      $display("SOME TESTS FAILED");
    end

    repeat (10) @(posedge clk_i);
    $finish;
  end

endmodule