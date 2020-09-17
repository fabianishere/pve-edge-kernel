#!/bin/bash
# Script for parsing version information in the repository
set -e 
set -o pipefail

LINUX_REPOSITORY=submodules/ubuntu-mainline
LINUX_VERSION_MAJOR=$(sed -n "s/^KERNEL_MAJ=\([0-9]*$\)/\1/p" < Makefile | xargs)
LINUX_VERSION_MINOR=$(sed -n "s/^KERNEL_MIN=\([0-9]*$\)/\1/p" < Makefile | xargs)
LINUX_VERSION_PATCHLEVEL=$(sed -n "s/^KERNEL_PATCHLEVEL=\([0-9]*$\)/\1/p" < Makefile | xargs)
LINUX_VERSION_PATCHLEVEL=${LINUX_VERSION_PATCHLEVEL:-0}
LINUX_VERSION=$LINUX_VERSION_MAJOR.$LINUX_VERSION_MINOR.$LINUX_VERSION_PATCHLEVEL
LINUX_PACKAGE_RELEASE=$(sed -n "s/^PKGREL=\(.*\)$/\1/p" < Makefile | xargs)
LINUX_FLAVOR=$(sed -n "s/^PVE_BUILD_TYPE ?=\(.*\)$/\1/p" < Makefile | xargs)

while getopts "MmprfdLBh" OPTION; do
    case $OPTION in
    M)
        echo $LINUX_VERSION_MAJOR
        exit 0
        ;;

    m)
        echo $LINUX_VERSION_MINOR
        exit 0
        ;; 
    p)
        echo $LINUX_VERSION_PATCHLEVEL
        exit 0
        ;; 
    r)
        echo $LINUX_PACKAGE_RELEASE
        exit 0
        ;;
    f)
        echo $LINUX_FLAVOR
        exit 0
        ;; 
    f)
        echo $LINUX_FLAVOR
        exit 0
        ;;
    L)
        echo $LINUX_VERSION
        exit 0
        ;;
    B)
        echo $(git --git-dir $LINUX_REPOSITORY/.git log -1 --pretty=%B | sed -n "s/^.*Ubuntu-\([0-9.-]*\).*$/\1/p")
        exit 0
        ;;
    h)
        echo "commit.sh [-Mmprfh]]"
        echo "  -M  major version"
        echo "  -m  minor version"
        echo "  -p  patch version"
        echo "  -r  package release"
        echo "  -f  flavor name"
        echo "  -L  Linux version"
        echo "  -h  this help message"
        exit 1
        ;;
    *)
        echo "Incorrect options provided"
        exit 1
        ;;
    esac
done

if [[ -z "$LINUX_FLAVOR" ]]; then
    LINUX_FLAVOR_SUFFIX=-$LINUX_FLAVOR
fi

echo "$LINUX_VERSION$LINUX_FLAVOR_SUFFIX-$LINUX_PACKAGE_RELEASE"
