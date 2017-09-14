RELEASE=5.0

# also update proxmox-ve/changelog if you change KERNEL_VER or KREL
KERNEL_VER=4.10.17
PKGREL=23
# also include firmware of previous version into
# the fw package:  fwlist-2.6.32-PREV-pve
KREL=3

KERNEL_SRC=ubuntu-artful
KERNEL_SRC_SUBMODULE=submodules/ubuntu-artful

EXTRAVERSION=-${KREL}-pve
KVNAME=${KERNEL_VER}${EXTRAVERSION}
PACKAGE=pve-kernel-${KVNAME}
HDRPACKAGE=pve-headers-${KVNAME}

ARCH=$(shell dpkg-architecture -qDEB_BUILD_ARCH)
NPROCS=$(shell nproc)

# amd64/x86_64/x86 share the arch subdirectory in the kernel, 'x86' so we need
# a mapping
KERNEL_ARCH=x86
ifneq (${ARCH}, amd64)
KERNEL_ARCH=${ARCH}
endif

GITVERSION:=$(shell git rev-parse HEAD)
CHANGELOG_DATE:=$(shell dpkg-parsechangelog -SDate -lchangelog.Debian)
export SOURCE_DATE_EPOCH ?= $(shell dpkg-parsechangelog -STimestamp -lchangelog.Debian)

SKIPABI=0

TOP=$(shell pwd)

KERNEL_CFG_ORG=config-${KERNEL_VER}.org

E1000EDIR=e1000e-3.3.5.3
E1000ESRC=${E1000EDIR}.tar.gz

IGBDIR=igb-5.3.5.4
IGBSRC=${IGBDIR}.tar.gz

IXGBEDIR=ixgbe-5.0.4
IXGBESRC=${IXGBEDIR}.tar.gz

SPLDIR=pkg-spl
SPLSRC=submodules/spl-module
ZFSDIR=pkg-zfs
ZFSSRC=submodules/zfs-module
ZFS_KO=zfs.ko
ZFS_KO_REST=zavl.ko znvpair.ko zunicode.ko zcommon.ko zpios.ko
ZFS_MODULES=$(ZFS_KO) $(ZFS_KO_REST)
SPL_KO=spl.ko
SPL_KO_REST=splat.ko
SPL_MODULES=$(SPL_KO) $(SPL_KO_REST)

DST_DEB=${PACKAGE}_${KERNEL_VER}-${PKGREL}_${ARCH}.deb
HDR_DEB=${HDRPACKAGE}_${KERNEL_VER}-${PKGREL}_${ARCH}.deb
PVEPKG=proxmox-ve
PVE_DEB=${PVEPKG}_${RELEASE}-${PKGREL}_all.deb
VIRTUALHDRPACKAGE=pve-headers
VIRTUAL_HDR_DEB=${VIRTUALHDRPACKAGE}_${RELEASE}-${PKGREL}_all.deb

LINUX_TOOLS_PKG=linux-tools-4.13
LINUX_TOOLS_DEB=${LINUX_TOOLS_PKG}_${KERNEL_VER}-${PKGREL}_${ARCH}.deb

DEBS=${DST_DEB} ${HDR_DEB} ${PVE_DEB} ${VIRTUAL_HDR_DEB} ${LINUX_TOOLS_DEB}

all: check_gcc deb
deb: ${DEBS}

pve: $(PVE_DEB)
${PVE_DEB}: proxmox-ve/control proxmox-ve/postinst ${PVE_RELEASE_KEYS}
	rm -rf proxmox-ve/data
	mkdir -p proxmox-ve/data/DEBIAN
	mkdir -p proxmox-ve/data/usr/share/doc/${PVEPKG}/
	mkdir -p proxmox-ve/data/etc/apt/trusted.gpg.d
	install -m 0644 proxmox-ve/proxmox-release-5.x.pubkey proxmox-ve/data/etc/apt/trusted.gpg.d/proxmox-ve-release-5.x.gpg
	sed -e 's/@KVNAME@/${KVNAME}/' -e 's/@KERNEL_VER@/${KERNEL_VER}/' -e 's/@RELEASE@/${RELEASE}/' -e 's/@PKGREL@/${PKGREL}/' <proxmox-ve/control >proxmox-ve/data/DEBIAN/control
	sed -e 's/@KVNAME@/${KVNAME}/' <proxmox-ve/postinst >proxmox-ve/data/DEBIAN/postinst
	chmod 0755 proxmox-ve/data/DEBIAN/postinst
	install -m 0755 proxmox-ve/postrm proxmox-ve/data/DEBIAN/postrm
	echo "git clone git://git.proxmox.com/git/pve-kernel.git\\ngit checkout ${GITVERSION}" > proxmox-ve/data/usr/share/doc/${PVEPKG}/SOURCE
	install -m 0644 proxmox-ve/copyright proxmox-ve/data/usr/share/doc/${PVEPKG}
	install -m 0644 proxmox-ve/changelog.Debian proxmox-ve/data/usr/share/doc/${PVEPKG}
	gzip -n --best proxmox-ve/data/usr/share/doc/${PVEPKG}/changelog.Debian
	dpkg-deb --build proxmox-ve/data ${PVE_DEB}

