# == Class site_hadoop::accounting
#
# Requires:
# * database
# * hdfs user and group (=hadoop)
#
# For example using puppetlabs-mysql and cesnet-hadoop:
#
#    include stdlib
#    
#    class{'site_hadoop':
#      stage       => 'setup',
#    }
#    
#    class{'site_hadoop::accountig':
#      db_password => 'accpass',
#      email       => 'mail@example.com',
#      hdfs        => '0,30 * * *',
#    }
#    
#    mysql::db { 'accounting':
#      user     => 'accounting',
#      password => 'accpass',
#      host     => 'localhost',
#      grant    => ['SELECT', 'INSERT', 'UPDATE', 'DELETE'],
#      sql      => '/usr/local/share/hadoop/accounting.sql',
#    }
#
#    Class['site_hadoop::accounting'] -> Mysql::Db['accounting']
#    Class['hadoop::nameserver::install'] -> Class['site_hadoop::accounting']
#
# === Parameters
#
# ####`db_name`
# = undef (system default is *accounting*)
#
# Database name for statistics.
#
# ####`db_user`
# = undef (system default is *accounting*)
#
# Database user for statistics.
#
# ####`db_password`
# = undef
#
# Database password for statistics.
#
# ####`email`
# = undef
#
# Email address to send errors from cron.
#
# [*hdfs*] undef
#
# Enable storing global HDFS disk and data statistics. The value is time in the cron format. See *man 5 crontab*.
#
# ####`principal`
# = undef
#
# Kerberos principal to access Hadoop.
#
class site_hadoop::accounting(
  $db_name = undef,
  $db_user = undef,
  $db_password = undef,
  $email = undef,
  $hdfs  = undef,
  $quota  = undef,
  $principal = undef,
) {
  # common
  file{'/usr/local/share/hadoop':
    ensure  => 'directory',
    owner => 'root',
    group => 'root',
    mode  => '0755',
  }
  file{"${site_hadoop::defaultconfdir}/hadoop-accounting":
    owner  => 'hdfs',
    group  => 'hdfs',
    mode   => '0400',
    content => template('site_hadoop/accounting/hadoop-accounting.erb'),
  }
  file{'/usr/local/share/hadoop/accounting.sql':
    owner => 'root',
    group => 'root',
    mode  => '0644',
    source => 'puppet:///modules/site_hadoop/accounting/create.sql',
  }

  # hdfs data
  file {'/usr/local/bin/accounting-hdfs':
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
    content => template('site_hadoop/accounting/hdfs.sh.erb'),
  }
  file {'/usr/local/share/hadoop/accounting-hdfs.awk':
    owner => 'root',
    group => 'root',
    mode  => '0644',
    source => 'puppet:///modules/site_hadoop/accounting/hdfs.awk',
    require => File['/usr/local/share/hadoop'],
  }
  if $hdfs {
    file{'/etc/cron.d/accounting-hdfs':
      owner => 'root',
      group => 'root',
      mode  => '0644',
      content => template('site_hadoop/accounting/cron-hdfs.erb'),
    }
  } else {
    file{'/etc/cron.d/accounting-hdfs':
      ensure => 'absent',
    }
  }

  # user quota
  file {'/usr/local/bin/accounting-quota':
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
    content => template('site_hadoop/accounting/quota.sh.erb'),
  }
  file {'/usr/local/share/hadoop/accounting-quota.awk':
    owner => 'root',
    group => 'root',
    mode  => '0644',
    source => 'puppet:///modules/site_hadoop/accounting/quota.awk',
    require => File['/usr/local/share/hadoop'],
  }
  if $quota {
    file{'/etc/cron.d/accounting-quota':
      owner => 'root',
      group => 'root',
      mode  => '0644',
      content => template('site_hadoop/accounting/cron-quota.erb'),
    }
  } else {
    file{'/etc/cron.d/accounting-quota':
      ensure => 'absent',
    }
  }
}
