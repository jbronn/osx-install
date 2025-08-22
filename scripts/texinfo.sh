#!/bin/bash
set -euxo pipefail

INSTALL="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/.. && pwd )"
NAME=texinfo
IDENTIFIER="org.gnu.pkg.${NAME}"
VERSION=7.2
VERNAME=$NAME-$VERSION
CHKSUM=0329d7788fbef113fa82cb80889ca197a344ce0df7646fe000974c5d714363a6
TARFILE=$VERNAME.tar.xz
URL=https://ftp.gnu.org/gnu/texinfo/$TARFILE

# Preparations.
BUILD=$INSTALL/build/$NAME
KEYRING=$INSTALL/keyring/gnu.gpg
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
# https://savannah.gnu.org/project/memberlist-gpgkeys.php?group=texinfo&download=1
gpgv -v --keyring $KEYRING $TARFILE.sig $TARFILE
tar xJf $TARFILE

# Configure.
cd $VERNAME
./configure \
    --prefix=/usr/local \
    --disable-dependency-tracking \
    --disable-install-warnings

# Compile and stage
make clean
make
make check
rm -fr $STAGING
make install DESTDIR=$STAGING

# Package
rm -f $PKG $INSTALL/pkg/$NAME.pkg
pkgbuild --root $STAGING --identifier "${IDENTIFIER}" --version $VERSION $PKG
ln -s $PKG $INSTALL/pkg/$NAME.pkg
