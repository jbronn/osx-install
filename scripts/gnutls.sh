#!/bin/bash
set -euxo pipefail

INSTALL="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/.. && pwd )"
NAME=gnutls
IDENTIFIER="org.gnu.pkg.${NAME}"
VERSION=3.6.16
VERMAJ=$(echo "${VERSION}" | awk -F. '{ print $1 "." $2 }')
VERNAME=${NAME}-${VERSION}
CHKSUM=1b79b381ac283d8b054368b335c408fedcb9b7144e0c07f531e3537d4328f3b3
TARFILE=${VERNAME}.tar
URL=https://www.gnupg.org/ftp/gcrypt/gnutls/v${VERMAJ}/${TARFILE}

# Preparations.
BUILD=$INSTALL/build/$NAME
KEYRING=$INSTALL/keyring/$NAME.gpg
STAGING=$INSTALL/stage/$VERNAME
PKG=$INSTALL/pkg/$VERNAME.pkg

# Check prereqs.
test -x /usr/local/bin/gpgv || \
    (echo "GnuPG required for download verification" && exit 1)
test -x /usr/local/bin/xz || \
    (echo "xz required for extracting tarball" && exit 1)
test -r /usr/local/lib/libnettle.dylib || \
    (echo "nettle package is required" && exit 1)
test -r /usr/local/lib/libgettextlib.dylib || \
    (echo "gettext package is required" && exit 1)

# Download.
mkdir -p $BUILD
cd $BUILD
if [ ! -r $TARFILE.xz ]; then
    curl -LO $URL.xz
fi
if [ ! -r $TARFILE.xz.sig ]; then
    curl -LO $URL.xz.sig
fi

# Verify and extract.
rm -fr $VERNAME
echo "${CHKSUM}  ${TARFILE}.xz" | shasum -a 256 -c -
# Daiki Ueno <ueno@unixuser.org>, GnuPG keyid: D605848ED7E69871
gpgv -v --keyring $KEYRING $TARFILE.xz.sig $TARFILE.xz
xz --decompress --keep --force $TARFILE.xz
tar xf $TARFILE
rm -f $TARFILE

# Configure.
GNUTLS_CONFIG_DIR=/usr/local/etc/gnutls
GNUTLS_TRUST_STORE=${GNUTLS_CONFIG_DIR}/cert.pem
cd $VERNAME
patch -p0 < ../gnutls-fallthrough.patch
patch -p1 < ../gnutls-undo-libtasn1-cisdigit.patch
CFLAGS="-Wno-implicit-function-declaration" ./configure \
      --prefix=/usr/local \
      --disable-dependency-tracking \
      --disable-dtls-srtp-support \
      --disable-gost \
      --disable-heartbeat-support \
      --disable-libdane \
      --disable-non-suiteb-curves \
      --disable-openssl-compatibility \
      --disable-silent-rules \
      --disable-ssl2-support \
      --disable-static \
      --enable-shared \
      --with-default-trust-store-file=${GNUTLS_TRUST_STORE} \
      --with-included-unistring \
      --with-included-libtasn1 \
      --with-system-priority-file=${GNUTLS_CONFIG_DIR}/config \
      --without-idn \
      --without-p11-kit \
      --without-tpm

# Compile and stage.
rm -fr $STAGING
make LDFLAGS="" install DESTDIR=$STAGING
mv -v $STAGING/usr/local/bin/certtool $STAGING/usr/local/bin/gnutls-certtool
mv -v $STAGING/usr/local/share/man/man1/certtool.1 $STAGING/usr/local/share/man/man1/gnutls-certtool.1
# Ensure empty file of cert.pem so it can introspected.
mkdir -p ${STAGING}${GNUTLS_CONFIG_DIR}
touch ${STAGING}${GNUTLS_TRUST_STORE}
# Script to create certfile from system keychains.
mkdir -p $BUILD/scripts
cat <<EOF > $BUILD/scripts/postinstall
#!/bin/bash
set -euo pipefail

/usr/bin/security find-certificate -a -p \
/Library/Keychains/System.keychain \
/System/Library/Keychains/SystemRootCertificates.keychain > \
${GNUTLS_TRUST_STORE}
EOF
chmod +x $BUILD/scripts/postinstall

# Package.
rm -f $PKG $INSTALL/pkg/$NAME.pkg
pkgbuild --root $STAGING --scripts $BUILD/scripts --identifier "${IDENTIFIER}" --version $VERSION $PKG
ln -s $PKG $INSTALL/pkg/$NAME.pkg
