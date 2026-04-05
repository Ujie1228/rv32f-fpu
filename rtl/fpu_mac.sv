import fpu_define::*;

module fpu_mac (
    input  fpu_mac_in_type  mac_i,
    output fpu_mac_out_type mac_o
);

  logic [51:0] add;
  logic [53:0] mul;
  logic [51:0] mac;
  logic [51:0] res;

  assign add = {mac_i.a, 25'h0};
  assign mul = $signed(mac_i.b) * $signed(mac_i.c);
  assign mac = (mac_i.op == 0) ? mul[51:0] : -mul[51:0];
  assign res = add + mac;
  assign mac_o.d = res;

endmodule
