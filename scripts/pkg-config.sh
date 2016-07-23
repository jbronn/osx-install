#!/bin/bash
set -ex

INSTALL="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/.. && pwd )"
NAME=pkg-config
IDENTIFIER="org.freedesktop.pkg.pkg-config"
VERSION=0.29.1
VERNAME=$NAME-$VERSION
CHKSUM=beb43c9e064555469bd4390dcfd8030b1536e0aa103f08d7abf7ae8cac0cb001
TARFILE=$VERNAME.tar.gz
URL=https://pkgconfig.freedesktop.org/releases/$TARFILE

# Dan Nicholson <nicholson.db@gmail.com>
KEYID=023A4420C7EC6914

# Preparations.
BUILD=$INSTALL/build/$NAME
STAGING=$INSTALL/stage/$VERNAME
PKG=$INSTALL/pkg/$VERNAME.pkg

mkdir -p $BUILD

cd $BUILD
if [ ! -r $TARFILE ]; then
    curl -O $URL
fi

if [ ! -r $TARFILE.asc ]; then
    curl -O $URL.asc
fi

# Verify checksum and extract.
if [ ! -d $VERNAME ]; then
    gpg --list-keys $KEYID || gpg --keyserver keys.gnupg.net --recv-keys $KEYID
    gpg --verify $TARFILE.asc || (echo "Can't verify tarball." && exit 1)
    
    echo "${CHKSUM}  ${TARFILE}" | shasum -a 256 -c -
    tar xzf $TARFILE
fi

# Configure.
cd $VERNAME
if [ ! -r Makefile ]; then
    LDFLAGS="-framework Foundation -framework Cocoa" \
    ./configure \
	--disable-debug \
	--prefix=/usr/local \
	--disable-host-tool \
	--with-internal-glib \
	--with-pc-path=/usr/local/lib/pkgconfig:/usr/local/share/pkgconfig:/usr/local/lib/pkgconfig:/usr/lib/pkgconfig
fi

# Package.
if [ ! -r $PKG ]; then
    make clean
    make
    make check

    rm -fr $STAGING
    make install DESTDIR=$STAGING

    pkgbuild --root $STAGING --identifier "${IDENTIFIER}" --version $VERSION $PKG
fi
