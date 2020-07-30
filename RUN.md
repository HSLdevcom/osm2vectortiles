# RUN.md

Build vector tile package and upload it to Azure blob storage

# Prerequisites

Clone `hsldevcom/osm2vectortiles`

Build local images that include swedish names etc.:
```
make import-osm
make import-sql
```

Install `azcopy`

```
wget -O azcopyv10.tar https://azcopyvnext.azureedge.net/release20190703/azcopy_linux_amd64_10.2.1.tar.gz

tar -xf azcopyv10.tar --strip-components=1

sudo chmod +x azcopy && sudo mv azcopy /usr/bin/
```

Set valid [Azure SAS-key](https://docs.microsoft.com/en-us/azure/storage/common/storage-dotnet-shared-access-signature-part-1) with write access for Azure storage blob container.

```
export AZURE_BLOB_SAS_ACCESS_KEY=<mysecrettoken>
```

# Crontab

Open crontab for editing:
```
crontab -e
```
If you run the the script with crontab, you need to make sure crontab has access to env AZURE_BLOB_SAS_ACCESS_KEY.

Add the following lines (notice the absolute paths that have to be updated):
```
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
AZURE_BLOB_SAS_ACCESS_KEY=<mysecrettoken>

0 1 * * 1,4 cd /[path]/osm2vectortiles && ./run.sh > /dev/null 2> /[path]/run.log
```
This sets the crontab to run every week on Mondays and Thursdays night at 1:00.
