require 'spec_helper'

describe 'tpm::ima' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do

      let(:params) {{
        :mount_dir => '/sys/kernel/security',
        :ima_audit => false,
        :ima_template => 'ima-ng',
        :ima_hash => 'sha1',
        :ima_tcb => true
      }}

      let(:facts) do
        os_facts.merge({
        :cmdline => { 'ima' => 'on' },
        :ima_enabled => 'true'
        })
      end

      it { is_expected.to compile.with_all_deps }
      it { is_expected.to create_class('tpm::ima') }

      it do
        is_expected.to contain_mount(params[:mount_dir]).with({
          'ensure'   => 'mounted',
          'atboot'   => true,
          'device'   => 'securityfs',
          'fstype'   => 'securityfs',
          'target'   => '/etc/fstab',
          'remounts' => true,
          'options'  => 'defaults',
          'dump'     => '0',
          'pass'     => '0'
        })
      end

      context 'without_ima_enabled' do

        let(:facts) do
          os_facts.merge({
            :cmdline => { 'foo' => 'bar' },
            :ima_enabled => false,
          })
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.not_to contain_file(params[:mount_dir]) }
        it { is_expected.to contain_reboot_notify('ima') }
        it { is_expected.to contain_kernel_parameter('ima').with_value('on') }
        it { is_expected.to contain_kernel_parameter('ima').with_bootmode('normal') }
        it { is_expected.to contain_kernel_parameter('ima_audit').with_value(false) }
        it { is_expected.to contain_kernel_parameter('ima_audit').with_bootmode('normal') }
        it { is_expected.to contain_kernel_parameter('ima_template').with_value(params[:ima_template]) }
        it { is_expected.to contain_kernel_parameter('ima_template').with_bootmode('normal') }
        it { is_expected.to contain_kernel_parameter('ima_hash').with_value(params[:ima_hash]) }
        it { is_expected.to contain_kernel_parameter('ima_hash').with_bootmode('normal') }
        it { is_expected.to contain_kernel_parameter('ima_tcb') }
      end

      context 'disabling_ima' do
        let(:params) {{ :enable => false }}

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_reboot_notify('ima') }
        it { is_expected.to contain_kernel_parameter('ima').with_ensure('absent') }
        it { is_expected.to contain_kernel_parameter('ima').with_bootmode('normal') }
        it { is_expected.to contain_kernel_parameter('ima_audit').with_ensure('absent') }
        it { is_expected.to contain_kernel_parameter('ima_audit').with_bootmode('normal') }
        it { is_expected.to contain_kernel_parameter('ima_template').with_ensure('absent') }
        it { is_expected.to contain_kernel_parameter('ima_template').with_bootmode('normal') }
        it { is_expected.to contain_kernel_parameter('ima_hash').with_ensure('absent') }
        it { is_expected.to contain_kernel_parameter('ima_hash').with_bootmode('normal') }
        it { is_expected.to contain_kernel_parameter('ima_tcb').with_ensure('absent') }
      end
    end
  end
end
