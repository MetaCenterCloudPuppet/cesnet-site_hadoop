# == Class site_hadoop::cloudera
#
# Set-up Cloudera repository.
#
class site_hadoop::cloudera {
  $url = $site_hadoop::mirrors[$site_hadoop::mirror]

  case $::osfamily {
    'Debian': {
      # cloudera repo
      exec { 'key-cloudera':
        command => "apt-key adv --fetch-key ${url}/archive.key",
        path    => $site_hadoop::path,
        creates => '/etc/apt/sources.list.d/cloudera.list',
      }
      ->
      exec { 'wget-cloudera':
        command => "wget -P /etc/apt/sources.list.d/ ${url}/cloudera.list && sed -i /etc/apt/sources.list.d/cloudera.list -e \"s/\\\\(deb\\\\|deb-src\\\\) http/\\\\1 [arch=amd64] http/\" && sed -i /etc/apt/sources.list.d/cloudera.list -e 's,\${baseUrl},http://archive.cloudera.com,' -e 's,\${category},cdh5,'",
        path    => $site_hadoop::path,
        creates => '/etc/apt/sources.list.d/cloudera.list',
      }
      ~>
      exec { 'apt-get-update':
        command     => 'apt-get update',
        refreshonly => true,
        path        => $site_hadoop::path,
      }

      file {'/etc/apt/preferences.d/10_cloudera.pref':
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
        source => 'puppet:///modules/site_hadoop/10_cloudera.pref',
      }
    }

    'RedHat': {
      if $::operatingsystem != 'Fedora' {
        exec { 'wget-cloudera':
          command => "wget -P /etc/yum.repos.d/ ${url}/cloudera-cdh5.repo",
          path    => $site_hadoop::path,
          creates => '/etc/yum.repos.d/cloudera-cdh5.repo',
        }
      }
    }

    default: { }
  }
}
