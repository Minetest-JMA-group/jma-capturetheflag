# Library Modification Instructions

This folder contains libraries and ELF files that require modification using `patchelf` to ensure proper functionality within the application. Follow the instructions below to modify the libraries and associated ELF files:

## Modifying Libraries:

### 1. Setting DT_RPATH for Libraries:
Use the following command to set the DT_RPATH for a library (makes the library use shared object files from that folder instead of from system-defined path):  
This is necessary both for libraries in this folder and in mod folders  
`patchelf --force-rpath libraryName`  
`patchelf --set-rpath /home/jmactf/server5.8/games/jma-capturetheflag/libs libraryName`
