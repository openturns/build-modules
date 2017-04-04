pkgname=$1
pkgver=$2

git clone https://github.com/openturns/${pkgname}.git
pushd ${pkgname}
git checkout v${pkgver}
pushd distro/windows
make PYBASEVER=$PYBASEVER ARCH=$ARCH CHECK_OT=n OT_PREFIX=$PWD/../../../openturns/build-$ARCH-w64-mingw32/install
cp -v *.exe ${TRAVIS_BUILD_DIR}
popd
popd
