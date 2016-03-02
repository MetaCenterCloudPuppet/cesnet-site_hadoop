# = Class site_hadoop::role::simple
#
# Hadoop cluster completely on one machine.
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
# * Hive metastore (optional)
# * Hive server2 (optional)
# * HDFS NFS Gateway (optional)
#
class site_hadoop::role::simple {
  include ::site_hadoop::role::master
  include ::site_hadoop::role::frontend
  include ::site_hadoop::role::slave
}
