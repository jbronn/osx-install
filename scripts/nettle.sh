#!/bin/bash
set -euxo pipefail

INSTALL="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/.. && pwd )"
NAME=nettle
IDENTIFIER="org.gnu.pkg.${NAME}"
VERSION=3.10.2
VERNAME=$NAME-$VERSION
CHKSUM=fe9ff51cb1f2abb5e65a6b8c10a92da0ab5ab6eaf26e7fc2b675c45f1fb519b5
TARFILE=$VERNAME.tar.gz
URL=https://ftp.gnu.org/gnu/nettle/$TARFILE

# Preparations.
BUILD=$INSTALL/build/$NAME
KEYRING=$INSTALL/keyring/gnu.gpg
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
