FreeBSD new install instructions
================================

Install from USB stick
----------------------

From USB stick, install:

1. Keyboard layout: USA (Caps Lock acts as Left Ctrl).
2. Set hostname
3. Install `ports`.
4. Auto disk partition. Entire disk. GPT.
5. Network. No IPv4, IPv6.
6. Set clock to UTC.
7. Enable `sshd`, `ntpd`, `powerd`, `dumpdev`.
8. Clean `/tmp` on startup.
9. Add user with `wheel` additional group.

Log in as root:

1. In `/boot/loader.conf`, add:
   ```
   if_iwm_load="YES"
   iwm8265fw_load="YES"
   ```
2. To configure wired ethernet in `/etc/rc.conf`, add:
   ```
   # SYNCDHCP forces startup to wait for dhclient to return, DHCP does not.
   ifconfig_em0="SYNCDHCP"
   ```
3. To configure WiFi in `/etc/rc.conf`, add:
   ```
   wlans_iwm0="wlan0"
   ifconfig_wlan0="WPA DHCP"
   ```
4. In `/etc/wpa_supplicant.conf`, add an entry:
   ```
   network={
	   ssid="my_ssid_name"
	   psk="my_password"
   }
   ```
5. Run: `chmod go-rwx /etc/wpa_supplicant.conf`
6. Edit `/etc/hosts` to fix the domain name and host:
   ```
   ::1       localhost localhost.bracken.jp myhost myhost.bracken.jp
   127.0.0.1 localhost localhost.bracken.jp myhost myhost.bracken.jp
   ```
7. Reboot by running: `reboot`

If required, dynamically load the iwm8265 intel Wifi driver:

    kldload if_iwm

Log in as root:

1. Get the Wifi MAC address `ifconfig wlan0`.
2. In the router, manually assign a fixed IP address.

Configure sendmail:

1. Edit `/etc/mail/aliases`. Set aliases for `root`, `manager`, and
   `dumper`.
2. Run `newaliases` to update the aliases database.
3. See https://www.freebsd.org/doc/handbook/sendmail.html for details.

Install general packages:

1. `pkg update -f`
2. Install sudo: `pkg install sudo`
3. Edit /usr/local/etc/sudoers. Uncomment: `%wheel ALL=(ALL) ALL`
4. Install zsh: `pkg install zsh`
5. Install zsh: `pkg install bash`
6. Install vim: `pkg install vim-console`
7. Install git: `pkg install git` (agree to install all)

Install developer packages:

1. Install tig: `pkg install tig`
2. Install python: `pkg install python3 python`
3. Install go: `pkg install go`
4. Install nasm: `pkg install nasm`
5. Install bazel: `pkg install bazel` (note: requires `bash` at runtime)
6. Install gn: `pkg install gn`
7. Install ninja: `pkg install ninja`
8. Install cscope: `pkg install cscope`

Log in as user:

1. `chsh -s /usr/local/bin/zsh`
2. `exit`

Log in as user again:

1. `ssh-keygen -t rsa -b 4096 -C "chris@bracken.jp (hostname)"`


Setting the keyboard layout
---------------------------

The console keyboard layout can be temporarily changed using the
`kbdcontrol` command:

    kbdcontrol -l jp.capsctrl

It can be permanently set by adding a line to `/etc/rc.conf`:

    keymap=jp.capsctrl

For US keyboard layout with Caps Lock as Control, use `us.ctrl` for a
Japanese keyboard with Caps Lock as Control, use `jp.capsctrl`. You can
find all layouts in the `/usr/share/vt/keymaps` directory.

In XWindows, the keyboard can be set using `setxkbmap`:

    setxkbmap jp

It can be permanently set by adding the above line to `.xinitrc`.

To map Caps Lock into a control key:

    setxkbmap -option ctrl:nocaps


Setting console font
--------------------

To list available fonts, run `vidfont`, an ncurses-based program that
sets the font to something legible when running. When it exits, it'll
dump the selected font name.

To set the font from a script, run:

    vidcontrol -f FONTNAME

where `FONTNAME` is the name dumped by vidfont.

To permanently set the console font, edit `/etc/rc.conf`:

    allscreens_flags="-f FONTNAME"

I find `terminus-b32` to be the most legible on a small screen. On a
large screen, `vgarom-8x14` or `vgarom-8x16` might be better.

A couple reference articles relating to framebuffer console fonts:

