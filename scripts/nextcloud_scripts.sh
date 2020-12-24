# Script resources for maintaining Nextcloud instance
#
# Copyright 2020 Abigail Schubert
# This work is licensed under the terms of the GNU General Public License v3
# For a copy, see <https://www.gnu.org/licenses/>

# Name of docker containers with nextcloud app and nextcloud database
APP_CONTAINER=nextcloud_app_1
DB_CONTAINER=nextcloud_db_1

# Credential file to get db username/password from.
DB_USER_CREDENTIAL_FILE="$HOME"/credentials/nc_backup

# User ID of linux user to use for executing occ commands
WWW_DATA_USER=33


exec_occ() {
    # Run an occ command (Nextcloud cli). Pass in command and any args.
    local OCC_CMD="php /var/www/html/occ"
    docker exec -u $WWW_DATA_USER $APP_CONTAINER $OCC_CMD $@
}


set_maintenance_mode() {
    # Enable/Disable maintenance mode. Pass in 'on' or 'off'
    exec_occ maintenance:mode --"$1"
}


dump_mysql() {
    # Dump mysql data to file. Requires destination folder argument $1
    mapfile -t < "$DB_USER_CREDENTIAL_FILE"
    local DB_USER=$(echo "${MAPFILE[0]}" | xargs)
    local DB_PW=$(echo "${MAPFILE[1]}" | xargs)
    local DEST="$1"/nextcloud-sqlbkp.bak
    local COMMAND="mysqldump --single-transaction -u \"$DB_USER\" -p\"${DB_PW}\" nextcloud"
    docker exec $DB_CONTAINER sh -c "$COMMAND" > "$DEST"
}


backup_nextcloud() {
    # Backup Nextcloud data. Requires two arguments: a source of data dir and a
    # destination directory to place the backup in.
    if [[ "$#" != 2 ]]; then
        echo "Wrong number of arguments. Requires source and dest directories."
        exit 1
    fi
    # strip trailing slash, if any. We want rsync to create new directory.
    local NC_DATA_DIR=${1%/}
    local BACKUP_DIR=${2%/}

    if [[ ! -d "$NC_DATA_DIR" ]]; then
        echo "ERROR: Nextcloud data directory does not exist!"
        echo "Expected: $NC_DATA_DIR"
        exit 1
    fi
    if [[ ! -d "$BACKUP_DIR" ]]; then
        echo "ERROR: Nextcloud data directory does not exist!"
        echo "Expected: $BACKUP_DIR"
        exit 1
    fi

    set_maintenance_mode on

    echo "Backing up $NC_DATA_DIR to $BACKUP_DIR"
    rsync -ar --delete --info=progress2 "$NC_DATA_DIR" "$BACKUP_DIR"

    echo "Backing up nextcloud database"
    dump_mysql "$BACKUP_DIR"

    set_maintenance_mode off
    echo "Completed nextcloud backup."
}

