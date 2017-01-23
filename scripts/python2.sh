#!/bin/bash
set -ex

INSTALL="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/.. && pwd )"
NAME=Python
IDENTIFIER="org.python.pkg.python2"
VERSION=2.7.13
VERNAME=$NAME-$VERSION
CHKSUM=a4f05a0720ce0fd92626f0278b6b433eee9a6173ddf2bced7957dfb599a5ece1
TARFILE=$VERNAME.tgz
URL=https://www.python.org/ftp/python/$VERSION/$TARFILE

# "Benjamin Peterson <bp@benjamin.pe>"
KEYID=04C367C218ADD4FF

# Preparations.
BUILD=$INSTALL/build/$NAME
STAGING=$INSTALL/stage/$VERNAME
PKG=$INSTALL/pkg/$VERNAME.pkg

# Download
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
        --enable-framework
fi

# Package.
if [ ! -r $PKG ]; then
    #make clean
    #make
    #make quicktest

    rm -fr $STAGING
    make install DESTDIR=$STAGING PYTHONAPPSDIR=/usr/local
    rm -fr $STAGING/usr/local/*.app

    # Link in the pkg-config files.
    mkdir -p $STAGING/usr/local/lib/pkgconfig
    ln -s /Library/Frameworks/Python.framework/Versions/2.7/lib/pkgconfig/python-2.7.pc $STAGING/usr/local/lib/pkgconfig
    ln -s /Library/Frameworks/Python.framework/Versions/2.7/lib/pkgconfig/python2.pc $STAGING/usr/local/lib/pkgconfig
    ln -s /Library/Frameworks/Python.framework/Versions/2.7/lib/pkgconfig/python.pc $STAGING/usr/local/lib/pkgconfig

    pkgbuild --root $STAGING --identifier "${IDENTIFIER}" --version $VERSION $PKG
fi