pve-headers: $(VIRTUAL_HDR_DEB)
${VIRTUAL_HDR_DEB}: proxmox-ve/pve-headers.control
	rm -rf pve-headers/data
	mkdir -p pve-headers/data/DEBIAN
	mkdir -p pve-headers/data/usr/share/doc/${VIRTUALHDRPACKAGE}/
	sed -e 's/@KVNAME@/${KVNAME}/' -e 's/@KERNEL_VER@/${KERNEL_VER}/' -e 's/@RELEASE@/${RELEASE}/' -e 's/@PKGREL@/${PKGREL}/' <proxmox-ve/pve-headers.control >pve-headers/data/DEBIAN/control
	echo "git clone git://git.proxmox.com/git/pve-kernel.git\\ngit checkout ${GITVERSION}" > pve-headers/data/usr/share/doc/${VIRTUALHDRPACKAGE}/SOURCE
	install -m 0644 proxmox-ve/copyright pve-headers/data/usr/share/doc/${VIRTUALHDRPACKAGE}
	install -m 0644 proxmox-ve/changelog.Debian pve-headers/data/usr/share/doc/${VIRTUALHDRPACKAGE}
	gzip -n --best pve-headers/data/usr/share/doc/${VIRTUALHDRPACKAGE}/changelog.Debian
	dpkg-deb --build pve-headers/data ${VIRTUAL_HDR_DEB}

check_gcc: 
ifeq    ($(CC), cc)
	gcc --version|grep "6\.3" || false
else
	$(CC) --version|grep "6\.3" || false
endif

${DST_DEB}: data control.in prerm.in postinst.in postrm.in copyright changelog.Debian | fwcheck abicheck
	mkdir -p data/DEBIAN
	sed -e 's/@KERNEL_VER@/${KERNEL_VER}/' -e 's/@KVNAME@/${KVNAME}/' -e 's/@PKGREL@/${PKGREL}/' -e 's/@ARCH@/${ARCH}/' <control.in >data/DEBIAN/control
	sed -e 's/@@KVNAME@@/${KVNAME}/g'  <prerm.in >data/DEBIAN/prerm
	chmod 0755 data/DEBIAN/prerm
	sed -e 's/@@KVNAME@@/${KVNAME}/g'  <postinst.in >data/DEBIAN/postinst
	chmod 0755 data/DEBIAN/postinst
	sed -e 's/@@KVNAME@@/${KVNAME}/g'  <postrm.in >data/DEBIAN/postrm
	chmod 0755 data/DEBIAN/postrm
	install -D -m 644 copyright data/usr/share/doc/${PACKAGE}/copyright
	install -D -m 644 changelog.Debian data/usr/share/doc/${PACKAGE}/changelog.Debian
	echo "git clone git://git.proxmox.com/git/pve-kernel.git\\ngit checkout ${GITVERSION}" > data/usr/share/doc/${PACKAGE}/SOURCE
	gzip -n -f --best data/usr/share/doc/${PACKAGE}/changelog.Debian
	rm -f data/lib/modules/${KVNAME}/source
	rm -f data/lib/modules/${KVNAME}/build
	dpkg-deb --build data ${DST_DEB}
	lintian ${DST_DEB}

LINUX_TOOLS_DH_LIST=strip installchangelogs installdocs compress shlibdeps gencontrol md5sums builddeb

