## Kernel information
KERNEL_MAJMIN=$(shell ./scripts/version.sh -n)
KERNEL_VER=$(shell ./scripts/version.sh -L)

# Increment KERNEL_RELEASE if the ABI changes (abicheck target in debian/rules)
KERNEL_RELEASE=1

## Debian package information
PKG_RELEASE=$(shell ./scripts/version.sh -r)
PKG_DATE:=$(shell dpkg-parsechangelog -SDate)
PKG_GIT_VERSION:=$(shell git rev-parse HEAD)

## Build flavor
# Default to PVE flavor
PKG_BUILD_FLAVOR ?= edge
ifneq (${PKG_BUILD_FLAVOR},edge)
	_ := $(info Using custom build flavor: ${PKG_BUILD_FLAVOR})
endif

## Build profile
# Default to generic march optimizations
PKG_BUILD_PROFILE ?= generic
ifneq (${PKG_BUILD_PROFILE},generic)
	_ := $(info Using custom build profile: ${PKG_BUILD_PROFILE})
endif

# Build settings
PVE_KERNEL_CC ?= ${CC}
PVE_ZFS_CC ?= ${CC}

### Debian package names
EXTRAVERSION=-${KERNEL_RELEASE}-${PKG_BUILD_FLAVOR}
KVNAME=${KERNEL_VER}${EXTRAVERSION}

PVE_KERNEL_PKG=pve-kernel-${KVNAME}
PVE_HEADER_PKG=pve-headers-${KVNAME}
PVE_USR_HEADER_PKG=pve-kernel-libc-dev
LINUX_TOOLS_PKG=linux-tools-${KERNEL_MAJMIN}
