# == Class site_hadoop::params
#
# Parameters and default values for site\_hadoop module.
#
class site_hadoop::params {
  $defaultconfdir = $::osfamily ? {
    'debian' => '/etc/default',
    'redhat' => '/etc/sysconfig',
  }

  $packages = $::osfamily ? {
    'debian'  => [
      'acl', 'procps',
      'python-scipy',
    ],
    'redhat'  => [
      'scipy',
    ],
    default => undef,
  }

  $packages_sasl = $::osfamily ? {
    /Debian/ => 'libsasl2-modules-gssapi-heimdal',
    /RedHat/ => 'cyrus-sasl-gssapi',
    default  => undef,
  }

  $packages_hue_saml = $::osfamily ? {
    /Debian/ => [
      'libxmlsec1-openssl',
      'xmlsec1',
    ],
    /RedHat/ => 'xmlsec1',
    default  => undef,
  }

  $path = '/sbin:/usr/sbin:/bin:/usr/bin'

  $osname = downcase($::operatingsystem)
  $osver = regsubst($::operatingsystemmajrelease,'\.','')
  $repotype = $::osfamily ? {
    'redhat' => 'yum',
    default  => 'apt',
  }

  $cloudera_default_mirror = 'cloudera'
  $cloudera_default_version = '5'
  $cloudera_baseurl = {
    'cloudera' => 'https://archive.cloudera.com',
    # only Debian at scientific
    'scientific' => $::operatingsystem ? {
      'debian'  => 'http://scientific.zcu.cz/repos/hadoop',
      default => 'http://archive.cloudera.com',
    },
    'scientific/test' => $::operatingsystem ? {
      'debian'  => 'http://scientific.zcu.cz/repos/hadoop-test',
      default => 'http://archive.cloudera.com',
    },
  }

  $bigtop_default_mirror = 'apache'
  $bigtop_default_version = '1.5.0'
}
