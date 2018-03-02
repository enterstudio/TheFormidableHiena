Title: Boot image zynq
Category: Xilinx
Tags: zynq, vivado, fpga, soc
Date: 2018-03-02 12:48

# Boot image
There are two possible variants how you can act:
1) Go and try to make XAPP1079 alive by yourself.
2) Read my boring digging in asm.

## Boring 'asm' stuff
To start both CPU some changes in files 'boot.S' and 'asm_vectors.S' were made.
These files contain in the folder '$PROJECT_NAME_bsp\ps7_cortexa9_0\libsrc\standalone_vX_X\src\'.
These two files are executed before program jumps to the c-program entry point - 'main' function.
In the loader script next sections are defined:

```c
SECTIONS
{
.text : {
   *(.vectors)
   *(.boot)
   *(.text)
    ...
```
In file 'asm_vectors.S' first section - 'vectors' is described like:
```asm
.section .vectors
    _vector_table:
    B	_boot
    ...
    #if XPAR_CPU_ID==0
    _cpu0_catch:
        .word	OKToRun			
    _cpu1_catch:
        .word	EndlessLoop0	
    #elif XPAR_CPU_ID==1
    _cpu0_catch:
        .word	EndlessLoop0
    _cpu1_catch:
        .word	OKToRun
    #endif
    IRQHandler:
    ...
```
This means, that code under tag '_boot' is the code that will be executed right after reset and tags '_cpu0_catch' and '_cpu1_catch' will appear right after vector table at addresses 0x20 and 0x24 accordingly:
![ZynqBoot](/images/Xilinx/zynq_boot.png)

The first instruction that is executed after reset is:
```asm
_prestart:
_boot:
    mrc p15,0,r1,c0,c0,5
```
This instruction reads CPU ID register into the r1 working register.
![Boot](/images/Xilinx/zynq_boot_mrc_p15.png)

After that code compares 'r1' value with 0xf.
If not 0x0 received, execution branches to the 'NotCpu0' tag, cause for CPU0 it should be 0x0:
```asm
and	r1, r1, #0xf
cmp	r1, #0
bne	NotCpu0
```
If CPU is CPU0, then execution branches to the '_cpu0_catch' tag:
```asm
ldr r0, =_cpu0_catch
b cpuxCont
...
cpuxCont:
    ldr lr, [r0]
    bx	lr
```
In file 'asm_vectors.S' for CPU0 tags '_cpu0_catch' and '_cpu1_catch' are described as:
```asm
#if XPAR_CPU_ID==0
_cpu0_catch:
    .word   OKToRun			
_cpu1_catch:
    .word   EndlessLoop0
```
'OKToRun' is tag for code that will initialize CPU and jumps to the c-program entry point:
b	_start  /* jump to C startup code */
At that point CPU0 will be started and running c-code.
For the second CPU - CPU1, this code executes in the next way:
```asm
NotCpu0:
    cmp	r1, #1
    bne	EndlessLoop0
    ldr	r0, =_cpu1_catch
	b cpuxCont
```
As I mentioned earlier 'r1' here caries value of CPU ID register, so if CPU not CPU0 or CPU1, code comes to the endless loop:
```asm
EndlessLoop0:
    wfe
    b	EndlessLoop0
```
If CPU is not CPU0 but CPU1, tags '_cpu0_catch' and '_cpu1_catch' will contain next code:
```asm
#elif XPAR_CPU_ID==1
_cpu0_catch:
    .word	EndlessLoop0
_cpu1_catch:
    .word	OKToRun
#endif
```
All this means that if we start execute software on CPU0 we can set address for CPU1's program entry point in address 0x24 in '_cpu1_catch' tag and after reset, CPU1 jumps to this tag and to its entry point consequently.
And the same logic is appropriate for CPU1 starts CPU0.
Function that makes such operation looks like this:
```asm
inline void Start_CPU_1(void) {
	//Disable cache on OCM
	Xil_SetTlbAttributes(0xFFFF0000, 0x14de2);           // S=b1 TEX=b100 AP=b11, Domain=b1111, C=b0, B=b0
	//Disable cache on fsbl vector table location
	Xil_SetTlbAttributes(0x00000000, 0x14de2);           // S=b1 TEX=b100 AP=b11, Domain=b1111, C=b0, B=b0
	/*
	 *  Reset and start CPU1
	 *  - Application for cpu1 exists at 0x00000000 per cpu1 linkerscript
	 *
	 */
#include "xil_misc_psreset_api.h"
#include "xil_io.h"
#define A9_CPU_RST_CTRL     (XSLCR_BASEADDR + 0x244)
#define A9_RST1_MASK        0x00000002
#define A9_CLKSTOP1_MASK    0x00000020
#define CPU1_CATCH          0x00000024
#define XSLCR_LOCK_ADDR     (XSLCR_BASEADDR + 0x4)
#define XSLCR_LOCK_CODE     0x0000767B
	u32 RegVal;
	/*
	 * Setup cpu1 catch address with starting address of app_cpu1. The FSBL initialized the vector table at 0x00000000
	 * using a boot.S that checks for cpu number and jumps to the address stored at the
	 * end of the vector table in cpu0_catch and cpu1_catch entries.
	 * Note: Cache has been disabled at the beginning of main(). Otherwise
	 * a cache flush would have to be issued after this write
	 */
	Xil_Out32(CPU1_CATCH, APP_CPU1_ADDR);
	/* Unlock the slcr register access lock */
	Xil_Out32(XSLCR_UNLOCK_ADDR, XSLCR_UNLOCK_CODE);
	//    the user must stop the associated clock, de-assert the reset, and then restart the clock. During a
	//    system or POR reset, hardware automatically takes care of this. Therefore, a CPU cannot run the code
	//    that applies the software reset to itself. This reset needs to be applied by the other CPU or through
	//    JTAG or PL. Assuming the user wants to reset CPU1, the user must to set the following fields in the
	//    slcr.A9_CPU_RST_CTRL (address 0xF8000244) register in the order listed:
	//    1. A9_RST1 = 1 to assert reset to CPU0
	//    2. A9_CLKSTOP1 = 1 to stop clock to CPU0
	//    3. A9_RST1 = 0 to release reset to CPU0
	//    4. A9_CLKSTOP1 = 0 to restart clock to CPU0
	/* Assert and deassert cpu1 reset and clkstop using above sequence*/
	RegVal = Xil_In32(A9_CPU_RST_CTRL);
	RegVal |= A9_RST1_MASK;
	Xil_Out32(A9_CPU_RST_CTRL, RegVal);
	RegVal |= A9_CLKSTOP1_MASK;
	Xil_Out32(A9_CPU_RST_CTRL, RegVal);
	RegVal &= ~A9_RST1_MASK;
	Xil_Out32(A9_CPU_RST_CTRL, RegVal);
	RegVal &= ~A9_CLKSTOP1_MASK;
	Xil_Out32(A9_CPU_RST_CTRL, RegVal);
	/* lock the slcr register access */
	Xil_Out32(XSLCR_LOCK_ADDR, XSLCR_LOCK_CODE);
}
```
I gave you the fishing-rod and its up to you how you will fishing.
You can change files 'boot.S' and 'asm_vectors.S' in folder: 
'c:\Xilinx\SDK\20XX.X\data\embeddedsw\lib\bsp\standalone_vX_X\src\arm\cortexa9\gcc\' or use outdated XAPP1079's sdk. It is still possible to compile it in Vivado 2017.1, but it needs some heavy files patching.
I will not provide any additional details, cause if you need two RTOS you definitely know how to use tools.

I finished at this point. Good luck.
