# Arch Linux Bootstrap Installer

**Arch Linux Bootstrap** adalah kerangka kerja pasca-instalasi yang dapat direproduksi untuk Arch Linux, dirancang berdasarkan snapshot Btrfs, systemd-boot, dan penyediaan desktop modular.

Dibuat untuk pengguna yang lebih suka memahami setiap lapisan sistem mereka.

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
| `4-user_sudoers.sh` | Buat user, set password, aktifkan sudo, install `yay` |
| `5-bootload_zram.sh` | Setup systemd-boot, `zram-generator`, dan `pacman.conf` |
| `6-desktop_environment.sh` | Install desktop environment dan paket pendukung |
| `7-setup_snapshots.sh` | Setup Snapper dan snapshot awal |

### `bash/v2/`
| File | Fungsi |
|---|---|
| `bootloader/grub-bios.sh` | Install bootloader menggunakan **GRUB** - `grub-bios.sh` untuk `firmware BIOS` |
| `bootloader/grub-efi.sh` | Install bootloader menggunakan **GRUB** - `grub-efi.sh` untuk `firmware EFI` |
| `bootloader/systemd-boot.sh` | Install bootloader menggunakan `systemd-boot` untuk `firmware EFI` |
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

### Untuk alur `v1` masuk ke folder `arch-install/bash/v1`

Jalankan skrip sesuai urutan nomornya dari lingkungan yang sesuai:
- skrip partisi dan mount dari **Arch live USB**
- skrip chroot di dalam **`arch-chroot /mnt`**
- skrip desktop dan snapshot setelah boot pertama sebagai user biasa

### Untuk alur `v2` yang lebih ringkas

```bash
# pastikan sudah clone repo (git clone https://github.com/archytech99/arch-install.git)
bash arch-install/bash/v2/01-partition-pacstrap.sh

# setelah selesai install:
mv arch-install/ /mnt/root
arch-chroot /mnt
cd /root
bash arch-install/bash/v2/02-chroot-setup.sh
chown <user>:<user> -R arch-install/
mv arch-install/ /home/<user>/
exit
umount -R /mnt
reboot

# setelah setup/konfigurasi chroot :
bash arch-install/bash/v2/03-desktop-snapper.sh
```

## Catatan penting

- Banyak skrip bersifat **destruktif**: ada `mkfs`, partisi disk, dan mount ulang.
- Skrip meminta input manual untuk disk, partisi, hostname, username, dan opsi desktop.
- Beberapa langkah masih interaktif dan tidak sepenuhnya non-interaktif.
- `v2` lebih praktis untuk pemakaian berulang karena alurnya sudah dikonsolidasi.
- Silahkan edit/update setiap skrip sesuai dengan kebutuhan.

## Backup folder

Folder `backup/` menyimpan konfigurasi dan data penting. Sebagian isinya bersifat sensitif, jadi pastikan hanya file yang memang ingin dibagikan yang ikut di-track.

## Status dokumen

README ini dibuat sebagai ringkasan struktur dan alur skrip di `bash/`.
Kalau nanti ada perubahan flow, cukup update tabel langkah dan daftar file di atas supaya tetap sinkron.

## Compatibility

| Component | Supported |
|---|---|
| Boot Mode | UEFI only |
| Filesystem | Btrfs only |
| Bootloader | systemd-boot |
| Desktop | KDE / Plasma / Hyprland |

## Keybinding

Dokumentasi shortcut keyboard untuk environment **Hyprland**.

### Modifier Keys

| Key             | Deskripsi              |
| --------------- | ---------------------- |
| `SUPER`         | Tombol Super / Windows |
| `SUPER + SHIFT` | Secondary modifier     |
| `SUPER + CTRL`  | Tertiary modifier      |
| `SUPER + ALT`   | Quaternary modifier      |

---

### General Keybindings

| Shortcut               | Fungsi                       |
| ---------------------- | ---------------------------- |
| `SUPER + ENTER`        | Membuka terminal             |
| `SUPER + X`            | Menutup window aktif         |
| `SUPER + E`            | Membuka file manager         |
| `SUPER + V`            | Membuka clipboard            |
| `SUPER + B`            | Membuka browser              |
| `SUPER + SHIFT + V`    | Toggle floating mode window  |
| `SUPER + SPACE`        | Membuka application launcher |
| `SUPER + CTRL + E`     | Membuka emoji picker         |
| `SUPER + CTRL + SPACE` | Membuka command runner       |
| `SUPER + CTRL + L`     | Logout / shutdown session    |
| `SUPER + P`            | Toggle pseudo tiling         |
| `SUPER + J`            | Toggle split layout          |

---

### Window Navigation

| Shortcut    | Fungsi                |
| ----------- | --------------------- |
| `SUPER + ←` | Fokus ke window kiri  |
| `SUPER + →` | Fokus ke window kanan |
| `SUPER + ↑` | Fokus ke window atas  |
| `SUPER + ↓` | Fokus ke window bawah |

---

### Workspace Management

#### Pindah workspace

| Shortcut       | Fungsi                  |
| -------------- | ----------------------- |
| `SUPER + 1..9` | Pindah ke workspace 1–9 |
| `SUPER + 0`    | Pindah ke workspace 10  |

#### Pindahkan window ke workspace

| Shortcut               | Fungsi                            |
| ---------------------- | --------------------------------- |
| `SUPER + SHIFT + 1..9` | Pindahkan window ke workspace 1–9 |
| `SUPER + SHIFT + 0`    | Pindahkan window ke workspace 10  |

#### Workspace cycling

| Shortcut                    | Fungsi               |
| --------------------------- | -------------------- |
| `SUPER + Mouse Scroll Down` | Workspace berikutnya |
| `SUPER + Mouse Scroll Up`   | Workspace sebelumnya |

---

### Mouse Actions

| Shortcut              | Fungsi        |
| --------------------- | ------------- |
| `SUPER + Left Click`  | Drag window   |
| `SUPER + Right Click` | Resize window |

---

### Audio Controls

| Shortcut      | Fungsi                 |
| ------------- | ---------------------- |
| `Volume Up`   | Naikkan volume +5%     |
| `Volume Down` | Turunkan volume -5%    |
| `Mute`        | Toggle mute speaker    |
| `Mic Mute`    | Toggle mute microphone |

---

### Brightness Controls

| Shortcut          | Fungsi                 |
| ----------------- | ---------------------- |
| `Brightness Up`   | Tambah brightness +5%  |
| `Brightness Down` | Kurangi brightness -5% |

---

### Media Controls

| Shortcut         | Fungsi             |
| ---------------- | ------------------ |
| `Next Track`     | Lagu berikutnya    |
| `Play / Pause`   | Play / Pause media |
| `Previous Track` | Lagu sebelumnya    |

---

### Notes

* Semua shortcut berbasis **Hyprland dispatcher**.
* Multimedia key (`XF86*`) bergantung pada keyboard/laptop yang mendukung.
* Audio control menggunakan:

  * `wpctl`
  * `playerctl`
* Brightness control menggunakan:

  * `brightnessctl`
