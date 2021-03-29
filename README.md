# Proxmox Edge kernels
Custom Linux kernels for Promox VE 6.

#### Versions
1. Linux 5.6 (EOL)
2. Linux 5.7 (EOL)
3. Linux 5.8 (EOL)
4. Linux 5.9 (EOL)
5. Linux 5.10
6. Linux 5.11

#### Flavors
1. Proxmox
2. [Navi Reset](https://github.com/fabianishere/pve-edge-kernel/issues/5)

#### Microarchitectures
1. Generic
2. Zen 2
3. Cascade Lake

## Installation
Select from the [Releases](https://github.com/fabianishere/pve-edge-kernel/releases) page the kernel version 
you want to install and download the appropriate deb package. Then, you can install the package as follows:

```sh
apt install ./pve-edge-kernel-VERSION-MARCH_VERSION_amd64.deb
```

## AppArmor issues
When using these kernels, Proxmox's AppArmor profiles may fail to load since it uses an older AppArmor feature set
which is not supported by these kernels anymore. This issue also appears when launching LXC containers.
To fix this, tell AppArmor to use the stock features file as opposed to Proxmox's features file, which is done
by updating `/etc/apparmor/parser.conf` as follows:

```
## Pin feature set (avoid regressions when policy is lagging behind
## the kernel)
# lxc-pve diverts to old feature file that is incompatible with kernel
# features-file=/usr/share/apparmor-features/features
features-file=/usr/share/apparmor-features/features.stock
```

## Building manually
You may also choose to manually build one of these kernels yourself.

#### Prerequisites
Make sure you have at least 30GB of free space available and have the following
packages installed:

```bash
apt install devscripts asciidoc-base automake bc bison cpio dh-python flex git kmod libdw-dev libelf-dev libiberty-dev libnuma-dev libpve-common-perl libslang2-dev libssl-dev libtool lintian lz4 perl-modules python2-minimal rsync sed sphinx-common tar xmlto zlib1g-dev dwarves
```
In case you are building a kernel version >= 5.8, make sure you have installed at least [dwarves >= 1.16.0](https://packages.debian.org/buster-backports/dwarves).
Unfortunately, this version is not available in the Debian Buster repositories, so you will have to install it from the buster-backports repository:

```bash
echo deb http://ftp.de.debian.org/debian buster-backports main >> /etc/apt/sources.list
apt update
apt install dwarves=1.19-1~bpo10+1
```
Or whatever version is available in backports when you are reading this guide.

#### Obtaining the source
```bash
git clone https://github.com/fabianishere/pve-edge-kernel
cd pve-ede-kernel
git checkout v5.11.x
git submodule update --init --depth=1 --recursive submodules/ubuntu-mainline
git submodule update --init --recursive
```
You can select the branch of your likings by changing `v5.11.x`. This will automatically select the last patchversion for the minor version you have chosen. If you wan to select the patchversion too, you can check the [available tags](https://github.com/fabianishere/pve-edge-kernel/tags), for example `git checkout v5.11.8-1`.

#### Building
The Makefile provides several environmental variables to control:

1. `PVE_BUILD_FLAVOR`  
   The name of the kernel flavor which represents a selection of kernel
   functionality (e.g. [hardened](https://github.com/anthraxx/linux-hardened) or [zen](https://github.com/zen-kernel/zen-kernel)).
   This name is part of the kernel version and package name, which means that you
   can have multiple flavors of the same kernel installed alongside each other.
   Note that the name itself does not control the selection of kernel functionality.
2. `PVE_BUILD_TYPE` (default `generic`)  
   The name of the kernel build type which represents the compilation options of
   the kernel (e.g. optimization level or micro architecture).
   This name is appended as suffix to the Debian package version in case it is not
   the default value.
3. `PVE_BUILD_CC`  
   The compiler to use for the kernel build.
4. `PVE_BUILD_CFLAGS`  
   The compilation options to use for the kernel build. Use this variable to specify
   the optimization level or micro architecture to build for.

Kernel options may be controlled from the [debian/rules](debian/rules) file. To build with
additional patches, you may add them to the [patches/pve](patches/pve) directory.

Invoking the following command will build the kernel and its associated packages:
```bash
make
```

## Questions
If you have any questions or want to see additional versions, flavors or micro architectures being built, feel
free to open an issue on Github.
