#!/bin/bash
set -euxo pipefail

INSTALL="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/.. && pwd )"
NAME=pkg-config
IDENTIFIER="org.freedesktop.pkg.pkg-config"
VERSION=0.29.2
VERNAME=$NAME-$VERSION
CHKSUM=6fc69c01688c9458a57eb9a1664c9aba372ccda420a02bf4429fe610e7e7d591
TARFILE=$VERNAME.tar.gz
URL=https://pkgconfig.freedesktop.org/releases/$TARFILE

# Preparations.
BUILD=$INSTALL/build/$NAME
KEYRING=$INSTALL/keyring/$NAME.gpg
STAGING=$INSTALL/stage/$VERNAME
PKG=$INSTALL/pkg/$VERNAME.pkg

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
# Dan Nicholson <nicholson.db@gmail.com>, GnuPG keyid: 023A4420C7EC6914
gpgv -v --keyring $KEYRING $TARFILE.asc $TARFILE
tar xzf $TARFILE

# Configure.
cd $VERNAME
./configure \
    CFLAGS="-Wno-int-conversion" \
    LIBS="-framework CoreFoundation -framework Cocoa" \
    --prefix=/usr/local \
    --disable-debug \
    --disable-host-tool \
    --with-internal-glib \
    --with-pc-path=/usr/local/lib/pkgconfig:/usr/local/share/pkgconfig:/usr/local/lib/pkgconfig:/usr/lib/pkgconfig

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
