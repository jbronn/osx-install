#!/bin/bash
set -euxo pipefail

INSTALL="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/.. && pwd )"
NAME=pinentry
IDENTIFIER="org.gnupg.pkg.${NAME}"
VERSION=1.3.1
VERNAME=$NAME-$VERSION
CHKSUM=bc72ee27c7239007ab1896c3c2fae53b076e2c9bd2483dc2769a16902bce8c04
TARFILE=$VERNAME.tar.bz2
URL=https://gnupg.org/ftp/gcrypt/pinentry/$TARFILE

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
    --disable-pinentry-fltk \
    --disable-pinentry-gnome3 \
    --disable-pinentry-gtk2 \
    --disable-pinentry-qt \
    --disable-pinentry-qt5 \
    --disable-pinentry-tqt \
    --enable-pinentry-tty

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
