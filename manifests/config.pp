class site_hadoop::config {
  if $site_hadoop::mc_setup {
    file { '/etc/profile.d/mc.csh':
      ensure => link,
      owner  => 'root',
      group  => 'root',
      target => "${site_hadoop::mc_setup}.csh",
    }
    file { '/etc/profile.d/mc.sh':
      ensure => link,
      owner  => 'root',
      group  => 'root',
      target => "${site_hadoop::mc_setup}.sh",
    }
  }
}
