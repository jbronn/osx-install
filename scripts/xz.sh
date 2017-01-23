#!/bin/bash
set -ex

INSTALL="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/.. && pwd )"
NAME=xz
IDENTIFIER="org.tukaani.pkg.xz"
VERSION=5.2.3
VERNAME=$NAME-$VERSION
CHKSUM=71928b357d0a09a12a4b4c5fafca8c31c19b0e7d3b8ebb19622e96f26dbf28cb
TARFILE=$VERNAME.tar.gz
URL=http://tukaani.org/xz/$TARFILE

# Lasse Collin <lasse.collin@tukaani.org>
KEYID=38EE757D69184620

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

if [ ! -r $TARFILE.sig ]; then
    curl -O $URL.sig
fi


# Verify and extract.
test -x /usr/local/bin/gpg || (echo "GnuPG required for verification" && exit 1)

if [ ! -d $VERNAME ]; then
    gpg --list-keys $KEYID || gpg --keyserver keys.gnupg.net --recv-keys $KEYID
    gpg --verify $TARFILE.sig || (echo "Can't verify tarball." && exit 1)

    echo "${CHKSUM}  ${TARFILE}" | shasum -a 256 -c -
    tar xzf $TARFILE
fi


# Configure.
cd $VERNAME
if [ ! -r Makefile ]; then
    ./configure \
        --disable-debug \
        --disable-dependency-tracking \
        --disable-silent-rules \
        --prefix=/usr/local
fi

# Package.
if [ ! -r $PKG ]; then
    make clean
    make
    rm -fr $STAGING
    make install DESTDIR=$STAGING
    pkgbuild --root $STAGING --identifier "${IDENTIFIER}" --version $VERSION $PKG
fi