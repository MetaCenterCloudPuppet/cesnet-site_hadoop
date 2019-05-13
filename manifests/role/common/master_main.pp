# = Class site_hadoop::role::common::master_main
#
# The "main" Hadoop master server class.
#
# It is used by "master_ha1" and "master_hdfs" roles. Actions:
#
# * there are handled privileged HDFS operations (formatting, creating directories)
# * there is the accounting
# * it is used as main server for all hadoop addons (if enabled):
#  * spark::master
#  * impala::catalog, impala::statestore
#  * hive::metastore, hive::server
#  * oozie::server
#
class site_hadoop::role::common::master_main {
  include ::hadoop
  include ::hadoop::namenode
  include ::site_hadoop::role::common
  include ::site_hadoop::role::common::impala

  if $hadoop::zookeeper_deployed {
    # HDFS (non-data) required
    if $site_hadoop::hbase_enable {
      include ::hbase::hdfs
    }
    if $site_hadoop::hive_enable {
      include ::hive::hdfs
    }
    if $site_hadoop::hue_enable {
      include ::hue::hdfs
    }
    if $site_hadoop::impala_enable {
      include ::impala::hdfs
    }
    if $site_hadoop::oozie_enable {
      include ::oozie::hdfs
    }
    if $site_hadoop::spark_enable {
      include ::spark::hdfs
    }
  }

  if $site_hadoop::spark_standalone_enable {
    include ::spark::master
  }

  if $hadoop::hdfs_deployed {
    if $site_hadoop::impala_enable {
      include ::impala::catalog
      include ::impala::statestore

      Class['::hadoop::common::hdfs::config'] -> Class['::impala::common::config']
      if $site_hadoop::hbase_enable {
        include ::hbase::common::config
        Class['::hbase::common::config'] -> Class['::impala::common::config']
      }
    }
    if $site_hadoop::hive_enable {
      include ::hive
      include ::hive::metastore

      if $site_hadoop::yarn_enable {
        include ::hive::server2
        Class['hive::hdfs'] -> Class['hive::server2']
      }

      if $site_hadoop::impala_enable {
        Class['hive::metastore::service'] -> Class['impala::catalog::service']
      }
    }
    if $site_hadoop::oozie_enable {
      include ::oozie
      include ::oozie::server
      include ::site_hadoop::role::common::core_site_workaround

      Class['site_hadoop::role::common::core_site_workaround'] -> Class['oozie::server::service']
      Class['oozie::hdfs'] -> Class['oozie::server::service']
    }
  }

  if $site_hadoop::accounting_enable {
    include ::mysql::server::mysqltuner

    if $hadoop::hdfs_deployed {
      include ::site_hadoop::accounting
      include ::site_hadoop::bookkeeping

      mysql::db{'accounting':
        user     => 'accounting',
        password => $site_hadoop::accounting::db_password,
        grant    => ['SELECT', 'INSERT', 'UPDATE', 'DELETE'],
        sql      => '/usr/local/share/hadoop/accounting.sql',
      }
      mysql::db{'bookkeeping':
        user     => 'bookkeeping',
        password => $site_hadoop::bookkeeping::db_password,
        grant    => ['SELECT', 'INSERT', 'UPDATE', 'DELETE'],
        sql      => '/usr/local/share/hadoop/bookkeeping.sql',
      }

      Class['site_hadoop::accounting'] -> Mysql::Db['accounting']
      Class['site_hadoop::bookkeeping'] -> Mysql::Db['bookkeeping']

      Class['hadoop::namenode::install'] -> Class['site_hadoop::accounting']
    }
  }
}
