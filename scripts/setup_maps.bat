@echo off
setlocal enabledelayedexpansion

REM Check if the working directory argument is provided
if "%~1"=="" (
    echo Usage: %~nx0 ^<working_directory^>
    exit /b 1
)

set "working_directory=%~1"

REM Convert relative path to absolute path
pushd "%working_directory%"
set "working_directory=%cd%"
popd

REM Check if ./mods directory exists in the working directory
if not exist "%working_directory%\mods\" (
    echo Error: The %working_directory%\mods directory does not exist.
    exit /b 1
)

set "textures_path=%working_directory%\mods\ctf\ctf_map\textures"
set "maps_path=%working_directory%\mods\ctf\ctf_map\maps"

echo Textures path: %textures_path%
echo Maps path: %maps_path%
echo.

REM Clean up old generated files in textures directory
echo Cleaning up old generated files...
if exist "%textures_path%\" (
    del /f /q "%textures_path%\*_screenshot.png" 2>nul
    del /f /q "%textures_path%\*Up.png" 2>nul
    del /f /q "%textures_path%\*Down.png" 2>nul
    del /f /q "%textures_path%\*Front.png" 2>nul
    del /f /q "%textures_path%\*Back.png" 2>nul
    del /f /q "%textures_path%\*Left.png" 2>nul
    del /f /q "%textures_path%\*Right.png" 2>nul
    echo Old files cleaned up
)
echo.

REM Process each map subdirectory using full path in the for loop
set "map_count=0"
for /d %%d in ("%maps_path%\*") do (
    set /a map_count+=1
    set "map_dir=%%d"
    set "map_name=%%~nxd"
    
    echo [!map_count!] Processing map: !map_name!
    
    REM Copy map screenshot to textures dir
    if exist "!map_dir!\screenshot.png" (
        copy /y "!map_dir!\screenshot.png" "%textures_path%\!map_name!_screenshot.png" >nul
        echo     Copied screenshot
    )
    
    REM Move skybox textures into map skybox folder if they aren't already there
    if exist "!map_dir!\skybox_1.png" (
        if not exist "!map_dir!\skybox\" (
            mkdir "!map_dir!\skybox"
        )
        
        REM Copy and rename skybox files
        if exist "!map_dir!\skybox_1.png" copy /y "!map_dir!\skybox_1.png" "!map_dir!\skybox\Up.png" >nul
        if exist "!map_dir!\skybox_2.png" copy /y "!map_dir!\skybox_2.png" "!map_dir!\skybox\Down.png" >nul
        if exist "!map_dir!\skybox_3.png" copy /y "!map_dir!\skybox_3.png" "!map_dir!\skybox\Front.png" >nul
        if exist "!map_dir!\skybox_4.png" copy /y "!map_dir!\skybox_4.png" "!map_dir!\skybox\Back.png" >nul
        if exist "!map_dir!\skybox_5.png" copy /y "!map_dir!\skybox_5.png" "!map_dir!\skybox\Left.png" >nul
        if exist "!map_dir!\skybox_6.png" copy /y "!map_dir!\skybox_6.png" "!map_dir!\skybox\Right.png" >nul
        
        REM Remove original numbered skybox files
        del /f /q "!map_dir!\skybox_*.png" 2>nul
        echo     Processed skybox files
    )
    
    REM Copy skybox textures to textures dir where Minetest can find them
    if exist "!map_dir!\skybox\" (
        if exist "!map_dir!\skybox\Up.png" copy /y "!map_dir!\skybox\Up.png" "%textures_path%\!map_name!Up.png" >nul
        if exist "!map_dir!\skybox\Down.png" copy /y "!map_dir!\skybox\Down.png" "%textures_path%\!map_name!Down.png" >nul
        if exist "!map_dir!\skybox\Front.png" copy /y "!map_dir!\skybox\Front.png" "%textures_path%\!map_name!Front.png" >nul
        if exist "!map_dir!\skybox\Back.png" copy /y "!map_dir!\skybox\Back.png" "%textures_path%\!map_name!Back.png" >nul
        if exist "!map_dir!\skybox\Left.png" copy /y "!map_dir!\skybox\Left.png" "%textures_path%\!map_name!Left.png" >nul
        if exist "!map_dir!\skybox\Right.png" copy /y "!map_dir!\skybox\Right.png" "%textures_path%\!map_name!Right.png" >nul
        
        echo     Copied skybox textures
    )
)

echo.
if !map_count! equ 0 (
    echo WARNING: No map subdirectories found!
) else (
    echo Successfully processed !map_count! maps
)

echo.
echo Script completed successfully
exit /b 0