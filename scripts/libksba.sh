#!/bin/bash
set -euxo pipefail

INSTALL="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/.. && pwd )"
NAME=libksba
IDENTIFIER="org.gnupg.pkg.${NAME}"
VERSION=1.6.7
VERNAME=$NAME-$VERSION
CHKSUM=cf72510b8ebb4eb6693eef765749d83677a03c79291a311040a5bfd79baab763
TARFILE=$VERNAME.tar.bz2
URL=https://gnupg.org/ftp/gcrypt/libksba/$TARFILE

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
    --disable-silent-rules \
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
