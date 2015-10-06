require 'spec_helper'

describe 'site_hadoop', :type => 'class' do
  on_supported_os.each do |os,facts|
    context "on #{os}" do
      let(:facts) do
        facts
      end
      it { should compile.with_all_deps }
      it { should contain_class('site_hadoop::cloudera') }
    end
  end
end
