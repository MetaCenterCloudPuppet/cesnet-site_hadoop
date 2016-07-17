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
  $hive_path='/usr/lib/hive/scripts/metastore/upgrade/mysql'

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

      if $hive::db and ($hive::db == 'mariadb' or $hive::db == 'mysql') and $site_hadoop::database_setup_enable {
        include ::mysql::server
        include ::mysql::bindings

        #
        # ERROR at line 822: Failed to open file 'hive-txn-schema-0.13.0.mysql.sql', error: 2
        # (resurrection of HIVE-6559, https://issues.apache.org/jira/browse/HIVE-6559)
        #
        Class['hive::metastore::install']
        ->
        exec{'hive-bug':
          command => "sed -i ${hive_path}/${site_hadoop::hive_schema} -e 's,^SOURCE hive,SOURCE ${hive_path}/hive,'",
          unless  => "grep 'SOURCE ${hive_path}' ${hive_path}/${site_hadoop::hive_schema}",
          path    => '/sbin:/usr/sbin:/bin:/usr/bin',
        }
        ->
        mysql::db { 'metastore':
          user     => 'hive',
          password => $hive::db_password,
          grant    => ['SELECT', 'INSERT', 'UPDATE', 'DELETE'],
          sql      => "${hive_path}/${site_hadoop::hive_schema}",
        }

        Class['hive::hdfs'] -> Class['hive::metastore']
        Class['hive::metastore::install'] -> Mysql::Db['metastore']
        Mysql::Db['metastore'] -> Class['hive::metastore::service']
        Class['mysql::bindings'] -> Class['hive::metastore::config']
      }

      if $site_hadoop::impala_enable {
        Class['hive::metastore::service'] -> Class['impala::catalog::service']
      }
    }
    if $site_hadoop::oozie_enable {
      include ::oozie
      include ::oozie::server

      if ($oozie::db == 'mariadb' or $oozie::db == 'mysql') and $site_hadoop::database_setup_enable {
        include ::mysql::server
        include ::mysql::bindings

        mysql::db { 'oozie':
          user     => 'oozie',
          password => $oozie::db_password,
          grant    => ['CREATE', 'INDEX', 'SELECT', 'INSERT', 'UPDATE', 'DELETE'],
        }

        Class['mysql::bindings'] -> Class['oozie::server::config']
        Mysql::Db['oozie'] -> Class['oozie::server::service']
        Class['oozie::hdfs'] -> Class['oozie::server::service']
      }
    }
  }

  if $site_hadoop::accounting_enable {
    include ::mysql::server
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
