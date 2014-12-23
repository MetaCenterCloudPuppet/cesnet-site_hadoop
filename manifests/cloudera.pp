class site_hadoop::cloudera {
  if $::osfamily == 'Debian' {
    # cloudera repo
    exec { 'key-cloudera':
      command => 'apt-key adv --fetch-key http://archive.cloudera.com/cdh5/debian/wheezy/amd64/cdh/archive.key',
      path    => $site_hadoop::path,
      creates => '/etc/apt/sources.list.d/cloudera.list',
    }
    ->
    exec { 'wget-cloudera':
      command => 'wget -P /etc/apt/sources.list.d/ http://archive.cloudera.com/cdh5/debian/wheezy/amd64/cdh/cloudera.list && sed -i /etc/apt/sources.list.d/cloudera.list -e "s/\\(deb\\|deb-src\\) http/\\1 [arch=amd64] http/"',
      path    => $site_hadoop::path,
      creates => '/etc/apt/sources.list.d/cloudera.list',
    }
    ~>
    exec { 'apt-get-update':
      command     => 'apt-get update',
      refreshonly => true,
      path        => $site_hadoop::path,
    }
  }
}
