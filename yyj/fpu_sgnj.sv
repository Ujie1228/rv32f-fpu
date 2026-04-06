import fpu_define::*;

module fp_sgnj (
    input  fpu_sgnj_in_type  fp_sgnj_i,
    output fpu_sgnj_out_type fp_sgnj_o
);

    logic [31:0] data1;
    logic [31:0] data2;
    logic [1:0] fmt;
    logic [2:0] rm;
    logic [31:0] result;

    always_comb begin

        data1 = fp_sgnj_i.data1;
        data2 = fp_sgnj_i.data2;
        rm = fp_sgnj_i.rm;

        result[30:0] = data1[30:0];
        if (rm == 0) begin
            result[31] = data2[31];
        end else if (rm == 1) begin
            result[31] = ~data2[31];
        end else if (rm == 2) begin
            result[31] = data1[31] ^ data2[31];
        end

        fp_sgnj_o.result = result;

    end

endmodule
