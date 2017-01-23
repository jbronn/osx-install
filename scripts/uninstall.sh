#!/bin/bash
set -ex

PKG_ID=$1

cd /
pkgutil --only-files --files $PKG_ID | tr '\n' '\0' | xargs -n 1 -0 rm -fv
pkgutil --forget $PKG_ID
