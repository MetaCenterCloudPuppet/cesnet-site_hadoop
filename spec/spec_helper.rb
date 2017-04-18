require 'puppetlabs_spec_helper/module_spec_helper'
require 'rspec-puppet-facts'

include RspecPuppetFacts

require 'simplecov'
require 'simplecov-console'

SimpleCov.start do
  add_filter '/spec'
  add_filter '/vendor'
  formatter SimpleCov::Formatter::MultiFormatter.new([
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::Console
  ])
end

$mysql_facts = {
  :root_home => '/root',
  :staging_http_get => 'wget',
}

$test_os={
    :supported_os => [
        {
          'osfamily' => 'Debian',
          'operatingsystem' => 'Debian',
          'operatingsystemrelease' => ['7']
        }, {
          'osfamily' => 'Debian',
          'operatingsystem' => 'Ubuntu',
          'operatingsystemrelease' => ['14.04']
        }, {
          'osfamily' => 'RedHat',
          'operatingsystem' => 'RedHat',
          'operatingsystemrelease' => ['6']
        }, {
          'osfamily' => 'CentOS',
          'operatingsystem' => 'RedHat',
          'operatingsystemrelease' => ['7']
        }
    ]
}
