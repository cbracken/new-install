Arch Linux Install with UEFI Boot
=================================

This provides a basic rundown of the process of installing Arch Linux with the
following setup:

  * UEFI boot
  * Full-disk encryption
  * Sway WM using Wayland

For a more thorough walkthrough of the install instructions, see the
[Installation guide][install_guide].

This guide assumes a wired ethernet connection and a working DHCP server.


Create USB boot disk
--------------------

Download an install image from https://www.archlinux.org/download/, then write
it to a disk using `dd`. Reboot the machine to be imaged and use the machine's
BIOS features to boot from the USB drive in UEFI mode.


Set up your install environment
-------------------------------

Once booted, you'll be dropped to a root command prompt. We'll be doing our
install in English, but substituting any other language here will allow you to
follow the install steps in that language. Note that this only affects the
language used during the install process, and does _not_ affect the languages
of the installation.

    # Set the desired keyboard layout; e.g. jp106.
    # Full list in /usr/share/kbd/keymaps/**/*.map.gz
    loadkeys us

    # Generate localizations and set language.
    # Uncomment desired language(s), e.g. en_CA.UTF-8.
    vi /etc/locale.gen
    locale-gen
    export LANG=en_CA.UTF-8

Next we'll verify that the machine is booted in UEFI mode:

    ls /sys/firmware/efivars

If the directory does not exist, the system is likely booted in BIOS mode. You
will want to enter the BIOS and enable UEFI boot. Then reboot from the USB
drive in UEFI mode.


Check internet connection
-------------------------

This guide assumes a wired ethernet connection and a working DHCP server. To
verify your network interface is detected and enabled, run:

    ip link

To check if you have a working connection, try:

    ping archlinux.org

Assuming that's working, we'll set the system clock:

    timedatectl set-ntp true

Then verify the service status:

    timedatectl status


Prepare the disk
----------------

Next we'll partition and re-format the disk. The end result is that we'd like
to have two physical disk partitions -- an EFI boot partition and a main
partition which we'll manage via the Logical Volume Manager (lvm).


### Partition the disk

To list the current disks and partitions:

    fdisk -l

The following steps will assume that we're partitioning and formatting the disk
`/dev/sda`:

    cgdisk /dev/sda

For UEFI boot on a 2 TB drive, we want something like:

    sda1 512M type=ef00 /efi
    sda2 1.9T type=8e00 /


### Set up full-disk encryption

Optionally, we set up [LUKS full-disk encryption][luks_guide] on the main
partition. This can be skipped if not desired.

First, create a LUKS-encrypted container on the system partition:

    cryptsetup luksFormat /dev/sda2

Next, we open the container. The decrypted container will be available at
`/dev/mapper/sda2_crypt`.

    cryptsetup open --type luks /dev/sda2 sda2_crypt

Later, when we get to GRUB bootloader setup steps, we'll need to configure it
to recognize that the partition is encrypted, and prompt to decrypt.


### Create the logical volumes

Next we'll prepare the disk for use with the Logical Volume Manager
([LVM][lvm_guide]). LVM uses the kernel's device mapper to provide a system of
logical volumes that are independent of the underlying disk layout.

The basic building blocks of LVM are:
* Physical Volume (PV): a Unix block device node, usable for storage by LVM.
  For example, a hard disk, a physical partition, a loopback file, or a
  device-mapper file such as a dm-crypt volume, like we're using.
* Volume Group (VG): a group of PVs. Physical Extents (PEs) are allocated from
  a VG for use by a Logical Volume (LV).
* Logical Volume (LV): a 'virtual' or 'logical' partition that resides in a VG
  and is composed of Physical Extents (PEs). LVs are Unix block devices
  analogous to physical partitions, e.g., they can be directly formatted with a
  filesystem.
* Physical Extent (PE): the smallest contiguous extent (default 4 MiB) that
  resides in a VG and can be assigned to an LV. PEs can be thought of as parts
  of PVs that can be allocated to any given LV.

To view physical volumes, volume groups, and logical volumes, use:

    pvdisplay
    vgdisplay
    lvdisplay

To view all devices capable of being used as a physical volume, run:

    lvmdiskscan

We'll start by creating the physical volume for the disk:

    pvcreate /dev/sda2  # or /dev/mapper/sda2_crypt if using LUKS.

Next, we'll create a volume group, `vg0`:

    vgcreate vg0 /dev/sda2  # or dev/mapper/sda2_crypt if using LUKS.

Then, we'll partition that into logical volumes for the root partition and
swap:

    lvcreate -L 1.8T vg0 -n lv_root

