#!/bin/bash
set -euxo pipefail

INSTALL="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/.. && pwd )"
NAME=postgresql
IDENTIFIER="org.postgresql.pkg.postgresql"
VERSION=17.6
VERNAME=$NAME-$VERSION
CHKSUM=e0630a3600aea27511715563259ec2111cd5f4353a4b040e0be827f94cd7a8b0
TARFILE=$VERNAME.tar.bz2
URL=https://ftp.postgresql.org/pub/source/v$VERSION/$VERNAME.tar.bz2

# Preparations.
BUILD=$INSTALL/build/$NAME
STAGING=$INSTALL/stage/$VERNAME
PKG=$INSTALL/pkg/$VERNAME.pkg

# Check prereqs.
test -r /usr/local/lib/libicui18n.dylib || \
    (echo "icu4c package is required" && exit 1)
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
export MACOSX_DEPLOYMENT_TARGET=$(sw_vers | grep ^ProductVersion | awk '{ print $2 }')
./configure \
    CPPFLAGS=-I/usr/local/include \
    LDFLAGS=-L/usr/local/lib \
    PG_SYSROOT=$(xcrun --show-sdk-path) \
    --prefix=/usr/local \
    --disable-debug \
    --enable-dtrace \
    --enable-nls \
    --enable-thread-safety \
    --with-bonjour \
    --with-icu \
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
# "macOS's “System Integrity Protection” (SIP) feature breaks make check, because it prevents passing the needed
#  setting of `DYLD_LIBRARY_PATH` down to the executables being tested. You can work around that by doing
#  `make install` before `make check`. Most PostgreSQL developers just turn off SIP, though."
# make check
rm -fr $STAGING
make install-world-bin DESTDIR=$STAGING

# Package.
rm -f $PKG $INSTALL/pkg/$NAME.pkg
pkgbuild --root $STAGING --identifier "${IDENTIFIER}" --version $VERSION $PKG
ln -s $PKG $INSTALL/pkg/$NAME.pkg
