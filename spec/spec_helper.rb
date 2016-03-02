require 'puppetlabs_spec_helper/module_spec_helper'
require 'rspec-puppet-facts'
include RspecPuppetFacts

$mysql_facts = {
  :root_home => '/root',
  :staging_http_get => 'wget',
}
