#!/bin/bash
set -ex

INSTALL="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/.. && pwd )"
NAME=emacs
VERSION=25.1
VERNAME=$NAME-$VERSION
CHKSUM=763344b90db4d40e9fe90c5d14748a9dbd201ce544e2cf0835ab48a0aa4a1c67
TARFILE=$VERNAME.tar.gz
URL=https://ftp.gnu.org/gnu/emacs/$TARFILE

# Nicolas Petton <nicolas@petton.fr>
KEYID=233587A47C207910

# Preparations.
BUILD=$INSTALL/build/$NAME
PKGDIR=$INSTALL/pkg/$NAME/$VERSION

# Download.
mkdir -p $BUILD $PKGDIR
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
    ./configure --prefix=/usr/local --with-xml2 --with-ns
fi

# Move application bundle (this isn't an installable that requires root).
if [ ! -d $PKGDIR/Emacs.app ]; then
    make install
    cp -v $BUILD/site-lisp/*.el nextstep/Emacs.app/Contents/Resources/site-lisp
    mv -v nextstep/Emacs.app $PKGDIR
fi 
