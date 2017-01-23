#!/bin/bash
set -ex

INSTALL="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/.. && pwd )"
NAME=pypa
IDENTIFIER="org.python.pkg.pypa"
VERSION=1.1.0
VERNAME=$NAME-$VERSION
PYPI_URL=https://pypi.python.org/pypi

# Preparations.
SETUPTOOLS_VERSION=33.1.1
PIP_VERSION=9.0.1
PY2_VERSION=2.7
PY3_VERSION=3.6
VIRTUALENV_VERSION=15.1.0
WHEEL_VERSION=0.29.0

BUILD=$INSTALL/build/$NAME
STAGING=$INSTALL/stage/$VERNAME
PKG=$INSTALL/pkg/$VERNAME.pkg

# Donald Stufft (dstufft) <donald@stufft.io>
KEYID=7C6B7C5D5E2B6356A926F04F6E3CBCE93372DCFA

# Wheel files.
SETUPTOOLS_WHEEL=setuptools-$SETUPTOOLS_VERSION-py2.py3-none-any.whl
PIP_WHEEL=pip-$PIP_VERSION-py2.py3-none-any.whl
VIRTUALENV_WHEEL=virtualenv-$VIRTUALENV_VERSION-py2.py3-none-any.whl
WHEEL_WHEEL=wheel-$WHEEL_VERSION-py2.py3-none-any.whl

cd $BUILD

test -x /usr/local/bin/gpg || (echo "GnuPG required for verification" && exit 1)
gpg --list-keys $KEYID || gpg --keyserver keys.gnupg.net --recv-keys $KEYID

if [ ! -r $SETUPTOOLS_WHEEL ]; then
    SETUPTOOLS_URL=$(curl $PYPI_URL/setuptools/json | ./pypi.py $SETUPTOOLS_VERSION)
    curl -O $SETUPTOOLS_URL
fi

if [ ! -r $PIP_WHEEL ]; then
    PIP_URL=$(curl $PYPI_URL/pip/json | ./pypi.py $PIP_VERSION)
    curl -O $PIP_URL
    curl -O $PIP_URL.asc
    gpg --verify $PIP_WHEEL.asc || (echo "Can't verify tarball." && rm -fv $PIP_WHEEL && exit 1)
fi

if [ ! -r $VIRTUALENV_WHEEL ]; then
    VIRTUALENV_URL=$(curl $PYPI_URL/virtualenv/json | ./pypi.py $VIRTUALENV_VERSION)
    curl -O $VIRTUALENV_URL
    curl -O $VIRTUALENV_URL.asc
    gpg --verify $VIRTUALENV_WHEEL.asc || (echo "Can't verify tarball." && rm -fv $VIRTUALENV_WHEEL && exit 1)
fi

if [ ! -r $WHEEL_WHEEL ]; then
    WHEEL_URL=$(curl $PYPI_URL/wheel/json | ./pypi.py $WHEEL_VERSION)
    curl -O $WHEEL_URL
fi

PY2_STAGING=$STAGING/Library/Frameworks/Python.framework/Versions/$PY2_VERSION
PY2_BIN=$PY2_STAGING/bin
PY2_LIB=$PY2_STAGING/lib/python$PY2_VERSION/site-packages
PY3_STAGING=$STAGING/Library/Frameworks/Python.framework/Versions/$PY3_VERSION
PY3_BIN=$PY3_STAGING/bin
PY3_LIB=$PY3_STAGING/lib/python$PY3_VERSION/site-packages

rm -fr $STAGING
mkdir -p $STAGING/usr/local/bin

mkdir -p $PY2_BIN $PY2_LIB
unzip $SETUPTOOLS_WHEEL -d $PY2_LIB
unzip $PIP_WHEEL -d $PY2_LIB
unzip $VIRTUALENV_WHEEL -d $PY2_LIB
unzip $WHEEL_WHEEL -d $PY2_LIB

mkdir -p $PY3_BIN $PY3_LIB
unzip $SETUPTOOLS_WHEEL -d $PY3_LIB
unzip $PIP_WHEEL -d $PY3_LIB
#unzip $VIRTUALENV_WHEEL -d $PY3_LIB
unzip $WHEEL_WHEEL -d $PY3_LIB


cat <<EOF > $PY2_BIN/easy_install-$PY2_VERSION
#!/usr/local/bin/python${PY2_VERSION}
__requires__ = 'setuptools==${SETUPTOOLS_VERSION}'
import sys
from pkg_resources import load_entry_point

if __name__ == '__main__':
    sys.exit(
        load_entry_point('setuptools==${SETUPTOOLS_VERSION}', 'console_scripts', 'easy_install-${PY2_VERSION}')()
    )
EOF
chmod +x $PY2_BIN/easy_install-$PY2_VERSION
ln -s /Library/Frameworks/Python.framework/Versions/$PY2_VERSION/bin/easy_install-$PY2_VERSION $STAGING/usr/local/bin/easy_install-$PY2_VERSION


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

cat <<EOF > $PY2_BIN/pip
#!/usr/local/bin/python${PY2_VERSION}
__requires__ = 'pip==${PIP_VERSION}'
import sys
from pkg_resources import load_entry_point

if __name__ == '__main__':
    sys.exit(
        load_entry_point('pip==${PIP_VERSION}', 'console_scripts', 'pip')()
    )
EOF
chmod +x $PY2_BIN/pip
ln -s /Library/Frameworks/Python.framework/Versions/$PY2_VERSION/bin/pip $STAGING/usr/local/bin/pip

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

cat <<EOF > $PY2_BIN/virtualenv
#!/usr/local/bin/python${PY2_VERSION}
__requires__ = 'virtualenv==${VIRTUALENV_VERSION}'
import sys
from pkg_resources import load_entry_point

if __name__ == '__main__':
    sys.exit(
        load_entry_point('virtualenv==${VIRTUALENV_VERSION}', 'console_scripts', 'virtualenv')()
    )
EOF
chmod +x $PY2_BIN/virtualenv
ln -s /Library/Frameworks/Python.framework/Versions/$PY2_VERSION/bin/virtualenv $STAGING/usr/local/bin/virtualenv


pkgbuild --root $STAGING --identifier "${IDENTIFIER}" --version $VERSION $PKG
