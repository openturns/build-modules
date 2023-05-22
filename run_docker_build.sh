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
for pkgnamever in otagrum-0.8 otfftw-0.13 otmixmod-0.14 otmorris-0.14 otrobopt-0.12 otsubsetinverse-1.10 otsvm-0.12
do
  pkgname=`echo ${pkgnamever}|cut -d "-" -f1`
  pkgver=`echo ${pkgnamever}|cut -d "-" -f2`
  cd
  curl -L https://github.com/openturns/${pkgname}/archive/v${pkgver}.tar.gz | tar xz && cd ${pkgname}-${pkgver}
  PREFIX=$PWD/install
  ${ARCH}-w64-mingw32-cmake \
    -DCMAKE_INSTALL_PREFIX=${PREFIX} \
    -DCMAKE_UNITY_BUILD=ON -DCMAKE_UNITY_BUILD_BATCH_SIZE=32 \
    -DPython_INCLUDE_DIR=${MINGW_PREFIX}/include/python${PYMAJMIN} \
    -DPython_LIBRARY=${MINGW_PREFIX}/lib/libpython${PYMAJMIN}.dll.a \
    -DPython_EXECUTABLE=/usr/bin/${ARCH}-w64-mingw32-python${PYMAJMIN}-bin \
    -DUSE_SPHINX=OFF -DBUILD_DOC=OFF \
    .
  make install
  ${ARCH}-w64-mingw32-strip --strip-unneeded ${PREFIX}/bin/*.dll ${PREFIX}/Lib/site-packages/${pkgname}/*.pyd
  if test "${pkgname}" = "otfftw"; then cp -v ${MINGW_PREFIX}/bin/libfftw*.dll ${PREFIX}/Lib/site-packages/${pkgname}; fi
  if test "${pkgname}" = "otagrum"; then cp -v ${MINGW_PREFIX}/bin/libagrum.dll ${PREFIX}/Lib/site-packages/${pkgname}; fi
  if test "${pkgname}" != "otagrum"; then cp ${PREFIX}/bin/lib${pkgname}.dll ${PREFIX}/Lib/site-packages/${pkgname} && OPENTURNS_NUM_THREADS=2 ctest -R pyinstall --output-on-failure --timeout 200 ${MAKEFLAGS}; fi

  cd distro/windows
  tar cjf ${pkgname}-${pkgver}-mingw-py${PYBASEVER}-${ARCH}.tar.bz2 --directory ${PREFIX}/.. `basename ${PREFIX}`
  makensis -DMODULE_PREFIX=${PREFIX} -DMODULE_VERSION=${pkgver} -DOPENTURNS_VERSION=${OTVERSION} -DPYBASEVER=${PYBASEVER} -DPYBASEVER_NODOT=${PYMAJMIN} -DARCH=${ARCH} installer.nsi

  if test -n "${uid}" -a -n "${gid}"
  then
    sudo cp -v *.tar.bz2 *.exe /io
    sudo chown ${uid}:${gid} /io/${pkgname}-${pkgver}-py${PYBASEVER}-${ARCH}.exe
  fi
done


