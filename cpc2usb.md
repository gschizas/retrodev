# CPC2USB #

This project permit use a usb pendrive how a normal amsdos disk drive, and extend it with directory support and similar "moderneces" :P

# Files of the source #

**ayuda.s**: Help messages that shows the |VHELP RSX.

**constantes.i**: Consts used by the project.

**error.i**: Error handlers.

**macros\_vdip.i**: Macros used by the project (could be subroutines, but now there is a lot of space in the vdrive.rom).

**vdrive.s**: The "Project" :P

# Todo #

  * Review the firmware patch code.
  * Add compatibility with other diskroms.
  * Push at the repository the code that generate a rom.
  * Think about include the video player and the file manager in the rom.