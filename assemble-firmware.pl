#!/usr/bin/perl -w

use strict;
use File::Basename;
use File::Path;

my $fwsrc0 = "linux-2.6-3.10.0/firmware";
my $fwsrc1 = "linux-firmware.git";
my $fwsrc2 = "dvb-firmware.git";
my $fwsrc3 = "firmware-misc";

my $fwlist = shift;
die "no firmware list specified" if !$fwlist || ! -f $fwlist;

my $target = shift;
die "no target directory" if !$target || ! -d $target;

my $force_skip = {

    # not needed, the HBA has burned-in firmware
    'ql2600_fw.bin' => 1,
    'ql2700_fw.bin' => 1,
    'ql8100_fw.bin' => 1,
    'ql8300_fw.bin' => 1,
};

my $skip = {};
# debian squeeze also misses those files
foreach my $fw (qw(
sms1xxx-stellar-dvbt-01.fw 
sms1xxx-nova-b-dvbt-01.fw
sms1xxx-nova-a-dvbt-01.fw
mrvl/sd8897_uapsta.bin
mrvl/pcie8766_uapsta.bin
mrvl/sd8786_uapsta.bin
cxgb4/t5fw.bin
brcm/brcmfmac-sdio.txt
brcm/brcmfmac-sdio.bin
brcm/brcmfmac43242a.bin
brcm/brcmfmac43143.bin
brcm/brcmfmac4354-sdio.txt
brcm/brcmfmac4339-sdio.txt
brcm/brcmfmac4339-sdio.bin
brcm/brcmfmac43362-sdio.txt
brcm/brcmfmac4335-sdio.txt
brcm/brcmfmac4334-sdio.txt
brcm/brcmfmac4330-sdio.txt
brcm/brcmfmac4329-sdio.txt
brcm/brcmfmac43241b4-sdio.txt
brcm/brcmfmac43241b0-sdio.txt
brcm/brcmfmac43143-sdio.txt
brcm/brcmfmac43455-sdio.txt
brcm/brcmfmac43430-sdio.txt
brcm/brcmfmac43430-sdio.bin
brcm/brcmfmac4356-pcie.txt
ct2fw-3.1.0.0.bin
ctfw-3.1.0.0.bin 
cbfw-3.1.0.0.bin

phanfw-4.0.579.bin


libertas/gspi8385.bin libertas/gspi8385_hlp.bin
ctfw.bin ct2fw.bin ctfw-3.0.3.1.bin ct2fw-3.0.3.1.bin
cbfw.bin cbfw-3.0.3.1.bin 
tehuti/firmware.bin
cyzfirm.bin
isi4616.bin
isi4608.bin
isi616em.bin
isi608.bin
isi608em.bin
c320tunx.cod
cp204unx.cod
c218tunx.cod
isight.fw
BT3CPCC.bin
bfubase.frm
solos-db-FPGA.bin
solos-Firmware.bin
solos-FPGA.bin
pca200e_ecd.bin2
prism2_ru.fw
tms380tr.bin
FW10 
FW13
comedi/jr3pci.idm

sd8686.bin
sd8686_helper.bin 
usb8388.bin
libertas_cs_helper.fw
lbtf_usb.bin

wl1271-fw.bin
wl1251-fw.bin
symbol_sp24t_sec_fw
symbol_sp24t_prim_fw
prism_ap_fw.bin
prism_sta_fw.bin
ar9170.fw
iwmc3200wifi-lmac-sdio.bin
iwmc3200wifi-calib-sdio.bin
iwmc3200wifi-umac-sdio.bin
iwmc3200top.1.fw
zd1201.fw
zd1201-ap.fw
isl3887usb
isl3886usb
isl3886pci
3826.arm

i2400m-fw-sdio-1.3.sbcf

nx3fwmn.bin
nx3fwct.bin
nxromimg.bin

myri10ge_rss_eth_z8e.dat
myri10ge_rss_ethp_z8e.dat
myri10ge_eth_z8e.dat
myri10ge_ethp_z8e.dat

i1480-phy-0.0.bin
i1480-usb-0.0.bin
i1480-pre-phy-0.0.bin

go7007fw.bin
go7007tv.bin

sep/resident.image.bin
sep/cache.image.bin
b43legacy/ucode4.fw
b43legacy/ucode2.fw 
b43/ucode9.fw
b43/ucode5.fw
b43/ucode15.fw
b43/ucode14.fw
b43/ucode13.fw
b43/ucode11.fw
b43/ucode16_mimo.fw
orinoco_ezusb_fw
isl3890
isl3886
isl3877
mwl8k/fmimage_8366.fw
mwl8k/helper_8366.fw
mwl8k/fmimage_8363.fw
mwl8k/helper_8363.fw
iwlwifi-6000g2a-4.ucode
iwlwifi-6000g2a-6.ucode
iwlwifi-130-5.ucode
iwlwifi-100-6.ucode
iwlwifi-1000-6.ucode
iwlwifi-8000-8.ucode
cxgb4/t4fw.bin
cxgb4/t4fw-1.3.10.0.bin

ast_dp501_fw.bin
RTL8192U/data.img
RTL8192U/main.img 
RTL8192U/boot.img
me2600_firmware.bin
me4000_firmware.bin
daqboard2000_firmware.bin
niscrb02.bin
niscrb01.bin
ni6534a.bin
libertas/usb8388.bin
libertas_cs.fw 
libertas/cf8305.bin
wil6210.fw
wil6210.board
ath10k/QCA988X/hw2.0/board.bin
ath10k/QCA988X/hw2.0/firmware-3.bin
ath10k/QCA988X/hw2.0/firmware-2.bin
ath10k/QCA988X/hw2.0/firmware.bin
ath6k/AR6004/hw1.3/fw.ram.bin
fw.ram.bin
ath6k/AR6004/hw1.1/bdata.DB132.bin
ath6k/AR6004/hw1.1/bdata.bin
ath6k/AR6004/hw1.0/bdata.DB132.bin
ath6k/AR6004/hw1.0/bdata.bin
ath6k/AR6004/hw1.2/fw.ram.bin
ath6k/AR6004/hw1.1/fw.ram.bin
ath6k/AR6004/hw1.0/fw.ram.bin 
ath6k/AR6003/hw2.1.1/bdata.bin
ath6k/AR6003/hw2.0/bdata.bin
iwlwifi-3165-10.ucode
iwlwifi-8000-10.ucode
brcm/brcmfmac43340-sdio.txt
brcm/brcmfmac43570-pcie.txt
brcm/brcmfmac4354-pcie.txt
brcm/brcmfmac4354-pcie.bin
brcm/brcmfmac43602-pcie.txt
mrvl/usb8801_uapsta.bin
rtlwifi/rtl8723efw.bin
softing-4.6/cancrd2.bin
softing-4.6/ldcard2.bin
softing-4.6/bcard2.bin
softing-4.6/cansja.bin
softing-4.6/cancard.bin
softing-4.6/ldcard.bin
softing-4.6/bcard.bin 
wd719x-risc.bin
wd719x-wcs.bin
libertas/gspi8385_helper.bin
wlan/prima/WCNSS_qcom_wlan_nv.bin
lattice-ecp3.bit

iwlwifi-3160-IWL3160_UCODE_API_OK.ucode
iwlwifi-8000-12.ucode

radeon/boniare_mc.bin
radeon/bonaire_sdma1.bin
radeon/bonaire_uvd.bin
radeon/bonaire_vce.bin
radeon/kabini_sdma1.bin
radeon/kabini_uvd.bin
radeon/kabini_vce.bin
radeon/kaveri_sdma1.bin
radeon/kaveri_uvd.bin
radeon/kaveri_vce.bin
radeon/hawaii_sdma1.bin
radeon/hawaii_vce.bin
radeon/hawaii_uvd.bin
radeon/mullins_sdma1.bin
radeon/mullins_vce.bin
radeon/mullins_uvd.bin

wil6210.brd
ath10k/QCA6174/hw3.0/board.bin 
ath10k/QCA6174/hw3.0/firmware-5.bin
ath10k/QCA6174/hw3.0/firmware-4.bin
ath10k/QCA6174/hw2.1/board.bin
ath10k/QCA6174/hw2.1/firmware-5.bin
ath10k/QCA6174/hw2.1/firmware-4.bin
ath10k/QCA988X/hw2.0/firmware-5.bin
brcm/brcmfmac43241b5-sdio.txt
brcm/brcmfmac4358-pcie.txt
brcm/brcmfmac4358-pcie.bin
mt7601u.bin
liquidio/lio_410nv.bin
liquidio/lio_210nv.bin
liquidio/lio_210sv.bin

mrvl/sd8997_uapsta.bin
mrvl/usb8997_uapsta.bin
mrvl/pcie8997_uapsta.bin
ti-connectivity/wl18xx-conf.bin
ath10k/QCA9377/hw1.0/board.bin
ath10k/QCA9377/hw1.0/firmware-5.bin
ath10k/QCA6174/hw3.0/board-2.bin
ath10k/QCA6174/hw2.1/board-2.bin
ath10k/QCA988X/hw2.0/board-2.bin
iwlwifi-8000-13.ucode
brcm/brcmfmac4371-pcie.txt
brcm/brcmfmac4366b-pcie.txt
brcm/brcmfmac4365b-pcie.txt
brcm/brcmfmac4365b-pcie.bin
brcm/brcmfmac4350-pcie.txt
cxgb4/t6fw.bin

ks7010sd.rom
liquidio/lio_23xx.bin
rtlwifi/rtl8723bu_bt.bin
ath10k/QCA9887/hw1.0/board-2.bin
mrvl/usbusb8997_combo_v4.bin
iwlwifi-6000g2b-IWL6000G2B_UCODE_API_MAX.ucode
iwlwifi-6000-6.ucode
iwlwifi-7265D-26.ucode
iwlwifi-3168-26.ucode
iwlwifi-8265-26.ucode
iwlwifi-8000C-26.ucode
iwlwifi-9000-pu-a0-lc-a0--26.ucode
iwlwifi-9260-th-a0-jf-a0--26.ucode
iwlwifi-9000-pu-a0-jf-a0--26.ucode
iwlwifi-Qu-a0-jf-b0--26.ucode
brcm/brcmfmac4366c-pcie.bin
brcm/brcmfmac4365c-pcie.bin
brcm/brcmfmac4359-pcie.bin

)) {
    $skip->{$fw} = 1;
}

