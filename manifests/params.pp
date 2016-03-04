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
    ],
    redhat  => [
      'krb5-workstation',
      'scipy',
    ],
    default => undef,
  }

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
