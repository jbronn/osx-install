#!/bin/bash
set -ex

INSTALL="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/.. && pwd )"
NAME=sqlite3
IDENTIFIER="org.sqlite.pkg.sqlite3"
VERSION=3.47.1
VERNUM=3470100
VERNAME=sqlite-src-$VERNUM
CHKSUM=416a6f45bf2cacd494b208fdee1beda509abda951d5f47bc4f2792126f01b452
SRCZIPFILE=$VERNAME.zip
SRCCHKSUM=572457f02b03fea226a6cde5aafd55a0a6737786bcb29e3b85bfb21918b52ce7
TARFILE=sqlite-autoconf-$VERNUM.tar.gz
URL=https://sqlite.org/2024/$TARFILE
SRCURL=https://sqlite.org/2024/$SRCZIPFILE

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
        --disable-dependency-tracking \
        --disable-static \
        --enable-all \
        --enable-dynamic-extensions \
        --enable-fts4 \
        --enable-fts5 \
        --enable-readline \
        --enable-releasemode \
        --enable-session \
        --enable-threadsafe \
        --enable-threads-override-locks

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
