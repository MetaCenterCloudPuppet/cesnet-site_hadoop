# == Class site_hadoop::autoupdate
#
# Configure automatic updates on Debian.
#
# === Parameters
#
# [*email*] undef
#   If specified, sent email on upgrade.
#
class site_hadoop::autoupdate(
  $email = undef,
  $time = $site_hadoop::params::time_autoupdate,
) inherits site_hadoop::params {
  include stdlib

  ensure_packages($site_hadoop::params::packages_autoupdate)

  if $::osfamily == 'Debian' {
    file { '/etc/cron-apt/config':
      content => template('site_hadoop/cron-apt.conf.erb'),
      owner   => 'root',
      group   => 'root',
      require => Package[$site_hadoop::params::packages_autoupdate],
    }
    file { '/etc/cron-apt/action.d/9-upgrade':
      source  => 'puppet:///modules/site_hadoop/cron-apt-upgrade',
      owner   => 'root',
      group   => 'root',
      require => Package[$site_hadoop::params::packages_autoupdate],
    }
    file { '/etc/cron.d/cron-apt':
      content => template('site_hadoop/cron-apt.cron.erb'),
      owner   => 'root',
      group   => 'root',
      require => Package[$site_hadoop::params::packages_autoupdate],
    }
  }
}
