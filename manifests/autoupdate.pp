# == Class site_hadoop::autoupdate
#
# Replaced by **cesnet-autoupdate** module. Configure automatic updates on Debian.
#
# === Parameters
#
# ####`email`
#
# Email to sent information about updates. Taken from site_hadoop *email* parameter (default undef).
#
# ####`full` false
#
# Upgrade type: false=upgrade, true=dist-upgrade.
#
# ####`time`
# = ''0 5 * * *'
#
# Time to upgrade in cron format (see *man 5 crontab*).
#
class site_hadoop::autoupdate(
  $email = $site_hadoop::email,
  $full = $site_hadoop::params::full,
  $time = $site_hadoop::params::time_autoupdate,
) inherits site_hadoop::params {
  include stdlib

  if $site_hadoop::params::packages_autoupdate {
    ensure_packages($site_hadoop::params::packages_autoupdate)
  }

  if $::osfamily == 'Debian' {
    if $full {
      $action = 'dist-upgrade'
    } else {
      $action = 'upgrade'
    }
    file { '/etc/cron-apt/config':
      content => template('site_hadoop/cron-apt.conf.erb'),
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      require => Package[$site_hadoop::params::packages_autoupdate],
    }
    file { '/etc/cron-apt/action.d/3-download':
      content => template('site_hadoop/cron-apt-action-download.erb'),
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      require => Package[$site_hadoop::params::packages_autoupdate],
    }
    file { '/etc/cron-apt/action.d/9-upgrade':
      content => template('site_hadoop/cron-apt-action-upgrade.erb'),
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      require => Package[$site_hadoop::params::packages_autoupdate],
    }
    file { '/etc/cron.d/cron-apt':
      content => template('site_hadoop/cron-apt.cron.erb'),
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      require => Package[$site_hadoop::params::packages_autoupdate],
    }
  }
}
