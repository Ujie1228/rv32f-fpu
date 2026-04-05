module lzc_128 (
    input  logic [127:0] data,
    output logic [6:0]   cnt,
    output logic         valid
);

  logic [5:0] z0;
  logic [5:0] z1;

  logic v0;
  logic v1;

  logic s0;
  logic s1;
  logic s2;
  logic s3;
  logic s4;
  logic s5;
  logic s6;
  logic s7;
  logic s8;
  logic s9;
  logic s10;
  logic s11;
  logic s12;
  logic s13;
  logic s14;

  lzc_64 u1_lzc_64 (
      .data  (data[63:0]),
      .cnt   (z0),
      .valid (v0)
  );

  lzc_64 u2_lzc_64 (
      .data  (data[127:64]),
      .cnt   (z1),
      .valid (v1)
  );

  assign s0 = v1 | v0;
  assign s1 = (~v1) & z0[0];
  assign s2 = z1[0] | s1;
  assign s3 = (~v1) & z0[1];
  assign s4 = z1[1] | s3;
  assign s5 = (~v1) & z0[2];
  assign s6 = z1[2] | s5;
  assign s7 = (~v1) & z0[3];
  assign s8 = z1[3] | s7;
  assign s9 = (~v1) & z0[4];
  assign s10 = z1[4] | s9;
  assign s11 = (~v1) & z0[5];
  assign s12 = z1[5] | s11;

  assign valid = s0;
  assign cnt[0] = s2;
  assign cnt[1] = s4;
  assign cnt[2] = s6;
  assign cnt[3] = s8;
  assign cnt[4] = s10;
  assign cnt[5] = s12;
  assign cnt[6] = v1;

endmodule
