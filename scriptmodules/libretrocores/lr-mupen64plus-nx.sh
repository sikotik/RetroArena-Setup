#!/usr/bin/env bash

# This file is part of The RetroArena (TheRA)
#
# The RetroArena (TheRA) is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/Retro-Arena/RetroArena-Setup/master/LICENSE.md
#

rp_module_id="lr-mupen64plus-nx"
rp_module_desc="N64 emu - Highly modified Mupen64Plus port for libretro"
rp_module_help="ROM Extensions: .z64 .n64 .v64\n\nCopy your N64 roms to $romdir/n64"
rp_module_licence="GPL3 https://raw.githubusercontent.com/libretro/mupen64plus-libretro-nx/mupen_next/LICENSE"
rp_module_section="lr"
rp_module_flags=""

function sources_lr-mupen64plus-nx() {
    gitPullOrClone "$md_build" https://github.com/libretro/mupen64plus-libretro-nx.git mupen_next
    isPlatform "rockpro64" && applyPatch "$md_data/rockpro64.patch"
}

function build_lr-mupen64plus-nx() {
    make clean
    local params=()
    if isPlatform "odroid-n2"; then
        params+=(platform=odroid64 BOARD=N2)
    elif isPlatform  "odroid-xu"; then
        params+=(platform=odroid BOARD=ODROID-XU)
    elif isPlatform "rockpro64"; then
        params+=(platform=rockpro64)
    else
        exit
    fi
    make "${params[@]}"
    md_ret_require="$md_build/mupen64plus_next_libretro.so"
}

function install_lr-mupen64plus-nx() {
    md_ret_files=(
        'mupen64plus_next_libretro.so'
        'README.md'
    )
}

function install_bin_lr-mupen64plus-nx() {
    downloadAndExtract "$__gitbins_url/lr-mupen64plus-nx.tar.gz" "$md_inst" 1
}

function configure_lr-mupen64plus-nx() {
    mkRomDir "n64"
    ensureSystemretroconfig "n64"

    addEmulator 0 "$md_id" "n64" "$md_inst/mupen64plus_next_libretro.so"
    addSystem "n64"
}
