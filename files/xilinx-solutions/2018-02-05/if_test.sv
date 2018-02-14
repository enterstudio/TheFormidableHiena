`define TEST

interface bus (input clk);
  logic [15:0] d;
  logic        vld;

  modport m (
    input clk,
    output d,
    output vld
  );

  modport s (
    input clk,
    input d,
    input vld
  );
endinterface

module test_gen (
  input clk,

`ifdef TEST
  bus.m bus2d[2][2],
`endif
  bus.m bus1d[2]
);
  logic [15:0] ctr = 0;

  always_ff @(posedge clk) begin
    ctr <= ctr + 1'b1;
  end

  generate
    for (genvar i=0; i<2; i++) begin
      assign bus1d[i].d = ctr;
      assign bus1d[i].vld = ctr[0];
`ifdef TEST
      for (genvar j=0; j<2; j++) begin
        assign bus2d[i][j].d = ctr;
        assign bus2d[i][j].vld = ctr[0];
      end
`endif
    end
  endgenerate
endmodule

module if_test (
  input         clk,
  output [15:0] dout1d[2],
  output        vld1d[2],
  output [15:0] dout2d[2][2],
  output        vld2d[2][2]
);

  bus test_bus1d[2] (clk);
`ifdef TEST
  bus test_bus2d[2][2] (clk);
`endif

  test_gen test_gen_inst (
    .clk   (clk),
`ifdef TEST
    .bus2d (test_bus2d),
`endif
    .bus1d (test_bus1d)
  );

  generate
    for (genvar i=0; i<2; i++) begin
      assign dout1d[i] = test_bus1d[i].d;
      assign vld1d[i] = test_bus1d[i].vld;
`ifdef TEST
      for (genvar j=0; j<2; j++) begin
        assign dout2d[i][j] = test_bus2d[i][j].d;
        assign vld2d[i][j] = test_bus2d[i][j].vld;
      end
`endif
    end
  endgenerate
endmodule
