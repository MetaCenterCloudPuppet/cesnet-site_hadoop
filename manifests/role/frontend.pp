# = Class site_hadoop::role::frontend
#
# Hadoop Frontend.
#
# services:
# * Hadoop Frontend + basic packages
# * HBase Frontend (optional)
# * Hive Frontend (optional)
# * Pig Frontend (optional)
# * Spark Frontend (optional)
# * HDFS NFS Gateway (optional)
#
class site_hadoop::role::frontend {
  include ::hadoop
  include ::site_hadoop::role::common::frontend

  if $hadoop::hdfs_deployed {
    if $site_hadoop::nfs_frontend_enable {
      include ::hadoop::nfs
    }
  }
}
