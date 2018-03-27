# = Class site_hadoop::role::common::core_site_workaround
#
# Workarounds a problem with HDFS configuration in some components during login (HDFS HttpFS, Oozie)
#
# For example there are often needed Kerberos mapping rules from core-site.xml in Kerberos cross-realm environment (hadoop.security.auth_to_local property).
#
# Note, the properties httpfs.authentication.kerberos.name.rules and oozie.authentication.kerberos.name.rules are still needed for authentication in the components themselfs.
#
# Known issue:
# * https://issues.apache.org/jira/browse/OOZIE-2704
#
class site_hadoop::role::common::core_site_workaround {
  $tomcat_dir = '/usr/lib/bigtop-tomcat'
  file { $tomcat_dir:
    ensure  => 'directory',
    recurse => true,
  }
  file { "${tomcat_dir}/lib":
    ensure  => 'directory',
    recurse => true,
  }
  ->
  file { "${tomcat_dir}/lib/core-site.xml":
    ensure => 'link',
    target => "${hadoop::confdir}/core-site.xml",
  }
}
