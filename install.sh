#!/usr/bin/sh

# setup variables
TARGET_DISK_DEVICE=""
SYSTEM_LOCALE="en_US.UTF-8"
PACKAGES_EXTRAS=""

# setup constants, no need to touch these
MOUNT_TARGET="/mnt"
PACKAGES="base base-dev xorg gdm neovim git wget $PACKAGES_EXTRAS"

_contains() {
    if [ "$1" = "${1/$2/xd}" ]; then
        return 1 # doesn't contain
    else
        return 0 # does contain
    fi
}

_drop() {
    echo "ERROR: $2"
    exit "$1"
}

_pacman_install() {
    # check for curl
    if [ ! "$(which curl)" ]; then
        _drop 69 "pacman wan't found"
    fi

    pacman -S --noconfirm $*
}

check_setup() {
    # check for curl
    if [ ! "$(which curl)" ]; then
        _drop 101 "curl wan't found"
    fi

    # check for internet connection
    NET_CURL_TEST_RESULT="$(curl -Is https://www.google.com/ | grep content-type)"
    if [ ! "$NET_CURL_TEST_RESULT" ]; then
        _drop 102 "couldn't confirm presence of internet connection"
    fi

    echo "All setup checks passed!"
}

pre_setup() {
    # Enable network time sync
    if [ ! "$(timedatectl set-ntp true && echo 1)" ]; then
        _drop 201 "Failed to setup network time sync"
    fi

    # Update package db
    pacman -Sy

    echo "Pre-setup is done"
}

partition() {
    # Partition the device
    fdisk "$TARGET_DISK_DEVICE" < ./fdisk_commands

    # make partitions
    mkfs.fat -F 32 "${TARGET_DISK_DEVICE}1"
    mkfs.fat -F 32 "${TARGET_DISK_DEVICE}1"
    mkswap "${TARGET_DISK_DEVICE}3"
    mkfs.ext4 -qF "${TARGET_DISK_DEVICE}4"

    # use swap right away
    swapon "${TARGET_DISK_DEVICE}3"

    echo "Partitioning is done"
}

setup() {


    echo "Setup is finished"
}


if [ ! "$TARGET_DISK_DEVICE" ]; then
    _drop 1 "Please specify target disk device"
fi

if [ ! "$SYSTEM_LOCALE" ]; then
    _drop 2 "Please specify system locale"
fi

check_setup
pre_setup
partition
setup
