#!/bin/bash
set -ex

INSTALL="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/.. && pwd )"
NAME=postgresql
IDENTIFIER="org.postgresql.pkg.postgresql"
VERSION=9.5.5
VERNAME=$NAME-$VERSION
CHKSUM=02c65290be74de6604c3fed87c9fd3e6b32e949f0ab8105a75bd7ed5aa71f394
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
        CFLAGS=-I/usr/local/include \
        LDFLAGS=-L/usr/local/lib \
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
    make install-world DESTDIR=$STAGING

    pkgbuild --root $STAGING --identifier "${IDENTIFIER}" --version $VERSION $PKG
fi
