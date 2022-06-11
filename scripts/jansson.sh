#!/bin/bash
set -euxo pipefail

INSTALL="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/.. && pwd )"
NAME=jansson
IDENTIFIER="org.digip.pkg.${NAME}"
VERSION=2.13.1
VERNAME=$NAME-$VERSION
CHKSUM=f4f377da17b10201a60c1108613e78ee15df6b12016b116b6de42209f47a474f
TARFILE=$VERNAME.tar.gz
URL=https://digip.org/jansson/releases/$TARFILE

# Preparations.
BUILD=$INSTALL/build/$NAME
KEYRING=$INSTALL/keyring/$NAME.gpg
STAGING=$INSTALL/stage/$VERNAME
PKG=$INSTALL/pkg/$VERNAME.pkg

# Check prereqs.
test -x /usr/local/bin/gpgv || (echo "GnuPG required for verification" && exit 1)

# Download.
mkdir -p $BUILD
cd $BUILD
if [ ! -r $TARFILE ]; then
    curl -LO $URL
fi
if [ ! -r $TARFILE.asc ]; then
    curl -LO $URL.asc
fi

# Verify and extract.
rm -fr $VERNAME
echo "${CHKSUM}  ${TARFILE}" | shasum -a 256 -c -
# Petri Lehtinen <petri@digip.org>, GnuPG keyid: D3657D24D058434C
gpgv -v --keyring $KEYRING $TARFILE.asc $TARFILE
tar xzf $TARFILE

# Configure.
cd $VERNAME
./configure \
    --prefix=/usr/local \
    --disable-dependency-tracking \
    --disable-static \
    --enable-shared

# Compile and stage.
make clean
make
rm -fr $STAGING
make install DESTDIR=$STAGING

# Package.
rm -f $PKG $INSTALL/pkg/$NAME.pkg
pkgbuild --root $STAGING --identifier "${IDENTIFIER}" --version $VERSION $PKG
ln -s $PKG $INSTALL/pkg/$NAME.pkg
