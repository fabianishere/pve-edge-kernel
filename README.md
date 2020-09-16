# Proxmox Edge kernels
Custom Linux kernels for Promox VE 6.

#### Versions
1. Linux 5.6
2. Linux 5.7
3. Linux 5.8

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
In case you are building a kernel version >= 5.8, make sure you have installed at least [dwarves >= 1.16.0](https://packages.debian.org/bullseye/dwarves).
Unfortunately, this version is currently only available in the Debian Testing and Debian Unstable repositories. To work around this issue, we describe two options:

1. You may add the Debian Testing repository to your APT sources as described [here](https://serverfault.com/a/382101) and install the newer `dwarves` package as follows:
```shell
apt install -t testing dwarves
```
2. Alternatively, you may [download](https://packages.debian.org/bullseye/dwarves) the newer `dwarves` (>= 1.16) package from the Debian website and install the package manually, for example:
```shell
wget http://ftp.us.debian.org/debian/pool/main/d/dwarves-dfsg/dwarves_1.17-1_amd64.deb
apt install ./dwarves_1.17-1_amd64.deb
```

#### Obtaining the source
```bash
git clone https://github.com/fabianishere/pve-edge-kernel
cd pve-ede-kernel
git submodule update --init --depth=1 --recursive submodules/ubuntu-mainline
git submodule update --init --recursive
```
Afterwards, select the branch of your likings (e.g. `v5.8.x`).

#### Building
Invoking the following command will build the kernel and its associated packages:
```bash
make
```
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

## Questions
If you have any questions or want to see additional versions, flavors or micro architectures being built, feel
free to open an issue on Github.
