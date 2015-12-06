##site\_hadoop

[![Build Status](https://travis-ci.org/MetaCenterCloudPuppet/cesnet-site_hadoop.svg?branch=master)](https://travis-ci.org/MetaCenterCloudPuppet/cesnet-site\_hadoop)

####Table of Contents

1. [Module Description - What the module does and why it is useful](#module-description)
   * [Accounting](#accounting)
   * [Bookkeeping](#bookkeeping)
2. [Setup - The basics of getting started with site\_hadoop](#setup)
    * [What cesnet-hadoop module affects](#what-site_hadoop-affects)
    * [Beginning with hadoop](#beginning-with-site_hadoop)
3. [Usage - Configuration options and additional functionality](#usage)
4. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
    * [Classes](#classes)
     * [site\_hadoop](#class-site_hadoop)
     * [site\_hadoop::accounting](#class-accounting)
     * [site\_hadoop::bookkeeping](#class-bookkeeping)
     * [site\_hadoop::java](#class-java)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

<a name="module-description"></a>
##Module Description

This is helper module for Hadoop, which performs settings and decisions not meant to be in generic Hadoop modules:

* sets Cloudera repository
* (optionally) installs particular version of Java (optionally enable webupd8 PPA repository)
* (optionally) custom scripts for accounting
* (optionally) custom scripts for bookkeeping

Supported:

* **Debian 7/wheezy** + Cloudera distribution (tested on Hadoop 2.5.0)
* **Fedora 21**
* **RHEL 6 and clones**

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

* Packages: Java JRE, Kerberos client, other "admin look & feel" packages (less, vim, ...), optionally cron-apt
* Files modified:
 * */etc/apt/sources.list.d/cloudera.list*
 * */etc/apt/preferences.d/10\_cloudera.pref*
 * */usr/local/bin/launch* (when *scripts\_enable* parameter is *true*)
 * Cloudera apt gpg key
 * (optionally) */etc/cron-apt/config*, */etc/cron-apt/action.d/9-upgrade*, *etc/cron.d/cron-apt*

**Note**: Security files are NOT handled by this module. They needs to be copied to proper places for CESNET Hadoop puppet modules.

<a name="beginning-with-site_hadoop"></a>
###Beginning with site\_hadoop

**Example**: the basic usage, core part necessary for cesnet-hadoop:

    class{'site_hadoop':
      stage => setup,
    }

Better to set stage to 'setup', because this will set also the repository. All Hadoop puppet modules would need depend on this otherwise.

<a name="usage"></a>
##Usage

**Example 1**: install Java 8, enable external PPA repository if needed

    class { '::site_hadoop::java'
      java_version    => 8,
      ppa_repo_enable => true,
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

* [**`site_hadoop`**](#class-site_hadoop): The main class
* `site_hadoop::devel`:
 * **`site_hadoop::devel::hadoop`**: Local post-installation steps for Hadoop for testing in Vagrant
* `site_hadoop::kdc`: Experiments with KDC
 * `site_hadoop::kdc::client`
 * `site_hadoop::kdc::params`
 * `site_hadoop::kdc::server`
* [**`site_hadoop::server::accounting`**](#class-accounting): Custom Hadoop accounting scripts
* `site_hadoop::server::autoupdate` (deprecated): Replaced by **cesnet-autopdate** module
* [**`site_hadoop::server::bookkeeping`**](#class-bookkeeping): Custom Hadoop bookkeeping scripts
* `site_hadoop::cloudera`: Set-up Cloudera repository
* `site_hadoop::config`: Configuration of Hadoop cluster machines
* `site_hadoop::install`: Installation of packages required by site\_hadoop module
* [**`site_hadoop::java`**](#class-java): Install Java JRE Headless
* `site_hadoop::params`: Parameters and default values for site\_hadoop module

<a name="class-site_hadoop"></a>
###`site_hadoop`

####`email`

Email address to send errors from cron. Default: undef.

####`mirror`

Cloudera mirror to use. Default: 'cloudera'.

Values:

* **cloudera**
* **scientific**
* **scientific/test**

####`scripts_enable`

Create also helper useful scripts in /usr/local. Default: true.

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

<a name="class-java"></a>
### site\_hadoop::java class

#### Parameters

#####`ensure`

`ensure` parameter for java packages. Default: undef.

Default is usually OK. Due to limitation in puppet, when java package is in *held* state, this must be specified also here.

#####`java_version`

Major version number of Java to install. Default: [8, 7].

Value can be array or single item. When array, the first available version is used.

#####`ppa_repo_enable`

Enable webupd8 PPA repository providing Oracle Java, if needed. Default: false.

PPA repository may be needed, if the given Java is not available natively in the distribution.

Even when **true**, native packages are preferred (see *params.pp*).

<a name="limitation"></a>
##Limitation

Java alternatives are not touched.

<a name="development"></a>
##Development

* Repository: [https://github.com/MetaCenterCloudPuppet/cesnet-site\_hadoop](https://github.com/MetaCenterCloudPuppet/cesnet-site_hadoop)
* Testing:
 * basic: see *.travis.xml*
 * vagrant: [https://github.com/MetaCenterCloudPuppet/hadoop-tests](https://github.com/MetaCenterCloudPuppet/hadoop-tests)
