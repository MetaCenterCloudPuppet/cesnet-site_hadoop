class site_hadoop::kdc::service {
  service{$site_hadoop::kdc::daemons['kadmin']:
    ensure => running,
  }
  service{$site_hadoop::kdc::daemons['kdc']:
    ensure => running,
  }
}
