Ubuntu install with UEFI boot
=============================

This provides a basic rundown of process of a minimal Ubuntu Linux install with
the following setup:

  * UEFI boot
  * LVM filesystem
  * Sway WM using Wayland

Rather than using the Ubuntu Desktop install media, we start with Ubuntu server
to generate a more minimal installation. By default, Ubuntu installs GDM and
the Gnome desktop, which makes using non X-based desktops more difficult.

This guide assumes a wired ethernet connection and a working DHCP server.


Create USB boot disk
--------------------

Download an install image from https://ubuntu.com/download/server, then write
it to a disk using `dd`. Reboot the machine to be imaged and use the machin's
BIOS features to boot from the USB drive in UEFI mode.


Walk through the Ubuntu installer
---------------------------------

Rough notes for installer (TODO: fill this out):
* When prompted for whether to download the updated installer, download it.
* When prompted to partition the disk, select to use the whole disk with LVM.
* When prompted to verify the LVM partitioning, adjust the space allocated to
  each volume, partition, as necessary.
* When prompted for which service to install, select none. Install the OpenSSH
  server if desired.

Reboot the machine.

Verify the machine booted into UEFI mode:

    ls /sys/firmware/efi/efivars

If the directory does not exist, the system is likely booted in BIOS mode. You
will want to enter BIOS and enable UEFI boot, then reboot from the USB drive in
UEFI mode and restart installation.

Next, we'll apply any immediate updates and remove any leftover unnecessary
packages from the install process.

    sudo apt upgrade
    sudo apt autoremove
    sudo apt clean

Next we'll purge any leftover config files from any removed packages:

    dpkg -l | grep '^rc '| awk '{print $2}' | xargs sudo dpkg -P


Configure the system
--------------------

### Generate localisations

Edit `/etc/locales.gen` and uncomment locales that we care about.

    en_AU.UTF-8
    en_CA.UTF-8
    en_GB.UTF-8
    en_US.UTF-8
    fr_CA.UTF-8
    ja_JP.UTF-8

Then, regenerate the localisation files.

    sudo locale-gen


### Set the system time zone

To get a list of available time zones:

    timedatectl list-timezones

Next, let's set the time zone then restart the `timedatectl` service:

    sudo timedatectl set-timezone America/Vancouver
    systemctl restart systemd-timedated

Finally, we'll verify the time zone is set correctly:

    timedatectl


### Install zsh

Next we'll install zsh and set it as our default shell.

    sudo apt install zsh zsh-doc
    chsh -s /usr/bin/zsh


### Install vim

We're not going to live on a system that doesn't have a reasonable text editor.

    sudo apt install vim


### Get audio working

First, we'll install ALSA:

    sudo apt-get install libasound2 libasound2-plugins alsa-utils alsa-oss

Then, we'll install PulseAudio:

    sudo apt-get install pulseaudio pulseaudio-utils

Next, we'll add ourselves to the audio groups.

    sudo usermod -aG pulse,pulse-access,audio chris

Next let's check the state of audio devices.

    pacmd list-sinks

At this point things will be broken until you reboot. So reboot.

    sudo shutdown -r now

When you log back in, run `alsamixer` and use the arrow keys to navigate to the
master channel and unmute it, then increase the volume. Press ESC to exit.

Audio should work at this point, but the easiest way to confirm that is with a
web browser, so next we'll get a window manager, terminal, and browser
installed.


Install the Sway window manager and useful apps
-----------------------------------------------

Next let's install the Wayland-based Sway tiling window manager and
suckless-tools for the dmenu launcher.

    sudo apt install sway sway-backgrounds swaybg swayidle swaylock \
                     suckless-tools

We'll want a security daemon that works to cache ssh keys, such as
gnome-keyring:

    sudo apt install gnome-keyring

For a terminal emulator, rxvt is lightweight and works well. We'll install the
256-colour unicode variant:

    sudo apt install rxvt-unicode-256color

For a Wayland-native terminal emulator, Alacritty is a good choice. The one
major downside as of March 2020 is that it doesn't have IME support for
inputting Japanese text under Wayland. Alacritty relies on the FreeDesktop
xdg-utils package to launch URLs from the terminal.

    sudo add-apt-repository ppa:mmstick76/alacritty
    sudo apt install alacritty
    sudo apt install xdg-utils


### Install Firefox

Next, we'll install Firefox. Since we want to be able to decode media, we also
install the non-free ubuntu-restricted-extras package.

    sudo apt install firefox ubuntu-unrestricted-extras

On high-resolution displays, Firefox can look pretty tiny. You can change the
scale factor by going to `about:config`. Then change the logical to physical
pixel ratio.

    layout.css.devPixelsPerPx = 1.3

To reset this value to the default, change it to -1.0.


Get Japanese working
--------------------

First we're going to need fonts. IPA Font and IPAex Font are produced by the
Dokuritsu Kyousei Houjin's Information-technology Promotion Agency (IPA) and
distributed under a permissive licence.

    sudo apt install fonts-ipafont fonts-ipaexfont

Next, we'll get an input manager installed. Input managers have two parts, the
input system (ibus, uim, fcitx) and the converion engine (anthy, mozc). As of
March 2020 uim nor fcitx are unsupported on Wayland, but ibus works well. Anthy
development has effectively been dead since 2009, so instead we'll use mozc.

    sudo apt install ibus-mozc mozc-utils-gui
    ibus-setup
    /usr/lib/mozc/mozc_tool --mode=config_dialog

Add the following environment variables in `.zshenv`.

    # Use ibus for Japanese IME.
    export GTK_IM_MODULE=ibus
    export XMODIFIERS=@im=ibus
    export QT_IM_MODULE=ibus

And on Sway startup, we'll want to launch `ibus-daemon` from the Sway config in
`~/.config/sway/config`.

    exec ibus-daemon --xim


Install developer tools
-----------------------

Next, let's install some software development tools.

### Basic developer tools

First, we'll start with the essentials.

    sudo apt install make
    sudo apt install clang lldb lld clang-format
    sudo apt install git tig
    sudo apt install universal-ctags cscope

Next, we'll pick one or more languages you want to develop in.

    sudo apt install nasm
    sudo apt install python3
    sudo apt install golang

It's likely, at least in 2020, that some tools still depend on Python 2.7. If
it's not installed, but turns out to be required, we can install a minimal
install.

    sudo apt install python-minimal

Rust install instructions exist at https://www.rust-lang.org/tools/install. As
of March 2020, these look like:

    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

Then customise the install to not alter the PATH, since any sane person would
prefer to hand-maintain their dotfiles themselves. If you haven't already, go
add `~/.cargo/bin` to your `PATH` environment variable.

Ninja is used by a bunch of build systems these days.

    sudo apt install ninja-build

If we need gn (generate ninja), we can build from source:

    git clone https://gn.googlesource.com/gn
    cd gn
    ./build/gen.py
    ninja -j8 -C out/
    ./out/gn_unittests
    mkdir -p ~/bin
    cp ./out/gn ~/bin

If we need bazel, we can pull from the upstream repository. Bazel wants zip and
unzip installed too:

    curl https://bazel.build/bazel-release.pub.gpg | sudo apt-key add -
    echo "deb [arch=amd64] https://storage.googleapis.com/bazel-apt stable jdk1.8" | \
        sudo tee /etc/apt/sources.list.d/bazel.list
    sudo apt update && sudo apt install bazel
    sudo apt install unzip zip

Bazel also likely wants gcc and g++ installed:

    sudo apt install gcc g++ gdb
