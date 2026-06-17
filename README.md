# Arch Linux Bootstrap Installer

**Arch Linux Bootstrap** is a reproducible post-installation framework for Arch Linux, designed around Btrfs snapshots, systemd-boot, and modular desktop provisioning.

Built for users who prefer to understand every layer of their system.

This repository contains two main installation flows:

* **`bash/v1/`** — legacy step-by-step installation flow, separated by individual stages.
* **`bash/v2/`** — streamlined installation flow, consolidated into 3 main stages.

> All scripts rely on `source ../.env` for helper functions such as `info`, `success`, `warn`, and `die`.

## Folder Structure

| Path          | Content                             |
| ------------- | ----------------------------------- |
| `bash/v1/`    | Legacy version, step-by-step        |
| `bash/v2/`    | Newer, more compact version         |
| `backup/`     | User configuration and data backups |
| `cheat-sheet` | Quick notes / references            |

## Installation Flow Overview

### `v1` Flow

1. Partition disk, format, and create Btrfs subvolumes
2. Mount all partitions and subvolumes
3. `pacstrap` base packages into `/mnt`
4. Configure timezone, locale, and hostname
5. Create user, enable `sudo`, enable services
6. Install systemd-boot and configure `zram`
7. Setup desktop environment
8. Setup Snapper snapshots

### `v2` Flow

1. `01-partition-pacstrap.sh`

   * Partition disk
   * Format EFI and root
   * Create Btrfs subvolumes
   * Mount final filesystem layout
   * Install base packages using `pacstrap`

2. `02-chroot-setup.sh`

   * Timezone, locale, hostname
   * User and password
   * Sudoers configuration
   * Core services
   * `systemd-boot` bootloader
   * `pacman.conf`, `mkinitcpio`, `zram`, `yay`

3. `03-desktop-snapper.sh`

   * Choose desktop: KDE Plasma or Hyprland via ML4W
   * Install audio stack, drivers, and applications
   * Setup Snapper for root and home
   * Create initial snapshots

## Script List

### `bash/v1/`

| File                       | Function                                                |
| -------------------------- | ------------------------------------------------------- |
| `0-btrfs_mnt.sh`           | Partition disk, format, create Btrfs subvolumes         |
| `1-mount_mnt.sh`           | Mount all subvolumes to `/mnt`                          |
| `2-pacstrap_mnt.sh`        | Install base packages to target system                  |
| `3-lctime-hostname.sh`     | Configure timezone, locale, hostname                    |
| `4-user_sudoers.sh`        | Create user, set password, enable sudo, install `yay`   |
| `5-bootload_zram.sh`       | Setup systemd-boot, `zram-generator`, and `pacman.conf` |
| `6-desktop_environment.sh` | Install desktop environment and supporting packages     |
| `7-setup_snapshots.sh`     | Setup Snapper and initial snapshots                     |

### `bash/v2/`

| File                         | Function                                                   |
| ---------------------------- | ---------------------------------------------------------- |
| `bootloader/grub-bios.sh`    | Install bootloader using **GRUB** for `BIOS firmware`      |
| `bootloader/grub-efi.sh`     | Install bootloader using **GRUB** for `EFI firmware`       |
| `bootloader/systemd-boot.sh` | Install bootloader using `systemd-boot` for `EFI firmware` |
| `01-partition-pacstrap.sh`   | Combined partitioning, mounting, and pacstrap              |
| `02-chroot-setup.sh`         | System configuration inside chroot                         |
| `03-desktop-snapper.sh`      | Desktop environment + Snapper                              |

## Requirements

These scripts are intended to run in an Arch Linux environment and require:

* `root` access or `sudo` depending on the stage
* Partitioning and filesystem utilities (`cfdisk`, `mkfs.fat`, `mkfs.btrfs`, `btrfs-progs`)
* Internet connection for package installation
* Manually selected EFI partition and Btrfs root partition
* Companion `.env` file providing output helpers and validation

## Usage

### For `v1` flow

Enter the folder `arch-install/bash/v1`.

Run scripts sequentially according to their numbering in the appropriate environment:

* Partitioning and mounting scripts from **Arch live USB**
* Chroot scripts inside **`arch-chroot /mnt`**
* Desktop and snapshot scripts after first boot as a regular user

### For the streamlined `v2` flow

```bash
# make sure the repo has been cloned
git clone https://github.com/archytech99/arch-install.git

bash arch-install/bash/v2/01-partition-pacstrap.sh

# after installation:
mv arch-install/ /mnt/root
arch-chroot /mnt
cd /root
bash arch-install/bash/v2/02-chroot-setup.sh
chown <user>:<user> -R arch-install/
mv arch-install/ /home/<user>/
exit
umount -R /mnt
reboot

# after chroot setup and first boot:
bash arch-install/bash/v2/03-desktop-snapper.sh
```

