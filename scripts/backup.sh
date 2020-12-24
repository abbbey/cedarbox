#!/usr/bin/bash
# This script backs up nextcloud & jellyfin data. It mounts and decrypts Ursa
# drive and stores a snapshot of the nextcloud data and database to a
# timestamped dir.
#
# This is intended to be run manually, as it requires sudo and the Ursa
# encryption password. There are probably decent ways to automate these creds
# being loaded, but this works ok as backup only happens once a month.
#
# Copyright 2020 Abigail Schubert
# This work is licensed under the terms of the GNU General Public License v3
# For a copy, see <https://www.gnu.org/licenses/>
set -eu

# Backup details
NC_DATA_DIR=/media/pleiades/nextcloud
JELLYFIN_MEDIA=/media/pleiades/jellyfin_media

# Mount and decrypt external drive
source luks_scripts.sh
mount_ursa

# Create backup directory
BACKUP_DIR="${URSA_MOUNT_POINT}"/$(date +backup_%Y_%m_%d)
if [[ -d "$BACKUP_DIR" ]]; then
    echo "Backup dir already exists!"
else
    mkdir "$BACKUP_DIR"
    if [[ ! -d "$BACKUP_DIR" ]]; then
        echo "Tried to create $BACKUP_DIR but it doesn't exist?!"
        exit 1
    fi
    echo "Created backup directory $BACKUP_DIR"
fi

# Backup Nextcloud
source nextcloud_scripts.sh
backup_nextcloud "$NC_DATA_DIR" "$BACKUP_DIR"

# Backup Jellyfin
echo "Backing up $JELLYFIN_MEDIA"
rsync -ar --delete --info=progress2 "$JELLYFIN_MEDIA" "$BACKUP_DIR"

echo "Backup completed. Unmounting drive..."
umount_ursa
echo "Done."
