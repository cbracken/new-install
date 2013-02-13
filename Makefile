install-cmdline-core:
	apt-get install aptitude
	aptitude install git
	aptitude install tmux
	aptitude install vim
	aptitude install zsh

install-cmdline-apps:
	aptitude install irssi
	aptitude install mutt notmuch offlineimap urlview

remove-x-annoyances:
	aptitude purge unity-lens-shopping
	aptitude purge appmenu-gtk appmenu-gtk3 appmenu-qt
	aptitude purge liboverlay-scrollbar-0.2-0 liboverlay-scrollbar3-0.2-0

install-x-apps:
	aptitude install chromium
	aptitude install fonts-takao
	aptitude install ibus-mozc emacs-mozc
	aptitude install vim-gnome
