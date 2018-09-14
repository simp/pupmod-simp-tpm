require 'spec_helper'

describe 'tpm::tboot' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) do
        if os_facts[:os][:release][:major] >= '7'
          os_facts[:augeasprovider_grub_version] = 2
        else
          os_facts[:augeasprovider_grub_version] = 1
        end
        os_facts[:tboot] = {
          'measured_launch' => false,
          'tboot_session'   => false,
        }
        os_facts
      end

      # El6 will no longer fail at this point because it does
      # not attempt to run grub unless it knows what version
      # of tboot is installed
      context 'default with unknown version of tboot' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('tpm') }
        it { is_expected.to contain_package('tboot') }
      end

      context 'default options with tboot version known' do
        let(:params) {{
          :tboot_version => '1.9.6',
        }}
        if os_facts[:os][:release][:major].to_i == 7
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_class('tpm') }
          it { is_expected.to contain_package('tboot') }
          it { is_expected.to contain_reboot_notify('Launch tboot') }
          it { is_expected.to contain_class('tpm::tboot::grub') }
          it { is_expected.to contain_class('tpm::tboot::grub::grub2') }
          it { is_expected.to contain_exec('Update grub config') }
          it { is_expected.to contain_file('/etc/default/grub-tboot').with_content(<<-EOF.gsub(/^\s+/,'').strip
            GRUB_CMDLINE_TBOOT="logging=serial,memory,vga min_ram=0x2000000"
            GRUB_CMDLINE_LINUX_TBOOT="intel_iommu=on"
            GRUB_TBOOT_POLICY_DATA=""
          EOF
            ) }
          it { is_expected.to contain_class('tpm::tboot::policy') } #\
          it { is_expected.to contain_file('/boot/list.data').with_ensure('absent') }
          it { is_expected.to contain_reboot_notify('Tboot Policy Change') }
          it 'should lock the default packages' do
            contain_yum__versionlock('*:kernel-*-*.*').with_ensure('present')
            contain_yum__versionlock('*:kernel-bigmem-*-*.*').with_ensure('present')
            contain_yum__versionlock('*:kernel-enterprise-*-*.*').with_ensure('present')
            contain_yum__versionlock('*:kernel-smp-*-*.*').with_ensure('present')
            contain_yum__versionlock('*:kernel-debug-*-*.*').with_ensure('present')
            contain_yum__versionlock('*:kernel-unsupported-*-*.*').with_ensure('present')
            contain_yum__versionlock('*:kernel-source-*-*.*').with_ensure('present')
            contain_yum__versionlock('*:kernel-devel-*-*.*').with_ensure('present')
            contain_yum__versionlock('*:kernel-PAE-*-*.*').with_ensure('present')
            contain_yum__versionlock('*:kernel-PAE-debug-*-*.*').with_ensure('present')
            contain_yum__versionlock('*:kernel-modules-*-*.*').with_ensure('present')
            contain_yum__versionlock('*:kernel-headers-*-*.*').with_ensure('present')
          end
        else
          # it { is_expected.to contain_class('tpm::tboot::grub::grub1') }
          it { is_expected.to compile.and_raise_error(/does not currently support Grub 0.99-1.0/) }
        end
      end

      context 'with tboot version < 1/9/7 and create_policy set to true' do
        let(:params) {{
          :tboot_version           => '1.9.6',
          :create_policy           => true
        }}
        it { is_expected.to compile.and_raise_error(/version of tboot installed must be 1.9.7 or greater to create a policy/) }
      end

      context 'different grub2 parameters, create_policy true and lock_kernel_packages set to false' do
        let(:params) {{
          :tboot_version           => '1.9.7',
          :tboot_boot_options      => ['logging=vga,memory','garbage'],
          :additional_boot_options => ['logging=vga,memory','garbage'],
          :create_policy           => true,
          :lock_kernel_packages    => false
        }}
        if os_facts[:os][:release][:major].to_i == 7
          it { is_expected.to contain_file('/etc/default/grub-tboot').with_content(<<-EOF.gsub(/^\s+/,'').strip
            GRUB_CMDLINE_TBOOT="logging=vga,memory garbage"
            GRUB_CMDLINE_LINUX_TBOOT="logging=vga,memory garbage"
            GRUB_TBOOT_POLICY_DATA="list.data"
          EOF
          ) }
          it { is_expected.to contain_file('/root/txt/create_lcp_boot_policy.sh') }
          it { is_expected.to contain_exec('Generate and install tboot policy').with({
            'require' => 'File[/root/txt/create_lcp_boot_policy.sh]',
            'notify'  => 'Reboot_notify[Tboot Policy Change]'
          })}
          it 'should ensure version lock is removed ' do
            contain_yum__versionlock('*:kernel-*-*.*').with_ensure('absent')
            contain_yum__versionlock('*:kernel-bigmem-*-*.*').with_ensure('absent')
            contain_yum__versionlock('*:kernel-enterprise-*-*.*').with_ensure('absent')
            contain_yum__versionlock('*:kernel-smp-*-*.*').with_ensure('absent')
            contain_yum__versionlock('*:kernel-debug-*-*.*').with_ensure('absent')
            contain_yum__versionlock('*:kernel-unsupported-*-*.*').with_ensure('absent')
            contain_yum__versionlock('*:kernel-source-*-*.*').with_ensure('absent')
            contain_yum__versionlock('*:kernel-devel-*-*.*').with_ensure('absent')
            contain_yum__versionlock('*:kernel-PAE-*-*.*').with_ensure('absent')
            contain_yum__versionlock('*:kernel-PAE-debug-*-*.*').with_ensure('absent')
            contain_yum__versionlock('*:kernel-modules-*-*.*').with_ensure('absent')
            contain_yum__versionlock('*:kernel-headers-*-*.*').with_ensure('absent')
          end

        else
          it { is_expected.to compile.and_raise_error(/does not currently support Grub 0.99-1.0/) }
        end
      end

      context 'sinit over source' do
        let(:params) {{
          :tboot_version => '1.9.7',
          :sinit_source => 'https://kickstart-server.domain/ks/2nd_gen_i5_i7_SINIT_51.BIN',
          :sinit_name   => '2nd_gen_i5_i7_SINIT_51.BIN'
        }}
        if os_facts[:os][:release][:major].to_i == 7
          it { is_expected.to contain_file('/root/txt/sinit').with_ensure('directory') }
          it { is_expected.to contain_file('/root/txt/sinit/2nd_gen_i5_i7_SINIT_51.BIN') }
          it { is_expected.to contain_file('/boot/2nd_gen_i5_i7_SINIT_51.BIN').with_source('/root/txt/sinit/2nd_gen_i5_i7_SINIT_51.BIN') }
        else
          it { is_expected.to compile.and_raise_error(/does not currently support Grub 0.99-1.0/) }
        end
      end

      context 'sinit over rsync' do
        let(:params) {{
          :tboot_version => '1.9.7',
          :sinit_source => 'rsync',
          :sinit_name   => '2nd_gen_i5_i7_SINIT_51.BIN',
          :rsync_server => '127.0.0.1',
        }}
        if os_facts[:os][:release][:major].to_i == 7
          it { is_expected.to contain_file('/root/txt/sinit').with_ensure('directory') }
          it { is_expected.to contain_rsync('tboot').with_source('tboot_rp_env/') }
          it { is_expected.to contain_file('/boot/2nd_gen_i5_i7_SINIT_51.BIN').with_source('/root/txt/sinit/2nd_gen_i5_i7_SINIT_51.BIN') }
        else
          it { is_expected.to compile.and_raise_error(/does not currently support Grub 0.99-1.0/) }
        end
      end

    end
  end
end
