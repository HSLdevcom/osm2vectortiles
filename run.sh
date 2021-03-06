#!/bin/bash
set -e

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

export AZURE_STORAGE_ACCOUNT=hslstoragekarttatuotanto

export CONTAINER_NAME=tiles
export BLOB_NAME=tiles.mbtiles
export FILENAME=export/tiles.mbtiles
export PREVIOUS_EXPORT_FILENAME=export/prev/old_tiles.mbtiles
export MIN_SIZE=660000000

if [ -f $FILENAME ]; then
    mkdir -p export/prev
    mv -f $FILENAME $PREVIOUS_EXPORT_FILENAME
fi

curl -sSfL "https://karttapalvelu.storage.hsldev.com/finland.osm/finland.osm.pbf" -o import/finland-latest.osm.pbf

docker-compose stop
docker-compose rm -f

docker-compose up -d postgis

sleep 1m

docker-compose run import-external

docker-compose up import-osm

docker-compose run import-sql

docker-compose run -e BBOX="18.9832098,59.3541578,31.6867044,70.1922939" -e MIN_ZOOM="0" -e MAX_ZOOM="14" export

docker-compose down -v

if [ ! -f $FILENAME ]; then
    (echo >&2 "File not found, exiting")
    exit 1
fi

if [ $(wc -c <"$FILENAME") -lt $MIN_SIZE ]; then
    (echo >&2 "File size under minimum, exiting")
    exit 1
fi

if [ -z "$AZURE_BLOB_SAS_ACCESS_KEY" ]; then
    (echo >&2 "\$AZURE_BLOB_SAS_ACCESS_KEY is empty. Cannot upload mbtiles to Blob, exiting")
    exit 1
fi

URL="https://"$AZURE_STORAGE_ACCOUNT".blob.core.windows.net/"$CONTAINER_NAME"/tiles.mbtiles"
URL_WITH_SAS=$URL"?"$AZURE_BLOB_SAS_ACCESS_KEY
echo "Uploading... to " $URL
azcopy copy $FILENAME $URL_WITH_SAS
echo "Done."
