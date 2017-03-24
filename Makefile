RELEASE=5.0

# also update proxmox-ve/changelog if you change KERNEL_VER or KREL
KERNEL_VER=4.10.1
PKGREL=2
# also include firmware of previous version into
# the fw package:  fwlist-2.6.32-PREV-pve
KREL=2

KERNEL_SRC=ubuntu-zesty
KERNEL_SRC_SUBMODULE=submodules/ubuntu-zesty

EXTRAVERSION=-${KREL}-pve
KVNAME=${KERNEL_VER}${EXTRAVERSION}
PACKAGE=pve-kernel-${KVNAME}
HDRPACKAGE=pve-headers-${KVNAME}

ARCH=amd64
GITVERSION:=$(shell cat .git/refs/heads/master)
CHANGELOG_DATE:=$(shell dpkg-parsechangelog -SDate -lchangelog.Debian)

SKIPABI=0

TOP=$(shell pwd)

KERNEL_CFG_ORG=config-${KERNEL_VER}.org

E1000EDIR=e1000e-3.3.5.3
E1000ESRC=${E1000EDIR}.tar.gz

IGBDIR=igb-5.3.5.4
IGBSRC=${IGBDIR}.tar.gz

IXGBEDIR=ixgbe-5.0.4
IXGBESRC=${IXGBEDIR}.tar.gz

# does not compile with kernel 3.19.8
#I40EDIR=i40e-1.2.38
#I40ESRC=${I40EDIR}.tar.gz

# looks up to date with kernel 3.19.8
#BNX2DIR=netxtreme2-7.11.05
#BNX2SRC=${BNX2DIR}.tar.gz

# does not compile with kernel 3.19.8
#AACRAIDVER=1.2.1-40700
#AACRAIDDIR=aacraid-${AACRAIDVER}.src
#AACRAIDSRC=aacraid-linux-src-${AACRAIDVER}.tgz

# does not compile with kernel 3.19.8
HPSAVER=3.4.8
HPSADIR=hpsa-${HPSAVER}
HPSASRC=${HPSADIR}-140.tar.bz2

# driver does not compile
#MEGARAID_DIR=megaraid_sas-06.703.11.00
#MEGARAID_SRC=${MEGARAID_DIR}-src.tar.gz

#ARECADIR=arcmsr-1.30.0X.19-140509
#ARECASRC=${ARECADIR}.zip

# this one does not compile with newer 3.10 kernels!
#RR272XSRC=RR272x_1x-Linux-Src-v1.5-130325-0732.tar.gz
#RR272XDIR=rr272x_1x-linux-src-v1.5

SPLDIR=pkg-spl
SPLSRC=submodules/zfs/pkg-spl.tar.gz
ZFSDIR=pkg-zfs
ZFSSRC=submodules/zfs/pkg-zfs.tar.gz
ZFS_MODULES=zfs.ko zavl.ko znvpair.ko zunicode.ko zcommon.ko zpios.ko
SPL_MODULES=spl.ko splat.ko

# DRBD9
#DRBDVER=9.0.6-1
#DRBDDIR=drbd-${DRBDVER}
#DRBDSRC=${DRBDDIR}.tar.gz
#DRBD_MODULES=drbd.ko drbd_transport_tcp.ko

DST_DEB=${PACKAGE}_${KERNEL_VER}-${PKGREL}_${ARCH}.deb
HDR_DEB=${HDRPACKAGE}_${KERNEL_VER}-${PKGREL}_${ARCH}.deb
PVEPKG=proxmox-ve
PVE_DEB=${PVEPKG}_${RELEASE}-${PKGREL}_all.deb
VIRTUALHDRPACKAGE=pve-headers
VIRTUAL_HDR_DEB=${VIRTUALHDRPACKAGE}_${RELEASE}-${PKGREL}_all.deb

LINUX_TOOLS_PKG=linux-tools-4.10
LINUX_TOOLS_DEB=${LINUX_TOOLS_PKG}_${KERNEL_VER}-${PKGREL}_amd64.deb

