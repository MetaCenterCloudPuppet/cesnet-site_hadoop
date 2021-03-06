require 'spec_helper'

describe 'site_hadoop::role::slave', :type => 'class' do
  on_supported_os($test_os).each do |os,facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge($hive_facts)
      end
      it { should compile.with_all_deps }
      it { should contain_class('site_hadoop::role::slave') }
      it { should contain_class('site_hadoop::repo::cloudera') }
      it { should contain_class('hadoop') }
      it { should contain_class('hadoop::datanode') }
      it { should contain_class('hadoop::nodemanager') }
    end
  end
end
