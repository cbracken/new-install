OpenBSD Install
===============

Last updated for OpenBSD 6.7.

Initial install
---------------

1. At install prompt, select "(I)nstall".
1. For keyboard, type us.swapctrlcaps or jp.swapctrlcaps.
1. When prompted for the hostname, enter the short hostname with no domain.
1. When prompted for an interface to configure, select em0.
1. When prompted for how to configure IPv4, use dhcp.
1. When prompted for how to configure IPv6, select none.
1. When prompted for the next network interface to configure, select
   done.
1. Enter your domain name at the prompt.
1. Enter the root password, then confirm.
1. When asked whether to start sshd by default select yes.
1. When prompted for whether to start xwindows select no for a server,
   optionally yes otherwise.
1. Leave the default console on video out rather than com0.
1. Add a user.
1. When prompted for whether to enabled root ssh login, select no.
1. When prompted for what timezone you're in enter "America" or "Asia".
1. When prompted for the sub-timezone, select the correct value.
1. Select the disk you wish to install the OS onto. Type ? to ensure
   you're writing to the correct disk.
1. Use gpt to partition the disk as desired.
1. When prompted for the location of sets, pick http.
1. Set proxy settings as needed, or leave blank if none.
1. The default http server is probably reasonable.
1. The default directory is probably correct.
1. Select all sets (unless there are some you don't want).
1. When prompted for more sets to install, select done.
1. When prompted to exit/halt/reboot, select reboot.

Create `/etc/doas.conf` with the following contents:

    permit nopass :wheel
    permit :wheel cmd reboot
    permit :wheel cmd shutdown
    permit nopass keepenv root as root

Edit `/etc/ssh/sshd_config` and set:

    PasswordAuthentication no
    ChallengeResponseAuthentication no

Restart sshd:

    kill -HUP `cat /var/run/sshd.pid`

Configure basics
----------------

Install zsh:

    doas pkg_add zsh

Install git:

    doas pkg_add git

Install vim. The following command will prompt you for which variant to
install (I prefer `vim-no_x11-python3`):

    doas pkg_add vim

Configure X11
-------------

Install i3, dmenu, urxvt:

    doas pkg_add i3
    doas pkg_add i3lock
    doas pkg_add i3status
    doas pkg_add dmenu
    doas pkg_add rxvt-unicode
