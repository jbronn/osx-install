#!/bin/bash
set -ex

INSTALL="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/.. && pwd )"
NAME=Python
IDENTIFIER="org.python.pkg.python2"
VERSION=2.7.12
VERNAME=$NAME-$VERSION
CHKSUM=3cb522d17463dfa69a155ab18cffa399b358c966c0363d6c8b5b3bf1384da4b6
TARFILE=$VERNAME.tgz
URL=https://www.python.org/ftp/python/$VERSION/$TARFILE

# "Benjamin Peterson <bp@benjamin.pe>"
KEYID=04C367C218ADD4FF

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
        --enable-framework
fi

# Package.
if [ ! -r $PKG ]; then
    make clean
    make
    make quicktest
    make install DESTDIR=$STAGING PYTHONAPPSDIR=/usr/local
    rm -fr $STAGING/usr/local/*.app

    # Link in the pkg-config files.
    mkdir -p $STAGING/usr/local/lib/pkgconfig
    ln -s /Library/Frameworks/Python.framework/Versions/2.7/lib/pkgconfig/python-2.7.pc $STAGING/usr/local/lib/pkgconfig
    ln -s /Library/Frameworks/Python.framework/Versions/2.7/lib/pkgconfig/python2.pc $STAGING/usr/local/lib/pkgconfig
    ln -s /Library/Frameworks/Python.framework/Versions/2.7/lib/pkgconfig/python.pc $STAGING/usr/local/lib/pkgconfig
    
    pkgbuild --root $STAGING --identifier "${IDENTIFIER}" --version $VERSION $PKG
fi
