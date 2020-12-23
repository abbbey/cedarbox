#!/usr/bin/bash
# This script backs up nextcloud & jellyfin data. It mounts and decrypts Ursa
# drive and stores a snapshot of the nextcloud data and database to a
# timestamped dir.
#
# This is intended to be run manually, as it requires sudo and the Ursa
# encryption password. There are probably decent ways to automate these creds
# being loaded, but this works ok as backup only happens once a month.
#
# This uses a credentials file for accessing the nextcloud db. See below.
#
# Copyright 2020 Abigail Schubert
# This work is licensed under the terms of the GNU General Public License v3
# For a copy, see <https://www.gnu.org/licenses/>
set -o nounset

# URSA details
UUID=167817ed-7f11-48ff-b9e7-a7d70e03c08c
LUKS_DEV=$(realpath /dev/disk/by-uuid/"$UUID")
MAPPED_DEV=/dev/mapper/ursa
MOUNT_POINT=/media/ursa

# Backup details
NC_DATA_DIR=/media/pleiades/nextcloud
DB_USER_CREDENTIAL_FILE="$HOME"/credentials/nc_backup
JELLYFIN_MEDIA=/media/pleiades/jellyfin_media


if [[ ! -b "$LUKS_DEV" ]]; then
    echo "Error: Ursa not found. Check that it is connected."
    exit 1
fi

echo "Found ursa. Decrypting and mounting to $MOUNT_POINT"
sudo cryptsetup luksOpen "$LUKS_DEV" ursa
sudo mount "$MAPPED_DEV" "$MOUNT_POINT"

exit 0

# Create backup directory
BACKUP_DIR="${MOUNT_POINT}"/$(date +backup_%Y_%m_%d)
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


# Read db user/pw (and strip any whitespace using xargs)
mapfile -t < "$DB_USER_CREDENTIAL_FILE"
DB_USER=$(echo "${MAPFILE[0]}" | xargs)
DB_PW=$(echo "${MAPFILE[1]}" | xargs)


sudo -u www-data php /var/www/nextcloud/occ maintenance:mode --on

echo "Backing up $NC_DATA_DIR"
rsync -ar --delete --info=progress2 "$NC_DATA_DIR" "$BACKUP_DIR"

echo "Backing up nextcloud database"
mysqldump --single-transaction -u "$DB_USER" -p"$DB_PW" nextcloud > "$BACKUP_DIR"/nextcloud-sqlbkp.bak

sudo -u www-data php /var/www/nextcloud/occ maintenance:mode --off

echo "Completed nextcloud backup."
echo "Backing up $JELLYFIN_MEDIA"
rsync -ar --delete --info=progress2 "$JELLYFIN_MEDIA" "$BACKUP_DIR"

echo "Backup completed. Unmounting drive..."
sudo umount "$MOUNT_POINT"
sudo cryptsetup luksClose ursa
echo "Done."
