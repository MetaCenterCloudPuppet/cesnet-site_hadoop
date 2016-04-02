class {'::hue':
  hdfs_hostname => $::fqdn,
}
class {'::site_hadoop':
  hbase_enable => false,
  hive_enable  => false,
  pig_enable   => false,
  spark_enable => false,
}
class {'::site_hadoop::accounting':
  db_password => 'good-password',
}
class {'::site_hadoop::bookkeeping':
  db_password => 'good-password',
}
