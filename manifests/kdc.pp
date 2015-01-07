class site_hadoop::kdc (
  $realm = $site_hadoop::kdc::params::realm,
  $master_password = $site_hadoop::kdc::params::master_password,
) inherits site_hadoop::kdc::params {

  include site_hadoop::kdc::install
  include site_hadoop::kdc::config
  include site_hadoop::kdc::service

  Class['site_hadoop::kdc::install'] ->
  Class['site_hadoop::kdc::config'] ~>
  Class['site_hadoop::kdc::service']
}
