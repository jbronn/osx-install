#!/bin/bash
set -ex

INSTALL="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/.. && pwd )"
NAME=sqlite3
IDENTIFIER="org.sqlite.pkg.sqlite3"
VERSION=3.50.4
VERNUM=3500400
VERNAME=sqlite-src-$VERNUM
CHKSUM=a3db587a1b92ee5ddac2f66b3edb41b26f9c867275782d46c3a088977d6a5b18
SRCZIPFILE=$VERNAME.zip
SRCCHKSUM=b7b4dc060f36053902fb65b344bbbed592e64b2291a26ac06fe77eec097850e9
TARFILE=sqlite-autoconf-$VERNUM.tar.gz
URL=https://sqlite.org/2025/$TARFILE
SRCURL=https://sqlite.org/2025/$SRCZIPFILE

# Preparations.
BUILD=$INSTALL/build/$NAME
STAGING=$INSTALL/stage/$VERNAME
PKG=$INSTALL/pkg/$NAME-$VERSION.pkg

# Download.
mkdir -p $BUILD
cd $BUILD
if [ ! -r $TARFILE ]; then
    curl -LO $URL
fi

if [ ! -r $SRCZIPFILE ]; then
    curl -LO $SRCURL
fi

# Extract
rm -fr $VERNAME
echo "${CHKSUM}  ${TARFILE}" | shasum -a 256 -c -
echo "${SRCCHKSUM}  ${SRCZIPFILE}" | shasum -a 256 -c -
unzip $SRCZIPFILE
cd $VERNAME
tar xzf ../$TARFILE

# Configure.
CFLAGS="-DSQLITE_ENABLE_API_ARMOR -DSQLITE_ENABLE_COLUMN_METADATA -DSQLITE_ENABLE_DBSTAT_VTAB -DSQLITE_ENABLE_FTS3 -DSQLITE_ENABLE_FTS3_PARENTHESIS -DSQLITE_ENABLE_GEOPOLY -DSQLITE_ENABLE_MATH_FUNCTIONS -DSQLITE_ENABLE_JSON1 -DSQLITE_ENABLE_PREUPDATE_HOOK -DSQLITE_ENABLE_MEMORY_MANAGEMENT -DSQLITE_ENABLE_RTREE -DSQLITE_ENABLE_STAT4 -DSQLITE_ENABLE_UNLOCK_NOTIFY -DSQLITE_DISABLE_DIRSYNC -DSQLITE_LIKE_DOESNT_MATCH_BLOBS -DSQLITE_MAX_VARIABLE_NUMBER=250000 -DSQLITE_SECURE_DELETE -DSQLITE_USE_URI" \
        ./configure \
        --prefix=/usr/local \
        --disable-editline \
        --enable-load-extension \
        --enable-readline \
        --enable-session \
        --enable-threadsafe

# Compile and stage.
make clean
make
make srctree-check fuzztest sourcetest
rm -fr $STAGING
make install DESTDIR=$STAGING

# Package.
rm -f $PKG $INSTALL/pkg/$NAME.pkg
pkgbuild --root $STAGING --identifier "${IDENTIFIER}" --version $VERSION $PKG
ln -s $PKG $INSTALL/pkg/$NAME.pkg
