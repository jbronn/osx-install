#!/bin/bash
set -ex

INSTALL="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/.. && pwd )"
NAME=sqlite3
IDENTIFIER="org.sqlite.pkg.sqlite3"
VERSION=3.13.0
VERNAME=sqlite-autoconf-3130000
CHKSUM=e2797026b3310c9d08bd472f6d430058c6dd139ff9d4e30289884ccd9744086b
TARFILE=$VERNAME.tar.gz
URL=https://sqlite.org/2016/$TARFILE

# Preparations.
BUILD=$INSTALL/build/$NAME
STAGING=$INSTALL/stage/$VERNAME
PKG=$INSTALL/pkg/$NAME-$VERSION.pkg

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
    CPPFLAGS="-DSQLITE_MAX_VARIABLE_NUMBER=250000 -DSQLITE_ENABLE_RTREE=1 -DSQLITE_ENABLE_JSON1=1" \
            ./configure \
            --prefix=/usr/local \
            --disable-dependency-tracking \
            --enable-dynamic-extensions
fi

# Package.
if [ ! -r $PKG ]; then
    make clean
    make
    rm -fr $STAGING
    make install DESTDIR=$STAGING
    pkgbuild --root $STAGING --identifier "${IDENTIFIER}" --version $VERSION $PKG
fi
