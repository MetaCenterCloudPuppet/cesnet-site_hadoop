##The main site module for Hadoop environment

[![Build Status](https://travis-ci.org/MetaCenterCloudPuppet/cesnet-site_hadoop.svg?branch=master)](https://travis-ci.org/MetaCenterCloudPuppet/cesnet-site\_hadoop) [![Puppet Forge](https://img.shields.io/puppetforge/v/cesnet/site_hadoop.svg)](https://forge.puppetlabs.com/cesnet/site\_hadoop)

####Table of Contents

1. [Module Description - What the module does and why it is useful](#module-description)
   * [Accounting](#accounting)
   * [Bookkeeping](#bookkeeping)
2. [Setup - The basics of getting started with site\_hadoop](#setup)
    * [What cesnet-hadoop module affects](#what-site_hadoop-affects)
3. [Usage - Configuration options and additional functionality](#usage)
    * [Basic Hadoop Cluster](#usage-basic)
    * [Hadoop Accounting](#usage-accounting)
    * [Hadoop Bookkeeping](#usage-bookkeeping)
4. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
    * [Classes](#classes)
     * [site\_hadoop](#class-site_hadoop)
     * [site\_hadoop::accounting](#class-accounting)
     * [site\_hadoop::bookkeeping](#class-bookkeeping)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

<a name="module-description"></a>
##Module Description

This is the main puppet module for Hadoop environment, which performs settings and decisions not meant to be in generic Hadoop modules:

* sets Cloudera repository
* enables custom accounting
* enables custom bookkeeping
* installs Hadoop and its addons using **roles**

This module provide roles. Roles are helper classes joining together external, hadoop, and hadoop addons puppet modules. They solve dependencies and hide complexity of putting all pieces together.

Puppet configured with `stringify_facts=false` is recommended (see also `hive::schema` parameter).

Tested with:

* **Debian 7/wheezy** + Cloudera distribution (tested on Hadoop 2.5.0/2.6.0, CDH 5.14.0)
* **Debian 8/jessie**
* **RHEL 6, 7 and clones**
* **Ubuntu 18.04**

<a name="accounting"></a>
### Accounting

Several basic values are regularly measured and saved to local MySQL database:

* disk space of each node
* disk space of each user (*/user/\**)
* number of jobs and basic summary (like elapsed times) for each user for last 24 hours

The last information (24 hours job statistics) could be mined also from data gathered by bookkeeping (see below). Accounting will do it more lightweight though - only summary is gathered without cloning of jobs metadata.

With accounting you will have basic statistics of Hadoop cluster.

<a name="bookkeeping"></a>
### Bookkeeping

Job metadata information is regularly copied from Hadoop to local MySQL database using HTTP REST API from YARN Resource Manager and MapRed Job History server.

Information stored:

* jobs: top-level information of submitted jobs (elapsed time, ...)
* subjobs: individual map/reduce tasks (node used, elapsed time, ...)
* job nodes: subjobs information aggregated per node (number of map/reduce tasks, summary of elapsed time, ...)

With all job metadata in local database you will have detailed history information of Hadoop cluster.

<a name="setup"></a>
##Setup

<a name="what-hadoop-affects"></a>
###What cesnet-hadoop module affects

* Packages: Java JRE, Kerberos client
* Files modified:
 * */etc/apt/sources.list.d/*.list*
 * */etc/apt/preferences.d/10\_*.pref*
 * apt gpg keys
 * */usr/local/bin/launch* (when *scripts\_enable* parameter is *true*)
 * */usr/lib/bigtop-tomcat/lib/core-site.xml*: link to */etc/hadoop/conf/core-site.xml* file as workaround problems with HDFS configuration during login in some components (HDFS httpfs, Oozie), for example to use Kerberos mapping rules often needed in Kerberos cross-realm environment

**Note**: Security files are NOT handled by this module. They needs to be copied to proper places.

<a name="usage"></a>
##Usage

<a name="usage-basic"></a>
### Basic Hadoop cluster with addons

This is basic multinode Hadoop cluster with addons.

Hadoop module addons modules still needs to be configured:

    $clients = [
      'client.example.com',
    ]
    $master = 'master.example.com'
    $slaves = [
        'node1.example.com',
        'node2.example.com',
        'node3.example.com',
    ]
    $zookeepers = [
      $master,
    ]
    # set to false for initial run
    $hdfs_deployed = true

    class { '::hadoop':
      hdfs_hostname       => $master,
      yarn_hostname       => $master,
      slaves              => $slaves,
      frontends           => $clients,
      nfs_hostnames       => $clients,
      zookeeper_hostnames => $zookeepers,
      hdfs_deployed       => $hdfs_deployed,
    }

    class { '::hbase':
      hdfs_hostname       => $master,
      master_hostname     => $master,
      slaves              => $slaves,
      zookeeper_hostnames => $zookeepers,
    }

    class { '::hive':
      metastore_hostname  => $master,
      server2_hostname    => $master,
      zookeeper_hostnames => $zookeepers,
    }

    class { '::spark':
      hdfs_hostname          => $master,
      historyserver_hostname => $master,
    }

    class { '::site_hadoop':
      users => [
        'hawking',
      ],
    }

    # required for hive, oozie
    class { '::mysql::bindings':
      java_enable => true,
    }

    node 'master.example.com' {
      class { '::zookeeper':
        hostnames => $zookeepers,
      }
      include ::site_hadoop::role::master
    }

    node /node\d+\.example\.com/ {
      include ::site_hadoop::role::slave
    }

    node 'client.example.com' {
      include ::site_hadoop::role::frontend
    }

Note: all the classes with parameters can be replaced by hiera.

Note 2: all classes with parameters there are configuration only classes, except the zookeeper class. Zookeeper must be specified only on the proper nodes, or there can be used hiera instead.

<a name="usage-accounting"></a>
### Hadoop accounting

This is already included in the "primary master" roles:

* *::site\_hadoop::role::master*
* *::site\_hadoop::role::master\_hdfs*
* *::site\_hadoop::role::master\_ha1*

It can be disabled by *accounting\_enable* parameter.

    class { '::mysql::server':
      root_password => 'strongpassword',
    }
    
    mysql::db { 'accounting':
      user     => 'accounting',
      password => 'accpass',
      host     => 'localhost',
      grant    => ['SELECT', 'INSERT', 'UPDATE', 'DELETE'],
      sql      => '/usr/local/share/hadoop/accounting.sql',
    }
    
    class{'site_hadoop::accounting':
      db_user          => 'accounting',
      db_password      => 'accpass',
      email            => 'email@example.com',
      accounting_hdfs  => '0 */4 * * *',
      accounting_quota => '0 */4 * * *',
      accounting_jobs  => '10 2 * * *',
      # needs to be empty string, when not using Kerberos security
      principal        => '',
    }
    
    # site_hadoop::accounting provides the SQL import script
    Class['site_hadoop::accounting'] -> Mysql::Db['accounting']
    # start accounting after Hadoop startup (not strictly needed)
    #Class['hadoop::namenode::service'] -> Class['site_hadoop::accounting']

<a name="usage-bookkeeping"></a>
### Hadoop bookkeeping

This is already included in the "primary master" roles:

* *::site\_hadoop::role::master*
* *::site\_hadoop::role::master\_hdfs*
* *::site\_hadoop::role::master\_ha1*

It can be disabled by *accounting\_enable* parameter.

    class{'mysql::server':
      root_password => 'strong_password',
    }

    mysql::db{'bookkeeping':
      user     => 'bookkeeping',
      password => 'bkpass',
      grant    => ['SELECT', 'INSERT', 'UPDATE', 'DELETE'],
      sql      => '/usr/local/share/hadoop/bookkeeping.sql',
    }

    class{'site_hadoop::bookkeeping':
      email       => 'email@example.com',
      db_name     => 'bookkeeping',
      db_user     => 'bookkeeping',
      db_password => 'bkpass',
      freq        => '*/12 * * * *',
      interval    => 3600,
    }

    Class['site_hadoop::bookkeeping'] -> Mysql::Db['bookkeeping']

<a name="reference"></a>
##Reference

<a name="classes"></a>
###Classes

* [**`site_hadoop`**](#class-site_hadoop): The main class
* `site_hadoop::devel`:
 * **`site_hadoop::devel::hadoop`**: Local post-installation steps for Hadoop for testing in Vagrant
* `site_hadoop::kdc`: Experiments with KDC
 * `site_hadoop::kdc::client`
 * `site_hadoop::kdc::params`
 * `site_hadoop::kdc::server`
* [**`site_hadoop::server::accounting`**](#class-accounting): Custom Hadoop accounting scripts
* [**`site_hadoop::server::bookkeeping`**](#class-bookkeeping): Custom Hadoop bookkeeping scripts
* `site_hadoop::config`: Configuration of Hadoop cluster machines
* `site_hadoop::install`: Installation of packages required by site\_hadoop module
* `site_hadoop::params`: Parameters and default values for site\_hadoop module
* `site_hadoop::repo::cloudera`: Set-up Cloudera repository
* `site_hadoop::repo::bigtop`: Set-up Bigtop repository
* **`site_hadoop::role::common`**: Hadoop initialization and dependencies needed on all nodes
* [**`site_hadoop::role::frontend`**](#role-frontend): Hadoop Frontend
* **`site_hadoop::role::frontend_ext`**: Hadoop External Frontend
* **`site_hadoop::role::ha`**: Hadoop HA quorum server
* [**`site_hadoop::role::hue`**](#role-hue): Apache Hue web interface
* [**`site_hadoop::role::master`**](#role-master): Hadoop Master server in cluster without high availability
* **`site_hadoop::role::master_ha1`**: Primary Hadoop master server in cluster with high availability
* **`site_hadoop::role::master_ha2`**: Secondary Hadoop master server in cluster with high availability
* **`site_hadoop::role::master_hdfs`**: Hadoop master providing HDFS Namenode in cluster without high availability
* **`site_hadoop::role::master_yarn`**: Hadoop master providing YARN Resourcemanager and MapRed Historyserver in cluster without high availability
* **`site_hadoop::role::simple`**: Hadoop cluster completely on one machine
* [**`site_hadoop::role::slave`**](#role-slave): Hadoop worker node


<a name="class-site_hadoop"></a>
###`site_hadoop`

####`distribution`

Hadoop distribution. Default: 'cloudera'.

Values:

* **bigtop**: Apache Bigtop
* **cloudera**: Cloudera
* *undef*: no repository setup

####`email`

Email address to send errors from cron. Default: undef.

####`key`

Repository key. Default: (auto)

Used in *site\_hadoop::cloudera*.

####`mirror`

Cloudera mirror to use. Default: 'cloudera'.

1. Bigtop:

 * **amazon**
 * **apache**

2. Cloudera:

 * **cloudera**
 * **scientific**
 * **scientific/test**

####`priority`

Debian repository priority. Default: 900.

####`release`

Apt release for Debian platforms. Default: undef (automatic).

####`url`

Override repository URL. Default: undef.

####`users`

Accounts to create. Default: undef.

####`user_realms`

Realms to add to *.k5login* files. Default: undef.

####`version`

Hadoop distribution version to install. Default: '5' (for Cloudera), '1.2.1' (for BigTop).

Selects Hadoop distribution version.

####`accounting_enable`

Installs MySQL/MariaDB on the primary master node and enables accounting and bookkeeping. Default: true.

See [site\_hadoop::accounting](#class-accounting) and [site\_hadoop::bookkeeping](#class-bookkeeping)

####`database_setup_enable`

Installs and setup database server and databases, if needed. Default: true.

Database is installed only, if enabled in parameters of:

* Hive: *db*
* Oozie: *db*
* site Hadoop *accounting\_enable*

####`hbase_enable`

Deploys Apache HBase addon. Default: true.

####`hive_enable`

Deploys Apache Hive addon. Default: true.

####`hue_enable`

Deploys Apache Hue web interface. Default: false.

####`impala_enable`

Deploys Cloudera Impala addon. Default: false.

Disabled by default because of crashes with security (IMPALA-2645).

####`java_enable`

Installs Java automatically. Default: true.

####`nfs_frontend_enable`

Launches HDFS NFS Gateway and mounts HDFS on the frontend. Default: true.

####`nfs_yarn_enable`

Launches HDFS NFS Gateway and mounts HDFS on the YARN master. Default: false.

####`oozie_enable`

Installs Apache Oozie addon. Default: true.

It is used by Apache Hue in workflow editor and for submitting jobs.

####`pig_enable`

Installs Apache Pig addon. Default: true.

####`scripts_enable`

Creates also helper useful scripts in /usr/local. Default: true.

####`spark_enable`

Deploys Apache Spark. Default: true.

####`spark_standalone_enable`

Deploys complete standalone Apache Spark cluster. Default: false.

####`yarn_enable`

Enables Hadoop YARN. Default: true.

<a name="class-accounting"></a>
###`site_hadoop::accounting` class

####`accounting_hdfs`

Enable storing global HDFS disk and data statistics. Default: undef.

The value is time in the cron format. See *man 5 crontab*.

####`accounting_quota`

Enable storing user data statistics. Default: undef.

The value is time in the cron format. See *man 5 crontab*.

####`accounting_jobs`

Enable storing user jobs statistics. Default: undef.

The value is time in the cron format. See *man 5 crontab*.

####`db_name`

Database name for statistics. Default: undef (system default is *accounting*).

####`db_user`

Database user for statistics. Default: undef (system default is *accounting*).

####`db_password`

Database password for statistics. Default: undef.

####`email`

Email address to send errors from cron. Default: undef.

####`mapred_hostname`

Hadoop Job History Node hostname for gathering user jobs statistics. Default: $::fqdn.

####`mapred_url`

HTTP REST URL of Hadoop Job History Node for gathering user jobs statistics. Default: "http://*mapred_hostname*:19888", "https://*mapred_hostname*:19890".

It is derived from *mapred_hostname* and *principal*, but it may be needed to override it anyway (different hosts due to High Availability, non-default port, ...).

####`principal`

Kerberos principal to access Hadoop. Default: undef (system default is nn/&#96;hostname -f&#96;).

Undef value means using default principal value. It needs to be empty string to disable security and not using Kerberos tickets!

<a name="class-bookkeeping"></a>
###`site_hadoop::bookkeeping` class

####`db_name`

Default: undef (system default is *bookkeeping*).

####`db_host`

Database name for statistics. Default: undef (system default is local socket).

####`db_user`

Database user for statistics. Default: undef (system default is *bookkeeping*).

####`db_password`

Database password for statistics. Default: undef (system default is empty password).

####`email`

Email address to send errors from cron. Default: undef.

####`freq`

Frequency of hadoop job metadata polling. Default: '*/10 * * * *'.

The value is time in the cron format. See *man 5 crontab*.

####`historyserver_hostname`

Hadoop Job History Server hostname. Default: $::fqdn.

####`https`

Enable HTTPS. Default: false.

####`interval`

Interval (in seconds) to scan Hadoop. Default: undef (scripts default: 3600).

####`keytab`

Service keytab for ticket refresh. Default: undef (script default: /etc/security/keytab/nn.service.keytab).

####`principal`

Kerberos principal name for gathering metadata. Default: undef (script default: nn/&#96;hostname -f&#96;@REALM).

Undef means using default principal value.

####`realm`

Kerberos realm. Default: undef.

Non-empty values enables the security.

####`refresh`

Ticket refresh frequency. Default: '0 */4 * * *'.

The value is time in the cron format. See *man 5 crontab*.

####`resourcemanager_hostname`

Hostname of the Hadoop YARN Resource Manager. Default: $::fqdn.

####`resourcemanager_hostname2`

Hostname of the second Hadoop YARN Resource Manager, used with high availability. Default: undef.

<a name="role-frontend"></a>
###`site_hadoop::role::frontend`

Hadoop Frontend.

Installed clients:

* Hadoop Frontend + basic packages
* HBase Frontend (optional, *hbase\_enable*)
* Hive Frontend (optional, *hive\_enable*)
* Pig Frontend (optional, *pig\_enable*)
* Spark Frontend (optional, *spark\_enable*)
* HDFS NFS Gateway (optional, *nfs_frontend\_enable*)

Required additional parameters:

* *hadoop::frontends*
* *hadoop::nfs\_hostnames*
* *hbase::frontends*

Add also 'nfs' user to *security.client.protocol.acl* authorization (not needed by default).

<a name="role-master"></a>
###`site_hadoop::role::master`

Hadoop Master server in cluster without high availability.

Use case: non-HA, single master, multiple nodes.

Services:

* HDFS Namenode (+ initialization for Spark, HBase, Hive, ...)
* HDFS NFS Gateway (optional, *nfs\_yarn\_enable*)
* YARN Resourcemanager (optional, *yarn\_enable*)
* MapRed Historyserver
* HBase Master (optional, *hbase\_enable*)
* Hive Metastore (optional, *hive\_enable*)
* Hive Server2 (optional, *hive\_enable*)
* Impala Catalog (optional, *impala\_enable\*)
* Impala Statestore (optional, *impala\_enable\*)
* MySQL (HDFS accounting+bookkeeping, Hive, Oozie)
* Oozie Server (optional, *oozie\_enable*)
* Spark Master (optional, *spark\_standalone\_enable*)
* Spark Historyserver (optional, *spark\_enable*)
* Zookeeper

Requires many parameters (hostnames for each service, ...).

MariaDB/MySQL database is supported. To setup and use it also for Hive, Hue and Oozie addons, add parameters:

    hive::db: mysql
    hive::db_password: OOZIE_DB_PASSWORD
    hue::db: mysql
    hue::db_password: HUE_DB_PASSWORD
    mysql::bindings::java_enable: true
    oozie::db: mysql
    oozie::db_password: HIVE_DB_PASSWORD

<a name="role-hue"></a>
###`site_hadoop::role::hue`

Apache Hue web interface.

Services:

* Hadoop HTTPFS (in case of HDFS HA)
* Hue
* MySQL

Required additional parameters:

* *hadoop::hue\_hostnames*
* *hadoop::httpfs\_hostnames*
* *hadoop::oozie\_hostnames*
* *hue::hdfs_hostname* or *hue::defaultFS*
* *hue::httpfs\_hostname*
* *hue::oozie\_hostname*
* *mysql::bindings::java\_enable*: *true*
* *oozie::hue\_hostnames*

Keep enabled also oozie.

Add also 'hue' user and 'oozie' group into *security.client.protocol.acl* authorization (not needed by default).

MariaDB/MySQL database is supported. To setup and use it for Hive, Hue, and Oozie addons, add parameters:

    hive::db: mysql
    hive::db_password: OOZIE_DB_PASSWORD
    hue::db: mysql
    hue::db_password: HUE_DB_PASSWORD
    oozie::db: mysql
    oozie::db_password: HIVE_DB_PASSWORD

<a name="role-slave"></a>
###`site_hadoop::role::slave`

Hadoop worker node.

Services:

* HDFS Datanode
* YARN Nodemanager (optional, *yarn\_enable*)
* HBase Regionserver (optional, *hbase\_enable*)
* Impala Server (optional, *impala\_enable*)
* Spark Worker (optional, *spark\_standalone\_enable*)

Requires many parameters (hostnames for each service, ...).

<a name="limitations"></a>
##Limitations

To avoid puppet dependency hell some packages are installed in the stage *setup*.

<a name="development"></a>
##Development

* Repository: [https://github.com/MetaCenterCloudPuppet/cesnet-site\_hadoop](https://github.com/MetaCenterCloudPuppet/cesnet-site_hadoop)
* Testing:
 * basic: see *.travis.xml*
 * vagrant: [https://github.com/MetaCenterCloudPuppet/hadoop-tests](https://github.com/MetaCenterCloudPuppet/hadoop-tests)
