#!/bin/bash
set -ex

INSTALL="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/.. && pwd )"
NAME=gnupg
IDENTIFIER="org.gnu.pkg.gnupg"
VERSION=1.4.20
VERNAME=$NAME-$VERSION
CHKSUM=04988b1030fa28ddf961ca8ff6f0f8984e0cddcb1eb02859d5d8fe0fe237edcc
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
