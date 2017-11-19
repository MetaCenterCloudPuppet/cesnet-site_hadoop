# == Class site_hadoop::repo::cloudera
#
# Set-up Cloudera repository.
#
class site_hadoop::repo::cloudera(
  $priority = $site_hadoop::priority,
  $url = undef,
){
  $cdh5_repopath = $::operatingsystem ? {
    'debian'  => "/cdh5/debian/${::lsbdistcodename}/${::architecture}/cdh",
    'ubuntu'  => "/cdh5/ubuntu/${::lsbdistcodename}/${::architecture}/cdh",
    default => "/cdh5/redhat/${site_hadoop::majdistrelease}/${::architecture}/cdh",
  }
  $baseurl = $site_hadoop::cloudera_baseurl[$site_hadoop::_mirror]
  $version = $site_hadoop::_version

  $_url = pick($url, "${baseurl}${cdh5_repopath}")

  case $::osfamily {
    'Debian': {
      include ::apt

      apt::key { 'cloudera':
        id     => '0xF36A89E33CC1BD0F71079007327574EE02A818DD',
        source => "${_url}/archive.key",
      }
      ->
      apt::pin { 'cloudera':
        originator => 'Cloudera',
        priority   => $priority,
      }
      ->
      apt::source { 'cloudera':
        architecture => $::architecture,
        comment      => "Packages for Cloudera's Distribution for Hadoop, Version ${version}, on ${::operatingsystem} ${site_hadoop::majdistrelease} ${::architecture}",
        location     => $_url,
        release      => "${::lsbdistcodename}-cdh${version}",
        repos        => 'contrib',
        include      => {
          deb => true,
          src => true,
        },
      }
      ~>
      exec { 'apt-get-update-cloudera':
        command     => 'apt-get update',
        refreshonly => true,
        path        => $site_hadoop::path,
      }
    }

    'RedHat': {
      if $::operatingsystem != 'Fedora' {
        $majdistrelease = $site_hadoop::majdistrelease
        file { '/etc/yum.repos.d/cloudera-cdh5.repo':
          owner   => 'root',
          group   => 'root',
          mode    => '0644',
          content => template('site_hadoop/cloudera.repo.erb'),
        }
      }
    }

    default: { }
  }
}
