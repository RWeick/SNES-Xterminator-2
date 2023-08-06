# SNES-Xterminator-2
The Kicad files, rom dump, and GAL JEDEC for the SNES Xterminator 2 cheat device. I have redone the trace layout and added additional pads for SMD components.  
Standard jumper configuration: Pads 2, 4, 6, 8, 10, and 12 are shorted.  

Preliminary analysis suggests the following operation of the GAL, multiplexer, and NAND gates:  

/O19 = A 0xFFE8 and BA 0x0, 0x2, 0x4, 0x6

/SRAM.CS = A 0x2C00 to 0x2FFF and BA 0x0 to 0x1F

When Famicom cart is inserted, Famicom CICs 1 and 2 are connected to the system.
When Famicom cart is not inserted, SNES cart CICs 1 and 2 are connected to the system.

The operation of the 18CV8PC is unknown at this time, but I will be analyzing it in operation for reverse engineering.

Main Board PCB Thickness: 1.2 mm  
Cartridge Connector Board PCB Thickness: 1.6 mm  

![image](https://github.com/RWeick/SNES-Xterminator-2/blob/main/Xterminator2.png)
![image](https://github.com/RWeick/SNES-Xterminator-2/blob/main/Xterminator2_Top.png)
