## Nextcloud Build Scripts

This directory contains dockerfiles and scripts for running a Nextcloud instance.
https://docs.nextcloud.com/

### Prerequisites

There are a couple manual tasks before the scripts can be run.

First, create the data directory. Currently this is configured as
`/media/pleiades/nextcloud`. If dockremap is enabled, make sure the mapped user
has permissions on this location.

Second, create the two credential files for the app, used to set environment
variables within the docker containers. Use shell syntax of VARIABLE=VALUE, with
one variable per line. Create:
*  `./_secrets_mysql.txt` containing assignments for the following vars:
   * `MYSQL_ROOT_PASSWORD`
   * `MYSQL_USER`
   * `MYSQL_USER_PASSWORD`
*  `./_secret_nextcloud.txt` containing assignments for:
   * `MYSQL_USER`
   * `MYSQL_USER_PASSWORD`
   * `NEXTCLOUD_ADMIN_USER`
   * `NEXTCLOUD_ADMIN_PASSWORD`

These are used by `docker-compose.yaml` and the `restore_backup.sh` script.

### Running Nextcloud

Once the prerequisites are fulfilled, run the nextcloud app by running `make`.

Nextcloud app will be available at localhost:8080

### Restoring from backup

A fresh Nextcloud container can be restored from backup data by executing the
`restore_backup.sh` script. Read the documentation in that script for
instructions.
