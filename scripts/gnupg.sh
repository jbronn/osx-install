#!/bin/bash
set -euxo pipefail

INSTALL="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/.. && pwd )"
NAME=gnupg
IDENTIFIER="org.gnu.pkg.${NAME}"
VERSION=1.4.23
VERNAME=$NAME-$VERSION
CHKSUM=c9462f17e651b6507848c08c430c791287cd75491f8b5a8b50c6ed46b12678ba
TARFILE=$VERNAME.tar.bz2
URL=https://gnupg.org/ftp/gcrypt/gnupg/$TARFILE

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
rm -fr $VERNAME
echo "${CHKSUM}  ${TARFILE}" | shasum -a 256 -c -
tar xjf $TARFILE

# Configure.
cd $VERNAME
./configure \
    CFLAGS=-I/usr/local/include \
    --disable-dependency-tracking \
    --disable-silent-rules \
    --disable-asm \
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
