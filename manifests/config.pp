class site_hadoop::config {
  if $site_hadoop::mc_setup {
    file { '/etc/profile.d/mc.csh':
      ensure => link,
      target => "${site_hadoop::mc_setup}.csh",
    }
    file { '/etc/profile.d/mc.sh':
      ensure => link,
      target => "${site_hadoop::mc_setup}.sh",
    }
  }

  if $::osfamily == 'Debian' {
    exec { 'key-cloudera':
      command => 'apt-key adv --fetch-key http://archive.cloudera.com/cdh5/debian/wheezy/amd64/cdh/archive.key',
      path    => $site_hadoop::path,
      creates => '/etc/apt/sources.list.d/cloudera.list',
    }
    ->
    exec { 'wget-cloudera':
      command => 'wget -P /etc/apt/sources.list.d/ http://archive.cloudera.com/cdh5/debian/wheezy/amd64/cdh/cloudera.list',
      path    => $site_hadoop::path,
      creates => '/etc/apt/sources.list.d/cloudera.list',
    }
  }
}
