#!/bin/bash

# Main Configuration
RAM="12G"
IOMMU_GPU_VGA="01:00.0"
IOMMU_GPU_AUDIO="01:00.1"
IOMMU_GPU_USB="01:00.2"
IOMMU_GPU_SERIAL="01:00.3"
OVMF="/usr/share/edk2-ovmf/x64/OVMF_CODE.fd"
VBIOS="/home/stetsed/before.rom"

# Kill the desktop manager and shutdown the X session.
kill_desktop()
{
	systemctl stop sddm
	pkill -9 x
}
# This section might cause errors, I have had it cause some errors with me. But my VM still runs fine.
manage_cpu_governor()
{   
    # Set the governor to argument [1]

    for i in $(seq 0 $(($(nproc)-1))); do
        echo $1 > /sys/devices/system/cpu/cpu${i}/cpufreq/scaling_governor
    done
}
# Remove the graphics card from the host.
disown_host()
{
    # Kill the console
    echo 0 > /sys/class/vtconsole/vtcon0/bind
    echo 0 > /sys/class/vtconsole/vtcon1/bind

    # Unbind the efi-framebuffer, obsoleet due to efifb=off.
    echo efi-framebuffer.0 > /sys/bus/platform/drivers/efi-framebuffer/unbind

    # Wait 2 seconds to make sure everything went through
    sleep 2

    # Unload i2c_nvidia_gpu, which is using nouveau and then unload nouveau.
    /sbin/modprobe -r i2c_nvidia_gpu
    /sbin/modprobe -r nouveau

    # Detach the GPU and it's devices.
    virsh nodedev-detach pci_0000_${IOMMU_GPU_VGA//[:.]/_}
    virsh nodedev-detach pci_0000_${IOMMU_GPU_AUDIO//[:.]/_}
    virsh nodedev-detach pci_0000_${IOMMU_GPU_USB//[:.]/_}
    virsh nodedev-detach pci_0000_${IOMMU_GPU_SERIAL//[:.]/_}

    # Load VFIO
    /sbin/modprobe vfio
    /sbin/modprobe vfio-pci
    /sbin/modprobe vfio_iommu_type1
}

adopt_host()
{
    # Unload vfio
    /sbin/modprobe -r vfio
    /sbin/modprobe -r vfio-pci
    /sbin/modprobe -r vfio_iommu_type1

    # Load nvidia modules
    /sbin/modprobe i2c_nvidia_gpu
    /sbin/modprobe nouveau

    # Reattach the GPU and it's devices
    virsh nodedev-reattach pci_0000_${IOMMU_GPU_VGA//[:.]/_}
    virsh nodedev-reattach pci_0000_${IOMMU_GPU_AUDIO//[:.]/_}
    virsh nodedev-reattach pci_0000_${IOMMU_GPU_USB//[:.]/_}
    virsh nodedev-reattach pci_0000_${IOMMU_GPU_SERIAL//[:.]/_}

    # Reload the framebuffer and console
    echo 1 > /sys/class/vtconsole/vtcon0/bind
    echo 1 > /sys/class/vtconsole/vtcon1/bind

    # Bind the efi-framebuffer, obsoleet due to efifb=off.
    echo efi-framebuffer.0 > /sys/bus/platform/drivers/efi-framebuffer/bind
}

start_kvm_and_block()
{
     OPTS="-name win10"

    # Processor (4 cores with 4 threads)
    # Set hyper-v settings to allow enabling of hyper-v and passing through vendor_id to avoid errors.
    OPTS="$OPTS -cpu host,l3-cache=on,+topoext,kvm=off,hv_vendor_id=1234567890ab,hv_vapic,hv_time,hv_relaxed,hv_spinlocks=0x1fff,hv-vpindex,hv-runtime,hv-crash,hv-time,hv-synic,hv-stimer,hv-reset,hv-frequencies,+invtsc"
    OPTS="$OPTS -smp 4,sockets=1,cores=4,threads=1"

    # Machine
    OPTS="$OPTS -machine type=q35,accel=kvm"

    # Memory
    OPTS="$OPTS -m $RAM"

    # Hardware clock
    OPTS="$OPTS -rtc base=localtime"

    # OVMF
    OPTS="$OPTS -drive if=pflash,format=raw,readonly,file=$OVMF"

    # System Drive
    OPTS="$OPTS -drive format=raw,file=/home/stetsed/win10.img"

    # Passing through the GPU to the guest and the VBIOS to the GPU VGA.
    OPTS="$OPTS -device vfio-pci,host=$IOMMU_GPU_VGA,multifunction=on,x-vga=on,romfile=$VBIOS"
    OPTS="$OPTS -device vfio-pci,host=$IOMMU_GPU_AUDIO"
    OPTS="$OPTS -device vfio-pci,host=$IOMMU_GPU_USB"
    OPTS="$OPTS -device vfio-pci,host=$IOMMU_GPU_SERIAL"

    # Usb peripherals
    OPTS="$OPTS -usb -device usb-host,vendorid=0x046d,productid=0xc539,id=mouse -device usb-host,vendorid=0x046d,productid=0xc33f,id=keyboard"

    # Blackhole vga
    OPTS="$OPTS -nographic -vga none -parallel none -serial none"

    OPTS="$OPTS -device AC97"
    #OPTS="$OPTS -device AC97,audiodev=pa1"
    #OPTS="$OPTS -audiodev pa,id=pa1,server=/tmp/pulse-socket,out.latency=2000"

    # Finaly start qemu 
    qemu-system-x86_64 $OPTS
}
kill_desktop
disown_host
manage_cpu_governor "performance"
start_kvm_and_block
## Wait for QEMU
wait
manage_cpu_governor "ondemand"
adopt_host
systemctl start sddm.service
