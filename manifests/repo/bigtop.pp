# == Class site_hadoop::repo:bigtop
#
# Set-up Bigtop repository.
#
class site_hadoop::repo::bigtop(
  $priority = $site_hadoop::priority,
  $url = undef,
){
  case $site_hadoop::_mirror {
    'amazon': {
      $baseurl = 'http://bigtop-repos.s3.amazonaws.com/releases'
    }
    'apache': {
      $baseurl = 'http://repos.bigtop.apache.org/releases'
    }
    default: {
      error('Unknown mirror')
    }
  }
  $version = $site_hadoop::_version
  $repopath = $::operatingsystem ? {
    'debian' => "/debian/${::lsbmajdistrelease}/${::hardwaremodel}",
    'ubuntu' => "/ubuntu/${::lsbdistrelease}/${::hardwaremodel}",
    default  => "/centos/${site_hadoop::majdistrelease}/${::hardwaremodel}",
  }

  $_url = pick($url, "${baseurl}/${version}${repopath}")

  case $::osfamily {
    'Debian': {
      include ::apt

      # source  => "https://dist.apache.org/repos/dist/release/bigtop/KEYS",
      apt::key { 'bigtop-rvs':
        id     => '0xE8966520DA24E9642E119A5F13971DA39475BD5D',
        server => 'pgp.mit.edu',
        before => Apt::Source['bigtop'],
      }
      apt::key { 'bigtop-abayer':
        id     => '0xE2F318071F656A62F88F252CB12E3E253ADD02D6',
        server => 'pgp.mit.edu',
        before => Apt::Source['bigtop'],
      }
      apt::key { 'bigtop-cos':
        id     => '0x2CAC83124870D88586166115220F69801F27E622',
        server => 'pgp.mit.edu',
        before => Apt::Source['bigtop'],
      }
      apt::key { 'bigtop-evansye':
        id     => '0x31E5AD30C48BD8BC320E2AE78A6F51C98C10EE0A',
        server => 'pgp.mit.edu',
        before => Apt::Source['bigtop'],
      }
      apt::pin { 'bigtop':
        originator => 'Bigtop',
        priority   => $priority,
        before     => Apt::Source['bigtop'],
      }

      apt::source { 'bigtop':
        comment  => "Packages for Cloudera's Distribution for Hadoop, Version ${version}, on ${::operatingsystem} ${site_hadoop::majdistrelease} ${::architecture}",
        location => $_url,
        release  => 'bigtop',
        repos    => 'contrib',
        include  => {
          deb => true,
          src => true,
        },
      }
      ~>
      exec { 'apt-get-update-bigtop':
        command     => 'apt-get update',
        refreshonly => true,
        path        => $site_hadoop::path,
      }
    }

    'RedHat': {
      $majdistrelease = $site_hadoop::majdistrelease
      file { '/etc/yum.repos.d/bigtop.repo':
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => template('site_hadoop/bigtop.repo.erb'),
      }
    }

    default: { }
  }
}
