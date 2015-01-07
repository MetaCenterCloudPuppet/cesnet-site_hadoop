class site_hadoop::kdc::params {
  $kdc_packages = $::osfamily ? {
    redhat => ['krb5-server', 'krb5-workstation'],
  }
  $realm = 'HADOOP'
  $kdcserver = $::fqdn
  $master_password = '12345'
}
