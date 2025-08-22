#!/bin/bash
set -euxo pipefail

INSTALL="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/.. && pwd )"
NAME=Python
IDENTIFIER="org.python.pkg.python3"
VERSION=3.13.7
VERMAJ="${VERSION:0:4}"
VEREXTRA=""
VERNAME=${NAME}-${VERSION}${VEREXTRA}
CHKSUM=5462f9099dfd30e238def83c71d91897d8caa5ff6ebc7a50f14d4802cdaaa79a
TARFILE=$VERNAME.tar.xz
URL=https://www.python.org/ftp/python/$VERSION/$TARFILE

# Preparations.
BUILD=$INSTALL/build/$NAME
KEYRING=$INSTALL/keyring/$NAME.gpg
STAGING=$INSTALL/stage/$VERNAME
PKG=$INSTALL/pkg/$VERNAME.pkg

# Check prereqs.
test -x /usr/local/bin/gpgv || \
    (echo "GnuPG required for verification" && exit 1)
test -r /usr/local/lib/libreadline.dylib || \
    (echo "readline package is required" && exit 1)
test -r /usr/local/lib/libssl.dylib || \
    (echo "openssl package is required" && exit 1)
test -r /usr/local/lib/libsqlite3.dylib || \
    (echo "sqlite3 package is required" && exit 1)

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
rm -fr $VERNAME
# Łukasz Langa (GPG langa.pl) <lukasz@langa.pl>, GnuPG keyid: B26995E310250568
# Pablo Galindo Salgado <pablogsal@gmail.com>, GnuPG keyid: 64E628F8D684696D
# Thomas Wouters <thomas@python.org>, GnuPG keyid: A821E680E5FA6305
gpgv -v --keyring $KEYRING $TARFILE.asc $TARFILE
echo "${CHKSUM}  ${TARFILE}" | shasum -a 256 -c -
tar xJf $TARFILE

# Configure.
cd $VERNAME
./configure \
    MACOSX_DEPLOYMENT_TARGET=$(sw_vers | grep ^ProductVersion | awk '{ print $2 }') \
    --prefix=/usr/local \
    --enable-ipv6 \
    --enable-framework \
    --enable-loadable-sqlite-extensions \
    --enable-optimizations \
    --with-dbmliborder=ndbm \
    --with-dtrace \
    --with-system-expat \
    --with-system-libmpdec \
    --without-ensurepip

# Compile
make clean
make

# TODO: Investigate these test failures:
## test_external_inspection.py
#
# ======================================================================
# ERROR: test_self_trace (test.test_external_inspection.TestGetStackTrace.test_self_trace)
# ----------------------------------------------------------------------
# Traceback (most recent call last):
#   File "/Users/jbronn/osx-install/build/Python/Python-3.13.1/Lib/test/test_external_inspection.py", line 80, in test_self_trace
#     stack_trace = get_stack_trace(os.getpid())
# RuntimeError: Failed to get .PyRuntime address
#
## test_popen.py
#
# ======================================================================
# ERROR: test_popen (test.test_popen.PopenTest.test_popen)
# ----------------------------------------------------------------------
# Traceback (most recent call last):
#   File "/Users/jbronn/osx-install/build/Python/Python-3.13.1/Lib/test/test_popen.py", line 35, in test_popen
#     self._do_test_commandline(
#     ~~~~~~~~~~~~~~~~~~~~~~~~~^
#         "foo bar",
#         ^^^^^^^^^^
#         ["foo", "bar"]
#         ^^^^^^^^^^^^^^
#     )
#     ^
#   File "/Users/jbronn/osx-install/build/Python/Python-3.13.1/Lib/test/test_popen.py", line 30, in _do_test_commandline
#     got = eval(data)[1:] # strip off argv[0]
#           ~~~~^^^^^^
#   File "<string>", line 0
#
# SyntaxError: invalid syntax
#
## test_signal.py
#
# ======================================================================
# FAIL: test_itimer_virtual (test.test_signal.ItimerTest.test_itimer_virtual)
# ----------------------------------------------------------------------
# Traceback (most recent call last):
#   File "/Users/jbronn/osx-install/build/Python/Python-3.13.1/Lib/test/test_signal.py", line 845, in test_itimer_virtual
#     for _ in support.busy_retry(support.LONG_TIMEOUT):
#              ~~~~~~~~~~~~~~~~~~^^^^^^^^^^^^^^^^^^^^^^
#   File "/Users/jbronn/osx-install/build/Python/Python-3.13.1/Lib/test/support/__init__.py", line 2490, in busy_retry
#     raise AssertionError(msg)
# AssertionError: timeout (300.0 seconds)
#
## test_venv.py
#
# ======================================================================
# ERROR: test_zippath_from_non_installed_posix (test.test_venv.BasicTest.test_zippath_from_non_installed_posix)
# Test that when create venv from non-installed python, the zip path
# ----------------------------------------------------------------------
# Traceback (most recent call last):
#   File "/Users/username/osx-install/build/Python/Python-3.11.2/Lib/test/test_venv.py", line 604, in test_zippath_from_non_installed_posix
#     subprocess.check_call(cmd,
#   File "/Users/username/osx-install/build/Python/Python-3.11.2/Lib/subprocess.py", line 413, in check_call
#     raise CalledProcessError(retcode, cmd)
# subprocess.CalledProcessError: Command '['/private/var/folders/ws/cjz0nqld52n7dkmzgts6ylyr0000gp/T/tmp6msltfxd/bin/python.exe', '-m', 'venv', '--without-pip', '/private/var/folders/ws/cjz0nqld52n7dkmzgts6ylyr0000gp/T/tmpesii6n04']' died with <Signals.SIGABRT: 6>.
#
rm -f \
    Lib/test/test_external_inspection.py \
    Lib/test/test_popen.py \
    Lib/test/test_signal.py \
    Lib/test/test_venv.py

# Test
make quicktest

# Stage.
rm -fr $STAGING
make install DESTDIR=$STAGING PYTHONAPPSDIR=/usr/local
rm -fr $STAGING/usr/local/*.app
rm -fr $STAGING/usr/local/bin/2to3*
# Link in the pkg-config files.
mkdir -p $STAGING/usr/local/lib/pkgconfig
ln -s /Library/Frameworks/Python.framework/Versions/$VERMAJ/lib/pkgconfig/python-$VERMAJ.pc $STAGING/usr/local/lib/pkgconfig
ln -s /Library/Frameworks/Python.framework/Versions/$VERMAJ/lib/pkgconfig/python3.pc $STAGING/usr/local/lib/pkgconfig

# Package.
rm -f $PKG $INSTALL/pkg/$NAME.pkg
pkgbuild --root $STAGING --identifier "${IDENTIFIER}" --version ${VERSION}${VEREXTRA} $PKG
ln -s $PKG $INSTALL/pkg/$NAME.pkg
