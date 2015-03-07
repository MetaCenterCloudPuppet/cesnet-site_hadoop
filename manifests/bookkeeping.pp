# == Class site_hadoop::accounting
#
# Custom Hadoop bookkeeping scripts. It clones job metadata from Hadoop to local MySQL database.
#
# Requires:
# * database
# * keytabs, when security enabled
#
# === Parameters
#
# ####`db_name`
# = undef (system default is *bookkeeping*)
#
# ####`db_host`
# = undef (system default is local socket)
#
# Database name for statistics.
#
# ####`db_user`
# = undef (system default is *bookkeeping*)
#
# Database user for statistics.
#
# ####`db_password`
# = undef (system default is empty password)
#
# Database password for statistics.
#
# ####`email`
# = undef
#
# Email address to send errors from cron.
#
# ####`freq`
# = '*/10 * * * *'
#
# Frequency of hadoop job metadata polling. The value is time in the cron format. See *man 5 crontab*.
#
# ####`historyserver_hostname`
# = $::fqdn
#
# Hadoop Job History Server hostname.
#
# ####`interval`
# = undef (scripts default: 3600)
#
# Interval (in seconds) to scan Hadoop.
#
# ####`keytab`
# = undef (script default: /etc/security/keytab/nn.service.keytab)
#
# Service keytab for ticket refresh.
#
# ####`principal`
# = undef (script default: nn/\`hostname -f\`@REALM)
#
# Kerberos principal name for gathering metadata. Undef means using default principal value.
#
# ####`realm`
# = undef
#
# Kerberos realm. Non-empty values enables the security.
#
# ####`refresh`
# = '0 */4 * * *'
#
# Ticket refresh frequency. The value is time in the cron format. See *man 5 crontab*.
#
# ####`resourcemanager_hostname`
# = $::fqdn
#
# Hadoop Resourse Manager hostname.
#
class site_hadoop::bookkeeping(
  $db_name = undef,
  $db_host = undef,
  $db_user = undef,
  $db_password = undef,
  $email = undef,
  $freq = '*/12 * * * *',
  $historyserver_hostname = $::fqdn,
  $interval = undef,
  $keytab = undef,
  $principal = undef,
  $realm = undef,
  $refresh = '0 */4 * * *',
  $resourcemanager_hostname = $::fqdn,
) {
  include stdlib

  $packages = $::osfamily ? {
    debian => ['python-pycurl', 'python-mysqldb'],
    redhat => ['python-pycurl', 'MySQL-python'],
    default => undef,
  }

  $prefix = '/usr/local'
  $configfile = '/etc/hadoop-bookkeeping'
  $ticket = '/tmp/krb5cc_hadoop_bookkeeping'

  ensure_packages($packages)
  ensure_resource('file', "${prefix}/share/hadoop", {
    ensure => 'directory',
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  })
  file{"${site_hadoop::defaultconfdir}/hadoop-bookkeeping":
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('site_hadoop/bookkeeping/env.erb'),
  }
  file{$configfile:
    owner   => 'hdfs',
    group   => 'hdfs',
    mode    => '0400',
    content => template('site_hadoop/bookkeeping/cfg.erb'),
  }
  file{"${prefix}/share/hadoop/bookkeeping.sql":
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    source => 'puppet:///modules/site_hadoop/bookkeeping/create.sql',
  }

  file {"${prefix}/bin/bookkeeping":
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => template('site_hadoop/bookkeeping/jobs.sh.erb'),
  }
  file {"${prefix}/share/hadoop/bookkeeping.py":
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    source  => 'puppet:///modules/site_hadoop/bookkeeping/jobs.py',
    require => File["${prefix}/share/hadoop"],
  }
  file {"${prefix}/share/hadoop/bookkeeping-refresh.sh":
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    source  => 'puppet:///modules/site_hadoop/bookkeeping/refresh.sh',
    require => File["${prefix}/share/hadoop"],
  }
  if $freq {
    file{'/etc/cron.d/hadoop-bookkeeping':
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => template('site_hadoop/bookkeeping/cron.erb'),
    }
  } else {
    file{'/etc/cron.d/hadoop-bookkeeping':
      ensure => 'absent',
    }
  }
  if $realm and $refresh {
    file{'/etc/cron.d/hadoop-bookkeeping-refresh':
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => template('site_hadoop/bookkeeping/cron-refresh.erb'),
    }
    exec{'bookkeeping-refresh-now':
      command => "${prefix}/share/hadoop/bookkeeping-refresh.sh",
      creates => $ticket,
      path    => '/sbin:/usr/sbin:/bin:/usr/bin',
      user    => 'hdfs',
      require => File["${prefix}/share/hadoop"],
    }
  } else {
    file{'/etc/cron.d/hadoop-bookkeeping-refresh':
      ensure => 'absent',
    }
    file{$ticket:
      ensure => 'absent',
    }
  }

}
