##site\_hadoop

[![Build Status](https://travis-ci.org/MetaCenterCloudPuppet/cesnet-site_hadoop.svg?branch=master)](https://travis-ci.org/MetaCenterCloudPuppet/cesnet-site\_hadoop)

####Table of Contents

1. [Overview](#overview)
2. [Module Description - What the module does and why it is useful](#module-description)
   * [Accounting](#accounting)
   * [Bookkeeping](#bookkeeping)
3. [Setup - The basics of getting started with site\_hadoop](#setup)
    * [What cesnet-hadoop module affects](#what-site_hadoop-affects)
    * [Beginning with hadoop](#beginning-with-site_hadoop)
4. [Usage - Configuration options and additional functionality](#usage)
5. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
    * [Classes](#classes)
    * [Module Parameters](#parameters)
    * [Accounting class parameters](#parameters-accounting)
    * [Bookkeeping class parameters](#parameters-bookkeeping)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

<a name="overview"></a>
##Overview

Helper module for using together with CESNET Hadoop puppet modules. There are implemented decisions not meant to be directly in generic Hadoop modules: settings of Cloudera repository, installing particular version of java, desired packages, and there are custom scripts for accounting, ...

<a name="module-description"></a>
##Module Description

This module performs settings and decisions not meant to be in generic Hadoop modules:

* sets Coudera repository
* installs particular version of Java
* (optionally) custom scripts for accounting
* (optionally) custom scripts for bookkeeping
* (optionally) enable autoupdates

Supported:

* Debian 7/wheezy + Cloudera distribution (tested on Hadoop 2.5.0)
* Fedora 21
* RHEL 6, CentOS 6

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
* subjobs: individial map/reduce tasks (node used, elasped time, ...)
* job nodes: subjobs information aggregated per node (number of map/reduce tasks, summary of elapsed time, ...)

With all job metadata in local database you will have detailed history information of Hadoop cluster.

<a name="setup"></a>
##Setup

<a name="what-hadoop-affects"></a>
###What cesnet-hadoop module affects

* Packages: Java JRE, Kerberos client, other "admin look & feel" packages (less, vim, ...), optionally cron-apt
* Files modified:
 * */etc/apt/sources.list.d/cloudera.list*
 * */etc/apt/preferences.d/10\_cloudera.pref*
 * */usr/local/bin/launch* (when *scripts_enable* parameter is *true*)
 * Cloudera apt gpg key
 * (optionally) */etc/cron-apt/config*, */etc/cron-apt/action.d/9-upgrade*, *etc/cron.d/cron-apt*

**Note**: Security files are NOT handled by this module. They needs to be copied to proper places for CESNET Hadoop puppet modules.

<a name="beginning-with-site_hadoop"></a>
###Beginning with site\_hadoop

**Example**: the basic usage, core part neccessary for cesnet-hadoop:

    class{'site_hadoop':
      stage => setup,
    }

Better to set stage to 'setup', because this will set also the repository. All Hadoop puppet modules would need depend on this otherwise.

<a name="usage"></a>
##Usage

**Example 1**: enable autoupdates:

    class{'site_hadoop':
      email => 'email@example.com',
      stage => 'setup',
    }
    
    class{'site_hadoop::autoupdate':
      time => '0 5 * * *',
    }

**Example 2**: enable Hadoop accounting:

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

**Example 3**: enable Hadoop bookkeeping:

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

* devel:
 * **hadoop**: Local post-installation steps for Hadoop for testing in Vagrant
* kdc:
 * client
 * params
 * server
* **accounting**: Custom Hadoop accouting scripts
* **autoupdate**: Configure automatic updates on Debian
* **bookkeeping**: Custom Hadoop bookkeeping scripts
* cloudera: Set-up Cloudera repository
* config: Configuration of Hadoop cluster machines
* init: The main class
* install: Installation of packages required by site\_hadoop module
* kdc: Experiments with KDC
* params: Parameters and default values for site\_hadoop module

<a name="parameters"></a>
###Module Parameters

####`email` undef

Email address to send errors from cron.

####`mirror` 'cloudera'

Cloudera mirror to use.

Values:

* **cloudera**
* **scientific**
* **scientific/test**

####`scripts_enable` true

Create also helper useful scripts in /usr/local.

<a name="parameters-accounting"></a>
###Accounting class parameters

####`accounting_hdfs`
= undef

Enable storing global HDFS disk and data statistics. The value is time in the cron format. See *man 5 crontab*.

####`accounting_quota`
= undef

Enable storing user data statistics. The value is time in the cron format. See *man 5 crontab*.

####`accounting_jobs`
= undef

Enable storing user jobs statistics. The value is time in the cron format. See *man 5 crontab*.

####`db_name`
= undef (system default is *accounting*)

Database name for statistics.

####`db_user`
= undef (system default is *accounting*)

Database user for statistics.

####`db_password`
= undef

Database password for statistics.

####`email`
= undef

Email address to send errors from cron.

####`mapred_hostname`
= $::fqdn

Hadoop Job History Node hostname for gathering user jobs statistics.

####`mapred_url`
= http://*mapred_hostname*:19888, https://*mapred_hostname*:19890

HTTP REST URL of Hadoop Job History Node for gathering user jobs statistics. It is derived from *mapred_hostname* and *principal*, but it may be needed to override it anyway (different hosts due to High Availability, non-default port, ...).

####`principal`
= undef (system default is nn/'hostname -f')

Kerberos principal to access Hadoop. Undef means using default principal value. It needs to be empty string to disable security and not using Kerberos tickets!

<a name="parameters-bookkeeping"></a>
###Bookkeeping class parameters

####`db_name`
= undef (system default is *bookkeeping*)

####`db_host`
= undef (system default is local socket)

Database name for statistics.

####`db_user`
= undef (system default is *bookkeeping*)

Database user for statistics.

####`db_password`
= undef (system default is empty password)

Database password for statistics.

####`email`
= undef

Email address to send errors from cron.

####`freq`
= '*/10 * * * *'

Frequency of hadoop job metadata polling. The value is time in the cron format. See *man 5 crontab*.

####`historyserver_hostname`
= $::fqdn

Hadoop Job History Server hostname.

####`interval`
= undef (scripts default: 3600)

Interval (in seconds) to scan Hadoop.

####`keytab`
= undef (script default: /etc/security/keytab/nn.service.keytab)

Service keytab for ticket refresh.

####`principal`
= undef (script default: nn/\`hostname -f\`@REALM)

Kerberos principal name for gathering metadata. Undef means using default principal value.

####`realm`
= undef

Kerberos realm. Non-empty values enables the security.

####`refresh`
= '0 */4 * * *'

Ticket refresh frequency. The value is time in the cron format. See *man 5 crontab*.

####`resourcemanager_hostname`
= $::fqdn

Hostname of the Hadoop YARN Resource Manager.

####`resourcemanager_hostname2`
= undef

Hostname of the second Hadoop YARN Resource Manager, used with high availability.

<a name="limitations"></a>
##Limitations

Only Debian 7 fully supported. The core part will work on Fedora 21 too.

<a name="development"></a>
##Development

* Repository: [https://github.com/MetaCenterCloudPuppet/cesnet-site\_hadoop](https://github.com/MetaCenterCloudPuppet/cesnet-site_hadoop)
* Testing: [https://github.com/MetaCenterCloudPuppet/hadoop-tests](https://github.com/MetaCenterCloudPuppet/hadoop-tests)
