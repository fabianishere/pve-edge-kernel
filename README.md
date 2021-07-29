# Proxmox Edge kernels
Custom Linux kernels for Proxmox VE 6.

#### Versions
1. Linux 5.13 (Stable)
1. Linux 5.12 (Stable) [EOL]
1. Linux 5.11 (Stable) [EOL]
1. Linux 5.10 (Long-term)

#### Flavors
1. Proxmox
2. [Navi Reset](https://github.com/fabianishere/pve-edge-kernel/issues/5)

## Installation
[![Hosted By: Cloudsmith](https://img.shields.io/badge/OSS%20hosting%20by-cloudsmith-blue?logo=cloudsmith&style=flat-square)](https://cloudsmith.com)

First, set up our Debian repository on your Proxmox installation: 
1. Add the repository's GPG key:
```bash
curl -1sLf 'https://dl.cloudsmith.io/public/pve-edge/kernel/gpg.8EC01CCF309B98E7.key' | apt-key add -
```
2. Set up the `pve-edge-kernel` repository:
```bash
echo "deb https://dl.cloudsmith.io/public/pve-edge/kernel/deb/debian buster main" > /etc/apt/sources.list.d/pve-edge-kernel.list
```
3. Install a kernel package:
```bash
apt update
apt install pve-kernel-5.12-edge
```

Package repository hosting is graciously provided by  [Cloudsmith](https://cloudsmith.com).
Cloudsmith is the only fully hosted, cloud-native, universal package management solution, that
enables your organization to create, store and share packages in any format, to any place, with total
confidence.

### Manual
Alternatively, you may manually install the kernels. Select from the [Releases](https://github.com/fabianishere/pve-edge-kernel/releases)
page the kernel version you want to install and download the appropriate Debian package.
Then, you can install the package as follows:

```sh
apt install ./pve-kernel-VERSION_amd64.deb
```

## AppArmor issues
When using these kernels, Proxmox's AppArmor profiles may fail to load since it
uses an older AppArmor feature set  which is not supported by these kernels anymore. 
This issue also appears when launching LXC containers.
To fix this, tell AppArmor to use the stock features file as opposed to 
Proxmox's features file, which is done by updating `/etc/apparmor/parser.conf` as follows:

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
Make sure you have at least 10 GB of free space available and have the following
packages installed:

```bash
apt install devscripts debhelper equivs git
```
In case you are building a kernel version >= 5.8, make sure you have installed
at least [dwarves >= 1.16.0](https://packages.debian.org/bullseye/dwarves).
This version is currently is not available in the main repository.
To work around this issue, we describe two options:

1. You may add the Debian Buster Backports repository to your APT sources as described
   [here](https://backports.debian.org/Instructions/) and install the
   newer `dwarves` package as follows:
   ```shell
   apt install -t buster-backports dwarves
   ```
2. Alternatively, you may [download](https://packages.debian.org/bullseye/dwarves)
   the newer `dwarves` (>= 1.16) package from the Debian website and install the
   package manually, for example:
   ```shell
   wget http://ftp.us.debian.org/debian/pool/main/d/dwarves-dfsg/dwarves_1.17-1_amd64.deb
   apt install ./dwarves_1.17-1_amd64.deb
   ```

#### Obtaining the source
Obtain the source code as follows:
```bash
git clone https://github.com/fabianishere/pve-edge-kernel
cd pve-edge-kernel
```
Then, select the branch of your likings (e.g. `v5.10.x`) and update the submodules:
```bash
git checkout v5.10.x
git submodule update --init --depth=1 --recursive linux
git submodule update --init --recursive
```

#### Building
First, generate the Debian control file for your kernel by running the following
in your command prompt:
```bash
debian/rules debian/control
```
Before we build, make sure you have installed the build dependencies:
```bash
sudo mk-build-deps -i
```
Invoking the following command will build the kernel and its associated packages:
```bash
debuild -ePVE* --jobs=auto -b -uc -us
```
The Makefile provides several environmental variables to control:

1. `PVE_BUILD_FLAVOR`  
   The name of the kernel flavor which represents a selection of kernel
   functionality (e.g. [hardened](https://github.com/anthraxx/linux-hardened) or [zen](https://github.com/zen-kernel/zen-kernel)).
   This name is part of the kernel version and package name, which means that you
   can have multiple flavors of the same kernel installed alongside each other.
   Note that the name itself does not control the selection of kernel functionality.
2. `PVE_BUILD_PROFILE` (default `generic`)  
   The name of the kernel build type which represents the compilation options of
   the kernel (e.g. optimization level or micro architecture).
   This name is appended as suffix to the Debian package version in case it is not
   the default value.
3. `PVE_KERNEL_CC`  
   The compiler to use for the kernel build.
4. `PVE_KERNEL_CFLAGS`  
   The compilation options to use for the kernel build. Use this variable to specify
   the optimization level or micro architecture to build for.

Kernel options may be controlled from [debian/config/config.pve](debian/config/config.pve). To build with
additional patches, you may add them to the [debian/patches/pve](debian/patches/pve) directory
and update the [series](debian/patches/series.linux) file accordingly.

## Contributing
Questions, suggestions and contributions are welcome and appreciated!
You can contribute in various meaningful ways:

* Report a bug through [Github issues](https://github.com/fabianishere/pve-edge-kernel/issues).
* Propose new patches and flavors for the project.
* Contribute improvements to the documentation.
* Provide feedback about how we can improve the project.
