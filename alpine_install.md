Alpine Linux
============

Installation
------------

For initial setup, run:

    setup-alpine

Create a user:

    adduser chris
    addgroup chris chris
    addgroup chris wheel
    addgroup chris video  # If building a desktop machine.
    addgroup chris input  # If building a desktop machine.

Install sudo:

    apk update
    apk upgrade
    apk add man man-pages
    apk add sudo sudo-doc
    apk add coreutils coreutils-doc

Edit `/etc/sudoers` to allow all members of group wheel to execute any command:

    %wheel ALL=(ALL) ALL

Enable the community repository by editing `/etc/apk/repositories`, and
enabling:

    http://dl-cdn.alpinelinux.org/alpine/v3.10/community

We now have a fully-working base install.  Log out then log back in as a user
in the _wheel_ group and verify that they can issue `sudo` commands. Once this
has been verified, we can lock down the root account to prevent password-based
login and force all admin work to be performed via `sudo`.

    passwd -l root

If we ever need to re-enable the root account, we can use the following command
to unlock it:

    sudo passwd -u root


Installing additional components
--------------------------------

Additional components can be installed via sudo by any user in the wheel group.

### zsh

    apk add zsh zsh-doc

You can then /etc/passwd and change the user's shell to /bin/zsh.


### Terminal utilities

    apk add tmux tmux-doc tmux-zsh-completion


### Development tools

    # nm, ld, strip, etc.
    apk add binutils binutils-doc

    # compilers, debuggers
    apk add clang clang-doc
    apk add lldb lldb-doc
    apk add nasm nasm-doc

    # source control
    apk add git git-doc git-zsh-completion
    apk add tig tig-doc


### Sway window manager

This requires some form of session management to set `XDG_RUNTIME_DIR`, etc.
given that Alpine does not use systemd.

    apk install eudev eudev-doc
    apk install sway sway-doc

    apk add                           \ # Install optional dependencies:
        xorg-server-xwayland          \ # strongly reccommended for compatibility reasons
        rxvt-unicode rxvt-unicode-doc \ # default terminal emulator
        dmenu dmenu-doc               \ # default application launcher
        swaylock swaylock-doc         \ # lockscreen tool
        swayidle swayidle-doc           # idle management (DPMS) daemon
