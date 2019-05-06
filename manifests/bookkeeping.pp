# == Class site_hadoop::bookkeeping
#
# Custom Hadoop bookkeeping scripts. It clones job metadata from Hadoop to local MySQL database.
#
# Requires:
# * database
# * keytabs, when security enabled
# * hadoop::yarn_hostname set
#
class site_hadoop::bookkeeping(
  $db_name = undef,
  $db_host = undef,
  $db_user = undef,
  $db_password = undef,
  $email = undef,
  $freq = '*/12 * * * *',
  $historyserver_hostname = $::hadoop::historyserver_hostname,
  $https = false,
  $interval = undef,
  $keytab = undef,
  $principal = undef,
  $realm = undef,
  $refresh = '0 */4 * * *',
  $resourcemanager_hostname = $::hadoop::yarn_hostname,
  $resourcemanager_hostname2 = $::hadoop::yarn_hostname2,
) {
  include ::stdlib

  $packages = $::osfamily ? {
    'debian' => ['python-pycurl', 'python-mysqldb'],
    'redhat' => ['python-pycurl', 'MySQL-python'],
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
    content => template('site_hadoop/bookkeeping/refresh.sh.erb'),
    require => File["${prefix}/share/hadoop"],
  }
  if $site_hadoop::yarn_enable and $freq {
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
  if $realm and $realm != '' and $refresh {
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
      require => [File["${prefix}/share/hadoop"], File["${site_hadoop::defaultconfdir}/hadoop-bookkeeping"]],
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
