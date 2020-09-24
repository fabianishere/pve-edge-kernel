#1/bin/bash
# Script to prepare update for new kernel release
set -e 
set -o pipefail

LINUX_REPOSITORY=submodules/ubuntu-mainline

while getopts "R:t:b:v:r:h" OPTION; do
    case $OPTION in
    R)
        LINUX_REPOSITORY=$OPTARG
        ;;
    t)
        LINUX_TAG=$OPTARG
        ;;
    b)
        LINUX_BASE=$OPTARG
        ;;
    v)
        LINUX_VERSION=$OPTARG
        ;;
    r)
        LINUX_PACKAGE_RELEASE=$OPTARG
        ;;
    h)
        echo "update.sh -rtbh"
        echo "  -R  path to Linux Git repository"
        echo "  -t  tag in Linux Git repository to pick"
        echo "  -b  manual basis for this kernel"
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

if [[ -z "$LINUX_BASE" ]]; then
    # Parse the Ubuntu base from which our build is derived
    UBUNTU_BASE=$(git --git-dir $LINUX_REPOSITORY/.git log -1 --pretty=%B | sed -n "s/^.*Ubuntu-\([0-9.-]*\).*$/\1/p")
    LINUX_BASE="Ubuntu $UBUNTU_BASE"
fi

if [[ -z "$LINUX_VERSION" ]]; then
    # Parse the Linux version from the Linux repository if it not provided by the user
    LINUX_VERSION=$(dpkg-parsechangelog -l $LINUX_REPOSITORY/debian.master/changelog --show-field Version | sed -n "s/^\([0-9.]*\).*$/\1/p")
fi

echo "Using Linux $LINUX_VERSION based on $LINUX_BASE."

# Prepare Debian changelog
sed -e "s/@KVNAME@/$LINUX_VERSION/g" -e "s/@KVMAJMIN@/$LINUX_VERSION_MAJOR.$LINUX_VERSION_MINOR/g" < debian/control.in > debian/control

LINUX_VERSION_MAJOR=$(echo $LINUX_VERSION | cut -d. -f1)
LINUX_VERSION_MINOR=$(echo $LINUX_VERSION | cut -d. -f2)
LINUX_VERSION_PATCH=$(echo $LINUX_VERSION | cut -d. -f3)
LINUX_VERSION_PATCH=${LINUX_VERSION_PATCH:-0} # Default to 0

LINUX_PACKAGE_RELEASE_PREVIOUS=$(scripts/version.sh -r)

# Check whether we need to increment the package release
if [[ -n $LINUX_PACKAGE_RELEASE ]]; then
    echo "Using custom package release $LINUX_PACKAGE_RELEASE"
elif [[ $LINUX_VERSION == "$(scripts/version.sh -L)" ]]; then
    LINUX_PACKAGE_RELEASE=$((LINUX_PACKAGE_RELEASE_PREVIOUS + 1))
    echo "Incrementing package release to $LINUX_PACKAGE_RELEASE"
else
    LINUX_PACKAGE_RELEASE=1
    echo "New package release"
fi

echo "Updating Makefile..."
# Update the Makefile with the proper version numbers
sed -i Makefile \
    -e "s/^KERNEL_MAJ=[0-9]*$/KERNEL_MAJ=$LINUX_VERSION_MAJOR/" \
    -e "s/^KERNEL_MIN=[0-9]*$/KERNEL_MIN=$LINUX_VERSION_MINOR/" \
    -e "s/^KERNEL_PATCHLEVEL=[0-9]*$/KERNEL_PATCHLEVEL=$LINUX_VERSION_PATCH/" \
    -e "s/^KREL=[0-9]*$/KREL=1/" \
    -e "s/^PKGREL=[0-9]*$/PKGREL=$LINUX_PACKAGE_RELEASE/"

echo "Generating entry for change log..."
# Generate a changelog entry
debchange -v $LINUX_VERSION-$LINUX_PACKAGE_RELEASE -D edge --force-distribution -U -M "Update to Linux $LINUX_VERSION based on $LINUX_BASE."

echo "Cleaning up"
rm -f debian/control

