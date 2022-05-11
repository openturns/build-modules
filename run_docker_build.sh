#!/bin/sh

set -xe

usage()
{
  echo "Usage: $0 OTVERSION PYBASEVER ARCH [uid] [gid]"
  exit 1
}

test $# -ge 2 || usage

sudo pacman -Sy --noconfirm mingw-w64-fftw mingw-w64-agrum  # for otfftw, otagrum

OTVERSION=$1
PYBASEVER=$2
PYMAJMIN=${PYBASEVER:0:1}${PYBASEVER:2}
ARCH=x86_64
MINGW_PREFIX=/usr/${ARCH}-w64-mingw32
uid=$3
gid=$4

# fetch openturns mingw binaries
cd /tmp
curl -L https://github.com/openturns/build/releases/download/v${OTVERSION}/openturns-mingw-${OTVERSION}-py${PYBASEVER}-${ARCH}.tar.bz2 | tar xj
sudo cp -r install/* ${MINGW_PREFIX}

# for each module
for pkgnamever in otagrum-0.6 otfftw-0.12 otmixmod-0.13 otmorris-0.13 otpmml-1.12 otrobopt-0.11 otsubsetinverse-1.9 otsvm-0.11
do
  pkgname=`echo ${pkgnamever}|cut -d "-" -f1`
  pkgver=`echo ${pkgnamever}|cut -d "-" -f2`
  cd
  curl -L https://github.com/openturns/${pkgname}/archive/v${pkgver}.tar.gz | tar xz && cd ${pkgname}-${pkgver}
  PREFIX=$PWD/install
  ${ARCH}-w64-mingw32-cmake \
    -DCMAKE_INSTALL_PREFIX=${PREFIX} \
    -DPYTHON_INCLUDE_DIR=${MINGW_PREFIX}/include/python${PYMAJMIN} \
    -DPYTHON_LIBRARY=${MINGW_PREFIX}/lib/libpython${PYMAJMIN}.dll.a \
    -DPYTHON_EXECUTABLE=/usr/bin/${ARCH}-w64-mingw32-python${PYMAJMIN}-bin \
    -DUSE_SPHINX=OFF -DBUILD_DOC=OFF \
    .
  make install
  ${ARCH}-w64-mingw32-strip --strip-unneeded ${PREFIX}/bin/*.dll ${PREFIX}/Lib/site-packages/${pkgname}/*.pyd
  if test "${pkgname}" = "otfftw"; then cp -v ${MINGW_PREFIX}/bin/libfftw*.dll ${PREFIX}/Lib/site-packages/${pkgname}; fi
  if test "${pkgname}" = "otagrum"; then cp -v ${MINGW_PREFIX}/bin/libagrum.dll ${PREFIX}/Lib/site-packages/${pkgname}; fi
  if test "${pkgname}" != "otagrum"; then cp ${PREFIX}/bin/lib${pkgname}.dll ${PREFIX}/Lib/site-packages/${pkgname} && ctest -R pyinstall --output-on-failure --timeout 200 ${MAKEFLAGS}; fi

  cd distro/windows
  tar cjf ${pkgname}-${pkgver}-mingw-py${PYBASEVER}-${ARCH}.tar.bz2 --directory ${PREFIX}/.. `basename ${PREFIX}`
  makensis -DMODULE_PREFIX=${PREFIX} -DMODULE_VERSION=${pkgver} -DOPENTURNS_VERSION=${OTVERSION} -DPYBASEVER=${PYBASEVER} -DPYBASEVER_NODOT=${PYMAJMIN} -DARCH=${ARCH} installer.nsi

  if test -n "${uid}" -a -n "${gid}"
  then
    sudo cp -v *.tar.bz2 *.exe /io
    sudo chown ${uid}:${gid} /io/${pkgname}-${pkgver}-py${PYBASEVER}-${ARCH}.exe
  fi
done


