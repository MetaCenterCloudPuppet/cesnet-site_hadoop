# == Class site_hadoop
#
# The main class. Basic system configurations for Hadoop cluster.
#
class site_hadoop (
  $email = undef,
  $mirror = $site_hadoop::params::mirror,
  $scripts_enable = $site_hadoop::params::scripts_enable,
) inherits site_hadoop::params {
  include 'site_hadoop::install'
  include 'site_hadoop::config'
  include 'site_hadoop::cloudera'

  Class['site_hadoop::cloudera'] ->
  Class['site_hadoop::install'] ->
  Class['site_hadoop::config'] ->
  Class['site_hadoop']
}
