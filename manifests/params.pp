# == Class site_hadoop::params
#
# Parameters and default values for site\_hadoop module.
#
class site_hadoop::params {
  $defaultconfdir = $::osfamily ? {
    debian => '/etc/default',
    redhat => '/etc/sysconfig',
  }

  $packages = $::osfamily ? {
    debian  => [
      'acl', 'heimdal-clients', 'procps',
      'python-scipy',
      'less', 'mc', 'vim', 'wget',
    ],
    redhat  => ['krb5-workstation', 'scipy', 'less', 'mc', 'vim-enhanced', 'wget'],
    default => undef,
  }

  $mc_setup = $::osfamily ? {
    debian  => '/usr/lib/mc/mc',
    default => undef,
  }

  $packages_autoupdate = $::operatingsystem ? {
    centos  => ['yum-cron'],
    debian  => ['cron-apt'],
    fedora  => ['yum-autoupdate'],
    ubuntu  => ['cron-apt'],
    default => undef,
  }

  $full = false

  # every night at 5:00
  $time_autoupdate = '0 5 * * *'

  $path = '/sbin:/usr/sbin:/bin:/usr/bin'

  $majdistrelease = regsubst($::operatingsystemrelease,'^(\d+)\.(\d+)','\1')
  $cdh5_repopath = $::operatingsystem ? {
    debian  => "/cdh5/debian/${::lsbdistcodename}/${::architecture}/cdh",
    ubuntu  => "/cdh5/ubuntu/${::lsbdistcodename}/${::architecture}/cdh",
    default => "/cdh5/redhat/${majdistrelease}/${::architecture}/cdh",
  }

  $mirror = 'cloudera'
  $mirrors = {
    'cloudera' => "http://archive.cloudera.com${cdh5_repopath}",
    # only Debian at scientific
    'scientific' => $::operatingsystem ? {
      debian  => 'http://scientific.zcu.cz/repos/hadoop',
      default => "http://archive.cloudera.com${cdh5_repopath}",
    },
    'scientific/test' => $::operatingsystem ? {
      debian  => 'http://scientific.zcu.cz/repos/hadoop-test',
      default => "http://archive.cloudera.com${cdh5_repopath}",
    }
  }

  $scripts_enable = true
}
