#!/bin/bash
set -euxo pipefail

INSTALL="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/.. && pwd )"
NAME=gettext
IDENTIFIER="org.gnu.pkg.${NAME}"
VERSION=0.22.5
VERNAME=$NAME-$VERSION
CHKSUM=fe10c37353213d78a5b83d48af231e005c4da84db5ce88037d88355938259640
TARFILE=$VERNAME.tar.xz
URL=https://ftp.gnu.org/gnu/gettext/$TARFILE

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
    # Bruno Haible (Open Source Development) <bruno@clisp.org>, GnuPG keyid: F5BE8B267C6A406D
    gpgv -v --keyring $KEYRING $TARFILE.sig $TARFILE
fi
tar xzf $TARFILE

# Configure.
cd $VERNAME
./configure \
    --prefix=/usr/local \
    --disable-charp \
    --disable-debug \
    --disable-dependency-tracking \
    --disable-java \
    --disable-silent-rules \
    --with-emacs \
    --with-included-gettext \
    --with-included-glib \
    --with-included-libcroco \
    --with-included-libunistring \
    --with-included-libxml \
    --without-cvs \
    --without-git \
    --without-xz

# Compile and stage.
make clean
make
#make check || true
rm -fr $STAGING
make install DESTDIR=$STAGING

# Package.
rm -f $PKG $INSTALL/pkg/$NAME.pkg
pkgbuild --root $STAGING --identifier "${IDENTIFIER}" --version $VERSION $PKG
ln -s $PKG $INSTALL/pkg/$NAME.pkg
