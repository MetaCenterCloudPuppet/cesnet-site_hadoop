# = Class site_hadoop::role::hue
#
# Apache Hue web interface.
#
# Components installed:
# * HDFS HttpFS
# * Hue
#
# Actions performed:
# * core-site.xml workaround for HDFS httpfs and Oozie (for login)
# * MySQL/MariaDB databse setup
#
class site_hadoop::role::hue {
  include ::site_hadoop::role::common

  if $hadoop::zookeeper_deployed and ($hadoop::hdfs_hostname2 and !empty($hadoop::hdfs_hostname2)){
    include ::hadoop::httpfs
    include ::site_hadoop::role::common::core_site_workaround

    Class['site_hadoop::role::common::core_site_workaround'] -> Class['hadoop::httpfs::service']
  }
  if $hadoop::zookeeper_deployed and $hadoop::hdfs_deployed {
    include ::hue
    # HBase thrift server doesn't work, problems when cluster security is enabled
    #if $site_hadoop::hbase_enable {
    #  include ::hbase::thriftserver
    #}

    # dependencies for SAML authentication backend
    if $::hue::auth == 'saml' and $::site_hadoop::packages_hue_saml {
      ensure_packages($::site_hadoop::packages_hue_saml)
      Package[$::site_hadoop::packages_hue_saml] -> Class['hue::service']
    }

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
