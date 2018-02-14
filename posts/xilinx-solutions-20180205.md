Title: Best solutions of the week of 2018-02-05
Category: Xilinx
Date: 2018-02-13 22:57
Tags: xilinx, fpga, forums, vivado

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

# PCIe IP not Exist 
## Question
I am using vivado 2017.1 and trying to use the IP-AXI Memory Mapped To PCI Express . But I couldn't find it in the library.
Thanks,
## Answer
It will not show up in the IP catalog if your board does not have a PCI express connector.

What I am not if it is a device compatibility issue or a filter based on the board data files.

I assume that if it is compatibility, then it has to do with the 7 series integrated block (fig. 1) which is part of the AXI memory mapped to pci express component. See page 10 on PG 054.

[PG054](https://www.xilinx.com/support/documentation/ip_documentation/pcie_7x/v3_0/pg054-7series-pcie.pdf)
![7 Series Requirements](/images/7seriesrequirements.png)

#  "There are no debug cores" in Zynq IP Integrator Design
## Question
I've got an IP Integrator/Block Diagram design targeting a Zynq XC7Z010, and I've been trying to put an ILA in it.  I have tried adding the ILA (both "normal' ILA and System ILA) as an IP block and connecting it up to some nets I want to look at; I have also tried opening the Synthesized Design and using Setup Debug.  If I do the latter, I can see the ILA and the Debug Hub being added to my design, and a probes file (.ltx) is generated.  But regardless of attempted method, when I program my device, I don't see any ILA core ... and a green bar appears at the top of the hardware manager window, saying "There are no debug cores."  The JTAG chain does come up just fine, such that I can see the processor, the FPGA, and the XADC inside the FPGA ... but no ILA.

I am using Vivado 2017.3.  I checked via the schematic that both the Hub and the ILA are getting a clock (looks like they are running on the same output clock of the processor that everything else in my design uses).
## Answer
Seems there's a specific sequence you have to follow:

  *Connect the hardware server and program the FPGA using Vivado. Don't program through SDK; that won't work.

  *Start run/debug in SDK, and wait for the debugger to load up to the beginning of main()

  *Refresh device in Vivado. Now the ILA core should be available.

  *Set up triggers.

  *Press the run button in SDK.


