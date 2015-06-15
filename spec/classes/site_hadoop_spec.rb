require 'spec_helper'

describe 'site_hadoop', :type => 'class' do
  $test_os.each do |facts|
    os = facts['operatingsystem']

    context "on #{os}" do
      let(:facts) do
        facts
      end
      it { should compile.with_all_deps }
      it { should contain_class('site_hadoop::cloudera') }
    end
  end
end
