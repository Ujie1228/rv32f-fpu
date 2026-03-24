import fpu_wire::*;

module fpu_max (
    input  fpu_max_in_type   max_i,
    output fpu_max_out_type  max_o
);
  timeunit 1ns; timeprecision 1ps;

  localparam logic [31:0] nan = 32'h7FC00000;

  logic [31:0] data1;
  logic [31:0] data2;
  logic [32:0] ext_data1;
  logic [32:0] ext_data2;
  logic [1:0]  fmt;
  logic [2:0]  rm;
  logic [9:0]  class1;
  logic [9:0]  class2;

  logic comp;
  logic [31:0] result;
  logic [4:0]  flags;

  always_comb begin

    data1 = max_i.data1;
    data2 = max_i.data2;
    ext_data1 = max_i.ext_data1;
    ext_data2 = max_i.ext_data2;
    fmt = max_i.fmt;
    rm = max_i.rm;
    class1 = max_i.class1;
    class2 = max_i.class2;

    comp = 0;
    result = 0;
    flags = 0;

    if (fmt == 0) begin

      comp = (ext_data1[31:0] > ext_data2[31:0]);

      if (rm == 0) begin  //MIN
        if (class1[8] & class2[8]) begin   //sNaN
          result   = nan;
          flags[4] = 1;
        end else if (class1[8]) begin
          result   = data2;
          flags[4] = 1;
        end else if (class2[8]) begin
          result   = data1;
          flags[4] = 1;
        end else if (class1[9] & class2[9]) begin   //qNaN
          result = nan;
        end else if (class1[9]) begin
          result = data2;
        end else if (class2[9]) begin
          result = data1;

        end else if (ext_data1[32] ^ ext_data2[32]) begin  //异号
          result = (ext_data1[32]) ? data1 : data2;
        end else begin                                     //同号
          if (ext_data1[32]) begin
            result = (comp) ? data1 : data2;
          end else begin
            result = (comp == 0) ? data1 : data2;
          end
        end

      end else if (rm == 1) begin  //MAX
        if ((class1[8] & class2[8])) begin   //sNaN
          result   = nan;
          flags[4] = 1;
        end else if (class1[8]) begin
          result   = data2;
          flags[4] = 1;
        end else if (class2[8]) begin
          result   = data1;
          flags[4] = 1;
        end else if (class1[9] & class2[9]) begin   //qNaN
          result = nan;
        end else if (class1[9]) begin
          result = data2;
        end else if (class2[9]) begin
          result = data1;

        end else if (ext_data1[32] ^ ext_data2[32]) begin  //异号
          result = (ext_data1[32]) ? data2 : data1;
        end else begin                                     //同号
            if (extend1[32]) begin
              result = (comp) ? data2 : data1;
            end else begin
              result = (comp == 0) ? data2 : data1;
            end
        end
      end
    end

    max_o.result = result;
    max_o.flags  = flags;

  end

endmodule