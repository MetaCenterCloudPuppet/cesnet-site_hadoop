# = Class site_hadoop::role::common::frontend
#
# Hadoop Frontend.
#
# Normal full frontend, without NFS daemon and mounts.
#
# services:
# * Hadoop Frontend + basic packages
# * HBase Frontend (optional)
# * Hive Frontend (optional)
# * Pig Frontend (optional)
# * Spark Frontend (optional)
# * HDFS NFS Gateway (optional)
#
class site_hadoop::role::common::frontend {
  include ::site_hadoop::role::common
  include ::site_hadoop::role::common::impala
  include ::hadoop::frontend
  if $site_hadoop::hbase_enable {
    include ::hbase::frontend
  }
  if $site_hadoop::impala_enable {
    include ::impala::frontend
    Class['::hadoop::common::hdfs::config'] -> Class['::impala::common::config']
  }
  if $site_hadoop::hbase_enable and $site_hadoop::impala_enable {
    Class['::hbase::common::config'] -> Class['::impala::common::config']
  }
  if $site_hadoop::hive_enable {
    include ::hive::frontend
    include ::hive::hcatalog
  }
  if $site_hadoop::hbase_enable and $site_hadoop::hive_enable {
    include ::hive::hbase
  }
  if $site_hadoop::pig_enable {
    include ::pig
  }
  if $site_hadoop::spark_enable {
    include ::spark::frontend
  }

  ## warning, when using pig (missing jar dependency in hive in Cloudera)
  # XXX: better not use the workaround unconditionally
  #if $site_hadoop::hbase_enable and $site_hadoop::hive_enable and $site_hadoop::pig_enable {
  #  file{'/usr/lib/hive/lib/slf4j-api-1.7.5.jar':
  #    source => '/usr/lib/hbase/lib/slf4j-api-1.7.5.jar',
  #  }
  #  Class['hive::frontend::install'] -> File['/usr/lib/hive/lib/slf4j-api-1.7.5.jar']
  #  Class['hbase::frontend::install'] -> File['/usr/lib/hive/lib/slf4j-api-1.7.5.jar']
  #}

  $packages = $::osfamily ? {
    'debian'  => ['ant', 'maven'],
    default => [],
  }

  package{$packages:}
}
