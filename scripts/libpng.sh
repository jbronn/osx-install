#!/bin/bash
set -ex

INSTALL="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/.. && pwd )"
NAME=libpng
IDENTIFIER="org.libpng.pkg.libpng"
VERSION=1.6.28
VERNAME=$NAME-$VERSION
CHKSUM=b6cec903e74e9fdd7b5bbcde0ab2415dd12f2f9e84d9e4d9ddd2ba26a41623b2
TARFILE=$VERNAME.tar.gz
URL=ftp://ftp.simplesystems.org/pub/libpng/png/src/libpng16/$TARFILE

# Glenn Randers-Pehrson (libpng) <glennrp@users.sourceforge.net>
KEYID=8048643BA2C840F4F92A195FF54984BFA16C640F

# Preparations.
BUILD=$INSTALL/build/$NAME
STAGING=$INSTALL/stage/$VERNAME
PKG=$INSTALL/pkg/$VERNAME.pkg

# Download.
mkdir -p $BUILD
cd $BUILD
if [ ! -r $TARFILE ]; then
    curl -O $URL
fi

if [ ! -r $TARFILE.asc ]; then
    curl -O $URL.asc
fi


# Verify and extract.
test -x /usr/local/bin/gpg || (echo "GnuPG required for verification" && exit 1)

if [ ! -d $VERNAME ]; then
    gpg --list-keys $KEYID || gpg --keyserver keys.gnupg.net --recv-keys $KEYID
    gpg --verify $TARFILE.asc || (echo "Can't verify tarball." && exit 1)
    
    echo "${CHKSUM}  ${TARFILE}" | shasum -a 256 -c -
    tar xzf $TARFILE
fi

# Configure.
cd $VERNAME
if [ ! -r Makefile ]; then
    ./configure \
        --disable-dependency-tracking \
        --disable-silent-rules \
        --prefix=/usr/local
fi

# Package.
if [ ! -r $PKG ]; then
    make clean
    make
    make test
    rm -fr $STAGING
    make install DESTDIR=$STAGING
    pkgbuild --root $STAGING --identifier "${IDENTIFIER}" --version $VERSION $PKG
fi
