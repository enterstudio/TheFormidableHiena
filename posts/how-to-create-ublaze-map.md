Title: How to create a map file for Microblaze
Category: Xilinx
Tags: zynq, vivado, fpga, soc
Date: 2018-03-04 16:47


##

Just sharing how to create a map file for uB in standalone/baremetal application 

To create a map file for a microblaze application, this is the syntax:

```
-Wl,-M=c:/delme/test.map
```
 
![ublazemap](/images/Xilinx/ublaze-map.png)

Note to Xilinx:  Could you update UG1043 to be more complete...the section highlighted in yellow could use more detail.  Searching on the forums turns up a variety of answers, and they are not necessarily consistent with the latest tools.  It is possible it is a different option for arm--I didn't check.  If so, please specify the map file creation option for arm as well.  Maybe it is already documented somewhere in DocNav but I could not find it in a reasonable amount of time. 

![ublazemap](/images/Xilinx/ublaze-map-2.png)
 

Or provide links on this thread to the proper answer records.

