# == Class: site_hadoop::kdc
#
# Experiments with KDC.
#
class site_hadoop::kdc (
  $realm = $site_hadoop::kdc::params::realm,
  $master_password = $site_hadoop::kdc::params::master_password,
  $perform = undef,
) inherits site_hadoop::kdc::params {
  if $site_hadoop::kdc::perform {
    include site_hadoop::kdc::server
  }
}
