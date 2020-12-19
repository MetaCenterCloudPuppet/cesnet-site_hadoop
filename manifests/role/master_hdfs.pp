# = Class site_hadoop::role::master_hdfs
#
# Hadoop master providing HDFS Namenode in cluster without high availability.
#
# Use case: non-HA, two machines for master daemons, multiple nodes.
#
# services:
# * HDFS namenode (+Spark, HBase, Hive)
# * Zookeeper server
# * HBase master (optional)
# * Hive metastore (optional)
# * Hive server2 (optional)
# * MySQL (HDFS accounting+bookkeeping, Hive)
# * Oozie server (optional)
# * Spark Master (optional)
#
class site_hadoop::role::master_hdfs {
  include ::hadoop
  include ::site_hadoop::role::common
  include ::site_hadoop::role::common::master_main
  include ::zookeeper::server

  if $hadoop::hdfs_deployed {
    if $site_hadoop::hbase_enable {
      include ::hbase::master

      if $site_hadoop::hdfs_enable {
        Class['hadoop::namenode::service'] -> Class['hbase::master::service']
        Class['zookeeper::server::service'] -> Class['hbase::master::service']
      }
    }
  }
}
