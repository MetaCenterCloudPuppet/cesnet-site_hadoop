# == Class site_hadoop::kdc::params
#
# Parameters for KDC.
#
class site_hadoop::kdc::params {
  case $::osfamily {
    'Debian': {
      $daemons = {
        'kadmin' => 'krb5-admin-server',
        'kdc' => 'krb5-kdc',
      }
      $packages = {
        'server' => ['krb5-kdc', 'krb5-admin-server'],
        #'client' => ['krb5-user'],
      }
    }
    'RedHat': {
      $daemons = {
        'kadmin' => 'kadmin',
        'kdc' => 'krb5kdc',
      }
      $packages = {
        'server' => ['krb5-server'],
        #'client' => ['krb5-workstation'],
      }
    }
    default: {
      fail("${::osfamily} (${::operatingsystem}) not supported")
    }
  }

  $kdc_conf_dir = $::osfamily ? {
    debian => '/etc/krb5kdc',
    redhat => '/var/kerberos/krb5kdc',
  }

  $kdc_data_dir = $::osfamily ? {
    debian => '/var/lib/krb5kdc',
    redhat => '/var/kerberos/krb5kdc',
  }

  $realm = 'HADOOP'

  $kdcserver = $::fqdn

  $master_password = '12345'
}
