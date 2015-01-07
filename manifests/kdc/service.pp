class site_hadoop::kdc::service {
  service{'kadmin':
    ensure => running,
  }
  service{'krb5kdc':
    ensure => running,
  }
}
