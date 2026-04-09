  package lzc_define;
  
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

endpackage