DEBS=${DST_DEB} ${HDR_DEB} ${PVE_DEB} ${VIRTUAL_HDR_DEB} ${LINUX_TOOLS_DEB}

all: check_gcc ${DEBS}

${PVE_DEB} pve: proxmox-ve/control proxmox-ve/postinst ${PVE_RELEASE_KEYS}
	rm -rf proxmox-ve/data
	mkdir -p proxmox-ve/data/DEBIAN
	mkdir -p proxmox-ve/data/usr/share/doc/${PVEPKG}/
	mkdir -p proxmox-ve/data/etc/apt/trusted.gpg.d
	install -m 0644 proxmox-ve/proxmox-release-4.x.pubkey proxmox-ve/data/etc/apt/trusted.gpg.d/proxmox-ve-release-4.x.gpg
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

${VIRTUAL_HDR_DEB} pve-headers: proxmox-ve/pve-headers.control
	rm -rf proxmox-ve/data
	mkdir -p proxmox-ve/data/DEBIAN
	mkdir -p proxmox-ve/data/usr/share/doc/${VIRTUALHDRPACKAGE}/
	sed -e 's/@KVNAME@/${KVNAME}/' -e 's/@KERNEL_VER@/${KERNEL_VER}/' -e 's/@RELEASE@/${RELEASE}/' -e 's/@PKGREL@/${PKGREL}/' <proxmox-ve/pve-headers.control >proxmox-ve/data/DEBIAN/control
	echo "git clone git://git.proxmox.com/git/pve-kernel-4.0.git\\ngit checkout ${GITVERSION}" > proxmox-ve/data/usr/share/doc/${VIRTUALHDRPACKAGE}/SOURCE
	install -m 0644 proxmox-ve/copyright proxmox-ve/data/usr/share/doc/${VIRTUALHDRPACKAGE}
	install -m 0644 proxmox-ve/changelog.Debian proxmox-ve/data/usr/share/doc/${VIRTUALHDRPACKAGE}
	gzip -n --best proxmox-ve/data/usr/share/doc/${VIRTUALHDRPACKAGE}/changelog.Debian
	dpkg-deb --build proxmox-ve/data ${VIRTUAL_HDR_DEB}

check_gcc: 
ifeq    ($(CC), cc)
	gcc --version|grep "6\.3" || false
else
	$(CC) --version|grep "6\.3" || false
endif

${DST_DEB}: data control.in prerm.in postinst.in postrm.in copyright changelog.Debian fwcheck abicheck
	mkdir -p data/DEBIAN
	sed -e 's/@KERNEL_VER@/${KERNEL_VER}/' -e 's/@KVNAME@/${KVNAME}/' -e 's/@PKGREL@/${PKGREL}/' <control.in >data/DEBIAN/control
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
	mkdir -p linux-tools/debian/linux-tools-4.10/usr/bin
	install -m 0755 ${KERNEL_SRC}/tools/perf/perf linux-tools/debian/linux-tools-4.10/usr/bin/perf_4.10
	cd linux-tools; for i in ${LINUX_TOOLS_DH_LIST}; do dh_$$i; done
	lintian ${LINUX_TOOLS_DEB}

fwlist-${KVNAME}: data
	./find-firmware.pl data/lib/modules/${KVNAME} >fwlist.tmp
	mv fwlist.tmp $@

fwcheck: fwlist-${KVNAME} fwlist-previous
	echo "checking fwlist for changes since last built firmware package.."
	echo "if this check fails, add fwlist-${KVNAME} to the pve-firmware repository and upload a new firmware package together with the ${KVNAME} kernel"
	bash -c "diff -up -N <(sort fwlist-previous | uniq) <(sort fwlist-${KVNAME} | uniq) > fwlist.diff"
	rm fwlist.diff

