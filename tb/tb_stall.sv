`timescale 1ns/1ps

import fpu_define::*;

module tb_stall;

  localparam time CLK_PERIOD = 10ns;
  localparam int  TIMEOUT_CYCLES = 1000; 

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
  localparam logic [31:0] F_ONE      = 32'h3F800000;
  localparam logic [31:0] F_TWO      = 32'h40000000;
  localparam logic [31:0] F_THREE    = 32'h40400000;
  localparam logic [31:0] F_FOUR     = 32'h40800000;
  localparam logic [31:0] F_SIX      = 32'h40C00000;
  localparam logic [31:0] F_TEN      = 32'h41200000;
  localparam logic [31:0] F_NEG_ONE  = 32'hBF800000;
  localparam logic [31:0] F_NEG_TWO  = 32'hC0000000;
  localparam logic [31:0] F_QNAN     = 32'h7FC00000;

  // --------------------------------------------------------------------------
  // Helpers: op constructors
  // --------------------------------------------------------------------------
  function automatic fpu_operation_type op_fadd();
    fpu_operation_type op; op = '0; op.fadd = 1'b1; return op;
  endfunction

  function automatic fpu_operation_type op_fsub();
    fpu_operation_type op; op = '0; op.fsub = 1'b1; return op;
  endfunction

  function automatic fpu_operation_type op_fmul();
    fpu_operation_type op; op = '0; op.fmul = 1'b1; return op;
  endfunction

  function automatic fpu_operation_type op_fmadd();
    fpu_operation_type op; op = '0; op.fmadd = 1'b1; return op;
  endfunction

  function automatic fpu_operation_type op_fdiv();
    fpu_operation_type op; op = '0; op.fdiv = 1'b1; return op;
  endfunction

  function automatic fpu_operation_type op_fclass();
    fpu_operation_type op; op = '0; op.fclass = 1'b1; return op;
  endfunction

  function automatic fpu_operation_type op_fmax();
    fpu_operation_type op; op = '0; op.fmax = 1'b1; return op;
  endfunction

  function automatic fpu_operation_type op_fcvt_i2f(input bit is_unsigned);
    fpu_operation_type op; op = '0; op.fcvt_i2f = 1'b1; op.fcvt_op = is_unsigned; return op;
  endfunction

  // --------------------------------------------------------------------------
  // 动态记分板结构
  // --------------------------------------------------------------------------
  typedef struct {
    string       name;
    logic [31:0] exp_result;
    logic [4:0]  exp_flags;
  } exp_data_t;

  exp_data_t exp_scoreboard[logic [4:0]];

  // --------------------------------------------------------------------------
  // Helper tasks
  // --------------------------------------------------------------------------
  task automatic reset_dut();
    begin
      top_i = '0;
      rst_ni = 1'b0;
      pass_count = 0;
      fail_count = 0;
      tag_seed   = 1;
      exp_scoreboard.delete();
      repeat (8) @(posedge clk_i);
      rst_ni = 1'b1;
      repeat (4) @(posedge clk_i);
    end
  endtask

  // 【优化点】：取消任务内的延迟和直接嗅探，改为接收从外层同步采样送进来的观测值
  task automatic compare_response(
    input string       name,
    input logic [4:0]  tag,
    input logic [31:0] exp_result,
    input logic [4:0]  exp_flags,
    input logic [31:0] obs_result, // 同步抓取到的真实 result
    input logic [4:0]  obs_flags   // 同步抓取到的真实 flags
  );
    begin
      // 纯逻辑判断，去掉了 #1，保证时序严格对齐
      if ((obs_result !== exp_result) || (obs_flags !== exp_flags)) begin
        fail_count++;
        $display("[FAIL] %s (Tag: 0x%0h)", name, tag);
        $display("       Expected: result=0x%08h flags=0x%0h", exp_result, exp_flags);
        $display("       Observed: result=0x%08h flags=0x%0h", obs_result, obs_flags);
      end else begin
        pass_count++;
        $display("[PASS] %s -> tag=0x%0h result=0x%08h flags=0x%0h",
                 name, tag, obs_result, obs_flags);
      end
    end
  endtask

  // --------------------------------------------------------------------------
  // 发送端
  // --------------------------------------------------------------------------
  task automatic issue_req(
    input string             name,
    input fpu_operation_type op,
    input logic [31:0]       data1,
    input logic [31:0]       data2,
    input logic [31:0]       data3,
    input logic [2:0]        rm,
    input logic [31:0]       exp_result,
    input logic [4:0]        exp_flags
  );
    logic [4:0] tag;
    begin
      tag = tag_seed[4:0];
      tag_seed++;

      exp_scoreboard[tag] = '{name: name, exp_result: exp_result, exp_flags: exp_flags};

      top_i.req_op_i    = op;
      top_i.req_data1_i = data1;
      top_i.req_data2_i = data2;
      top_i.req_data3_i = data3;
      top_i.req_rm_i    = rm;
      top_i.req_tag_i   = tag;
      top_i.req_valid_i = 1'b1;

      do begin
        @(posedge clk_i);
      end while (top_o.req_ready_o !== 1'b1);

      top_i.req_valid_i = 1'b0;
    end
  endtask

  // --------------------------------------------------------------------------
  // 并发连续注入与严格同周期乱序检查 (适配 Valid 提前一拍的流水线延迟)
  // --------------------------------------------------------------------------
  task automatic test_continuous_stall_suite();
    int total_ops = 8;
    
    begin
      $display("\n---- OUT-OF-ORDER SUITE (1-CYCLE DELAY SAMPLING) ----");
      
      fork
        // ---------------------------------
        // 线程 1: 发送 (Producer)
        // ---------------------------------
        begin
          issue_req("pipe_add1", op_fadd(), F_ONE, F_TWO, F_PZERO, 3'd0, F_THREE, 5'b00000);
          issue_req("pipe_sub1", op_fsub(), F_THREE, F_ONE, F_PZERO, 3'd0, F_TWO, 5'b00000);
          issue_req("pipe_mul1", op_fmul(), F_TWO, F_THREE, F_PZERO, 3'd0, F_SIX, 5'b00000);
          issue_req("pipe_div1", op_fdiv(), F_SIX, F_TWO, F_PZERO, 3'd0, F_THREE, 5'b00000); 
          issue_req("pipe_madd1",op_fmadd(), F_TWO, F_THREE, F_FOUR, 3'd0, F_TEN, 5'b00000);
          issue_req("pipe_class",op_fclass(), F_QNAN, F_PZERO, F_PZERO, 3'd0, 32'h200, 5'b00000);
          issue_req("pipe_cvt_i",op_fcvt_i2f(1'b0), 32'h00000001, F_PZERO, F_PZERO, 3'd0, F_ONE, 5'b00000);
          issue_req("pipe_fmax", op_fmax(), F_ONE, F_NEG_TWO, F_PZERO, 3'd1, F_ONE, 5'b00000);
        end

        // ---------------------------------
        // 线程 2: 接收 (Consumer)
        // ---------------------------------
        begin
          int received = 0;
          exp_data_t exp;
          
          logic [4:0]  obs_tag;
          logic [31:0] obs_result;
          logic [4:0]  obs_flags;
          int timeout = 0;

          // 【新增】：用于打拍延迟的 valid 信号寄存器
          logic valid_q = 1'b0; 

          top_i.resp_ready_i = 1'b1; 

          // 确保复位已撤销后再开始采样
          wait(rst_ni === 1'b1);

          while (received < total_ops) begin
            @(posedge clk_i);
            timeout++;

            // 1. 数据采样阶段：如果【上一拍】的 valid_q 是 1，说明【这一拍】的数据是有效的
            if (valid_q === 1'b1) begin
              obs_tag    = top_o.resp_tag_o;
              obs_result = top_o.resp_result_o;
              obs_flags  = top_o.resp_flags_o;

              timeout = 0; // 收到有效数据，清零超时计数器
              
              // 过滤掉复位或空闲时总线上残留的 Tag 0（可选安全机制）
              if (obs_tag !== 5'h0) begin
                if (exp_scoreboard.exists(obs_tag)) begin
                  exp = exp_scoreboard[obs_tag]; 
                  compare_response(exp.name, obs_tag, exp.exp_result, exp.exp_flags, obs_result, obs_flags);
                  exp_scoreboard.delete(obs_tag); 
                  received++;
                end else begin
                  $display("[FAIL] Unexpected Tag received: 0x%0h", obs_tag);
                  fail_count++;
                  received++; // 防止死循环卡死
                end
              end else begin
                  $display("[DEBUG] Ignored spurious Tag 0 at time %t", $time);
              end
            end

            // 2. 状态更新阶段：采样【当前拍】的 valid 信号，存入 valid_q，供【下一拍】使用
            valid_q = top_o.resp_valid_o;

            // 超时检测
            if (timeout > TIMEOUT_CYCLES * 10) begin
              $display("[FAIL] Timeout! Received only %0d/%0d results.", received, total_ops);
              fail_count++;
              break;
            end
          end
        end
      join
    end
  endtask

  // --------------------------------------------------------------------------
  // Main
  // --------------------------------------------------------------------------
  initial begin
    top_i = '0;
    top_i.resp_ready_i = 1'b1;

    reset_dut();

    test_continuous_stall_suite();

    $display("============================================================");
    $display("TEST SUMMARY: PASS=%0d FAIL=%0d", pass_count, fail_count);
    $display("============================================================");

    if (fail_count == 0) begin
      $display("ALL PIPELINE TESTS PASSED (Perfect Synchronous Out-of-Order Match)");
    end else begin
      $display("SOME TESTS FAILED - Please review RTL output timing logic");
    end

    repeat (10) @(posedge clk_i);
    $finish;
  end

endmodule