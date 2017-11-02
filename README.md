# emr-alluxio
alluxio - emr bootstrap action scripts

# AWS command line
Upload the alluxio.sh to a S3 bucket; Then run aws cli to create a EMR cluster, with specific alluxio version (1.6.0), memory setting for each worker (2GB) and the S3 bucket that you want to mount to alluxio at root.

```
aws emr create-cluster --name "Alluxio Cluster" --release-label emr-5.7.0 
--ec2-attributes KeyName=<keypair_name>,InstanceProfile=EMR_EC2_DefaultRole,SubnetId=<subnet_id>
--service-role EMR_DefaultRole 
--applications Name=Hadoop Name=Hive Name=Hue Name=ZooKeeper Name=HCatalog 
--emrfs Consistent=true,RetryCount=5,RetryPeriod=30 
--instance-count 3 --instance-type m4.xlarge 
--bootstrap-action Path="s3://<your_bucket>/alluxio.sh",Args=["1.6.0","2GB","<s3_bucket_as_alluxio_underFS>"]
```

After the cluster is in "Waiting" status, open web browser at:
http://<public_dns_of_master>:19999 , you will see the alluxio cluster is ready.

# emr cluster conf

```
[
  {
    "Classification": "core-site",
    "Properties": {
      "fs.alluxio.impl": "alluxio.hadoop.FileSystem",
      "fs.alluxio-ft.impl": "alluxio.hadoop.FaultTolerantFileSystem"
    }
  },
  {
    "Classification": "spark-defaults",
    "Properties": {
          "spark.driver.extraClassPath": ":/usr/lib/hadoop-lzo/lib/*:/usr/lib/hadoop/hadoop-aws.jar:/usr/share/aws/aws-java-sdk/*:/usr/share/aws/emr/emrfs/conf:/usr/share/aws/emr/emrfs/lib/*:/usr/share/aws/emr/emrfs/auxlib/*:/usr/share/aws/emr/security/conf:/usr/share/aws/emr/security/lib/*:/opt/alluxio-core-client-spark-1.2.0-jar-with-dependencies.jar"
     }
  }
]
```
