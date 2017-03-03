#!/usr/bin/python
import sys
import pexpect
import pdb
DEBUG=True
def start_qemu():
    child = pexpect.spawn('''qemu-system-aarch64 -machine virt,gic_version=3
                          -cpu host -kernel Image -drive if=none,file=ubuntu.img,id=fs
                          -device virtio-blk-device,drive=fs
                          -append "console=ttyAMA0 root=/dev/vda1 rw rootwait"
                          -device virtio-net-device,netdev=net0
                          -netdev tap,id=net0,script=qemu-ifup.sh,downscript=qemu-ifdown.sh
                          -nographic -D -d -enable-kvm''')
    child.logfile = sys.stdout
    index = child.expect(["estuary:\/\$", pexpect.EOF, pexpect.TIMEOUT])
    if index == 0:
        return child
    elif index == 1:
        print "the qemu start time out with status EOF"
        return -1
    elif index == 2:
        print "the qemu start time out with status TIMEOUT"  # continue to wait
        return -1


def close_qemu(child):
    child.sendcontrol('a')
    child.sendline("c")
    child.sendline("quit")
    child.expect(pexpect.EOF)
    print(child.exitstatus, child.signalstatus)
    return


def create_dir_in_qemu(child):
    child.sendline("mkdir hello-world")
    child.expect("estuary:\/\$")
    child.sendline("ls")
    index_ls = child.expect(["hello-world", pexpect.EOF, pexpect.TIMEOUT])
    if index_ls == 0:
        print '''yes the dir create successful'''
        # time.sleep(0.1)
        child.sendline("sync")
        child.expect("estuary:\/\$")
    elif index_ls == 1:
        print '''sorry the dir create failed with status EOF'''
        close_qemu(child)
        exit(-1)
    elif index_ls == 2:
        print '''sorry the dir create failed with status TIMEOUT'''
        close_qemu(child)
        exit(-1)
    print 'create qemu before return'
    return


def find_the_exist_dir_in_virt_disk(child):
    child.sendline("ls")
    index_ls = child.expect(["hello-world", pexpect.EOF, pexpect.TIMEOUT])
    if index_ls == 0:
        print '''yes the dir find successful'''
    elif index_ls == 1:
        print '''sorry the dir can not find with status EOF'''
        close_qemu(child)
        exit(-1)
    elif index_ls == 2:
        print '''sorry the dir can not find with status TIMEOUT'''
        close_qemu(child)
        exit(-1)
    return


def test_the_network(child):
    child.sendline("ip addr add 192.168.2.3/24 dev eth0")
    child.expect("estuary:\/\$")
    child.sendline("ip addr")
    index_ip = child.expect(["192.168.2.3/24", pexpect.EOF, pexpect.TIMEOUT])
    if index_ip == 0:
        print '''yes the ip config successful'''
    elif index_ip == 1:
        print '''sorry the ip set failed with status EOF'''
        close_qemu(child)
        exit(-1)
    elif index_ip == 2:
        print '''sorry ip find with status TIMEOUT'''
        close_qemu(child)
        exit(-1)

    child.sendline("ping 192.168.2.1 -c 3")
#    child.expect("estuary:\/\$", timeout=300)
#    child.sendline("echo $?")
#    child.interact()
    index_echo = child.expect([' 0% packet loss', pexpect.EOF, pexpect.TIMEOUT])
    if index_echo == 0:
        print '''yes the network test is successful'''
    elif index_echo == 1:
        print '''sorry the network test failed with status EOF'''
        close_qemu(child)
        exit(-1)
    elif index_echo == 2:
        print '''sorry the network test failed with status TIMEOUT'''
        close_qemu(child)
        exit(-1)

    return


def main():
    # pexpect.run("mkdir 123")
    # (command_output, exitstatus) = pexpect.run("mkdir 123", withexitstatus=1)
    # print command_output
    # print exitstatus
    # pexpect.run("mkdir 123")
    child = start_qemu()
    if child == -1:
        print '''qemu start failed'''
        exit(-1)
    create_dir_in_qemu(child)
    close_qemu(child)
    child1 = start_qemu()
    if child1 == -1:
    	test_the_network(child1)
    close_qemu(child1)


#    child = pexpect.spawn('''qemu-system-aarch64 -machine virt,gic_version=3
#                          -cpu host -kernel Image -drive if=none,file=ubuntu.img,id=fs
#                          -device virtio-blk-device,drive=fs
#                          -append "console=ttyAMA0 root=/dev/vda1 rw rootwait"
#                          -device virtio-net-device,netdev=net0
#                          -netdev tap,id=net0,script=qemu-ifup.sh,downscript=qemu-ifdown.sh
#                          -nographic -D -d -enable-kvm''')
#    index = child.expect(["estuary:\/\$", pexpect.EOF, pexpect.TIMEOUT])
#    if index == 0:
#        child.sendline('''mkdir hello-world''')
#        child.expect("estuary:\/\$")
#        child.sendline('''ls''')
#        index_ls = child.expect(["hello-world", pexpect.EOF, pexpect.TIMEOUT])
#        if index_ls == 0:
#            print '''yes the dir create successful'''
#        elif index_ls == 1:
#            print '''sorry the dir create failed with status EOF'''
#        elif index_ls == 2:
#            print '''sorry the dir create failed with status TIMEOUT'''
#        child.close()
#        print(child.exitstatus, child.signalstatus)
#    elif index == 1:
#        print "the qemu start time out with status EOF"
#    elif index == 2:
#        print "the qemu start time out with status TIMEOUT"  # continue to wait
    print '''yes i have boot sucessful'''

if __name__ == "__main__":
    main()
