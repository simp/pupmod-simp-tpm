require 'spec_helper'

describe 'tpm::ima::appraise::fixmode' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do

      context 'with relabel true' do
        let (:params) {{
          relabel_file: '/tmp/simp/.ima_relabel',
          relabel: true
        }}

        it { is_expected.to contain_kernel_parameter('ima_appraise').with({
          'value'    => 'fix',
          'bootmode' => 'normal',
        }).that_notifies('Reboot_notify[ima_appraise_fix_reboot]')}
        it { is_expected.to contain_file('/tmp/simp/.ima_relabel').with({'ensure' => 'file' })}
        it { is_expected.to contain_reboot_notify('ima_appraise_fix_reboot').that_subscribes_to('Kernel_parameter[ima_appraise]')}

      end
      context 'with relabel false' do
        let (:params) {{
          relabel_file: '/tmp/simp/.ima_relabel',
          relabel: false
        }}

        it { is_expected.to contain_kernel_parameter('ima_appraise').with({
          'value'    => 'fix',
          'bootmode' => 'normal',
        }).that_notifies('Reboot_notify[ima_appraise_fix_reboot]')}
        it { is_expected.to contain_file('/tmp/simp/.ima_relabel').with({'ensure' => 'absent' })}
        it { is_expected.to contain_reboot_notify('ima_appraise_fix_reboot').that_subscribes_to('Kernel_parameter[ima_appraise]')}
      end
    end
  end
end
