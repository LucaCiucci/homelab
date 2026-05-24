# My Home Server configuration

This subdirectory contains the services used on my Raspberry Pi 4b home server.

Main services:
- Gitolite
- Samba
- Vaultwarden
- Glances
- restic server
- Caddy to glue everything together

## Testing locally

To test it locally::
```bash
./setup_test_env.bash
```
Then, I can run the services with:
```bash
docker compose up
```

## Deploying to the Raspberry Pi

> [!IMPORTANT]
> Additional setup is required, see the [Raspberry setup](#raspberry-setup) section below.

To deploy the services to the Raspberry Pi, I set:
```bash
docker compose down
git pull --rebase
docker compose up -d
```

## Backups

The [`snapshot.sh`](./snapshot.sh) script can be used to create safe snapshots of the data. These should then be synced externally with a restic.

To delete old snapshots, use [`delete_snapshots.nu`](./delete_snapshots.nu).

## Raspberry setup

This configuration expects a `btrfs` mounted at `/media/luca/rpi-data`, with the
subvolumes listed in [`.env.raspberry`](.env.raspberry) created. Snapshots will be
saved in `/media/luca/rpi-data/.snapshots`.

### Creating the btrfs subvolumes

To create the subvolumes, I run:
```bash
cd /media/luca/rpi-data
sudo btrfs subvolume create @gitolite
sudo btrfs subvolume create @vaultwarden
# ...
```
The full list of subvolumes to be created is in [`.env.raspberry`](.env.raspberry).

### Setup disk mount

During a the boot, docker could start the services before the disk is mounted, causing them to see an empty directory instead of the data. To avoid this, we have to ensure that the disk is mounted before docker starts.

To do this, we first find the UUID of the disk with:
```bash
lsblk -o NAME,FSTYPE,UUID,LABEL,MOUNTPOINTS
```
Then, we edit the `/etc/fstab` file to add the following line:
```bash
UUID=THE_DISK_UUID /mnt/rpi-data btrfs defaults,nofail,noatime 0 2
```
Note that we have to add the `nofail` option to avoid booting issues if the disk is not present, and the `noatime` should help with performance and disk wear.

Systemd will create a mount unit for this named `mnt-rpi\x2ddata.mount`, which we can use to make docker wait. So add a systemd override for the docker service with:
```bash
sudo systemctl edit docker.service
```
And add the following content:
```ini
[Unit]
After=mnt-rpi\x2ddata.mount
Requires=mnt-rpi\x2ddata.mount
```
This will ensure that docker starts only after the disk is mounted, and if the disk fails to mount, docker will not start at all. `sudo systemctl daemon-reload` to apply the changes.

Now, there are 3 possible scenarios in the future:
1. If the disk is present and mounts successfully, docker will start as normal.
2. If the disk is not present, or fails to mount, docker will not start, and we will see an error in the logs about the missing mount (`journalctl -u docker.service`).
3. If the `/etc/fstab` entry is removed, docker will refuse to start because of `Requires=mnt-rpi\x2ddata.mount`, and we will see an error in the logs about the missing mount (`journalctl -u docker.service`).

So for scenario (2) and (3), we can undo it by removing the `/etc/fstab` entry and the systemd override:
```bash
sudo rm /etc/systemd/system/docker.service.d/override.conf
sudo systemctl daemon-reload
```

Some more info [here](https://share.google/aimode/4LYaipL1ZgDTPXt0y).

### Creating the samba password files

Add the necessary password files in [`samba/pwd/`](./samba/pwd/), see [the readme](./samba/pwd/README.md) for more details.
