# = Class site_hadoop::role::master_ha2
#
# Secondary Hadoop master server in cluster with high availability.
#
class site_hadoop::role::master_ha2 {
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

  include ::site_hadoop::role::common
  if $site_hadoop::hdfs_enable {
    include ::hadoop::namenode
    if $zkfc_enable {
      include ::hadoop::zkfc
    }
  }

  if $site_hadoop::yarn_enable {
    include ::hadoop::resourcemanager
  }

  if $site_hadoop::hive_enable {
    include ::hive::user
  }

  if $site_hadoop::hue_enable {
    include ::hue::user
  }

  if $site_hadoop::impala_enable {
    include ::impala::user
  }

  if $site_hadoop::oozie_enable {
    include ::oozie::user
  }

  if $hadoop::hdfs_deployed {
    if $site_hadoop::yarn_enable {
      include ::hadoop::historyserver
    }
    if $site_hadoop::hbase_enable {
      include ::hbase
      if $hbase::backup_hostnames {
        include ::hbase::master
      } else {
        include ::hbase::user
      }
    }
    if $site_hadoop::spark_enable {
      include ::spark::historyserver
      include ::spark::user

      # prefer system user created by the package
      Class['spark::historyserver::install'] -> Class['spark::user']
    }
  }
}
