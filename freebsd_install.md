FreeBSD new install instructions
================================

Download install image
----------------------

First, we'll need to download an install image from
https://www.freebsd.org/where.html. These instructions presume amd64
architecture, so we'll use an amd64-memstick image.

Once the image is downloaded, write it to a USB stick using `dd`. Using
the instructions in the FreeBSD Handbook here:
https://www.freebsd.org/doc/handbook/bsdinstall-pre.html.


Install from USB stick
----------------------

Boot from the USB stick in UEFI mode. The machine should now boot into
the FreeBSD installer.

1. Keyboard layout: USA (Caps Lock acts as Left Ctrl).
2. Set hostname
3. Install `ports`.
4. Auto disk partition. Entire disk. GPT.
5. Network. No IPv4, IPv6.
6. Set clock to UTC.
7. Enable `sshd`, `ntpd`, `powerd`, `dumpdev`.
8. Clean `/tmp` on startup.
9. Add user with `wheel` additional group.

Once these steps are done, select the option to drop into a console
session to complete a few additional steps.


### Set the console keyboard layout

The console keyboard layout can be temporarily changed using the
`kbdcontrol` command:

    kbdcontrol -l jp.capsctrl

It can be permanently set by adding a line to `/etc/rc.conf`:

    keymap=jp.capsctrl

For US keyboard layout with Caps Lock as Control, use `us.ctrl` for a
Japanese keyboard with Caps Lock as Control, use `jp.capsctrl`. You can
find all layouts in the `/usr/share/vt/keymaps` directory.


### Configure the hostname

First we'll get the hostname set:

First, set domain-qualified hostname in `/etc/rc.conf`.

    hostname="myhost.bracken.jp"

Next, update `/etc/hosts` to use domain name. Add raw hostname and
domain-qualified hostname after localhost entries.

    ::1       localhost localhost.bracken.jp myhost myhost.bracken.jp
    127.0.0.1 localhost localhost.bracken.jp myhost myhost.bracken.jp


### Configure wired ethernet

Next, configure wired ethernet for DHCP. In `/etc/rc.conf`, add:

    # SYNCDHCP forces startup to wait for dhclient to return, DHCP does not.
    ifconfig_em0="SYNCDHCP"


### Configure WiFi

If we need Intel WiFi, in `/boot/loader.conf`, add:

    if_iwm_load="YES"
    iwm8265fw_load="YES"

and then configure DHCP for WiFi in `/etc/rc.conf`:

    wlans_iwm0="wlan0"
    ifconfig_wlan0="WPA DHCP"

and set up the WiFi network and password in `/etc/wpa_supplicant.conf`:

    network={
     ssid="my_ssid_name"
     psk="my_password"
    }

then ensure that no one but root can read the contents:

    chmod go-rwx /etc/wpa_supplicant.conf

To assign a fixed IP address to always be returned by the router's DHCP
server, get the WiFi MAC address using `ifconfig wlan0`, then in the
router, manually assign a fixed IP address.


### Configure sendmail

By default, sendmail operates localhost only. If you disable it, you'll
need to enable an alternative mail handler since the system assumes mail
is available.

Given that we generally want to disable root login on all hosts, it's
useful to forward root's mail to a local user. To do so:

1. Edit `/etc/mail/aliases`. Forward root's mail to a local user (e.g.
   `chris`) or a domain-qualified email address such as
   `chris@bracken.jp`.
2. Run `newaliases` to rebuild the random-access database populated from
   `/etc/mail/aliases`. This is exactly the same as `sendmail -bi`.

See https://www.freebsd.org/doc/handbook/sendmail.html for details.


### Set the console font

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

