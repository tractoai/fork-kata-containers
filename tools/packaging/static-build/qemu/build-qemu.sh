#!/usr/bin/env bash
#
# Copyright (c) 2022 Intel Corporation
#
# SPDX-License-Identifier: Apache-2.0

[ -z "${DEBUG}" ] || set -x
set -o errexit
set -o nounset
set -o pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

kata_packaging_dir="${script_dir}/../.."
kata_packaging_scripts="${kata_packaging_dir}/scripts"

kata_static_build_dir="${kata_packaging_dir}/static-build"
kata_static_build_scripts="${kata_static_build_dir}/scripts"

ARCH=${ARCH:-$(uname -m)}

rm -fr qemu
git clone --depth=1 --branch "${QEMU_VERSION_NUM}" "${QEMU_REPO}" qemu
pushd qemu
${kata_packaging_scripts}/patch_qemu.sh "${QEMU_VERSION_NUM}" "${kata_packaging_dir}/qemu/patches"
if [ "$(uname -m)" != "${ARCH}" ] && [ "${ARCH}" == "s390x" ]; then
       PREFIX="${PREFIX}" ${kata_packaging_scripts}/configure-hypervisor.sh -s "${HYPERVISOR_NAME}" "${ARCH}" | xargs ./configure  --with-pkgversion="${PKGVERSION}" --cc=s390x-linux-gnu-gcc --cross-prefix=s390x-linux-gnu- --prefix="${PREFIX}" --target-list=s390x-softmmu
else
       PREFIX="${PREFIX}" ${kata_packaging_scripts}/configure-hypervisor.sh -s "${HYPERVISOR_NAME}" "${ARCH}" | xargs ./configure  --with-pkgversion="${PKGVERSION}"
fi
make -j"$(nproc +--ignore 1)"
make install DESTDIR="${QEMU_DESTDIR}"
popd
${kata_static_build_scripts}/qemu-build-post.sh
mv "${QEMU_DESTDIR}/${QEMU_TARBALL}" /share/
