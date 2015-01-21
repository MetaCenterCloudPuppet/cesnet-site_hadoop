####Table of Contents

1. [Overview](#overview)
2. [Module Description - What the module does and why it is useful](#module-description)
3. [Setup - The basics of getting started with site\_hadoop](#setup)
    * [What cesnet-hadoop module affects](#what-site_hadoop-affects)
    * [Beginning with hadoop](#beginning-with-site_hadoop)
4. [Usage - Configuration options and additional functionality](#usage)
5. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
    * [Classes](#classes)
    * [Module Parameters](#parameters)
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
* (optionally) enable autoupdates

Supported:

* Debian 7/wheezy + Cloudera distribution (tested on Hadoop 2.5.0)
* Fedora 21

<a name="setup"></a>
##Setup

<a name="what-hadoop-affects"></a>
###What cesnet-hadoop module affects

* Packages: Java JRE, Kerberos client, other "admin look & feel" packages (less, vim, ...), optionally cron-apt
* Files modified:
 * */etc/apt/sources.list.d/cloudera.list*
 * */etc/apt/preferences.d/10\_cloudera.pref*
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
      db_user           => 'accounting',
      db_password       => 'accpass',
      email             => 'email@example.com',
      accounting_hdfs  => '0 */4 * * *',
      accounting_quota => '0 */4 * * *',
      accounting_jobs  => '10 2 * * *',
    }
    
    # site_hadoop::accounting provides the SQL import script
    Class['site_hadoop::accounting'] -> Mysql::Db['accounting']
    # start accounting after Hadoop startup (not strictly needed)
    #Class['hadoop::namenode::service'] -> Class['site_hadoop::accounting']

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
* cloudera
* config
* init
* install
* kdc: Experiments with KDC

<a name="parameters"></a>
###Module Parameters

####`email` undef

Email address to send errors from cron.

####`mirror` 'cloudera'

Cloudera mirror to use.

Values:

* **cloudera**
* **scientific**


<a name="limitations"></a>
##Limitations

Only Debian 7 fully supported. The core part will work on Fedora 21 too.

<a name="development"></a>
##Development

* Repository: [https://github.com/MetaCenterCloudPuppet/cesnet-site\_hadoop](https://github.com/MetaCenterCloudPuppet/cesnet-site_hadoop)
* Testing: [https://github.com/MetaCenterCloudPuppet/hadoop-tests](https://github.com/MetaCenterCloudPuppet/hadoop-tests)
