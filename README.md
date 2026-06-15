# Postinstall

Kumpulan skrip *post-install* untuk instalasi Arch Linux berbasis **Btrfs + systemd-boot + Snapper**.

Repo ini punya dua jalur utama:
- **`bash/v1/`** — alur instalasi bertahap, dipisah per langkah.
- **`bash/v2/`** — alur instalasi yang lebih ringkas, digabung jadi 3 tahap utama.

> Semua skrip mengandalkan `source ../.env` untuk fungsi helper seperti `info`, `success`, `warn`, dan `die`.

## Struktur folder

| Path | Isi |
|---|---|
| `bash/v1/` | Versi lama, langkah demi langkah |
| `bash/v2/` | Versi baru, lebih ringkas |
| `backup/` | Backup konfigurasi dan data pengguna |
| `cheat-sheet` | Catatan cepat / referensi |

## Gambaran alur instalasi

### Alur `v1`
1. Partisi disk, format, dan buat subvolume Btrfs
2. Mount semua partisi dan subvolume
3. `pacstrap` paket dasar ke `/mnt`
4. Set timezone, locale, hostname
5. Buat user, aktifkan `sudo`, enable service
6. Install systemd-boot dan konfigurasi `zram`
7. Setup desktop environment
8. Setup Snapper snapshot

### Alur `v2`
1. `01-partition-pacstrap.sh`
   - Partisi disk
   - Format EFI dan root
   - Buat subvolume Btrfs
   - Mount layout final
   - Install paket dasar dengan `pacstrap`
2. `02-chroot-setup.sh`
   - Timezone, locale, hostname
   - User dan password
   - Sudoers
   - Service dasar
   - Bootloader `systemd-boot`
   - `pacman.conf`, `mkinitcpio`, `zram`, `yay`
3. `03-desktop-snapper.sh`
   - Pilih desktop: KDE Plasma atau Hyprland via ML4W
   - Install audio stack, driver, dan aplikasi
   - Setup Snapper root dan home
   - Buat snapshot awal

## Daftar skrip

### `bash/v1/`
| File | Fungsi |
|---|---|
| `0-btrfs_mnt.sh` | Partisi disk, format, buat subvolume Btrfs |
| `1-mount_mnt.sh` | Mount semua subvolume ke `/mnt` |
| `2-pacstrap_mnt.sh` | Install paket dasar ke sistem target |
| `3-lctime-hostname.sh` | Set timezone, locale, dan hostname |
| `4-gen_uuid.sh` | Generate UUID root dan cek entry bootloader |
| `5-user_sudoers.sh` | Buat user, set password, aktifkan sudo, install `yay` |
| `6-bootload_zram.sh` | Setup systemd-boot, `zram-generator`, dan `pacman.conf` |
| `6-desktop_environment.sh` | Install desktop environment dan paket pendukung |
| `7-setup_snapshots.sh` | Setup Snapper dan snapshot awal |

### `bash/v2/`
| File | Fungsi |
|---|---|
| `01-partition-pacstrap.sh` | Gabungan partisi, mount, dan pacstrap |
| `02-chroot-setup.sh` | Konfigurasi sistem di dalam chroot |
| `03-desktop-snapper.sh` | Desktop environment + Snapper |

## Prasyarat

Skrip ini diasumsikan dijalankan di lingkungan Arch Linux dan membutuhkan:
- akses `root` atau `sudo` sesuai tahap
- paket utilitas partisi dan filesystem (`cfdisk`, `mkfs.fat`, `mkfs.btrfs`, `btrfs-progs`)
- koneksi internet untuk instalasi paket
- partisi EFI dan root Btrfs yang sudah dipilih manual
- file `.env` pendamping yang menyediakan helper output dan validasi

## Cara pakai

### Untuk alur `v2` yang lebih ringkas

```bash
cd /data/WorkBase/Postinstall/bash/v2
bash 01-partition-pacstrap.sh
arch-chroot /mnt
bash /root/02-chroot-setup.sh
exit
umount -R /mnt
reboot
# setelah boot pertama:
bash 03-desktop-snapper.sh
```

### Untuk alur `v1`

Jalankan skrip sesuai urutan nomornya dari lingkungan yang sesuai:
- skrip partisi dan mount dari **Arch live USB**
- skrip chroot di dalam **`arch-chroot /mnt`**
- skrip desktop dan snapshot setelah boot pertama sebagai user biasa

## Catatan penting

- Banyak skrip bersifat **destruktif**: ada `mkfs`, partisi disk, dan mount ulang.
- Skrip meminta input manual untuk disk, partisi, hostname, username, dan opsi desktop.
- Beberapa langkah masih interaktif dan tidak sepenuhnya non-interaktif.
- `v2` lebih praktis untuk pemakaian berulang karena alurnya sudah dikonsolidasi.

## Backup folder

Folder `backup/` menyimpan konfigurasi dan data penting. Sebagian isinya bersifat sensitif, jadi pastikan hanya file yang memang ingin dibagikan yang ikut di-track.

## Status dokumen

README ini dibuat sebagai ringkasan struktur dan alur skrip di `bash/`.
Kalau nanti ada perubahan flow, cukup update tabel langkah dan daftar file di atas supaya tetap sinkron.

## Cheat Sheets (log install)

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
cd ~
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