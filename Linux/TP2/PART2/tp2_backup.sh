#!/bin/bash

# Backup script for web.tp2.linux
# Edited : 12/10/2021 10:30
# Author : Fabian INGREMEAU
# Version : 1.0.0

argsArray=( "$@" )
argsArray=("${argsArray[@]:1}")
destFolder=$1
tarName="$(date '+tp2_backup_%Y%m%d_%T' | tr -d :).tar"
exportName=/srv/backup/web.tp2.linux/"$(date '+tp2_backup_%Y%m%d_%T' | tr -d :)"

tar cvf $tarName --files-from /dev/null
for item in "${argsArray[@]}"
do
	tar rf $tarName "$item"
done
gzip $tarName

pushd $destFolder

nbOfBackups="$(ls | wc -l)"
if [ $nbOfBackups -eq 5 ]
then
	rm "$(ls -t | tail -1)"
fi

popd

rsync -av --remove-source-files "$tarName.gz" $destFolder
