# == Class site_hadoop
#
# Basic system configurations for Hadoop cluster on Meta.
#
class site_hadoop inherits site_hadoop::params {
  include 'site_hadoop::install'
  include 'site_hadoop::config'
  include 'site_hadoop::cloudera'

  Class['site_hadoop::cloudera'] ->
  Class['site_hadoop::install'] ->
  Class['site_hadoop::config'] ->
  Class['site_hadoop']
}
