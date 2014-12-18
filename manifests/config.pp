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
}
