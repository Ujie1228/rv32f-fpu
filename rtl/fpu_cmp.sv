import fpu_define::*;

module fpu_cmp (
    input  fpu_cmp_in_type   cmp_i,
    output fpu_cmp_out_type  cmp_o
);
  timeunit 1ns; timeprecision 1ps;

  logic [32:0] data1;
  logic [32:0] data2;
  logic [2:0]  rm;
  logic [9:0]  class1;
  logic [9:0]  class2;

  logic [31:0] result;
  logic [4:0]  flags;

  logic        comp_lt;
  logic        comp_le;

  always_comb begin

    data1 = cmp_i.extend1;
    data2 = cmp_i.extend2;
    rm = cmp_i.rm;
    class1 = cmp_i.class1;
    class2 = cmp_i.class2;

    result = 0;
    flags = 0;

    comp_lt = 0;
    comp_le = 0;

    if( (rm==0) || (rm==1) || (rm==2) )begin
      comp_lt = (data1[31:0] <  data2[31:0]);
      comp_le = (data1[31:0] <= data2[31:0]);
    end
  
    if(rm==0)begin //FEQ
      if (class1[8] | class2[8]) begin
        flags[4] = 1;
      end else if (class1[9] | class2[9]) begin
        result[0] = 0;
      end else if ((class1[3] | class1[4]) & (class2[3] | class2[4])) begin
        result[0] = 1;
      end else if (data1 == data2) begin
        result[0] = 1;
      end
      
    end else if(rm==1)begin //FLT
      if (class1[8] | class2[8] | class1[9] | class2[9]) begin
        flags[4] = 1;
      end else if ((class1[3] | class1[4]) & (class2[3] | class2[4])) begin
        result[0] = 0;
      end else if (data1[32] ^ data2[32]) begin
        result[0] = data1[32];
      end else if (data1[32] == 0) begin
        result[0] = comp_lt;
      end else begin
        result[0] = ~comp_le;
      end
      
    end else if(rm==2)begin //FLE
      if (class1[8] | class2[8] | class1[9] | class2[9]) begin
        flags[4] = 1;
      end else if ((class1[3] | class1[4]) & (class2[3] | class2[4])) begin
        result[0] = 1;
      end else if (data1[32] ^ data2[32]) begin
        result[0] = data1[32];
      end else if (data1[32] == 0) begin
        result[0] = comp_le;
      end else begin
        result[0] = ~comp_lt;
      end
    end      

    cmp_o.result = result;
    cmp_o.flags  = flags;

  end

endmodule