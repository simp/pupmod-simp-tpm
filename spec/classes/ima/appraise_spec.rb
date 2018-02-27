require 'spec_helper'

shared_examples_for 'an ima appraise enabled system' do
  it { is_expected.to compile.with_all_deps }
  it { is_expected.to create_package('attr') }
  it { is_expected.to create_package('ima-evm-utils') }
  it { is_expected.to create_kernel_parameter('ima_appraise_tcb')}
  it { is_expected.to create_file('/myscripts/ima_security_attr_update.sh').with({
    'source' => 'puppet:///modules/tpm/ima_security_attr_update.sh'
  })}
end

describe 'tpm::ima::appraise' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do

#      if os_facts[:operatingsystemmajrelease].to_s == '7'
      let (:default_facts) do
        os_facts.merge({
          :puppet => { :vardir =>  '/tmp'},
        })
      end

      context 'with default params' do
        let (:params) {{
          relabel_file: '/tmp/relabel',
          package_ensure: 'installed',
          scriptdir: '/myscripts'
        }}

        context 'with ima_appraise not set' do
          let (:facts) do
            default_facts.merge({
              :cmdline => { 'foo' => 'bar' }
            })
          end
          it_should_behave_like 'an ima appraise enabled system'
          it { is_expected.to contain_class('tpm::ima::appraise::fixmode').with({
            'relabel' => true  })}
        end

        context 'with ima_appraise not set but ima_appraise_tcb set' do
          let (:facts) do
            default_facts.merge({
              :cmdline => { 'foo' => 'bar', 'ima_appraise_tcb' => '' }
            })
          end
          it_should_behave_like 'an ima appraise enabled system'
          it { is_expected.to_not contain_class('tpm::ima::appraise::fixmode') }
          it { is_expected.to_not contain_class('tpm::ima::appraise::relabel') }
          it { is_expected.to contain_file('/tmp/relabel').with({
            'ensure' => 'absent'
          })}
        end

        context 'with ima_appraise fix' do
          let (:facts) do
            default_facts.merge({
              :cmdline => { 'ima_appraise' => 'fix' }
            })
          end
          it_should_behave_like 'an ima appraise enabled system'
          it { is_expected.to_not contain_class('tpm::ima::appraise::fixmode') }
          it { is_expected.to contain_class('tpm::ima::appraise::relabel').with({
            'relabel_file' => '/tmp/relabel'})}
        end

        context 'with ima_appraise enforce' do
          let (:facts) do
            default_facts.merge({
              :cmdline => { 'ima_appraise' => 'enforce' }
            })
          end
          it_should_behave_like 'an ima appraise enabled system'
          it { is_expected.to_not contain_class('tpm::ima::appraise::fixmode') }
          it { is_expected.to_not contain_class('tpm::ima::appraise::relabel') }
          it { is_expected.to contain_file('/tmp/relabel').with({
            'ensure' => 'absent'
          })}
        end

        context 'with ima_appraise off' do
          let (:facts) do
            default_facts.merge({
              :cmdline => { 'ima_appraise' => 'off' }
            })
          end
          it_should_behave_like 'an ima appraise enabled system'
          it { is_expected.to contain_class('tpm::ima::appraise::fixmode').with({
            'relabel' => true  })}
          it { is_expected.to_not contain_class('tpm::ima::appraise::relabel') }
          it_should_behave_like 'an ima appraise enabled system'
        end
      end

      context 'with  fix_mode set to true' do
        let (:params) {{
          relabel_file: '/tmp/relabel',
          scriptdir: '/myscripts',
          force_fixmode: true,
          package_ensure: 'installed'
        }}
        it_should_behave_like 'an ima appraise enabled system'
        it { is_expected.to contain_class('tpm::ima::appraise::fixmode').with({
          'relabel' => false  })}
        it { is_expected.to_not contain_class('tpm::ima::appraise::relabel') }
      end
      context 'with enable set to false' do
        let (:params) {{
          enable: false,
          package_ensure: 'installed',
          scriptdir: '/myscripts',
          relabel_file:   '/tmp/relabel'
        }}

        it { is_expected.to create_kernel_parameter('ima_appraise_tcb').with({
          'ensure' => 'absent'
        })}
        it { is_expected.to create_kernel_parameter('ima_appraise').with({
          'ensure' => 'absent'
        })}
      end
    end
  end
end