abi-${KVNAME}: .compile_mark
	sed -e 's/^\(.\+\)[[:space:]]\+\(.\+\)[[:space:]]\(.\+\)$$/\3 \2 \1/' ${KERNEL_SRC}/Module.symvers | sort > abi-${KVNAME}

abicheck: abi-${KVNAME} abi-current abi-blacklist
	./abi-check abi-${KVNAME} abi-current ${SKIPABI}

data: .compile_mark igb.ko ixgbe.ko e1000e.ko ${SPL_MODULES} ${ZFS_MODULES}
	rm -rf data tmp; mkdir -p tmp/lib/modules/${KVNAME}
	mkdir tmp/boot
	install -m 644 ${KERNEL_SRC}/.config tmp/boot/config-${KVNAME}
	install -m 644 ${KERNEL_SRC}/System.map tmp/boot/System.map-${KVNAME}
	install -m 644 ${KERNEL_SRC}/arch/x86_64/boot/bzImage tmp/boot/vmlinuz-${KVNAME}
	cd ${KERNEL_SRC}; make INSTALL_MOD_PATH=../tmp/ modules_install
	## install latest ibg driver
	install -m 644 igb.ko tmp/lib/modules/${KVNAME}/kernel/drivers/net/ethernet/intel/igb/
	# install latest ixgbe driver
	install -m 644 ixgbe.ko tmp/lib/modules/${KVNAME}/kernel/drivers/net/ethernet/intel/ixgbe/
	# install latest e1000e driver
	install -m 644 e1000e.ko tmp/lib/modules/${KVNAME}/kernel/drivers/net/ethernet/intel/e1000e/
	## install hpsa driver
	#install -m 644 hpsa.ko tmp/lib/modules/${KVNAME}/kernel/drivers/scsi/
	# install zfs drivers
	install -d -m 0755 tmp/lib/modules/${KVNAME}/zfs
	install -m 644 ${SPL_MODULES} ${ZFS_MODULES} tmp/lib/modules/${KVNAME}/zfs
	# install drbd9
	#install -m 644 ${DRBD_MODULES} tmp/lib/modules/${KVNAME}/kernel/drivers/block/drbd
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
--set-str CONFIG_DEFAULT_IOSCHED deadline \
-e CONFIG_MODVERSIONS \
-d CONFIG_DEFAULT_SECURITY_DAC \
-e CONFIG_DEFAULT_SECURITY_APPARMOR \
--set-str CONFIG_DEFAULT_SECURITY apparmor

.compile_mark: ${KERNEL_SRC}/README ${KERNEL_CFG_ORG}
	cp ${KERNEL_CFG_ORG} ${KERNEL_SRC}/.config
	cd ${KERNEL_SRC}; ./scripts/config ${PVE_CONFIG_OPTS}
	cd ${KERNEL_SRC}; make oldconfig
	cd ${KERNEL_SRC}; make KBUILD_BUILD_VERSION_TIMESTAMP="PVE ${KERNEL_VER}-${PKGREL} ($(CHANGELOG_DATE))" -j 8
	make -C ${KERNEL_SRC}/tools/perf prefix=/usr HAVE_CPLUS_DEMANGLE=1 NO_LIBPYTHON=1 NO_LIBPERL=1 NO_LIBCRYPTO=1 PYTHON=python2.7
	make -C ${KERNEL_SRC}/tools/perf man
	touch $@

