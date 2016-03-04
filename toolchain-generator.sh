#!/bin/sh

 ##############################################################################
 #       ninjastorms - shuriken operating system                              #
 #                                                                            #
 #    Copyright (C) 2014 - 2016  Andreas Grapentin et al.                     #
 #                                                                            #
 #    This program is free software: you can redistribute it and/or modify    #
 #    it under the terms of the GNU General Public License as published by    #
 #    the Free Software Foundation, either version 3 of the License, or       #
 #    (at your option) any later version.                                     #
 #                                                                            #
 #    This program is distributed in the hope that it will be useful,         #
 #    but WITHOUT ANY WARRANTY; without even the implied warranty of          #
 #    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the           #
 #    GNU General Public License for more details.                            #
 #                                                                            #
 #    You should have received a copy of the GNU General Public License       #
 #    along with this program.  If not, see <http://www.gnu.org/licenses/>.   #
 ##############################################################################

set -e
set -u

# toolchain parameters
TARGET=${TARGET:-i686-elf}
MFLAGS=${MFLAGS:-}
PREFIX=${PREFIX:-/usr/local}

# used versions
GCC_VERSION=${GCC_VERSION:-4.8.0}
GMP_VERSION=${GMP_VERSION:-5.1.1}
MPC_VERSION=${MPC_VERSION:-1.0.1}
MPFR_VERSION=${MPFR_VERSION:-3.1.2}
GDB_VERSION=${GDB_VERSION:-7.6}
BINUTILS_VERSION=${BINUTILS_VERSION:-2.24}

# directory config
TARDIR=${TARDIR:-$(dirname $(readlink -f $0))/sources}
PATCHDIR=$(dirname $(readlink -f $0))/patches
BUILDROOT=${BUILDROOT:-/tmp/$(basename $0)}
SRCDIR=$BUILDROOT/src
BUILDDIR=$BUILDROOT/build

# clean up previous build, if any
rm -rf $SRCDIR $BUILDDIR
mkdir -vp $TARDIR $SRCDIR $BUILDDIR

# fetch
fetch () {
  if [ -f $TARDIR/$(basename $1).* ]; then
    return
  fi

  wget -nc -P $TARDIR --progress=dot:giga $1.bz2 || \
  wget -nc -P $TARDIR --progress=dot:giga $1.xz || \
  wget -nc -P $TARDIR --progress=dot:giga $1.gz
}

fetch ftp://ftp.gnu.org/gnu/gcc/gcc-$GCC_VERSION/gcc-$GCC_VERSION.tar
fetch ftp://ftp.gnu.org/gnu/gmp/gmp-$GMP_VERSION.tar
fetch ftp://ftp.gnu.org/gnu/mpc/mpc-$MPC_VERSION.tar
fetch http://www.mpfr.org/mpfr-$MPFR_VERSION/mpfr-$MPFR_VERSION.tar
fetch ftp://ftp.gnu.org/gnu/gdb/gdb-$GDB_VERSION.tar
fetch http://ftp.gnu.org/gnu/binutils/binutils-$BINUTILS_VERSION.tar

# unpack
for f in $TARDIR/*.tar.*; do
  tar -C $SRCDIR --checkpoint=.4096 --total -xf $f
done

mv $SRCDIR/gmp-$GMP_VERSION $SRCDIR/gcc-$GCC_VERSION/gmp
mv $SRCDIR/mpc-$MPC_VERSION $SRCDIR/gcc-$GCC_VERSION/mpc
mv $SRCDIR/mpfr-$MPFR_VERSION $SRCDIR/gcc-$GCC_VERSION/mpfr

# build binutils
mkdir -vp $BUILDDIR/binutils-$BINUTILS_VERSION
cd $BUILDDIR/binutils-$BINUTILS_VERSION
../../src/binutils-$BINUTILS_VERSION/configure \
    --target=$TARGET --prefix=$PREFIX --disable-nls --with-sysroot --disable-werror
make $MFLAGS all
make install

export PATH="$PATH:$PREFIX/bin"

# build gcc
mkdir -vp $BUILDDIR/gcc-$GCC_VERSION
cd $BUILDDIR/gcc-$GCC_VERSION
../../src/gcc-$GCC_VERSION/configure \
    --target=$TARGET --prefix=$PREFIX --disable-nls --enable-languages="c,c++" --without-headers
make $MFLAGS all-gcc
make $MFLAGS all-target-libgcc
make install-gcc
make install-target-libgcc

# build gdb
patch -d $SRCDIR/gdb-$GDB_VERSION -p1 < $PATCHDIR/gdb-configure.patch
mkdir -vp $BUILDDIR/gdb-$GDB_VERSION
cd $BUILDDIR/gdb-$GDB_VERSION
../../src/gdb-$GDB_VERSION/configure \
    --target=$TARGET --prefix=$PREFIX --disable-nls --disable-werror
make $MFLAGS all
make install

# cleanup
rm -rf $BUILDDIR $SRCDIR

echo "all done. :)"
