#!/bin/bash
set -ex

INSTALL="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/.. && pwd )"
NAME=sqlite3
IDENTIFIER="org.sqlite.pkg.sqlite3"
VERSION=3.41.0
VERNAME="sqlite-autoconf-$(echo "${VERSION}" | tr -d .)000"
CHKSUM=49f77ac53fd9aa5d7395f2499cb816410e5621984a121b858ccca05310b05c70
TARFILE=$VERNAME.tar.gz
URL=https://sqlite.org/2023/$TARFILE

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
