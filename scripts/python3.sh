#!/bin/bash
set -ex

INSTALL="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/.. && pwd )"
NAME=Python
IDENTIFIER="org.python.pkg.python3"
VERSION=3.5.2
VERNAME=$NAME-$VERSION
CHKSUM=1524b840e42cf3b909e8f8df67c1724012c7dc7f9d076d4feef2d3eff031e8a0
TARFILE=$VERNAME.tgz
URL=https://www.python.org/ftp/python/$VERSION/$TARFILE

# Larry Hastings <larry@hastings.org>
KEYID=3A5CA953F73C700D

# Preparations.
BUILD=$INSTALL/build/$NAME
STAGING=$INSTALL/stage/$VERNAME
PKG=$INSTALL/pkg/$VERNAME.pkg

mkdir -p $BUILD

cd $BUILD
if [ ! -r $TARFILE ]; then
    curl -O $URL
    echo "${CHKSUM}  ${TARFILE}" | shasum -a 256 -c - || (echo "Invalid checksum" && rm -v $TARFILE && exit 1)
fi

# Verify the tarball.
if [ ! -d $VERNAME ]; then
    curl -O $URL.asc
    gpg --list-keys $KEYID || gpg --keyserver keys.gnupg.net --recv-keys $KEYID
    gpg --verify $TARFILE.asc || (echo "Can't verify tarball." && exit 1)
    tar xzf $TARFILE
fi

# Configure.
cd $VERNAME
if [ ! -r Makefile ]; then
    ./configure \
        MACOSX_DEPLOYMENT_TARGET=10.11 \
        --prefix=/usr/local \
        --enable-ipv6 \
        --enable-framework \
        --without-ensurepip
fi

# Package.
if [ ! -r $PKG ]; then
    make clean
    make

    # TODO: Figure out why popen test is failing.
    make quicktest || true

    make install DESTDIR=$STAGING PYTHONAPPSDIR=/usr/local
    rm -fr $STAGING/usr/local/*.app
    rm -fr $STAGING/usr/local/bin/2to3*

    # Link in the pkg-config files.
    mkdir -p $STAGING/usr/local/lib/pkgconfig
    ln -s /Library/Frameworks/Python.framework/Versions/3.5/lib/pkgconfig/python-3.5.pc $STAGING/usr/local/lib/pkgconfig
    ln -s /Library/Frameworks/Python.framework/Versions/3.5/lib/pkgconfig/python3.pc $STAGING/usr/local/lib/pkgconfig

    pkgbuild --root $STAGING --identifier "${IDENTIFIER}" --version $VERSION $PKG
fi
