#!/bin/bash
set -euxo pipefail

INSTALL="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/.. && pwd )"
NAME=nettle
IDENTIFIER="org.gnu.pkg.${NAME}"
VERSION=3.10
VERNAME=$NAME-$VERSION
CHKSUM=b4c518adb174e484cb4acea54118f02380c7133771e7e9beb98a0787194ee47c
TARFILE=$VERNAME.tar.gz
URL=https://ftp.gnu.org/gnu/nettle/$TARFILE

# Preparations.
BUILD=$INSTALL/build/$NAME
KEYRING=$INSTALL/keyring/$NAME.gpg
STAGING=$INSTALL/stage/$VERNAME
PKG=$INSTALL/pkg/$VERNAME.pkg

# Check prereqs.
test -r /usr/local/lib/libgmp.dylib || (echo "gmp required to be installed" && exit 1)

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
if [ -x /usr/local/bin/gpgv ]; then
    # Niels Möller <nisse@lysator.liu.se>, GnuPG keyid: F3599FF828C67298
    gpgv -v --keyring $KEYRING $TARFILE.sig $TARFILE
fi
tar xzf $TARFILE

# Configure.
cd $VERNAME
./configure \
    --prefix=/usr/local \
    --disable-dependency-tracking \
    --disable-openssl \
    --enable-shared

# Compile and stage
make clean
make
make check || true
rm -fr $STAGING
make install DESTDIR=$STAGING

# Package
rm -f $PKG $INSTALL/pkg/$NAME.pkg
pkgbuild --root $STAGING --identifier "${IDENTIFIER}" --version $VERSION $PKG
ln -s $PKG $INSTALL/pkg/$NAME.pkg
