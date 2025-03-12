#!/usr/bin/env bash
set -euxo pipefail

INSTALL="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/.. && pwd )"
NAME=openconnect
IDENTIFIER="org.infradead.pkg.${NAME}"
VERSION=9.12
VERNAME=$NAME-$VERSION
CHKSUM=a2bedce3aa4dfe75e36e407e48e8e8bc91d46def5335ac9564fbf91bd4b2413e
TARFILE=$VERNAME.tar.gz
URL=https://www.infradead.org/openconnect/download/$TARFILE

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

# Compile and stage.
cd $VERNAME
patch -p1 < ../openconnect-75126982.diff
export LIBXML2_CFLAGS="$(xml2-config --cflags)"
export LIBXML2_LIBS="$(xml2-config --libs)"
./configure \
    --prefix=/usr/local \
    --sbindir=/usr/local/bin \
    --localstatedir=/usr/local/var \
    --with-vpnc-script=/usr/local/share/vpnc-scripts/vpnc-script

# Compile and stage.
make clean
make
make check
rm -fr $STAGING
make install DESTDIR=$STAGING

mkdir -p $STAGING/usr/local/share/vpnc-scripts
cp -pv ../vpnc-script $STAGING/usr/local/share/vpnc-scripts

# Package.
rm -f $PKG $INSTALL/pkg/$NAME.pkg
pkgbuild --root $STAGING --identifier "${IDENTIFIER}" --version $VERSION $PKG
ln -s $PKG $INSTALL/pkg/$NAME.pkg
