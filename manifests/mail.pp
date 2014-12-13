# == Class site_hadoop::mail
#
# Configure sending emails on Debian.
#
class site_hadoop::mail {
  include stdlib

  if $::osfamily == 'Debian' {
    ensure_packages(['bsd-mailx'])

    file { '/etc/exim4/update-exim4.conf.conf':
      content => template('site_hadoop/update-exim4.conf.erb'),
      require => Package['bsd-mailx'],
    }
    ~>
    service { 'exim4':
      ensure     => running,
      enable     => true,
      hasrestart => true,
      restart    => 'service exim4 reload',
    }
  }
}
