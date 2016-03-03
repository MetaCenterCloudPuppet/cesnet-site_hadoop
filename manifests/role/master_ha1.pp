# = Class site_hadoop::role::master_ha1
#
# Primary Hadoop master server in cluster with high availability.
#
class site_hadoop::role::master_ha1 {
  include ::hadoop
  $hdfs_deployed = $hadoop::hdfs_deployed
  $properties = $hadoop::properties

  if $properties {
    if !has_key($properties, 'dfs.ha.automatic-failover.enabled') or $properties['dfs.ha.automatic-failover.enabled'] {
      $zkfc_enable = true
    } else {
      $zkfc_enable = false
    }
  } else {
    $zkfc_enable = true
  }

  include ::site_hadoop::role::common::master_main
  if $zkfc_enable {
    include ::hadoop::zkfc
  }

  if $hdfs_deployed {
    if $site_hadoop::yarn_enable {
      include ::hadoop::resourcemanager
    }
    if $site_hadoop::hbase_enable {
      include ::hbase::master
    }
  }
}
