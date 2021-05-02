#!/bin/bash
# Script to prepare update for new kernel release
set -e
set -o pipefail

LINUX_REPOSITORY=linux
LINUX_VERSION_PREVIOUS=$(scripts/version.sh -L)

while getopts "R:t:v:r:h" OPTION; do
    case $OPTION in
    R)
        LINUX_REPOSITORY=$OPTARG
        ;;
    t)
        LINUX_TAG=$OPTARG
        ;;
    v)
        LINUX_VERSION=$OPTARG
        ;;
    r)
        LINUX_PACKAGE_RELEASE=$OPTARG
        ;;
    h)
        echo "update.sh -Rrtvh"
        echo "  -R  path to Linux Git repository"
        echo "  -t  tag in Linux Git repository to pick"
        echo "  -v  manual version for this kernel"
        echo "  -r  manual release version for this kernel"
        echo "  -h  this help message"
        exit 1
        ;;
    *)
        echo "Incorrect options provided"
        exit 1
        ;;
    esac
done

# Fetch from Git repository
echo "Fetching $LINUX_TAG from Linux Git repository..."

git --git-dir $LINUX_REPOSITORY/.git fetch origin --depth 1 $LINUX_TAG
git --git-dir $LINUX_REPOSITORY/.git checkout FETCH_HEAD

if [[ -z "$LINUX_VERSION" ]]; then
    # Parse the Linux version from the Linux repository if it not provided by the user
    LINUX_VERSION=$(scripts/version.sh -L)
fi

echo "Using Linux $LINUX_VERSION."

# Prepare Debian changelog
sed -e "s/@KVNAME@/$LINUX_VERSION/g" -e "s/@KVMAJMIN@/$LINUX_VERSION_MAJOR.$LINUX_VERSION_MINOR/g" < debian/templates/control.in > debian/control

LINUX_VERSION_MAJOR=$(echo $LINUX_VERSION | cut -d. -f1)
LINUX_VERSION_MINOR=$(echo $LINUX_VERSION | cut -d. -f2)
LINUX_VERSION_PATCH=$(echo $LINUX_VERSION | cut -d. -f3)
LINUX_VERSION_PATCH=${LINUX_VERSION_PATCH:-0} # Default to 0

LINUX_PACKAGE_RELEASE_PREVIOUS=$(scripts/version.sh -r)

# Check whether we need to increment the package release
if [[ -n $LINUX_PACKAGE_RELEASE ]]; then
    echo "Using custom package release $LINUX_PACKAGE_RELEASE"
elif [[ $LINUX_VERSION == "$LINUX_VERSION_PREVIOUS" ]]; then
    LINUX_PACKAGE_RELEASE=$((LINUX_PACKAGE_RELEASE_PREVIOUS + 1))
    echo "Incrementing package release to $LINUX_PACKAGE_RELEASE"
else
    LINUX_PACKAGE_RELEASE=1
    echo "New package release"
fi

echo "Updating crack.bundle..."
wget https://kernel.ubuntu.com/~kernel-ppa/mainline/v$LINUX_VERSION/crack.bundle -O crack.bundle

echo "Generating entry for change log..."
# Generate a changelog entry
debchange -v $LINUX_VERSION-$LINUX_PACKAGE_RELEASE -D edge --force-distribution -U -M "Update to Linux $LINUX_VERSION."

echo "Cleaning up"
rm -f debian/control

