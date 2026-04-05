import fpu_define::*;
import lzc_define::*;

module fpu_top (
    input   logic            clk_i,
    input   logic            rst_ni,
    input   fpu_top_in_type  top_i,
    output  fpu_top_out_type top_o
);

    //lzc
    lzc_32_in_type  lzc1_32_i;
    lzc_32_out_type lzc1_32_o;
    lzc_32_in_type  lzc2_32_i;
    lzc_32_out_type lzc2_32_o;
    lzc_32_in_type  lzc3_32_i;
    lzc_32_out_type lzc3_32_o;
    lzc_32_in_type  lzc4_32_i;
    lzc_32_out_type lzc4_32_o;
    lzc_128_in_type lzc_128_i;
    lzc_128_out_type lzc_128_o;

    lzc_32 u1_lzc_32 (
        .data  (lzc1_32_i.data),
        .cnt   (lzc1_32_o.cnt),
        .valid (lzc1_32_o.valid)
    );

    lzc_32 u2_lzc_32 (
        .data  (lzc2_32_i.data),
        .cnt   (lzc2_32_o.cnt),
        .valid (lzc2_32_o.valid)
    );

    lzc_32 u3_lzc_32 (
        .data  (lzc3_32_i.data),
        .cnt   (lzc3_32_o.cnt),
        .valid (lzc3_32_o.valid)
    );

    lzc_32 u4_lzc_32 (
        .data  (lzc4_32_i.data),
        .cnt   (lzc4_32_o.cnt),
        .valid (lzc4_32_o.valid)
    );

    lzc_128 u_lzc_128 (
        .data  (lzc_128_i.data),
        .cnt   (lzc_128_o.cnt),
        .valid (lzc_128_o.valid)
    );

    // extend
    logic [32:0] extend1;
    logic [32:0] extend2;
    logic [32:0] extend3;

    logic [9:0] class1;
    logic [9:0] class2;
    logic [9:0] class3;

    fpu_ext u1_fpu_ext (
        .data_i   (top_i.req_data1_i),
        .extend_o (extend1),
        .class_o  (class1),
        .lzc_o    (lzc1_32_o),
        .lzc_i    (lzc1_32_i)
    );
    
    fpu_ext u2_fpu_ext (
        .data_i   (top_i.req_data2_i),
        .extend_o (extend2),
        .class_o  (class2),
        .lzc_o    (lzc2_32_o),
        .lzc_i    (lzc2_32_i)
    );

    fpu_ext u3_fpu_ext (
        .data_i   (top_i.req_data2_i),
        .extend_o (extend3),
        .class_o  (class3),
        .lzc_o    (lzc3_32_o),
        .lzc_i    (lzc3_32_i)
    );  

    // op_class
    logic [3:0] op_class;
    fpu_operation_type op;

    assign op = top_i.req_op_i;

    always_comb begin
        op_class = MISC;
        if (op.fmadd | op.fmsub | op.fnmadd | op.fnmsub | op.fadd | op.fsub | op.fmul) begin
        op_class = FMA;
        end else if (op.fdiv | op.fsqrt) begin
        op_class = DIV;
        end else if (op.fcvt_i2f | op.fcvt_f2i) begin
        op_class = CVT;
        end else if (op.fsgnj | op.fcmp | op.fmax | op.fclass) begin
        op_class = MISC;
        end
    end


    // outports wire
    wire       	req_ready_o;
    wire       	resp_valid_o;
    wire       	misc_stall_o;
    wire       	cvt_stall_o;
    wire       	fma_stall_o;
    wire       	div_stall_o;

    fpu_control u_fpu_control(
        .clk_i            	( clk_i             ),
        .rst_ni           	( rst_ni            ),
        .op_class_i       	( op_class_i        ),
        .misc_ready_i     	( misc_ready_i      ),
        .cvt_ready_i      	( cvt_ready_i       ),
        .fma_ready_i      	( fma_ready_i       ),
        .div_ready_i      	( div_ready_i       ),
        .req_ready_o      	( req_ready_o       ),
        .misc_data_vld_i  	( misc_data_vld_i   ),
        .cvt_data_vld_i   	( cvt_data_vld_i    ),
        .fma_data_vld_i   	( fma_data_vld_i    ),
        .div_data_vld_i   	( div_data_vld_i    ),
        .resp_valid_o     	( resp_valid_o      ),
        .misc_reg_empty_i 	( misc_reg_empty_i  ),
        .cvt_reg_empty_i  	( cvt_reg_empty_i   ),
        .fma_reg_empty_i  	( fma_reg_empty_i   ),
        .div_reg_empty_i  	( div_reg_empty_i   ),
        .div_busy_i       	( div_busy_i        ),
        .misc_stall_o     	( misc_stall_o      ),
        .cvt_stall_o      	( cvt_stall_o       ),
        .fma_stall_o      	( fma_stall_o       ),
        .div_stall_o      	( div_stall_o       )
    );

    wire        	req_data_FMA_reg_o;
    wire        	req_data_DIV_reg_o;
    wire        	req_data_CVT_reg_o;
    wire        	req_data_MISC_reg_o;

    fpu_exe u_fpu_exe(
        .clk_i               	( clk_i                ),
        .rst_ni              	( rst_ni               ),
        .data1_i             	( data1_i              ),
        .data2_i             	( data2_i              ),
        .data3_i             	( data3_i              ),
        .extend1_i           	( extend1_i            ),
        .extend2_i           	( extend2_i            ),
        .extend3_i           	( extend3_i            ),
        .class1_i            	( class1_i             ),
        .class2_i            	( class2_i             ),
        .class3_i            	( class3_i             ),
        .req_op_i            	( req_op_i             ),
        .op_class_i          	( op_class_i           ),
        .req_rm_i            	( req_rm_i             ),
        .req_tag_i           	( req_tag_i            ),
        .req_valid_i         	( req_valid_i          ),
        .misc_ready_i        	( misc_ready_i         ),
        .cvt_ready_i         	( cvt_ready_i          ),
        .fma_ready_i         	( fma_ready_i          ),
        .div_ready_i         	( div_ready_i          ),
        .req_data_FMA_reg_o  	( req_data_FMA_reg_o   ),
        .req_data_DIV_reg_o  	( req_data_DIV_reg_o   ),
        .req_data_CVT_reg_o  	( req_data_CVT_reg_o   ),
        .req_data_MISC_reg_o 	( req_data_MISC_reg_o  )
    );



    wire   	misc_o;
    wire   	misc_ready_o;
    wire   	misc_data_vld_o;

    fpu_misc u_fpu_misc(
        .clk_i           	( clk_i            ),
        .rst_ni          	( rst_ni           ),
        .misc_stall_i    	( misc_stall_o     ),
        .misc_i          	( req_data_MISC_reg_o           ),
        .misc_o          	( misc_o           ),
        .misc_ready_o    	( misc_ready_o     ),
        .misc_data_vld_o 	( misc_data_vld_o  )
    );



endmodule