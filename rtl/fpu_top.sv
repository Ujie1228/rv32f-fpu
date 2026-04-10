import fpu_define::*;
import lzc_define::*;

module fpu_top (
    input   logic            clk_i,
    input   logic            rst_ni,
    input   var fpu_top_in_type  top_i,
    output  var fpu_top_out_type top_o
);

    // lzc模块信号
    lzc_32_in_type   lzc1_32_i;
    lzc_32_out_type  lzc1_32_o;
    lzc_32_in_type   lzc2_32_i;
    lzc_32_out_type  lzc2_32_o;
    lzc_32_in_type   lzc3_32_i;
    lzc_32_out_type  lzc3_32_o;
    lzc_32_in_type   lzc4_32_i;
    lzc_32_out_type  lzc4_32_o;
    lzc_128_in_type  lzc_128_i;
    lzc_128_out_type lzc_128_o;

    // extend模块信号
    logic [32:0] extend1;
    logic [32:0] extend2;
    logic [32:0] extend3;

    logic [9:0] class1;
    logic [9:0] class2;
    logic [9:0] class3;

    // op_class信号
    logic [3:0] op_class;
    fpu_operation_type op;
    
    // control模块信号
    logic       misc_ready_i;
    logic       cvt_ready_i;
    logic       fma_ready_i;
    logic       div_ready_i;
    logic       req_ready_o;

    logic       misc_data_vld_i;
    logic       cvt_data_vld_i;
    logic       fma_data_vld_i;
    logic       div_data_vld_i;
    logic       resp_valid_o;

    logic       misc_reg_empty_i;
    logic       cvt_reg_empty_i;
    logic       fma_reg_empty_i;
    logic       div_reg_empty_i;

    logic       misc_stall_o;
    logic       cvt_stall_o;
    logic       fma_stall_o;
    logic       div_stall_o;

    logic       div_busy;
    
    // exe模块信号
    logic       misc_start_o;
    logic       div_start_o;
    logic       cvt_start_o;
    logic       fma_start_o;
    
    fpu_fma_in_type       req_data_FMA_reg_o;
    fpu_div_in_type       req_data_DIV_reg_o;
    fpu_cvt_in_type       req_data_CVT_reg_o;
    fpu_misc_in_type      req_data_MISC_reg_o;

    fpu_misc_out_type     resp_misc_reg_i;
    fpu_div_reg_out       resp_div_reg_i;
    fpu_cvt_out_type      resp_cvt_reg_i;
    fpu_fma_reg_out       resp_fma_reg_i;
    
    // div模块信号
    fpu_div_out_type      div_nrnd;
    fpu_mac_in_type       mac_i;
    fpu_mac_out_type      mac_o;
    fpu_rnd_out_type      div_rnd_o;

    // cvt模块信号
    fpu_rnd_in_type       cvt_rnd_i;
    fpu_rnd_out_type      cvt_rnd_o;

    // fma模块信号
    fpu_fma_out_type      fma_nrnd;
    fpu_rnd_out_type      fma_rnd_o;

    // op
    assign op = top_i.req_op_i;

    // top_o
    assign top_o.req_ready_o = req_ready_o;
    assign top_o.resp_valid_o = resp_valid_o;


    // op_class控制
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

    // div_busy控制
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (~rst_ni) begin
            div_busy <= 0;
        end else if (top_i.req_valid_i & div_ready_i & (op_class ==DIV)) begin
            div_busy <= 1;
        end else if (div_nrnd.ready) begin
            div_busy <= 0;
        end
    end


    //lzc
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


    // control
    fpu_control u_fpu_control(
        .clk_i            	( clk_i             ),
        .rst_ni           	( rst_ni            ),
        .op_class_i       	( op_class          ),
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
        .div_busy_i       	( div_busy          ),
        .misc_stall_o     	( misc_stall_o      ),
        .cvt_stall_o      	( cvt_stall_o       ),
        .fma_stall_o      	( fma_stall_o       ),
        .div_stall_o      	( div_stall_o       )
    );


    // exe
    fpu_exe u_fpu_exe(
        .clk_i               	( clk_i                ),
        .rst_ni              	( rst_ni               ),

        .data1_i             	( top_i.req_data1_i    ),
        .data2_i             	( top_i.req_data2_i    ),
        .data3_i             	( top_i.req_data3_i    ),
        .extend1_i           	( extend1              ),
        .extend2_i           	( extend2              ),
        .extend3_i           	( extend3              ),
        .class1_i            	( class1               ),
        .class2_i            	( class2               ),
        .class3_i            	( class3               ),
        .req_op_i            	( op                   ),
        .op_class_i          	( op_class             ),
        .req_rm_i            	( top_i.req_rm_i       ),
        .req_tag_i           	( top_i.req_tag_i      ),

        .req_valid_i         	( top_i.req_valid_i    ),
        .req_ready_i            ( req_ready_o          ),
        .misc_ready_i        	( misc_ready_i         ),
        .cvt_ready_i         	( cvt_ready_i          ),
        .fma_ready_i         	( fma_ready_i          ),
        .div_ready_i         	( div_ready_i          ),
        .div_busy_i             ( div_busy             ),

        .misc_stall_i           ( misc_stall_o         ),
        .div_stall_i            ( div_stall_o          ),
        .cvt_stall_i            ( cvt_stall_o          ),
        .fma_stall_i            ( fma_stall_o          ),

        .req_data_FMA_reg_o  	( req_data_FMA_reg_o   ),
        .req_data_DIV_reg_o  	( req_data_DIV_reg_o   ),
        .req_data_CVT_reg_o  	( req_data_CVT_reg_o   ),
        .req_data_MISC_reg_o 	( req_data_MISC_reg_o  ),

        .misc_start_o           ( misc_start_o         ),
        .div_start_o            ( div_start_o          ),
        .cvt_start_o            ( cvt_start_o          ),
        .fma_start_o            ( fma_start_o          ),

        .resp_ready_i           ( top_i.resp_ready_i   ),
        .resp_misc_reg_i        ( resp_misc_reg_i      ),
        .resp_div_reg_i         ( resp_div_reg_i       ),
        .resp_cvt_reg_i         ( resp_cvt_reg_i       ),
        .resp_fma_reg_i         ( resp_fma_reg_i       ),

        .misc_data_vld_i        ( misc_data_vld_i      ),
        .div_data_vld_i         ( div_data_vld_i       ),
        .cvt_data_vld_i         ( cvt_data_vld_i       ),
        .fma_data_vld_i         ( fma_data_vld_i       ),

        .misc_reg_empty_o       ( misc_reg_empty_i     ),
        .div_reg_empty_o        ( div_reg_empty_i      ),
        .cvt_reg_empty_o        ( cvt_reg_empty_i      ),
        .fma_reg_empty_o        ( fma_reg_empty_i      ),

        .resp_result_o          ( top_o.resp_result_o  ),
        .resp_flags_o           ( top_o.resp_flags_o   ),
        .resp_tag_o             ( top_o.resp_tag_o     )
    );


    // misc
    fpu_misc u_fpu_misc(
        .clk_i           	( clk_i               ),
        .rst_ni          	( rst_ni              ),
        .misc_stall_i    	( misc_stall_o        ),
        .misc_start_i       ( misc_start_o        ),
        .misc_reg_i         ( req_data_MISC_reg_o ),
        .misc_reg_o         ( resp_misc_reg_i     ),
        .misc_ready_o    	( misc_ready_i        ),
        .misc_data_vld_o 	( misc_data_vld_i     )
    );


    // div
    fpu_div u_fpu_div(
        .clk_i           	( clk_i              ),
        .rst_ni          	( rst_ni             ),
        .div_stall_i    	( div_stall_o        ),
        .div_start_i        ( div_start_o        ),
        .fpu_fdiv_i         ( req_data_DIV_reg_o ),
        .fpu_fdiv_o         ( div_nrnd           ),
        .div_reg_o          ( resp_div_reg_i     ),
        .fpu_mac_o          ( mac_o              ),
        .fpu_mac_i          ( mac_i              ),
        .div_rnd_i          ( div_rnd_o          ),
        .div_ready_o        ( div_ready_i        ),
        .div_data_vld_o     ( div_data_vld_i     ),
        .div_reg_empty_i    ( div_reg_empty_o    )
    );

    fpu_mac u_fpu_mac(
        .mac_i              (mac_i),
        .mac_o              (mac_o)
    );

    fpu_rnd u1_fpu_rnd(
        .rnd_i              (div_nrnd.fpu_rnd ),
        .rnd_o              (div_rnd_o        )
    );


    // cvt
    fpu_cvt u_fpu_cvt(
        .clk_i              ( clk_i              ),
        .rst_ni             ( rst_ni             ),
        .cvt_stall_i        ( cvt_stall_o        ),
        .cvt_start_i        ( cvt_start_o        ),
        .cvt_reg_i          ( req_data_CVT_reg_o ),
        .cvt_reg_o          ( resp_cvt_reg_i     ),
        .lzc_i              ( lzc4_32_o          ),
        .lzc_o              ( lzc4_32_i          ),
        .cvt_rnd_i          ( cvt_rnd_o          ),
        .cvt_rnd_o          ( cvt_rnd_i          ),
        .cvt_ready_o        ( cvt_ready_i        ),
        .cvt_data_vld_o     ( cvt_data_vld_i     )
    );

    fpu_rnd u2_fpu_rnd(
        .rnd_i              (cvt_rnd_i),
        .rnd_o              (cvt_rnd_o)
    );


    // fma
    fpu_fma u_fpu_fma(
        .clk_i              ( clk_i              ),
        .rst_ni             ( rst_ni             ),
        .fma_stall_i        ( fma_stall_o        ),
        .fma_start_i        ( fma_start_o        ),
        .fpu_fma_i          ( req_data_FMA_reg_o ),
        .fpu_fma_o          ( fma_nrnd           ),
        .fma_reg_o          ( resp_fma_reg_i     ),
        .fma_rnd_i          ( fma_rnd_o          ),
        .lzc_i              ( lzc_128_o          ),
        .lzc_o              ( lzc_128_i          ),
        .fma_ready_o        ( fma_ready_i        ),
        .fma_data_vld_o     ( fma_data_vld_i     )
    );

    fpu_rnd u3_fpu_rnd(
        .rnd_i              (fma_nrnd.fpu_rnd ),
        .rnd_o              (fma_rnd_o        )
    );

endmodule