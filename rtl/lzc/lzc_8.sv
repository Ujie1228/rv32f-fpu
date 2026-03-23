module lzc_8 (
    input  [7:0] data,
    output [2:0] cnt,
    output       valid
);
  timeunit 1ns; timeprecision 1ps;

  logic [1:0] z0;
  logic [1:0] z1;

  logic v0;
  logic v1;

  logic s0;
  logic s1;
  logic s2;
  logic s3;
  logic s4;
  logic s5;
  logic s6;

  lzc_4 lzc_4_0 (
      .data  (data[3:0]),
      .cnt   (z0),
      .valid (v0)
  );

  lzc_4 lzc_4_1 (
      .data  (data[7:4]),
      .cnt   (z1),
      .valid (v1)
  );

  assign s0 = v1 | v0;
  assign s1 = (~v1) & z0[0];
  assign s2 = z1[0] | s1;
  assign s3 = (~v1) & z0[1];
  assign s4 = z1[1] | s3;

  assign valid = s0;
  assign cnt[0] = s2;
  assign cnt[1] = s4;
  assign cnt[2] = v1;

endmodule