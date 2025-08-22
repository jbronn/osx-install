#!/bin/bash
set -ex

INSTALL="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/.. && pwd )"
NAME=xz
IDENTIFIER="org.tukaani.pkg.xz"
VERSION=5.8.1
VERNAME=$NAME-$VERSION
CHKSUM=507825b599356c10dca1cd720c9d0d0c9d5400b9de300af00e4d1ea150795543
TARFILE=$VERNAME.tar.gz
URL=https://tukaani.org/xz/$TARFILE

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
# Verify signature if gpgv is available.
if [ -x /usr/local/bin/gpgv ]; then
    # Lasse Collin <lasse.collin@tukaani.org>, GnuPG keyid 38EE757D69184620.
    gpgv -v --keyring $KEYRING $TARFILE.sig $TARFILE
fi
tar xzf $TARFILE

# Configure.
cd $VERNAME
./configure \
    --prefix=/usr/local \
    --disable-debug \
    --disable-dependency-tracking \
    --disable-silent-rules \
    --disable-nls

# Compile and stage.
make clean
make
rm -fr $STAGING
make install DESTDIR=$STAGING

# Package.
rm -f $PKG $INSTALL/pkg/$NAME.pkg
pkgbuild --root $STAGING --identifier "${IDENTIFIER}" --version $VERSION $PKG
ln -s $PKG $INSTALL/pkg/$NAME.pkg
