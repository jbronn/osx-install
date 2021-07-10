#!/bin/bash
set -euxo pipefail

INSTALL="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/.. && pwd )"
NAME=putty
IDENTIFIER="org.gnu.pkg.${NAME}"
VERSION=0.75
VERNAME=$NAME-$VERSION
CHKSUM=d3173b037eddbe9349abe978101277b4ba9f9959e25dedd44f87e7b85cc8f9f5
TARFILE=$VERNAME.tar.gz
URL=https://the.earth.li/~sgtatham/putty/latest/$TARFILE

# Preparations.
BUILD=$INSTALL/build/$NAME
KEYRING=$INSTALL/keyring/$NAME.gpg
STAGING=$INSTALL/stage/$VERNAME
PKG=$INSTALL/pkg/$VERNAME.pkg

# Download.
mkdir -p $BUILD
cd $BUILD
if [ ! -r $TARFILE ]; then
    curl -LO $URL
fi
if [ ! -r $TARFILE.gpg ]; then
    curl -LO $URL.gpg
fi

# Verify and extract.
test -x /usr/local/bin/gpgv || (echo "GnuPG required for verification" && exit 1)
rm -fr $VERNAME
echo "${CHKSUM}  ${TARFILE}" | shasum -a 256 -c -
# PuTTY Releases <putty@projects.tartarus.org>, GnuPG keyid: 6289A25F4AE8DA82
gpgv -v --keyring $KEYRING $TARFILE.gpg $TARFILE
tar xzf $TARFILE
