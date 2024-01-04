# Library Modification Instructions

This folder contains libraries and ELF files that require modification using `patchelf` to ensure proper functionality within the application. Follow the instructions below to modify the libraries and associated ELF files:

## Modifying Libraries:

### 1. Setting DT_RPATH for Libraries:
Use the following command to set the DT_RPATH for a library (makes the library use shared object files from that folder instead of from system-defined path):  
`patchelf --force-rpath libraryName`  
`patch --set-rpath /home/jmactf/server5.8/games/jma-capturetheflag/mods/libs libraryName`

### 2. Modifying libc.so.6
In addition to setting DT_RPATH, libc requires to set the interpreter to the linker, matching the library version, which is also provided in this folder.  
`patchelf --set-interpreter /home/jmactf/server5.8/games/jma-capturetheflag/mods/libs/ld-linux-x86-64.so.2 libc.so.6`
