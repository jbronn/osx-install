#!/bin/bash
set -euxo pipefail

INSTALL="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/.. && pwd )"
NAME=pypa
IDENTIFIER="org.python.pkg.pypa"
VERSION=21.7.0
VERNAME=$NAME-$VERSION
PYPI_URL=https://pypi.org/pypi

# Preparations.
SETUPTOOLS_VERSION=57.1.0
PIP_VERSION=21.1.3
PY3_VERSION=3.9
WHEEL_VERSION=0.36.2

BUILD=$INSTALL/build/$NAME
KEYRING=$INSTALL/keyring/$NAME.gpg
STAGING=$INSTALL/stage/$VERNAME
PKG=$INSTALL/pkg/$VERNAME.pkg

# Wheel files.
SETUPTOOLS_WHEEL=setuptools-$SETUPTOOLS_VERSION-py3-none-any.whl
PIP_WHEEL=pip-$PIP_VERSION-py3-none-any.whl
WHEEL_WHEEL=wheel-$WHEEL_VERSION-py2.py3-none-any.whl


# Download.
cd $BUILD
if [ ! -r $SETUPTOOLS_WHEEL ]; then
    SETUPTOOLS_URL=$(curl $PYPI_URL/setuptools/json | ./pypi.py $SETUPTOOLS_VERSION)
    curl -LO $SETUPTOOLS_URL
fi
if [ ! -r $PIP_WHEEL ]; then
    PIP_URL=$(curl $PYPI_URL/pip/json | ./pypi.py $PIP_VERSION)
    curl -LO $PIP_URL
fi
if [ ! -r $WHEEL_WHEEL ]; then
    WHEEL_URL=$(curl $PYPI_URL/wheel/json | ./pypi.py $WHEEL_VERSION)
    curl -LO $WHEEL_URL
fi

# Stage.
PY3_STAGING=$STAGING/Library/Frameworks/Python.framework/Versions/$PY3_VERSION
PY3_BIN=$PY3_STAGING/bin
PY3_LIB=$PY3_STAGING/lib/python$PY3_VERSION/site-packages

rm -fr $STAGING
mkdir -p $STAGING/usr/local/bin

mkdir -p $PY3_BIN $PY3_LIB
unzip $SETUPTOOLS_WHEEL -d $PY3_LIB
unzip $PIP_WHEEL -d $PY3_LIB
unzip $WHEEL_WHEEL -d $PY3_LIB

cat <<EOF > $PY3_BIN/easy_install-$PY3_VERSION
#!/usr/local/bin/python${PY3_VERSION}
__requires__ = 'setuptools==${SETUPTOOLS_VERSION}'
import sys
from pkg_resources import load_entry_point

if __name__ == '__main__':
    sys.exit(
        load_entry_point('setuptools==${SETUPTOOLS_VERSION}', 'console_scripts', 'easy_install')()
    )
EOF
chmod +x $PY3_BIN/easy_install-$PY3_VERSION
ln -s /Library/Frameworks/Python.framework/Versions/$PY3_VERSION/bin/easy_install-$PY3_VERSION  $STAGING/usr/local/bin/easy_install-$PY3_VERSION

cat <<EOF > $PY3_BIN/pip3
#!/usr/local/bin/python${PY3_VERSION}
__requires__ = 'pip==${PIP_VERSION}'
import sys
from pkg_resources import load_entry_point

if __name__ == '__main__':
    sys.exit(
        load_entry_point('pip==${PIP_VERSION}', 'console_scripts', 'pip3')()
    )
EOF
chmod +x $PY3_BIN/pip3
ln -s /Library/Frameworks/Python.framework/Versions/$PY3_VERSION/bin/pip3 $STAGING/usr/local/bin/pip3

pkgbuild --root $STAGING --identifier "${IDENTIFIER}" --version $VERSION $PKG
