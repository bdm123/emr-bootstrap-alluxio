#!/bin/bash

version=$1
memory_size=$2
s3_bucket_name=$3
[[ -z $version ]] && version=1.6.0
[[ -z $memory_size ]] && memory_size=2GB


# prepare
sudo wget https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64 -O /usr/local/bin/jq
sudo chmod 755 /usr/local/bin/jq

ismaster=`cat /mnt/var/lib/info/instance.json | jq -r '.isMaster'`
masterdns=`cat /mnt/var/lib/info/job-flow.json | jq -r '.masterPrivateDnsName'`

cd /usr/local

# Download alluxio
sudo wget http://alluxio.org/downloads/files/${version}/alluxio-${version}-hadoop-2.7-bin.tar.gz -P /tmp
sudo tar -zxf /tmp/alluxio-${version}-hadoop-2.7-bin.tar.gz
sudo mv alluxio-* alluxio
sudo chown -R hadoop:hadoop alluxio

# Download client
#sudo wget http://downloads.alluxio.org/downloads/files/${version}/alluxio-core-client-spark-${version}-jar-with-dependencies.jar

initialize_alluxio () {
  cd /usr/local/alluxio
  sudo chown -R hadoop:hadoop .
  # config
  sed -i '/ALLUXIO_WORKER_MEMORY_SIZE/d' ./conf/alluxio-env.sh
  echo "ALLUXIO_WORKER_MEMORY_SIZE=${memory_size}" >> ./conf/alluxio-env.sh
  echo "ALLUXIO_UNDERFS_ADDRESS=\"s3a://${s3_bucket_name}\"" >> ./conf/alluxio-env.sh
  
  cp conf/alluxio-site.properties.template conf/alluxio-site.properties
  echo "alluxio.security.authorization.permission.enabled=false" >> ./conf/alluxio-site.properties
  echo "alluxio.user.block.size.bytes.default=128MB" >> ./conf/alluxio-site.properties

}

cd /usr/local/alluxio

if [[ ${ismaster} == "true" ]]; then
  [[ ${masterdns} == "localhost" ]] && masterdns=`hostname -f`
  # bootstrap
  sudo ./bin/alluxio bootstrapConf ${masterdns}

  # initialize
  initialize_alluxio
 
  # Format
  sudo ./bin/alluxio format
  # Start master
  sudo ./bin/alluxio-start.sh master
else
  # bootstrap
  sudo ./bin/alluxio bootstrapConf ${masterdns}  

  # initialize
  initialize_alluxio

  # Format
  sudo ./bin/alluxio format
  # Start worker
  sudo ./bin/alluxio-start.sh worker SudoMount
fi


