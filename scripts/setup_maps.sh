#!/bin/bash
set -e

# Go back if we're inside the scripts folder
if [ -f setup_maps.sh ]; then
    cd ..
fi

# Check and remove broken symlinks in the current directory
find ./mods/ctf/ctf_map/textures/ -type l ! -exec test -e {} \; -exec rm {} +

cd mods/ctf/ctf_map/maps/

# Create symlinks for textures from map sub-dirs to ctf_map_core/textures
for f in *; do
    if [ -d "${f}" ]; then
        # Create symlink for map screenshot in textures dir
        if [ -f "${f}/screenshot.png" ]; then
            ln -sf "$(pwd)/${f}/screenshot.png" "$(pwd)/../textures/${f}_screenshot.png"
        fi

        # Move skybox textures into map skybox folder if they aren't already there
        if [ -f "${f}/skybox_1.png" ]; then
            if [ ! -d "${f}/skybox/" ]; then
                mkdir "${f}/skybox/"
            fi

            ln -sf "$(pwd)/${f}/skybox_1.png" "$(pwd)/${f}/skybox/Up.png"
            ln -sf "$(pwd)/${f}/skybox_2.png" "$(pwd)/${f}/skybox/Down.png"
            ln -sf "$(pwd)/${f}/skybox_3.png" "$(pwd)/${f}/skybox/Front.png"
            ln -sf "$(pwd)/${f}/skybox_4.png" "$(pwd)/${f}/skybox/Back.png"
            ln -sf "$(pwd)/${f}/skybox_5.png" "$(pwd)/${f}/skybox/Left.png"
            ln -sf "$(pwd)/${f}/skybox_6.png" "$(pwd)/${f}/skybox/Right.png"
            rm "${f}/skybox_*.png"
        fi

        # Move skybox textures to textures dir where Minetest can find them
        if [ -d "${f}/skybox/" ]; then
            ln -sf "$(pwd)/${f}/skybox/Up.png"    "$(pwd)/../textures/${f}Up.png"
            ln -sf "$(pwd)/${f}/skybox/Down.png"  "$(pwd)/../textures/${f}Down.png"
            ln -sf "$(pwd)/${f}/skybox/Front.png" "$(pwd)/../textures/${f}Front.png"
            ln -sf "$(pwd)/${f}/skybox/Back.png"  "$(pwd)/../textures/${f}Back.png"
            ln -sf "$(pwd)/${f}/skybox/Left.png"  "$(pwd)/../textures/${f}Left.png"
            ln -sf "$(pwd)/${f}/skybox/Right.png" "$(pwd)/../textures/${f}Right.png"
        fi
    fi
done
