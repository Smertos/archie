#!/usr/bin/sh

# TODO: replace with something POSIX-compliant
source ./settings.sh

# setup constants, no need to touch these
MOUNT_TARGET="/mnt"
PACKAGES="base base-devel $KERNEL linux-firmware grub efibootmgr os-prober amd-ucode xf86-video-amdgpu xorg gdm neovim git wget $PACKAGES_EXTRAS"

DEVICE_BOOT="${TARGET_DISK_DEVICE}1"
MOUNT_BOOT="${MOUNT_TARGET}/boot"

DEVICE_EFI="${TARGET_DISK_DEVICE}2"
MOUNT_EFI="${MOUNT_TARGET}/boot/EFI"

DEVICE_SWAP="${TARGET_DISK_DEVICE}3"
DEVICE_ROOT="${TARGET_DISK_DEVICE}4"

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

_run_in_chroot() {
    arch-chroot "$MOUNT_TARGET" bash -c "$*"
}

check_setup() {
    # check for curl
    if [ ! -e /sys/firmware/efi/efivars ]; then
        _drop 100 "efivars not found. Check if your system supports UEFI."
    fi

    # check for curl
    if [ ! "$(which curl)" ]; then
        _drop 101 "curl not found"
    fi

    # check for internet connection
    NET_CURL_TEST_RESULT="$(curl -Is https://www.google.com/ | grep content-type)"
    if [ ! "$NET_CURL_TEST_RESULT" ]; then
        _drop 102 "couldn't confirm presence of internet connection"
    fi

    # check for curl
    if [ ! "$(which pacman)" ]; then
        _drop 103 "pacman not found. You sure you're running ArchLinux :?"
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
    mkfs.fat -F 32 "$DEVICE_BOOT"
    mkfs.fat -F 32 "$DEVICE_EFI"
    mkswap "$DEVICE_SWAP"
    mkfs.ext4 -qF "$DEVICE_ROOT"

    # use swap right away
    swapon "$DEVICE_SWAP"

    # mount the rest of partitions
    mount "$DEVICE_ROOT" "$MOUNT_TARGET"

    mkdir "$MOUNT_BOOT"
    mount "$DEVICE_BOOT" "$MOUNT_BOOT"

    mkdir "$MOUNT_EFI"
    mount "$DEVICE_EFI" "$MOUNT_EFI"

    echo "Partitioning & mounting is done"
}

setup() {
    # Install all the packages
    pacstrap /mnt $PACKAGES

    # Generate filesystem mount map
    genfstab -U "$MOUNT_TARGET" > "${MOUNT_TARGET}/etc/fstab"

    # Setup our timezone
    _run_in_chroot "ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime"

    # Set a host name
    _run_in_chroot "echo $HOSTNAME > /etc/hostname"

    # Generate /etc/adjtime
    _run_in_chroot "hwclock --systohc"

    # Setup locale
    ## Backup full locale list
    if [ ! -e "$MOUNT_TARGET/etc/locale.gen.full"  ]; then
        _run_in_chroot "mv /etc/locale.gen /etc/locale.gen.full"
    fi

    ## Filter out the locale we need and keep it
    _run_in_chroot "cat /etc/locale.gen.full | grep -m1 $SYSTEM_LOCALE | cut -c3-99 > /etc/locale.gen"
    _run_in_chroot "echo LANG=$SYSTEM_LOCALE > /etc/locale.conf"

    ## Generate kept locales
    locale-gen

    # Setup hosts file
    _run_in_chroot "echo 127.0.0.1	localhost > /etc/hosts"
    _run_in_chroot "echo ::1		localhost >> /etc/hosts"
    _run_in_chroot "echo 127.0.1.1	${HOSTNAME}.localdomain	${HOSTNAME} >> /etc/hosts"


    # Create new initramfs
    _run_in_chroot "mkinitcpio -P"

    # Install GRUB
    _run_in_chroot "grub-install --target=x86_64-efi --efi-directory=/boot/EFI --bootloader-id=GRUB"
    _run_in_chroot "grub-mkconfig -o /boot/grub/grub.cfg"

    echo "Basic setup is finished"
    echo "Don't forget to setup root password and create all the users you need"
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
