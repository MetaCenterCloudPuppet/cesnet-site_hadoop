require 'spec_helper'

describe 'site_hadoop::role::hue', :type => 'class' do
  on_supported_os($test_os).each do |os,facts|
    context "on #{os}" do
      let(:facts) do
        facts
      end
      it { should compile.with_all_deps }
      it { should contain_class('site_hadoop::role::hue') }
      it { should contain_class('java_ng') }
      it { should contain_class('site_hadoop::cloudera') }
      it { should contain_class('hadoop') }
      # only with HDFS HA
      #it { should contain_class('hadoop::httpfs') }
      it { should contain_class('hue') }
    end
  end
end
