#!/bin/bash
set -euxo pipefail

INSTALL="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/.. && pwd )"
NAME=emacs
VERSION=27.2
VERNAME=$NAME-$VERSION
CHKSUM=80ff6118fb730a6d8c704dccd6915a6c0e0a166ab1daeef9fe68afa9073ddb73
TARFILE=$VERNAME.tar.gz
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
# Eli Zaretskii (eliz) <eliz@gnu.org>, GnuPG keyid: 91C1262F01EB8D39
gpgv -v --keyring $KEYRING $TARFILE.sig $TARFILE
tar xzf $TARFILE

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
