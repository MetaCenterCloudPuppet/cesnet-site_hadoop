# == Class site_hadoop::config
#
# Configuration of Hadoop cluster machines, not meant to be in generic Hadoop puppet modules.
#
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

  if $site_hadoop::scripts_enable {
    file { '/usr/local/bin/launch':
      owner  => 'root',
      group  => 'root',
      mode   => '0755',
      source => 'puppet:///modules/site_hadoop/launch.sh',
    }
  } else {
    file { '/usr/local/bin/launch':
      ensure => 'absent',
    }
  }
}
