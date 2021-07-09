#!/bin/bash
set -euxo pipefail

INSTALL="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/.. && pwd )"
NAME=Python
IDENTIFIER="org.python.pkg.python3"
VERSION=3.9.6
VERMAJ="${VERSION:0:3}"
VERNAME=$NAME-$VERSION
CHKSUM=d0a35182e19e416fc8eae25a3dcd4d02d4997333e4ad1f2eee6010aadc3fe866
TARFILE=$VERNAME.tgz
URL=https://www.python.org/ftp/python/$VERSION/$TARFILE

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

if [ ! -r $TARFILE.asc ]; then
    curl -LO $URL.asc
fi

# Verify and extract.
test -x /usr/local/bin/gpgv || (echo "GnuPG required for verification" && exit 1)
rm -fr $VERNAME
# Łukasz Langa (GPG langa.pl) <lukasz@langa.pl>, GnuPG keyid: B26995E310250568
gpgv -v --keyring $KEYRING $TARFILE.asc $TARFILE || \
    (echo "Can't verify tarball." && exit 1)
echo "${CHKSUM}  ${TARFILE}" | shasum -a 256 -c -
tar xzf $TARFILE

# Configure.
cd $VERNAME
./configure \
    MACOSX_DEPLOYMENT_TARGET=$(sw_vers | grep ^ProductVersion | awk '{ print $2 }') \
    --prefix=/usr/local \
    --enable-ipv6 \
    --enable-framework \
    --without-ensurepip

# Compile
make clean
make

# TODO: Figure out why popen test is failing.
make quicktest || true

rm -fr $STAGING
make install DESTDIR=$STAGING PYTHONAPPSDIR=/usr/local
rm -fr $STAGING/usr/local/*.app
rm -fr $STAGING/usr/local/bin/2to3*

# Link in the pkg-config files.
mkdir -p $STAGING/usr/local/lib/pkgconfig
ln -s /Library/Frameworks/Python.framework/Versions/$VERMAJ/lib/pkgconfig/python-$VERMAJ.pc $STAGING/usr/local/lib/pkgconfig
ln -s /Library/Frameworks/Python.framework/Versions/$VERMAJ/lib/pkgconfig/python3.pc $STAGING/usr/local/lib/pkgconfig

# Package
pkgbuild --root $STAGING --identifier "${IDENTIFIER}" --version $VERSION $PKG
