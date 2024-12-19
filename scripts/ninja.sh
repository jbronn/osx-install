#!/usr/bin/env bash
set -euxo pipefail

INSTALL="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/.. && pwd )"
NAME=ninja
IDENTIFIER="org.ninja-build.pkg.${NAME}"
VERSION=1.12.1
VERNAME=$NAME-$VERSION
CHKSUM=821bdff48a3f683bc4bb3b6f0b5fe7b2d647cf65d52aeb63328c91a6c6df285a
TARFILE=v$VERSION.tar.gz
URL=https://github.com/ninja-build/ninja/archive/refs/tags/$TARFILE

# Preparations.
BUILD=$INSTALL/build/$NAME
STAGING=$INSTALL/stage/$VERNAME
PKG=$INSTALL/pkg/$VERNAME.pkg

# Download.
mkdir -p $BUILD
cd $BUILD
if [ ! -r $TARFILE ]; then
    curl -LO $URL
fi

# Verify and extract.
rm -fr $VERNAME
echo "${CHKSUM}  ${TARFILE}" | shasum -a 256 -c -
tar xzf $TARFILE

# Compile and stage.
cd $VERNAME
python3 configure.py --bootstrap --verbose --with-python=python3

rm -fr $STAGING
mkdir -p \
      $STAGING/usr/local/bin \
      $STAGING/usr/local/etc/bash_completion.d \
      $STAGING/usr/local/share/zsh/site-functions

cp -v ninja $STAGING/usr/local/bin
cp -v misc/bash-completion $STAGING/usr/local/etc/bash_completion.d/ninja-completion.sh
cp -v misc/zsh-completion $STAGING/usr/local/share/zsh/site-functions/_ninja

# Package.
rm -f $PKG $INSTALL/pkg/$NAME.pkg
pkgbuild --root $STAGING --identifier "${IDENTIFIER}" --version $VERSION $PKG
ln -s $PKG $INSTALL/pkg/$NAME.pkg