${KERNEL_SRC}/README ${KERNEL_CFG_ORG}: ${KERNEL_SRC_SUBMODULE} | submodules
	rm -rf ${KERNEL_SRC}
	cp -a ${KERNEL_SRC_SUBMODULE} ${KERNEL_SRC}
	cat ${KERNEL_SRC}/debian.master/config/config.common.ubuntu ${KERNEL_SRC}/debian.master/config/amd64/config.common.amd64 ${KERNEL_SRC}/debian.master/config/amd64/config.flavour.generic > ${KERNEL_CFG_ORG}
	cd ${KERNEL_SRC}; patch -p1 < ../uname-version-timestamp.patch
	cd ${KERNEL_SRC}; patch -p1 <../bridge-patch.diff
	#cd ${KERNEL_SRC}; patch -p1 <../bridge-forward-ipv6-neighbor-solicitation.patch
	#cd ${KERNEL_SRC}; patch -p1 <../add-empty-ndo_poll_controller-to-veth.patch
	cd ${KERNEL_SRC}; patch -p1 <../override_for_missing_acs_capabilities.patch
	#cd ${KERNEL_SRC}; patch -p1 <../vhost-net-extend-device-allocation-to-vmalloc.patch
	cd ${KERNEL_SRC}; patch -p1 < ../kvm-dynamic-halt-polling-disable-default.patch
	cd ${KERNEL_SRC}; patch -p1 < ../cgroup-cpuset-add-cpuset.remap_cpus.patch
	cd ${KERNEL_SRC}; patch -p1 < ../CVE-2017-2596-kvm-page-reference-leakage-in-handle_vmon.patch
	sed -i ${KERNEL_SRC}/Makefile -e 's/^EXTRAVERSION.*$$/EXTRAVERSION=${EXTRAVERSION}/'
	touch $@

aacraid.ko: .compile_mark ${AACRAIDSRC}
	rm -rf ${AACRAIDDIR}
	mkdir ${AACRAIDDIR}
	cd ${AACRAIDDIR};tar xzf ../${AACRAIDSRC}
	cd ${AACRAIDDIR};rpm2cpio aacraid-${AACRAIDVER}.src.rpm|cpio -i
	cd ${AACRAIDDIR};tar xf aacraid_source.tgz
	[ ! -e /lib/modules/${KVNAME}/build ] || rm /lib/modules/${KVNAME}/build
	make -C ${TOP}/${KERNEL_SRC} M=${TOP}/${AACRAIDDIR} KSRC=${TOP}/${KERNEL_SRC} modules
	cp ${AACRAIDDIR}/aacraid.ko .

hpsa.ko hpsa: .compile_mark ${HPSASRC}
	rm -rf ${HPSADIR}
	tar xf ${HPSASRC}
#	sed -i ${HPSADIR}/drivers/scsi/hpsa_kernel_compat.h -e 's/^\/\* #define RHEL7.*/#define RHEL7/'
	[ ! -e /lib/modules/${KVNAME}/build ] || rm /lib/modules/${KVNAME}/build
	make -C ${TOP}/${KERNEL_SRC} M=${TOP}/${HPSADIR}/drivers/scsi KSRC=${TOP}/${KERNEL_SRC} modules
	cp ${HPSADIR}/drivers/scsi/hpsa.ko hpsa.ko

e1000e.ko e1000e: .compile_mark ${E1000ESRC}
	rm -rf ${E1000EDIR}
	tar xf ${E1000ESRC}
	[ ! -e /lib/modules/${KVNAME}/build ] || rm /lib/modules/${KVNAME}/build
	cd ${E1000EDIR}; patch -p1 < ../intel-module-gcc6-compat.patch
	cd ${E1000EDIR}; patch -p1 < ../e1000e_4.10_compat.patch
	cd ${E1000EDIR}/src; make BUILD_KERNEL=${KVNAME} KSRC=${TOP}/${KERNEL_SRC}
	cp ${E1000EDIR}/src/e1000e.ko e1000e.ko

igb.ko igb: .compile_mark ${IGBSRC}
	rm -rf ${IGBDIR}
	tar xf ${IGBSRC}
	[ ! -e /lib/modules/${KVNAME}/build ] || rm /lib/modules/${KVNAME}/build
	cd ${IGBDIR}; patch -p1 < ../intel-module-gcc6-compat.patch
	cd ${IGBDIR}; patch -p1 < ../igb_4.9_compat.patch
	cd ${IGBDIR}; patch -p1 < ../igb_4.10_compat.patch
	cd ${IGBDIR}/src; make BUILD_KERNEL=${KVNAME} KSRC=${TOP}/${KERNEL_SRC}
	cp ${IGBDIR}/src/igb.ko igb.ko