${LINUX_TOOLS_DEB}: .compile_mark control.tools changelog.Debian copyright
	rm -rf linux-tools ${LINUX_TOOLS_DEB}
	mkdir -p linux-tools/debian
	cp control.tools linux-tools/debian/control
	echo 9 > linux-tools/debian/compat
	cp changelog.Debian linux-tools/debian/changelog
	cp copyright linux-tools/debian
	mkdir -p linux-tools/debian/linux-tools-4.13/usr/bin
	install -m 0755 ${KERNEL_SRC}/tools/perf/perf linux-tools/debian/linux-tools-4.13/usr/bin/perf_4.13
	cd linux-tools; for i in ${LINUX_TOOLS_DH_LIST}; do dh_$$i; done
	lintian ${LINUX_TOOLS_DEB}

fwlist-${KVNAME}: data
	./find-firmware.pl data/lib/modules/${KVNAME} >fwlist.tmp
	mv fwlist.tmp $@

.PHONY: fwcheck
fwcheck: fwlist-${KVNAME} fwlist-previous
	@echo "checking fwlist for changes since last built firmware package.."
	@echo "if this check fails, add fwlist-${KVNAME} to the pve-firmware repository and upload a new firmware package together with the ${KVNAME} kernel"
	sort fwlist-previous | uniq > fwlist-previous.sorted
	sort fwlist-${KVNAME} | uniq > fwlist-${KVNAME}.sorted
	diff -up -N fwlist-previous.sorted fwlist-${KVNAME}.sorted > fwlist.diff
	rm fwlist.diff fwlist-previous.sorted fwlist-${KVNAME}.sorted
	@echo "done, no need to rebuild pve-firmware"


abi-${KVNAME}: .compile_mark
	sed -e 's/^\(.\+\)[[:space:]]\+\(.\+\)[[:space:]]\(.\+\)$$/\3 \2 \1/' ${KERNEL_SRC}/Module.symvers | sort > abi-${KVNAME}

.PHONY: abicheck
abicheck: abi-${KVNAME} abi-previous abi-blacklist
	./abi-check abi-${KVNAME} abi-previous ${SKIPABI}

data: .compile_mark igb.ko ixgbe.ko e1000e.ko ${SPL_MODULES} ${ZFS_MODULES}
	rm -rf data tmp; mkdir -p tmp/lib/modules/${KVNAME}
	mkdir tmp/boot
	install -m 644 ${KERNEL_SRC}/.config tmp/boot/config-${KVNAME}
	install -m 644 ${KERNEL_SRC}/System.map tmp/boot/System.map-${KVNAME}
	install -m 644 ${KERNEL_SRC}/arch/${KERNEL_ARCH}/boot/bzImage tmp/boot/vmlinuz-${KVNAME}
	cd ${KERNEL_SRC}; make INSTALL_MOD_PATH=../tmp/ modules_install
	## install latest ibg driver
	install -m 644 igb.ko tmp/lib/modules/${KVNAME}/kernel/drivers/net/ethernet/intel/igb/
	# install latest ixgbe driver
	install -m 644 ixgbe.ko tmp/lib/modules/${KVNAME}/kernel/drivers/net/ethernet/intel/ixgbe/
	# install latest e1000e driver
	install -m 644 e1000e.ko tmp/lib/modules/${KVNAME}/kernel/drivers/net/ethernet/intel/e1000e/
	# install zfs drivers
	install -d -m 0755 tmp/lib/modules/${KVNAME}/zfs
	install -m 644 ${SPL_MODULES} ${ZFS_MODULES} tmp/lib/modules/${KVNAME}/zfs
	# remove firmware
	rm -rf tmp/lib/firmware
	# strip debug info
	find tmp/lib/modules -name \*.ko -print | while read f ; do strip --strip-debug "$$f"; done
	# finalize
	/sbin/depmod -b tmp/ ${KVNAME}
	# Autogenerate blacklist for watchdog devices (see README)
	install -m 0755 -d tmp/lib/modprobe.d
	ls tmp/lib/modules/${KVNAME}/kernel/drivers/watchdog/ > watchdog-blacklist.tmp
	echo ipmi_watchdog.ko >> watchdog-blacklist.tmp
	cat watchdog-blacklist.tmp|sed -e 's/^/blacklist /' -e 's/.ko$$//'|sort -u > tmp/lib/modprobe.d/blacklist_${PACKAGE}.conf
	mv tmp data

