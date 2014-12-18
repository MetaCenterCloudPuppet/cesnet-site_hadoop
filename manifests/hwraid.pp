class site_hadoop::hwraid {
  $path='/sbin:/usr/sbin:/bin:/usr/bin'

  exec { 'key-hwraid':
    command => 'apt-key adv --fetch-key http://hwraid.le-vert.net/debian/hwraid.le-vert.net.gpg.key',
    path    => $path,
    creates => '/etc/apt/sources.list.d/hwraid.list',
  }
  ->
  file { '/etc/apt/sources.list.d/hwraid.list':
    source => 'puppet:///modules/site_hadoop/hwraid.list',
  }
  ~>
  exec { 'apt-get-update':
    command     => 'apt-get update',
    refreshonly => true,
    path    => $path,
  }
  ->
  package { 'megacli': }
}
