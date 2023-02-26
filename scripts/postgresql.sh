#!/bin/bash
set -euxo pipefail

INSTALL="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/.. && pwd )"
NAME=postgresql
IDENTIFIER="org.postgresql.pkg.postgresql"
VERSION=15.2
VERNAME=$NAME-$VERSION
CHKSUM=99a2171fc3d6b5b5f56b757a7a3cb85d509a38e4273805def23941ed2b8468c7
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
