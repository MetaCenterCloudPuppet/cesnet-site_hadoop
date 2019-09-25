# == Class site_hadoop::repo::cloudera
#
# Set-up Cloudera repository.
#
class site_hadoop::repo::cloudera(
  $priority = $site_hadoop::priority,
  $url = undef,
  $release = undef,
){
  $baseurl = $site_hadoop::cloudera_baseurl[$site_hadoop::_mirror]
  $version = $site_hadoop::_version
  $cdh_major_version = regsubst("${version}.", '\..*', '')

  $cdh5_repopath = $::operatingsystem ? {
    'debian' => "/cdh5/debian/${::lsbdistcodename}/${::architecture}/cdh",
    'ubuntu' => "/cdh5/ubuntu/${::lsbdistcodename}/${::architecture}/cdh",
    default  => "/cdh5/redhat/${site_hadoop::osver}/${::architecture}/cdh",
  }
  $cdh6_repopath = $::operatingsystem ? {
    /CentOS|Scientific/ => "/cdh6/${version}/redhat${site_hadoop::osver}/${site_hadoop::repotype}",
    /OpenSuse/ => "/cdh6/${version}/sles${site_hadoop::osver}/${site_hadoop::repotype}",
    default    => "/cdh6/${version}/${site_hadoop::osname}${site_hadoop::osver}/${site_hadoop::repotype}",
  }
  $cdh_repopath = $cdh_major_version ? {
    /^5/    => $cdh5_repopath,
    default => $cdh6_repopath,
  }
  $cdh_key = $cdh_major_version ? {
    /^5/    => '0xF36A89E33CC1BD0F71079007327574EE02A818DD',
    default => '0xCECDB80C4E9004B0CFE852962279662784415700',
  }

  $_url = pick($url, "${baseurl}${cdh_repopath}")
  $_key = pick($site_hadoop::key, $cdh_key)

  case $::osfamily {
    'Debian': {
      include ::apt

      $_release = pick($release, "${::lsbdistcodename}-cdh${version}")

      apt::key { 'cloudera':
        id     => $_key,
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
        comment      => "Packages for Cloudera's Distribution for Hadoop, Version ${version}, on ${::operatingsystem} ${::operatingsystemmajrelease} ${::architecture}",
        location     => $_url,
        release      => $_release,
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
        $majdistrelease = $::operatingsystemmajrelease
        $prevrepos = $cdh_major_version ? {
          /^5/    => ['/etc/yum.repos.d/cloudera-cdh6.repo'],
          default => ['/etc/yum.repos.d/cloudera-cdh5.repo'],
        }
        $newrepo = $cdh_major_version ? {
          /^5/    => '/etc/yum.repos.d/cloudera-cdh5.repo',
          default => '/etc/yum.repos.d/cloudera-cdh6.repo',
        }
        $yum_baseurl = $cdh_major_version ? {
          /^5/    => "${_url}/${version}/",
          default => "${_url}/",
        }
        file { $prevrepos:
          ensure => absent,
        }
        file { $newrepo:
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
