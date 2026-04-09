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

    // misc_o
    fpu_misc_out_type misc_o;

    // sgnj cmp max class
    fpu_sgnj_in_type  sgnj_i;
    fpu_sgnj_out_type sgnj_o;
    fpu_cmp_in_type   cmp_i;
    fpu_cmp_out_type  cmp_o;
    fpu_max_in_type   max_i;
    fpu_max_out_type  max_o;
    fpu_class_in_type class_i;
    fpu_class_out_type class_o;

    // start
    logic start_n;

    assign start_n = misc_start_i;

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
    
    // ready
    assign misc_ready_o = ~misc_stall_i;

    // fsgnj
    fpu_sgnj u_fpu_sgnj (
        .sgnj_i(sgnj_i),
        .sgnj_o(sgnj_o)
    );

    // fcmp
    fpu_cmp u_fpu_cmp (
        .cmp_i(cmp_i),
        .cmp_o(cmp_o)
    );

    // fmax
    fpu_max u_fpu_max (
        .max_i(max_i),
        .max_o(max_o)
    );

    // class
    assign class_o.result = {22'b0, class_i.class1};

    // misc_o
    always_comb begin
        misc_o = '0;
        if (misc_i.op.fsgnj) begin
            misc_o.result = sgnj_o.result;
            misc_o.flags = '0;
            misc_o.tag = misc_i.tag;
        end else if (misc_i.op.fcmp) begin
            misc_o.result = cmp_o.result;
            misc_o.flags = cmp_o.flags;
            misc_o.tag = misc_i.tag;
        end else if (misc_i.op.fmax) begin
            misc_o.result = max_o.result;
            misc_o.flags = max_o.flags;
            misc_o.tag = misc_i.tag;
        end else if (misc_i.op.fclass) begin
            misc_o.result = class_o.result;
            misc_o.flags = '0;
            misc_o.tag = misc_i.tag;
        end
    end

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (~rst_ni) begin
            misc_reg_o <= '0;
            misc_data_vld_o <= '0;
        end else if (misc_stall_i) begin
            misc_reg_o <= misc_reg_o;
            misc_data_vld_o <= misc_data_vld_o;
        end else if (start_n) begin
            misc_reg_o <= misc_o;
            misc_data_vld_o <= 1'b1;
        end else begin
            misc_data_vld_o <= 1'b0;
        end
    end

endmodule

