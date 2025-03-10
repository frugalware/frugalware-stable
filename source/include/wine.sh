#!/bin/sh

###
# = wine.sh(3)
# James Buren <ryuo@frugalware.org>
#
# == NAME
# wine.sh - for Frugalware
#
# == SYNOPSIS
# Common schema for wine stable & development packages.
#
# == EXAMPLE
# pkgname=wine
# pkgver=1.2.3
# pkgrel=3
# Finclude wine
###

url="http://www.winehq.org"
groups=('xapps-extra')
depends=('lcms2' 'openal' 'libglu' 'libldap>=2.5.4' 'libpcap' 'libpulse' 'libmpg123' 'libgphoto2' 'gettext' 'libxml2' 'ocl-icd' \
	'libxcursor' 'libxi' 'libxrandr' 'libxinerama' 'libxcomposite' 'sane-backends' 'v4l-utils' 'libxrender' 'wayland' \
	'libxslt' 'vkd3d' 'vulkan-icd-loader' 'faudio' 'libosmesa' 'pcsc-lite' 'gst1-plugins-base' 'libxkbcommon')
#32 bit
depends+=('lib32-lcms2' 'lib32-libxcursor' 'lib32-libxi' 'lib32-libxrandr' 'lib32-libxinerama' 'lib32-libxcomposite' \
	'lib32-libxrender' 'lib32-freetype2' 'lib32-libxml2' 'lib32-ncurses' 'lib32-vkd3d' 'lib32-ocl-icd' 'lib32-libxkbcommon' \
	'lib32-libldap>=2.5.4' 'lib32-vulkan-icd-loader' 'lib32-faudio' 'lib32-libosmesa' 'lib32-wayland')
makedepends=('x11-protos' 'cups' 'bison' 'opencl-headers' 'kernel-headers' 'wayland-protocols')
_F_cd_path="wine-$pkgver"
options=('genscriptlet' 'static' 'nofortify' 'nolto' 'plt' 'ldbfd')
archs=('x86_64')
_F_conf_configure="../configure"
_F_archive_grepv="\-rc"
Fconfopts="	--without-oss \
		--with-x \
		--with-wayland \
		--with-gstreamer"
F32confopts+="	--libdir=/usr/lib32 \
		--without-oss \
		--with-x \
		--with-wayland \
		--with-gstreamer"


Finclude cross32

case "$pkgname" in

wine)
	pkgdesc="An Open Source implementation of the Windows API on top of X and Unix. (Stable)"
	_F_archive_grep="\.0"
	up2date="Flasttar https://dl.winehq.org/wine/source/\$(Flastverdir https://dl.winehq.org/wine/source/)/"
	conflicts=('wine-devel' 'lib32-wine-devel')
	provides=('lib32-wine')
	replaces=('lib32-wine')
	source=(https://dl.winehq.org/wine/source/${pkgver}/wine-$pkgver.tar.xz)
	;;

wine-devel)
	pkgdesc="An Open Source implementation of the Windows API on top of X and Unix. (Development)"
	_F_archive_name="wine"
	up2date="Flasttar https://dl.winehq.org/wine/source/10.x"
	conflicts=('wine' 'lib32-wine-devel')
	provides=('wine' 'lib32-wine-devel')
	replaces=('lib32-wine-devel')
	source=(https://dl.winehq.org/wine/source/10.x/wine-$pkgver.tar.xz)
	;;

default)
	error "Unsupported package: $pkgname"
	Fdie
	;;

esac

build()
{
	Fcd
	Fpatchall
	Fsed 'lib64' 'lib' configure.ac
	Fautoreconf
	Fexec rm -rf 64Bit_build || Fdie
	Fexec mkdir 64Bit_build || Fdie
	Fexec cd 64Bit_build || Fdie
	Fmake --enable-win64

	Fexec cd .. || Fdie
	Fexec rm -rf 32Bit_build || Fdie
	Fexec mkdir 32Bit_build || Fdie
        Fexec cd 32Bit_build || Fdie
        Fcross32_prepare

        Fmake --libdir=/usr/lib32 --with-wine64="$Fsrcdir/${_F_cd_path}/64Bit_build" 
        Fmakeinstall  libdir="$Fpkgdir/usr/lib32" dlldir="$Fpkgdir/usr/lib32/wine"

        Fexec cd ../64Bit_build || Fdie
        Fmakeinstall  libdir="$Fpkgdir/usr/lib" dlldir="$Fpkgdir/usr/lib/wine"

	Fexec cp $Fincdir/wine.conf $Fsrcdir
	Ffile /etc/binfmt.d/wine.conf
	Fln /usr/i686-frugalware-linux/bin/wine-preloader /usr/bin/wine-preloader
	Fln /usr/i686-frugalware-linux/bin/wine /usr/bin/wine

	## we cannot use reset_and_fix here since we don't split anything
	__cross32_unset_vars
	__cross32_export_orig_vars


}
