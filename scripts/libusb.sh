#!/bin/bash
set -euxo pipefail

INSTALL="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/.. && pwd )"
NAME=libusb
IDENTIFIER="info.libusb.pkg.${NAME}"
VERSION=1.0.29
VERNAME=$NAME-$VERSION
CHKSUM=5977fc950f8d1395ccea9bd48c06b3f808fd3c2c961b44b0c2e6e29fc3a70a85
TARFILE=$VERNAME.tar.bz2
URL=https://github.com/libusb/libusb/releases/download/v$VERSION/$TARFILE

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
rm -fr $VERNAME
echo "${CHKSUM}  ${TARFILE}" | shasum -a 256 -c -
# Verify signature if gpgv is available.
if [ -x /usr/local/bin/gpgv ]; then
    # Tormod Volden <tormod.volden@gmail.com>, GnuPG key id: C68187379B23DE9EFC46651E2C80FF56C6830A0E
    gpgv -v --keyring $KEYRING $TARFILE.asc $TARFILE
fi
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
