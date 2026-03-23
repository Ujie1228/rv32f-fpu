module lzc_4 (
    input  [3:0] data,
    output [1:0] cnt,
    output       valid
);
  timeunit 1ns; timeprecision 1ps;

  logic s0;
  logic s1;
  logic s2;
  logic s3;
  logic s4;

  assign s0 = data[3] | data[2];
  assign s1 = data[1] | data[0];
  assign s2 = s1 | s0;
  assign s3 = (~s0) & data[1];
  assign s4 = s3 | data[3];

  assign valid = s2;
  assign cnt[0] = s4;
  assign cnt[1] = s0;

endmodule