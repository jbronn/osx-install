#!/bin/bash
set -euxo pipefail

INSTALL="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/.. && pwd )"
NAME=gmp
IDENTIFIER="org.gnu.pkg.${NAME}"
VERSION=6.2.1
VERNAME=$NAME-$VERSION
CHKSUM=eae9326beb4158c386e39a356818031bd28f3124cf915f8c5b1dc4c7a36b4d7c
TARFILE=$VERNAME.tar.bz2
URL=https://gmplib.org/download/gmp/$TARFILE

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
if [ ! -r $TARFILE.sig ]; then
    curl -LO $URL.sig
fi

# Verify and extract.
rm -fr $VERNAME
echo "${CHKSUM}  ${TARFILE}" | shasum -a 256 -c -
# Niels Möller <nisse@lysator.liu.se>, GnuPG keyid: F3599FF828C67298
gpgv -v --keyring $KEYRING $TARFILE.sig $TARFILE
tar xzf $TARFILE

# Configure.
cd $VERNAME
./configure \
    --prefix=/usr/local \
    --disable-dependency-tracking \
    --disable-silent-rules \
    --disable-static \
    --enable-cxx \
    --with-pic

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
