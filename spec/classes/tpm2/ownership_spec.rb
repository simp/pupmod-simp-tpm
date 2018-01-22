require 'spec_helper'

describe 'tpm::tpm2::ownership' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) do
        os_facts.merge({ :has_tpm => true,
                         :tpm_version => 'tpm2' })
      end

      context 'with default parameters and a physical TPM' do
        let(:params) {{
          'tpm_name'      => 'tpm0',
          'owned'         => true,
          'ownerauth'    => 'badpass1',
          'lockauth'     => 'badpass1',
          'endorseauth'  => 'badpass1',
        }}

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_tpm2_ownership('tpm0').with({
          'owned'          => true,
          'ownerauth'     => 'badpass1',
          'local'          => false,
          'inhex'          => false
        }) }
      end

    end
  end
end
