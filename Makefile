# Standard post-install steps for Ubuntu

install-cmdline-core:
	apt-get install aptitude
	aptitude install git tig
	aptitude install jq
	aptitude install tmux
	aptitude install vim
	aptitude install zsh

install-xterm-256color-italic:
	tic xterm-256color-italic.terminfo

install-irssi:
	aptitude install irssi

install-mutt:
	aptitude install \
		abook \
		mutt \
		msmtp \
		notmuch \
		offlineimap \
		urlview \
		w3m \
		python-keyring

install-x-apps:
	aptitude install chromium
	aptitude install fonts-takao
	aptitude install i3
	aptitude install ibus-mozc emacs-mozc
	aptitude install rxvt-unicode-256color
	aptitude install vim-gnome