## Important Notes

* Many scripts are **destructive**: they include `mkfs`, disk partitioning, and remount operations.
* Scripts require manual input for disk, partition, hostname, username, and desktop options.
* Some steps remain interactive and are not fully non-interactive.
* `v2` is more practical for repeated installations due to its consolidated workflow.
* Feel free to modify or update each script according to your needs.

## Backup Folder

The `backup/` directory stores important configurations and data. Some files may contain sensitive information, so ensure only intended files are tracked or shared.

## Documentation Status

This README serves as a structural and workflow summary of scripts inside `bash/`.

If the installation flow changes later, simply update the step tables and file list above to keep everything synchronized.

## Compatibility

| Component  | Supported             |
| ---------- | --------------------- |
| Boot Mode  | BIOS and UEFI         |
| Filesystem | Btrfs only            |
| Bootloader | systemd-boot and GRUB |
| Desktop    | KDE Plasma / Hyprland |

## Keybindings

Keyboard shortcut documentation for the **Hyprland** environment.

### Modifier Keys

| Key             | Description         |
| --------------- | ------------------- |
| `SUPER`         | Super / Windows key |
| `SUPER + SHIFT` | Secondary modifier  |
| `SUPER + CTRL`  | Tertiary modifier   |
| `SUPER + ALT`   | Quaternary modifier |

---

### General Keybindings

| Shortcut               | Function                  |
| ---------------------- | ------------------------- |
| `SUPER + ENTER`        | Open terminal             |
| `SUPER + X`            | Close active window       |
| `SUPER + E`            | Open file manager         |
| `SUPER + V`            | Open clipboard            |
| `SUPER + B`            | Open browser              |
| `SUPER + SHIFT + V`    | Toggle floating mode      |
| `SUPER + SPACE`        | Open application launcher |
| `SUPER + CTRL + E`     | Open emoji picker         |
| `SUPER + CTRL + SPACE` | Open command runner       |
| `SUPER + CTRL + L`     | Logout / shutdown session |
| `SUPER + P`            | Toggle pseudo tiling      |
| `SUPER + J`            | Toggle split layout       |

---

### Window Navigation

| Shortcut    | Function           |
| ----------- | ------------------ |
| `SUPER + ←` | Focus left window  |
| `SUPER + →` | Focus right window |
| `SUPER + ↑` | Focus upper window |
| `SUPER + ↓` | Focus lower window |

---

### Workspace Management

#### Switch Workspace

| Shortcut       | Function                |
| -------------- | ----------------------- |
| `SUPER + 1..9` | Switch to workspace 1–9 |
| `SUPER + 0`    | Switch to workspace 10  |

#### Move Window to Workspace

| Shortcut               | Function                     |
| ---------------------- | ---------------------------- |
| `SUPER + SHIFT + 1..9` | Move window to workspace 1–9 |
| `SUPER + SHIFT + 0`    | Move window to workspace 10  |

#### Workspace Cycling

| Shortcut                    | Function           |
| --------------------------- | ------------------ |
| `SUPER + Mouse Scroll Down` | Next workspace     |
| `SUPER + Mouse Scroll Up`   | Previous workspace |

---

### Mouse Actions

| Shortcut              | Function      |
| --------------------- | ------------- |
| `SUPER + Left Click`  | Drag window   |
| `SUPER + Right Click` | Resize window |

---

### Audio Controls

| Shortcut      | Function               |
| ------------- | ---------------------- |
| `Volume Up`   | Increase volume +5%    |
| `Volume Down` | Decrease volume -5%    |
| `Mute`        | Toggle speaker mute    |
| `Mic Mute`    | Toggle microphone mute |

---

### Brightness Controls

| Shortcut          | Function                |
| ----------------- | ----------------------- |
| `Brightness Up`   | Increase brightness +5% |
| `Brightness Down` | Decrease brightness -5% |

---

### Media Controls

| Shortcut         | Function           |
| ---------------- | ------------------ |
| `Next Track`     | Next track         |
| `Play / Pause`   | Play / Pause media |
| `Previous Track` | Previous track     |

---

### Notes

* All shortcuts are based on **Hyprland dispatchers**.

* Multimedia keys (`XF86*`) depend on keyboard/laptop support.

* Audio control uses:

  * `wpctl`
  * `playerctl`

* Brightness control uses:

  * `brightnessctl`
