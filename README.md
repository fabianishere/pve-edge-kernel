# Proxmox Edge kernels
Custom Linux kernels for Proxmox VE.

#### Available Versions
1. Linux 5.19
1. Linux 5.18

Older builds are still available at the [Releases](https://github.com/fabianishere/pve-edge-kernel/releases) page.

## Installation
[![Hosted By: Cloudsmith](https://img.shields.io/badge/OSS%20hosting%20by-cloudsmith-blue?logo=cloudsmith&style=flat-square)](https://cloudsmith.com)

First, set up our Debian repository on your Proxmox installation: 
1. **Add the repository's GPG key:**  
   ```bash
   curl -1sLf 'https://dl.cloudsmith.io/public/pve-edge/kernel/gpg.8EC01CCF309B98E7.key' | gpg --dearmor -o /usr/share/keyrings/pve-edge-kernel.gpg
   ```
2. **Set up the `pve-edge-kernel` repository:**  
   If you are still on _Proxmox VE 6_, pick the Buster-based repository:
   ```bash
   echo "deb [signed-by=/usr/share/keyrings/pve-edge-kernel.gpg] https://dl.cloudsmith.io/public/pve-edge/kernel/deb/debian buster main" > /etc/apt/sources.list.d/pve-edge-kernel.list
   ```
   If you are already on _Proxmox VE 7_, pick the Bullseye-based repository:
   ```bash
   echo "deb [signed-by=/usr/share/keyrings/pve-edge-kernel.gpg] https://dl.cloudsmith.io/public/pve-edge/kernel/deb/debian bullseye main" > /etc/apt/sources.list.d/pve-edge-kernel.list
   ```
3. **Install a kernel package:**  
   ```bash
   apt update
   apt install pve-kernel-5.18-edge
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

## AppArmor intervention
Previously, these kernels required changing the AppArmor feature file to a non-default version.
This issue has been fixed since version 5.16.
If you have used the workaround, please update back to the default configuration in `/etc/apparmor/parser.conf` as follows:
```diff
## Pin feature set (avoid regressions when policy is lagging behind
## the kernel) 
- compile-features=/usr/share/apparmor-features/features.stock
+ compile-features=/usr/share/apparmor-features/features
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

1. `PVE_KERNEL_CC`  
   The compiler to use for the kernel build.
2. `PVE_KERNEL_CFLAGS`  
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