PVE_CONFIG_OPTS= \
-m INTEL_MEI_WDT \
-d CONFIG_SND_PCM_OSS \
-e CONFIG_TRANSPARENT_HUGEPAGE_MADVISE \
-d CONFIG_TRANSPARENT_HUGEPAGE_ALWAYS \
-m CONFIG_CEPH_FS \
-m CONFIG_BLK_DEV_NBD \
-m CONFIG_BLK_DEV_RBD \
-m CONFIG_BCACHE \
-m CONFIG_JFS_FS \
-m CONFIG_HFS_FS \
-m CONFIG_HFSPLUS_FS \
-e CONFIG_BRIDGE \
-e CONFIG_BRIDGE_NETFILTER \
-e CONFIG_BLK_DEV_SD \
-e CONFIG_BLK_DEV_SR \
-e CONFIG_BLK_DEV_DM \
-e CONFIG_BLK_DEV_NVME \
-d CONFIG_INPUT_EVBUG \
-d CONFIG_CPU_FREQ_DEFAULT_GOV_ONDEMAND \
-e CONFIG_CPU_FREQ_DEFAULT_GOV_PERFORMANCE \
-d CONFIG_MODULE_SIG \
-d CONFIG_MEMCG_DISABLED \
-e CONFIG_MEMCG_SWAP_ENABLED \
-e CONFIG_MEMCG_KMEM \
-d CONFIG_DEFAULT_CFQ \
-e CONFIG_DEFAULT_DEADLINE \
-e CONFIG_MODVERSIONS \
-d CONFIG_DEFAULT_SECURITY_DAC \
-e CONFIG_DEFAULT_SECURITY_APPARMOR \
--set-str CONFIG_DEFAULT_SECURITY apparmor

.compile_mark: ${KERNEL_SRC}/README ${KERNEL_CFG_ORG}
	[ ! -e /lib/modules/${KVNAME}/build ] || (echo "please remove /lib/modules/${KVNAME}/build" && false)
	cp ${KERNEL_CFG_ORG} ${KERNEL_SRC}/.config
	cd ${KERNEL_SRC}; ./scripts/config ${PVE_CONFIG_OPTS}
	cd ${KERNEL_SRC}; make oldconfig
	cd ${KERNEL_SRC}; make KBUILD_BUILD_VERSION_TIMESTAMP="PVE ${KERNEL_VER}-${PKGREL} (${CHANGELOG_DATE})" -j ${NPROCS}
	make -C ${KERNEL_SRC}/tools/perf prefix=/usr HAVE_CPLUS_DEMANGLE=1 NO_LIBPYTHON=1 NO_LIBPERL=1 NO_LIBCRYPTO=1 PYTHON=python2.7
	make -C ${KERNEL_SRC}/tools/perf man
	touch $@

${KERNEL_CFG_ORG}: ${KERNEL_SRC}/README
${KERNEL_SRC}/README: ${KERNEL_SRC_SUBMODULE} | submodules
	rm -rf ${KERNEL_SRC}
	cp -a ${KERNEL_SRC_SUBMODULE} ${KERNEL_SRC}
	cat ${KERNEL_SRC}/debian.master/config/config.common.ubuntu ${KERNEL_SRC}/debian.master/config/${ARCH}/config.common.${ARCH} ${KERNEL_SRC}/debian.master/config/${ARCH}/config.flavour.generic > ${KERNEL_CFG_ORG}
	cd ${KERNEL_SRC}; patch -p1 < ../uname-version-timestamp.patch
	cd ${KERNEL_SRC}; patch -p1 <../bridge-patch.diff
	#cd ${KERNEL_SRC}; patch -p1 <../bridge-forward-ipv6-neighbor-solicitation.patch
	#cd ${KERNEL_SRC}; patch -p1 <../add-empty-ndo_poll_controller-to-veth.patch
	cd ${KERNEL_SRC}; patch -p1 <../override_for_missing_acs_capabilities.patch
	#cd ${KERNEL_SRC}; patch -p1 <../vhost-net-extend-device-allocation-to-vmalloc.patch
	cd ${KERNEL_SRC}; patch -p1 < ../kvm-dynamic-halt-polling-disable-default.patch
	cd ${KERNEL_SRC}; patch -p1 < ../cgroup-cpuset-add-cpuset.remap_cpus.patch
	sed -i ${KERNEL_SRC}/Makefile -e 's/^EXTRAVERSION.*$$/EXTRAVERSION=${EXTRAVERSION}/'
	touch $@

