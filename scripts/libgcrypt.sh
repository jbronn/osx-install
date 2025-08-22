#!/bin/bash
set -euxo pipefail

INSTALL="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/.. && pwd )"
NAME=libgcrypt
IDENTIFIER="org.gnupg.pkg.${NAME}"
VERSION=1.11.2
VERNAME=$NAME-$VERSION
CHKSUM=6ba59dd192270e8c1d22ddb41a07d95dcdbc1f0fb02d03c4b54b235814330aac
TARFILE=$VERNAME.tar.bz2
URL=https://gnupg.org/ftp/gcrypt/libgcrypt/$TARFILE

# Preparations.
BUILD=$INSTALL/build/$NAME
KEYRING=$INSTALL/keyring/gnupg.gpg
STAGING=$INSTALL/stage/$VERNAME
PKG=$INSTALL/pkg/$VERNAME.pkg

# Check prereqs.
test -r /usr/local/lib/libgpg-error.dylib || (echo "libgpg-error required to be installed" && exit 1)

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
    --disable-asm \
    --disable-debug \
    --disable-dependency-tracking \
    --disable-silent-rules \
    --enable-static

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
