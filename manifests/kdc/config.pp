class site_hadoop::kdc::config {
  $realm = $site_hadoop::kdc::realm
  $domain = $site_hadoop::kdc::domain
  $kdcserver = $site_hadoop::kdc::kdcserver

  file { '/etc/krb5.conf':
    mode    => '0644',
    content => template('site_hadoop/krb5.conf.erb'),
  }

  file { "${site_hadoop::kdc::kdc_dir}/kdc.conf":
    mode    => '0600',
    content => template('site_hadoop/kdc.conf.erb'),
  }

  exec { 'kdb5_util-create':
    command => "kdb5_util create -s -P ${site_hadoop::kdc::master_password}",
    path    => '/sbin:/usr/sbin:/bin:/usr/bin',
    creates => "${site_hadoop::kdc::kdc_dir}/principal",
  }
  File['/etc/krb5.conf'] -> Exec['kdb5_util-create']
  File["${site_hadoop::kdc::kdc_dir}/kdc.conf"] -> Exec['kdb5_util-create']
}
