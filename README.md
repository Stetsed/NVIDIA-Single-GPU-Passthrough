# NVIDIA-Single-GPU-Passthrough
Hello everybody :D, So recently I have seen alot of people have been having issues with single-gpu passthrough. And I decided to release this guide for not libvirt GPU passthrough. But QEMU shell script. The reason I have gone for this is because I have had less issues to get this to work with shell-script, mostly the audio. This guide will only work for people using nouveau on manjaro with nvidia , as that is what this is based off. 

There are some things I am gonna assume:
1. You have installed manjaro(Xfce), others will work but might need some adjustment interms of desktop manager etc, with the nouveau drivers. So the open-source drivers. The reason for this is the nvidia drivers are a mess.
2. You are running intel, and a Nvidia GPU
3. You have sudo
4. You have made a virtual machine via Virt-manager to install the OS, having chosen Q35 and OVMF.

# Step 1
Ok let's begin. To begin with we are gonna enable IOMMU and disable EFIFB, assuming you installed arch you will be using the GRUB bootloader. In this case what you will do is
1. Sudo nano /etc/default/grub
2. Go to "Grub_cmdline_linux_default", and then somewhere here, enable IOMMU by typing intel_iommu=on.
3. Also add efifb=off.
4. Now regenerate the grub.cfg file with, grub-mkconfig -o /boot/grub/grub.cfg
5. After doing this run the shell script in this repo called "IOMMU.sh"
6. Now you need to check if all your NVIDIA things are in 1 group, there may be something like "Intel PCIE bridge", that is fine.
7. If they are not then your IOMMU groups are screwed and you will have to do some annoying stuff which I will not cover here.

# Step 2
Assuming that this step went fine, you are next gonna find the IOMMU for ALL your nvidia devices. I use a GTX 1660 so I have 4.
1. Look for your devices, you will atleast have 1.
2. Write all of the IOMMU numbers at the beginning down, Ex; 01:00.1

# Step 3
Now we will have to "Patch" our vBIOS of our graphics card to patch thru. You can download it from sites such as techpowerd, but I would recommend just dumping it from your card directly as it is more reliable, however this can cause damage. 
1. Get a copy of your bios, either from your card with something such as Nvflash, or download it from a site such as techpowerd.
2. Open it is bless hex editor, if you haven't yet installed this, "sudo Pacman -S bless"
3. Now do Ctrl+F and search for "VIDEO" as text.
4. Now find the first U before VIDEO, and delete EVERYTHING before it. 
5. Now save it as a seperate file(So you have a backup).

# Step 4
Now we have to edit the shell script to work for us. You will find most of the editing noted inside the shell script.
1. Edit the IOMMU groups to your ones, there are 4 enteries, if you have less remove the ones you do not need, including the ones later in the script.
2. Edit the OVMF location, to find this just go to virt-manager and you should be able to find it there.
3. Edit the VBIOS location, which you edited it the previos step. Mine is called before.rom but yours will be something like patched.rom(or whatever you saved it as)
4. Edit systemctl stop sddm, to systemctl stop (Your desktop manager) which in the case of Manjaro XFCE is LightDM, Manjaro KDE uses SDDM. Do the same with the systemctl at the end of the script.
5. Now go to "Disown Host", and find "Echo 0 > /sys/class/vtconsole/vtcon0/bind" I also have vtcon1, you might not. Check this by doing "ls /sys/class/vtconsole/". For every entry here make an echo command, If you only have vtcon0, just remove the vtcon1. 
6. When running this script the line which has "Echo efi-framebuffer etc" will error, this is normal due to us disabling it with efifb=off. You can remove this but I have left it in.
7. Now you repeat step 5 on the adopt_host function.
8. Now you are gonna edit "Start_kvm_and_block", and first edit "smp,sockets=1,cores=4,threads=1" and edit it to whatever you want. This would give the VM 4 cores.
9. Now edit in the same section "System Drive" with the drive you earlier installed your OS on via virt-manager.
10. Last thing we have to edit is the USB Devices, you are gonna do this by doing the command "lsusb" then find your keyboard and mouse you want to pass through. The vendor ID will be the first 4 charachters after ID, and then after the :, will be the product ID. So if you have in lsmod 0001:0002. You will make vendor_id=0x0001 and productid=0x0002.


# And we are done :D
Now when you fire up the script it should kill your desktop and x-session, and boot you into your VM. You have to run this via SSH or the VM will close due to the script closing. You could fix this by using a screen or smth. It might say "Segmentation Fault(Core Dumped)". I am also experiecing this myself, I have not yet found a fix for it, but it seems that it's a chanch that it will happen and a chanch that it just works.

# Support
For help or anything else regarding this project please make a "Issue" and if you want to add anything just make a pull-request and I shall see if they should be added.

# Credits
Alena: Made the original script which I have modified

Archwiki: Alot of this info comes from there article on PCI passthrough via OVMF
https://wiki.archlinux.org/index.php/PCI_passthrough_via_OVMF

joeknock90: For his single GPU passthrough guide. Which this guide also uses parts from. But then uses shell script instead of libvirt.
https://github.com/joeknock90/Single-GPU-Passthrough
