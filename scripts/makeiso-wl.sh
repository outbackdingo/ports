#!/bin/sh

as_root()
{
	if [ $(id -u) = 0 ]; then
		$*
	elif [ -x /usr/bin/sudo ]; then
		sudo $*
	else
		su -c \\"$*\\"
	fi
}

case ${0##*/} in
	*-runit.sh) INIT=runit;;
	*) INIT=sysv;;
esac

PORTSDIR="$(dirname $(dirname $(realpath $0)))"
SCRIPTDIR="$(dirname $(realpath $0))"
ROOTFS="$PWD/rootfs"

[ -f $SCRIPTDIR/config ] && . $SCRIPTDIR/config

MUST_PKG="wpa_supplicant os-prober grub"
WAYLAND_PKG="xcb-util-cursor xcb-util-keysyms libxfont2 libxcvt libtirpc xwayland"
MAIN_PKG="sudo zsh alsa-utils dosfstools mtools gvfs fastfetch nnn hyprland kitty alacritty wofi rofi htop wireplumber pipewire fzy thunar"
SWAY_PKG="waybar"
THEME_PKG="osx-arc-theme ttf-mononoki"

RELEASE=$(cat $PORTSDIR/current-release)
outputiso="$PORTSDIR/venomlinux-wayland-$INIT-$(uname -m)-$(date +%Y%m%d).iso"
pkgs="$(echo $MUST_PKG $WAYLAND_PKG $MAIN_PKG $SWAY_PKG $THEME_PKG | tr ' ' ',')"

as_root $SCRIPTDIR/build.sh \
	-zap || exit 1

if [ "$INIT" = runit ]; then
	echo 'rc runit-rc' | as_root tee -a $ROOTFS/etc/scratchpkg.alias
	as_root $ROOTFS/usr/bin/xchroot $ROOTFS scratch remove -y sysvinit rc
	pkgs="$pkgs,runit-rc"
fi

as_root $SCRIPTDIR/build.sh \
	-rebase \
	-iso \
	-outputiso="$outputiso" \
	-pkg="$pkgs" || exit 1

exit 0
