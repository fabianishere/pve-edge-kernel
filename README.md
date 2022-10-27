# Proxmox Edge kernels
Custom Linux kernels for Proxmox VE 7.

#### Available Versions
1. Linux 6.0
2. Linux 5.19 **[EOL]**

Older builds are still available at the [Releases](https://github.com/fabianishere/pve-edge-kernel/releases) page.

## Installation
[![Hosted By: Cloudsmith](https://img.shields.io/badge/OSS%20hosting%20by-cloudsmith-blue?logo=cloudsmith&style=flat-square)](https://cloudsmith.com)

First, set up our Debian repository on your Proxmox installation: 
1. **Add the repository's GPG key:**  
   ```bash
   curl -1sLf 'https://dl.cloudsmith.io/public/pve-edge/kernel/gpg.8EC01CCF309B98E7.key' | gpg --dearmor -o /usr/share/keyrings/pve-edge-kernel.gpg
   ```
2. **Set up the `pve-edge-kernel` repository:**  
   ```bash
   echo "deb [signed-by=/usr/share/keyrings/pve-edge-kernel.gpg] https://dl.cloudsmith.io/public/pve-edge/kernel/deb/debian bullseye main" > /etc/apt/sources.list.d/pve-edge-kernel.list
   ```
3. **Install a kernel package:**  
   ```bash
   apt update
   apt install pve-kernel-6.0-edge
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

## Building manually
You may also choose to manually build one of these kernels yourself.

#### Prerequisites
Make sure you have at least 10 GB of free space available and have the following
packages installed:

```bash
apt install devscripts debhelper equivs git
```

#### Obtaining the source
Obtain the source code as follows:
```bash
git clone https://github.com/fabianishere/pve-edge-kernel
cd pve-edge-kernel
```
Then, select the branch of your likings (e.g. `v6.0.x`) and update the submodules:
```bash
git checkout v6.0.x
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

## Removal
Use `apt` to remove individual kernel packages from your system. If you want
to remove all packages from a particular kernel release, use the following
command:

```bash
apt remove pve-kernel-6.0*edge pve-headers-6.0*edge
```

## Contributing
Questions, suggestions and contributions are welcome and appreciated!
You can contribute in various meaningful ways:

* Report a bug through [Github issues](https://github.com/fabianishere/pve-edge-kernel/issues).
* Propose new patches and flavors for the project.
* Contribute improvements to the documentation.
* Provide feedback about how we can improve the project.
