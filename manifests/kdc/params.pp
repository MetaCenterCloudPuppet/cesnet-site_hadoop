class site_hadoop::kdc::params {
  case $::osfamily {
    'Debian': {
      $daemons = {
        'kadmin' => 'krb5-admin-server',
        'kdc' => 'krb5-kdc',
      }
    }
    'RedHat': {
      $daemons = {
        'kadmin' => 'kadmin',
        'kdc' => 'krb5kdc',
      }
    }
  }

  $kdc_dir = $::osfamily ? {
    debian => '/var/lib/krb5kdc',
    redhat => '/var/kerberos/krb5kdc',
  }

  $kdc_packages = $::osfamily ? {
    debian => ['krb5-kdc', 'krb5-admin-server'],
    redhat => ['krb5-server', 'krb5-workstation'],
  }

  $realm = 'HADOOP'

  $kdcserver = $::fqdn

  $master_password = '12345'
}
