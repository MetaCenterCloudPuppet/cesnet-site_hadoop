# == Class site_hadoop::repo:bigtop
#
# Set-up Bigtop repository.
#
class site_hadoop::repo::bigtop(
  $gpg_server = undef,
  $keys_url = 'https://dist.apache.org/repos/dist/release/bigtop/KEYS',
  $priority = $site_hadoop::priority,
  $url = undef,
  $release = undef,
){
  case $site_hadoop::_mirror {
    'amazon': {
      $baseurl = 'http://bigtop-repos.s3.amazonaws.com/releases'
    }
    'apache': {
      $baseurl = 'http://repos.bigtop.apache.org/releases'
    }
    default: {
      $baseurl = 'http://repos.bigtop.apache.org/releases'
    }
  }
  $version = $site_hadoop::_version
  $repopath = $::operatingsystem ? {
    'debian' => "/debian/${::lsbmajdistrelease}/${::architecture}",
    'ubuntu' => "/ubuntu/${::lsbdistrelease}/${::architecture}",
    default  => "/centos/${site_hadoop::osver}/${::architecture}",
  }

  $_url = pick($url, "${baseurl}/${version}${repopath}")

  case $::osfamily {
    'Debian': {
      include ::apt
      include ::stdlib

      $_release = pick($release, 'bigtop')

      # both unreliable: gpg servers (DNS), and apt puppet module (https source)
      # ==> trying to import keys manually (it can be disabled using $key_url parameter)
      if ($keys_url) {
        ensure_packages('wget')
        Package['wget']
        ->
        exec { 'fetch-apt-key-bigtop':
          command => "wget ${keys_url} -O - | apt-key add -",
          path    => '/sbin:/usr/sbin:/bin:/usr/bin',
          creates => '/etc/apt/sources.list.d/bigtop.list',
          before  => Apt::Source['bigtop'],
        }
      }
      #$gpg_server='pool.sks-keyservers.net'
      if ($gpg_server) {
        apt::key { 'bigtop-rvs':
          id     => '0xE8966520DA24E9642E119A5F13971DA39475BD5D',
          server => $gpg_server,
          before => Apt::Source['bigtop'],
        }
        apt::key { 'bigtop-abayer':
          id     => '0xE2F318071F656A62F88F252CB12E3E253ADD02D6',
          server => $gpg_server,
          before => Apt::Source['bigtop'],
        }
        apt::key { 'bigtop-cos':
          id     => '0x2CAC83124870D88586166115220F69801F27E622',
          server => $gpg_server,
          before => Apt::Source['bigtop'],
        }
        apt::key { 'bigtop-evansye':
          id     => '0x31E5AD30C48BD8BC320E2AE78A6F51C98C10EE0A',
          server => $gpg_server,
          before => Apt::Source['bigtop'],
        }
        apt::key { 'bigtop-junhe':
          id     => '0x8452C57BBD6289FF7F83FB193FD4C6CB5F26908B',
          server => $gpg_server,
          before => Apt::Source['bigtop'],
        }
      }
      apt::pin { 'bigtop':
        originator => 'Bigtop',
        priority   => $priority,
        before     => Apt::Source['bigtop'],
      }

      apt::source { 'bigtop':
        comment  => "Packages for BigTop Distribution for Hadoop, Version ${version}",
        location => $_url,
        release  => $_release,
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
      $majdistrelease = $site_hadoop::operatingsystemmajrelease
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
