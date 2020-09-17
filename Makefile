# also bump pve-kernel-meta if either of MAJ.MIN, PATCHLEVEL or KREL change
KERNEL_MAJ=5
KERNEL_MIN=8
KERNEL_PATCHLEVEL=9
# increment KREL if the ABI changes (abicheck target in debian/rules)
# rebuild packages with new KREL and run 'make abiupdate'
KREL=1

PKGREL=1
PKGRELLOCAL=1
PKGRELFULL=${PKGREL}

KERNEL_MAJMIN=$(KERNEL_MAJ).$(KERNEL_MIN)
KERNEL_VER=$(KERNEL_MAJMIN).$(KERNEL_PATCHLEVEL)

EXTRAVERSION=-${KREL}

# Append Linux flavor name to EXTRAVERSION
ifdef PVE_BUILD_FLAVOR
	_ := $(info Using build flavor: ${PVE_BUILD_FLAVOR})
	EXTRAVERSION:=${EXTRAVERSION}-${PVE_BUILD_FLAVOR}
endif

# Default to generic micro architecture
PVE_BUILD_TYPE ?= generic

ifneq (${PVE_BUILD_TYPE},generic)
	_ := $(info Using build type: ${PVE_BUILD_TYPE})
	PKGRELFULL:=${PKGRELFULL}+${PVE_BUILD_TYPE}${PKGRELLOCAL}
endif

KVNAME=${KERNEL_VER}${EXTRAVERSION}
PACKAGE=pve-edge-kernel-${KVNAME}
HDRPACKAGE=pve-edge-headers-${KVNAME}

ARCH=$(shell dpkg-architecture -qDEB_BUILD_ARCH)

# amd64/x86_64/x86 share the arch subdirectory in the kernel, 'x86' so we need
# a mapping
KERNEL_ARCH=x86
ifneq (${ARCH}, amd64)
KERNEL_ARCH=${ARCH}
endif

GITVERSION:=$(shell git rev-parse HEAD)

SKIPABI=0

BUILD_DIR=build

KERNEL_SRC=ubuntu-mainline
KERNEL_SRC_SUBMODULE=submodules/$(KERNEL_SRC)
KERNEL_CFG_ORG=config-${KERNEL_VER}.org

ZFSONLINUX_SUBMODULE=submodules/zfsonlinux/
ZFSDIR=pkg-zfs

MODULES=modules
MODULE_DIRS=${ZFSDIR}

# exported to debian/rules via debian/rules.d/dirs.mk
DIRS=KERNEL_SRC ZFSDIR MODULES

DST_DEB=${PACKAGE}_${KERNEL_VER}-${PKGRELFULL}_${ARCH}.deb
HDR_DEB=${HDRPACKAGE}_${KERNEL_VER}-${PKGRELFULL}_${ARCH}.deb
LINUX_TOOLS_DEB=linux-tools-$(KERNEL_MAJMIN)_${KERNEL_VER}-${PKGRELFULL}_${ARCH}.deb

DEBS=${DST_DEB} ${HDR_DEB} ${LINUX_TOOLS_DEB}

all: deb release.txt artifacts.txt
deb: ${DEBS}

release.txt:
	echo "${KVNAME}" > release.txt
	echo "${KERNEL_VER}" >> release.txt
	echo "${PKGREL}" >> release.txt
	echo "${ARCH}" >> release.txt
	echo "${PVE_BUILD_FLAVOR}" >> release.txt
	echo "${PVE_BUILD_TYPE}" >> release.txt

artifacts.txt:
	echo "${DST_DEB}" > artifacts.txt
	echo "${HDR_DEB}" >> artifacts.txt
	echo "${LINUX_TOOLS_DEB}" >> artifacts.txt

${LINUX_TOOLS_DEB} ${HDR_DEB}: ${DST_DEB}
${DST_DEB}: ${BUILD_DIR}.prepared
	cd ${BUILD_DIR}; dpkg-buildpackage --jobs=auto -b -uc -us

${BUILD_DIR}.prepared: $(addsuffix .prepared,${KERNEL_SRC} ${MODULES} debian)
	cp -a fwlist-previous ${BUILD_DIR}/
	cp -a abi-prev-* ${BUILD_DIR}/
	cp -a abi-blacklist ${BUILD_DIR}/
	touch $@

