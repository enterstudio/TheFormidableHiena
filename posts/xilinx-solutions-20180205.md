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
[if_test.sv](/files/xilinx-solutions/2018-02-05/if_test.sv)
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
