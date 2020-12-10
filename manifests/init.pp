# == Class site_hadoop
#
# The main class. Basic system configurations for Hadoop cluster.
#
class site_hadoop (
  $distribution = 'cloudera',
  $email = undef,
  $key = undef,
  $mirror = undef,
  $priority = 900,
  $release = undef,
  $url = undef,
  $users = undef,
  $user_realms = undef,
  $version = undef,
  $accounting_enable = true,
  $database_setup_enable = true,
  $hbase_enable = true,
  $hive_enable = true,
  $hue_enable = false,
  $impala_enable = false,
  $nfs_frontend_enable = true,
  $nfs_yarn_enable = false,
  $oozie_enable = false,
  $pig_enable = true,
  $scripts_enable = true,
  $spark_enable = true,
  $spark_standalone_enable = false,
) inherits site_hadoop::params {
  include ::hadoop

  case $distribution {
    'bigtop': {
      $_mirror = pick($mirror, $site_hadoop::params::bigtop_default_mirror)
      $_version = pick($version, $site_hadoop::params::bigtop_default_version)
    }
    'cloudera': {
      $_mirror = pick($mirror, $site_hadoop::params::cloudera_default_mirror)
      $_version = pick($version, $site_hadoop::params::cloudera_default_version)
    }
    'native': {
      $_mirror = undef
      $_version = undef
    }
    default: {
      error("Unknown distribution ${distribution}")
    }
  }

  $hdfs_enable = $hadoop::hdfs_enable
  $yarn_enable = $hadoop::yarn_enable
}
