#!/usr/bin/sh

# setup variables
export HOSTNAME="" # name your heatin', memory-eating monster *nom-nom*
export KERNEL="linux" # name of kernel package aka 'linux', 'linux-lts', 'linux-zen', 'linux-hardened'
export PACKAGES_EXTRAS="" # list of additional packages to installed, separated by spaces
export SYSTEM_LOCALE="en_US.UTF-8" # locale name from /etc/locale.gen
export TARGET_DISK_DEVICE="" # should be something like '/dev/sdx'
export TIMEZONE="Asia/Yekaterinburg" # do 'timedatectl list-timezones' to lookup exact name, in case you forgotten :)
