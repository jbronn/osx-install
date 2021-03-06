#!/bin/bash
set -euxo pipefail

INSTALL="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/.. && pwd )"
NAME=libpng
IDENTIFIER="org.libpng.pkg.libpng"
VERSION=1.6.37
VERNAME=$NAME-$VERSION
CHKSUM=daeb2620d829575513e35fecc83f0d3791a620b9b93d800b763542ece9390fb4
TARFILE=$VERNAME.tar.gz
URL=http://prdownloads.sourceforge.net/libpng/$TARFILE

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

# Verify and extract.
rm -fr $VERNAME
echo "${CHKSUM}  ${TARFILE}" | shasum -a 256 -c -
tar xzf $TARFILE

# Configure.
cd $VERNAME
./configure \
    --prefix=/usr/local \
    --disable-dependency-tracking \
    --disable-silent-rules \
    --disable-static

# Compile and stage.
make clean
make
make test
rm -fr $STAGING
make install DESTDIR=$STAGING
sed -i -e 's/^Requires: zlib//' $STAGING/usr/local/lib/pkgconfig/libpng16.pc
sed -i -e 's/^Libs.private: -lz//' $STAGING/usr/local/lib/pkgconfig/libpng16.pc

# Package.
rm -f $PKG $INSTALL/pkg/$NAME.pkg
pkgbuild --root $STAGING --identifier "${IDENTIFIER}" --version $VERSION $PKG
ln -s $PKG $INSTALL/pkg/$NAME.pkg
