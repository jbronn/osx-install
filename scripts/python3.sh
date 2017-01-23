#!/bin/bash
set -ex

INSTALL="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/.. && pwd )"
NAME=Python
IDENTIFIER="org.python.pkg.python3"
VERSION=3.5.3
VERNAME=$NAME-$VERSION
CHKSUM=d8890b84d773cd7059e597dbefa510340de8336ec9b9e9032bf030f19291565a
TARFILE=$VERNAME.tgz
URL=https://www.python.org/ftp/python/$VERSION/$TARFILE

# Larry Hastings <larry@hastings.org>
KEYID=3A5CA953F73C700D

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
    
    rm -fr $STAGING
    make install DESTDIR=$STAGING PYTHONAPPSDIR=/usr/local
    rm -fr $STAGING/usr/local/*.app
    rm -fr $STAGING/usr/local/bin/2to3*

    # Link in the pkg-config files.
    mkdir -p $STAGING/usr/local/lib/pkgconfig
    ln -s /Library/Frameworks/Python.framework/Versions/3.5/lib/pkgconfig/python-3.5.pc $STAGING/usr/local/lib/pkgconfig
    ln -s /Library/Frameworks/Python.framework/Versions/3.5/lib/pkgconfig/python3.pc $STAGING/usr/local/lib/pkgconfig

    pkgbuild --root $STAGING --identifier "${IDENTIFIER}" --version $VERSION $PKG
fi
