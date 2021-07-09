#!/bin/bash
set -ex

INSTALL="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/.. && pwd )"
NAME=sqlite3
IDENTIFIER="org.sqlite.pkg.sqlite3"
VERSION=3.36.0
VERNAME=sqlite-autoconf-3360000
CHKSUM=bd90c3eb96bee996206b83be7065c9ce19aef38c3f4fb53073ada0d0b69bbce3
TARFILE=$VERNAME.tar.gz
URL=https://sqlite.org/2021/$TARFILE

# Preparations.
BUILD=$INSTALL/build/$NAME
STAGING=$INSTALL/stage/$VERNAME
PKG=$INSTALL/pkg/$NAME-$VERSION.pkg

# Download.
mkdir -p $BUILD
cd $BUILD
if [ ! -r $TARFILE ]; then
    curl -LO $URL
fi

# Extract
rm -fr $VERNAME
echo "${CHKSUM}  ${TARFILE}" | shasum -a 256 -c -
tar xzf $TARFILE

# Configure.
cd $VERNAME
CPPFLAGS="-DSQLITE_ENABLE_COLUMN_METADATA=1 -DSQLITE_DISABLE_DIRSYNC=1 -DSQLITE_SECURE_DELETE=1 -fno-strict-aliasing" \
        ./configure \
        --prefix=/usr/local \
        --disable-dependency-tracking \
        --disable-static \
        --enable-dynamic-extensions \
        --enable-threadsafe

# Compile and stage.
make clean
make
rm -fr $STAGING
make install DESTDIR=$STAGING

# Package.
rm -f $PKG $INSTALL/pkg/$NAME.pkg
pkgbuild --root $STAGING --identifier "${IDENTIFIER}" --version $VERSION $PKG
ln -s $PKG $INSTALL/pkg/$NAME.pkg
