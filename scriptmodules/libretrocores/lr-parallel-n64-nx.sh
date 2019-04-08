#!/usr/bin/env bash

# This file is part of The RetroArena (TheRA)
#
# The RetroArena (TheRA) is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/Retro-Arena/RetroArena-Setup/master/LICENSE.md
#

rp_module_id="lr-parallel-n64-nx"
rp_module_desc="N64 emu - Highly modified Mupen64Plus port for libretro nx"
rp_module_help="ROM Extensions: .z64 .n64 .v64\n\nCopy your N64 roms to $romdir/n64"
rp_module_licence="GPL2 https://raw.githubusercontent.com/libretro/parallel-n64/master/mupen64plus-core/LICENSES"
rp_module_section="lr"

function depends_lr-parallel-n64-nx() {
    local depends=()
    isPlatform "x11" && depends+=(libgl1-mesa-dev)
    isPlatform "rpi" && depends+=(libraspberrypi-dev)
    getDepends "${depends[@]}"
}

function sources_lr-parallel-n64-nx() {
   gitPullOrClone "$md_build" https://github.com/sikotik/paraLLeXT.git 
    
}

function build_lr-parallel-n64-nx() {
    rpSwap on 1000
    make clean
    local params=()
    if isPlatform "rockpro64" || isPlatform "odroid-xu"; then
        params+=(platform="$__platform")
    elif isPlatform "odroid-n2"; then
        params+=(platform="unix $_platform")
    fi
    make "${params[@]}"
    rpSwap off
    md_ret_require="$md_build/parallel_n64-nx_libretro.so"
}

function install_lr-parallel-n64-nx() {
    md_ret_files=(
        'parallel_n64-nx_libretro.so'
        'README.md'
    )
}

function install_bin_lr-parallel-n64-nx() {
    downloadAndExtract "$__gitbins_url/lr-parallel-n64-nx.tar.gz" "$md_inst" 1
}

function configure_lr-parallel-n64-nx() {
    mkRomDir "n64"
    ensureSystemretroconfig "n64"

    # Set core options
    setRetroArchCoreOption "parallel-n64-nx-gfxplugin" "auto"
    setRetroArchCoreOption "parallel-n64-nx-gfxplugin-accuracy" "low"
    setRetroArchCoreOption "parallel-n64-nx-screensize" "640x480"

    # Copy config files
    cat > $datadir/BIOS/gles2n64rom.conf << _EOF_
#rom specific settings

rom name=SUPER MARIO 64
target FPS=25

rom name=Kirby64
target FPS=25

rom name=Banjo-Kazooie
framebuffer enable=1
update mode=4
target FPS=25

rom name=BANJO TOOIE
hack banjo tooie=1
ignore offscreen rendering=1
framebuffer enable=1
update mode=4

rom name=STARFOX64
window width=864
window height=520
target FPS=27

rom name=MARIOKART64
target FPS=27

rom name=THE LEGEND OF ZELDA
texture use IA=0
hack zelda=1
target FPS=17

rom name=ZELDA MAJORA'S MASK
texture use IA=0
hack zelda=1
rom name=F-ZERO X
window width=864
window height=520
target FPS=55
rom name=WAVE RACE 64
window width=864
window height=520
target FPS=27
rom name=SMASH BROTHERS
framebuffer enable=1
window width=864
window height=520
target FPS=27
rom name=1080 SNOWBOARDING
update mode=2
target FPS=27
rom name=PAPER MARIO
update mode=4
rom name=STAR WARS EP1 RACER
video force=1
video width=320
video height=480
rom name=JET FORCE GEMINI
framebuffer enable=1
update mode=2
ignore offscreen rendering=1
target FPS=27
rom name=RIDGE RACER 64
window width=864
window height=520
enable lighting=0
target FPS=27
rom name=Diddy Kong Racing
target FPS=27
rom name=MarioParty
update mode=4
rom name=MarioParty3
update mode=4
rom name=Beetle Adventure Rac
window width=864
window height=520
target FPS=27
rom name=EARTHWORM JIM 3D
rom name=LEGORacers
rom name=GOEMONS GREAT ADV
window width=864
window height=520
rom name=Buck Bumble
window width=864
window height=520
rom name=BOMBERMAN64U2
window width=864
window height=520
rom name=ROCKETROBOTONWHEELS
window width=864
window height=520
rom name=GOLDENEYE
force screen clear=1
framebuffer enable=1
window width=864
window height=520
target FPS=25
rom name=Mega Man 64
framebuffer enable=1
target FPS=25
_EOF_
    chown $user:$user "$biosdir/gles2n64rom.conf"

    addEmulator 0 "$md_id" "n64" "$md_inst/parallel_n64-nx_libretro.so"
    addSystem "n64"
}