sub copy_fw {
    my ($src, $dstfw) = @_;

    my $dest = "$target/$dstfw";

    return if -f $dest;

    mkpath dirname($dest);
    system ("cp '$src' '$dest'") == 0 || die "copy $src to $dest failed";
}

my $fwdone = {};

open(TMP, $fwlist);
while(defined(my $line = <TMP>)) {
    chomp $line;
    my ($fw, $mod) = split(/\s+/, $line, 2);

    next if $mod =~ m|^kernel/sound|;
    next if $mod =~ m|^kernel/drivers/isdn|;

    # skip ZyDas usb wireless, use package zd1211-firmware instead
    next if $fw =~ m|^zd1211/|; 

    # skip atmel at76c50x wireless networking chips.
    # use package atmel-firmware instead
    next if $fw =~ m|^atmel_at76c50|;

    # skip Bluetooth dongles based on the Broadcom BCM203x 
    # use package bluez-firmware instead
    next if $fw =~ m|^BCM2033|;

    next if $fw =~ m|^xc3028-v27\.fw|; # found twice!
    next if $fw =~ m|.inp|; # where are those files?
    next if $fw =~ m|^ueagle-atm/|; # where are those files?

    next if $force_skip->{$fw};

    next if $fwdone->{$fw};
    $fwdone->{$fw} = 1;

    my $fwdest = $fw;
    if ($fw eq 'libertas/gspi8686.bin') {
	$fw = 'libertas/gspi8686_v9.bin';
    }
    if ($fw eq 'libertas/gspi8686_hlp.bin') {
	$fw = 'libertas/gspi8686_v9_helper.bin';
    }

    if ($fw eq 'PE520.cis') {
	$fw = 'cis/PE520.cis';
    }
 
    # the rtl_nic/rtl8168d-1.fw file is buggy in current kernel tree
    if (-f "$fwsrc0/$fw" && 
	($fw ne 'rtl_nic/rtl8168d-1.fw')) { 
	copy_fw("$fwsrc0/$fw", $fwdest);
	next;
    }
    if (-f "$fwsrc1/$fw") {
	copy_fw("$fwsrc1/$fw", $fwdest);
	next;
    }
    if (-f "$fwsrc3/$fw") {
	copy_fw("$fwsrc3/$fw", $fwdest);
	next;
    }

    if ($fw =~ m|/|) {
	next if $skip->{$fw};

        die "unable to find firmware: $fw $mod\n";
    }

    my $name = basename($fw);

    my $sr = `find '$fwsrc1' -type f -name '$name'`;
    chomp $sr;
    if ($sr) {
	#print "found $fw in $sr\n";
	copy_fw($sr, $fwdest);
	next;
    }

    $sr = `find '$fwsrc2' -type f -name '$name'`;
    chomp $sr;
    if ($sr) {
	print "found $fw in $sr\n";
	copy_fw($sr, $fwdest);
	next;
    }

    $sr = `find '$fwsrc3' -type f -name '$name'`;
    chomp $sr;
    if ($sr) {
	#print "found $fw in $sr\n";
	copy_fw($sr, $fwdest);
	next;
    }

    next if $skip->{$fw};
    next if $fw =~ m|^dvb-|;

    die "unable to find firmware: $fw $mod\n";
}
close(TMP);

exit(0);
