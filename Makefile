RELEASE=5.1

# also update pve-kernel-meta.git if either of these change
KERNEL_VER=4.13.13
KREL=6

PKGREL=41

EXTRAVERSION=-${KREL}-pve
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

SKIPABI=0

ifeq    ($(CC), cc)
GCC=gcc
else
GCC=$(CC)
endif

BUILD_DIR=build

KERNEL_SRC=ubuntu-artful
KERNEL_SRC_SUBMODULE=submodules/ubuntu-artful
KERNEL_CFG_ORG=config-${KERNEL_VER}.org

E1000EDIR=e1000e-3.3.6
E1000ESRC=${E1000EDIR}.tar.gz

IGBDIR=igb-5.3.5.10
IGBSRC=${IGBDIR}.tar.gz

IXGBEDIR=ixgbe-5.3.3
IXGBESRC=${IXGBEDIR}.tar.gz

ZFSONLINUX_SUBMODULE=submodules/zfsonlinux
SPLDIR=pkg-spl
SPLSRC=${ZFSONLINUX_SUBMODULE}/spl-debian
ZFSDIR=pkg-zfs
ZFSSRC=${ZFSONLINUX_SUBMODULE}/zfs-debian

MODULES=modules
MODULE_DIRS=${E1000EDIR} ${IGBDIR} ${IXGBEDIR} ${SPLDIR} ${ZFSDIR}

# exported to debian/rules via debian/rules.d/dirs.mk
DIRS=KERNEL_SRC E1000EDIR IGBDIR IXGBEDIR SPLDIR ZFSDIR MODULES

DST_DEB=${PACKAGE}_${KERNEL_VER}-${PKGREL}_${ARCH}.deb
HDR_DEB=${HDRPACKAGE}_${KERNEL_VER}-${PKGREL}_${ARCH}.deb
LINUX_TOOLS_DEB=linux-tools-4.13_${KERNEL_VER}-${PKGREL}_${ARCH}.deb

DEBS=${DST_DEB} ${HDR_DEB} ${LINUX_TOOLS_DEB}

all: check_gcc deb
deb: ${DEBS}

check_gcc:
	$(GCC) --version|grep "6\.3" || false
	@$(GCC) -Werror -mindirect-branch=thunk-extern -mindirect-branch-register -c -x c /dev/null -o check_gcc.o \
		|| ( rm -f check_gcc.o; \
		     echo "Please install gcc-6 packages with indirect thunk / RETPOLINE support"; \
		     false)
	@rm -f check_gcc.o

${LINUX_TOOLS_DEB} ${HDR_DEB}: ${DST_DEB}
${DST_DEB}: ${BUILD_DIR}.prepared
	cd ${BUILD_DIR}; dpkg-buildpackage --jobs=auto -b -uc -us
	lintian ${DST_DEB}
	#lintian ${HDR_DEB}
	lintian ${LINUX_TOOLS_DEB}

${BUILD_DIR}.prepared: $(addsuffix .prepared,${KERNEL_SRC} ${MODULES} debian)
	cp -a fwlist-previous ${BUILD_DIR}/
	cp -a abi-previous ${BUILD_DIR}/
	cp -a abi-blacklist ${BUILD_DIR}/
	touch $@

debian.prepared: debian
	rm -rf ${BUILD_DIR}/debian
	mkdir -p ${BUILD_DIR}
	cp -a debian ${BUILD_DIR}/debian
	echo "git clone git://git.proxmox.com/git/pve-kernel.git\\ngit checkout ${GITVERSION}" > ${BUILD_DIR}/debian/SOURCE
	@$(foreach dir, ${DIRS},echo "${dir}=${${dir}}" >> ${BUILD_DIR}/debian/rules.d/env.mk;)
	echo "KVNAME=${KVNAME}" >> ${BUILD_DIR}/debian/rules.d/env.mk
	cd ${BUILD_DIR}; debian/rules debian/control
	touch $@

${KERNEL_SRC}.prepared: ${KERNEL_SRC_SUBMODULE} | submodule
	rm -rf ${BUILD_DIR}/${KERNEL_SRC} $@
	mkdir -p ${BUILD_DIR}
	cp -a ${KERNEL_SRC_SUBMODULE} ${BUILD_DIR}/${KERNEL_SRC}
