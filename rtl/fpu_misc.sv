import fpu_define::*;

module fpu_misc (
    input  logic             clk_i,
    input  logic             rst_ni,
    input  logic             reg_empty,
    input  fpu_misc_in_type  misc_i,
    output fpu_misc_out_type misc_o,
    output logic             misc_ready,
    output logic             misc_valid
);

  fpu_sgnj_in_type  sgnj_i;
  fpu_sgnj_out_type sgnj_o;
  fpu_cmp_in_type   cmp_i;
  fpu_cmp_out_type  cmp_o;
  fpu_max_in_type   max_i;
  fpu_max_out_type  max_o;

  assign sgnj_i.data1 = misc_i.data1;
  assign sgnj_i.data2 = misc_i.data2;
  assign sgnj_i.rm = misc_i.rm;

  assign cmp_i.extend1 = misc_i.extend1;
  assign cmp_i.extend2 = misc_i.extend2;
  assign cmp_i.rm = misc_i.rm;
  assign cmp_i.class1 = misc_i.class1;
  assign cmp_i.class2 = misc_i.class2;

  assign max_i.data1 = misc_i.data1;
  assign max_i.data2 = misc_i.data2;
  assign max_i.extend1 = misc_i.extend1;
  assign max_i.extend2 = misc_i.extend2;
  assign max_i.rm = misc_i.rm;
  assign max_i.class1 = misc_i.class1;
  assign max_i.class2 = misc_i.class2;

  //fsgnj
  fpu_sgnj u_fpu_sgnj (
    .sgnj_i(sgnj_i),
    .sgnj_o(sgnj_o)
  );

  //fcmp
  fpu_cmp u_fpu_cmp (
    .cmp_i(cmp_i),
    .cmp_o(cmp_o)
  );

  //fmax
  fpu_max u_fpu_max (
    .max_i(max_i),
    .max_o(max_o)
  );

  //fclass


  always_ff @(posedge clk_i or posedge rst_ni) begin
    if (rst_ni) begin
      misc_o <= 0;
    end else if (reg_empty) begin
      misc_o.req_valid <= misc_i.req_valid;
      misc_o.req_tag <= misc_i.req_tag;
      if (misc_i.op.fsgnj) begin
        misc_o.result <= sgnj_o.result;
        misc_o.flags <= 0;
      end else if (misc_i.op.fcmp) begin
        misc_o.result <= cmp_o.result;
        misc_o.flags <= cmp_o.flags;
      end else if (misc_i.op.fmax) begin
        misc_o.result <= max_o.result;
        misc_o.flags <= max_o.flags;
      end else if (misc_i.op.fclass) begin
        misc_o.result <= {22'h0, misc_i.class1};
        misc_o.flags <= 0;
      end
    end
  end

endmodule