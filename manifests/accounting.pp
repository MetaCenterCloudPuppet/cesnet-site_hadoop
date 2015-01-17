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
#      db_password => 'accpass',
#      email       => 'mail@example.com',
#      stage       => 'setup',
#    }
#    
#    class{'site_hadoop::accountig':
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
# [*hdfs*] undef
#
# Enable storing global HDFS disk and data statistics. The value is time in the cron format. See *man 5 crontab*.
#
class site_hadoop::accounting(
  $hdfs  = undef,
) {
  file {'/usr/local/bin/accounting-hdfs':
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
    content => template('site_hadoop/accounting/hdfs.sh.erb'),
  }

  file{'/usr/local/share/hadoop':
    ensure  => 'directory',
    owner => 'root',
    group => 'root',
    mode  => '0755',
  }
  ->
  file {'/usr/local/share/hadoop/accounting-hdfs.awk':
    owner => 'root',
    group => 'root',
    mode  => '0644',
    source => 'puppet:///modules/site_hadoop/accounting/hdfs.awk',
  }

  file{'/usr/local/share/hadoop/accounting.sql':
    owner => 'root',
    group => 'root',
    mode  => '0644',
    source => 'puppet:///modules/site_hadoop/accounting/create.sql',
  }

  $db_name = $site_hadoop::db_name
  $db_user = $site_hadoop::db_user
  $db_password = $site_hadoop::db_password
  if $db_name or $db_user or $db_password {
    file{"${site_hadoop::defaultconfdir}/hadoop-accounting":
      owner  => 'hdfs',
      group  => 'hdfs',
      mode   => '0400',
      content => template('site_hadoop/accounting/hadoop-accounting.erb'),
    }
  } else {
    file{"${site_hadoop::defaultconfdir}/hadoop-accounting":
      ensure => 'absent',
    }
  }

  $email = $site_hadoop::email
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
}
