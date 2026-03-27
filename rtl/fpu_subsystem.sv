module fpu_subsystem (
    //基础信号
    input  logic        clk,
    input  logic        rst_n,
    input  logic        clear,

    //指令与握手控制
    input  logic [31:0] instruction,
    input  logic        req_valid,
    output logic        req_ready,

    //来自CPU整数寄存器的数据
    input  logic [31:0] int_rs1_data,

    //数据输出
    output logic [31:0] int_rd_data,//需要写回CPU整数寄存器的数据
    output logic        int_rd_wr,
    output logic        fpu_finish,

    //CSR接口
    input  logic [31:0] csr_wdata,//CPU写入FCSR的数据
    input  logic        csr_wr,
    output logic [31:0] csr_rdata
);
  timeunit 1ns; timeprecision 1ps;

  fpu_top_in_type  top_i;
  fpu_top_out_type top_o;

  logic [2:0] frm_fcsr;

  logic [4:0] rs1_addr;
  logic [4:0] rs2_addr;
  logic [4:0] rs3_addr;
  logic [4:0] rd_addr;

  logic [31:0] fprf_rs1_data;
  logic use_int_rs1;
  logic fp_wr_o;
  logic wr;
  logic busy;

    //译码器
  fpu_decoder fpu_decoder_comp ( 
    .instruction (instruction),
    .frm_fcsr    (frm_fcsr),

    .rs1_addr    (rs1_addr),
    .rs2_addr    (rs2_addr),
    .rs3_addr    (rs3_addr),
    .rd_addr     (rd_addr),

    .op          (top_i.op),
    .fmt         (top_i.fmt),
    .rm          (top_i.rm),
    .fp_wr_o     (fp_wr_o),
    .int_wr_o    (int_rd_wr),
    .use_int_rs1 (use_int_rs1)  //是否使用整数操作数
  );

    //浮点寄存器堆(FPRF)
  fprf fprf_comp (
    .clk      (clk),
    .rst_n    (rst_n),

    .rs1_addr (rs1_addr),
    .rs2_addr (rs2_addr),
    .rs3_addr (rs3_addr),
    .rd_addr  (rd_addr),
    .wr       (wr),
    .wdata    (top_o.result),

    .rs1_data (fprf_rs1_data),
    .rs2_data (top_i.data2),
    .rs3_data (top_i.data3)
  );

    //浮点控制与状态寄存器（FCSR）
  fcsr fcsr_comp (
    .clk         (clk),
    .rst_n       (rst_n),

    .flags       (top_o.flags),
    .flags_wr    (top_o.ready),
    .csr_wdata   (csr_wdata),
    .csr_wr      (csr_wr),
    
    .frm_out     (frm_fcsr),
    .fcsr_data_o (csr_rdata)
  );

    //fpu_top
  fpu_top fpu_top_comp (
    .clk    (clk),
    .rst_n  (rst_n),
    .clear  (clear),
    .top_i  (top_i),
    .top_o  (top_o),
    .busy   (busy),
    .finish (fpu_finish)
  );

  always_comb begin

    req_ready = 0;
    wr = 0;

    if (use_int_rs1) begin
      top_i.data1 = int_rs1_data;
    end else begin
      top_i.data1 = fprf_rs1_data;
    end
  
    int_rd_data = top_o.result;

    if (req_valid) begin
      if (busy) begin
        req_ready = 0;
      end else begin
        req_ready = 1;
      end
    end else begin
      req_ready = 0;
    end

    if (fp_wr_o & fpu_finish) begin
      wr = 1;
    end else begin
      wr = 0;
    end

  end

endmodule