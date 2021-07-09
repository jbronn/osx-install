#!/bin/bash
set -euxo pipefail

INSTALL="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/.. && pwd )"
NAME=readline
IDENTIFIER="org.gnu.pkg.${NAME}"
VERSION=8.1
VERNAME=$NAME-$VERSION
CHKSUM=f8ceb4ee131e3232226a17f51b164afc46cd0b9e6cef344be87c65962cb82b02
TARFILE=$VERNAME.tar.gz
URL=https://ftp.gnu.org/gnu/readline/$TARFILE

COMPACTVERSION=$(echo $VERSION | tr -d .)
PATCHURL=https://ftp.gnu.org/gnu/readline/$VERNAME-patches
PATCHVERSION=1

# Preparations.
BUILD=$INSTALL/build/$NAME
KEYRING=$INSTALL/keyring/$NAME.gpg
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
test -x /usr/local/bin/gpgv || (echo "GnuPG required for verification" && exit 1)
rm -fr $VERNAME
echo "${CHKSUM}  ${TARFILE}" | shasum -a 256 -c -
# Chet Ramey <chet@cwru.edu>, GnuPG key id: BB5869F064EA74AB
gpgv -v --keyring $KEYRING $TARFILE.sig $TARFILE
tar xzf $TARFILE

# Download, verify, and apply the patches.
PATCHNUMS=$(/usr/bin/python -c "print(' '.join([str(i).zfill(3) for i in range(1,$PATCHVERSION+1)]))")
for i in $PATCHNUMS; do
    PATCHFILE="${NAME}${COMPACTVERSION}-${i}"
    if [ ! -r $PATCHFILE ]; then
        curl -O $PATCHURL/$PATCHFILE
    fi

    if [ ! -r $PATCHFILE.sig ]; then
        curl -O $PATCHURL/$PATCHFILE.sig
    fi

    gpgv -v --keyring $KEYRING $PATCHFILE.sig $PATCHFILE
    patch -d $VERNAME -p0 <$PATCHFILE
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