* [General](https://lists.freebsd.org/pipermail/freebsd-questions/2018-February/281063.html)
* [Japanese](http://www.lufimia.net/cal/workstation/index.htm)
* [Japanese](https://www.next-hop.net/~hiraga/FreeBSD/japanese-vt.shtml)


Using a serial cable
--------------------

FreeBSD includes built-in support for various UART serial cables
including the Prolific PL-2303 and FTDI cables. Connecting the cable
will create three character devices named `ttyUN`, `ttyUN.init`, and
`ttyUN.lock` in the dev filesystem.

* `ttyUN` is the serial device.
* `ttyUN.init` is an initialisation device used to initialise
  communication port parameters each time a port is opened, such as
  `crtscts` for modems which use `RTS/CTS` signalling for flow control.
* `ttyUN.lock` is used to lock flags on ports to prevent users or
  programs from changing certain parameters. See the man pages for
  `termios`, `sio`, and `stty` for information on terminal settings,
  locking and initialising devices, and setting terminal options,
  respectively.

More info on serial port configuration can be found in the FreeBSD
Handbook:

* [25.2 USB Virtual Serial Ports](https://www.freebsd.org/doc/handbook/usb-device-mode-terminals.html)
* [26.2 Serial Terminology and Hardware](https://www.freebsd.org/doc/handbook/serial.html)

To connect to the serial line, use the `cu` command:

    cu -l /dev/ttyU0 -s 115200

To disconnect the serial session, type `~.` from within `cu`.


Installing on a new machine
---------------------------

### Configure machine

1. When adding the first user, when prompted for additional groups in
   addition to their own group add them to `wheel`.
1. Set domain-qualified hostname in `/etc/rc.conf`.
1. Update `/etc/hosts` to use domain name. Add raw hostname and
   domain-qualified hostname after localhost entries.
1. Set the console font in `/etc/rc.conf` (see section above).

### Install packages

1. Run `pkg install sudo` to install sudo.
1. Run `pkg install vim-console` to install vim.
1. Run `pkg install zsh` to install zsh.
1. Run `pkg install tmux` to install tmux.
1. Run `pkg install git` to install git.
1. Run `pkg install tig` to install tig (interactive git tool).
1. Run `pkg install w3m` to install w3m browser.
1. Run `pkg install mutt` to install mutt email client.
1. Run `pkg install notmuch` to install notmuch email indexer.
1. Run `pkg install isync` to install email syncing.
1. Run `pkg install msmtp` to install an SMTP plugin mutt can use.

### Set up sudo

1. Edit `/usr/local/sudoers` and uncomment the following line to enable
   sudo access for members of the `wheel` group:
   ```
   %wheel ALL=(ALL) ALL
   ```
1. Disable direct root login by editing the passwd file using the `vipw`
   command. Find the row starting with `root:` and replace the hashed
   password between the first and second colons on that line with `*`.
   The line should look something like:
   ```
   root:*:0:0::0:0:Charlie &:/root:/bin/csh
   ```
1. Type `:wq` to save and exit.

### Local email setup

By default, sendmail operates localhost only. If you disable it, you'll
need to enable an alternative mail handler since the system assumes mail
is available.

Given that we generally want to disable root login on all hosts, it's
useful to forward root's mail to a local user. To do so:

1. Edit `/etc/mail/aliases`. Forward root's mail to a local user (e.g.
   `chris`) or a domain-qualified email address such as
   `chris@bracken.jp`.
2. Run `sudo newaliases` to rebuild the random-access database populated
   from `/etc/mail/aliases`. This is exactly the same as `sudo sendmail
   -bi`.

### Configure sshd

1. Edit `/etc/ssh/sshd_config` and uncomment:
   ```
   PasswordAuthentication no
   ```
   then change `no` to `yes`.
1. Edit `/etc/rc.conf` to add:
   ```
   sshd_enable="YES"
   ```
1. Start the sshd server:
   ```
   sudo service sshd start
   ```
1. Connect to the host via ssh from another machine:
   ```
   ssh myhost
   ```
1. Copy your existing public key into `~/.ssh/authorized_keys` on the
   new machine -- e.g. on the new host: `cat > ~/.ssh/authorized_keys`.
   Then paste the public key you want to use to log in, and type ctrl-d
   to save. You can find your public key in `~/.ssh/id_rsa.pub` on the
   existing host you want to connect from.
1. Edit `/etc/ssh/sshd_config` to disable password-based authentication,
   and allow only key-based authentication by setting
   `PasswordAuthentication` and `ChallengeResponseAuthentication` to
   `no`.
1. Restart the sshd server to pick up the config change.
   ```
   sudo service sshd restart
   ```

### Configure audio

We'll want some mechanism for managing audio volume. The `alsa-utils`
package includes `amixer` which does the trick:

    sudo pkg install alsa-utils

We may also want to disable the PC speaker and its annoying beep. Edit
`/etc/sysctl.conf` and add the following:

    # Disable the terminal bell.
    kern.vt.enable_bell=0


### NVIDIA drivers

For systems with an NVIDIA card, we'll install the drivers, configure
them to load at boot, and add X11 config.

First install the drivers:

    sudo pkg install nvidia-driver

Next add the following line to `/boot/loader.conf`:

    nvidia_load="YES"

Then add the following line to `/etc/rc.conf`:

    kld_list="nvidia-modeset"

Next, create the file
`/usr/local/etc/X11/xorg.conf.d/driver-nvidia.conf` with the following
contents:

    Section "Device"
        Identifier "NVIDIA Card"
        VendorName "NVIDIA Corporation"
	Driver "nvidia"
    EndSection

Finally, reboot the system or run `kldload nvidia-modeset` to manually
load the driver.


### Configure XWindows

To install XWindows with the i3 window manager and compton compositor:

    sudo install xorg
    sudo install i3 i3status i3lock dmenu compton
    sudo install rxvt-unicode

Add the following line to `/etc/rc.conf`:

    dbus_enable="YES"

Add yourself to the `video` group:

    pw groupmod video -m $USER

Install DRM kernel module:

    sudo pkg install drm-fbsd12.0-kmod

Then set it to load at boot time by adding the following line to
`/etc/rc.conf`:

    kld_list="/boot/modules/i915kms.ko"

In some instances, this seems to result in a kernel panic. If that
happens, install DRM from the `graphics/drm-kmod` port in the ports
tree.

Install fonts:

    sudo pkg install webfonts
    sudo pkg install noto-basic
    sudo pkg install noto-jp
    sudo pkg install ja-font-ipa ja-font-ipa-uigothic ja-font-ipaex

Then refresh the font cache:

    fc-cache -f

Install firefox:

    sudo pkg install firefox

Reboot the system and attempt to run `startx`.


### Japanese input on the virtual console

Download Japanese fonts:

    fetch http://people.freebsd.org/~emaste/newcons/b16.fnt
    fetch http://www.wheel.gr.jp/~dai/fonts/jiskan16u.fnt
    fetch http://www.wheel.gr.jp/~dai/fonts/jiskan16s.fnt
    fetch http://www.wheel.gr.jp/~dai/fonts/unifont-8.0.01.fnt

Copy the fonts to a local font directory:

    sudo mkdir /usr/local/share/fonts/vt
    cp *.fnt /usr/local/share/fonts/vt

You can convert BDF or HEX fonts to console `.fnt` files using the
`vtfontcvt` command. See the `vtfontcvt` man page for details.

Use the mechanism described (`vidfont` and `vidcontrol`) elsewhere in
this document to set the font.


### Japanese input in XWindows

Setting Japanese keyboard layout with caps-lock as control:

    setxkbmap -layout jp -option ctrl:nocaps

Installing mozc IME:

    sudo install ja-ibus-mozc

In `~/.xinitrc`, before launching i3, add:

    # Use fcitx for Japanese IME.
    export GTK_IM_MODULE=ibus
    export QT_IM_MODULE=ibus
    export XMODIFIERS=@im=ibus

    # Start mozc engine and ibus IME.
    /usr/local/bin/mozc start
    ibus-daemon --xim &

Configure ibus by running `ibus-setup`. Using the *Input Method* pane,
add *Japanese* and *Mozc*. Remove US keyboard if present (unless you're
using a US keyboard). Note that when you do this step, dbus will need to
be running; this involves either a reboot after the XWindows config
steps above or manually starting it via `service dbus start` before
running `startx`.


Editing kernel sources
----------------------

When editing kernel sources in vim, the indentation settings should be:

    set autoindent      " Copy indent from current line when starting a new line
    set smartindent     " Attempt to autoindent when starting a new line
    set smarttab        " Use shiftwidth rather than tabstop at start of line
    set tabstop=8       " Number of spaces a tab counts for
    set shiftwidth=4    " Number of spaces for each step of autoindent
    set softtabstop=4   " Number of spaces a tab counts for when editing
    set noexpandtab     " Use tabs rather than spaces


Troubleshooting
---------------

### ssh-add fails to run

If, when running ssh-add, you get an error along the lines of

    Could not open a connection to your authentication agent.

you likely need to start ssh-agent. You can do this via:

    eval $(ssh agent -s)


### Segfault on keyboard input in dmenu

If you have the `XMODIFIERS` variable set but your IME isn't properly
configured and running, you'll get a crash on keyboard input to dmenu.


### Can't sudo or log in as root

Imagine you delete the root password via `vipw` without actually editing
the `/usr/local/etc/sudoers` file first, or that you did edit that file
but that no user is in the `wheel` group. Time to boot to single-user
mode. Reboot the machine and when prompted at the initial FreeBSD boot
prompt, quickly select option `2` to boot to single-user mode.

The root filesystem is mounted read-only by default, so first we'll need
to remount the root filesystem as read-write:

    /sbin/mount -o rw /

Next, edit `/usr/local/etc/sudoers` or make whatever other changes are
required to fix your mistakes. Finally, reboot.


### Force renew DHCP lease

DHCP leases are cached in /var/db/dhclient.leases.em0 (remplace `em0`
with the interface name).

To force renewal of DHCP lease:

    sudo service dhclient restart em0

To manually unbind/remove an IP address from an interface:

    sudo ifconfig em0 remove 192.168.1.x


### Force NTP time sync

To force sync the time on the host:

    sudo ntpdate -v -b in.pool.ntp.org


### Intel NUC6i3SYK-specific issues

#### SD card reader doesn't work

Intel NUC6i3SYK devices give a repeating error on startup:

    sdhci_pci0_slot0: Controller timeout

and dumps registers. It seems like there's an issue with support for the
NUC's SD card reader. After a couple minutes, eventually it gives up and
continues.  To eliminate the warning on startup, reboot and enter the
BIOS by holding down F2, then disable the SD coard reader in the
*Devices* section of the *Advanced* options.

Alternatively, edit `/boot/loader.conf` to contain:

    hw.sdhci.enable_msi=0

If that doesn't work, edit `/boot/device.hints` to contain:

    hint.sdhci_pci.0.disabled="1"


#### Bluetooth doesn't work

Mostly from notes in FreeBSD [Bugzilla issue
237083](https://bugs.freebsd.org/bugzilla/show_bug.cgi?id=237038).

The NUC's Intel 8260 bluetooth/wireless requires a custom firmware
download.  FreeBSD 12.0 doesn't ship with all the support needed for
this chipset. Fixes were landed in July 2019, but will take time to get
released.

In the meantime, the firmware downloader can be found here:
[](https://github.com/wulf7/iwmbt-firmware). Build the downloader:

    git clone git@github.com:wulf7/iwmbt-firmware
    cd iwmbt-firmake
    make

There's no need to install this, since it's a one-off tool to download
and install the firmware. However, before you run it, you need to
prevent FreeBSD from trying to auto-attach the device. Edit
`/etc/devd.conf` and comment out the following lines, then power off and
power back on the machine (a reboot is insufficient to clear the
hardware state):

    attach 100 {
    	device-name "ubt[0-9]+";
    	action "service bluetooth quietstart $device-name";
    };

Next, to download the firmware, we run:

    sudo ./iwmbtfw

This should get the download to happen, writing the firmware to
`/usr/local/share/iwmbt-firmware/ibt-11-5.sfi`. You can then start the
service with:

    sudo service start bluetooth ubt0

To list the attached bluetooth nodes, try:

    sudo ngctl list

It should display something like:

    There are 6 total nodes:
    Name: ubt0            Type: ubt             ID: 00000007   Num hooks: 0
    Name: ubt0hci         Type: hci             ID: 0000000?   Num hooks: 0
    Name: ubt012cap       Type: 12cap           ID: 0000000?   Num hooks: 0
    Name: btsock_hci_raw  Type: btsock_hci_raw  ID: 00000008   Num hooks: 0
    Name: btsock_l2c_raw  Type: btsock_l2c_raw  ID: 00000009   Num hooks: 0
    Name: btsock_l2c      Type: btsock_l2c      ID: 0000000a   Num hooks: 0
    Name: btsock_sco      Type: btsock_sco      ID: 0000000b   Num hooks: 0
    Name: ngctl1441       Type: socket          ID: 00000019   Num hooks: 0

I notice when I do it, I'm missing the `ubt0hci` and `ubt012cap` entries
though.

Once you're done, uncomment the section of `/dev/devd.conf` above and
reboot.