# TODO: split for archs, track and diff in our repository?
	cat ${BUILD_DIR}/${KERNEL_SRC}/debian.master/config/config.common.ubuntu ${BUILD_DIR}/${KERNEL_SRC}/debian.master/config/${ARCH}/config.common.${ARCH} ${BUILD_DIR}/${KERNEL_SRC}/debian.master/config/${ARCH}/config.flavour.generic > ${KERNEL_CFG_ORG}
	cp ${KERNEL_CFG_ORG} ${BUILD_DIR}/${KERNEL_SRC}/.config
	sed -i ${BUILD_DIR}/${KERNEL_SRC}/Makefile -e 's/^EXTRAVERSION.*$$/EXTRAVERSION=${EXTRAVERSION}/'
	rm -rf ${BUILD_DIR}/${KERNEL_SRC}/debian ${BUILD_DIR}/${KERNEL_SRC}/debian.master
	cd ${BUILD_DIR}/${KERNEL_SRC}; for patch in ../../patches/kernel/*.patch; do patch -p1 < $${patch}; done
	touch $@

${MODULES}.prepared: $(addsuffix .prepared,${MODULE_DIRS})
	touch $@

${E1000EDIR}.prepared: ${E1000ESRC}
	rm -rf ${BUILD_DIR}/${MODULES}/${E1000EDIR} $@
	mkdir -p ${BUILD_DIR}/${MODULES}/${E1000EDIR}
	tar --strip-components=1 -C ${BUILD_DIR}/${MODULES}/${E1000EDIR} -xf ${E1000ESRC}
	cd ${BUILD_DIR}/${MODULES}/${E1000EDIR}; patch -p1 < ../../../patches/intel/intel-module-gcc6-compat.patch
	cd ${BUILD_DIR}/${MODULES}/${E1000EDIR}; patch -p1 < ../../../patches/intel/e1000e/e1000e_4.10_max-mtu.patch
	touch $@

${IGBDIR}.prepared: ${IGBSRC}
	rm -rf ${BUILD_DIR}/${MODULES}/${IGBDIR} $@
	mkdir -p ${BUILD_DIR}/${MODULES}/${IGBDIR}
	tar --strip-components=1 -C ${BUILD_DIR}/${MODULES}/${IGBDIR} -xf ${IGBSRC}
	cd ${BUILD_DIR}/${MODULES}/${IGBDIR}; patch -p1 < ../../../patches/intel/igb/igb_4.10_max-mtu.patch
	cd ${BUILD_DIR}/${MODULES}/${IGBDIR}; patch -p1 < ../../../patches/intel/igb/igb_4.12_compat.patch
	touch $@

${IXGBEDIR}.prepared: ${IXGBESRC}
	rm -rf ${BUILD_DIR}/${MODULES}/${IXGBEDIR} $@
	mkdir -p ${BUILD_DIR}/${MODULES}/${IXGBEDIR}
	tar --strip-components=1 -C ${BUILD_DIR}/${MODULES}/${IXGBEDIR} -xf ${IXGBESRC}
	touch $@

$(SPLDIR).prepared: ${SPLSRC}
	rm -rf ${BUILD_DIR}/${MODULES}/${SPLDIR} $@
	mkdir -p ${BUILD_DIR}/${MODULES}/${SPLDIR}
	cp -a ${SPLSRC}/* ${BUILD_DIR}/${MODULES}/${SPLDIR}
	cd ${BUILD_DIR}/${MODULES}/${SPLDIR}; for patch in ../../../${SPLSRC}/../spl-patches/*.patch; do patch -p1 < $${patch}; done
	touch $@

$(ZFSDIR).prepared: ${ZFSSRC}
	rm -rf ${BUILD_DIR}/${MODULES}/${ZFSDIR} $@
	mkdir -p ${BUILD_DIR}/${MODULES}/${ZFSDIR}
	cp -a ${ZFSSRC}/* ${BUILD_DIR}/${MODULES}/${ZFSDIR}
	cd ${BUILD_DIR}/${MODULES}/${ZFSDIR}; for patch in ../../../${ZFSSRC}/../zfs-patches/*.patch; do patch -p1 < $${patch}; done
	touch $@

.PHONY: upload
upload: ${DEBS}
	tar cf - ${DEBS}|ssh repoman@repo.proxmox.com -- upload --product pve,pmg --dist stretch --arch ${ARCH}

.PHONY: distclean
distclean: clean
	git submodule deinit --all

# upgrade to current master
.PHONY: update_modules
update_modules: submodule
	git submodule foreach 'git pull --ff-only origin master'
	cd ${ZFSSRC}; git pull --ff-only origin master
	cd ${SPLSRC}; git pull --ff-only origin master

# make sure submodules were initialized
.PHONY: submodule
submodule:
	test -f "${KERNEL_SRC_SUBMODULE}/README" || git submodule update --init ${KERNEL_SRC_SUBMODULE}
	test -f "${ZFSONLINUX_SUBMODULE}/Makefile" || git submodule update --init ${ZFSONLINUX_SUBMODULE}
	(test -f "${ZFSSRC}/debian/changelog" && test -f "${SPLZRC}/debian/changelog") || (cd ${ZFSONLINUX_SUBMODULE}; git submodule update --init)


.PHONY: clean
clean:
	rm -rf *~ build *.prepared ${KERNEL_CFG_ORG}
