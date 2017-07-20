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
        os_facts
      end

      context 'default options' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('tpm') }
        it { is_expected.to contain_class('tpm') } #\
          # .that_comes_before("Class['tpm::tboot::policy']") }
        it { is_expected.to contain_class('tpm::tboot::policy') } #\
          # .that_notifies("Class['tpm::tboot::grub']") }
        it { is_expected.to contain_class('tpm::tboot::grub') } #\
          # .that_notifies("Reboot_notify['launch tboot']") }
        it { is_expected.to contain_reboot_notify('launch tboot') }

        if os_facts[:os][:release][:major].to_i == 7
          it { is_expected.to contain_class('tpm::tboot::grub::grub2') }
          it { is_expected.to contain_file('/etc/grub.d/20_linux_tboot') }
          it { is_expected.to contain_grub_config('GRUB_CMDLINE_TBOOT').with_value(['logging=serial,memory,vga']) }
          it { is_expected.to contain_grub_config('GRUB_CMDLINE_LINUX_TBOOT').with_value(['intel_iommu=on']) }
          it { is_expected.to contain_grub_config('GRUB_TBOOT_POLICY_DATA').with_value('list.data') }
          it { is_expected.to contain_exec('Update grub config') }
        else
          it { is_expected.to contain_class('tpm::tboot::grub::grub1') }
        end

        it { is_expected.to contain_file('/root/txt/create_lcp_boot_policy.sh') }
        it { is_expected.to contain_exec('Generate and install tboot policy') }
      end

      context 'sinit over source' do
        let(:params) {{
          :sinit_source => 'https://kickstart-server.domain/ks/2nd_gen_i5_i7_SINIT_51.BIN',
          :sinit_name   => '2nd_gen_i5_i7_SINIT_51.BIN'
        }}
        it { is_expected.to contain_file('/root/txt/sinit').with_ensure('directory') }
        it { is_expected.to contain_file('/root/txt/sinit/2nd_gen_i5_i7_SINIT_51.BIN') }
        it { is_expected.to contain_file('/boot/2nd_gen_i5_i7_SINIT_51.BIN').with_source('/root/txt/sinit/2nd_gen_i5_i7_SINIT_51.BIN') }
      end

      context 'sinit over rsync' do
        let(:params) {{
          :sinit_source => 'rsync',
          :sinit_name   => '2nd_gen_i5_i7_SINIT_51.BIN',
          :rsync_server => '127.0.0.1',
        }}
        it { is_expected.to contain_file('/root/txt/sinit').with_ensure('directory') }
        it { is_expected.to contain_rsync('tboot').with_source('tboot_rp_env/') }
        it { is_expected.to contain_file('/boot/2nd_gen_i5_i7_SINIT_51.BIN').with_source('/root/txt/sinit/2nd_gen_i5_i7_SINIT_51.BIN') }
      end

      context 'last boot was trusted and was successful' do
        let(:facts) do
          os_facts[:tboot_successful] = true
          os_facts
        end
        it { is_expected.not_to contain_exec('Generate and install tboot policy') }
      end

    end
  end
end
