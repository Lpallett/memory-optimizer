#!/bin/bash

# Firstly, mount hugetlbfs, for example:
# mount -t hugetlbfs none /dev/hugepages
# Then reserve some huge pages as below:
# echo "10000" > /proc/sys/vm/nr_hugepages

[[ $qemu_cmd ]] || qemu_cmd=qemu-system-x86_64
[[ $qemu_smp ]] || qemu_smp='cpus=32'
[[ $qemu_mem ]] || qemu_mem='128G'
[[ $qemu_ssh ]] || qemu_ssh='2222'
[[ $qemu_log ]] && qemu_log=file:$qemu_log
[[ $qemu_log ]] || qemu_log=stdio
[[ $interleave ]] && numactl="numactl --interleave=$interleave"

kvm=(
	$numactl
	$qemu_cmd
	-machine pc,nvdimm
	-cpu host
	-enable-kvm
	-smp $qemu_smp
	-numa node,nodeid=0,memdev=hgtlb0
	-m $qemu_mem
	-object memory-backend-file,id=hgtlb0,size=$qemu_mem,mem-path=/dev/hugepages
	-device e1000,netdev=net0
	-netdev user,id=net0,hostfwd=tcp::$qemu_ssh-:22
	-drive if=virtio,file=images/guest.raw,format=raw
	-serial $qemu_log
	-display none
	-monitor none
)
#echo "kvm=${kvm[@]}"
exec "${kvm[@]}"
