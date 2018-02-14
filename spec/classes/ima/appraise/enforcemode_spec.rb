require 'spec_helper'

describe 'tpm::ima::appraise::enforcemode' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do

      context 'with default parameters' do

        it { is_expected.to contain_kernel_parameter('ima_appraise').with({
          'value'    => 'enforce',
          'bootmode' => 'normal',
        }).that_notifies('Exec[dracut ima appraise rebuild]')}
        it { is_expected.to contain_exec('dracut ima appraise rebuild').with({
          'command'     => '/sbin/dracut -f',
          'refreshonly' => true
        }).that_subscribes_to('Kernel_parameter[ima_appraise]')}
        it { is_expected.to contain_reboot_notify('ima_appraise_enforce_reboot').that_subscribes_to('Kernel_parameter[ima_appraise]')}

      end
    end
  end
end
