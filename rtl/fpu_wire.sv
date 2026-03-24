package fpu_wire;

  timeunit 1ns; timeprecision 1ps;

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
    logic fmv_i2f;
    logic fmv_f2i;
    logic fcvt_i2f;
    logic fcvt_f2i;
    logic [1:0] fcvt_op;
  } fpu_operation_type;

  //********top*********
  typedef struct packed {
    logic [31:0] data1;
    logic [31:0] data2;
    logic [31:0] data3;
    fpu_operation_type op;
    logic [1:0] fmt;
    logic [2:0] rm;
    logic enable;
  } fpu_top_in_type;

  typedef struct packed {
    logic [31:0] result;
    logic [4:0] flags;
    logic ready;
  } fpu_top_out_type;
  
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

  parameter fpu_rnd_in_type init_fpu_rnd_in = '{
      sig : 0,
      expo : 0,
      mant : 0,
      rema : 0,
      fmt : 0,
      rm : 0,
      grs : 0,
      snan : 0,
      qnan : 0,
      dbz : 0,
      infs : 0,
      zero : 0,
      diff : 0
  };

  //********lzc*********
  typedef struct packed {
    logic [31:0] data;
  } lzc_32_in_type;

  typedef struct packed {
    logic [4:0] cnt;
    logic valid;
  } lzc_32_out_type;

  //*******class********
  typedef struct packed {
    logic [31:0] data;
    logic [1:0]  fmt;
  } fpu_class_in_type;

  typedef struct packed {
    logic [32:0] ext_data;
    logic [9:0]  classification;
  } fpu_class_out_type;

  //********cmp*********
  typedef struct packed {
    logic [32:0] ext_data1;
    logic [32:0] ext_data2;
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
    logic [32:0] ext_data1;
    logic [32:0] ext_data2;
    logic [1:0]  fmt;
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
    logic [1:0]  fmt;
    logic [2:0]  rm;
  } fpu_sgnj_in_type;

  typedef struct packed {
    logic [31:0] result;
  } fpu_sgnj_out_type;

  //********cvt*********
  typedef struct packed {
    logic [32:0] ext_data;
    fpu_operation_type op;
    logic [2:0] rm;
    logic [9:0] classification;
  } fpu_cvt_f2i_in_type;

  typedef struct packed {
    logic [31:0] result;
    logic [4:0]  flags;
  } fpu_cvt_f2i_out_type;

  typedef struct packed {
    logic [32:0] ext_data;
    logic [1:0] op;
    logic [2:0] rm;
    logic [9:0] classification;
    logic [31:0] result;
    logic [4:0] flags;
    logic snan;
    logic qnan;
    logic infs;
    logic zero;
    logic sign_cvt;
    logic [9:0] exponent_cvt;
    logic [58:0] mantissa_cvt;
    logic [9:0] exponent_bias;
    logic [32:0] mantissa_uint;
    logic [2:0] grs;
    logic odd;
    logic rnded;
    logic oor;
    logic or_1;
    logic or_2;
    logic or_3;
    logic or_4;
    logic or_5;
    logic oor_64u;
    logic oor_64s;
    logic oor_32u;
    logic oor_32s;
  } fpu_cvt_f2i_var_type;

  typedef struct packed {
    logic [31:0] data;
    fp_operation_type op;
    logic [1:0] fmt;
    logic [2:0] rm;
  } fpu_cvt_i2f_in_type;

  typedef struct packed {
    fpu_rnd_in_type rnd;
  } fpu_cvt_i2f_out_type;

  typedef struct packed {
    logic [31:0] data;
    logic [1:0] op;
    logic [1:0] fmt;
    logic [2:0] rm;
    logic snan;
    logic qnan;
    logic dbz;
    logic infs;
    logic zero;
    logic sign_uint;
    logic [4:0] exponent_uint;
    logic [31:0] mantissa_uint;
    logic [4:0] counter_uint;
    logic [6:0] exponent_bias;
    logic sign_rnd;
    logic [10:0] exponent_rnd;
    logic [24:0] mantissa_rnd;
    logic [2:0] grs;
  } fpu_cvt_i2f_var_type;

  //*******fma**********
  typedef struct packed {
    logic [32:0] ext_data1;
    logic [32:0] ext_data2;
    logic [32:0] ext_data3;
    logic [9:0] class1;
    logic [9:0] class2;
    logic [9:0] class3;
    fpu_operation_type op;
    logic [1:0] fmt;
    logic [2:0] rm;
  } fpu_fma_in_type;

  typedef struct packed {
    fpu_rnd_in_type rnd;
    logic ready;
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

  //******div_sqrt******
  typedef struct packed {
    logic [32:0] ext_data1;
    logic [32:0] ext_data2;
    logic [9:0] class1;
    logic [9:0] class2;
    fpu_operation_type op;
    logic [1:0] fmt;
    logic [2:0] rm;
  } fpu_div_sqrt_in_type;

  typedef struct packed {
    fpu_rnd_in_type rnd;
    logic ready;
  } fpu_div_sqrt_out_type;

endpackage