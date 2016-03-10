# == Class site_hadoop
#
# The main class. Basic system configurations for Hadoop cluster.
#
class site_hadoop (
  $email = undef,
  $hive_schema = $site_hadoop::params::hive_schema,
  $mirror = $site_hadoop::params::mirror,
  $users = undef,
  $user_realms = undef,
  $version = '5',
  $accounting_enable = true,
  $hbase_enable = true,
  $hive_enable = true,
  $impala_enable = false,
  $java_enable = true,
  $nfs_frontend_enable = true,
  $nfs_yarn_enable = false,
  $pig_enable = true,
  $scripts_enable = true,
  $spark_enable = true,
  $spark_standalone_enable = false,
  $yarn_enable = true,
) inherits site_hadoop::params {
}
