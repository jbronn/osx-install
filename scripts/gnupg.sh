#!/bin/bash
set -euxo pipefail

INSTALL="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/.. && pwd )"
NAME=gnupg
IDENTIFIER="org.gnupg.pkg.${NAME}"
VERSION=2.4.8
VERNAME=$NAME-$VERSION
CHKSUM=b58c80d79b04d3243ff49c1c3fc6b5f83138eb3784689563bcdd060595318616
TARFILE=$VERNAME.tar.bz2
URL=https://gnupg.org/ftp/gcrypt/gnupg/$TARFILE

# Preparations.
BUILD=$INSTALL/build/$NAME
KEYRING=$INSTALL/keyring/$NAME.gpg
STAGING=$INSTALL/stage/$VERNAME
PKG=$INSTALL/pkg/$VERNAME.pkg

# Check prereqs.
test -r /usr/local/lib/libgettextlib.dylib || (echo "gettext required to be installed" && exit 1)
test -r /usr/local/lib/libassuan.dylib || (echo "libassuan required to be installed" && exit 1)
test -r /usr/local/lib/libgcrypt.dylib || (echo "libgcrypt required to be installed" && exit 1)
test -r /usr/local/lib/libgpg-error.dylib || (echo "libgpg-error required to be installed" && exit 1)
test -r /usr/local/lib/libgnutls.dylib || (echo "gnutls required to be installed" && exit 1)
test -r /usr/local/lib/libksba.dylib || (echo "libksba required to be installed" && exit 1)
test -r /usr/local/lib/libreadline.dylib || (echo "readline package is required" && exit 1)
test -r /usr/local/lib/libusb-1.0.dylib || (echo "libusb required to be installed" && exit 1)
test -x /usr/local/bin/pinentry || (echo "pinentry required to be installed" && exit 1)
test -r /usr/local/lib/libnpth.dylib || (echo "npth required to be installed" && exit 1)

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
# GnuPG 2 required to verify.
if [ -x /usr/local/bin/gpgv ] && gpgv --version | head -n1 | awk '{ print $3 }' | grep -q ^2\.; then
    # Werner Koch (dist signing 2020), GnuPG keyid: 6DAA6E64A76D2840571B4902528897B826403AD
    # Niibe Yutaka (GnuPG Release Key), GnuPG keyid: AC8E115BF73E2D8D47FA9908E98E9B2D19C6C8BD
    gpgv -v --keyring $KEYRING $TARFILE.sig $TARFILE
fi
tar xjf $TARFILE

# Configure.
cd $VERNAME
./configure \
    --disable-debug \
    --disable-dependency-tracking \
    --disable-silent-rules \
    --enable-all-tests \
    --with-pinentry-pgm=/usr/local/bin/pinentry

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