If we need to tweak the size by some smaller amount, we can use lvresize with a
relative size. For example:

    lvresize -L +5G vg0 -n lv_root

Next, we'll use the remainder of the disk for swap:

    lvcreate -L 15.96G vg0 -n lv_swap


### Create filesystems for volumes

Format the EFI partition as 32-bit FAT:

    mkfs.fat -F32 /dev/sda1

Format the root filesystem as ext4:

    mkfs.ext4 /dev/mapper/vg0-lv_root

Format the swap partition:

    mkswap /dev/mapper/vg0-lv_swap
    swapon /dev/mapper/vg0-lv_swap

Mount the filesystems:

    mount /dev/mapper/vg0-lv_root /mnt
    mkdir /mnt/efi
    mount /dev/sda1 /mnt/efi


Install the base system
-----------------------

The disk is now prepared for installation and mounted under `/mnt`. Next, we'll
install the base system to the target disk.

### Bootstrap the install

First, we install the base system, kernel, and firmware blobs:

    pacstrap -i /mnt base linux linux-firmware

Next, we generate an `/etc/fstab` file to mount the disk partitions at boot
based on what's currently mounted:

    genfstab -U -p /mnt >> /mnt/etc/fstab
    cat /mnt/etc/fstab  # check it!


### Chroot ourselves into the new root filesystem

Now that we've got a basic install, we'll chroot jail ourselves into `/mnt`:

    arch-chroot /mnt

Since a system is literally not POSIX-compliant without `ed` and `vi`, and we
desperately need an editor from here on in, we'll install them now:

    pacman -S ed vi


### Set up system locales

Configure the available locales for the system. These are what will be
available to users on the final system, and also what we'll use during install
steps from here on in:

    vi /etc/locale.gen
    # uncomment en_CA, fr_CA, en_US, ja_JP
    locale-gen
    echo LANG=en_CA.UTF-8 > /etc/locale.conf
    export LANG=en_CA.UTF-8


### Create a console keymap that replaces caps lock with control

Since I prefer a control key where it was intended to be, we'll create a new
keyboard layout that remaps the Caps Lock key to control:

    cp /usr/share/kbd/keymaps/i386/qwerty/us.map.gz us-ctrlcaps.map.gz
    gunzip us-ctrlcaps.map.gz
    # edit the file to set keycode 58 to Control
    vi us-ctrlcaps.map
    gzip us-ctrlcaps.map
    cp us-ctrlcaps.map.gz /usr/share/kbd/keymaps/i386/qwerty/
    chown root /usr/share/kbd/keymaps/i386/qwerty/us-ctrlcaps.map.gz
    chgrp root /usr/share/kbd/keymaps/i386/qwerty/us-ctrlcaps.map.gz

Next, let's configure the system console keymap:

    vi /etc/vconsole.conf

Add the following to the file:

    KEYMAP=us   # or us-ctrlcaps if you do the step above
    FONT=Lat2-Terminus16   # if you want a fancy terminal font


### Configure system timezone

We'll set the system timezone to Vancouver, BC, Canada:

    ln -s /usr/share/zoneinfo/America/Vancouver /etc/localtime

Next, we generate sync the hardware clock to UTC based on the current system
time, and generate `/etc/adjtime`:

    hwclock --systohc --utc


### Set the hostname

Here, we set the system hostname:

    echo myawesomehostname > /etc/hostname

And generate the hosts file:

    vi /etc/hosts

The file contents should just contain the IPv4 and IPv6 entries for localhost:

    127.0.0.1	localhost
    ::1		localhost


### Configure DHCP

Arch, and most Linux distributions these days, use [systemd][systemd_guide] to
manage running daemons and logging. Now would be a good time do read up on it.

Install [dhcpcd][dhcpcd_guide]:

    pacman -S dhcpcd
    
Edit the configuration in `/etc/dhcpcd.conf` to add the interface to configure at the top of the file:

    interface eno1
    
Enable the service:

    systemctl enable dhcpcd.service
    
    
### Configure NTP

Install [ntpd][ntpd_guide]:

    pacman -S ntp
    
Then edit the `/etc/ntpd.conf`. It's recommended to add the `iburst` option at
the end of every `server` line in the config file. This triggers a burst of
packets only if it cannot obtain a connection on the first attempt. Do not use
the `burst` option, which sends a burst of packets on _all_ attempts and can
get you blacklisted.

Finally, enable the service:

    systemctl enable ntpd.service


Enable and start the NTP service:

    systemctl enable ntpd.service
    systemctl start ntpd.service



### Initramfs

