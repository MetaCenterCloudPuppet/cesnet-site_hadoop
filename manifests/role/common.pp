# = Class site_hadoop::role::common
#
# Hadoop inicializations and dependencies needed on all nodes.
#
# Actions:
# * repository setup
# * include all cesnet puppet modules config classes
# * java installation
# * creating user accounts
#
class site_hadoop::role::common {
  include ::stdlib
  include ::site_hadoop
  include ::site_hadoop::config
  include ::hadoop
  include ::zookeeper

  case $::site_hadoop::distribution {
    'bigtop': {
      class{'::site_hadoop::repo::bigtop':
        priority => $::site_hadoop::priority,
        url      => $::site_hadoop::url,
        release  => $::site_hadoop::release,
        stage    => 'setup',
      }
      -> Class['site_hadoop::install']
    }
    'cloudera': {
      class{'::site_hadoop::repo::cloudera':
        priority => $::site_hadoop::priority,
        url      => $::site_hadoop::url,
        release  => $::site_hadoop::release,
        stage    => 'setup',
      }
      -> Class['site_hadoop::install']
    }
    default: {}
  }

  class{'::site_hadoop::install':
    stage => 'setup',
  }

  if $site_hadoop::java_enable {
    if member($hadoop::frontends, $::fqdn) {
      $java_flavor = 'jdk'
    } else {
      $java_flavor = 'headless'
    }
    class{'::java_ng':
      flavor      => $java_flavor,
      set_default => member($hadoop::frontends, $::fqdn),
      stage       => 'setup',
    }
  }

  if $site_hadoop::hbase_enable { include ::hbase }
  if $site_hadoop::hive_enable { include ::hive }
  if $site_hadoop::impala_enable { include ::impala }
  if $site_hadoop::oozie_enable { include ::oozie }
  if $site_hadoop::spark_enable { include ::spark }

  if $site_hadoop::users and $hadoop::zookeeper_deployed {
    $touchfile = 'hdfs-users-created'
    $is_hdfs_namenode = ($hadoop::hdfs_hostname == $::fqdn)
    $is_frontend = member($hadoop::frontends, $::fqdn)

    hadoop::user{$site_hadoop::users:
      shell     => $is_frontend,
      hdfs      => $is_hdfs_namenode,
      groups    => 'users',
      realms    => $site_hadoop::user_realms,
      touchfile => $touchfile,
    }

    if $is_hdfs_namenode {
      hadoop::kinit{$touchfile:
      }
      ->
      Hadoop::User <| touchfile == $touchfile |>
      ->
      hadoop::kdestroy{$touchfile:
        touch     => true,
      }
    }
  }
}
