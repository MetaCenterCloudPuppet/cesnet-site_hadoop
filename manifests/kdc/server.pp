# == Class site_hadoop::kdc::server
#
# KDC Server setup (not tested).
#
class site_hadoop::kdc::server {
  include stdlib
  include site_hadoop::kdc::client

  ensure_packages($site_hadoop::kdc::packages['server'])

  $realm = $site_hadoop::kdc::realm
  $domain = $site_hadoop::kdc::domain
  $kdcserver = $site_hadoop::kdc::kdcserver
  $kdcconf = "${site_hadoop::kdc::kdc_conf_dir}/kdc.conf"

  file { $kdcconf:
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
    content => template('site_hadoop/kdc.conf.erb'),
    require => Package[$site_hadoop::kdc::packages['server']],
  }

  exec { 'kdb5_util-create':
    command => "kdb5_util create -s -P ${site_hadoop::kdc::master_password}",
    path    => '/sbin:/usr/sbin:/bin:/usr/bin',
    # reading /dev/random
    timeout => 0,
    creates => "${site_hadoop::kdc::kdc_data_dir}/principal",
    require => Package[$site_hadoop::kdc::packages['server']],
  }

  service{$site_hadoop::kdc::daemons['kadmin']:
    ensure => running,
  }
  service{$site_hadoop::kdc::daemons['kdc']:
    ensure => running,
  }

  File['/etc/krb5.conf'] -> Exec['kdb5_util-create']
  File['/etc/krb5.conf'] ~> Service[$site_hadoop::kdc::daemons['kadmin']]
  File['/etc/krb5.conf'] ~> Service[$site_hadoop::kdc::daemons['kdc']]

  File[$kdcconf] -> Exec['kdb5_util-create']
  File[$kdcconf] ~> Service[$site_hadoop::kdc::daemons['kadmin']]
  File[$kdcconf] ~> Service[$site_hadoop::kdc::daemons['kdc']]

  Exec['kdb5_util-create'] -> Service[$site_hadoop::kdc::daemons['kadmin']]
  Exec['kdb5_util-create'] -> Service[$site_hadoop::kdc::daemons['kdc']]
}
