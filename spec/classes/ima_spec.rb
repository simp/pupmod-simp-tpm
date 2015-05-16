require 'spec_helper'

describe 'tpm::ima' do

  let(:params) {{
    :mount_dir => '/sys/kernel/security',
    :ima_audit => false,
    :ima_template => 'ima-ng',
    :ima_hash => 'sha1',
    :ima_tcb => true
  }}

  let(:facts) {{
    :cmdline => { 'ima' => 'on' },
    :ima_enabled => 'true',
    :operatingsystem => 'RedHat',
    :lsbmajdistrelease => '7'
  }}

  it { should compile.with_all_deps }
  it { should create_class('tpm::ima') }

  it do
    should contain_mount(params[:mount_dir]).with({
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

    let(:facts) {{
      :cmdline => { 'foo' => 'bar' },
      :ima_enabled => false,
      :operatingsystem => 'RedHat',
      :lsbmajdistrelease => '7'
    }}

    it { should compile.with_all_deps }
    it { should_not contain_file(params[:mount_dir]) }
    it { should contain_reboot_notify('ima') }
    it { should contain_kernel_parameter('ima').with_value('on') }
    it { should contain_kernel_parameter('ima').with_bootmode('normal') }
    it { should contain_kernel_parameter('ima_audit').with_value(params[:ima_audit]) }
    it { should contain_kernel_parameter('ima_audit').with_bootmode('normal') }
    it { should contain_kernel_parameter('ima_template').with_value(params[:ima_template]) }
    it { should contain_kernel_parameter('ima_template').with_bootmode('normal') }
    it { should contain_kernel_parameter('ima_hash').with_value(params[:ima_hash]) }
    it { should contain_kernel_parameter('ima_hash').with_bootmode('normal') }
    it { should contain_kernel_parameter('ima_tcb') }
  end

  context 'disabling_ima' do
    let(:params) {{ :enable => false }}

    it { should compile.with_all_deps }
    it { should contain_reboot_notify('ima') }
    it { should contain_kernel_parameter('ima').with_ensure('absent') }
    it { should contain_kernel_parameter('ima').with_bootmode('normal') }
    it { should contain_kernel_parameter('ima_audit').with_ensure('absent') }
    it { should contain_kernel_parameter('ima_audit').with_bootmode('normal') }
    it { should contain_kernel_parameter('ima_template').with_ensure('absent') }
    it { should contain_kernel_parameter('ima_template').with_bootmode('normal') }
    it { should contain_kernel_parameter('ima_hash').with_ensure('absent') }
    it { should contain_kernel_parameter('ima_hash').with_bootmode('normal') }
    it { should contain_kernel_parameter('ima_tcb').with_ensure('absent') }
  end
end
