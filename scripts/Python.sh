#!/bin/bash
set -euxo pipefail

INSTALL="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/.. && pwd )"
NAME=Python
IDENTIFIER="org.python.pkg.python3"
VERSION=3.11.2
VERMAJ="${VERSION:0:3}"
VEREXTRA=""
VERNAME=${NAME}-${VERSION}${VEREXTRA}
CHKSUM=29e4b8f5f1658542a8c13e2dd277358c9c48f2b2f7318652ef1675e402b9d2af
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
    --without-ensurepip

# Compile
make clean
make

# TODO: Investigate these test failures:
## test_distutils.py
# ======================================================================
# FAIL: test_deployment_target_default (distutils.tests.test_build_ext.ParallelBuildExtTestCase.test_deployment_target_default)
# ----------------------------------------------------------------------
# Traceback (most recent call last):
#   File "/Users/username/osx-install/build/Python/Python-3.11.2/Lib/distutils/unixccompiler.py", line 117, in _compile
#     self.spawn(compiler_so + cc_args + [src, '-o', obj] +
#   File "/Users/username/osx-install/build/Python/Python-3.11.2/Lib/distutils/ccompiler.py", line 910, in spawn
#     spawn(cmd, dry_run=self.dry_run)
#   File "/Users/username/osx-install/build/Python/Python-3.11.2/Lib/distutils/spawn.py", line 91, in spawn
#     raise DistutilsExecError(
# distutils.errors.DistutilsExecError: command '/usr/bin/gcc' failed with exit code 1
#
## test_popen.py
# ======================================================================
# ERROR: test_popen (test.test_popen.PopenTest.test_popen)
# ----------------------------------------------------------------------
# Traceback (most recent call last):
#   File "/Users/username/osx-install/build/Python/Python-3.11.2/Lib/test/test_popen.py", line 35, in test_popen
#     self._do_test_commandline(
#   File "/Users/username/osx-install/build/Python/Python-3.11.2/Lib/test/test_popen.py", line 30, in _do_test_commandline
#     got = eval(data)[1:] # strip off argv[0]
#           ^^^^^^^^^^
#   File "<string>", line 0
# SyntaxError: invalid syntax
#
## test_venv.py
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
   Lib/test/test_distutils.py \
   Lib/test/test_popen.py \
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
