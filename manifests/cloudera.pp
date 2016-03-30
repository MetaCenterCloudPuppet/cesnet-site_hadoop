# == Class site_hadoop::cloudera
#
# Set-up Cloudera repository.
#
class site_hadoop::cloudera {
  $cdh5_repopath = $site_hadoop::cdh5_repopath
  $url = $site_hadoop::mirrors[$site_hadoop::mirror]
  $version = $site_hadoop::version

  case $::osfamily {
    'Debian': {
      include ::apt

      apt::key { 'cloudera':
        id     => '0xF36A89E33CC1BD0F71079007327574EE02A818DD',
        source => "${url}/archive.key",
      }
      ->
      apt::pin { 'cloudera':
        originator => 'Cloudera',
        priority   => 900,
      }
      ->
      apt::source { 'cloudera':
        architecture => $::architecture,
        comment      => "Packages for Cloudera's Distribution for Hadoop, Version ${version}, on ${::operatingsystem} ${site_hadoop::majdistrelease} ${::architecture}",
        location     => "${url}${cdh5_repopath}",
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
