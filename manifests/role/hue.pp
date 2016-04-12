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
    # HBase thrift server doesn't work, problems when cluster security is enabled
    #if $site_hadoop::hbase_enable {
    #  include ::hbase::thriftserver
    #}

    if $::hue::db and ($::hue::db == 'mariadb' or $::hue::db == 'mysql') and $::site_hadoop::database_setup_enable {
      include ::mysql::server

      mysql::db { 'hue':
        user     => $::hue::db_user,
        password => $::hue::db_password,
        grant    => ['ALL'],
      }

      Mysql::Db['hue'] -> Class['hue::service']
    }
  }
}
