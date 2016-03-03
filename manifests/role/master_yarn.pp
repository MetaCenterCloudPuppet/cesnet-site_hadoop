# = Class site_hadoop::role::master_yarn
#
# Hadoop master providing YARN Resourcemanager and MapRed Historyserver in cluster without high availability.
#
# Use case: non-HA, two machines for master daemons, multiple nodes.
#
# services:
# * YARN Resourcemanager (optional)
# * MapRed Historyserver
# * Spark Historyserver (optional)
# * HDFS NFS Gateway (optional)
#
class site_hadoop::role::master_yarn {
  include ::hadoop
  include ::site_hadoop::role::common

  if $site_hadoop::yarn_enable {
    include ::hadoop::resourcemanager
  }

  if $hadoop::hdfs_deployed {
    include ::hadoop::historyserver
    if $site_hadoop::nfs_yarn_enable {
      include ::hadoop::nfs
    }
    if $site_hadoop::spark_enable {
      include ::spark::historyserver
    }
  }
}
