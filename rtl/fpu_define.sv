package fpu_define;

  //******operation*****
  typedef struct packed {
    logic fmadd;
    logic fmsub;
    logic fnmadd;
    logic fnmsub;
    logic fadd;
    logic fsub;
    logic fmul;
    logic fdiv;
    logic fsqrt;
    logic fsgnj;
    logic fcmp;
    logic fmax;
    logic fclass;
    logic fcvt_i2f;
    logic fcvt_f2i;
    logic fcvt_ui2f;
    logic fcvt_uf2i;
  } fpu_operation_type;

  localparam FMA = 4'b0001;
  localparam DIV = 4'b0010;
  localparam CVT = 4'b0100;
  localparam MISC = 4'b1000;

  //********top*********
  typedef struct packed {
    logic        req_valid_i;
    fpu_operation_type req_op_i;
    logic [31:0] req_data1_i;
    logic [31:0] req_data2_i;
    logic [31:0] req_data3_i;
    logic [2:0]  req_rm_i;
    logic [4:0]  req_tag_i;
    logic        resp_ready_i;
  } fpu_top_in_type;

  typedef struct packed {
    logic        req_ready_o;
    logic        resp_valid_o;
    logic [31:0] resp_result_o;
    logic [4:0]  resp_flags_o;
    logic [4:0]  resp_tag_o;
  } fpu_top_out_type;
  
  //*******misc*********
  typedef struct packed {
    logic [31:0] data1;
    logic [31:0] data2;
    logic [32:0] extend1;
    logic [32:0] extend2;
    fpu_operation_type op;
    logic [2:0]  rm;
    logic [9:0]  class1;
    logic [9:0]  class2;
    logic        req_valid;
    logic [4:0]  req_tag;
  } fpu_misc_in_type;

  typedef struct packed {
    logic [31:0] result;
    logic [4:0]  flags;
    logic        req_valid;
    logic [4:0]  req_tag;
  } fpu_misc_out_type;

  //*******rnd**********
  typedef struct packed {
    logic sig;
    logic [10:0] expo;
    logic [24:0] mant;
    logic [1:0] rema;
    logic [1:0] fmt;
    logic [2:0] rm;
    logic [2:0] grs;
    logic snan;
    logic qnan;
    logic dbz;
    logic infs;
    logic zero;
    logic diff;
  } fpu_rnd_in_type;

  typedef struct packed {
    logic [31:0] result;
    logic [4:0]  flags;
  } fpu_rnd_out_type;

  //********lzc*********
  typedef struct packed {
    logic [31:0] data;
  } lzc_32_in_type;

  typedef struct packed {
    logic [4:0] cnt;
    logic valid;
  } lzc_32_out_type;

  typedef struct packed {
    logic [127:0] data;
  } lzc_128_in_type;

  typedef struct packed {
    logic [6:0] cnt;
    logic valid;
  } lzc_128_out_type;

  //********cmp*********
  typedef struct packed {
    logic [32:0] extend1;
    logic [32:0] extend2;
    logic [2:0]  rm;
    logic [9:0]  class1;
    logic [9:0]  class2;
  } fpu_cmp_in_type;

  typedef struct packed {
    logic [31:0] result;
    logic [4:0]  flags;
  } fpu_cmp_out_type;

  //*******max**********
  typedef struct packed {
    logic [31:0] data1;
    logic [31:0] data2;
    logic [32:0] extend1;
    logic [32:0] extend2;
    logic [2:0]  rm;
    logic [9:0]  class1;
    logic [9:0]  class2;
  } fpu_max_in_type;

  typedef struct packed {
    logic [31:0] result;
    logic [4:0]  flags;
  } fpu_max_out_type;

  //*******sgnj*********
  typedef struct packed {
    logic [31:0] data1;
    logic [31:0] data2;
    logic [2:0]  rm;
  } fpu_sgnj_in_type;

  typedef struct packed {
    logic [31:0] result;
  } fpu_sgnj_out_type;

  //********cvt*********
  typedef struct packed {
    logic [31:0] data;
    logic [32:0] extend;
    fpu_operation_type op;
    logic [2:0]  rm;
    logic [9:0]  classification;
    logic        req_valid;
    logic [4:0]  req_tag;
  } fpu_cvt_in_type;

  typedef struct packed {
    logic [31:0] result;
    logic [4:0]  flags;
    logic        req_valid;
    logic [4:0]  req_tag;
  } fpu_cvt_out_type;

  //*******fma**********
  typedef struct packed {
    logic [32:0] extend1;
    logic [32:0] extend2;
    logic [32:0] extend3;
    logic [9:0]  class1;
    logic [9:0]  class2;
    logic [9:0]  class3;
    fpu_operation_type op;
    logic [2:0]  rm;
    logic        req_valid;
    logic [4:0]  req_tag;
  } fpu_fma_in_type;

  typedef struct packed {
    logic [31:0] result;
    logic [4:0]  flags;
    logic        req_valid;
    logic [4:0]  req_tag;
  } fpu_fma_out_type;

  //*******mac**********
  typedef struct packed {
    logic [26:0] a;
    logic [26:0] b;
    logic [26:0] c;
    logic op;
  } fpu_mac_in_type;

  typedef struct packed {
    logic [51:0] d;
  } fpu_mac_out_type;

  //*********div********
  typedef struct packed {
    logic [32:0] extend1;
    logic [32:0] extend2;
    logic [9:0]  class1;
    logic [9:0]  class2;
    fpu_operation_type op;
    logic [2:0]  rm;
    logic        req_valid;
    logic [4:0]  req_tag;
  } fpu_div_in_type;

  typedef struct packed {
    logic [31:0] result;
    logic [4:0]  flags;
    logic        req_valid;
    logic [4:0]  req_tag;
  } fpu_div_out_type;

endpackage