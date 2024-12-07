#!/bin/bash
set -euxo pipefail

INSTALL="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/.. && pwd )"
NAME=libassuan
IDENTIFIER="org.gnupg.pkg.${NAME}"
VERSION=2.5.7
VERNAME=$NAME-$VERSION
CHKSUM=0103081ffc27838a2e50479153ca105e873d3d65d8a9593282e9c94c7e6afb76
TARFILE=$VERNAME.tar.bz2
URL=https://gnupg.org/ftp/gcrypt/libassuan/$TARFILE

# Preparations.
BUILD=$INSTALL/build/$NAME
KEYRING=$INSTALL/keyring/$NAME.gpg
STAGING=$INSTALL/stage/$VERNAME
PKG=$INSTALL/pkg/$VERNAME.pkg

# Download.
mkdir -p $BUILD
cd $BUILD
if [ ! -r $TARFILE ]; then
    curl -LO $URL
fi
if [ ! -r $TARFILE.sig ]; then
    curl -LO $URL.sig
fi

# Verify and extract.
rm -fr $VERNAME
echo "${CHKSUM}  ${TARFILE}" | shasum -a 256 -c -
# TODO: Verify signature if updated gpgv is available.
tar xjf $TARFILE

# Configure.
cd $VERNAME
./configure \
    --disable-debug \
    --disable-dependency-tracking \
    --disable-silent-rules \
    --enable-static

# Compile and stage.
make clean
make
make check
rm -fr $STAGING
make install DESTDIR=$STAGING

# Package.
rm -f $PKG $INSTALL/pkg/$NAME.pkg
pkgbuild --root $STAGING --identifier "${IDENTIFIER}" --version $VERSION $PKG
ln -s $PKG $INSTALL/pkg/$NAME.pkg
