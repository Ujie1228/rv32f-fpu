`timescale 1ns/1ps

import fpu_define::*;

module tb_fpu_fma;

  localparam time CLK_PERIOD = 10ns;
  localparam int  TIMEOUT_CYCLES = 400;
  localparam string VECTOR_FILE = "F:/git/program/f2/rv32f_fpu/result/fma_test_vectors.txt"; 

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
  // 时钟生成
  // --------------------------------------------------------------------------
  initial begin
    clk_i = 1'b0;
    forever #(CLK_PERIOD/2) clk_i = ~clk_i;
  end

  // --------------------------------------------------------------------------
  // FMA 字符串转操作数结构体映射
  // --------------------------------------------------------------------------
  function automatic fpu_operation_type get_op_from_string(string op_name);
    fpu_operation_type op;
    op = '0;
    if      (op_name == "FADD")   op.fadd   = 1'b1;
    else if (op_name == "FSUB")   op.fsub   = 1'b1;
    else if (op_name == "FMUL")   op.fmul   = 1'b1;
    else if (op_name == "FMADD")  op.fmadd  = 1'b1;
    else if (op_name == "FMSUB")  op.fmsub  = 1'b1;
    else if (op_name == "FNMADD") op.fnmadd = 1'b1;
    else if (op_name == "FNMSUB") op.fnmsub = 1'b1;
    else $display("WARNING: Unknown Operation string: %s", op_name);
    return op;
  endfunction

  // --------------------------------------------------------------------------
  // 基础任务
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
      if ((top_o.resp_tag_o   !== exp_tag   ) ||
          (top_o.resp_result_o !== exp_result) ||
          (top_o.resp_flags_o  !== exp_flags )) begin
        fail_count++;
        $display("[FAIL] %s", name);
        $display("       Expected: result=0x%08h flags=0x%0h", exp_result, exp_flags);
        $display("       Observed: result=0x%08h flags=0x%0h", top_o.resp_result_o, top_o.resp_flags_o);
      end else begin
        pass_count++;
        $display("[PASS] %s -> result=0x%08h flags=0x%0h",
                 name, top_o.resp_result_o, top_o.resp_flags_o);
      end
    end
  endtask

  // --------------------------------------------------------------------------
  // 核心执行任务 (处理握手协议)
  // --------------------------------------------------------------------------
  task automatic run_case(
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
    int timeout;

    begin
      tag = tag_seed[4:0];
      tag_seed++;

      top_i.req_op_i    = op;
      top_i.req_data1_i = data1;
      top_i.req_data2_i = data2;
      top_i.req_data3_i = data3;
      top_i.req_rm_i    = rm;
      top_i.req_tag_i   = tag;
      top_i.req_valid_i = 1'b0;

      // 等待 DUT 准备好 (req_ready_o == 1)
      timeout = 0;
      while (top_o.req_ready_o !== 1'b1) begin
        @(posedge clk_i);
        timeout++;
        if (timeout > TIMEOUT_CYCLES) begin
          fail_count++;
          $display("[FAIL] %s -> Request timeout! FMA pipeline might be stalled.", name);
          clear_req();
          return;
        end
      end

      top_i.req_valid_i = 1'b1;
      @(posedge clk_i);
      top_i.req_valid_i = 1'b0;
      clear_req();

      // 等待 DUT 输出结果 (resp_valid_o == 1)
      timeout = 0;
      while (top_o.resp_valid_o !== 1'b1) begin
        @(posedge clk_i);
        timeout++;
        if (timeout > TIMEOUT_CYCLES) begin
          fail_count++;
          $display("[FAIL] %s -> Response timeout! FMA didn't finish execution.", name);
          return;
        end
      end

      // 接收响应并比对
      top_i.resp_ready_i = 1'b1;
      @(posedge clk_i);
      compare_response(name, tag, exp_result, exp_flags);

      @(posedge clk_i);
    end
  endtask

  // --------------------------------------------------------------------------
  // 文件解析与测试驱动任务
  // --------------------------------------------------------------------------
  task automatic run_fma_tests_from_file();
    int fd;
    string line;
    int scan_items;
    
    // 解析变量
    string op_str;
    logic [2:0] rm;
    logic [31:0] d1, d2, d3, exp_res;
    logic [4:0] exp_flags;
    
    int line_num = 0;
    string case_name;

    begin
      // 尝试打开文件
      fd = $fopen(VECTOR_FILE, "r");
      if (fd == 0) begin
        $display("============================================================");
        $display("FATAL ERROR: Could not open file '%s'", VECTOR_FILE);
        $display("Make sure the path is absolute or correct relative to the sim directory.");
        $display("============================================================");
        $finish;
      end

      $display("\n---- RUNNING FMA TESTS FROM %s ----", VECTOR_FILE);

      // 逐行解析
      while (!$feof(fd)) begin
        if ($fgets(line, fd)) begin
          line_num++;
          
          // 跳过空行和注释行（"//"开头）
          if (line.len() <= 1) continue;
          if (line[0] == "/" && line[1] == "/") continue;

          // 提取格式化数据: %s(字符串) %x(16进制)
          scan_items = $sscanf(line, "%s %x %x %x %x %x %x", 
                               op_str, rm, d1, d2, d3, exp_res, exp_flags);
          
          if (scan_items == 7) begin
            $sformat(case_name, "Line%0d_%s", line_num, op_str);
            run_case(case_name, get_op_from_string(op_str), d1, d2, d3, rm, exp_res, exp_flags);
          end else begin
            $display("WARNING: Parse error on line %0d: %s", line_num, line);
          end
        end
      end
      $fclose(fd);
    end
  endtask

  // --------------------------------------------------------------------------
  // Main
  // --------------------------------------------------------------------------
  initial begin
    top_i = '0;
    top_i.resp_ready_i = 1'b1;

    reset_dut();

    // 运行基于文本数据的 FMA 测试
    run_fma_tests_from_file();

    $display("============================================================");
    $display("FMA TEST SUMMARY: PASS=%0d FAIL=%0d", pass_count, fail_count);
    $display("============================================================");

    if (fail_count == 0) begin
      $display("ALL FMA TESTS PASSED SUCCESSFULLY");
    end else begin
      $display("WARNING: SOME FMA TESTS FAILED!");
    end

    repeat (10) @(posedge clk_i);
    $finish;
  end

endmodule