e1000e.ko e1000e: .compile_mark ${E1000ESRC}
	rm -rf ${E1000EDIR}
	tar xf ${E1000ESRC}
	[ ! -e /lib/modules/${KVNAME}/build ] || (echo "please remove /lib/modules/${KVNAME}/build" && false)
	cd ${E1000EDIR}; patch -p1 < ../intel-module-gcc6-compat.patch
	cd ${E1000EDIR}; patch -p1 < ../e1000e_4.10_compat.patch
	cd ${E1000EDIR}; patch -p1 < ../e1000e_4.10_max-mtu.patch
	cd ${E1000EDIR}/src; make BUILD_KERNEL=${KVNAME} KSRC=${TOP}/${KERNEL_SRC}
	cp ${E1000EDIR}/src/e1000e.ko e1000e.ko

igb.ko igb: .compile_mark ${IGBSRC}
	rm -rf ${IGBDIR}
	tar xf ${IGBSRC}
	[ ! -e /lib/modules/${KVNAME}/build ] || (echo "please remove /lib/modules/${KVNAME}/build" && false)
	cd ${IGBDIR}; patch -p1 < ../intel-module-gcc6-compat.patch
	cd ${IGBDIR}; patch -p1 < ../igb_4.9_compat.patch
	cd ${IGBDIR}; patch -p1 < ../igb_4.10_compat.patch
	cd ${IGBDIR}; patch -p1 < ../igb_4.10_max-mtu.patch
	cd ${IGBDIR}/src; make BUILD_KERNEL=${KVNAME} KSRC=${TOP}/${KERNEL_SRC}
	cp ${IGBDIR}/src/igb.ko igb.ko

ixgbe.ko ixgbe: .compile_mark ${IXGBESRC}
	rm -rf ${IXGBEDIR}
	tar xf ${IXGBESRC}
	[ ! -e /lib/modules/${KVNAME}/build ] || (echo "please remove /lib/modules/${KVNAME}/build" && false)
	cd ${IXGBEDIR}; patch -p1 < ../ixgbe_4.10_compat.patch
	cd ${IXGBEDIR}; patch -p1 < ../ixgbe_4.10_max-mtu.patch
	cd ${IXGBEDIR}/src; make CFLAGS_EXTRA="-DIXGBE_NO_LRO" BUILD_KERNEL=${KVNAME} KSRC=${TOP}/${KERNEL_SRC}
	cp ${IXGBEDIR}/src/ixgbe.ko ixgbe.ko

$(SPL_KO_REST): $(SPL_KO)
$(SPL_KO): .compile_mark ${SPLSRC}
	rm -rf ${SPLDIR}
	rsync -ra ${SPLSRC}/ ${SPLDIR}
	[ ! -e /lib/modules/${KVNAME}/build ] || (echo "please remove /lib/modules/${KVNAME}/build" && false)
	cd ${SPLDIR}; ./autogen.sh
	cd ${SPLDIR}; ./configure --with-config=kernel --with-linux=${TOP}/${KERNEL_SRC} --with-linux-obj=${TOP}/${KERNEL_SRC}
	cd ${SPLDIR}; make
	cp ${SPLDIR}/module/spl/spl.ko spl.ko
	cp ${SPLDIR}/module/splat/splat.ko splat.ko

$(ZFS_KO_REST): $(ZFS_KO)
$(ZFS_KO): .compile_mark ${ZFSSRC}
	rm -rf ${ZFSDIR}
	rsync -ra ${ZFSSRC}/ ${ZFSDIR}
	[ ! -e /lib/modules/${KVNAME}/build ] || (echo "please remove /lib/modules/${KVNAME}/build" && false)
	cd ${ZFSDIR}; ./autogen.sh
	cd ${ZFSDIR}; ./configure --with-spl=${TOP}/${SPLDIR} --with-spl-obj=${TOP}/${SPLDIR} --with-config=kernel --with-linux=${TOP}/${KERNEL_SRC} --with-linux-obj=${TOP}/${KERNEL_SRC}
	cd ${ZFSDIR}; make
	cp ${ZFSDIR}/module/zfs/zfs.ko zfs.ko
	cp ${ZFSDIR}/module/avl/zavl.ko zavl.ko
	cp ${ZFSDIR}/module/nvpair/znvpair.ko znvpair.ko
	cp ${ZFSDIR}/module/unicode/zunicode.ko zunicode.ko
	cp ${ZFSDIR}/module/zcommon/zcommon.ko zcommon.ko
	cp ${ZFSDIR}/module/zpios/zpios.ko zpios.ko

