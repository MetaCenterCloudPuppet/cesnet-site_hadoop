# = Class site_hadoop::role::master
#
# Hadoop Master server in cluster without high availability.
#
# Use case: non-HA, single master, multiple nodes.
#
# services:
# * HDFS namenode (+Spark, HBase, Hive)
# * YARN Resourcemanager (optional)
# * MapRed Historyserver
# * zookeeper
# * HBase master (optional)
# * Hive metastore (optional)
# * Hive server2 (optional)
# * MySQL (HDFS accounting+bookkeeping, Hive)
# * Spark Master (optional)
# * Spark Historyserver (optional)
# * HDFS NFS Gateway (optional)
#
class site_hadoop::role::master {
  include ::site_hadoop::role::master_hdfs
  include ::site_hadoop::role::master_yarn

  if $site_hadoop::spark_enable {
    Class['hadoop::namenode::service'] -> Class['spark::historyserver::service']
  }
}
