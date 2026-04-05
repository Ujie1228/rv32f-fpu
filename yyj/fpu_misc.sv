import fpu_define::*;

module fpu_misc(
    input logic clk_i,
    input logic rst_ni,

    input logic misc_stall_i,
    input logic misc_start_i,
    input  fpu_misc_in_type  misc_reg_i,

    output fpu_misc_out_type misc_reg_o,
    output logic misc_ready_o,
    output logic misc_data_vld_o
);

    // sgnj cmp max class
    fpu_sgnj_in_type  sgnj_i;
    fpu_sgnj_out_type sgnj_o;
    fpu_cmp_in_type   cmp_i;
    fpu_cmp_out_type  cmp_o;
    fpu_max_in_type   max_i;
    fpu_max_out_type  max_o;
    fpu_class_in_type class_i;
    fpu_class_out_type class_o;

    assign sgnj_i.data1 = misc_reg_i.data1;
    assign sgnj_i.data2 = misc_reg_i.data2;
    assign sgnj_i.rm = misc_reg_i.rm;

    assign cmp_i.extend1 = misc_reg_i.extend1;
    assign cmp_i.extend2 = misc_reg_i.extend2;
    assign cmp_i.rm = misc_reg_i.rm;
    assign cmp_i.class1 = misc_reg_i.class1;
    assign cmp_i.class2 = misc_reg_i.class2;

    assign max_i.data1 = misc_reg_i.data1;
    assign max_i.data2 = misc_reg_i.data2;
    assign max_i.extend1 = misc_reg_i.extend1;
    assign max_i.extend2 = misc_reg_i.extend2;
    assign max_i.rm = misc_reg_i.rm;
    assign max_i.class1 = misc_reg_i.class1;
    assign max_i.class2 = misc_reg_i.class2;
    
    assign class_i.class1 = misc_reg_i.class1;

endmodule// outports wire

