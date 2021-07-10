#!/bin/bash
set -euxo pipefail

INSTALL="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/.. && pwd )"
NAME=cmake
IDENTIFIER="org.gnu.pkg.${NAME}"
VERSION=3.20.5
VERNAME=$NAME-$VERSION
TARFILE=$VERNAME.tar.gz
URL=https://github.com/Kitware/CMake/releases/download/v$VERSION/$VERNAME.tar.gz
SHAURL=https://github.com/Kitware/CMake/releases/download/v$VERSION/$VERNAME-SHA-256.txt

# Preparations.
BUILD=$INSTALL/build/$NAME
KEYRING=$INSTALL/keyring/$NAME.gpg
STAGING=$INSTALL/stage/$VERNAME
PKG=$INSTALL/pkg/$VERNAME.pkg

# Check prereqs.
test -x /usr/local/bin/gpgv || (echo "GnuPG required for verification" && exit 1)

# Download.
mkdir -p $BUILD
cd $BUILD
if [ ! -r $TARFILE ]; then
    curl -LO $URL
fi
if [ ! -r $VERNAME-SHA-256.txt ]; then
    curl -LO $SHAURL
fi
if [ ! -r $VERNAME-SHA-256.txt.asc ]; then
    curl -LO $SHAURL.asc
fi

# Verify and extract.
rm -fr $VERNAME
# Brad King <brad.king@kitware.com>, GnuPG keyid: 2D2CEF1034921684.
gpgv -v --keyring $KEYRING $VERNAME-SHA-256.txt.asc $VERNAME-SHA-256.txt
shasum -c <(grep -e "${TARFILE}\$" $VERNAME-SHA-256.txt)
tar xzf $TARFILE
