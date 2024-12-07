#!/bin/bash
set -euxo pipefail

INSTALL="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/.. && pwd )"
NAME=libusb
IDENTIFIER="info.libusb.pkg.${NAME}"
VERSION=1.0.27
VERNAME=$NAME-$VERSION
CHKSUM=ffaa41d741a8a3bee244ac8e54a72ea05bf2879663c098c82fc5757853441575
TARFILE=$VERNAME.tar.bz2
URL=https://github.com/libusb/libusb/releases/download/v1.0.27/$TARFILE

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
if [ ! -r $TARFILE.asc ]; then
    curl -LO $URL.asc
fi

# Verify and extract.
test -x /usr/local/bin/gpgv || (echo "GnuPG required for verification" && exit 1)
rm -fr $VERNAME
echo "${CHKSUM}  ${TARFILE}" | shasum -a 256 -c -
# Tormod Volden <tormod.volden@gmail.com>, GnuPG key id: C68187379B23DE9EFC46651E2C80FF56C6830A0E
gpgv -v --keyring $KEYRING $TARFILE.asc $TARFILE

# TODO: Verify signature if updated gpgv is available.
tar xjf $TARFILE

# Configure.
cd $VERNAME
./configure \
    --disable-dependency-tracking \
    --prefix=/usr/local

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
