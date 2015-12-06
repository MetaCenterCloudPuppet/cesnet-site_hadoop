# = Class java
#
# Install Java JRE Headless.
#
class site_hadoop::java(
  $ensure = undef,
  $java_version = [8, 7],
  $ppa_repo_enable = false,
) inherits ::site_hadoop::params {
  include ::stdlib

  $path = '/sbin:/usr/sbin:/bin:/usr/bin'

  if $ppa_repo_enable {
    $java_available_versions = union($::site_hadoop::params::java_native_versions, $::site_hadoop::params::java_ppa_versions)
  } else {
    $java_available_versions = $::site_hadoop::params::java_native_versions
  }
  notice('Available Java versions:', join($java_available_versions, ', '))

  if is_array($java_version) {
    $java_requested_versions = intersection($java_version, $java_available_versions)
  } else {
    $java_requested_versions = intersection([$java_version], $java_available_versions)
  }
  if count($java_requested_versions) == 0 {
    fail('No requested Java versions found, available versions:', join($java_available_versions, ', '))
  }

  $_java_version = $java_requested_versions[0]
  notice("Selected Java version: ${_java_version}")

  if !member($::site_hadoop::params::java_native_versions, $_java_version) and member($::site_hadoop::params::java_ppa_versions, $_java_version) {
    $ppa_file = '/etc/apt/sources.list.d/webupd8team-ppa-java.list'
    exec { 'repo-key-ppa':
      command => 'apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys EEA14886',
      creates => $ppa_file,
      path    => $path,
    }
    ->
    file { $ppa_file:
      owner  => 'root',
      group  => 'root',
      mode   => '0644',
      source => 'puppet:///modules/site_hadoop/ppa.list',
    }

    exec { 'repo-ppa-update':
      command     => 'apt-get update',
      path        => $path,
      refreshonly => true,
      subscribe   => File[$ppa_file],
    }

    exec { 'repo-ppa-accept-license':
      command => "echo oracle-java${_java_version}-installer shared/accepted-oracle-license-v1-1 select true | debconf-set-selections",
      path    => $path,
      unless  => "dpkg -l oracle-java${_java_version}-installer",
    }

    $java_packages = ["oracle-java${_java_version}-installer", "oracle-java${_java_version}-unlimited-jce-policy"]

    if !$ensure {
      ensure_packages($java_packages)
    } else {
      package{$java_packages:
        ensure => $ensure,
      }
    }

    Exec['repo-ppa-accept-license']
    -> Package["oracle-java${_java_version}-installer"]
    -> Package["oracle-java${_java_version}-unlimited-jce-policy"]
  } else {
    $java_packages = $::osfamily ? {
      /Debian/ => ["openjdk-${_java_version}-jre-headless"],
      /RedHat/ => ["java-1.${_java_version}.0-jre-headless"],
      default  => undef,
    }

    if !$ensure {
      ensure_packages($java_packages)
    } else {
      package{$java_packages:
        ensure => $ensure,
      }
    }
  }
}
