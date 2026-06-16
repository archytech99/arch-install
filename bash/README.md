# Cheat Sheets (log install)

```log
## Arch Linux Installation
#######################################################################
cfdisk /dev/nvme
mkfs.fat -F32 /dev/<partition>
mkfs.btrfs -f /dev/<partition>

mount /dev/<partition> /mnt
btrfs su cr /mnt/@
btrfs su cr /mnt/@home
btrfs su cr /mnt/@varlog
btrfs su cr /mnt/@docker
btrfs su cr /mnt/@snapshots
btrfs su cr /mnt/@snapshots_home
umount /mnt

mount -o compress=zstd,subvol=@ /dev/<partition> /mnt
mkdir -p /mnt/{boot,home,home/.snapshots,var/log,var/lib/docker,.snapshots}
mount -o compress=zstd,subvol=@home /dev/<partition> /mnt/home
mount -o compress=zstd,subvol=@varlog /dev/<partition> /mnt/var/log
mount -o compress=zstd,subvol=@docker /dev/<partition> /mnt/var/lib/docker
mount -o compress=zstd,subvol=@snapshots /dev/<partition> /mnt/.snapshots
mount -o compress=zstd,subvol=@snapshots_home /dev/<partition> /mnt/home/.snapshots
mount /dev/<partition> /mnt/boot

pacstrap -K /mnt \
base \
linux \
linux-firmware \
linux-headers \
amd-ucode \
sudo \
nano \
btop \
git \
curl \
wget \
openssh \
systemd \
bash-completion \
networkmanager \
ufw \
snapper \
zram-generator \
base-devel \
reflector \
rsync \
fastfetch \
man-db \
man-pages
genfstab -U /mnt >> /mnt/etc/fstab
arch-chroot /mnt
#######################################################################

## pre-Config Root System
#######################################################################
ln -sf /usr/share/zoneinfo/Asia/Jakarta /etc/localtime
hwclock --systohc
nano /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "KEYMAP=us" > /etc/vconsole.conf
echo "archytech" > /etc/hostname

EDITOR=nano visudo
## Uncomment to allow members of group wheel to execute any command
# %wheel ALL=(ALL:ALL) ALL

useradd -m -G wheel <user>
passwd <user>
passwd
systemctl enable NetworkManager
systemctl enable sshd
systemctl enable ufw

bootctl install
# update value 'loader.conf'
nano /boot/loader/loader.conf
#default arch
#timeout 3
#editor no

# create file 'arch.conf' if not available
lsblk -f
nano /boot/loader/entries/arch.conf
#title     Arch Linux
#
#linux    /vmlinuz-linux
#
#initrd    /amd-ucode.img
#initrd    /initramfs-linux.img
#

# Appending UUID to arch.conf
ID=$(blkid -s UUID -o value /dev/<partition>)
echo "options root=UUID=$ID rootflags=subvol=@ rw" >> \
/boot/loader/entries/arch.conf
lsblk -f && cat /boot/loader/entries/arch.conf
mkinitcpio -P

# Enable parallel downloads packages
nano /etc/pacman.conf
pacman -Syu

# Install YAY as normal user
su - <user>
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -sir
cd ~/
exit # return to root
#######################################################################

## Install Desktop Environment and Driver or
## alt. Install Hyprland by ML4W
## "bash <(curl -s https://ml4w.com/os/stable)"
#######################################################################
sudo pacman -Syu
sudo pacman -S plasma-meta dolphin konsole kate sddm xorg
sudo systemctl enable sddm
sudo pacman -S \
pipewire \
pipewire-pulse \
pipewire-alsa \
wireplumber
sudo pacman -S \
mesa \
vulkan-radeon \
lib32-vulkan-radeon \
steam \
btrfs-assistant \
libreoffice \
unzip \
p7zip
#######################################################################

## Snapper Setup (After Live USB)
#######################################################################
# Snapper setup dance - root
umount /.snapshots
rmdir /.snapshots
snapper -c root create-config /
btrfs subvolume delete /.snapshots
mkdir /.snapshots
mount -a
chmod 750 /.snapshots

# Snapper setup dance - home
umount /home/.snapshots
rmdir /home/.snapshots
snapper -c home create-config /home/
btrfs subvolume delete /home/.snapshots
mkdir /home/.snapshots
mount -a
chmod 750 /home/.snapshots

snapper -c root create --description "Fresh Arch Install"
snapper -c home create --description "Fresh Arch Install"
#######################################################################

## Snapper Recovery Rollback (From Live USB)
#######################################################################
# Recovery Root
lsblk -f
mount -o subvolid=5 /dev/<partition> /mnt
ls -la /mnt
mv /mnt/@ /mnt/@-broken
btrfs subvolume snapshot /mnt/@snapshots/<id>/snapshot /mnt/@
umount /mnt
reboot

# Recovery Home
lsblk -f
mount -o subvolid=5 /dev/<partition> /mnt
ls -la /mnt
mv /mnt/@home /mnt/@home-broken
btrfs subvolume snapshot /mnt/@snapshots_home/<id>/snapshot /mnt/@home
umount /mnt
reboot
#######################################################################
```