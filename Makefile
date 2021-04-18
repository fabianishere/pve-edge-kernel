PKGREL=1
PKGRELLOCAL=1
PKGRELFULL=${PKGREL}

KERNEL_MAJMIN=$(shell ./scripts/version.sh -n)
KERNEL_VER=$(shell ./scripts/version.sh -L)

KREL=1
EXTRAVERSION=-${KREL}-edge

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
PACKAGE=pve-kernel-${KVNAME}
HDRPACKAGE=pve-headers-${KVNAME}

ARCH=$(shell dpkg-architecture -qDEB_BUILD_ARCH)

# amd64/x86_64/x86 share the arch subdirectory in the kernel, 'x86' so we need
# a mapping
KERNEL_ARCH=x86
ifneq (${ARCH}, amd64)
KERNEL_ARCH=${ARCH}
endif

GITVERSION:=$(shell git rev-parse HEAD)

BUILD_DIR=build

KERNEL_SRC=linux
KERNEL_SRC_SUBMODULE=$(KERNEL_SRC)
KERNEL_CFG_ORG=config-${KERNEL_VER}.org

MODULES=modules
MODULE_DIRS=${ZFSDIR}

# exported to debian/rules via debian/rules.d/dirs.mk
DIRS=KERNEL_SRC MODULES

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
	git -C ${KERNEL_SRC} fetch ../crack.bundle $$(git -C ${KERNEL_SRC} ls-remote ../crack.bundle | cut -f1)
	git -C ${KERNEL_SRC} checkout -f FETCH_HEAD
	rm -rf ${BUILD_DIR}/${KERNEL_SRC} $@
	mkdir -p ${BUILD_DIR}
	cp -a ${KERNEL_SRC_SUBMODULE} ${BUILD_DIR}/${KERNEL_SRC}
	sed -i ${BUILD_DIR}/${KERNEL_SRC}/Makefile -e 's/^EXTRAVERSION.*$$/EXTRAVERSION=${EXTRAVERSION}/'
	rm -rf ${BUILD_DIR}/${KERNEL_SRC}/debian
	cp -r zfs ${BUILD_DIR}/zfs
	touch $@

${MODULES}.prepared: $(addsuffix .prepared,${MODULE_DIRS})
	touch $@

.PHONY: clean
clean:
	rm -rf *~ build *.prepared ${KERNEL_CFG_ORG}
	rm -f *.deb *.ddeb *.changes *.buildinfo release.txt artifacts.txt
	rm -f debian/control debian/pve-edge-*.postinst debian/pve-edge-*.prerm debian/pve-edge-*.postrm debian/rules.d/env.mk
