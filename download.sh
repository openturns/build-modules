#!/bin/sh

user=$1

release=1.12rc1
for _basename in otpmml-1.5 otsvm-0.4 otrobopt-0.3 otmixmod-0.6 otmorris-0.4 otlm-0.6 otfftw-0.5
do
  project=`echo "${_basename}" | cut -d '-' -f 1`
  version=`echo "${_basename}" | cut -d '-' -f 2`

  # source
  wget -c https://github.com/openturns/${project}/archive/v${version}.tar.gz -O /tmp/${_basename}.tar.gz

  for pybasever in 2.7 3.6 3.7
  do
    for _arch in i686 x86_64
    do
      _file=${_basename}-py${pybasever}-${_arch}.exe
      wget -c https://github.com/openturns/build-modules/releases/download/v${release}/${_file} -P /tmp
    done
  done
done

sha256sum /tmp/*.tar.gz
sha256sum /tmp/*.exe
