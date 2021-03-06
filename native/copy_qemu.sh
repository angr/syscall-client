#!/bin/bash -e

if [[ -z "$1" ]]; then
	echo "Usage: $0 [path_to_qemu]"
	exit 1
fi

pushd $1
# copied from the qemu build so we don't have to depend on python to configure
cd linux-user/arm
/bin/sh syscallhdr.sh syscall.tbl syscall_nr.h common,oabi
cd ../i386
/bin/sh syscallhdr.sh syscall_32.tbl syscall_32_nr.h i386
cd ../x86_64
/bin/sh syscallhdr.sh syscall_64.tbl syscall_64_nr.h common,64
cd ../mips
/bin/sh syscallhdr.sh syscall_o32.tbl syscall_o32_nr.h o32 '' 4000
cd ../mips64
/bin/sh syscallhdr.sh syscall_n64.tbl syscall_n64_nr.h n64 '' TARGET_SYSCALL_OFFSET
cd ../ppc
/bin/sh syscallhdr.sh syscall.tbl syscall_nr.h common,nospu,32
popd

rm -rf qemu
mkdir qemu
for subdir in linux-user util include include/qemu include/fpu include/exec include/exec/user target; do
	mkdir qemu/$subdir
done

cp -r $1/linux-user/host qemu/linux-user/host

for fname in include/qemu/compiler.h linux-user/errno_defs.h linux-user/fd-trans.c linux-user/fd-trans.h include/glib-compat.h linux-user/ioctls.h linux-user/linux_loop.h linux-user/qemu.h include/qemu/selfmap.h linux-user/socket.h linux-user/syscall.c linux-user/syscall_defs.h linux-user/syscall_types.h linux-user/uname.c linux-user/uname.h include/exec/user/abitypes.h include/exec/user/thunk.h linux-user/safe-syscall.S thunk.c include/qemu/cutils.h include/fpu/softfloat.h include/fpu/softfloat-types.h include/fpu/softfloat-helpers.h include/fpu/softfloat-macros.h include/qemu/bswap.h include/qemu/host-utils.h include/qemu/bitops.h include/qemu/atomic.h linux-user/signal.c linux-user/signal-common.h linux-user/strace.c linux-user/strace.list; do
	cp $1/$fname qemu/$fname
done

cp -r $1/linux-user/generic qemu/linux-user/generic

for arch in i386 x86_64 arm aarch64 mips mips64 ppc; do
	mkdir qemu/linux-user/$arch
	for fname in target_cpu.h sockbits.h target_cpu.h target_fcntl.h target_structs.h target_syscall.h target_signal.h termbits.h; do
		cp $1/linux-user/$arch/$fname qemu/linux-user/$arch
	done
	cp $1/linux-user/$arch/syscall*.h qemu/linux-user/$arch 2>/dev/null || true
	if [ -d "$1/target/$arch" ]; then
		mkdir qemu/target/$arch
		cp $1/target/$arch/cpu-param.h qemu/target/$arch
	fi
done

mkdir qemu/linux-user/arm/nwfpe
cp $1/linux-user/arm/nwfpe/fpa11.h $1/linux-user/arm/nwfpe/fpsr.h qemu/linux-user/arm/nwfpe
