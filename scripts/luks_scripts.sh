# Functions for mounting/unmounting ursa drive
#
# Copyright 2020 Abigail Schubert
# This work is licensed under the terms of the GNU General Public License v3
# For a copy, see <https://www.gnu.org/licenses/>

# This is where URSA gets mounted to
URSA_MOUNT_POINT=/media/ursa


mount_ursa() {
    # Mount ursa and map to $URSA_MOUNT_POINT
    local UUID=167817ed-7f11-48ff-b9e7-a7d70e03c08c
    local LUKS_DEV=$(realpath /dev/disk/by-uuid/"$UUID")
    local MAPPED_DEV=/dev/mapper/ursa

    if [[ ! -b "$LUKS_DEV" ]]; then
        echo "Error: Ursa not found. Check that it is connected."
        exit 1
    fi

    echo "Found ursa. Decrypting and mounting to $URSA_MOUNT_POINT"
    sudo cryptsetup luksOpen "$LUKS_DEV" ursa
    sudo mount "$MAPPED_DEV" "$URSA_MOUNT_POINT"
}


umount_ursa() {
    # Unmount ursa and remove luks mapping
    echo "Unmounting ursa"
    sudo umount "$URSA_MOUNT_POINT"
    sudo cryptsetup luksClose ursa
}
