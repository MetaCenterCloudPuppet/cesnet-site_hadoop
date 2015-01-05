class site_hadoop::params {
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
    debian => ['acpid', 'heimdal-clients', 'less', 'mc', 'puppet', 'vim', 'wget'],
    redhat => ['acpid', 'krb5-workstation', 'less', 'mc', 'puppet', 'vim-enhanced', 'wget'],
  }
  $mc_setup = $::osfamily ? {
    debian => '/usr/lib/mc/mc',
    default => undef,
  }

  $packages_autoupdate = $::osfamily ? {
    debian => ['cron-apt'],
    redhat => ['yum-autoupdate'],
  }

  # every night at 5:00
  $time_autoupdate = '0 5 * * *'

  $path = '/sbin:/usr/sbin:/bin:/usr/bin'

  $mirror = 'cloudera'
  $mirrors = {
    'cloudera' => 'http://archive.cloudera.com/cdh5/debian/wheezy/amd64/cdh',
    'scientific' => 'http://scientific.zcu.cz/repos/hadoop',
  }
}