ixgbe.ko ixgbe: .compile_mark ${IXGBESRC}
	rm -rf ${IXGBEDIR}
	tar xf ${IXGBESRC}
	[ ! -e /lib/modules/${KVNAME}/build ] || rm /lib/modules/${KVNAME}/build
	cd ${IXGBEDIR}; patch -p1 < ../ixgbe_4.10_compat.patch
	cd ${IXGBEDIR}/src; make CFLAGS_EXTRA="-DIXGBE_NO_LRO" BUILD_KERNEL=${KVNAME} KSRC=${TOP}/${KERNEL_SRC}
	cp ${IXGBEDIR}/src/ixgbe.ko ixgbe.ko

i40e.ko i40e: .compile_mark ${I40ESRC}
	rm -rf ${I40EDIR}
	tar xf ${I40ESRC}
	[ ! -e /lib/modules/${KVNAME}/build ] || rm /lib/modules/${KVNAME}/build
	cd ${I40EDIR}/src; make BUILD_KERNEL=${KVNAME} KSRC=${TOP}/${KERNEL_SRC}
	cp ${I40EDIR}/src/i40e.ko i40e.ko

bnx2.ko cnic.ko bnx2x.ko: ${BNX2SRC}
	rm -rf ${BNX2DIR}
	tar xf ${BNX2SRC}
	[ ! -e /lib/modules/${KVNAME}/build ] || rm /lib/modules/${KVNAME}/build
	cd ${BNX2DIR}; make -C bnx2/src KVER=${KVNAME} KSRC=${TOP}/${KERNEL_SRC}
	cd ${BNX2DIR}; make -C bnx2x/src KVER=${KVNAME} KSRC=${TOP}/${KERNEL_SRC}
	cp `find ${BNX2DIR} -name bnx2.ko -o -name cnic.ko -o -name bnx2x.ko` .

arcmsr.ko: .compile_mark ${ARECASRC}
	rm -rf ${ARECADIR}
	mkdir ${ARECADIR}; cd ${ARECADIR}; unzip ../${ARECASRC}
	[ ! -e /lib/modules/${KVNAME}/build ] || rm /lib/modules/${KVNAME}/build
	cd ${ARECADIR}; make -C ${TOP}/${KERNEL_SRC} SUBDIRS=${TOP}/${ARECADIR} KSRC=${TOP}/${KERNEL_SRC} modules
	cp ${ARECADIR}/arcmsr.ko arcmsr.ko

${SPL_MODULES}: .compile_mark ${SPLSRC}
	rm -rf ${SPLDIR}
	tar xf ${SPLSRC}
	cd ${SPLDIR}; ./autogen.sh
	cd ${SPLDIR}; ./configure --with-config=kernel --with-linux=${TOP}/${KERNEL_SRC} --with-linux-obj=${TOP}/${KERNEL_SRC}
	cd ${SPLDIR}; make
	cp ${SPLDIR}/module/spl/spl.ko spl.ko
	cp ${SPLDIR}/module/splat/splat.ko splat.ko

${ZFS_MODULES}: .compile_mark ${ZFSSRC}
	rm -rf ${ZFSDIR}
	tar xf ${ZFSSRC}
	cd ${ZFSDIR}; ./autogen.sh
	cd ${ZFSDIR}; ./configure --with-spl=${TOP}/${SPLDIR} --with-spl-obj=${TOP}/${SPLDIR} --with-config=kernel --with-linux=${TOP}/${KERNEL_SRC} --with-linux-obj=${TOP}/${KERNEL_SRC}
	cd ${ZFSDIR}; make
	cp ${ZFSDIR}/module/zfs/zfs.ko zfs.ko
	cp ${ZFSDIR}/module/avl/zavl.ko zavl.ko
	cp ${ZFSDIR}/module/nvpair/znvpair.ko znvpair.ko
	cp ${ZFSDIR}/module/unicode/zunicode.ko zunicode.ko
	cp ${ZFSDIR}/module/zcommon/zcommon.ko zcommon.ko
	cp ${ZFSDIR}/module/zpios/zpios.ko zpios.ko

