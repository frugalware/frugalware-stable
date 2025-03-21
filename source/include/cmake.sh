#!/bin/sh

###
# = cmake.sh(3)
# Gabriel Craciunescu <crazy@frugalware.org>
#
# == NAME
# cmake.sh - for Frugalware
#
# == SYNOPSIS
# Common schema for packages using cmake build system.
#
# == OPTIONS
# * _F_cmake_type (default: None): Possible values  Debug, Debugfull, Release, Relwithdebinfo
# * _F_cmake_verbose (default: True): Possible values True or False
# * _F_cmake_color (default: OFF): Possible values ON or OFF
# * _F_cmake_confopts (default: nothing): Use like with Fconfopts
###

if [ -z "$_F_cmake_type" ]; then
	_F_cmake_type="Release"
fi

if [ -z "$_F_cmake_verbose" ]; then
	_F_cmake_verbose="True"
fi

if [ -z "$_F_cmake_color" ]; then
	_F_cmake_color="OFF"
fi

if [ -z "$_F_cmake_src_dir" ]; then
	_F_cmake_src_dir="."
fi


if [ -z "$_F_cmake_rpath" ]; then
        _F_cmake_rpath="ON"
else
	_F_cmake_rpath="OFF"
fi

if [ -z "$_F_cmake_install_rpath" ]; then
	_F_cmake_install_rpath="ON"
else
	_F_cmake_install_rpath="OFF"
fi

if [ -z "$_F_cmake_build_dir" ]; then
        _F_cmake_build_dir="frugalware_cmake_build"
fi

if [ -z "$_F_cmake_use_ninja" ]; then
    cmake_generator=""
    cmake_builder="make"
else
    cmake_generator=" -G Ninja "
    cmake_builder="ninja"
    makedepends+=('ninja')
fi

CROSS_LIB="lib"
CROSS_BIN="bin"
CROSS_SBIN="bin"
CROSS_PREFIX="/usr"
CROSS_INC="include"

###
# == APPENDED VARIABLES
# * makedepends(): add cmake and pkgconfig
# * options(): add nostrip if _F_cmake_type is Debug*
###
makedepends+=('cmake>=3.23' 'pkgconfig')

###
# == PROVIDED FUNCTIONS
# * CMake_setup(): Setup packages depending on some _F_cmake_* options.
###
CMake_setup()
{
	local i

	case "$_F_cmake_type" in
	Debug*)
		options=("${options[@]}" 'nostrip')
		for i in $(seq 0 $((${#subpkgs[@]} - 1))); do
			suboptions[$i]="${suboptions[$i]} nostrip"
		done
		;;
	esac
}

###
# * CMake_conf(): This is the 'configure' part but cmake way.
###
CMake_conf()
{
	CMake_setup

	cmake \
        ${cmake_generator} \
		-DCMAKE_INSTALL_PREFIX=${CROSS_PREFIX} \
		-DCMAKE_INSTALL_LIBDIR=${CROSS_LIB} \
		-DCMAKE_INSTALL_BINDIR=${CROSS_BIN} \
		-DCMAKE_INSTALL_SBINDIR=${CROSS_SBIN} \
		-DCMAKE_INSTALL_INCLUDEDIR=${CROSS_INC} \
		-DSYSCONF_INSTALL_DIR=/etc \
		-DLIBEXEC_INSTALL_DIR="/usr/${CROSS_LIB}/$pkgname" \
		-DCMAKE_INSTALL_LIBEXECDIR="/usr/${CROSS_LIB}/$pkgname" \
		-DCMAKE_BUILD_TYPE="$_F_cmake_type" \
		-DCMAKE_VERBOSE_MAKEFILE="$_F_cmake_verbose" \
		-DCMAKE_COLOR_MAKEFILE="$_F_cmake_color" \
		-DCMAKE_EXE_LINKER_FLAGS="$LDFLAGS" \
		-DCMAKE_SHARED_LINKER_FLAGS="$LDFLAGS" \
		-DCMAKE_MODULE_LINKER_FLAGS="$LDFLAGS" \
		-DCMAKE_CXX_FLAGS="$CXXFLAGS" \
		-DCMAKE_C_FLAGS="$CFLAGS" \
		-DCMAKE_CXX_FLAGS_DEBUG="$CXXFLAGS" \
		-DCMAKE_C_FLAGS_DEBUG="$CFLAGS" \
		-DCMAKE_SKIP_RPATH="$_F_cmake_rpath" \
		-DCMAKE_SKIP_INSTALL_RPATH="$_F_cmake_install_rpath" \
		-DCMAKE_CXX_FLAGS_RELEASE="-DNDEBUG" \
		-DCMAKE_C_FLAGS_RELEASE="-DNDEBUG" \
		-Wno-dev \
		$_F_cmake_confopts "$@" -S $_F_cmake_src_dir -B $_F_cmake_build_dir|| Fdie
}

###
# * CMake_prepare_build(): Runs 'Fpatchall' and prepares the 'build' dir needed by cmake.
###
CMake_prepare_build()
{
	Fcd
        if [ -z "$_Fbuild_no_patch" ]; then
	        Fpatchall
        fi
}

###
# * CMake_make(): Calls 'CMake_prepare_build()' , 'CMake_conf()' and runs cmake_builder
###
CMake_make()
{
	CMake_prepare_build
	CMake_conf "$@"
	cd $_F_cmake_build_dir || Fdie
	${cmake_builder} || Fdie
}

CMake_install()
{
    if [ -z "$_F_cmake_use_ninja" ]; then
        make DESTDIR=$Fdestdir install/fast || Fdie
    else
        DESTDIR=$Fdestdir ninja install || Fdie
    fi
	Fremove_static_libs
	Ffix_la_files
}
###
# * CMake_build(): build() wrapper
###
CMake_build()
{
	CMake_make "$@"
	CMake_install
}

###
# * build(): Calls 'CMake_build()'
###
build()
{
	CMake_build
}

