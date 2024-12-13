require 'spec_helper'

describe 'tpm' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) do
        os_facts.merge({
                         cmdline: { 'foo' => 'bar' },
          has_tpm: false
                       })
      end

      # before(:each) do
      #   allow(File).to receive(:exist?).with('/dev/tpm0').and_return(true)
      # end

      context 'with default parameters and no physical TPM' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_class('tpm') }
        it { is_expected.not_to create_class('ima') }
        it { is_expected.not_to create_class('tpm::ownership') }
        it { is_expected.not_to contain_package('tpm-tools') }
        it { is_expected.not_to contain_package('trousers') }
        it { is_expected.not_to contain_service('tcsd') }
      end

      context 'with default parameters and a detected TPM' do
        let(:facts) do
          os_facts.merge({ has_tpm: true })
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_class('tpm') }
        it { is_expected.not_to create_class('ima') }
        it { is_expected.not_to create_class('tpm::ownership') }
        it { is_expected.to contain_package('tpm-tools').with_ensure('latest') }
        it { is_expected.to contain_package('trousers').with_ensure('latest') }
        it {
          is_expected.to contain_service('tcsd').with({
                                                        'ensure'  => 'running',
          'enable' => true,
                                                      })
        }
      end

      context 'with detected TPM and take_ownership => true' do
        let(:facts) do
          os_facts.merge({ has_tpm: true })
        end
        let(:params) { { take_ownership: true } }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_class('tpm') }
        it { is_expected.not_to create_class('ima') }
        it { is_expected.to create_class('tpm::ownership') }
        it { is_expected.to contain_package('tpm-tools').with_ensure('latest') }
        it { is_expected.to contain_package('trousers').with_ensure('latest') }
        it {
          is_expected.to contain_service('tcsd').with({
                                                        'ensure'  => 'running',
          'enable' => true,
                                                      })
        }
      end

      context 'with detected TPM and ima => true and take_ownership => true' do
        let(:facts) do
          os_facts.merge({ has_tpm: true })
        end
        let(:params) do
          {
            ima: true,
         take_ownership: true,
          }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_class('tpm') }
        it { is_expected.to create_class('ima') }
        it { is_expected.to create_class('tpm::ownership') }
        it { is_expected.to contain_package('tpm-tools').with_ensure('latest') }
        it { is_expected.to contain_package('trousers').with_ensure('latest') }
        it {
          is_expected.to contain_service('tcsd').with({
                                                        'ensure'  => 'running',
          'enable' => true,
                                                      })
        }
      end
    end
  end
end
