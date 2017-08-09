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
          'tboot_session'   => false
        }
        os_facts
      end

      context 'default options, regular boot' do
        if os_facts[:os][:release][:major].to_i == 7
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_class('tpm') }
          it { is_expected.to contain_class('tpm') } #\
            # .that_comes_before("Class['tpm::tboot::policy']") }
          it { is_expected.to contain_class('tpm::tboot::policy') } #\
            # .that_notifies("Class['tpm::tboot::grub']") }
          it { is_expected.to contain_class('tpm::tboot::grub') } #\
            # .that_notifies("Reboot_notify['Launch tboot']") }
          it { is_expected.to contain_reboot_notify('Launch tboot') }

          it { is_expected.to contain_class('tpm::tboot::grub::grub2') }
          it { is_expected.to contain_file('/root/txt/create_lcp_boot_policy.sh') }
          it { is_expected.to contain_file('/root/txt/19_linux_tboot_pretxt.diff') }
          it { is_expected.to contain_exec('Patch 19_linux_tboot_pretxt, removing list.data and SINIT') }
          it { is_expected.to contain_file('/root/txt/20_linux_tboot.diff') }
          it { is_expected.to contain_exec('Patch 20_linux_tboot with list.data and SINIT') }
          it { is_expected.to contain_exec('Update grub config') }
          it { is_expected.to contain_file('/etc/default/grub-tboot').with_content(<<-EOF.gsub(/^\s+/,'').strip
            GRUB_CMDLINE_TBOOT="logging=serial,memory,vga min_ram=0x2000000"
            GRUB_CMDLINE_LINUX_TBOOT="intel_iommu=on"
            GRUB_TBOOT_POLICY_DATA="list.data"
          EOF
            ) }
        else
          # it { is_expected.to contain_class('tpm::tboot::grub::grub1') }
          it { is_expected.to compile.and_raise_error(/does not currently support Grub 0.99-1.0/) }
        end
      end

      context 'default options, tboot kernel' do
        let(:facts) do
          os_facts[:tboot] = {
            'measured_launch' => false,
            'tboot_session'   => true
          }
          os_facts
        end
        if os_facts[:os][:release][:major].to_i == 7
          it { is_expected.to contain_exec('Generate and install tboot policy') }
        else
          it { is_expected.to compile.and_raise_error(/does not currently support Grub 0.99-1.0/) }
        end

      end

      context 'different grub2 parameters' do
        let(:params) {{
          :tboot_boot_options      => ['logging=vga,memory','garbage'],
          :additional_boot_options => ['logging=vga,memory','garbage'],
        }}
        if os_facts[:os][:release][:major].to_i == 7
          it { is_expected.to contain_file('/etc/default/grub-tboot').with_content(<<-EOF.gsub(/^\s+/,'').strip
            GRUB_CMDLINE_TBOOT="logging=vga,memory garbage"
            GRUB_CMDLINE_LINUX_TBOOT="logging=vga,memory garbage"
            GRUB_TBOOT_POLICY_DATA="list.data"
          EOF
          ) }
        else
          it { is_expected.to compile.and_raise_error(/does not currently support Grub 0.99-1.0/) }
        end
      end

      context 'sinit over source' do
        let(:params) {{
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

      context 'last boot was trusted and was successful' do
        let(:facts) do
          os_facts[:tboot_successful] = true
          os_facts
        end
        if os_facts[:os][:release][:major].to_i == 7
          it { is_expected.not_to contain_exec('Generate and install tboot policy') }
        else
          it { is_expected.to compile.and_raise_error(/does not currently support Grub 0.99-1.0/) }
        end
      end

    end
  end
end
