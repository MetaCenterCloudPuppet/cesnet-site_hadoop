class site_hadoop::params {
  $defaultconfdir = $::osfamily ? {
    debian => '/etc/default',
    redhat => '/etc/sysconfig',
  }

  case $::osfamily {
    'Debian': {
      case $::lsbdistcodename {
        'lenny', 'squeeze', 'lucid', 'natty': {
          $java_packages = ['openjdk-6-jre-headless']
        }
        'wheezy', 'jessie', 'precise','quantal','raring','saucy', 'trusty': {
          $java_packages = ['openjdk-7-jre-headless']
        }
      }
    }
    default: {}
  }
    
  $packages = $::osfamily ? {
    debian => ['acl', 'heimdal-clients', 'less', 'mc', 'puppet', 'vim', 'wget'],
    redhat => ['krb5-workstation', 'less', 'mc', 'puppet', 'vim-enhanced', 'wget'],
  }
  $mc_setup = $::osfamily ? {
    debian  => '/usr/lib/mc/mc',
    default => undef,
  }

  $packages_autoupdate = $::osfamily ? {
    debian => ['cron-apt'],
    redhat => ['yum-autoupdate'],
  }

  $full = false

  # every night at 5:00
  $time_autoupdate = '0 5 * * *'

  $path = '/sbin:/usr/sbin:/bin:/usr/bin'

  $majdistrelease = regsubst($::operatingsystemrelease,'^(\d+)\.(\d+)','\1')
  $cdh5_repopath = $::operatingsystem ? {
    debian => "/cdh5/debian/${::lsbdistcodename}/${::architecture}/cdh",
    redhat => "/cdh5/redhat/${majdistrelease}/${::architecture}/cdh/",
    ubuntu => "/cdh5/ubuntu/${::lsbdistcodename}/${::architecture}/cdh",
  }

  $mirror = 'cloudera'
  $mirrors = {
    'cloudera' => "http://archive.cloudera.com${cdh5_repopath}",
    # only Debian at scientific
    'scientific' => $::operatingsystem ? {
      debian  => 'http://scientific.zcu.cz/repos/hadoop',
      default => "http://archive.cloudera.com${cdh5_repopath}",
    }
  }
}
