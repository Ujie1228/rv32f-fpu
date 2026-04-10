import fpu_define::*;
import lzc_define::*;

module fpu_ext (
    input  logic [31:0] data_i,
    output logic [32:0] extend_o,
    output logic [9:0]  class_o,
    input  var lzc_32_out_type lzc_o,
    output var lzc_32_in_type  lzc_i
);

  logic [31:0] data;

  logic [31:0] mantissa;
  logic [4:0]  counter;

  logic [32:0] result;
  logic [9:0]  classification;

  logic mantissa_zero;
  logic exponent_zero;
  logic exponent_ones;
  
  always_comb begin

    data = data_i;

    mantissa = 32'hFFFFFFFF;
    counter = 0;

    result = 0;
    classification = 0;

    mantissa_zero = 0;
    exponent_zero = 0;
    exponent_ones = 0;

    exponent_zero = ~|data[30:23];
    exponent_ones = &data[30:23];
    mantissa_zero = ~|data[22:0];

    result[32] = data[31];

    if (exponent_ones) begin
      result[31:23] = 9'h1FF;
      result[22:0]  = data[22:0];
    end else if (exponent_zero == 0) begin  //规格化数（除0之外）
      result[31:23] = {1'h0, data[30:23]} + 9'h080;
      result[22:0]  = data[22:0];
    end else if (mantissa_zero == 0) begin  //非规格化数
      mantissa = {1'h0, data[22:0], 8'hFF};
      lzc_i.data = mantissa;
      counter = ~lzc_o.cnt;
      result[31:23] = 9'h081 - {4'h0, counter};
      result[22:0]  = (data[22:0] << counter);
    end
      

    if (result[32]) begin  //负数
      if (exponent_ones) begin
        if (mantissa_zero) begin
          classification[0] = 1;  //-Inf
        end else if (result[22] == 0) begin
          classification[8] = 1;  //sNaN
        end else begin
          classification[9] = 1;  //qNaN
        end
      end else if (exponent_zero) begin
        if (mantissa_zero) begin
          classification[3] = 1;  //-0
        end else begin
          classification[2] = 1;  //负非规格化数
        end
      end else begin
        classification[1] = 1;    //负规格化数
      end
    end else begin         //正数
      if (exponent_ones) begin
        if (mantissa_zero) begin
          classification[7] = 1;  //Inf
        end else if (result[22] == 0) begin
          classification[8] = 1;  //sNaN
        end else begin
          classification[9] = 1;  //qNaN
        end
      end else if (exponent_zero) begin
        if (mantissa_zero) begin
          classification[4] = 1;  //+0
        end else begin
          classification[5] = 1;  //正非规格化数
        end
      end else begin
        classification[6] = 1;    //正规格化数
      end
    end

    extend_o = result;
    class_o = classification;

  end

endmodule