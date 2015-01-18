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
# === Parameters
#
# ####`accounting_hdfs`
# = undef
#
# Enable storing global HDFS disk and data statistics. The value is time in the cron format. See *man 5 crontab*.
#
# ####`accounting_quota`
# = undef
#
# Enable storing user data statistics. The value is time in the cron format. See *man 5 crontab*.
#
# ####`accounting_jobs`
# = undef
#
# Enable storing user jobs statistics. The value is time in the cron format. See *man 5 crontab*.
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
# ####`mapred_hostname`
# = $::fqdn
#
# Hadoop Job History Node hostname for gathering user jobs statistics.
#
# ####`mapred_url`
# = http://*mapred_hostname*:19888, https://*mapred_hostname*:19890
#
# HTTP REST URL of Hadoop Job History Node for gathering user jobs statistics. It is derived from *mapred_hostname* and *principal*, but it may be needed to override it anyway (different hosts due to High Availability, non-defalt port, ...).
#
# ####`principal`
# = undef
#
# Kerberos principal to access Hadoop.
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

  # common
  ensure_packages($packages)
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
  if $accounting_hdfs {
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
  if $accounting_quota {
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
  file {'/usr/local/bin/accounting-jobs':
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
    content => template('site_hadoop/accounting/jobs.py.erb'),
  }
  if $accounting_jobs {
    file{'/etc/cron.d/accounting-jobs':
      owner => 'root',
      group => 'root',
      mode  => '0644',
      content => template('site_hadoop/accounting/cron-jobs.erb'),
    }
  } else {
    file{'/etc/cron.d/accounting-jobs':
      ensure => 'absent',
    }
  }
}