* [How to change console font type and size](https://lists.freebsd.org/pipermail/freebsd-questions/2018-February/281063.html)
* [CLI・CUIなワークステーションを作る](http://www.lufimia.net/cal/workstation/index.htm)
* [FreeBSDで日本語コンソールvtを使う](https://www.next-hop.net/~hiraga/FreeBSD/japanese-vt.shtml)

Reboot the machine
------------------

Once the above steps are done, run exit the shell and select to end the
installation and reboot.


Install initial packages
------------------------

Install general packages:
1. `pkg update -f`
2. Install doas: `pkg install doas`
3. Install zsh: `pkg install zsh`
4. Install bash: `pkg install bash` (only required for bazel)
5. Install vim: `pkg install vim-console`
6. Install tmux: `pkg install tmux`

For VMs running under XCP-NG:
1. Install Xen guide utils: `pkg install xe-guest-utilities`
2. In /etc/rc.conf, add: `xenguest_enable="YES"`

Install mutt email support:
1. Run `pkg install mutt` to install mutt email client.
2. Run `pkg install abook` to install address book.
3. Run `pkg install notmuch` to install notmuch email indexer.
4. Run `pkg install isync` to install email syncing.
5. Run `pkg install msmtp` to install an SMTP plugin mutt can use.
6. Run `pkg install w3m` to install w3m browser.

Install newsreader support:
1. Install newsboat: `pkg install newsboat`

Install developer packages:
1. Install git: `pkg install git` (agree to install all)
2. Install tig: `pkg install tig`
3. Install python: `pkg install python3 python`
4. Install go: `pkg install go`
5. Install nasm: `pkg install nasm`
6. Install bazel: `pkg install bazel` (note: requires `bash` at runtime)
7. Install gn: `pkg install gn`
8. Install ninja: `pkg install ninja`
9. Install cscope: `pkg install cscope`
10. Install meson: `pkg install meson`
11. Install cmake: `pkg install cmake`

Install static web site support:
1. Install gohugo: `pkg install gohugo`


Set up doas
-----------

Edit `/usr/local/etc/doas.conf` and add the following text:

    permit nopass :wheel
    permit :wheel cmd reboot
    permit :wheel cmd shutdown
    permit nopass keepenv root as root


Set up sudo
-----------

1. Edit `/usr/local/etc/sudoers` and uncomment the following line to
   enable sudo access for members of the `wheel` group:

        %wheel ALL=(ALL) ALL

1. Disable direct root login by editing the passwd file using the `vipw`
   command. Find the row starting with `root:` and replace the hashed
   password between the first and second colons on that line with `*`.
   The line should look something like:

        root:*:0:0::0:0:Charlie &:/root:/bin/csh

1. Type `:wq` to save and exit.

Now that sudo is set up, log in as a user in the `wheel` group on
another console (Use Ctrl-Alt-F1 through F8 to switch ttys) and run
`sudo ls /root` to verify everything is configured properly, then exit
the root shell and continue all further steps as a user in the `wheel`
group.


Configure sshd
--------------

Edit `/etc/ssh/sshd_config` and uncomment or edit each of the following
lines to disable password-based logins and allow only key-based
authentication:

    PasswordAuthentication no
    ChallengeResponseAuthentication no
    PubkeyAuthentication yes

Edit `/etc/rc.conf` to add:

    sshd_enable="YES"

Start the sshd server:

    sudo service sshd start

Connect to the host via ssh from another machine:

    ssh myhost

Copy any existing public key you want to be able to log in into
`~/.ssh/authorized_keys` on the new machine -- e.g. on the new host:
`cat > ~/.ssh/authorized_keys`. Then paste the public key you want to
use to log in, and type ctrl-d to save.  You can find your public key in
`~/.ssh/id_rsa.pub` on the existing host you want to connect from.


Configure audio
---------------

We'll want some mechanism for managing audio volume. The `alsa-utils`
package includes `amixer` which does the trick:

    sudo pkg install alsa-utils

We may also want to disable the PC speaker and its annoying beep. Edit
`/etc/sysctl.conf` and add the following:

    # Disable the terminal bell.
    kern.vt.enable_bell=0


Set up NVIDIA drivers
---------------------

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


Change shell to zsh
-------------------

Log in as your user:

1. `chsh -s /usr/local/bin/zsh`
2. `exit`

Log in as user again:

1. `ssh-keygen -t rsa -b 4096 -C "chris@bracken.jp (hostname)"`


Configure XWindows
------------------

### Install Xorg, WM, and apps

Install XWindows:

    sudo install xorg

Install the i3 window manager:

    sudo install i3        \  # window manager
                 i3status  \  # status bar
                 i3lock    \  # lock screen
                 dmenu     \  # app launcher
                 xautolock \  # lock screen timeout manager
                 sxiv      \  # image viewer
                 xpdf         # PDF viewer

Install dunst for notifications:

    sudo install dunst

Optionally, install compton compositor:

    sudo install compton

Install urxvt terminal:

    sudo install rxvt-unicode

Install flameshot screenshotting tool:

    sudo install flameshot

Install fonts:

    sudo pkg install webfonts
    sudo pkg install twemoji-color-font-ttf
    sudo pkg install noto-basic
    sudo pkg install noto-jp
    sudo pkg install ja-font-ipa ja-font-ipa-uigothic ja-font-ipaex

Then refresh the font cache:

    fc-cache -f

Install Firefox web browser:

    sudo pkg install firefox   # browser
    sudo pkg install openh264  # H264 video plugin


### Configure X

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


### Configure keyboard layout

In XWindows, the keyboard can be set using `setxkbmap`:

    setxkbmap jp

It can be permanently set by adding the above line to `.xinitrc`.

To map Caps Lock into a control key:

    setxkbmap -option ctrl:nocaps


### Configure mouse

To configure natural scrolling, create the file
`/usr/local/etc/X11/xorg.conf.d/mouse.conf` with the following contents:

    Section "InputDevice"
      Identifier "Mouse1"
      Driver "mouse"
      Option "Protocol" "auto"
      Option "Device" "/dev/sysmouse"
      Option "Buttons" "5"
      Option "ZAxisMapping" "4 5"
    EndSection


### Reboot

Reboot the system and attempt to run `startx`.


Configure Japanese input
------------------------

### XWindows

Setting Japanese keyboard layout with caps-lock as control:

    setxkbmap -layout jp -option ctrl:nocaps

Installing mozc IME:

    sudo install ja-fcitx-mozc

In `~/.xinitrc`, before launching i3, add:

    # Use fcitx for Japanese IME.
    export GTK_IM_MODULE=fcitx
    export QT_IM_MODULE=fcitx
    export XMODIFIERS=@im=fcitx

    # Start mozc engine and fcitx IME.
    /usr/local/bin/mozc start
    /usr/local/bin/fcitx -d

Configure fcitx by running `fcitx-configtool`. Using the *Input Method* pane,
add *Mozc*. Remove US keyboard if present (unless you're using a US keyboard).
Note that when you do this step, dbus will need to be running; this involves
either a reboot after the XWindows config steps above or manually starting it
via `service dbus start` before running `startx`.


### Virtual console

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


Optionally set up pf firewall
------------------------------

Canonical reference in the FreeBSD Handbook:
https://www.freebsd.org/doc/handbook/firewalls-pf.html

An excellent tutorial on the OpenBSD packet filter:
https://home.nuug.no/~peter/pf/en/

Another decent starter reference: http://srobb.net/pf.html


### Enable pf

We'll need to populate `/etc/pf.conf`. A minimal config file that blocks
all incoming connections other than SSH (port 22):

    # Our external-facing network interface.
    ext_if="em0"

    # Block spoofed IP addresses on em0.
    antispoof for $ext_if

    # Allow all connections over loopback.
    # "quick" means if rule is matched, stop processing here.
    pass quick on lo0 all

    # Block all incoming connections.
    block in all

    # Allow incoming SSH connections.
    pass in proto tcp to port 22

    # Allow all outgoing connections.
    pass out all keep state

To run a check on our config file without yet applying it:

    pfctl -nvf /etc/pf.conf

Next, we'll start `pf`, but since many a system administrator has found
themselves locked out of their own server by applying a bad config, it's
useful to queue up a command to disable the firewall after two minutes.
In another terminal, log into the remote machine, get a root shell using
`sudo -s`, then run the following:

    # Sleep 2 minutes, then disable pf.
    sleep 120; pfctl -d

Then, before the two minutes is up, run these commands in another
terminal to start the firewall:

    # Load the pf kernel module.
    sudo kldload pf

    # Enable pf.
    sudo pfctl -e

It's likely your SSH sessions will hang when you enable the packet
filter. Quickly try connecting via SSH to verify you can connect before
the two minute timeout above expires. If it worked, re-enable the packet
filter on the server using `sudo pfctl -e`.

Once everything checks out, enable the packet filter on startup by
adding the following lines to `/etc/rc.conf`:

    pf_enable="YES"
    pflog_enable="YES"


### Reading pf logs

To read the pf logs, run:

    sudo tcpdump -netttr /var/log/pflog


### Enabling blacklistd

Canonical reference in the FreeBSD Handbook:
https://www.freebsd.org/doc/handbook/firewalls-blacklistd.html

If you've got an external-facing SSH port, you'll be continuously
spammed with bogus connection attempts from people attempting to get
access to badly-configured machines. The less clever of these tend to
attack your machine repeatedly from the same IP address. FreeBSD
includes the `blacklistd` service which can be used to temporarily ban
IP addresses after repeated failed connection attempts.

First, we'll add a pf anchor for blacklistd blocks in `/etc/pf.conf`:

    anchor "blacklistd/*" in on $ext_if

Next we'll enable it on boot. Add the following line to `/etc/rc.conf`:

    blacklistd_enable="YES"

Nest, start the blacklistd service:

    sudo service blacklistd start

Finally, we'll enable blacklist support in sshd. Edit
`/etc/ssh/sshd_config` and uncomment the line:

    UseBlacklist yes

Then we'll restart sshd:

    sudo service sshd restart

at this point, everything should be up and running.


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

DHCP leases are cached in /var/db/dhclient.leases.em0 (replace `em0`
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
BIOS by holding down F2, then disable the SD card reader in the
*Devices* section of the *Advanced* options.

Alternatively, edit `/boot/loader.conf` to contain:

    hw.sdhci.enable_msi=0

If that doesn't work, edit `/boot/device.hints` to contain:

    hint.sdhci_pci.0.disabled="1"


#### Bluetooth doesn't work

Mostly from notes in FreeBSD [Bugzilla issue
237083](https://bugs.freebsd.org/bugzilla/show_bug.cgi?id=237038).

The NUC's Intel 8260 Bluetooth/wireless requires a custom firmware
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

To list the attached Bluetooth nodes, try:

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
