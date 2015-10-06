require 'spec_helper'

describe 'site_hadoop::java' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) do
          facts
        end

        it { is_expected.to compile.with_all_deps }

        if facts[:osfamily] == 'RedHat' then
          context "has java 8" do
            it { is_expected.to contain_package('java-1.8.0-jre-headless') }
          end
        elsif os =~ /(ubuntu-14|debian-(7|8|9))-/ then
          context "has java 7" do
            it { is_expected.to contain_package('openjdk-7-jre-headless') }
          end
        end

      end
    end
  end

  context 'unsupported operating system' do
    describe 'site_hadoop::java class without any parameters on Solaris/Nexenta' do
      let(:facts) do
        {
          :osfamily        => 'Solaris',
          :operatingsystem => 'Nexenta',
        }
      end

      it { expect { is_expected.to contain_class('site_hadoop::java') }.to raise_error(Puppet::Error, /Solaris.Nexenta not supported/) }
    end
  end

  context 'java from ppa' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) do
          facts
        end
        let(:params) {
          {:ppa_repo_enable => true, :java_version => 8}
        }

        if os =~ /(ubuntu-14|debian-(7|8))-/ then
          context "has java 8 in ppa" do
            it { is_expected.to contain_package('oracle-java8-installer') }
          end
        end
      end
    end
  end

end
