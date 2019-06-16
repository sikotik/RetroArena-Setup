#!/usr/bin/env bash

# This file is part of The RetroArena (TheRA)
#
# The RetroArena (TheRA) is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/Retro-Arena/RetroArena-Setup/master/LICENSE.md
#

rp_module_id="usbromservice"
rp_module_desc="USB ROM Service"
rp_module_section="opt"

function _get_ver_usbromservice() {
    echo 0.0.24
}

function _update_hook_usbromservice() {
    ! rp_isInstalled "$md_idx" && return
    [[ ! -f "$md_inst/disabled" ]] && install_scripts_usbromservice
}

function install_bin_usbromservice() {
    local depends=(rsync ntfs-3g exfat-fuse)
    if ! hasPackage usbmount $(_get_ver_usbromservice); then
        depends+=(debhelper devscripts pmount lockfile-progs)
        getDepends "${depends[@]}"
        gitPullOrClone "$md_build/usbmount" https://github.com/rbrito/usbmount.git
        cd "$md_build/usbmount"
        dpkg-buildpackage
        dpkg -i ../usbmount_*_all.deb
        rm -f ../usbmount_*
    fi
    
    [[ ! -f "$md_inst/disabled" ]] && install_scripts_usbromservice
    touch "$md_inst/installed"
}

function install_scripts_usbromservice() {
    # copy our mount.d scripts over
    local file
    local dest
    for file in "$md_data/"*; do
        dest="/etc/usbmount/mount.d/${file##*/}"
        sed "s/USERTOBECHOSEN/$user/g" "$file" >"$dest"
        chmod +x "$dest"
    done
}

function enable_usbromservice() {
    rm -f "$md_inst/disabled"
    install_scripts_usbromservice
}

function disable_usbromservice() {
    local file
    for file in "$md_data/"*; do
        file="/etc/usbmount/mount.d/${file##*/}"
        rm -f "$file"
    done
    [[ -d "$md_inst" ]] && touch "$md_inst/disabled"
}

function remove_usbromservice() {
    disable_usbromservice
    apt-get remove -y usbmount
}

function configure_usbromservice() {
    iniConfig "=" '"' /etc/usbmount/usbmount.conf
    local fs
    for fs in ntfs exfat; do
        iniGet "FILESYSTEMS"
        if [[ "$ini_value" != *$fs* ]]; then
            iniSet "FILESYSTEMS" "$ini_value $fs"
        fi
    done
    iniGet "MOUNTOPTIONS"
    local uid=$(id -u $user)
    local gid=$(id -g $user)
    if [[ ! "$ini_value" =~ uid|gid ]]; then
        iniSet "MOUNTOPTIONS" "$ini_value,uid=$uid,gid=$gid"
    fi
}

function createdir_usbromservice() {
    if ls -la /var/run/usbmount | grep "\->" >/dev/null; then
        rsync -a -f"+ */" -f"- *" "$datadir/roms/" "/media/usb0/retroarena/roms/"
        printMsgs "dialog" "The 'retroarena/roms' directory structure has been created on the USB drive"
    else
        printMsgs "dialog" "USB drive is not mounted"
    fi
}

function synctousb_usbromservice() {
    if ls -la /var/run/usbmount | grep "\->" >/dev/null; then
        if [[ ! -d "/media/usb0/retroarena/roms" ]]; then
            mkdir -p "/media/usb0/retroarena" "/media/usb0/retroarena/roms"
        fi
        echo "---------------------------------------------------"
        echo "Unmounting '$datadir/roms'........"
        umount -l "$datadir/roms"
        cd ~
        echo "---------------------------------------------------"
        echo "Sync from SD to USB 'roms' is now starting........."
        rsync -rtu --human-readable --no-i-r --copy-links --info=progress2 "$datadir/roms/" "/media/usb0/retroarena/roms/"
        printMsgs "dialog" "Sync completed!\n\nOnce rebooted, it will automatically mount the USB drive.\n\nPress OK to reboot!"
        reboot
    else
        printMsgs "dialog" "USB drive is not mounted"
    fi
}

function synctosd_usbromservice() {
    if ls -la /var/run/usbmount | grep "\->" >/dev/null; then
        echo "---------------------------------------------------"
        echo "Sync from USB to SD 'RetroArena' is now starting..."
        rsync -rtu --human-readable --no-i-r --copy-links --info=progress2 "/media/usb0/retroarena-sync/" "$datadir/"
        printMsgs "dialog" "Sync completed!"
    else
        printMsgs "dialog" "USB drive is not mounted"
    fi
}

function gui_usbromservice() {
    local avail=$(df -h | awk '$NF == "/" { print $4 }')
    local cmd
    local options
    local choice
    while true; do
        cmd=(dialog --backtitle "$__backtitle" --menu "Choose from an option below." 22 86 16)
        options=(
            1 "Sync from SD to USB 'roms'"
            2 "Sync from SD to USB 'roms' directory structure only"
            3 "Sync from USB 'retroarena-sync' to SD 'RetroArena'"
            4 "Enable USB ROM Service"
            5 "Disable USB ROM Service"
        )
        choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
        if [[ -n "$choice" ]]; then
            case "$choice" in
                1)
                    printMsgs "dialog" "This will sync all folders and files from the SD card '$datadir/roms' directory to the USB drive 'retroarena/roms' directory.\n\nOnly the 'retroarena/roms' folder is mounted due to various system requirements.\n\nWARNING: This may take a long time. Press OK to continue."
                    synctousb_usbromservice
                    ;;
                2)
                    printMsgs "dialog" "This will sync only the folder structure of the SD card '$datadir/roms' directory to the USB drive 'retroarena/roms' directory.\n\nPress OK to continue."
                    createdir_usbromservice
                    ;;
                3)
                    printMsgs "dialog" "This will sync all folders and files from the USB drive 'retroarena-sync' directory to the SD card '$datadir' directory.\n\nThe SD card has $avail of available space. Ensure the USB drive 'retroarena-sync' directory does NOT have more than $avail of files being copied.\n\nWARNING: This may take a long time. Press OK to continue."
                    synctosd_usbromservice
                    ;;
                4)
                    rp_callModule "$md_id" enable
                    printMsgs "dialog" "Enabled $md_desc\n\nOnly 'retroarena/roms' directory will be mounted on the USB drive.\n\nAll other directories will remain in the SD card, including: 'BIOS', 'settingsmenu', and 'splashscreens'."
                    ;;
                5)
                    rp_callModule "$md_id" disable
                    printMsgs "dialog" "Disabled $md_desc"
                    ;;
            esac
        else
            break
        fi
    done
}
