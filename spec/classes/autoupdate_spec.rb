require 'spec_helper'

describe 'site_hadoop::autoupdate', :type => 'class' do
  context "on Debian" do
    let(:facts) { {:operatingsystem => 'Debian', :osfamily => 'Debian', :lsbdistcodename => 'wheezy' } }

    it { should compile.with_all_deps }
    it { should contain_file('/etc/cron.d/cron-apt') }
  end
  context "on non-Debian" do
    let(:facts) { {:operatingsystem => 'Fedora', :osfamily => 'RedHat' } }

    it { should compile.with_all_deps }
  end
end
