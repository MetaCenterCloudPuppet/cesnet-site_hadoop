# = Class site_hadoop::role::hue
#
# Apache Hue web interface.
#
class site_hadoop::role::hue {
  include ::site_hadoop::role::common

  if $hadoop::zookeeper_deployed and ($hadoop::hdfs_hostname2 and !empty($hadoop::hdfs_hostname2)){
    include ::hadoop::httpfs
  }
  if $hadoop::zookeeper_deployed and $hadoop::hdfs_deployed {
    include ::hue
  }
}
