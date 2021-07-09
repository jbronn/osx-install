#!/bin/bash
set -euxo pipefail

INSTALL="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/.. && pwd )"
NAME=openssl
IDENTIFIER="org.openssl.pkg.${NAME}"
VERSION=1.1.1k
VERNAME=$NAME-$VERSION
CHKSUM=892a0875b9872acd04a9fde79b1f943075d5ea162415de3047c327df33fbaee5
TARFILE=$VERNAME.tar.gz
URL=https://www.openssl.org/source/$TARFILE

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
if [ ! -r $TARFILE.asc ]; then
    curl -LO $URL.asc
fi

# Verify and extract.
test -x /usr/local/bin/gpgv || (echo "GnuPG required for verification" && exit 1)
rm -fr $VERNAME
echo "${CHKSUM}  ${TARFILE}" | shasum -a 256 -c -
# Matt Caswell <matt@openssl.org>, GnuPG keyid: D9C4D26D0E604491
gpgv -v --keyring $KEYRING $TARFILE.asc $TARFILE
tar xzf $TARFILE

# Configure
OPENSSL_CONFIG_DIR=/usr/local/etc/ssl
OPENSSL_TRUST_STORE=${OPENSSL_CONFIG_DIR}/cert.pem
cd $VERNAME
perl ./Configure \
  --prefix=/usr/local \
  --openssldir=${OPENSSL_CONFIG_DIR} \
  no-ssl3 \
  no-ssl3-method \
  no-zlib \
  darwin64-x86_64-cc \
  enable-ec_nistp_64_gcc_128

# Compile and stage.
make
rm -fr $STAGING
make install DESTDIR=$STAGING MANDIR=/usr/local/share/man MANSUFFIX=ssl
make test
# Ensure empty file for system CA certificates so it can introspected.
touch ${STAGING}${OPENSSL_TRUST_STORE}
# Script to create certfile from system keychains.
mkdir -p $BUILD/scripts
cat <<EOF > $BUILD/scripts/postinstall
#!/bin/bash
set -euo pipefail

/usr/bin/security find-certificate -a -p \
/Library/Keychains/System.keychain \
/System/Library/Keychains/SystemRootCertificates.keychain > \
${OPENSSL_TRUST_STORE}
EOF
chmod +x $BUILD/scripts/postinstall

# Package.
rm -f $PKG $INSTALL/pkg/$NAME.pkg
pkgbuild --root $STAGING --scripts $BUILD/scripts --identifier "${IDENTIFIER}" --version $VERSION $PKG
ln -s $PKG $INSTALL/pkg/$NAME.pkg
