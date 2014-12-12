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
  }
    
  $packages = $::osfamily ? {
    debian => ['acpid', 'heimdal-clients', 'less', 'mc', 'puppet', 'vim', 'wget'],
    redhat => ['acpid', 'krb5-workstation', 'less', 'mc', 'puppet', 'vim-enhanced', 'wget'],
  }
  $mc_setup = $::osfamily ? {
    debian => '/usr/lib/mc/mc',
  }

  $path = '/sbin:/usr/sbin:/bin:/usr/bin'
}
