require 'spec_helper'

# Contains the tests for modules init and both install modules.
#
describe 'tpm' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) do
        os_facts.merge({
          :cmdline => {'foo' => 'bar'},
          :has_tpm => false
        })
      end

      # before(:each) do
      #   File.stubs(:exists?).with('/dev/tpm0').returns(true)
      # end

      context 'with default parameters and no physical TPM' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_class('tpm') }
        it { is_expected.not_to create_class('tpm::ima') }
        it { is_expected.not_to create_class('tpm::tpm1::install') }
        it { is_expected.not_to create_class('tpm::tpm2::install') }
        it { is_expected.not_to create_class('tpm::ima') }
      end


      context 'with detected TPM unable to determine TPM type' do
        let(:facts) do
          os_facts.merge({ :has_tpm => true,
                           :tpm_version => 'unknown' })
        end

        it { is_expected.not_to create_class('tpm::tpm1::install') }
        it { is_expected.not_to create_class('tpm::tpm2::install') }
      end

      context 'with a detected TPM version 1' do
        let(:facts) do
          os_facts.merge({ :has_tpm => true,
                           :tpm_version => 'tpm1' })
        end

        context 'with default parameters' do
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_class('tpm') }
          it { is_expected.not_to create_class('tpm::ima') }
          it { is_expected.not_to create_class('tpm::tpm1::ownership') }
          it { is_expected.to create_class('tpm::tpm1::install') }
          it { is_expected.to contain_package('tpm-tools').with_ensure('installed') }
          it { is_expected.to contain_package('trousers').with_ensure('installed') }
          it { is_expected.to contain_service('tcsd').with({
            'ensure'  => 'running',
          'enable'  => true,
          }) }
        end

        context 'with param take_ownership => true' do
          let(:params) {{ :take_ownership => true }}

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_class('tpm') }
          it { is_expected.not_to create_class('tpm::ima') }
          it { is_expected.to create_class('tpm::tpm1::ownership') }
          it { is_expected.to create_class('tpm::tpm1::install') }
          it { is_expected.to contain_package('tpm-tools').with_ensure('installed') }
          it { is_expected.to contain_package('trousers').with_ensure('installed') }
          it { is_expected.to contain_service('tcsd').with({
            'ensure'  => 'running',
            'enable'  => true,
          }) }
        end
      #TPM 1.0
      end

      context 'with a detected TPM version 2' do
        let(:facts) do
          os_facts.merge({ :has_tpm => true,
                           :tpm_version => 'tpm2' })
        end

        context 'with default params' do

          if os_facts[:os][:release][:major].to_i < 7
            context 'on os version < 7 ' do
              it { is_expected.to_not compile}
            end
          else
            context 'on  os version => 7' do
              it { is_expected.to compile.with_all_deps }
              it { is_expected.to create_class('tpm') }
              it { is_expected.not_to create_class('tpm::ima') }
              it { is_expected.not_to create_class('tpm::tpm2::ownership') }
              it { is_expected.to create_class('tpm::tpm2::install') }
              it { is_expected.to contain_package('tpm2-tools').with_ensure('installed') }
              it { is_expected.to contain_package('tpm2-tss').with_ensure('installed') }
              it { is_expected.to contain_service('resourcemgr').with({
                'ensure'  => 'running',
                'enable'  => true,
              }) }
            end
          end
        end

        context 'with take_ownership true' do
          let(:params) {{ :take_ownership => true }}

          if os_facts[:os][:release][:major].to_i < 7
            context 'on os version < 7 ' do
              it { is_expected.to_not compile}
            end
          else
            context 'on os version >= 7 ' do
              it { is_expected.to compile.with_all_deps }
              it { is_expected.to create_class('tpm') }
              it { is_expected.not_to create_class('tpm::ima') }
              it { is_expected.to create_class('tpm::tpm2::ownership') }
              it { is_expected.to create_class('tpm::tpm2::install') }
              it { is_expected.to contain_package('tpm2-tools').with_ensure('installed') }
              it { is_expected.to contain_package('tpm2-tss').with_ensure('installed') }
              it { is_expected.to contain_service('resourcemgr').with({
                'ensure'  => 'running',
                'enable'  => true,
              }) }
            end
          end
        # take_ownership true
        end
      #TPM2.0
      end
    end
  end
end
