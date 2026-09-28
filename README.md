This is a work in progress RTL core of the original DMG Game Boy for the Sipeed Tang Nano 20k FPGA board since GBTang is broken. 
I took GBTang as a base for HDMI output, game selection menu, controller support and MicroSD interface.

For the DMG Game Boy core I took VerilogBoy from Wenting Zhang and debugged it a lot, since the original core is highly inaccurate.

For installation, one must follor the SNESTang guide, the firmware can be found in this repository in the firmware folder.

SNESTang installation guide: https://github.com/nand2mario/snestang/blob/main/doc/installation.md

And as a last detail, one must provide the original binary of the Nintendo logo under an archive called "bootrom.mif", getting
the HEX code and creating a new file, pasting the code and renaming it is enough.
"bootrom.mif" should be placed in "src/VerilogBoy".
