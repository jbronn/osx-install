#!/bin/bash
set -euxo pipefail

INSTALL="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/.. && pwd )"
NAME=Python
IDENTIFIER="org.python.pkg.python3"
VERSION=3.14.4
VERMAJ="${VERSION:0:4}"
VEREXTRA=""
VERNAME=${NAME}-${VERSION}${VEREXTRA}
CHKSUM=d923c51303e38e249136fc1bdf3568d56ecb03214efdef48516176d3d7faaef8
TARFILE=$VERNAME.tar.xz
URL=https://www.python.org/ftp/python/$VERSION/$TARFILE

# Preparations.
BUILD=$INSTALL/build/$NAME
KEYRING=$INSTALL/keyring/$NAME.gpg
STAGING=$INSTALL/stage/$VERNAME
PKG=$INSTALL/pkg/$VERNAME.pkg

# Check prereqs.
test -x /usr/local/bin/cosign || \
    (echo "cosign required for verification" && exit 1)
test -r /usr/local/lib/libreadline.dylib || \
    (echo "readline package is required" && exit 1)
test -r /usr/local/lib/libssl.dylib || \
    (echo "openssl package is required" && exit 1)
test -r /usr/local/lib/libsqlite3.dylib || \
    (echo "sqlite3 package is required" && exit 1)

# Download.
mkdir -p $BUILD
cd $BUILD
if [ ! -r $TARFILE ]; then
    curl -LO $URL
fi
if [ ! -r $TARFILE.sigstore ]; then
    curl -LO $URL.sigstore
fi

# Verify and extract.
rm -fr $VERNAME
cosign verify-blob \
--bundle $TARFILE.sigstore \
--cert-identity hugo@python.org \
--certificate-oidc-issuer https://github.com/login/oauth \
$TARFILE
echo "${CHKSUM}  ${TARFILE}" | shasum -a 256 -c -
tar xJf $TARFILE

cd $VERNAME

# Patch failing tests on macOS.
patch -p1 < ../test-fixes.patch

# Configure.
export MACOSX_DEPLOYMENT_TARGET=$(sw_vers | grep ^ProductVersion | awk '{ print $2 }')
./configure \
    --prefix=/usr/local \
    --enable-ipv6 \
    --enable-framework \
    --enable-loadable-sqlite-extensions \
    --enable-optimizations \
    --with-dbmliborder=ndbm \
    --with-dtrace \
    --with-lto \
    --with-system-expat \
    --with-system-libmpdec \
    --with-tail-call-interp \
    --without-ensurepip

# Compile
make clean
make

# Test
make quicktest

# Stage.
rm -fr $STAGING
make install DESTDIR=$STAGING PYTHONAPPSDIR=/usr/local
rm -fr $STAGING/usr/local/*.app
rm -fr $STAGING/usr/local/bin/2to3*
# Link in the pkg-config files.
mkdir -p $STAGING/usr/local/lib/pkgconfig
ln -s /Library/Frameworks/Python.framework/Versions/$VERMAJ/lib/pkgconfig/python-$VERMAJ.pc $STAGING/usr/local/lib/pkgconfig
ln -s /Library/Frameworks/Python.framework/Versions/$VERMAJ/lib/pkgconfig/python3.pc $STAGING/usr/local/lib/pkgconfig

# Package.
rm -f $PKG $INSTALL/pkg/$NAME.pkg
pkgbuild --root $STAGING --identifier "${IDENTIFIER}" --version ${VERSION}${VEREXTRA} $PKG
ln -s $PKG $INSTALL/pkg/$NAME.pkg

# Cleanup
rm -fr $STAGING
