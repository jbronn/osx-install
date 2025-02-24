#!/bin/bash
set -euxo pipefail

INSTALL="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/.. && pwd )"
NAME=emacs
VERSION=30.1
VERNAME=$NAME-$VERSION
CHKSUM=6ccac1ae76e6af93c6de1df175e8eb406767c23da3dd2a16aa67e3124a6f138f
TARFILE=$VERNAME.tar.xz
URL=https://ftp.gnu.org/gnu/emacs/$TARFILE

# Preparations.
BUILD=$INSTALL/build/$NAME
KEYRING=$INSTALL/keyring/$NAME.gpg
PKGDIR=$INSTALL/pkg/$NAME/$VERSION

# Check prereqs.
test -x /usr/local/bin/gpgv || (echo "GnuPG required for verification" && exit 1)
test -r /usr/local/lib/libjansson.dylib || (echo "libjansson required to be installed" && exit 1)
test -r /usr/local/lib/libgnutls.dylib || (echo "gnutls required to be installed" && exit 1)

# Download.
mkdir -p $BUILD $PKGDIR
cd $BUILD
if [ ! -r $TARFILE ]; then
    curl -LO $URL
fi
if [ ! -r $TARFILE.sig ]; then
    curl -LO $URL.sig
fi

# Verify and extract.
test -x /usr/local/bin/gpg || (echo "GnuPG required for verification" && exit 1)
rm -fr $VERNAME
echo "${CHKSUM}  ${TARFILE}" | shasum -a 256 -c -
# Eli Zaretskii (eliz) <eliz@gnu.org>, GnuPG keyids: 91C1262F01EB8D39, E78DAE0F3115E06B
gpgv -v --keyring $KEYRING $TARFILE.sig $TARFILE
tar xJf $TARFILE

# Configure; `--with-ns` is magic flag that makes this an bundle.
cd $VERNAME
./configure \
    --prefix=/usr/local \
    --with-ns \
    --with-xml2

# Package.
rm -fr $PKGDIR/Emacs.app $INSTALL/pkg/Emacs.app
make install
# Move application bundle (this isn't a `.pkg` that requires root).
mv -v nextstep/Emacs.app $PKGDIR
