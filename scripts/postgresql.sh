#!/bin/bash
set -ex

INSTALL="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/.. && pwd )"
NAME=postgresql
IDENTIFIER="org.postgresql.pkg.postgresql"
VERSION=9.5.3
VERNAME=$NAME-$VERSION
CHKSUM=7385c01dc58acba8d7ac4e6ad42782bd7c0b59272862a3a3d5fe378d4503a0b4
TARFILE=$VERNAME.tar.bz2
URL=https://ftp.postgresql.org/pub/source/v$VERSION/$VERNAME.tar.bz2

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
    tar xzf $TARFILE
fi

# Configure.
cd $VERNAME
if [ ! -r GNUMakefile ]; then
    ./configure \
        MACOSX_DEPLOYMENT_TARGET=10.11 \
        --prefix=/usr/local \
        --disable-debug \
        --enable-dtrace \
        --enable-thread-safety \
        --with-bonjour \
        --with-gssapi \
        --with-ldap \
        --with-openssl \
        --with-pam \
        --with-libxml \
        --with-libxslt \
        --with-python \
        --with-uuid=e2fs
fi

# Package.
if [ ! -r $PKG ]; then
    make clean
    make
    make check

    rm -fr $STAGING
    make install DESTDIR=$STAGING

    pkgbuild --root $STAGING --identifier "${IDENTIFIER}" --version $VERSION $PKG
fi