The initial ramdisk is a very small environment which loads various kernel
modules and sets up necessary prerequisites before handing over control to
`init`. This makes it possible to have encrypted root filesystems and root
filesystems on a software RAID array. The `pacstrap` step earlier generates an
initial ramdisk, but since we're using LVM and full-disk encryption, we need to
generate a new one with those options enabled, using
[mkinitcpio][mkinitcpio_guide]. First, edit the config file:

    vi /etc/mkinitcpio.conf

We'll need to modify the `HOOKS` line to add `encrypt lvm2` immediately before
the `filesystems` entry on the line:

    HOOKS=(... block encrypt lvm2 filesystems ...)

Next, we'll then regenerate the initial ramdisk:

    mkinitcpio -p linux


### Set root passwd

Next, we'll set the root password:

    passwd

Once we've got `doas` installed in a later step, and an administrator user
created, we'll disable the root account, but for now, we'll want to be able to
log in as root to configure the system.


Install GRUB bootloader
-----------------------

Next up, let's install the [UEFI][uefi_guide]-capable GRUB bootloader:

    pacman -S grub efibootmgr
    grub-install --target=x86_64-efi \
                 --efi-directory=/efi \
                 --bootloader-id=GRUB \
                 --recheck \
                 --debug

### Install Intel/AMD microcode updates

Next, assuming we're using an Intel or AMD process, we'll enable microcode
loading support, to enable CPU microcode patching that fixes security issues or
bugs in the CPU.

If you have an Intel CPU:

    pacman -S intel-ucode

Or, if you have an AMD processor:

    pacman -S amd-ucode

In the `grub-mkconfig` step that follows, these packages are automatically
detected and GRUB will be configured appropriately.


### Configure LUKS encryption support

Next, if you elected to configure LUKS full-disk encryption above, we'll
configure GRUB to handle full-disk encryption, so it doesn't look like a
physical partition full of random noise:

    vi /etc/default/grub

Edit the `GRUB_CMDLINE_LINUX` line to indicate that /dev/sda2:vg0 is encrypted:

    GRUB_CMDLINE_LINUX="cryptdevice=/dev/sda2:vg0


### Regenerate GRUB config

Next regenerate the GRUB config file on the boot partition:

    grub-mkconfig -o /boot/grub/grub.cfg


Reboot
------

Exit the chroot environment by typing `exit` or pressing ctrl-d.

Unmount all partitions, in case any are busy:

    umount -R /mnt

Finally, reboot the machine by typing `reboot`. Once the machine reboots, yank
the USB drive so you boot from disk, not the USB drive.


Post-installation
-----------------

Now that we've got a working base system, we'll configure the machine to be
somewhat useful. Log in as `root`, with the password you set earlier for the
following steps.

### Install additional shells

Since zsh is generally a nicer ksh, and I prefer it to bash, let's install that
first:

    pacman -S zsh


### Create admin user

Next, let's create a new user and set their password:

    useradd -m -g users -G wheel -s /bin/zsh chris
    passwd chris


### Install doas

For security reasons, we'd like to disable the root account and force all
administrative actions to occur via the `doas` command. First install it:

    pacman -S opendoas

Then we edit `/etc/doas.conf` and uncomment (or add) the following line:

    permit nopass :wheel
    permit :wheel cmd reboot
    permit :wheel cmd shutdown
    permit nopass keepenv root as root

To verify this worked, log out of the root account, then log in as the admin
user created in the previous step and verify they can issue commands with
`doas`.

    doas ls /root

If that worked, lock-down the root account:

    doas passwd -l root

If you even need to unlock the root account, issue:

    doas passwd -u root

Now that the root account is disabled, the remainder of the steps should be
executed via doas from an admin user account.


### Install essential packages

First, we install core packages we can't live without:

    pacman -S man-db man-pages
    pacman -S openssh


### Configure auto-mounting USB devices

Next, we'll set up automounting USB disks. Since many of these are FAT32
format, we'll also install tools for dealing with DOS partitions:

    pacman -S udisks2
    pacman -S dosfstools


### Install useful packages

Since `vim` is far nicer to work in than `ed`, `ex`, or `vim`, we'll install
it first:

    pacman -S vim

Support for zip archives is handy:

    pacman -S zip unzip

Core tooling:

    pacman -S dnsutils

Next, terminal multiplexing support via tmux:

    pacman -S tmux

Next, compilers and development tools:

    pacman -S binutils
    pacman -S clang lld lldb
    pacman -S nasm

And, source control:

    pacman -S git tig

