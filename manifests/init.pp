# == Class site_hadoop
#
# Basic system configurations for Hadoop cluster on Meta.
#
# ##Parameters
#
# ####`db_name`
# = undef (system default is *accounting*)
#
# Database name for statistics.
#
# ####`db_user`
# = undef (system default is *accounting*)
#
# Database user for statistics.
#
# ####`db_password`
# = undef
#
# Database password for statistics.
#
# ####`email` = undef
# = undef
#
# Email address to send errors from cron.
#
# ####`mirror`
# = 'cloudera'
#
# Cloudera mirror to use.
#
# Values:
# * **cloudera**
# * **scientific**
#
class site_hadoop (
  $db_name = undef,
  $db_user = undef,
  $db_password = undef,
  $email = undef,
  $mirror = $site_hadoop::params::mirror,
) inherits site_hadoop::params {
  include 'site_hadoop::install'
  include 'site_hadoop::config'
  include 'site_hadoop::cloudera'

  Class['site_hadoop::cloudera'] ->
  Class['site_hadoop::install'] ->
  Class['site_hadoop::config'] ->
  Class['site_hadoop']
}
