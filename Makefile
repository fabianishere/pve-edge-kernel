# also bump pve-kernel-meta if either of MAJ.MIN, PATCHLEVEL or KREL change
KERNEL_MAJ=4
KERNEL_MIN=15
KERNEL_PATCHLEVEL=18
# increment KREL if the ABI changes (abicheck target in debian/rules)
# rebuild packages with new KREL and run 'make abiupdate'
KREL=14

PKGREL=39

KERNEL_MAJMIN=$(KERNEL_MAJ).$(KERNEL_MIN)
KERNEL_VER=$(KERNEL_MAJMIN).$(KERNEL_PATCHLEVEL)

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

KERNEL_SRC=ubuntu-bionic
KERNEL_SRC_SUBMODULE=submodules/$(KERNEL_SRC)
KERNEL_CFG_ORG=config-${KERNEL_VER}.org

E1000EDIR=e1000e-3.4.1.1
E1000ESRC=${E1000EDIR}.tar.gz

IGBDIR=igb-5.3.5.18
IGBSRC=${IGBDIR}.tar.gz

ZFSONLINUX_SUBMODULE=submodules/zfsonlinux
SPLDIR=pkg-spl
ZFSDIR=pkg-zfs

MODULES=modules
MODULE_DIRS=${E1000EDIR} ${IGBDIR} ${SPLDIR} ${ZFSDIR}

# exported to debian/rules via debian/rules.d/dirs.mk
DIRS=KERNEL_SRC E1000EDIR IGBDIR SPLDIR ZFSDIR MODULES

DST_DEB=${PACKAGE}_${KERNEL_VER}-${PKGREL}_${ARCH}.deb
HDR_DEB=${HDRPACKAGE}_${KERNEL_VER}-${PKGREL}_${ARCH}.deb
LINUX_TOOLS_DEB=linux-tools-$(KERNEL_MAJMIN)_${KERNEL_VER}-${PKGREL}_${ARCH}.deb

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
	cp -a abi-prev-* ${BUILD_DIR}/
	cp -a abi-blacklist ${BUILD_DIR}/
	touch $@

debian.prepared: debian
	rm -rf ${BUILD_DIR}/debian
	mkdir -p ${BUILD_DIR}
	cp -a debian ${BUILD_DIR}/debian
	echo "git clone git://git.proxmox.com/git/pve-kernel.git\\ngit checkout ${GITVERSION}" > ${BUILD_DIR}/debian/SOURCE
	@$(foreach dir, ${DIRS},echo "${dir}=${${dir}}" >> ${BUILD_DIR}/debian/rules.d/env.mk;)
	echo "KVNAME=${KVNAME}" >> ${BUILD_DIR}/debian/rules.d/env.mk
	echo "KERNEL_MAJMIN=${KERNEL_MAJMIN}" >> ${BUILD_DIR}/debian/rules.d/env.mk
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
	set -e; cd ${BUILD_DIR}/${KERNEL_SRC}; for patch in ../../patches/kernel/*.patch; do echo "applying patch '$$patch'" && patch -p1 < $${patch}; done
	touch $@

${MODULES}.prepared: $(addsuffix .prepared,${MODULE_DIRS})
	touch $@

${E1000EDIR}.prepared: ${E1000ESRC}
	rm -rf ${BUILD_DIR}/${MODULES}/${E1000EDIR} $@
	mkdir -p ${BUILD_DIR}/${MODULES}/${E1000EDIR}
	tar --strip-components=1 -C ${BUILD_DIR}/${MODULES}/${E1000EDIR} -xf ${E1000ESRC}
	cd ${BUILD_DIR}/${MODULES}/${E1000EDIR}; patch -p1 < ../../../patches/intel/intel-module-gcc6-compat.patch
	cd ${BUILD_DIR}/${MODULES}/${E1000EDIR}; patch -p1 < ../../../patches/intel/e1000e/e1000e_4.10_max-mtu.patch
	cd ${BUILD_DIR}/${MODULES}/${E1000EDIR}; patch -p1 < ../../../patches/intel/e1000e/e1000e_4.15-new-timer.patch
	touch $@

${IGBDIR}.prepared: ${IGBSRC}
	rm -rf ${BUILD_DIR}/${MODULES}/${IGBDIR} $@
	mkdir -p ${BUILD_DIR}/${MODULES}/${IGBDIR}
	tar --strip-components=1 -C ${BUILD_DIR}/${MODULES}/${IGBDIR} -xf ${IGBSRC}
	cd ${BUILD_DIR}/${MODULES}/${IGBDIR}; patch -p1 < ../../../patches/intel/igb/igb_4.15_mtu.patch
	touch $@

${SPLDIR}.prepared: ${ZFSDIR}.prepared
${ZFSDIR}.prepared: ${ZFSONLINUX_SUBMODULE}
	rm -rf ${BUILD_DIR}/${MODULES}/${SPLDIR} ${BUILD_DIR}/${MODULES}/${ZFSDIR} ${BUILD_DIR}/${MODULES}/tmp $@
	mkdir -p ${BUILD_DIR}/${MODULES}/tmp
	cp -a ${ZFSONLINUX_SUBMODULE}/* ${BUILD_DIR}/${MODULES}/tmp
	cd ${BUILD_DIR}/${MODULES}/tmp; make kernel
	rm -rf ${BUILD_DIR}/${MODULES}/tmp
	touch ${ZFSDIR}.prepared ${SPLDIR}.prepared

.PHONY: upload
upload: ${DEBS}
	tar cf - ${DEBS}|ssh -X repoman@repo.proxmox.com -- upload --product pve,pmg --dist stretch --arch ${ARCH}

.PHONY: distclean
distclean: clean
	git submodule deinit --all

# upgrade to current master
.PHONY: update_modules
update_modules: submodule
	git submodule foreach 'git pull --ff-only origin master'
	cd ${ZFSONLINUX_SUBMODULE}; git pull --ff-only origin master

# make sure submodules were initialized
.PHONY: submodule
submodule:
	test -f "${KERNEL_SRC_SUBMODULE}/README" || git submodule update --init ${KERNEL_SRC_SUBMODULE}
	test -f "${ZFSONLINUX_SUBMODULE}/Makefile" || git submodule update --init ${ZFSONLINUX_SUBMODULE}
	(test -f "${ZFSONLINUX_SUBMODULE}/zfs/upstream/README.markdown" && test -f "${ZFSONLINUX_SUBMODULE}/spl/upstream/README.markdown") || (cd ${ZFSONLINUX_SUBMODULE}; git submodule update --init)

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
	rm -f *.deb *.changes *.buildinfo
