#!/bin/bash

# Backup script for db.tp2.linux
# Edited : 24/10/2021 17:31
# Author : Fabian INGREMEAU
# Version : 1.0.0

database=$2
destFolder=$1
tarName="$(date '+tp2_backup_db_%Y%m%d_%T' | tr -d :).tar"

mysqldump "$database" --user=root --password=root > backup.sql

tar cvf $tarName "backup.sql"
gzip $tarName

pushd $destFolder

nbOfBackups="$(ls | wc -l)"
if [ $nbOfBackups -eq 5 ]
then
	rm "$(ls -t | tail -1)"
fi

popd

rsync -av --remove-source-files "$tarName.gz" $destFolder

rm backup.sql
