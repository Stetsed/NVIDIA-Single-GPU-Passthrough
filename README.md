# This guide is now archived and will no longer recieve updates unless I decide to update it, but due to the dynamic situtation of GPU passthrough and me switching to have 2 dGPU's I will no longer be updating this.

# NVIDIA-Single-GPU-Passthrough
Hello everybody, me again. I have recently been fiddling around alot more with virtual machines because I was bored so I decided to remake this guide again because I see that it doesn't cover everything and as I recently decided to improve my setup to be more efficient I decided to update this guide aswell. Please note that this guide might not be 100% accurate so please only use this if you do have some experience, but you don't need to be an expert. And also an improved version of the start.sh script as I have made changes to it.

With this guide I am assuming:
1. You have root acces.
2. You have setup a virtual machine with the virt-manager choosing Q35 and OVMF.

# Step 1
Firstly we have to enable IOMMU on the machine, I have used GRUB and Systemd-boot so I will show methods for those but if you use the internet you should be able to find relativley quickly what to do.

GRUB:

1. Sudo nano /etc/default/grub
2. Go to "Grub_cmdline_linux_default", and then somewhere here, enable IOMMU by typing intel_iommu=on, or if your on AMD do amd_iommu=on.
3. Now regenerate the grub.cfg file with, grub-mkconfig -o /boot/grub/grub.cfg

Systemd-boot
1. sudo nano /boot/loader/entries/(entry for your loader)
2. Find the line which says "Options"
3. Add either intel_iommu=on if you are on an intel CPU or amd_iommu=on if you are on a AMD CPU.

# Step 2
1. After doing this run the shell script in this repo called "IOMMU.sh"
2. Now you need to check if all your NVIDIA things are in 1 group, there may be something like "Intel PCIE bridge", that is fine.
3. If they are not then your IOMMU groups are screwed and you will have to do ACS patching and the likes which I will not cover.

# Step 3
Now we will have to "Patch" our vBIOS of our graphics card to patch thru. You can download it from sites such as techpowerd, but I would recommend just dumping it from your card directly as it is more reliable.
1. Get a copy of your bios, either from your card with something such as Nvflash, or download it from a site such as techpowerup.
2. Open it is bless hex editor, if you haven't yet installed this, "sudo Pacman -S bless" on Arch based distros.
3. Now do Ctrl+F and search for "VIDEO" as text.
4. Now find the first U before VIDEO, and delete EVERYTHING before it. 
5. Now save it as a seperate file(So you have a backup).

# Step 4
Now this is where we turn away from the previous way we did it and start using some... better stuff honestly.
1. Download Start.sh from the github repository.
2. Run "sudo ls /sys/class/vtconsole"
3. Now as seen in the script there are 2 vtconsoles on my machine, this can be diffrent is yours and adjust, just copy the line and replace the number or remove it if you only have 1.

# Step 5
The last step is to add the devices from nvidia to our VM. 
1. Go to Virt-manager
2. Go to your VM and do "Add Device"
3. Add PCI-Device
4. Add your NVIDIA devices which might be multiple include all the audio etc aswell.


# And we are done :D

Compared to my previous guide this was ALOT easier as I found that driver unloading is not required(Suprise), and overall after doing a bunch of messing around I was able to get this script to a state where it worked evertime and I have been using it since.

Now to run it all you do is SSH into your PC via another device, and then run "Sudo ./Start.sh", and then "virsh -c qemu:///system" and then do "start (name of VM)" and your done the VM will now startup. You can also setup Libvirt Hooks which make it so the script will run when the machine is started not requiring an SSH session.


# Credits

Archwiki: Alot of this info comes from there article on PCI passthrough via OVMF
https://wiki.archlinux.org/index.php/PCI_passthrough_via_OVMF

joeknock90: For his single GPU passthrough guide. Which this guide also uses parts from.
https://github.com/joeknock90/Single-GPU-Passthrough
