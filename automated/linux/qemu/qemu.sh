#!/bin/sh
. ../../lib/sh-test-lib
OUTPUT="$(pwd)/output"
RESULT_FILE="${OUTPUT}/result.txt"
SKIP_INSTALL="false"
get_binary() {
	if [ ! -e "./Image" ]; then
		wget http://192.168.1.107/v3.0rc0-pretest1/Image
		wget http://192.168.1.107/v3.0rc0-pretest1/mini-rootfs.cpio.gz
	fi
	wait
}

install() {
    dist_name
    if [ "${dist}"x = ""x ]; then
	echo 'version tool not install'
	exit
    fi
    case "${dist}" in
      Debian|Ubuntu) pkgs="lsb-release qemu qemu-kvm libvirt-bin bridge-utils" ;;
      Fedora|CentOS) pkgs="qemu qemu-kvm libvirt libcanberra-gtk2 qemu-kvm qemu-kvm-tools libvirt-cim libvirt-client libvirt-java.noarch  libvirt-python libiscsi-1.7.0-5.el6  dbus-devel  virt-clone tunctl virt-manager libvirt libvirt-python python-virtinst wget bridge-utils" ;;
    esac
	# centos and Fedor add linaro repo source
	if [ "${dist}"x = "Fedora"x ] || [ "${dist}"x = "CentOS"x ]; then
		if [ ! -e /etc/yum.repos.d/Linaro-overlay.repo ]; then
			cat > /etc/yum.repos.d/Linaro-overlay.repo << END_TEXT
[linaro-overlay]
name = Linaro Overlay packages for CentOS 7
baseurl = http://repo.linaro.org/rpm/linaro-overlay/centos-7/repo
enable = 1
END_TEXT
		fi
		# change the yum`s default conf ,because some of the packages \
		# do not conform to the GPG validation
		sed -i "/^gpgcheck/s/1/0/g" /etc/yum.conf
	fi

    install_deps "${pkgs}" "${SKIP_INSTALL}"
	if [ "${dist}"x = "Fedora"x ] || [ "${dist}"x = "CentOS"x ]; then
		# recovery yum's default conf
		sed -i "/^gpgcheck/s/0/1/g" /etc/yum.conf
	fi
}

# Create a virtual bridge named "br0" and configure the local network interface
set_up_bridge() {
	brctl addbr br0
	ip addr add 192.168.2.1/24 dev br0
	# add route
	ip link set br0 up
	ip route add 192.168.2.0/24 via 192.168.2.1 dev br0
}

del_bridge() {
	ip link set br0 down
	brctl delbr br0

}

# create a virtual disk
create_virt_disk() {
if [ ! -e ./ubuntu.img ]; then
	local path=`pwd`
	modprobe nbd max_part=8
	qemu-img create -f qcow2 ubuntu.img 1G
	qemu-nbd -c /dev/nbd0 ubuntu.img
	yes | mkfs.ext4 /dev/nbd0
	parted -s /dev/nbd0 mklabel gpt
	parted -s /dev/nbd0 mkpart ROOT ext4 1 1G
	yes | mkfs.ext4 /dev/nbd0p1
	mkdir -p /mnt/image
	mount /dev/nbd0p1 /mnt/image/
	cd /mnt/image
	zcat "${path}/mini-rootfs.cpio.gz" |cpio -dimv
	cd "${path}"
	umount /mnt/image
	qemu-nbd -d /dev/nbd0
fi
}
# start qemu with virt disk and network
start_qemu_disk_network() {
	dist_name
	case "${dist}" in
	   Fedora|CentOS)
	        local key=`python ./test-pexpect.py`
	        echo $?
	        echo "${key}":q
	   ;;
	   Debian|Ubuntu)
		python ./test-pexpect.py
	   ;;
	esac
}
# install depended-upon packages
install
get_binary
set_up_bridge
create_virt_disk
start_qemu_disk_network
del_bridge

