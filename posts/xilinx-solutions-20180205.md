Title: Best solutions of the week of 2018-02-05
Category: Xilinx
Date: 2018-02-13 22:57
Tags: xilinx, fpga, forum

# 2D Array of System Verilog Interfaces

## Question
I'm using 2017.4 and though UG901 says that Array of Interfaces is Not Supported, I have been successfully using 1D arrays for a while now. 
Example:
```c
bus my_bus[2] ();
```
However when I try to generate a 2D array of interfaces it fails in Elaboration.
```c
bus my_bus[2][2] ();
```
Any idea when this will be supported?
Attached a test case to show this.

```verilog
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
```
## Answer
Vivado support for multi-dimensional arrays of interfaces is spotty.
We've successfully used single dimensional arrays of interfaces with Vivado Synthesis and it's fully supported.  Our designs have had them, and used since one of the 2015 Vivado releases.
We are using 2D arrays of interfaces too, but it's limited.
Vivado appears to only allow you to index a single (left most, most varying) dimension PER module.  I know that's a bit cryptic.  But Vivado will allow 2-d arrays-of-interface instantiates, and declarations within portlists.  From your examples:
```verilog
module top()
  bus bus2d[3:0][2:0]
  submodule sub1 ( .s_bus2d( bus2d ) )
endmodule

module submodule
#( 
  parameter ARRAY1 = 4,
  parameter ARRAY0 = 3
)
(
  bus.s s_bus2d[ ARRAY1 - 1 : 0 ] [ ARRAY0 - 1 : 0 ]
);

generate
  for( genvar i = 0; i < ARRAY1; i++ )
  begin : iter_i
    low_level low_level1( .s_bus1d( s_bus2d[ i ] ) );
  end
endgenerate
endmodule
```
I left out the low_level module - but it has a 1-d array of interfaces.  Hopefully you get the picture.
But Vivado wouldn't let you directly index into both dimensions.  You need to do the "slice" as above to slice off one dimension on it's way down to a lower level.
Hopefully that's clear.  It's been on the list of things I wanted to ask Xilinx to address, but lower down for us, since we could work with it like above for our few use cases.
Regards,
Mark

# 
