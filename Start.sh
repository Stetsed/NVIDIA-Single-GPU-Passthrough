#!/bin/bash
set -x

# Kill Desktop Manager
systemctl stop sddm

#Wait 3 Seconds
sleep 3

#Kill everything with X including x-session
pkill -9 x

#Wait 3 Seconds
sleep 3

#Restart dnscrypt-proxy because pkill -9 x kills it
systemctl start dnscrypt-proxy

# Kill the console
echo 0 > /sys/class/vtconsole/vtcon0/bind
echo 0 > /sys/class/vtconsole/vtcon1/bind

#Sleep for 10 Seconds
sleep 10

# Unbind the efi-framebuffer
echo efi-framebuffer.0 > /sys/bus/platform/drivers/efi-framebuffer/unbind

# Wait 10 seconds
sleep 10

# Load VFIO Drivers
/sbin/modprobe vfio
/sbin/modprobe vfio-pci
/sbin/modprobe vfio_iommu_type1

virsh -c qemu:///system
