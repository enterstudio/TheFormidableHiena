Title: Vivado scripting basics
Date: 2018-02-16 19:40
Modified: 2018-02-16 19:40
Category: FPGA
Tags: vivado, tcl, fpga, linux
Slug: vivado-under-the-hood
Summary: Vivado scripting basics

# Introduction

My motivation for looking inside Vivado runs was that I wanted to implement a Vivado project from within XEmacs, using the Compile button, and all that within a rather tangled Makefile-based build system. But I also wanted to leave the possibility to open the project using Vivado’s GUI, if something went wrong or needed inspection. So working in non-project mode was out of the question.

On the face of it, the solution was simple: Just execute the runme.sh scripts in the run directories. Or use launch_runs in a Tcl script. Well, that sounds simple, but there is no output to console during these runs. In particular, the implementation is completely silent. I opted out the fun of staring on the cursor for an hour or so, having no idea what’s going on during the implementation. Leaving me no option but to get my hands a bit dirty.

It’s recommended to first [take a look on this page](http://xillybus.com/tutorials/vivado-version-control-packaging), which discusses other aspects of scripting.

# Preparing the runs & OOCs

Vivado runs are just an execution of a Tcl script in one of the *.runs directories. This holds true for all runs, both Out-Of-Context runs (OOCs, e.g. IP cores) as well as synthesis and implementation runs.

Say that the project’s name is myproj, and the top-level module’s name is top.v (or top.vhd, if you insist). As the project is generated, Vivado creates a directory named myproj.run, which contains a set of subdirectories, for example fifo_32x512_synth_1/, fifo_8x2048_synth_1/, synth_1/ and impl_1/. In this example, the first two directories belong to two FIFO IPs, and the other two are implementation related.

synth_1 and impl_1 are most likely generated when the project is created in Vivado’s GUI, or with create_run Tcl calls if the project is generated with a setup scripts (again, take a look on [this page](http://xillybus.com/tutorials/vivado-version-control-packaging)). This is kinda out of scope here. The thing is to create and invoke the runs for the IPs (that is, the Out-Of-Context parts, OOCs).

In my personal preference, these OOCs are added to the project with the following Tcl snippet:

```tcl
foreach i $oocs {
    if [file exists "$essentials_dir/$i/$i.dcp"] {
	read_checkpoint "$essentials_dir/$i/$i.dcp"
    } else {
	add_files -norecurse -fileset $obj "$essentials_dir/$i/$i.xci"
    }
}
```

To make a long story short, the idea is to include the DCP file rather than the XCI if possible, so the IP isn’t re-generated if it has already been so. Which means that the DCP file has to deleted if the IP core’s attributes have been changed, or the changes won’t take any effect.

We’ll assume that the IPs were included as XCIs, because including DCPs requires no runs.

The next step is to create the scripts for all runs with the following Tcl command:

```tcl
launch_runs -scripts_only impl_1 -to_step write_bitstream
```

Note that thanks to the -scripts_only flag, no run executes here, but just the run directories and their respective scripts. In particular, the IPs are elaborated, or generated, at this point. But not synthesized.

# Building the OOCs

It’s a waste of time to run the IPs’ synthesis one after the other, as each synthesis doesn’t depend on the other. So a parallel launch can be done as follows:

First, obtain a list of runs to be run, and reset them:

```tcl
set ooc_runs [get_runs -filter {IS_SYNTHESIS && name != "synth_1"} ]

foreach run $ooc_runs { reset_run $run }
```

The filter grabs the synthesis target of the IPs’ runs, and skips synth_1. Resetting is done, or Vivado complains it should.

Next, launch these specific runs in parallel:

```tcl
if { [ llength $ooc_runs ] } {
  launch_runs -jobs 8 $ooc_runs
}
```

Note that ooc_runs may be an empty list, in particular if all IPs were loaded as DCPs before. If launch_runs is called with no runs, it fails with an error. To prevent this, $ooc_runs is checked first.

And then finally, wait for all runs to finish. wait_on_run can only wait on one specific run, but it’s fine looping on all launched runs. The loop will finish after the last run has finished:

```tcl
foreach run $ooc_runs { wait_on_run $run }
```

# Finally: Implementing the project

As mentioned above, launching a run actually consists of executing runme.sh (or runme.bat on Windows, never tried it). The runme.sh shell script sets the PATH with the current Vivado executable, and then invokes the following command with ISEWrap.sh as a wrapper:

```tcl
vivado -log top.vds -m64 -mode batch -messageDb vivado.pb -notrace -source top.tcl
```

(Recall that “top” is the name of the toplevel module)

**Spoiler**: Just invoking the command above will execute the run with all log output going to console, but Vivado’s GUI will not reflect that the execution took place properly. More on that below.

It’s important to note that the “vivado” executable is invoked. This is in fact the way it’s done even when launched from within the GUI or with a launch_runs Tcl command. If the -jobs parameter is given to launch_runs, it will invoke the “vivado” executable several times in parallel. If you want to convince yourself that this indeed happens, note that you get something like this in the console inside Vivado’s GUI, which is exactly what Vivado prints out when invoked from the command line:

```sh
****** Vivado v2015.2 (64-bit)
  **** SW Build 1266856 on Fri Jun 26 16:35:25 MDT 2015
  **** IP Build 1264090 on Wed Jun 24 14:22:01 MDT 2015
    ** Copyright 1986-2015 Xilinx, Inc. All Rights Reserved.
```
Vivado’s invocation involves three flags that are undocumented:

. The -notrace flag simply means that Vivado doesn’t print out the Tcl commands it executes, which it would otherwise do by default. I drop this flag in my own scripts: With all the mumbo-jumbo that is emitted anyhow, the Tcl commands are relatively informative.
. The -m64 probably means “run in 64 bit mode”, but I have no idea.
. The -messageDb seems to set the default message *.pb output, which is probably some kind of database from which the GUI takes its data to present in the Message tab. Note that the main Tcl script for impl_1 (e.g. top.tcl) involves several calls to create_msg_db followed by close_msg_db, which is probably how the implementation run has messages divided into subcategories. Just my guesses, since nothing of this is documented (not even these Tcl commands).
. The ISEWrap.sh wrapper is crucially important if you want to be able to open the GUI after the implementation and work as if it was done in the GUI: It makes it possible for the GUI to tell which run has started, completed or failed. Namely, it creates two files, one when the run starts, and one when it ends.

For example, during the invocation of a run, .vivado.begin.rst is created (note the “hidden file name” starting with a dot), and contains something like this:

```xml
<?xml version="1.0"?>
<ProcessHandle Version="1" Minor="0">
    <Process Command="vivado" Owner="eli" Host="myhost.localdomain" Pid="1003">
    </Process>
</ProcessHandle>
```
And if the process terminates successfully, another empty file is created, .vivado.end.rst. If it failed, the empty file .vivado.error.rst is created instead. The synth_1 run creates only these two, but as for impl_1, individual files are generated for each step in the implementation Tcl script by virtue of file-related Tcl commands, e.g. .init_design.begin.rst, .place_design.begin.rst etc (and also end scripts). And yes, the run system is somewhat messy in that these files are created in several different ways.

If these files aren’t generated, the Vivado GUI will get confused on whether the runs have taken place or not. In particular, the synth_1 run will stand at “Scripts Generated” even after a full implementation.

Bottom line
Recall that the reason for all this diving into the Vivado runs mechanism, was to perform these runs with log output on the console.

The ISEWrap.sh wrapper (actually, the way it’s used) is the reason why there is no output to console during the run’s execution. The end of runme.sh goes:

```sh
ISEStep="./ISEWrap.sh"
EAStep()
{
     $ISEStep $HD_LOG "$@" >> $HD_LOG 2>&1
     if [ $? -ne 0 ]
     then
         exit
     fi
}

# pre-commands:
/bin/touch .init_design.begin.rst

EAStep vivado -log top.vdi -applog -m64 -messageDb vivado.pb -mode batch -source top.tcl -notrace
```
The invocation of vivado is done by calling EAStep() with the desired command line as arguments. This is passed on by EAStep() to the wrapper as arguments, which in turn executes vivado as required, along with the creating of the begin-end files. But note the redirection (marked in red) to the log file. It goes there, but not to console.

So one possibility is to rewrite runme.sh slightly, and modify EAStep() so it uses the “tee” UNIX utility or doesn’t redirect at all into a log file. Or modify the wrapper for your own needs. I went for option B (there were plenty of scripts anyhow in my build system).


