`timescale 1ns / 1ps
import fpu_define::*;

module tb_rv32f_fpu;

  // ==========================================
  // 2. 信号定义与时钟/复位生成
  // ==========================================
  logic clk_i;
  logic rst_ni;
  fpu_top_in_type  top_i;
  fpu_top_out_type top_o;

  // 生成 100MHz 时钟 (周期 10ns)
  initial begin
    clk_i = 0;
    forever #5 clk_i = ~clk_i;
  end

  // ==========================================
  // 3. 模块实例化 (DUT)
  // ==========================================
  fpu_top dut (
    .clk_i  (clk_i),
    .rst_ni (rst_ni),
    .top_i  (top_i),
    .top_o  (top_o)
  );

  // ==========================================
  // 4. 辅助 Task：发送激励与接收结果
  // ==========================================
  
  // 发送请求 Task (处理 Valid-Ready 握手)
  task automatic send_request(
    input fpu_operation_type op,
    input shortreal val1, // 直接传入浮点数
    input shortreal val2,
    input shortreal val3,
    input logic [4:0] tag
  );
    begin
      // 在时钟下降沿给数据，避免建立保持时间冲突
      @(negedge clk_i);
      top_i.req_valid_i = 1'b1;
      top_i.req_op_i    = op;
      top_i.req_data1_i = $shortrealtobits(val1); // 自动转为 IEEE 754 32bit
      top_i.req_data2_i = $shortrealtobits(val2);
      top_i.req_data3_i = $shortrealtobits(val3);
      top_i.req_rm_i    = 3'b000; // 默认舍入模式: RNE (Round to Nearest, ties to Even)
      top_i.req_tag_i   = tag;

      // 等待 DUT 给出 req_ready_o (握手成功)
      do begin
        @(posedge clk_i);
      end while (top_o.req_ready_o !== 1'b1);

      // 握手完成，撤销 Valid
      #1; 
      top_i.req_valid_i = 1'b0;
      top_i.req_op_i    = '0;
    end
  endtask

  // 等待结果 Task
  task automatic wait_response();
    begin
      // 等待 DUT 给出 resp_valid_o
      while (top_o.resp_valid_o !== 1'b1) begin
        @(posedge clk_i);
      end
      
      // 打印结果，将 IEEE 754 bits 还原为浮点数打印
      $display("Time: %0t | Tag: %0d | Result: %f | Flags: %b", 
                $time, top_o.resp_tag_o, $bitstoshortreal(top_o.resp_result_o), top_o.resp_flags_o);
    end
  endtask

  // ==========================================
  // 5. 顶层测试序列 (Test Sequence)
  // ==========================================
  fpu_operation_type op_cmd;

  initial begin
    // 初始化输入信号
    top_i = '0;
    rst_ni = 0;
    top_i.resp_ready_i = 1'b1; // TB 始终准备好接收数据

    // 释放复位
    #20 rst_ni = 1;
    #10;
    $display("--- 仿真开始 ---");

    // ----------------------------------------------------
    // 测试 1：基本加法 fadd (预计组合逻辑 1 拍，总共 2-3 拍后输出)
    // 计算: 12.5 + 5.25 = 17.75
    // ----------------------------------------------------
    op_cmd = '0;
    op_cmd.fadd = 1'b1;
    send_request(op_cmd, 12.5, 5.25, 0.0, 5'd1); // Tag=1
    wait_response();

    #20;

    // ----------------------------------------------------
    // 测试 2：乘加 fmadd (流水线 FMA 需要 4 个周期)
    // 计算: (2.0 * 3.5) + 1.5 = 8.5
    // ----------------------------------------------------
    op_cmd = '0;
    op_cmd.fmadd = 1'b1;
    send_request(op_cmd, 2.0, 3.5, 1.5, 5'd2); // Tag=2
    wait_response();

    #20;

    // ----------------------------------------------------
    // 测试 3：背靠背连续发送 (测试握手和流水线是否堵塞)
    // ----------------------------------------------------
    $display("--- 开始流水线连续测试 ---");
    fork
      // 线程 1：连续发请求
      begin
        op_cmd = '0; op_cmd.fsub = 1'b1;
        send_request(op_cmd, 10.0, 1.0, 0.0, 5'd3); // Tag=3
        op_cmd = '0; op_cmd.fmul = 1'b1;
        send_request(op_cmd, 3.0,  3.0, 0.0, 5'd4); // Tag=4
      end
      // 线程 2：接收两次结果
      begin
        wait_response();
        wait_response();
      end
    join

    #50;
    $display("--- 仿真结束 ---");
    $stop; // 暂停仿真，便于在波形图查看
  end

endmodule