#.PHONY: update-drbd
#update-drbd:
#	rm -rf ${DRBDDIR} ${DRBDSRC} drbd-9.0
#	git clone --recursive git://git.drbd.org/drbd-9.0
#	cd drbd-9.0; make tarball
#	mv drbd-9.0/${DRBDSRC} ${DRBDSRC} 
#
#.PHONY: drbd
#drbd ${DRBD_MODULES}: .compile_mark ${DRBDSRC}
#	rm -rf ${DRBDDIR}
#	tar xzf ${DRBDSRC}
#	[ ! -e /lib/modules/${KVNAME}/build ] || rm /lib/modules/${KVNAME}/build
#	cd ${DRBDDIR}; make KVER=${KVNAME} KDIR=${TOP}/${KERNEL_SRC}
#	mv ${DRBDDIR}/drbd/drbd.ko drbd.ko
#	mv ${DRBDDIR}/drbd/drbd_transport_tcp.ko drbd_transport_tcp.ko

#iscsi_trgt.ko: .compile_mark ${ISCSITARGETSRC}
#	rm -rf ${ISCSITARGETDIR}
#	tar xf ${ISCSITARGETSRC}
#	cd ${ISCSITARGETDIR}; make KSRC=${TOP}/${KERNEL_SRC}
#	cp ${ISCSITARGETDIR}/kernel/iscsi_trgt.ko iscsi_trgt.ko

headers_tmp := $(CURDIR)/tmp-headers
headers_dir := $(headers_tmp)/usr/src/linux-headers-${KVNAME}

${HDR_DEB} hdr: .compile_mark headers-control.in headers-postinst.in
	rm -rf $(headers_tmp)
	install -d $(headers_tmp)/DEBIAN $(headers_dir)/include/
	sed -e 's/@KERNEL_VER@/${KERNEL_VER}/' -e 's/@KVNAME@/${KVNAME}/' -e 's/@PKGREL@/${PKGREL}/' <headers-control.in >$(headers_tmp)/DEBIAN/control
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
	cd ${KERNEL_SRC}; (find arch/x86 -name include -type d -print | \
		xargs -n1 -i: find : -type f) | \
		cpio -pd --preserve-modification-time $(headers_dir)
	mkdir -p ${headers_tmp}/lib/modules/${KVNAME}
	ln -sf /usr/src/linux-headers-${KVNAME} ${headers_tmp}/lib/modules/${KVNAME}/build
	dpkg-deb --build $(headers_tmp) ${HDR_DEB}
	#lintian ${HDR_DEB}

dvb-firmware.git/README:
	git clone https://github.com/OpenELEC/dvb-firmware.git dvb-firmware.git

linux-firmware.git/WHENCE:
	git clone git://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git linux-firmware.git


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
submodules ${SPLSRC} ${ZFSSRC}:
	test -f "${KERNEL_SRC_SUBMODULE}/README" || git submodule update --init


.PHONY: clean
clean:
	rm -rf *~ .compile_mark watchdog-blacklist.tmp ${KERNEL_CFG_ORG} ${KERNEL_SRC} ${KERNEL_SRC}.tmp ${KERNEL_CFG_ORG} ${KERNEL_SRC}.org orig tmp data proxmox-ve/data *.deb ${headers_tmp} fwdata fwlist.tmp *.ko fwlist-${KVNAME} ${ZFSDIR} ${SPLDIR} ${SPL_MODULES} ${ZFS_MODULES} hpsa.ko ${HPSADIR} ${DRBDDIR} drbd-9.0 ${IGBDIR} igb.ko ${IXGBEDIR} ixgbe.ko ${E1000EDIR} e1000e.ko linux-tools ${LINUX_TOOLS_DEB}





