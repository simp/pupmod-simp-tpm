require 'spec_helper'

describe 'tpm::ima::policy' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do

      if os_facts[:operatingsystemmajrelease].to_s == '6'
        let(:facts) do
          os_facts.merge({
            :init_systems => ['sysv']
          })
        end
      else
        let(:facts) do
          os_facts.merge({
            :init_systems => ['systemd']
          })
        end

      end

      let(:default_sample) {
        File.read(File.expand_path('spec/files/default_ima_policy.conf'))
      }

      context 'with default params' do
        it { is_expected.to create_class('tpm::ima::policy') }
        if os_facts[:operatingsystemmajrelease].to_s == '6'
          it { is_expected.to create_file('/etc/init.d/import_ima_rules').with_ensure('absent') }
          it { is_expected.to create_service('import_ima_rules').with({
            :ensure  => 'stopped',
            :enable  => false,
          }) }
        else
          it { is_expected.to create_file('/etc/systemd/system/import_ima_rules.service').with_ensure('absent') }
          it { is_expected.to create_service('import_ima_rules.service').with.with({
            :ensure  => 'stopped',
            :enable  => false,
          }) }
        end
      end

      context 'with manage => true' do
        let(:params) {{ :manage => true }}
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_class('tpm::ima::policy') }
        it { is_expected.to create_file('/etc/ima').with_ensure('directory') }
        it { is_expected.to create_exec('load_ima_policy') \
          .with_command('cat /etc/ima/policy.conf > /sys/kernel/security/ima/policy') }

        it { is_expected.to create_file('/etc/ima/policy.conf') \
          .with_content(default_sample) }

        if os_facts[:operatingsystemmajrelease].to_s == '6'
          it { is_expected.to create_file('/etc/init.d/import_ima_rules').with_mode('0755') }
          it { is_expected.to create_service('import_ima_rules').with({
            :ensure  => 'stopped',
            :enable  => true,
          }) }
        else
          it { is_expected.to create_file('/etc/systemd/system/import_ima_rules.service').with_mode('0644') }
          it { is_expected.to create_service('import_ima_rules.service').with.with({
            :ensure  => 'stopped',
            :enable  => true,
          }) }
        end
      end

      context 'with an selinux policy disabled' do
        let(:params) {{
          :dont_watch_lastlog_t => false,
          :manage               => true
        }}
        let(:selinux_sample) {
          File.read(File.expand_path('spec/files/selinux_ima_policy.conf'))
        }

        it { is_expected.to create_file('/etc/ima/policy.conf') \
          .with_content(selinux_sample) }
      end

      context 'with an fsmagic disabled' do
        let(:params) {{
           :dont_watch_binfmtfs => false,
           :manage              => true
        }}
        let(:fsmagic_sample) {
          File.read(File.expand_path('spec/files/fsmagic_ima_policy.conf'))
        }

        it { is_expected.to create_file('/etc/ima/policy.conf') \
          .with_content(fsmagic_sample) }
      end

      context 'with custom selinux contexts' do
        let(:params) {{
          :dont_watch_list => [ 'user_home_t', 'locale_t' ],
          :manage => true
        }}
        let(:custom_sample) {
          File.read(File.expand_path('spec/files/custom_ima_policy.conf'))
        }

        it { is_expected.to create_file('/etc/ima/policy.conf') \
          .with_content(custom_sample) }
      end
    end
  end
end
