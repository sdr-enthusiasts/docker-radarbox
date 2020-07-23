#!/usr/bin/env bash

# Verbosity (x)
# Exit on any error (e)
set -x

apt-get update
apt-get install -y --no-install-recommends \
  bc \
  file

# If cross-building, we have no way to determine this without looking at the installed binaries using libmagic/file
# Do we have libmagic/file installed

# Make sure `file` (libmagic) is available
if ! which file; then
  echo "ERROR: 'file' (libmagic) not available, cannot detect architecture!"
  exit 1
fi
FILEBINARY=$(which file)
FILEOUTPUT=$("${FILEBINARY}" -L "${FILEBINARY}")

# 32-bit x86
# Example output:
# /usr/bin/file: ELF 32-bit LSB shared object, Intel 80386, version 1 (SYSV), dynamically linked, interpreter /lib/ld-musl-i386.so.1, stripped
# /usr/bin/file: ELF 32-bit LSB shared object, Intel 80386, version 1 (SYSV), dynamically linked, interpreter /lib/ld-linux.so.2, for GNU/Linux 3.2.0, BuildID[sha1]=d48e1d621e9b833b5d33ede3b4673535df181fe0, stripped  
if echo "${FILEOUTPUT}" | grep "Intel 80386" > /dev/null; then
  ARCH="x86"
fi

# x86-64
# Example output:
# /usr/bin/file: ELF 64-bit LSB shared object, x86-64, version 1 (SYSV), dynamically linked, interpreter /lib/ld-musl-x86_64.so.1, stripped
# /usr/bin/file: ELF 64-bit LSB shared object, x86-64, version 1 (SYSV), dynamically linked, interpreter /lib64/ld-linux-x86-64.so.2, for GNU/Linux 3.2.0, BuildID[sha1]=6b0b86f64e36f977d088b3e7046f70a586dd60e7, stripped
if echo "${FILEOUTPUT}" | grep "x86-64" > /dev/null; then
  ARCH="amd64"
fi

# armel
# /usr/bin/file: ELF 32-bit LSB shared object, ARM, EABI5 version 1 (SYSV), dynamically linked, interpreter /lib/ld-linux.so.3, for GNU/Linux 3.2.0, BuildID[sha1]=f57b617d0d6cd9d483dcf847b03614809e5cd8a9, stripped
if echo "${FILEOUTPUT}" | grep "ARM" > /dev/null; then

  ARCH="arm"

  # armhf
  # Example outputs:
  # /usr/bin/file: ELF 32-bit LSB shared object, ARM, EABI5 version 1 (SYSV), dynamically linked, interpreter /lib/ld-musl-armhf.so.1, stripped  # /usr/bin/file: ELF 32-bit LSB shared object, ARM, EABI5 version 1 (SYSV), dynamically linked, interpreter /lib/ld-linux-armhf.so.3, for GNU/Linux 3.2.0, BuildID[sha1]=921490a07eade98430e10735d69858e714113c56, stripped
  # /usr/bin/file: ELF 32-bit LSB shared object, ARM, EABI5 version 1 (SYSV), dynamically linked, interpreter /lib/ld-linux-armhf.so.3, for GNU/Linux 3.2.0, BuildID[sha1]=921490a07eade98430e10735d69858e714113c56, stripped
  if echo "${FILEOUTPUT}" | grep "armhf" > /dev/null; then
    ARCH="armhf"
  fi

  # arm64
  # Example output:
  # /usr/bin/file: ELF 64-bit LSB shared object, ARM aarch64, version 1 (SYSV), dynamically linked, interpreter /lib/ld-musl-aarch64.so.1, stripped
  # /usr/bin/file: ELF 64-bit LSB shared object, ARM aarch64, version 1 (SYSV), dynamically linked, interpreter /lib/ld-linux-aarch64.so.1, for GNU/Linux 3.7.0, BuildID[sha1]=a8d6092fd49d8ec9e367ac9d451b3f55c7ae7a78, stripped
  if echo "${FILEOUTPUT}" | grep "aarch64" > /dev/null; then
    ARCH="aarch64"
  fi

fi

echo "========== Attempting build for ${ARCH} =========="

if [ "$ARCH" = "amd64" ]
then
    exec \
        /src/buildscripts/build.amd64.sh

elif [ "$ARCH" = "armhf" ]
then
    exec \
        /src/buildscripts/build.arm32.sh

elif [ "$ARCH" = "aarch64" ]
then
    exec \
        /src/buildscripts/build.arm64.sh

else
    echo ""
    echo "ERROR!"
    echo "This build is running on an unsupported architecture ($(uname -m))."
    echo "Please raise an issue on this container's GitHub reporting this."
    echo ""
    exit 1
    
fi