# Proxmox Edge kernels
Custom Linux kernels for Promox VE 6.

#### Versions
1. Linux 5.6
2. Linux 5.7
3. Linux 5.8

#### Flavors
1. Proxmox
2. Clear Linux

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

## Questions
If you have any questions or want to see additional versions, flavors or micro architectures being built, feel
free to open an issue on Github.
