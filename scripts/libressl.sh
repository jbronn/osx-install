#!/bin/bash
set -ex

INSTALL="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/.. && pwd )"
NAME=libressl
IDENTIFIER="org.openbsd.pkg.libressl"
VERSION=2.4.4
VERNAME=$NAME-$VERSION
CHKSUM=6fcfaf6934733ea1dcb2f6a4d459d9600e2f488793e51c2daf49b70518eebfd1
TARFILE=$VERNAME.tar.gz
URL=https://ftp.openbsd.org/pub/OpenBSD/LibreSSL/$TARFILE

# Brent Cook <bcook@openbsd.org>
KEYID=663AF51BD5E4D8D5

# Preparations.
BUILD=$INSTALL/build/$NAME
STAGING=$INSTALL/stage/$VERNAME
PKG=$INSTALL/pkg/$VERNAME.pkg

mkdir -p $BUILD
cd $BUILD
if [ ! -r $TARFILE ]; then
    curl -O $URL
fi

if [ ! -r $TARFILE.asc ]; then
    curl -O $URL.asc
fi


# Verify and extract.
test -x /usr/local/bin/gpg || (echo "GnuPG required for verification" && exit 1)

if [ ! -d $VERNAME ]; then
    gpg --list-keys $KEYID || gpg --keyserver keys.gnupg.net --recv-keys $KEYID
    gpg --verify $TARFILE.asc || (echo "Can't verify tarball." && exit 1)
    
    echo "${CHKSUM}  ${TARFILE}" | shasum -a 256 -c -
    tar xzf $TARFILE
fi

# Create post-install script.
if [ ! -r $BUILD/scripts/postinstall ]; then
    mkdir -p $BUILD/scripts
    cat <<EOF > $BUILD/scripts/postinstall
#!/usr/bin/ruby

keychains = %w[
  /System/Library/Keychains/SystemRootCertificates.keychain
]

certs_list = \`security find-certificate -a -p #{keychains.join(" ")}\`
certs = certs_list.scan(
  /-----BEGIN CERTIFICATE-----.*?-----END CERTIFICATE-----/m
)

valid_certs = certs.select do |cert|
  IO.popen("/usr/local/bin/openssl x509 -inform pem -checkend 0 -noout", "w") do |openssl_io|
    openssl_io.write(cert)
    openssl_io.close_write
  end

  \$?.success?
end

f = File.new("/usr/local/etc/libressl/cert.pem", "w")
f.write(valid_certs.join("\n"))
f.close
EOF
    chmod +x $BUILD/scripts/postinstall
fi


# Configure.
cd $VERNAME
if [ ! -r Makefile ]; then
    ./configure \
        MACOSX_DEPLOYMENT_TARGET=10.11 \
        --prefix=/usr/local \
        --disable-dependency-tracking \
        --disable-silent-rules \
        --with-openssldir=/usr/local/etc/libressl \
        --sysconfdir=/usr/local/etc/libressl
fi

# Package.
if [ ! -r $PKG ]; then
    make clean
    make
    make check

    rm -fr $STAGING
    make install DESTDIR=$STAGING

    # Remove LibreSSL's default certificate store so it can be auto-generated from what comes with OS X.
    rm -f $STAGING/usr/local/etc/libressl/cert.pem
    
    pkgbuild --root $STAGING --scripts $BUILD/scripts --identifier "${IDENTIFIER}" --version $VERSION $PKG
fi
