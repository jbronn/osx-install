#!/bin/bash
set -ex

INSTALL="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/.. && pwd )"
NAME=graphviz
IDENTIFIER="org.graphviz.pkg.graphviz"
VERSION=2.38.0
VERNAME=$NAME-$VERSION
CHKSUM=81aa238d9d4a010afa73a9d2a704fc3221c731e1e06577c2ab3496bdef67859e
TARFILE=$VERNAME.tar.gz
URL=http://graphviz.org/pub/graphviz/stable/SOURCES/$TARFILE

# Preparations.
BUILD=$INSTALL/build/$NAME
STAGING=$INSTALL/stage/$VERNAME
PKG=$INSTALL/pkg/$VERNAME.pkg

mkdir -p $BUILD

cd $BUILD
if [ ! -r $TARFILE ]; then
    curl -O $URL
fi

# Extract
if [ ! -d $VERNAME ]; then
    echo "${CHKSUM}  ${TARFILE}" | shasum -a 256 -c -
    tar xzf $TARFILE
fi

# Create post-install script.
if [ ! -r $BUILD/scripts/postinstall ]; then
    mkdir -p $BUILD/scripts
    cat <<EOF > $BUILD/scripts/postinstall
#!/bin/bash
/usr/local/bin/dot -c
EOF
    chmod +x $BUILD/scripts/postinstall
fi


# Configure.
cd $VERNAME
if [ ! -r Makefile ]; then
    ./configure \
        --disable-debug \
        --disable-dependency-tracking \
        --prefix=/usr/local \
        --disable-swig \
        --disable-tcl \
        --without-pangocairo \
        --without-freetype2 \
        --without-rsvg \
        --without-qt \
        --with-quartz
fi

# Package.
if [ ! -r $PKG ]; then
    make clean
    make
    rm -fr $STAGING
    make install DESTDIR=$STAGING
    rm $STAGING/usr/local/bin/gvmap.sh
    pkgbuild --root $STAGING --scripts $BUILD/scripts --identifier "${IDENTIFIER}" --version $VERSION $PKG
fi
