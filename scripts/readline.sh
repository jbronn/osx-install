#!/bin/bash
set -ex

INSTALL="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/.. && pwd )"
NAME=readline
IDENTIFIER="org.gnu.pkg.readline"
VERSION=6.3
VERNAME=$NAME-$VERSION
CHKSUM=56ba6071b9462f980c5a72ab0023893b65ba6debb4eeb475d7a563dc65cafd43
TARFILE=$VERNAME.tar.gz
URL=https://ftp.gnu.org/gnu/readline/$TARFILE

COMPACTVERSION=$(echo $VERSION | tr -d .)
PATCHURL=https://ftp.gnu.org/gnu/readline/$VERNAME-patches
PATCHVERSION=8

# Chet Ramey <chet@cwru.edu>
KEYID=BB5869F064EA74AB

# Preparations.
BUILD=$INSTALL/build/$NAME
STAGING=$INSTALL/stage/$VERNAME.$PATCHVERSION
PKGDIR=$INSTALL/pkg
PKG=$PKGDIR/$VERNAME.$PATCHVERSION.pkg

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

    if [ ! -r $PATCHFILE.patched ]; then
        gpg --verify $PATCHFILE.sig || (echo "Can't verify patch." && exit 1)
        patch -d $VERNAME -p0 <$PATCHFILE
        touch $PATCHFILE.patched
    fi
done

# Configure.
cd $VERNAME
if [ ! -r Makefile ]; then
    ./configure --prefix=/usr/local --enable-multibyte
fi

# Build, stage, and package.
if [ ! -r $PKG ]; then
    make clean
    make

    rm -fr $STAGING
    make install DESTDIR=$STAGING

    rmdir $STAGING/usr/local/bin
    pkgbuild --root $STAGING --identifier "$IDENTIFIER" --version $VERSION.$PATCHVERSION $PKG
fi
