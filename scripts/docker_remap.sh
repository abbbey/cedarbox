#!/usr/bin/bash
# Create users for docker namespace remapping. Creates whale_root, whale_www,
# and whale_user which map to container root/www-data/user.
#
# User namespace remapping must be enabled in docker first by adding
# { "userns-remap": "default" } to /etc/docker/daemon.json and restarting
# docker daemon. Docker will create a mapping in /etc/subuid showing the uid
# relationship between host uids and container uids.
#
# Copyright 2020 Abigail Schubert
# This work is licensed under the terms of the GNU General Public License v3
# For a copy, see <https://www.gnu.org/licenses/>

set -ue

BASE_ID=$(awk -F: '$1 == "dockremap" { print $2 }' /etc/subuid)

# Check to see we successfully got base uid
if [[ -z $BASE_ID ]]; then
    echo "ERROR: Couldn't find dockremap offset in /etc/subuid. Have you "
    echo "       enabled it in /etc/docker/daemon.json?"
    exit 1
fi

ROOT_ID=$BASE_ID
WWW_ID=$(expr $BASE_ID + 33)
USER_ID=$(expr $BASE_ID + 1000)

add_user() {
    # Add user. Specify uid/gid as $1 and user name as $2
    sudo groupadd -g "$1" "$2"
    sudo useradd --uid "$1" --gid "$1" -s /sbin/nologin --no-create-home "$2"
}

echo "Creating user whale_root with uid $ROOT_ID"
add_user "$ROOT_ID" whale_root
echo "Creating user whale_www with uid $WWW_ID"
add_user "$WWW_ID" whale_www
echo "Creating user whale_user with uid $USER_ID"
add_user "$USER_ID" whale_user

