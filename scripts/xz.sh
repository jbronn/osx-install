#!/bin/bash
set -ex

INSTALL="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/.. && pwd )"
NAME=xz
IDENTIFIER="org.tukaani.pkg.xz"
VERSION=5.2.2
VERNAME=$NAME-$VERSION
CHKSUM=73df4d5d34f0468bd57d09f2d8af363e95ed6cc3a4a86129d2f2c366259902a2
TARFILE=$VERNAME.tar.gz
URL=https://fossies.org/linux/misc/$TARFILE

# Preparations.
BUILD=$INSTALL/build/$NAME
STAGING=$INSTALL/stage/$VERNAME
PKG=$INSTALL/pkg/$VERNAME.pkg

mkdir -p $BUILD

cd $BUILD
if [ ! -r $TARFILE ]; then
    curl -O $URL
fi

# Extract
if [ ! -d $VERNAME ]; then
    echo "${CHKSUM}  ${TARFILE}" | shasum -a 256 -c -
    tar xzf $TARFILE
fi

# Configure.
cd $VERNAME
if [ ! -r Makefile ]; then
    ./configure \
        --disable-debug \
        --disable-dependency-tracking \
        --disable-silent-rules \
        --prefix=/usr/local
fi

# Package.
if [ ! -r $PKG ]; then
    make clean
    make
    rm -fr $STAGING
    make install DESTDIR=$STAGING
    pkgbuild --root $STAGING --identifier "${IDENTIFIER}" --version $VERSION $PKG
fi
