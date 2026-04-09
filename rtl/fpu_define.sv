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
      logic fcvt_op;
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
      logic [4:0]  tag;
    } fpu_misc_in_type;

    typedef struct packed {
      logic [31:0] result;
      logic [4:0]  flags;
      logic [4:0]  tag;
    } fpu_misc_out_type;

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

    //*******class*********
    typedef struct packed {
      logic [9:0] class1;  
    } fpu_class_in_type;

    typedef struct packed {
      logic [31:0] result;
    } fpu_class_out_type;

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

    //********cvt*********
    typedef struct packed {
      logic [31:0] data;
      logic [32:0] extend;
      fpu_operation_type op;
      logic [2:0]  rm;
      logic [9:0]  classification;
      logic [4:0]  tag;
    } fpu_cvt_in_type;

    typedef struct packed {
      logic [31:0] result;
      logic [4:0]  flags;
      logic [4:0]  tag;
    } fpu_cvt_out_type;

    typedef struct packed {
      logic [32:0] extend;
      fpu_operation_type op;
      logic [2:0] rm;
      logic [9:0] classification;
    } fpu_cvt_f2i_in_type;

    typedef struct packed {
      logic [31:0] result;
      logic [4:0]  flags;
    } fpu_cvt_f2i_out_type;

    typedef struct packed {
      logic [32:0] extend;
      logic op;
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
      fpu_operation_type op;
      logic [2:0] rm;
    } fpu_cvt_i2f_in_type;

    typedef struct packed {
      fpu_rnd_in_type fpu_rnd;
    } fpu_cvt_i2f_out_type;

    typedef struct packed {
      logic [31:0] data;
      logic op;
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
      logic [32:0] extend1;
      logic [32:0] extend2;
      logic [32:0] extend3;
      logic [9:0]  class1;
      logic [9:0]  class2;
      logic [9:0]  class3;
      fpu_operation_type op;
      logic [2:0]  rm;
      logic [4:0]  tag;
    } fpu_fma_in_type;

    typedef struct packed {
      fpu_rnd_in_type fpu_rnd;
      logic ready;
      logic [4:0]  tag;
    } fpu_fma_out_type;

    typedef struct packed {
      logic [31:0] result;
      logic [4:0]  flags;
      logic [4:0]  tag;
    } fpu_fma_reg_out;

    typedef struct packed {
      logic [1:0] fmt;
      logic [2:0] rm;
      logic snan;
      logic qnan;
      logic dbz;
      logic infs;
      logic zero;
      logic sign_mul;
      logic [10:0] exponent_mul;
      logic [76:0] mantissa_mul;
      logic sign_add;
      logic [10:0] exponent_add;
      logic [76:0] mantissa_add;
      logic exponent_neg;
      logic ready;
      logic [4:0]  tag;
    } fpu_fma_reg_type_1;

    parameter fpu_fma_reg_type_1 init_fpu_fma_reg_1 = '{
        fmt : 0,
        rm : 0,
        snan : 0,
        qnan : 0,
        dbz : 0,
        infs : 0,
        zero : 0,
        sign_mul : 0,
        exponent_mul : 0,
        mantissa_mul : 0,
        sign_add : 0,
        exponent_add : 0,
        mantissa_add : 0,
        exponent_neg : 0,
        ready : 0,
        tag: 0
    };

    typedef struct packed {
      logic [32:0] a;
      logic [32:0] b;
      logic [32:0] c;
      logic [9:0] class_a;
      logic [9:0] class_b;
      logic [9:0] class_c;
      logic [1:0] fmt;
      logic [2:0] rm;
      logic snan;
      logic qnan;
      logic dbz;
      logic infs;
      logic zero;
      logic sign_a;
      logic [8:0] exponent_a;
      logic [23:0] mantissa_a;
      logic sign_b;
      logic [8:0] exponent_b;
      logic [23:0] mantissa_b;
      logic sign_c;
      logic [8:0] exponent_c;
      logic [23:0] mantissa_c;
      logic sign_mul;
      logic [10:0] exponent_mul;
      logic [76:0] mantissa_mul;
      logic sign_add;
      logic [10:0] exponent_add;
      logic [76:0] mantissa_add;
      logic [76:0] mantissa_l;
      logic [76:0] mantissa_r;
      logic [10:0] exponent_dif;
      logic [5:0] counter_dif;
      logic exponent_neg;
      logic ready;
      logic [4:0]  tag;
    } fpu_fma_var_type_1;

    typedef struct packed {
      logic sign_rnd;
      logic [10:0] exponent_rnd;
      logic [24:0] mantissa_rnd;
      logic [1:0] fmt;
      logic [2:0] rm;
      logic [2:0] grs;
      logic snan;
      logic qnan;
      logic dbz;
      logic infs;
      logic zero;
      logic diff;
      logic ready;
      logic [4:0]  tag;
    } fpu_fma_reg_type_2;

    parameter fpu_fma_reg_type_2 init_fpu_fma_reg_2 = '{
        sign_rnd : 0,
        exponent_rnd : 0,
        mantissa_rnd : 0,
        fmt : 0,
        rm : 0,
        grs : 0,
        snan : 0,
        qnan : 0,
        dbz : 0,
        infs : 0,
        zero : 0,
        diff : 0,
        ready : 0,
        tag: 0
    };

    typedef struct packed {
      logic [1:0] fmt;
      logic [2:0] rm;
      logic snan;
      logic qnan;
      logic dbz;
      logic infs;
      logic zero;
      logic diff;
      logic sign_mul;
      logic [10:0] exponent_mul;
      logic [76:0] mantissa_mul;
      logic sign_add;
      logic [10:0] exponent_add;
      logic [76:0] mantissa_add;
      logic exponent_neg;
      logic sign_mac;
      logic [10:0] exponent_mac;
      logic [76:0] mantissa_mac;
      logic [6:0] counter_mac;
      logic [10:0] counter_sub;
      logic [7:0] bias;
      logic sign_rnd;
      logic [10:0] exponent_rnd;
      logic [24:0] mantissa_rnd;
      logic [2:0] grs;
      logic ready;
      logic [4:0]  tag;
    } fpu_fma_var_type_2;

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
      logic [4:0]  tag;
    } fpu_div_in_type;

    typedef struct packed {
      fpu_rnd_in_type fpu_rnd;
      logic ready;
    } fpu_div_out_type;

    typedef struct packed {
      logic [31:0] result;
      logic [4:0]  flags;
      logic [4:0]  tag;
    } fpu_div_reg_out;

    typedef struct packed {
      logic [2:0] state;
      logic [5:0] istate;
      logic [1:0] fmt;
      logic [2:0] rm;
      logic [32:0] a;
      logic [32:0] b;
      logic [9:0] class_a;
      logic [9:0] class_b;
      logic snan;
      logic qnan;
      logic infs;
      logic dbz;
      logic zero;
      logic op;
      logic [6:0] index;
      logic [26:0] qa;
      logic [26:0] qb;
      logic [26:0] q0;
      logic [26:0] q1;
      logic [26:0] y;
      logic [26:0] y0;
      logic [26:0] y1;
      logic [26:0] y2;
      logic [26:0] h0;
      logic [26:0] h1;
      logic [26:0] e0;
      logic [26:0] e1;
      logic [51:0] r0;
      logic [51:0] r1;
      logic sign_fdiv;
      logic [10:0] exponent_fdiv;
      logic [55:0] mantissa_fdiv;
      logic [1:0] counter_fdiv;
      logic [7:0] exponent_bias;
      logic sign_rnd;
      logic [10:0] exponent_rnd;
      logic [24:0] mantissa_rnd;
      logic [1:0] remainder_rnd;
      logic [10:0] counter_rnd;
      logic [2:0] grs;
      logic odd;
      logic [31:0] result;
      logic [4:0] flags;
      logic ready;
    } fpu_fdiv_reg_functional_type;

    parameter fpu_fdiv_reg_functional_type init_fpu_fdiv_reg_functional = '{
      state : 0,
      istate : 0,
      fmt : 0,
      rm : 0,
      a : 0,
      b : 0,
      class_a : 0,
      class_b : 0,
      snan : 0,
      qnan : 0,
      infs : 0,
      dbz : 0,
      zero : 0,
      op : 0,
      index : 0,
      qa : 0,
      qb : 0,
      q0 : 0,
      q1 : 0,
      y : 0,
      y0 : 0,
      y1 : 0,
      y2 : 0,
      h0 : 0,
      h1 : 0,
      e0 : 0,
      e1 : 0,
      r0 : 0,
      r1 : 0,
      sign_fdiv : 0,
      exponent_fdiv : 0,
      mantissa_fdiv : 0,
      counter_fdiv : 0,
      exponent_bias : 0,
      sign_rnd : 0,
      exponent_rnd : 0,
      mantissa_rnd : 0,
      remainder_rnd : 0,
      counter_rnd : 0,
      grs : 0,
      odd : 0,
      result : 0,
      flags : 0,
      ready : 0
    };

    typedef struct packed {
      logic [2:0] state;
      logic [4:0] istate;
      logic [1:0] fmt;
      logic [2:0] rm;
      logic [32:0] a;
      logic [32:0] b;
      logic [9:0] class_a;
      logic [9:0] class_b;
      logic snan;
      logic qnan;
      logic infs;
      logic dbz;
      logic zero;
      logic op;
      logic [26:0] qa;
      logic [26:0] qb;
      logic [25:0] q;
      logic [27:0] e;
      logic [27:0] r;
      logic [27:0] m;
      logic sign_fdiv;
      logic [10:0] exponent_fdiv;
      logic [77:0] mantissa_fdiv;
      logic [1:0] counter_fdiv;
      logic [7:0] exponent_bias;
      logic sign_rnd;
      logic [10:0] exponent_rnd;
      logic [24:0] mantissa_rnd;
      logic [1:0] remainder_rnd;
      logic [10:0] counter_rnd;
      logic [2:0] grs;
      logic odd;
      logic [31:0] result;
      logic [4:0] flags;
      logic ready;
    } fpu_fdiv_reg_fixed_type;

    parameter fpu_fdiv_reg_fixed_type init_fpu_fdiv_reg_fixed = '{
      state : 0,
      istate : 0,
      fmt : 0,
      rm : 0,
      a : 0,
      b : 0,
      class_a : 0,
      class_b : 0,
      snan : 0,
      qnan : 0,
      infs : 0,
      dbz : 0,
      zero : 0,
      op : 0,
      qa : 0,
      qb : 0,
      q : 0,
      e : 0,
      r : 0,
      m : 0,
      sign_fdiv : 0,
      exponent_fdiv : 0,
      mantissa_fdiv : 0,
      counter_fdiv : 0,
      exponent_bias : 0,
      sign_rnd : 0,
      exponent_rnd : 0,
      mantissa_rnd : 0,
      remainder_rnd : 0,
      counter_rnd : 0,
      grs : 0,
      odd : 0,
      result : 0,
      flags : 0,
      ready : 0
    };

endpackage