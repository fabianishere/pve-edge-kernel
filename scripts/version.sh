#!/bin/bash
# Script for parsing version information in the repository
set -e
set -o pipefail

LINUX_REPOSITORY=linux
LINUX_VERSION=$(sed -n "s/^VERSION = \([0-9]*$\)/\1/p" < linux/Makefile | xargs)
LINUX_PATCHLEVEL=$(sed -n "s/^PATCHLEVEL = \([0-9]*$\)/\1/p" < linux/Makefile | xargs)
LINUX_SUBLEVEL=$(sed -n "s/^SUBLEVEL = \([0-9]*$\)/\1/p" < linux/Makefile | xargs)
LINUX_VERSION_FULL=$LINUX_VERSION.$LINUX_PATCHLEVEL.$LINUX_SUBLEVEL
PACKAGE_VERSION=$(dpkg-parsechangelog -SVersion)
PACKAGE_RELEASE=$(echo $PACKAGE_VERSION | sed -n 's/^.*-\([0-9]*\).*$/\1/p' | xargs)

while getopts "MmnprdLh" OPTION; do
    case $OPTION in
    M)
        echo $LINUX_VERSION
        exit 0
        ;;
    m)
        echo $LINUX_PATCHLEVEL
        exit 0
        ;;
    n)
        echo $LINUX_VERSION.$LINUX_PATCHLEVEL
        exit 0
        ;;
    p)
        echo $LINUX_SUBLEVEL
        exit 0
        ;;
    r)
        echo $PACKAGE_RELEASE
        exit 0
        ;;
    L)
        echo $LINUX_VERSION_FULL
        exit 0
        ;;
    h)
        echo "version.sh [-Mmnprfh]"
        echo "  -M  major version"
        echo "  -m  minor version"
        echo "  -n  major minor version"
        echo "  -p  patch version"
        echo "  -r  package release"
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

echo "$PACKAGE_VERSION"
