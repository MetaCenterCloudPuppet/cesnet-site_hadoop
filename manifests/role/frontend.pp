# = Class site_hadoop::role::frontend
#
# Hadoop Frontend.
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
