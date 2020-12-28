#!/usr/bin/bash
# This script will restore a Nextcloud backup to a fresh NC container.
# Requires a mysql data dump, created from old nc instance in maintenance mode.
# Expects _secret files in cwd as used by the docker-compose file.
#
# Copyright 2020 Abigail Schubert
# This work is licensed under the terms of the GNU General Public License v3
# For a copy, see <https://www.gnu.org/licenses/>

set -o errexit
set -o nounset

# Create sql dump of preexisting nc database using the following command:
# mysqldump --single-transaction -u "$DB_USER" -p"$DB_PW" nextcloud > mysql_dump.bak
MYSQL_DUMP="./mysql_dump.bak"

NC_DATA_BACKUP=/media/pleiades/nc_next
NC_DATA_DIR=/media/pleiades/nextcloud

APP_CONTAINER=nextcloud_app_1
DB_CONTAINER=nextcloud_db_1
WWW_DATA_USER=33

get_secret() {
    # Get secret from file
    local SECRET_FILE=$1
    local KEY=$2
    if [[ ! -e $SECRET_FILE ]]; then
        echo "ERROR: Could not read secret file $SECRET_FILE" >&2
        exit 1
    fi
    local VALUE=$(awk -F= -v key="$KEY" '$1 == key { print $2 }' $1)
    if [[ -z $VALUE ]]; then
        echo "ERROR: Could not find secret \"$KEY\" in $SECRET_FILE" >&2
        exit 1
    fi
    echo $VALUE
}

echo_e() {
    # Echo using backslash escapes
    echo -e $@
}

exec_mysql() {
    # Run a mysql command
    docker exec $DB_CONTAINER sh -c "mysql -p${MYSQL_ROOT_PW} --execute \"$1\""
}

exec_occ() {
    # Run an occ command (nextcloud cli). Pass in command and any args.
    local OCC_CMD="php /var/www/html/occ"
    docker exec -u $WWW_DATA_USER $APP_CONTAINER $OCC_CMD $@
}

set_maintenance_mode() {
    # Enable/Disable maintenance mode. Pass in 'on' or 'off'
    exec_occ maintenance:mode --"$1"
}

MYSQL_ROOT_PW=$(get_secret ./_secrets_mysql.txt "MYSQL_ROOT_PASSWORD")
NC_ADMIN_USER="'"$(get_secret ./_secrets_nextcloud.txt "NEXTCLOUD_ADMIN_USER")"'"
NC_ADMIN_PW="'"$(get_secret ./_secrets_nextcloud.txt "NEXTCLOUD_ADMIN_PASSWORD")"'"


# Add trailing slash on source dir or rsync will screw it up
i=$((${#NC_DATA_BACKUP}-1))
if [[ "${NC_DATA_BACKUP:$i:1}" != "/" ]]; then
    echo "adding stuff"
    NC_DATA_BACKUP=${NC_DATA_BACKUP}/
fi

# Confirm parameters before execution
echo_e "This process will restore $APP_CONTAINER and $DB_CONTAINER using backups"
echo_e "\tmysql_dump: \t$MYSQL_DUMP"
echo_e "\tdata backup:\t$NC_DATA_BACKUP"
echo_e "\tdata dest:  \t$NC_DATA_DIR"

read -p "If this is correct, type \"yolo\" to continue: " -r USER_CONFIRMS
if [[ $USER_CONFIRMS != 'yolo' ]]; then
    echo "Action aborted."
    exit 1
fi

echo_e "Beginning restoration process."
set_maintenance_mode on

echo_e "Rsync from backup"
sudo rsync -ar --delete --info=progress2 "$NC_DATA_BACKUP" "$NC_DATA_DIR"

echo_e "\nRemoving old nextcloud database"
exec_mysql "DROP DATABASE nextcloud;"

echo_e "\nRestoring mysql backup"
docker cp $MYSQL_DUMP "$DB_CONTAINER":/dmp
exec_mysql "CREATE DATABASE nextcloud;"
docker exec $DB_CONTAINER sh -c "mysql -p$MYSQL_ROOT_PW nextcloud < /dmp"
docker exec $DB_CONTAINER sh -c "rm /dmp"

echo_e "\nAdding back nc_admin privileges"
# Read nc username and password (and strip any whitespace using xargs)
# Two layers of \" so that the single-quotes persist thru all the variable expansions
exec_mysql "GRANT ALL PRIVILEGES ON nextcloud.* TO \"\"${NC_ADMIN_USER}\"\"
            IDENTIFIED BY \"\"${NC_ADMIN_PW}\"\";"

echo_e "\nFixing missing indices in nc database"
exec_occ db:add-missing-indices
echo_e "\nFixing missing primary keys in nc database"
exec_occ db:add-missing-primary-keys
echo_e "\nFixing missing columns in nc database"
exec_occ db:add-missing-columns

set_maintenance_mode off
echo_e "\nRestoration complete."
