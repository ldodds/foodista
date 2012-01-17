#!/bin/sh

DATA_BUCKET="b-foodista-z9h6vavo"
SOURCE_URI="https://raw.github.com/castagna/foodista/master/foodista.sh"
MANIFEST_URI="https://${AWS_S3_BUCKET_NAME}.s3.amazonaws.com/${AWS_S3_PATH}/manifest.json"

sudo apt-get install -y ruby rubygems
sudo gem install htmlentities hpricot rdf 

echo "getting foodista code"
cd /mnt/data || exit 255

git clone git://github.com/castagna/foodista.git
cd /mnt/data/foodista || exit 255

echo "crawling foodista"
rake publish

echo "uploading result to S3"
s3cmd --no-progress -P -m application/x-gzip put data.gz \
    s3://${AWS_S3_BUCKET_NAME}/${AWS_S3_PATH}/foodista.gz || exit 255

echo "adding additional build metadata"
curl --silent -i -X POST -H "Content-Type: text/turtle" -T meta.ttl \
    --digest -u "${COHODO_USER}:${COHODO_PASS}" \
    "http://db.cohodo.net/updates/direct/${BUILD_BUCKET}?graph=${BUILD_URI}" || exit 255

status=`ingest ${MANIFEST_URI} ${DATA_BUCKET} ${SOURCE_URI}`
annotate rdfs:seeAlso ${status}

