import fpu_wire::*;

module fpu_decoder (
    input  logic [31:0] instruction,
    input  logic [2:0]  frm_fcsr,

    output logic [4:0]  rs1_addr,
    output logic [4:0]  rs2_addr,
    output logic [4:0]  rs3_addr,
    output logic [4:0]  rd_addr,

    output fpu_operation_type op,
    output logic [1:0]  fmt,
    output logic [2:0]  rm,
    output logic        fp_wr_o,
    output logic        int_wr_o,
    output logic        use_int_rs1
);
  timeunit 1ns; timeprecision 1ps;

  logic [4:0] funct;
  logic [4:0] rs3;
  logic [1:0] fmt_i;
  logic [4:0] rs2;
  logic [4:0] rs1;
  logic [2:0] rm_i;
  logic [4:0] rd;
  logic [6:0] opcode;

  always_comb begin

    funct  = instruction[31:27];
    rs3    = instruction[31:27];
    fmt_i  = instruction[26:25];
    rs2    = instruction[24:20];
    rs1    = instruction[19:15];
    rm_i   = instruction[14:12];
    rd     = instruction[11:7];
    opcode = instruction[6:0];

    rs1_addr = 0;
    rs2_addr = 0;
    rs3_addr = 0;
    rd_addr = 0;
    op = 0;
    fmt = 0;
    rm = 0;
    fp_wr_o = 0;
    int_wr_o = 0;
    use_int_rs1 = 0;

    if ((opcode == 7'b1010011) & (fmt_i == 0)) begin

      rs1_addr = rs1;
      rs2_addr = rs2;
      rd_addr = rd;
      fmt = fmt_i;
      rm = (rm_i == 3'b111)? frm_fcsr : rm_i;

      if (funct == 5'b00000) begin            //fadd
        op.fadd = 1;
        fp_wr_o = 1;
      end else if (funct == 5'b00001) begin   //fsub
        op.fsub = 1;
        fp_wr_o = 1;
      end else if (funct == 5'b00010) begin   //fmul
        op.fmul = 1;
        fp_wr_o = 1;
      end else if (funct == 5'b00011) begin   //fdiv
        op.fdiv = 1;
        fp_wr_o = 1;
      end else if (funct == 5'b01011) begin   //fsqrt
        op.fsqrt = 1;
        fp_wr_o = 1;
      end else if (funct == 5'b00100) begin   //fsgnj
        op.fsgnj = 1;
        fp_wr_o = 1;
      end else if (funct == 5'b00101) begin   //fmax
        op.fmax = 1;
        fp_wr_o = 1;
      end else if (funct == 5'b10100) begin   //fcmp
        op.fcmp = 1;
        int_wr_o = 1;
      end else if (funct == 5'b11000) begin   //fcvt_f2i
        op.fcvt_f2i = 1;
        op.fcvt_op = (rs2 == 0) ? 2'b00 : 2'b01;
        int_wr_o = 1;
      end else if (funct == 5'b11010) begin   //fcvt_i2f
        op.fcvt_i2f = 1;
        op.fcvt_op = (rs2 == 0) ? 2'b00 : 2'b01;
        use_int_rs1 = 1;
        fp_wr_o = 1;
      end else if (funct == 5'b11100) begin
        if (rm_i == 0) begin                  //fmv_f2i
          op.fmv_f2i = 1;
          int_wr_o = 1;
        end else if (rm_i == 1) begin         //fclass
          op.fclass = 1;
          int_wr_o = 1;
        end
      end else if (funct == 5'b11110) begin   //fmv_i2f
        op.fmv_i2f = 1;
        use_int_rs1 = 1;
        fp_wr_o = 1;
      end
    end else if ((opcode == 7'b1000011) & (fmt_i == 0)) begin  //fmadd
      rs1_addr = rs1;
      rs2_addr = rs2;
      rs3_addr = rs3;
      rd_addr = rd;
      op.fmadd = 1;
      fmt = fmt_i;
      rm = (rm_i == 3'b111)? frm_fcsr : rm_i;
      fp_wr_o = 1;
    end else if ((opcode == 7'b1000111) & (fmt_i == 0)) begin  //fmsub
      rs1_addr = rs1;
      rs2_addr = rs2;
      rs3_addr = rs3;
      rd_addr = rd;
      op.fmsub = 1;
      fmt = fmt_i;
      rm = (rm_i == 3'b111)? frm_fcsr : rm_i;
      fp_wr_o = 1;
    end else if ((opcode == 7'b1001011) & (fmt_i == 0)) begin  //fnmsub
      rs1_addr = rs1;
      rs2_addr = rs2;
      rs3_addr = rs3;
      rd_addr = rd;
      op.fnmsub = 1;
      fmt = fmt_i;
      rm = (rm_i == 3'b111)? frm_fcsr : rm_i;
      fp_wr_o = 1;      
    end else if ((opcode == 7'b1001111) & (fmt_i == 0)) begin  //fnmadd
      rs1_addr = rs1;
      rs2_addr = rs2;
      rs3_addr = rs3;
      rd_addr = rd;
      op.fnmadd = 1;
      fmt = fmt_i;
      rm = (rm_i == 3'b111)? frm_fcsr : rm_i;
      fp_wr_o = 1;
    end

  end

endmodule