class site_hadoop::kdc::client {
  $realm = $site_hadoop::kdc::realm
  $domain = $site_hadoop::kdc::domain
  $kdcserver = $site_hadoop::kdc::kdcserver

  #ensure_packages($site_hadoop::kdc::packages['client'])

  file { '/etc/krb5.conf':
    mode    => '0644',
    content => template('site_hadoop/krb5.conf.erb'),
  }
}
