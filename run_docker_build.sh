#!/bin/sh

set -xe

usage()
{
  echo "Usage: $0 OTVERSION PYBASEVER ARCH [uid] [gid]"
  exit 1
}

test $# -ge 3 || usage

sudo pacman -Sy --noconfirm mingw-w64-fftw  # for otfftw
sudo pacman -Sy --noconfirm texlive-latexextra  # for modules that still have a PDF doc
#aurman -S --noconfirm --noedit mingw-w64-agrum  # for otagrum

OTVERSION=$1
PYBASEVER=$2
PYMAJMIN=${PYBASEVER:0:1}${PYBASEVER:2:1}
ARCH=$3
MINGW_PREFIX=/usr/${ARCH}-w64-mingw32
uid=$4
gid=$5

# fetch openturns mingw binaries
cd /tmp
curl -L https://github.com/openturns/build/releases/download/v${OTVERSION}/openturns-mingw-${OTVERSION}-py${PYBASEVER}-${ARCH}.tar.bz2 | tar xj
sudo cp -r install/* ${MINGW_PREFIX}

# for each module
for pkgnamever in otfftw-0.8 otmixmod-0.9 otmorris-0.7 otpmml-1.8 otrobopt-0.6 otsubsetinverse-1.5 otsvm-0.7
do
  pkgname=`echo ${pkgnamever}|cut -d "-" -f1`
  pkgver=`echo ${pkgnamever}|cut -d "-" -f2`
  cd
  git clone https://github.com/openturns/${pkgname}.git && cd ${pkgname}
  git checkout v${pkgver}
  PREFIX=$PWD/install
  ${ARCH}-w64-mingw32-cmake \
    -DCMAKE_INSTALL_PREFIX=${PREFIX} -DCMAKE_INSTALL_LIBDIR=lib \
    -DPYTHON_INCLUDE_DIR=${MINGW_PREFIX}/include/python${PYMAJMIN} \
    -DPYTHON_LIBRARY=${MINGW_PREFIX}/lib/libpython${PYMAJMIN}.dll.a \
    -DPYTHON_EXECUTABLE=/usr/bin/${ARCH}-w64-mingw32-python${PYMAJMIN}-bin \
    -DPYTHON_SITE_PACKAGES=Lib/site-packages \
    -DUSE_SPHINX=OFF \
    .
  make install
  ${ARCH}-w64-mingw32-strip --strip-unneeded ${PREFIX}/bin/*.dll ${PREFIX}/Lib/site-packages/${pkgname}/*.pyd
  cp ${PREFIX}/bin/*.dll python/test && ctest -R pyinstall --output-on-failure --timeout 200 ${MAKEFLAGS}
  if test "${pkgname}" = "otfftw"; then cp -v ${MINGW_PREFIX}/bin/libfftw*.dll ${PREFIX}/bin; fi
  if test "${pkgname}" = "otagrum"; then cp -v ${MINGW_PREFIX}/bin/libagrum.dll ${PREFIX}/bin; fi

  cd distro/windows
  makensis -DMODULE_PREFIX=${PREFIX} -DMODULE_VERSION=${pkgver} -DOPENTURNS_VERSION=${OTVERSION} -DPYBASEVER=${PYBASEVER} -DPYBASEVER_NODOT=${PYMAJMIN} -DARCH=${ARCH} installer.nsi

  if test -n "${uid}" -a -n "${gid}"
  then
    sudo cp -v ${pkgname}-${pkgver}-py${PYBASEVER}-${ARCH}.exe /io
    sudo chown ${uid}:${gid} /io/${pkgname}-${pkgver}-py${PYBASEVER}-${ARCH}.exe
  fi
done


