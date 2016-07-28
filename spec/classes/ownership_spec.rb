require 'spec_helper'

describe 'tpm::ownership' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) do
        os_facts.merge({ :has_tpm => true })
      end

      context 'with default parameters and a physical TPM' do
        let(:params) {{
          'owner_pass'     => 'badpass1',
          'srk_pass'       => 'badpass2',
          'advanced_facts' => true
        }}

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to create_class('tpm::ownership') }
        it { is_expected.to contain_tpm_ownership('tpm0').with({
          'ensure'         => 'present',
          'owner_pass'     => 'badpass1',
          'srk_pass'       => 'badpass2',
          'advanced_facts' => true
        }) }
      end

    end
  end
end
