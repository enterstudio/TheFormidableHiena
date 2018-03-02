Title: How to program flash without a Vivado SDK project
Category: Xilinx
Tags: zynq, vivado, fpga, soc
Date: 2018-03-01 22:36

Follow these steps:

1. Open XSDK directly (not from Vivado)

![Open XSDK outside Vivado](/images/Xilinx/open_sdk_alone.gif)

2. You will need to be provided three files: fsbl.elf, BOOT.bin, design.hdf (names might be different)

3. Drag the hardware file (design.hdf in this example) into the SDK's Project Explorer. This will create a hardware project.

4. From SDK's menu Xilinx, choose "Program Flash"

5. Click on "Browse" for the Image file and select the BOOT.bin file

6. Click on "Browse" for the FSBL file and choose the fsbl.elf file 

7. Make sure your board JTAG/USB is connected to your computer. 

8. Make sure your board's OTG USB is NOT connected to your computer

9. Select the boot jumper to JTAG (NOT QSPI).

10. Hit "Program" and wait until it completes. 

11. switch off power on the board

12. Select the boot jumper to QSPI

13. Put a micro usb card on the board

14. Power on board

15. Connect the USB/OTG cable to your computer

16. You should see a popup either asking to view files or to format the card, if it is not formatted.

17. If the card is not formatted, format it to FAT32

18. Copy some files or create some text inside the storage

19. Eject the storage device and remove the micro SD card 

20. Open the micro SD card in a card reader and check that you see the files you created.

![Program Flash](/images/Xilinx/program_flash_sdk.gif)