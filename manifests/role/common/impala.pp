# = Class site_hadoop::role::common::impala
#
# Installs SASL GSSAPI module required for impala security. The heimdal version is used. Installed only if impala and security is enabled.
#
# As the heimdal is in conflict with hue (requiring the MIT version instead), it is not installed on hue nodes. impala-shell still works there though.
#
# Limitation: dependency handling is quite hacky.
#
class site_hadoop::role::common::impala {
  include ::stdlib

  if hiera('impala::realm', '') != '' and $site_hadoop::packages_sasl {
    if hiera('site_hadoop::impala_enable', false) and !member(hiera('hadoop::hue_hostnames', []), $::fqdn) {
      ensure_packages($site_hadoop::packages_sasl)
      if defined(Class['impala::common::config']) {
        Package[$site_hadoop::packages_sasl] -> Class['impala::common::config']
      }
    }
  }
}
