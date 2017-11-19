require 'spec_helper'

describe 'site_hadoop::role::master', :type => 'class' do
  on_supported_os($test_os).each do |os,facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge($mysql_facts)
      end
      it { should compile.with_all_deps }
      it { should contain_class('java_ng') }
      it { should contain_class('site_hadoop::role::master') }
      it { should contain_class('site_hadoop::accounting') }
      it { should contain_class('site_hadoop::bookkeeping') }
      it { should contain_class('site_hadoop::repo::cloudera') }
      it { should contain_class('hadoop') }
      it { should contain_class('hadoop::namenode') }
      it { should contain_class('hadoop::resourcemanager') }
    end
  end
end