headers_tmp := $(CURDIR)/tmp-headers
headers_dir := $(headers_tmp)/usr/src/linux-headers-${KVNAME}

hdr: $(HDR_DEB)
${HDR_DEB}: .compile_mark headers-control.in headers-postinst.in
	rm -rf $(headers_tmp)
	install -d $(headers_tmp)/DEBIAN $(headers_dir)/include/
	sed -e 's/@KERNEL_VER@/${KERNEL_VER}/' -e 's/@KVNAME@/${KVNAME}/' -e 's/@PKGREL@/${PKGREL}/' -e 's/@ARCH@/${ARCH}/' <headers-control.in >$(headers_tmp)/DEBIAN/control
	sed -e 's/@@KVNAME@@/${KVNAME}/g'  <headers-postinst.in >$(headers_tmp)/DEBIAN/postinst
	chmod 0755 $(headers_tmp)/DEBIAN/postinst
	install -D -m 644 copyright $(headers_tmp)/usr/share/doc/${HDRPACKAGE}/copyright
	install -D -m 644 changelog.Debian $(headers_tmp)/usr/share/doc/${HDRPACKAGE}/changelog.Debian
	echo "git clone git://git.proxmox.com/git/pve-kernel.git\\ngit checkout ${GITVERSION}" > $(headers_tmp)/usr/share/doc/${HDRPACKAGE}/SOURCE
	gzip -n -f --best $(headers_tmp)/usr/share/doc/${HDRPACKAGE}/changelog.Debian
	install -m 0644 ${KERNEL_SRC}/.config $(headers_dir)
	install -m 0644 ${KERNEL_SRC}/Module.symvers $(headers_dir)
	cd ${KERNEL_SRC}; find . -path './debian/*' -prune -o -path './include/*' -prune -o -path './Documentation' -prune \
	  -o -path './scripts' -prune -o -type f \
	  \( -name 'Makefile*' -o -name 'Kconfig*' -o -name 'Kbuild*' -o \
	     -name '*.sh' -o -name '*.pl' \) \
	  -print | cpio -pd --preserve-modification-time $(headers_dir)
	cd ${KERNEL_SRC}; cp -a include scripts $(headers_dir)
	cd ${KERNEL_SRC}; (find arch/${KERNEL_ARCH} -name include -type d -print | \
		xargs -n1 -i: find : -type f) | \
		cpio -pd --preserve-modification-time $(headers_dir)
	mkdir -p ${headers_tmp}/lib/modules/${KVNAME}
	ln -sf /usr/src/linux-headers-${KVNAME} ${headers_tmp}/lib/modules/${KVNAME}/build
	dpkg-deb --build $(headers_tmp) ${HDR_DEB}
	#lintian ${HDR_DEB}

.PHONY: upload
upload: ${DEBS}
	tar cf - ${DEBS}|ssh repoman@repo.proxmox.com -- upload --product pve --dist stretch --arch ${ARCH}

.PHONY: distclean
distclean: clean
	rm -rf linux-firmware.git dvb-firmware.git ${KERNEL_SRC}.org 

# upgrade to current master
.PHONY: update_modules
update_modules: submodules
	git submodule foreach 'git pull --ff-only origin master'

# make sure submodules were initialized
.PHONY: submodules
submodules:
	test -f "${KERNEL_SRC_SUBMODULE}/README" || git submodule update --init
	test -f "${ZFSSRC}/debian/changelog" || git submodule update --init
	test -f "${SPLSRC}/debian/changelog" || git submodule update --init


.PHONY: clean
clean:
	rm -rf *~ .compile_mark watchdog-blacklist.tmp ${KERNEL_CFG_ORG} ${KERNEL_SRC} ${KERNEL_SRC}.tmp ${KERNEL_CFG_ORG} ${KERNEL_SRC}.org orig tmp data proxmox-ve/data *.deb ${headers_tmp} fwdata fwlist.tmp *.ko abi-${KVNAME} fwlist-${KVNAME} ${ZFSDIR} ${SPLDIR} ${SPL_MODULES} ${ZFS_MODULES} hpsa.ko ${HPSADIR} ${DRBDDIR} drbd-9.0 ${IGBDIR} igb.ko ${IXGBEDIR} ixgbe.ko ${E1000EDIR} e1000e.ko linux-tools ${LINUX_TOOLS_DEB}





