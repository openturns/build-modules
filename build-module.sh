#!/bin/sh

usage()
{
  echo "Usage: $0 pkgname pkgver"
  exit 1
}

test $# = 2 || usage

pkgname=$1
pkgver=$2

git clone https://github.com/openturns/${pkgname}.git
cd ${pkgname}
git checkout v${pkgver}
cd distro/windows
make PYBASEVER=${PYBASEVER} ARCH=${ARCH} CHECK_OT=n OT_PREFIX=${HOME}/build/openturns/build/openturns/build-${ARCH}-w64-mingw32/install
cp -v *.exe ${TRAVIS_BUILD_DIR}
