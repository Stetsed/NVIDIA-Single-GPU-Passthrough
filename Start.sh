#!/bin/bash
set -x

# Kill Desktop Manager
systemctl stop sddm

#Wait 3 Seconds
sleep 3

# Kill the console
echo 0 > /sys/class/vtconsole/vtcon0/bind
echo 0 > /sys/class/vtconsole/vtcon1/bind

#Sleep for 6 Seconds
sleep 10

# Unbind the efi-framebuffer
echo efi-framebuffer.0 > /sys/bus/platform/drivers/efi-framebuffer/unbind

# Wait 6 seconds
sleep 6

# Load VFIO Drivers
/sbin/modprobe vfio
/sbin/modprobe vfio-pci
/sbin/modprobe vfio_iommu_type1

virsh -c qemu:///system
