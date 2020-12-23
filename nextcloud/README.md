## Nextcloud Build Scripts

This directory contains dockerfiles and scripts for running a Nextcloud instance.
https://docs.nextcloud.com/

### Prerequisites

There are a couple manual tasks before the scripts can be run.

First, create the data directory. Currently this is configured as
`/media/pleiades/nextcloud`.

Second, create the three secret credential files for the app. They should be
located within this directory. Create:
*  `_secret_mysql_root_pw.txt`
*  `_secret_nc_admin_user.txt`
*  `_secret_nc_admin_pw.txt`

These are used by `docker-compose.yaml` and the `restore_backup.sh` script.

### Running Nextcloud

Once the prerequisites are fulfilled, run the nextcloud app by running `make`.

### Restoring from backup

A fresh Nextcloud container can be restored from backup data by executing the
`restore_backup.sh` script. Read the documentation in that script for
instructions.
