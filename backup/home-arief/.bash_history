clear
ln -sf /usr/share/zoneinfo/Asia/Jakarta /etc/localtime
hwclock --systohc
nano /etc/locale.gen
locale-gen
echo LANG=en_US.UTF-8 /etc/locale.conf
echo "archytech" /etc/hostname
EDITOR=nano visudo
systemctl enable NetworkManager
nano /etc/pacman.conf
pacman -Syu
mkdir git && cd git && git clone https://aur.archlinux.org/yay.git
cd yay/
makepkg -sir
