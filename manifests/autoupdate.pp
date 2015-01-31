# == Class site_hadoop::autoupdate
#
# Configure automatic updates on Debian.
#
# === Parameters
#
# ####`email`
#
# Email to sent information about updates. Taken from site_hadoop *email* parameter (default undef).
#
# ####`time`
# = ''0 5 * * *'
#
# Time to upgrade in cron format (see *man 5 crontab*).
#
class site_hadoop::autoupdate(
  $email = $site_hadoop::email,
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
