# == Class site_hadoop::accounting
#
# Custom Hadoop accouting scripts.
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
#    class{'site_hadoop::accounting':
#      db_password => 'accpass',
#      email       => 'mail@example.com',
#      accounting_hdfs => '0,30 * * *',
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
class site_hadoop::accounting(
  $accounting_hdfs = undef,
  $accounting_quota = undef,
  $accounting_jobs = undef,
  $db_name = undef,
  $db_user = undef,
  $db_password = undef,
  $email = undef,
  $mapred_hostname = $::fqdn,
  $mapred_url = undef,
  $principal = undef,
) {
  include stdlib

  $packages = ['python-pycurl']

  $prefix = '/usr/local'

  # common
  ensure_packages($packages)
  ensure_resource('file', "${prefix}/share/hadoop", {
    ensure => 'directory',
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  })
  file{"${site_hadoop::defaultconfdir}/hadoop-accounting":
    owner   => 'hdfs',
    group   => 'hdfs',
    mode    => '0400',
    content => template('site_hadoop/accounting/hadoop-accounting.erb'),
  }
  file{"${prefix}/share/hadoop/accounting.sql":
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    source => 'puppet:///modules/site_hadoop/accounting/create.sql',
  }

  # hdfs data
  file {"${prefix}/bin/accounting-hdfs":
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => template('site_hadoop/accounting/hdfs.sh.erb'),
  }
  file {"${prefix}/share/hadoop/accounting-hdfs.awk":
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    source  => 'puppet:///modules/site_hadoop/accounting/hdfs.awk',
    require => File["${prefix}/share/hadoop"],
  }
  if $accounting_hdfs {
    file{'/etc/cron.d/accounting-hdfs':
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => template('site_hadoop/accounting/cron-hdfs.erb'),
    }
  } else {
    file{'/etc/cron.d/accounting-hdfs':
      ensure => 'absent',
    }
  }

  # user quota
  file {"${prefix}/bin/accounting-quota":
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => template('site_hadoop/accounting/quota.sh.erb'),
  }
  file {"${prefix}/share/hadoop/accounting-quota.awk":
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    source  => 'puppet:///modules/site_hadoop/accounting/quota.awk',
    require => File["${prefix}/share/hadoop"],
  }
  if $accounting_quota {
    file{'/etc/cron.d/accounting-quota':
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => template('site_hadoop/accounting/cron-quota.erb'),
    }
  } else {
    file{'/etc/cron.d/accounting-quota':
      ensure => 'absent',
    }
  }

  # user jobs
  if $mapred_url {
    $_mapred_url = $mapred_url
  } else {
    if $principal {
      $_mapred_url = "https://${mapred_hostname}:19890"
    } else {
      $_mapred_url = "http://${mapred_hostname}:19888"
    }
  }
  file {"${prefix}/bin/accounting-jobs":
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => template('site_hadoop/accounting/jobs.sh.erb'),
  }
  file {"${prefix}/share/hadoop/accounting-jobs.py":
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    source  => 'puppet:///modules/site_hadoop/accounting/jobs.py',
    require => File["${prefix}/share/hadoop"],
  }
  if $accounting_jobs {
    file{'/etc/cron.d/accounting-jobs':
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => template('site_hadoop/accounting/cron-jobs.erb'),
    }
  } else {
    file{'/etc/cron.d/accounting-jobs':
      ensure => 'absent',
    }
  }
}
