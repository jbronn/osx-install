#!/bin/bash
set -euxo pipefail

INSTALL="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/.. && pwd )"
NAME=bash
IDENTIFIER="org.gnu.pkg.${NAME}"
VERSION=5.2
VERNAME=$NAME-$VERSION
CHKSUM=a139c166df7ff4471c5e0733051642ee5556c1cc8a4a78f145583c5c81ab32fb
TARFILE=$VERNAME.tar.gz
URL=https://ftp.gnu.org/gnu/bash/$TARFILE

COMPACTVERSION=$(echo $VERSION | tr -d .)
PATCHURL=https://ftp.gnu.org/gnu/bash/$VERNAME-patches
PATCHVERSION=37

# Preparations.
BUILD=$INSTALL/build/$NAME
KEYRING=$INSTALL/keyring/$NAME.gpg
STAGING=$INSTALL/stage/$VERNAME-$PATCHVERSION
PKGDIR=$INSTALL/pkg
PKG=$PKGDIR/$VERNAME-$PATCHVERSION.pkg

# Download.
mkdir -p $BUILD
cd $BUILD
if [ ! -r $TARFILE ]; then
    curl -LO $URL
fi

if [ ! -r $TARFILE.sig ]; then
    curl -LO $URL.sig
fi

# Verify and extract.
test -x /usr/local/bin/gpgv || (echo "GnuPG required for verification" && exit 1)
rm -fr $VERNAME
echo "${CHKSUM}  ${TARFILE}" | shasum -a 256 -c -
# Chet Ramey <chet@cwru.edu>, GnuPG key id: BB5869F064EA74AB
gpgv -v --keyring $KEYRING $TARFILE.sig $TARFILE
tar xzf $TARFILE

# Download, verify, and apply the patches.
PATCHNUMS=$(expr ${PATCHVERSION} + 1)
PATCHINDEX=1
until [ "${PATCHINDEX}" = "${PATCHNUMS}" ]; do
    PATCHFILE="${NAME}${COMPACTVERSION}-$(printf '%03d' ${PATCHINDEX})"
    if [ ! -r $PATCHFILE ]; then
        curl -O $PATCHURL/$PATCHFILE
    fi

    if [ ! -r $PATCHFILE.sig ]; then
        curl -O $PATCHURL/$PATCHFILE.sig
    fi

    gpgv -v --keyring $KEYRING $PATCHFILE.sig $PATCHFILE
    patch -d $VERNAME -p0 <$PATCHFILE

    PATCHINDEX=$(expr ${PATCHINDEX} + 1)
done

# Configure and compile.
cd $VERNAME
CFLAGS="-DSSH_SOURCE_BASHRC" \
LDFLAGS="-Wl,-rpath,@loader_path/../lib/bash" \
./configure --prefix=/usr/local
make clean
make
make check

# Stage
rm -fr $STAGING
make install DESTDIR=$STAGING
#mkdir -p $STAGING/usr/local/lib/pkgconfig
#cp -v $BUILD/$VERNAME/readline.pc $STAGING/usr/local/lib/pkgconfig
#sed -i -e 's/^Requires.private: termcap//' $STAGING/usr/local/lib/pkgconfig/readline.pc

# Package
rm -f $PKG $INSTALL/pkg/$NAME.pkg
pkgbuild --root $STAGING --identifier "$IDENTIFIER" --version $VERSION-$PATCHVERSION $PKG
ln -s $PKG $INSTALL/pkg/$NAME.pkg
