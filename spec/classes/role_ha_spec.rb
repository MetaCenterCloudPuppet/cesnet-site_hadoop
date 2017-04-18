require 'spec_helper'

describe 'site_hadoop::role::ha', :type => 'class' do
  on_supported_os($test_os).each do |os,facts|
    context "on #{os}" do
      let(:facts) do
        facts
      end
      it { should compile.with_all_deps }
      it { should contain_class('site_hadoop::role::ha') }
      it { should contain_class('java_ng') }
      it { should contain_class('site_hadoop::cloudera') }
      it { should contain_class('hadoop') }
      it { should contain_class('hadoop::journalnode') }
      it { should contain_class('zookeeper') }
    end
  end
end
