#!/bin/bash
set -euxo pipefail

INSTALL="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/.. && pwd )"
NAME=icu4c
IDENTIFIER="org.unicode.pkg.${NAME}"
VERSION=76.1
VERNAME=$NAME-$VERSION
CHKSUM=dfacb46bfe4747410472ce3e1144bf28a102feeaa4e3875bac9b4c6cf30f4f3e
TARFILE=$NAME-$(echo $VERSION | tr '.' '_')-src.tgz
URL=https://github.com/unicode-org/icu/releases/download/release-$(echo $VERSION | tr '.' '-')/$TARFILE

# ICU is signed, but unfortunately signature uses Ed25519 which is too new for GPGv1 to
# verify -- ugh, guess I'll have to look into glib madness to get GPGv2 working after all.

# Preparations.
BUILD=$INSTALL/build/$NAME
STAGING=$INSTALL/stage/$VERNAME
PKG=$INSTALL/pkg/$VERNAME.pkg

# Download.
mkdir -p $BUILD
cd $BUILD
if [ ! -r $TARFILE ]; then
    curl -LO $URL
fi

# Verify checksum and extract.
rm -fr icu
shasum -a 256 -c <(printf "${CHKSUM}  ${TARFILE}\n")
tar xzf $TARFILE

# Configure.
cd icu/source
CFLAGS="-O2" \
./configure \
  --disable-samples \
  --enable-rpath \
  --enable-shared \
  --enable-static \
  --with-library-bits=64

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