For a GUI environment, we install Sway, an i3-like Wayland-based window manager:

    pacman -S sway swaylock swayidle dmenu    # Use noto fonts if prompted
    pacman -S xorg-server-xwayland xorg-xrdb  # Xwayland support
    pacman -S alacritty                       # terminal

Next, install some additional Western and Japanese fonts:

    pacman -S adobe-source-code-pro-fonts
    pacman -S adobe-source-serif-pro-fonts
    pacman -S adobe-source-han-sans-otc-fonts
    pacman -S otf-ipafont
    pacman -S noto-fonts noto-fonts-cjk noto-fonts-emoji noto-fonts-extra

Finally, we need a web browser:

    pacman -S firefox


### Audio

It's useful to have the `alsa-utils` package installed for playing around with
audio levels via `alsa-mixer`.

    pacman -S alsa-utils
    pacman -S pulseaudio-alsa

Then start pulseaudio on user login:

    systemctl --user start pulseaudio

If using Intel HDA audio, via the `snd_hda_intel` kernel module you may need to
ensure the following line exists in `/etc/modprobe.d/alsa-base.conf` (or other
equivalent file you edit/create under the `/etc/modprobe.d` directory):

    options snd-hda-intel model=auto

Without this, Intel audio sometimes simply utterly fails to work.


### Install yay for AUR support

To support installing packages from AUR, we install the `yay` tool, which is a
wrapper around `pacman` similar to what `yaourt` used to support. First we
clone the source from AUR:

    git clone https://aur.archlinux.org/yay.git
    cd yay

Next we run `makepkg` with the `-s` (build from source) and `-i` (install)
options:

    makepkg -si

If you get a warning along the lines of "ERROR: Cannot find the fakeroot
binary", install it via the following command:

    pacman -S fakeroot

Fakeroot is a tool that makes it easier to create tar archives, etc. containing
files with root ownership, which would otherwise require root user privileges.


### Install firmware for NUC

Intel NUC devices may need particular closed-source firmware blobs installed.
For the NUC8i5BEK, install:

    yay -S wd719x-firmware
    yay -S aic94xx-firmware


### Install Japanese input support

fcitx5 is the IME frontend for Japanese input, while mozc provides the candidate
selection backend. Install all the required packags:

    pacman -S fcitx5-mozc fcitx5-configtool fcitx5-gtk

Note that as of summer 2021, the Wayland IME protocol is still unstable. fcitx5
only has partial integration with the sway window manager on Wayland. Under
Xwayland, it works fine.


### Install mutt email client

Install mutt:

    pacman -S mutt

Install msmtp for SMTP sending:

    pacman -S msmtp

Install notmuch for search/indexing:

    pacman -S notmuch-mutt

Install HTML-to-text support and URL handling:

    pacman -S w3m urlscan

Install isync (also known as mbsync):

    pacman -S isync


### HP printer support

Next, we'll configure [CUPS][cups_guide] printer support for HP printers,
mostly since that's what I have.

    pacman -S cups hplip
    doas vi /etc/sane.d/dll.d/hpaio  # uncomment or add hpaio

Start the CUPS printer daemon:

    doas systemctl enable org.cups.cupsd.service
    doas hp-setup -i # PPD files under /usr/share/ppd/HP/


### Install windows8 fonts

See details in the [MS Fonts guide][ms_fonts_guide].

These instructions are out-of-date and probably a bad idea:
    curl -o  ttf-ms-win8.tgz \
             https://drive.google.com/open?id=0BxQqjcVVn0shNGpqdDZYUjdaNUU
    tar zxvf ttf-ms-win8.tgz
    cd ttf-ms-win8.tgz
    makepkg -if


[install_guide]: https://wiki.archlinux.org/index.php/Installation_guide
[luks_guide]: https://wiki.archlinux.org/index.php/Dm-crypt
[lvm_guide]: https://wiki.archlinux.org/index.php/LVM
[systemd_guide]: https://wiki.archlinux.org/index.php/Systemd
[dhcpcd_guide]: https://wiki.archlinux.org/index.php/Dhcpcd
[ntpd_guide]: https://wiki.archlinux.org/title/Network_Time_Protocol_daemon
[mkinitcpio_guide]: https://wiki.archlinux.org/index.php/mkinitcpio
[uefi_guide]: https://wiki.archlinux.org/index.php/Unified_Extensible_Firmware_Interface
[cups_guide]: https://wiki.archlinux.org/index.php/CUPS
[ms_fonts_guide]: https://wiki.archlinux.org/index.php/MS_Fonts
[gnome_guide]: https://wiki.archlinux.org/index.php/GNOME
