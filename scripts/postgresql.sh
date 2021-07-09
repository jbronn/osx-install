#!/bin/bash
set -euxo pipefail

INSTALL="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/.. && pwd )"
NAME=postgresql
IDENTIFIER="org.postgresql.pkg.postgresql"
VERSION=13.3
VERNAME=$NAME-$VERSION
CHKSUM=3cd9454fa8c7a6255b6743b767700925ead1b9ab0d7a0f9dcb1151010f8eb4a1
TARFILE=$VERNAME.tar.bz2
URL=https://ftp.postgresql.org/pub/source/v$VERSION/$VERNAME.tar.bz2

# Preparations.
BUILD=$INSTALL/build/$NAME
STAGING=$INSTALL/stage/$VERNAME
PKG=$INSTALL/pkg/$VERNAME.pkg

# Check prereqs.
test -r /usr/local/lib/libssl.dylib || \
    (echo "openssl package is required" && exit 1)

# Download.
mkdir -p $BUILD
cd $BUILD
if [ ! -r $TARFILE ]; then
    curl -LO $URL
fi

# Verify checksum and extract.
rm -fr $VERNAME
shasum -a 256 -c <(printf "${CHKSUM}  ${TARFILE}\n")
tar xzf $TARFILE

# Configure.
cd $VERNAME
./configure \
    CFLAGS=-I/usr/local/include \
    LDFLAGS=-L/usr/local/lib \
    MACOSX_DEPLOYMENT_TARGET=$(sw_vers | grep ^ProductVersion | awk '{ print $2 }') \
    --prefix=/usr/local \
    --disable-debug \
    --enable-dtrace \
    --enable-thread-safety \
    --with-bonjour \
    --with-gssapi \
    --with-ldap \
    --with-libxml \
    --with-libxslt \
    --with-openssl \
    --with-pam \
    --with-perl \
    --with-python \
    --with-tcl \
    --with-uuid=e2fs

# Compile and stage.
make clean
make
make check || true
rm -fr $STAGING
make install-world DESTDIR=$STAGING

# Package.
rm -f $PKG $INSTALL/pkg/$NAME.pkg
pkgbuild --root $STAGING --identifier "${IDENTIFIER}" --version $VERSION $PKG
ln -s $PKG $INSTALL/pkg/$NAME.pkg
