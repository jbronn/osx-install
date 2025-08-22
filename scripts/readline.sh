#!/bin/bash
set -euxo pipefail

INSTALL="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/.. && pwd )"
NAME=readline
IDENTIFIER="org.gnu.pkg.${NAME}"
VERSION=8.3
VERNAME=$NAME-$VERSION
CHKSUM=fe5383204467828cd495ee8d1d3c037a7eba1389c22bc6a041f627976f9061cc
TARFILE=$VERNAME.tar.gz
URL=https://ftp.gnu.org/gnu/readline/$TARFILE

COMPACTVERSION=$(echo $VERSION | tr -d .)
PATCHURL=https://ftp.gnu.org/gnu/readline/$VERNAME-patches
PATCHVERSION=1

# Preparations.
BUILD=$INSTALL/build/$NAME
KEYRING=$INSTALL/keyring/gnu.gpg
STAGING=$INSTALL/stage/$VERNAME-$PATCHVERSION
PKGDIR=$INSTALL/pkg
PKG=$PKGDIR/$VERNAME-$PATCHVERSION.pkg

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
    # Chet Ramey <chet@cwru.edu>, GnuPG key id: BB5869F064EA74AB
    gpgv -v --keyring $KEYRING $TARFILE.sig $TARFILE
fi
tar xzf $TARFILE

# Download, verify, and apply the patches.
PATCHNUMS=$(expr ${PATCHVERSION} + 1)
PATCHINDEX=1
until [ "${PATCHINDEX}" = "${PATCHNUMS}" ]; do
    PATCHFILE="${NAME}${COMPACTVERSION}-$(printf '%03d' ${PATCHINDEX})"
    if [ ! -r $PATCHFILE ]; then
        curl -O $PATCHURL/$PATCHFILE
    fi

    if [ ! -r $PATCHFILE.sig ]; then
        curl -O $PATCHURL/$PATCHFILE.sig
    fi

    gpgv -v --keyring $KEYRING $PATCHFILE.sig $PATCHFILE
    patch -d $VERNAME -p0 <$PATCHFILE

    PATCHINDEX=$(expr ${PATCHINDEX} + 1)
done

# Configure and compile.
cd $VERNAME
./configure \
    --prefix=/usr/local \
    --disable-static \
    --enable-multibyte
make clean
make

# Stage
rm -fr $STAGING
make install DESTDIR=$STAGING
mkdir -p $STAGING/usr/local/lib/pkgconfig
cp -v $BUILD/$VERNAME/readline.pc $STAGING/usr/local/lib/pkgconfig
sed -i -e 's/^Requires.private: termcap//' $STAGING/usr/local/lib/pkgconfig/readline.pc
rmdir $STAGING/usr/local/bin

# Package
rm -f $PKG $INSTALL/pkg/$NAME.pkg
pkgbuild --root $STAGING --identifier "$IDENTIFIER" --version $VERSION-$PATCHVERSION $PKG
ln -s $PKG $INSTALL/pkg/$NAME.pkg
