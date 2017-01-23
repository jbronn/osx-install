#!/bin/bash
set -ex

INSTALL="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/.. && pwd )"
NAME=gnupg
IDENTIFIER="org.gnu.pkg.gnupg"
VERSION=1.4.21
VERNAME=$NAME-$VERSION
CHKSUM=6b47a3100c857dcab3c60e6152e56a997f2c7862c1b8b2b25adf3884a1ae2276
TARFILE=$VERNAME.tar.bz2
URL=https://gnupg.org/ftp/gcrypt/gnupg/$TARFILE

# Preparations.
BUILD=$INSTALL/build/$NAME
STAGING=$INSTALL/stage/$VERNAME
PKG=$INSTALL/pkg/$VERNAME.pkg

mkdir -p $BUILD

cd $BUILD
if [ ! -r $TARFILE ]; then
    curl -O $URL
fi

# Verify checksum and extract.
if [ ! -d $VERNAME ]; then
    echo "${CHKSUM}  ${TARFILE}" | shasum -a 256 -c -
    tar xjf $TARFILE
fi

# Configure.
cd $VERNAME
if [ ! -r Makefile ]; then
    ./configure \
        CFLAGS=-I/usr/local/include \
        --disable-dependency-tracking \
        --disable-silent-rules \
        --disable-asm \
        --prefix=/usr/local
fi

# Package.
if [ ! -r $PKG ]; then
    make clean
    make
    make check
    make install DESTDIR=$STAGING
    pkgbuild --root $STAGING --identifier "${IDENTIFIER}" --version $VERSION $PKG
fi