debian.prepared: debian
	rm -rf ${BUILD_DIR}/debian
	mkdir -p ${BUILD_DIR}
	cp -a debian ${BUILD_DIR}/debian
	echo "git clone git@github.com:fabianishere/pve-kernel-edge.git\\ngit checkout ${GITVERSION}" > ${BUILD_DIR}/debian/SOURCE
	@$(foreach dir, ${DIRS},echo "${dir}=${${dir}}" >> ${BUILD_DIR}/debian/rules.d/env.mk;)
	echo "KVNAME=${KVNAME}" >> ${BUILD_DIR}/debian/rules.d/env.mk
	echo "KERNEL_MAJMIN=${KERNEL_MAJMIN}" >> ${BUILD_DIR}/debian/rules.d/env.mk
	cd ${BUILD_DIR}; debian/rules debian/control
ifneq (${PVE_BUILD_TYPE},generic)
	cd ${BUILD_DIR}; debchange -l +${PVE_BUILD_TYPE} -D edge --force-distribution -U -M "Specialization for ${PVE_BUILD_TYPE}"
endif
	touch $@

PVE_PATCHES=$(wildcard patches/pve/*.patch)

${KERNEL_SRC}.prepared: ${KERNEL_SRC_SUBMODULE}
	rm -rf ${BUILD_DIR}/${KERNEL_SRC} $@
	mkdir -p ${BUILD_DIR}
	cp -a ${KERNEL_SRC_SUBMODULE} ${BUILD_DIR}/${KERNEL_SRC}
# TODO: split for archs, track and diff in our repository?
	cat ${BUILD_DIR}/${KERNEL_SRC}/debian.master/config/config.common.ubuntu ${BUILD_DIR}/${KERNEL_SRC}/debian.master/config/${ARCH}/config.common.${ARCH} ${BUILD_DIR}/${KERNEL_SRC}/debian.master/config/${ARCH}/config.flavour.generic > ${KERNEL_CFG_ORG}
	cp ${KERNEL_CFG_ORG} ${BUILD_DIR}/${KERNEL_SRC}/.config
	sed -i ${BUILD_DIR}/${KERNEL_SRC}/Makefile -e 's/^EXTRAVERSION.*$$/EXTRAVERSION=${EXTRAVERSION}/'
	rm -rf ${BUILD_DIR}/${KERNEL_SRC}/debian ${BUILD_DIR}/${KERNEL_SRC}/debian.master
	set -e; cd ${BUILD_DIR}/${KERNEL_SRC}; for patch in ${PVE_PATCHES}; do echo "applying PVE patch '$$patch'" && patch -p1 < ../../$${patch}; done
	touch $@

${MODULES}.prepared: $(addsuffix .prepared,${MODULE_DIRS})
	touch $@

ZFS_PATCHES=$(wildcard patches/zfs/*.patch)

${ZFSDIR}.prepared: ${ZFSONLINUX_SUBMODULE}
	rm -rf ${BUILD_DIR}/${MODULES}/${ZFSDIR} ${BUILD_DIR}/${MODULES}/tmp $@
	mkdir -p ${BUILD_DIR}/${MODULES}/tmp
	cp -a ${ZFSONLINUX_SUBMODULE}/* ${BUILD_DIR}/${MODULES}/tmp
	set -e; cd ${BUILD_DIR}/${MODULES}/tmp/upstream; for patch in ${ZFS_PATCHES}; do echo "applying patch '$$patch'" && patch -p1 < ../../../../$${patch}; done
	cd ${BUILD_DIR}/${MODULES}/tmp; make kernel
	rm -rf ${BUILD_DIR}/${MODULES}/tmp
	touch ${ZFSDIR}.prepared

# call after ABI bump with header deb in working directory
.PHONY: abiupdate
abiupdate: abi-prev-${KVNAME}
abi-prev-${KVNAME}: abi-tmp-${KVNAME}
ifneq ($(strip $(shell git status --untracked-files=no --porcelain -z)),)
	@echo "working directory unclean, aborting!"
	@false
else
	git rm "abi-prev-*"
	mv $< $@
	git add $@
	git commit -s -m "update ABI file for ${KVNAME}" -m "(generated with debian/scripts/abi-generate)"
	@echo "update abi-prev-${KVNAME} committed!"
endif

abi-tmp-${KVNAME}:
	@ test -e ${HDR_DEB} || (echo "need ${HDR_DEB} to extract ABI data!" && false)
	debian/scripts/abi-generate ${HDR_DEB} $@ ${KVNAME} 1

.PHONY: clean
clean:
	rm -rf *~ build *.prepared ${KERNEL_CFG_ORG}
	rm -f *.deb *.ddeb *.changes *.buildinfo release.txt artifacts.txt
	rm -f debian/control debian/pve-edge-*.postinst debian/pve-edge-*.prerm debian/pve-edge-*.postrm debian/rules.d/env.mk
