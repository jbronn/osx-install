#!/bin/bash
set -ex

INSTALL="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/.. && pwd )"
NAME=openssl
IDENTIFIER="org.openssl.pkg.openssl"
VERSION=1.0.2h
VERNAME=$NAME-$VERSION
CHKSUM=1d4007e53aad94a5b2002fe045ee7bb0b3d98f1a47f8b2bc851dcd1c74332919
TARFILE=$VERNAME.tar.gz
URL=https://www.openssl.org/source/$TARFILE

# Matt Caswell <matt@openssl.org>
KEYID=D9C4D26D0E604491

# Preparations.
BUILD=$INSTALL/build/$NAME
STAGING=$INSTALL/stage/$VERNAME
PKG=$INSTALL/pkg/$VERNAME.pkg

# Download.
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

# Patch to link to system zlib.
cd $VERNAME
if [ ! -r crypto/comp/c_zlib.c.bak ]; then
    sed -i.bak -e 's/DSO_load(NULL, "z", NULL, 0)/DSO_load(NULL, \"\/usr\/lib\/libz.dylib\", NULL, DSO_FLAG_NO_NAME_TRANSLATION)/' crypto/comp/c_zlib.c
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

f = File.new("/usr/local/etc/openssl/cert.pem", "w")
f.write(valid_certs.join("\n"))
f.close
EOF
    chmod +x $BUILD/scripts/postinstall
fi

# Configure, compile, and create package.
if [ ! -r $PKG ]; then
    perl ./Configure \
	--prefix=/usr/local \
	--install-prefix=$STAGING \
	--openssldir=/usr/local/etc/openssl \
	no-ssl2 zlib-dynamic shared enable-cms darwin64-x86_64-cc enable-ec_nistp_64_gcc_128

    make depend
    make
    make test

    rm -fr $STAGING
    make install MANDIR=/usr/local/share/man MANSUFFIX=ssl

    # Remove some conflicting man files.
    rm -v $STAGING/usr/local/share/man/man1/md5.1ssl
    rm -v $STAGING/usr/local/share/man/man3/md5.3ssl
    
    # Ensure empty file of cert.pem so it can introspected.
    touch $STAGING/usr/local/etc/openssl/cert.pem
    
    pkgbuild --root $STAGING --scripts $BUILD/scripts --identifier "${IDENTIFIER}" --version $VERSION $PKG
fi
